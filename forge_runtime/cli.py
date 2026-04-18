from __future__ import annotations

import argparse
import json
import sys

from .config import load_runtime_config
from .runtime import ForgeRuntime, RuntimeError as ForgeError


def _make_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="forge-runtime",
        description="Run lab commands inside a Daytona sandbox bound to the current project.",
    )
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_exec = sub.add_parser("exec", help="Execute a command inside the sandbox.")
    p_exec.add_argument("--no-sync-up", action="store_true", help="Skip uploading project files first.")
    p_exec.add_argument("--no-sync-down", action="store_true", help="Skip downloading artifacts after.")
    p_exec.add_argument("--timeout", type=int, default=None, help="Per-command timeout in seconds.")
    p_exec.add_argument("--env", action="append", default=[], metavar="KEY=VALUE", help="Extra env var.")
    p_exec.add_argument("argv", nargs=argparse.REMAINDER, help="Command to run (prefix with --).")

    p_shell = sub.add_parser("shell", help="Run an interactive bash shell command in the sandbox.")
    p_shell.add_argument("script", nargs="?", default="bash -l", help="Shell command, default: bash -l")

    sub.add_parser("status", help="Show sandbox binding for the current project.")
    sub.add_parser("up", help="Ensure the sandbox exists and is started, sync project up.")
    sub.add_parser("sync", help="Force re-upload of the project to the sandbox.")
    sub.add_parser("pull", help="Download sandbox artifacts back into the project.")
    sub.add_parser("stop", help="Stop the sandbox without deleting it.")
    sub.add_parser("down", help="Delete the sandbox bound to this project.")

    return parser


def _parse_env(items: list[str]) -> dict[str, str]:
    env: dict[str, str] = {}
    for item in items:
        if "=" not in item:
            raise SystemExit(f"forge: invalid --env value: {item!r}")
        key, value = item.split("=", 1)
        env[key] = value
    return env


def main(argv: list[str] | None = None) -> int:
    parser = _make_parser()
    args = parser.parse_args(argv)

    try:
        runtime = ForgeRuntime(load_runtime_config())
    except ForgeError as exc:
        print(f"forge: {exc}", file=sys.stderr)
        return 2

    try:
        if args.cmd == "exec":
            argv_list = list(args.argv)
            if argv_list and argv_list[0] == "--":
                argv_list = argv_list[1:]
            if not argv_list:
                print("forge: nothing to run; pass a command after --", file=sys.stderr)
                return 2
            result = runtime.exec(
                argv_list,
                sync_up=not args.no_sync_up,
                sync_down=not args.no_sync_down,
                env=_parse_env(args.env),
                timeout=args.timeout,
            )
            return result.exit_code

        if args.cmd == "shell":
            result = runtime.exec(args.script, sync_up=True, sync_down=True)
            return result.exit_code

        if args.cmd == "status":
            print(json.dumps(runtime.status(), indent=2))
            return 0

        if args.cmd == "up":
            runtime.upload_project()
            print(json.dumps(runtime.status(), indent=2))
            return 0

        if args.cmd == "sync":
            runtime.upload_project()
            print("uploaded")
            return 0

        if args.cmd == "pull":
            written = runtime.download_project()
            print(f"pulled {len(written)} files")
            return 0

        if args.cmd == "stop":
            ok = runtime.stop_sandbox()
            print("stopped" if ok else "no sandbox bound")
            return 0

        if args.cmd == "down":
            ok = runtime.delete_sandbox()
            print("deleted" if ok else "no sandbox bound")
            return 0

    except ForgeError as exc:
        print(f"forge: {exc}", file=sys.stderr)
        return 1

    parser.error(f"unknown command: {args.cmd}")
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
