from __future__ import annotations

import io
import os
import tarfile
from fnmatch import fnmatch
from pathlib import Path
from typing import Iterable


DEFAULT_IGNORE: tuple[str, ...] = (
    ".git",
    ".venv",
    "venv",
    "env",
    "node_modules",
    "__pycache__",
    ".mypy_cache",
    ".pytest_cache",
    ".ruff_cache",
    ".cache",
    ".forge",
    ".DS_Store",
    "*.pyc",
    "*.pyo",
    "*.o",
    "*.obj",
)


def _is_ignored(rel: Path, patterns: Iterable[str]) -> bool:
    parts = rel.parts
    for pattern in patterns:
        for part in parts:
            if fnmatch(part, pattern):
                return True
        if fnmatch(rel.as_posix(), pattern):
            return True
    return False


def pack_project(project_root: Path, ignore: Iterable[str] = DEFAULT_IGNORE) -> bytes:
    """Create a deterministic tar.gz of the project for upload."""
    project_root = project_root.resolve()
    patterns = tuple(ignore)
    buf = io.BytesIO()
    with tarfile.open(fileobj=buf, mode="w:gz") as tar:
        for dirpath, dirnames, filenames in os.walk(project_root):
            here = Path(dirpath)
            rel_here = here.relative_to(project_root)

            dirnames[:] = [
                d for d in sorted(dirnames)
                if not _is_ignored(rel_here / d, patterns)
            ]

            for name in sorted(filenames):
                rel = rel_here / name
                if _is_ignored(rel, patterns):
                    continue
                full = here / name
                if not full.is_file():
                    continue
                tar.add(str(full), arcname=rel.as_posix(), recursive=False)
    return buf.getvalue()


def extract_archive(archive: bytes, project_root: Path, ignore: Iterable[str] = DEFAULT_IGNORE) -> list[str]:
    """Extract a tar.gz from sandbox into the project root, overwriting tracked files."""
    project_root = project_root.resolve()
    patterns = tuple(ignore)
    written: list[str] = []
    with tarfile.open(fileobj=io.BytesIO(archive), mode="r:gz") as tar:
        for member in tar.getmembers():
            name = member.name.lstrip("./")
            if not name or name == ".":
                continue
            rel = Path(name)
            if rel.is_absolute() or ".." in rel.parts:
                continue
            if _is_ignored(rel, patterns):
                continue
            target = project_root / rel
            if member.isdir():
                target.mkdir(parents=True, exist_ok=True)
                continue
            if not member.isfile():
                continue
            target.parent.mkdir(parents=True, exist_ok=True)
            extracted = tar.extractfile(member)
            if extracted is None:
                continue
            data = extracted.read()
            target.write_bytes(data)
            if member.mode:
                try:
                    target.chmod(member.mode & 0o777)
                except OSError:
                    pass
            written.append(rel.as_posix())
    return written


def ignore_tar_args(ignore: Iterable[str] = DEFAULT_IGNORE) -> str:
    """Render --exclude args for the sandbox `tar` invocation."""
    return " ".join(f"--exclude={_shell_quote(p)}" for p in ignore)


def _shell_quote(value: str) -> str:
    if not value or any(c in value for c in " \t\n\"'\\$`"):
        return "'" + value.replace("'", "'\\''") + "'"
    return value
