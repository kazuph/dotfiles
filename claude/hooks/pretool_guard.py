#!/usr/bin/env python3
"""
PreToolUse guard - mainブランチ保護のみ

Edit/Write/MultiEdit/NotebookEdit に対して:
- mainブランチで .md 以外の編集はブロック（worktree除く）
- .allow-main ファイルが存在する場合は制限緩和

.allow-main の編集禁止は settings.json の deny で管理。
Bash ツールのガードは ai_guard.zsh + settings.json で管理。
"""

import json
import os
import subprocess
import sys
from typing import Optional, Tuple


def emit_decision(decision: str, reason: Optional[str] = None) -> None:
    payload = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": decision,
        }
    }
    if reason:
        payload["hookSpecificOutput"]["permissionDecisionReason"] = reason
    print(json.dumps(payload, ensure_ascii=False))
    sys.exit(0)


def get_target_directory(input_data: dict) -> str:
    tool_input = input_data.get("tool_input", {})
    for key in ("file_path", "path", "notebook_path"):
        path = tool_input.get(key)
        if isinstance(path, str) and path:
            return os.path.dirname(os.path.abspath(path))
    for key in ("file_paths", "paths"):
        paths = tool_input.get(key)
        if isinstance(paths, list) and paths:
            for candidate in paths:
                if isinstance(candidate, str) and candidate:
                    return os.path.dirname(os.path.abspath(candidate))
    edits = tool_input.get("edits")
    if isinstance(edits, list):
        for edit in edits:
            if not isinstance(edit, dict):
                continue
            for key in ("file_path", "path", "notebook_path"):
                path = edit.get(key)
                if isinstance(path, str) and path:
                    return os.path.dirname(os.path.abspath(path))
    return input_data.get("cwd", os.getcwd())


def run_git(args: list, cwd: str) -> Optional[str]:
    try:
        result = subprocess.run(
            ["git"] + args, capture_output=True, text=True, timeout=5, cwd=cwd
        )
        if result.returncode == 0:
            return result.stdout.strip()
    except Exception:
        pass
    return None


def get_git_info(target_dir: str) -> Tuple[bool, Optional[str], Optional[str], bool]:
    branch = run_git(["rev-parse", "--abbrev-ref", "HEAD"], target_dir)
    if not branch:
        return False, None, None, False
    root = run_git(["rev-parse", "--show-toplevel"], target_dir)
    git_path = os.path.join(root or target_dir, ".git") if root else None
    is_worktree = os.path.isfile(git_path) if git_path else False
    return True, branch, root, is_worktree


def main():
    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)

    tool_name = input_data.get("tool_name", "")
    tool_input = input_data.get("tool_input", {})
    file_path = tool_input.get("file_path") or tool_input.get("path")

    # Edit/Write系ツール以外は対象外
    if tool_name not in {"Write", "Edit", "MultiEdit", "NotebookEdit"}:
        emit_decision("allow", f"対象外ツール: {tool_name}")

    # Gitリポジトリ情報を取得
    target_dir = get_target_directory(input_data)
    in_repo, branch, git_root, is_worktree = get_git_info(target_dir)

    # Gitリポジトリ外は許可
    if not in_repo:
        emit_decision("allow", "gitリポジトリ外")

    # .allow-main ファイルが存在する場合は制限緩和
    if git_root and os.path.isfile(os.path.join(git_root, ".allow-main")):
        emit_decision("allow", ".allow-main により制限緩和")

    # main/master かつ 非worktree の場合
    if branch in {"main", "master"} and not is_worktree:
        # .md ファイルは許可
        if file_path and file_path.endswith(".md"):
            emit_decision("allow", "mainでの.md編集を許可")

        # それ以外はブロック
        worktree_msg = (
            "mainブランチでの直接作業は避けてください。\n"
            "対象: {root}\n"
            "推奨: git wt feature/xxx\n"
            "worktreeディレクトリで作業してください。\n"
            ".md以外の編集はブロックされました。"
        ).format(root=git_root or target_dir)
        emit_decision("deny", worktree_msg)

    # 非main または worktree は許可
    emit_decision("allow", f"branch={branch}")


if __name__ == "__main__":
    main()
