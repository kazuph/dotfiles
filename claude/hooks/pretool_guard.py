#!/usr/bin/env python3
"""
PreToolUse guard that consolidates previous main-branch protections and command blacklists.

Behavior summary:
- Blocks creation/edit of .allow-main everywhere.
- Applies destructive/deploy/publish blacklist to Bash (unless .allow-main is present).
- main/master + non-worktree:
    * Git: only safe read-only subcommands allowed; others blocked unless .allow-main.
    * Bash: blacklist only; other non-git commands allowed.
    * Write/Edit: allow only .md; others blocked (unless .allow-main).
- Worktree or non-main: blacklist only; git unrestricted.
- .allow-main file present: main restrictions relaxed, but creating/editing .allow-main still blocked.

Worktree guidance message uses ./.worktree/feature-xxx path per policy.
"""

import json
import os
import re
import shlex
import subprocess
import sys
from typing import Dict, List, Optional, Tuple


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


def get_target_directory(input_data: Dict) -> str:
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
    if tool_input.get("command"):
        return input_data.get("cwd", os.getcwd())
    return input_data.get("cwd", os.getcwd())


def run_git(args: List[str], cwd: str) -> Optional[str]:
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


def load_git_aliases(target_dir: str) -> Dict[str, str]:
    aliases: Dict[str, str] = {}
    for scope in (
        ["git", "config", "--local", "--get-regexp", "^alias\\."],
        ["git", "config", "--global", "--get-regexp", "^alias\\."],
    ):
        try:
            result = subprocess.run(
                scope, capture_output=True, text=True, timeout=3, cwd=target_dir
            )
            if result.returncode == 0:
                for line in result.stdout.splitlines():
                    if not line.strip():
                        continue
                    try:
                        key, value = line.split(None, 1)
                        alias_name = key.split("alias.", 1)[1]
                        aliases[alias_name] = value.strip()
                    except Exception:
                        continue
        except Exception:
            continue
    return aliases


SAFE_GIT_SUBCMDS = {
    "status",
    "show",
    "log",
    "diff",
    "reflog",
    "rev-parse",
    "rev-list",
    "ls-tree",
    "cat-file",
    "describe",
    "help",
    "version",
    "whatchanged",
    "shortlog",
    "annotate",
    "blame",
    "grep",
    "show-ref",
    "count-objects",
    "fsck",
}


def is_safe_git_command(subcmd: Optional[str], args: List[str]) -> bool:
    if subcmd is None:
        return False
    if subcmd in SAFE_GIT_SUBCMDS:
        return True
    if subcmd == "branch":
        forbidden = {
            "-m",
            "-M",
            "--move",
            "--set-upstream-to",
            "--unset-upstream",
            "--create-reflog",
        }
        return not any(flag in forbidden for flag in args)
    if subcmd == "remote":
        if not args:
            return True
        if args[0] in {"-v", "--verbose"}:
            return True
        if args[0] == "show":
            return True
        return False
    if subcmd == "worktree":
        if not args:
            return False
        # allow listing, creating, and removing worktrees
        if args[0] in {"list", "add", "remove"}:
            return True
        return False
    if subcmd == "gtr":
        # git-worktree-helper (gtr): worktree management tool
        # Only allow safe operations (matching git worktree policy)
        if not args:
            return True  # gtr without args shows help/status
        safe_gtr_cmds = {"new", "list", "switch", "add", "cd", "shell"}
        return args[0] in safe_gtr_cmds
    if subcmd == "config":
        forbidden_fragments = {
            "--add",
            "--replace-all",
            "--unset",
            "--unset-all",
            "--remove-section",
            "--rename-section",
            "--global",
            "--system",
            "--file",
            "-f",
            "--edit",
            "-e",
        }
        return not any(arg in forbidden_fragments for arg in args)
    if subcmd == "fetch":
        return True
    return False


def split_segments(command: str) -> List[str]:
    return [seg.strip() for seg in re.split(r"[;&]|&&|\|\||\n", command) if seg.strip()]


def resolve_git(subcmd_token: str, rest: List[str], aliases: Dict[str, str]) -> Tuple[Optional[str], List[str], bool]:
    # alias expansion
    if subcmd_token in aliases:
        alias_body = aliases[subcmd_token]
        if alias_body.startswith("!"):
            return None, [], True
        try:
            alias_tokens = shlex.split(alias_body)
        except Exception:
            alias_tokens = alias_body.split()
        if not alias_tokens:
            return None, [], False
        subcmd = alias_tokens[0]
        args = alias_tokens[1:] + rest
        return subcmd, args, False
    return subcmd_token, rest, False


def git_segments_all_safe(command: str, aliases: Dict[str, str]) -> bool:
    segments = split_segments(command)
    for seg in segments:
        try:
            tokens = shlex.split(seg)
        except ValueError:
            return False
        if "git" not in tokens:
            # non-git segment inside git-only context -> treat as unsafe
            continue
        git_idx = tokens.index("git")
        after = tokens[git_idx + 1 :]
        # skip -c and global flags
        i = 0
        while i < len(after) and after[i].startswith("-"):
            if after[i] == "-c" and i + 1 < len(after):
                i += 2
                continue
            i += 1
        if i >= len(after):
            return False
        subcmd_token = after[i]
        args = after[i + 1 :]
        subcmd, args_resolved, alias_unsafe = resolve_git(subcmd_token, args, aliases)
        if alias_unsafe:
            return False
        if not is_safe_git_command(subcmd, args_resolved):
            return False
    return True


