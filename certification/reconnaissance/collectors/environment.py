"""
TIA_FORENSIC_RECON_ENGINE — environment collector.

Move 0. Captures runtime versions and dependency manifest metadata.
Never reads .env* content. Never runs dependency install.

READ-ONLY. No network. No install. No .env read.
"""
from __future__ import annotations

import os
import platform
import shutil
import subprocess
from typing import Any, Dict, List, Optional

from . import _common as C


SECRET_BASENAMES = {".env", ".env.production", ".env.local", ".env.staging", ".env.development"}


def _safe_run(cmd: List[str], timeout: float = 10.0) -> Optional[str]:
    try:
        proc = subprocess.run(
            cmd, capture_output=True, text=True, encoding="utf-8",
            errors="replace", timeout=timeout
        )
        if proc.returncode != 0:
            return None
        return (proc.stdout or "").strip()
    except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
        return None


def _version_string(name: str, version_args: List[str]) -> Dict[str, Any]:
    if not shutil.which(name):
        return {"available": False, "name": name, "version_text": None, "version_normalized": None}
    raw = _safe_run([name, *version_args])
    if raw is None:
        return {"available": False, "name": name, "version_text": None, "version_normalized": None}
    # Normalize: first line; strip
    first = raw.splitlines()[0].strip() if raw else ""
    return {
        "available": True,
        "name": name,
        "version_text": first,
        # Version normalized = same as text for now; future Move could parse semver.
        "version_normalized": first,
    }


def _file_metadata(repo: str, rel_path: str) -> Optional[Dict[str, Any]]:
    """Return size + sha256 for a manifest file. NEVER read content for secret files."""
    base = os.path.basename(rel_path)
    if base in SECRET_BASENAMES:
        # Defensive: never even open the file.
        full = os.path.join(repo, rel_path)
        try:
            size = os.path.getsize(full)
        except OSError:
            size = 0
        return {
            "path": rel_path,
            "size_bytes": size,
            "sha256": None,
            "content_read": False,
            "policy": "excluded_by_policy_secret",
        }
    full = os.path.join(repo, rel_path)
    if not os.path.isfile(full):
        return None
    try:
        size = os.path.getsize(full)
    except OSError:
        return None
    sha = C.sha256_file(full)
    return {"path": rel_path, "size_bytes": size, "sha256": sha, "content_read": False}


def collect(repo: str) -> Dict[str, Any]:
    """Return the environment evidence bundle."""
    # 1. Runtime versions (deterministic; failure -> available:False).
    runtimes: Dict[str, Any] = {
        "elixir": _version_string("elixir", ["--version"]),
        "erlang":  _version_string("erl", ["-noshell", "-eval", "io:format(\"~s~n\",[erlang:system_info(otp_release)]),halt()."]),
        "python": _version_string("python", ["--version"]),
        "node":    _version_string("node", ["--version"]),
        "npm":     _version_string("npm", ["--version"]),
    }

    # 2. Platform
    platform_info = {
        "system": platform.system(),
        "release": platform.release(),
        "machine": platform.machine(),
        "python_implementation": platform.python_implementation(),
        "python_version": platform.python_version(),
    }

    # 3. Dependency manifest candidates (READ ONLY). Record presence + size + sha256
    #    for each; do NOT read content.
    manifest_candidates = [
        "mix.lock",                       # Elixir / Mix
        "requirements.txt",               # Python
        "pyproject.toml",
        "Pipfile",
        "Pipfile.lock",
        "package.json",
        "package-lock.json",
        "yarn.lock",
        "pnpm-lock.yaml",
        "Cargo.toml",
        "Cargo.lock",
        "go.mod",
        "go.sum",
        "tsconfig.json",
    ]
    manifests: List[Dict[str, Any]] = []
    for rel in manifest_candidates:
        meta = _file_metadata(repo, rel)
        if meta is not None:
            manifests.append(meta)

    return {
        "schema_version": "1.0.0",
        "evidence_kind": "environment",
        "produced_by": {"collector": "environment", "contract_version": C.CONTRACT_VERSION},
        "produced_at_t0": C.T0_COMMIT,
        # M0-CLOSE-06: these versions describe the environment in which the
        # Move-0 audit EXECUTED, not necessarily the environment in which T0
        # historically operated. No mechanism in Move 0 proves the latter.
        "environment_kind": "AUDIT_EXECUTION_ENVIRONMENT",
        "environment_disclaimer": (
            "The runtime versions and platform recorded here were observed in "
            "the environment that executed this Move-0 audit. They do NOT "
            "establish the runtime environment in which T0 historically "
            "operated. Treating them as T0's historical runtime requires an "
            "explicit provenance mechanism, which is out of scope for Move 0."
        ),
        "runtimes": runtimes,
        "platform": platform_info,
        "dependency_manifests": manifests,
        "manifest_count": len(manifests),
    }
