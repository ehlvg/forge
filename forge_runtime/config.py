from __future__ import annotations

import os
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

import yaml


DEFAULT_REMOTE_WORKDIR = "/home/daytona/work"
DEFAULT_BOOTSTRAP = r"""
set -e
if [ -f "$WORK/.forge-bootstrapped" ]; then exit 0; fi
mkdir -p "$WORK"
sudo_cmd=""
if command -v sudo >/dev/null 2>&1 && [ "$(id -u)" != "0" ]; then sudo_cmd="sudo"; fi
export DEBIAN_FRONTEND=noninteractive
$sudo_cmd apt-get update -y
$sudo_cmd apt-get install -y --no-install-recommends \
  build-essential g++ cmake ninja-build \
  python3 python3-pip python3-venv \
  fonts-dejavu fonts-dejavu-core \
  curl ca-certificates xz-utils tar
if ! command -v typst >/dev/null 2>&1; then
  arch="$(uname -m)"
  case "$arch" in
    x86_64) ttarget="x86_64-unknown-linux-musl" ;;
    aarch64|arm64) ttarget="aarch64-unknown-linux-musl" ;;
    *) echo "unsupported arch: $arch" >&2; exit 1 ;;
  esac
  tmp="$(mktemp -d)"
  curl -fsSL "https://github.com/typst/typst/releases/latest/download/typst-${ttarget}.tar.xz" -o "$tmp/typst.tar.xz"
  tar -xJf "$tmp/typst.tar.xz" -C "$tmp"
  $sudo_cmd install -m 0755 "$tmp"/typst-*/typst /usr/local/bin/typst
  rm -rf "$tmp"
fi
touch "$WORK/.forge-bootstrapped"
""".strip()


@dataclass
class DaytonaSettings:
    snapshot: str | None = None
    image: str | None = None
    api_key: str | None = None
    api_url: str | None = None
    target: str | None = None
    env: dict[str, str] = field(default_factory=dict)
    auto_stop_minutes: int | None = 15
    auto_delete_minutes: int | None = None
    public: bool = False
    bootstrap: str = DEFAULT_BOOTSTRAP


@dataclass
class RuntimeConfig:
    project_root: Path
    remote_workdir: str = DEFAULT_REMOTE_WORKDIR
    daytona: DaytonaSettings = field(default_factory=DaytonaSettings)
    sandbox_state_path: Path = field(init=False)
    project_label: str = field(init=False)

    def __post_init__(self) -> None:
        self.project_root = Path(self.project_root).resolve()
        self.sandbox_state_path = self.project_root / ".forge" / "sandbox.json"
        self.project_label = _project_label(self.project_root)


def _project_label(path: Path) -> str:
    import hashlib

    return hashlib.sha1(str(path).encode("utf-8")).hexdigest()[:16]


def _read_yaml(path: Path) -> dict[str, Any]:
    if not path.is_file():
        return {}
    try:
        data = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
    except yaml.YAMLError as exc:
        raise SystemExit(f"forge: invalid YAML in {path}: {exc}") from exc
    return data if isinstance(data, dict) else {}


def _load_dotenv(path: Path) -> None:
    if not path.is_file():
        return
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        key = key.strip()
        value = value.strip().strip('"').strip("'")
        if key and key not in os.environ:
            os.environ[key] = value


def find_project_root(start: Path | None = None) -> Path:
    cur = (start or Path.cwd()).resolve()
    for candidate in [cur, *cur.parents]:
        if (candidate / "forge.yaml").is_file():
            return candidate
    return cur


def load_runtime_config(start: Path | None = None) -> RuntimeConfig:
    project_root = find_project_root(start)
    _load_dotenv(project_root / ".env")
    _load_dotenv(Path.home() / ".forge.env")

    global_cfg = _read_yaml(Path.home() / ".forge.yaml")
    project_cfg = _read_yaml(project_root / "forge.yaml")

    runtime_cfg: dict[str, Any] = {}
    for src in (global_cfg, project_cfg):
        block = src.get("runtime") if isinstance(src, dict) else None
        if isinstance(block, dict):
            runtime_cfg = _merge(runtime_cfg, block)

    daytona_cfg = runtime_cfg.get("daytona") if isinstance(runtime_cfg.get("daytona"), dict) else {}

    settings = DaytonaSettings(
        snapshot=os.environ.get("FORGE_DAYTONA_SNAPSHOT") or daytona_cfg.get("snapshot"),
        image=os.environ.get("FORGE_DAYTONA_IMAGE") or daytona_cfg.get("image"),
        api_key=os.environ.get("DAYTONA_API_KEY") or daytona_cfg.get("api_key"),
        api_url=os.environ.get("DAYTONA_API_URL") or daytona_cfg.get("api_url"),
        target=os.environ.get("DAYTONA_TARGET") or daytona_cfg.get("target"),
        env={**(daytona_cfg.get("env") or {})},
        auto_stop_minutes=_int(daytona_cfg.get("auto_stop_minutes"), default=15),
        auto_delete_minutes=_int(daytona_cfg.get("auto_delete_minutes"), default=None),
        public=bool(daytona_cfg.get("public", False)),
        bootstrap=str(daytona_cfg.get("bootstrap") or DEFAULT_BOOTSTRAP).strip(),
    )

    remote_workdir = (
        os.environ.get("FORGE_REMOTE_WORKDIR")
        or runtime_cfg.get("remote_workdir")
        or DEFAULT_REMOTE_WORKDIR
    )

    return RuntimeConfig(project_root=project_root, remote_workdir=str(remote_workdir), daytona=settings)


def _merge(base: dict[str, Any], extra: dict[str, Any]) -> dict[str, Any]:
    out = dict(base)
    for key, value in extra.items():
        if isinstance(value, dict) and isinstance(out.get(key), dict):
            out[key] = _merge(out[key], value)
        else:
            out[key] = value
    return out


def _int(value: Any, default: int | None) -> int | None:
    if value is None or value == "":
        return default
    try:
        return int(value)
    except (TypeError, ValueError):
        return default