def bash_blacklist_hit(command: str) -> Optional[Tuple[str, str]]:
    """
    Returns (decision, reason) tuple or None if no match.
    decision: "deny" for hard block, "ask_user" for confirmation dialog
    """
    if not command.strip():
        return None

    # block any attempt mentioning .allow-main (hard deny)
    if ".allow-main" in command:
        return ("deny", "🚫 .allow-main 作成・操作は禁止されています。")

    # Destructive patterns - require user confirmation (ask_user)
    destructive_patterns = [
        r"\brm\b\s+-[frFR]+",
        r"\brmdir\b",
        r"\bunlink\b",
        r"\bshred\b",
        r"\bfind\b[^\n]*-delete",
        r"\bmv\b[^\n]*\s/dev/null\b",
        r"\bdd\b[^\n]*of=/dev/sd",
        r"\bdiskutil\b\s+erase",
        r"\bmkfs\b",
        r"\bparted\b",
    ]

    # Deploy patterns - require user confirmation (ask_user)
    deploy_patterns = [
        r"\bdeploy\b",
        r"\bpublish\b",
        r"\brelease\b",
        r"\bnpm\s+publish\b",
        r"\bpnpm\s+publish\b",
        r"\byarn\s+publish\b",
        r"\bvercel\b",
        r"\bnetlify\b",
        r"\bfirebase\b[^\n]*\bdeploy\b",
        r"\bgcloud\b[^\n]*\bdeploy\b",
        r"\baws\b[^\n]*\bs3\b[^\n]*\bsync\b",
        r"\bgh\b\s+release\b",
    ]

    for pat in destructive_patterns + deploy_patterns:
        if re.search(pat, command, flags=re.IGNORECASE):
            return ("ask_user", "⚠️ 破壊的/デプロイ系コマンドです。実行しますか？")
    return None


def block_allow_main_file() -> None:
    err = (
        "🚫 .allow-main の作成・編集は禁止されています（全ブランチ共通）。\n"
        "main保護バイパス用途のため、手動生成は行わないでください。"
    )
    emit_decision("deny", err)


def main():
    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)

    tool_name = input_data.get("tool_name", "")
    tool_input = input_data.get("tool_input", {})
    command_str = tool_input.get("command", "") if tool_name == "Bash" else ""
    file_path = tool_input.get("file_path") or tool_input.get("path")

    target_dir = get_target_directory(input_data)

    # .allow-main ファイル操作を最優先でブロック
    if file_path and os.path.basename(file_path) == ".allow-main":
        block_allow_main_file()

    in_repo, branch, git_root, is_worktree = get_git_info(target_dir)
    allow_main_flag = bool(git_root and os.path.isfile(os.path.join(git_root, ".allow-main")))

    # Bashブラックリスト（allow-mainが無い場合のみ適用）
    if tool_name == "Bash" and not allow_main_flag:
        result = bash_blacklist_hit(command_str)
        if result:
            decision, reason = result
            emit_decision(decision, reason)

    # Gitリポジトリ外はブラックリストのみ適用済み、その他許可
    if not in_repo:
        emit_decision("allow", "gitリポジトリ外")

    # allow-main がある場合は main 制限を緩和（ただし .allow-main 作成は禁止済）
    if allow_main_flag:
        emit_decision("allow", ".allow-main により制限緩和")

    # main/master かつ 非worktree の特別処理
    if branch in {"main", "master"} and not is_worktree:
        worktree_msg = (
            "🚫 mainブランチでの直接作業は避けてください。\n"
            "📁 対象: {root}\n"
            "✅ 推奨: git worktree add ./.worktree/feature-xxx -b feature/xxx\n"
            "その後 ./.worktree/feature-xxx で作業してください。"
        ).format(root=git_root or target_dir)

        if tool_name == "Bash":
            aliases = load_git_aliases(target_dir)
            # 単語境界を考慮（github.com 等の誤検出を防ぐ）
            has_git = bool(re.search(r'\bgit\b', command_str))
            if has_git:
                if git_segments_all_safe(command_str, aliases):
                    emit_decision("allow", "mainだが安全なgitコマンドを許可")
                else:
                    emit_decision("deny", worktree_msg + "\n🔍 読み取り系以外のgitは禁止です。")
            else:
                # 非git Bash: ブラックリストを通過済なら許可
                emit_decision("allow", "mainだが非gitコマンドを許可（ブラックリスト通過）")
        elif tool_name in {"Write", "Edit", "MultiEdit", "NotebookEdit"}:
            if file_path and file_path.endswith(".md"):
                emit_decision("allow", "mainでの.md編集を許可")
            else:
                emit_decision("deny", worktree_msg + "\n.md以外の編集はブロックされました。")
        else:
            emit_decision("deny", worktree_msg)

    # 非main または worktree
    emit_decision("allow", f"branch={branch}")


if __name__ == "__main__":
    main()
