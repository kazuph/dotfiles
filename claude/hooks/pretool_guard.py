#!/usr/bin/env python3
"""
PreToolUse guard - mainブランチ保護のみ

Edit/Write/MultiEdit/NotebookEdit に対して:
- mainブランチで .md 以外の編集はブロック（worktree除く）
- .allow-main ファイルが存在する場合は制限緩和

Bash に対して:
- main/master への git push をブロック
- .allow-main ファイルが存在する場合は許可
"""

import json
import os
import shlex
import subprocess
import sys
from typing import Optional, Tuple


PROTECTED_BRANCHES = {"main", "master"}


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
    for key in ("cwd",):
        path = tool_input.get(key)
        if isinstance(path, str) and path:
            return os.path.abspath(path)
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


def get_bash_command(input_data: dict) -> str:
    tool_input = input_data.get("tool_input", {})
    for key in ("command", "cmd"):
        command = tool_input.get(key)
        if isinstance(command, str) and command.strip():
            return command.strip()
    return ""


def is_protected_ref(ref: str, current_branch: Optional[str]) -> bool:
    candidate = ref.strip()
    if not candidate:
        return False
    if candidate == "HEAD":
        return current_branch in PROTECTED_BRANCHES
    normalized = candidate.removeprefix("refs/heads/")
    return normalized in PROTECTED_BRANCHES


def is_git_push_to_protected_branch(
    command: str, current_branch: Optional[str]
) -> bool:
    try:
        tokens = shlex.split(command)
    except ValueError:
        tokens = command.split()

    git_index = None
    for index, token in enumerate(tokens):
        if os.path.basename(token) == "git":
            git_index = index
            break

    if git_index is None or git_index + 1 >= len(tokens):
        return False
    if tokens[git_index + 1] != "push":
        return False

    args = tokens[git_index + 2 :]
    positionals = [arg for arg in args if arg and not arg.startswith("-")]

    # refspec未指定の push は現在ブランチをそのまま push するとみなす
    if len(positionals) <= 1:
        return current_branch in PROTECTED_BRANCHES

    refspecs = positionals[1:]
    for refspec in refspecs:
        if ":" in refspec:
            _, destination = refspec.split(":", 1)
            if is_protected_ref(destination, current_branch):
                return True
            continue
        if is_protected_ref(refspec, current_branch):
            return True

    return False


def main():
    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)

    tool_name = input_data.get("tool_name", "")
    tool_input = input_data.get("tool_input", {})
    file_path = tool_input.get("file_path") or tool_input.get("path")

    # Bash/Edit/Write系ツール以外は対象外
    if tool_name not in {"Bash", "Write", "Edit", "MultiEdit", "NotebookEdit"}:
        emit_decision("allow", f"対象外ツール: {tool_name}")

    # Gitリポジトリ情報を取得
    target_dir = get_target_directory(input_data)
    in_repo, branch, git_root, is_worktree = get_git_info(target_dir)

    # Gitリポジトリ外は許可
    if not in_repo:
        emit_decision("allow", "gitリポジトリ外")

    allow_main = bool(
        git_root and os.path.isfile(os.path.join(git_root, ".allow-main"))
    )

    if tool_name == "Bash":
        command = get_bash_command(input_data)
        if not command:
            emit_decision("allow", "Bashコマンド未指定")

        if is_git_push_to_protected_branch(command, branch):
            if allow_main:
                emit_decision("allow", ".allow-main により main/master への push を許可")
            emit_decision(
                "deny",
                "main/master への git push は禁止されています。\n"
                "必要な場合のみリポジトリ直下に .allow-main を置いてください。",
            )

        emit_decision("allow", f"branch={branch}")

    # .allow-main ファイルが存在する場合は制限緩和
    if allow_main:
        emit_decision("allow", ".allow-main により制限緩和")

    # main/master かつ 非worktree の場合
    if branch in PROTECTED_BRANCHES and not is_worktree:
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
