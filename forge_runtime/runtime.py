from __future__ import annotations

import json
import shlex
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

from daytona import (
    CreateSandboxFromImageParams,
    CreateSandboxFromSnapshotParams,
    Daytona,
    DaytonaConfig,
    DaytonaError,
    DaytonaNotFoundError,
    Sandbox,
    SandboxState,
)

from . import sync
from .config import RuntimeConfig, load_runtime_config


REMOTE_UPLOAD_PATH = "/tmp/forge-upload.tar.gz"
REMOTE_DOWNLOAD_PATH = "/tmp/forge-download.tar.gz"
LABEL_PROJECT = "forge.project"
LABEL_KIND = "forge.kind"


class RuntimeError(Exception):
    """Forge runtime failure (configuration, network, sandbox)."""


@dataclass
class ExecResult:
    exit_code: int
    output: str


class ForgeRuntime:
    def __init__(self, config: RuntimeConfig | None = None) -> None:
        self.config = config or load_runtime_config()
        self._client: Daytona | None = None
        self._sandbox: Sandbox | None = None

    @property
    def client(self) -> Daytona:
        if self._client is not None:
            return self._client
        settings = self.config.daytona
        if not settings.api_key:
            raise RuntimeError(
                "DAYTONA_API_KEY is not set. Put it into the environment or .env "
                "(or set runtime.daytona.api_key in forge.yaml).",
            )
        cfg = DaytonaConfig(
            api_key=settings.api_key,
            api_url=settings.api_url,
            target=settings.target,
        )
        self._client = Daytona(cfg)
        return self._client

    def _save_state(self, sandbox: Sandbox) -> None:
        state_path = self.config.sandbox_state_path
        state_path.parent.mkdir(parents=True, exist_ok=True)
        state_path.write_text(
            json.dumps({"id": sandbox.id, "label": self.config.project_label}, indent=2) + "\n",
            encoding="utf-8",
        )
        gitignore = state_path.parent / ".gitignore"
        if not gitignore.exists():
            gitignore.write_text("*\n", encoding="utf-8")

    def _load_state(self) -> dict | None:
        path = self.config.sandbox_state_path
        if not path.is_file():
            return None
        try:
            return json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            return None

    def _clear_state(self) -> None:
        path = self.config.sandbox_state_path
        if path.is_file():
            path.unlink()

    def _create_params(self):
        settings = self.config.daytona
        labels = {LABEL_PROJECT: self.config.project_label, LABEL_KIND: "lab"}
        env_vars = {"WORK": self.config.remote_workdir, **settings.env}
        kwargs = dict(
            labels=labels,
            env_vars=env_vars,
            public=settings.public,
            auto_stop_interval=settings.auto_stop_minutes,
            auto_delete_interval=settings.auto_delete_minutes,
        )
        if settings.snapshot:
            return CreateSandboxFromSnapshotParams(snapshot=settings.snapshot, **kwargs)
        if settings.image:
            return CreateSandboxFromImageParams(image=settings.image, **kwargs)
        return CreateSandboxFromSnapshotParams(**kwargs)

    def _find_existing(self) -> Sandbox | None:
        state = self._load_state()
        if state and state.get("id"):
            try:
                sandbox = self.client.get(state["id"])
            except DaytonaNotFoundError:
                self._clear_state()
                sandbox = None
            except DaytonaError as exc:
                raise RuntimeError(f"failed to get sandbox {state['id']}: {exc}") from exc
            else:
                return sandbox

        try:
            page = self.client.list(labels={LABEL_PROJECT: self.config.project_label})
        except DaytonaError as exc:
            raise RuntimeError(f"failed to list sandboxes: {exc}") from exc
        for sb in getattr(page, "items", []) or []:
            self._save_state(sb)
            return sb
        return None

    def get_or_create_sandbox(self) -> Sandbox:
        if self._sandbox is not None:
            return self._sandbox

        sandbox = self._find_existing()
        if sandbox is None:
            try:
                sandbox = self.client.create(self._create_params(), timeout=180)
            except DaytonaError as exc:
                raise RuntimeError(f"failed to create sandbox: {exc}") from exc
            self._save_state(sandbox)
        else:
            state = getattr(sandbox, "state", None)
            if state in {SandboxState.STOPPED, SandboxState.ARCHIVED}:
                try:
                    self.client.start(sandbox, timeout=120)
                except DaytonaError as exc:
                    raise RuntimeError(f"failed to start sandbox: {exc}") from exc

        self._sandbox = sandbox
        self._ensure_workdir(sandbox)
        self._bootstrap(sandbox)
        return sandbox

    def _ensure_workdir(self, sandbox: Sandbox) -> None:
        cmd = f"mkdir -p {shlex.quote(self.config.remote_workdir)}"
        resp = sandbox.process.exec(cmd)
        if resp.exit_code:
            raise RuntimeError(f"failed to create remote workdir: {resp.result}")

    def _bootstrap(self, sandbox: Sandbox) -> None:
        script = self.config.daytona.bootstrap
        if not script:
            return
        marker = f"{self.config.remote_workdir.rstrip('/')}/.forge-bootstrapped"
        check = sandbox.process.exec(f"test -f {shlex.quote(marker)}")
        if check.exit_code == 0:
            return
        cmd = f"WORK={shlex.quote(self.config.remote_workdir)} bash -lc {shlex.quote(script)}"
        resp = sandbox.process.exec(cmd, timeout=20 * 60)
        if resp.exit_code:
            raise RuntimeError(
                f"runtime bootstrap failed (exit {resp.exit_code}):\n{resp.result}",
            )

    def upload_project(self) -> None:
        sandbox = self.get_or_create_sandbox()
        archive = sync.pack_project(self.config.project_root)
        sandbox.fs.upload_file(archive, REMOTE_UPLOAD_PATH)
        cmd = (
            f"mkdir -p {shlex.quote(self.config.remote_workdir)} && "
            f"tar -xzf {shlex.quote(REMOTE_UPLOAD_PATH)} -C {shlex.quote(self.config.remote_workdir)} && "
            f"rm -f {shlex.quote(REMOTE_UPLOAD_PATH)}"
        )
        resp = sandbox.process.exec(cmd, timeout=10 * 60)
        if resp.exit_code:
            raise RuntimeError(f"failed to extract project archive in sandbox: {resp.result}")

    def download_project(self, ignore: Iterable[str] = sync.DEFAULT_IGNORE) -> list[str]:
        sandbox = self.get_or_create_sandbox()
        excludes = sync.ignore_tar_args(ignore)
        cmd = (
            f"cd {shlex.quote(self.config.remote_workdir)} && "
            f"tar {excludes} -czf {shlex.quote(REMOTE_DOWNLOAD_PATH)} ."
        )
        resp = sandbox.process.exec(cmd, timeout=10 * 60)
        if resp.exit_code:
            raise RuntimeError(f"failed to pack sandbox project: {resp.result}")
        data = sandbox.fs.download_file(REMOTE_DOWNLOAD_PATH)
        sandbox.process.exec(f"rm -f {shlex.quote(REMOTE_DOWNLOAD_PATH)}")
        return sync.extract_archive(data, self.config.project_root)

    def exec(
        self,
        command: list[str] | str,
        *,
        sync_up: bool = True,
        sync_down: bool = True,
        env: dict[str, str] | None = None,
        timeout: int | None = None,
        stream: bool = True,
    ) -> ExecResult:
        if sync_up:
            self.upload_project()
        sandbox = self.get_or_create_sandbox()

        if isinstance(command, list):
            cmd_str = " ".join(shlex.quote(part) for part in command)
        else:
            cmd_str = command

        wrapped = f"cd {shlex.quote(self.config.remote_workdir)} && {cmd_str}"
        resp = sandbox.process.exec(wrapped, env=env, timeout=timeout)

        output = resp.result or ""
        if stream and output:
            sys.stdout.write(output)
            if not output.endswith("\n"):
                sys.stdout.write("\n")
            sys.stdout.flush()

        if sync_down:
            try:
                self.download_project()
            except RuntimeError as exc:
                print(f"forge: warning: failed to sync artifacts back: {exc}", file=sys.stderr)

        exit_code = int(resp.exit_code or 0)
        return ExecResult(exit_code=exit_code, output=output)

    def delete_sandbox(self) -> bool:
        state = self._load_state()
        if not state or not state.get("id"):
            return False
        try:
            sandbox = self.client.get(state["id"])
        except DaytonaNotFoundError:
            self._clear_state()
            return False
        try:
            self.client.delete(sandbox)
        except DaytonaError as exc:
            raise RuntimeError(f"failed to delete sandbox: {exc}") from exc
        self._clear_state()
        return True

    def stop_sandbox(self) -> bool:
        state = self._load_state()
        if not state or not state.get("id"):
            return False
        try:
            sandbox = self.client.get(state["id"])
        except DaytonaNotFoundError:
            self._clear_state()
            return False
        try:
            self.client.stop(sandbox)
        except DaytonaError as exc:
            raise RuntimeError(f"failed to stop sandbox: {exc}") from exc
        return True

    def status(self) -> dict:
        state = self._load_state() or {}
        info: dict = {
            "project_root": str(self.config.project_root),
            "project_label": self.config.project_label,
            "remote_workdir": self.config.remote_workdir,
            "sandbox_id": state.get("id"),
        }
        if not state.get("id"):
            info["state"] = "no sandbox bound"
            return info
        try:
            sandbox = self.client.get(state["id"])
        except DaytonaNotFoundError:
            info["state"] = "missing (sandbox was deleted remotely)"
            return info
        info["state"] = str(getattr(sandbox, "state", "unknown"))
        return info
