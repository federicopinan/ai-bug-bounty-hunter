#!/usr/bin/env python3
"""Manage per-finding evidence vaults under programs/{target}/vulns/poc/{finding_id}."""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

SAFE_RE = re.compile(r"^[A-Za-z0-9._-]+$")
SEVERITIES = {"Info", "Informational", "Low", "Medium", "High", "Critical"}
KINDS = {"request", "response", "screenshot", "payload", "note", "other"}
DEFAULT_MAX_EVIDENCE_BYTES = 10 * 1024 * 1024


def repo_root() -> Path:
    return Path(__file__).resolve().parents[2]


def fail(message: str) -> None:
    print(json.dumps({"ok": False, "error": message}, indent=2), file=sys.stderr)
    raise SystemExit(1)


def clean_name(raw: str, label: str) -> str:
    value = raw.strip().removeprefix("http://").removeprefix("https://").rstrip("/")
    if not value or value.startswith("/") or ".." in value or "/" in value or "\\" in value:
        fail(f"unsafe {label}: {raw}")
    if not SAFE_RE.fullmatch(value):
        fail(f"{label} may only contain letters, numbers, dots, underscores, and dashes")
    return value


def iso_now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")


def vault_dir(target: str, finding_id: str) -> Path:
    return repo_root() / "programs" / target / "vulns" / "poc" / finding_id


def metadata_path(target: str, finding_id: str) -> Path:
    return vault_dir(target, finding_id) / "metadata.json"


def read_metadata(target: str, finding_id: str) -> dict[str, Any]:
    path = metadata_path(target, finding_id)
    if not path.is_file():
        fail("evidence vault missing metadata.json")
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        fail(f"metadata.json invalid JSON: {exc.msg}")
    if not isinstance(data, dict):
        fail("metadata.json must be an object")
    data.setdefault("evidence", [])
    return data


def write_metadata(target: str, finding_id: str, data: dict[str, Any]) -> None:
    metadata_path(target, finding_id).write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def safe_source(raw: str) -> Path:
    path = Path(raw).expanduser().resolve()
    if not path.is_file():
        fail(f"evidence file not found: {raw}")
    return path


def max_evidence_bytes() -> int:
    raw = os.environ.get("EVIDENCE_VAULT_MAX_BYTES")
    if raw is None or raw.strip() == "":
        return DEFAULT_MAX_EVIDENCE_BYTES
    try:
        value = int(raw)
    except ValueError:
        fail("EVIDENCE_VAULT_MAX_BYTES must be an integer byte count")
    if value < 1:
        fail("EVIDENCE_VAULT_MAX_BYTES must be greater than zero")
    return value


def enforce_size_limit(source: Path) -> None:
    size = source.stat().st_size
    limit = max_evidence_bytes()
    if size > limit:
        fail(f"evidence file too large: {size} bytes exceeds limit of {limit} bytes")


def safe_dest_name(source: Path, kind: str, root: Path) -> str:
    stem = re.sub(r"[^A-Za-z0-9._-]+", "-", source.stem).strip(".-_") or kind
    suffix = re.sub(r"[^A-Za-z0-9.]", "", source.suffix)[:24]
    candidate = f"{kind}-{stem}{suffix}"
    dest = root / candidate
    count = 2
    while dest.exists():
        candidate = f"{kind}-{stem}-{count}{suffix}"
        dest = root / candidate
        count += 1
    return candidate


def command_init(args: argparse.Namespace) -> None:
    target = clean_name(args.target, "target")
    finding_id = clean_name(args.finding_id, "finding_id")
    if args.severity not in SEVERITIES:
        fail("severity must be one of: Info, Informational, Low, Medium, High, Critical")
    root = vault_dir(target, finding_id)
    root.mkdir(parents=True, exist_ok=True)
    metadata = {
        "target": target,
        "findingId": finding_id,
        "title": args.title,
        "severity": "Info" if args.severity == "Informational" else args.severity,
        "type": args.type,
        "endpoint": args.endpoint,
        "createdAt": iso_now(),
        "updatedAt": iso_now(),
        "evidence": [],
    }
    write_metadata(target, finding_id, metadata)
    for name, heading in [("reproduction.md", "Steps to Reproduce"), ("impact.md", "Impact")]:
        path = root / name
        if not path.exists():
            path.write_text(f"# {heading}\n\nTODO: Add validated, in-scope details.\n", encoding="utf-8")
    print(json.dumps({"ok": True, "vault": root.relative_to(repo_root()).as_posix(), "metadata": metadata}, indent=2))


def command_add(args: argparse.Namespace) -> None:
    target = clean_name(args.target, "target")
    finding_id = clean_name(args.finding_id, "finding_id")
    source = safe_source(args.file)
    enforce_size_limit(source)
    root = vault_dir(target, finding_id)
    if not root.is_dir():
        fail("evidence vault does not exist; run init first")
    metadata = read_metadata(target, finding_id)
    dest_name = safe_dest_name(source, args.kind, root)
    dest = root / dest_name
    shutil.copy2(source, dest)
    item = {
        "kind": args.kind,
        "path": dest_name,
        "originalName": source.name,
        "description": args.description or "",
        "addedAt": iso_now(),
    }
    evidence = metadata.setdefault("evidence", [])
    if not isinstance(evidence, list):
        fail("metadata evidence must be an array")
    evidence.append(item)
    metadata["updatedAt"] = iso_now()
    write_metadata(target, finding_id, metadata)
    print(json.dumps({"ok": True, "added": item, "vault": root.relative_to(repo_root()).as_posix()}, indent=2))


def command_list(args: argparse.Namespace) -> None:
    target = clean_name(args.target, "target")
    finding_id = clean_name(args.finding_id, "finding_id")
    root = vault_dir(target, finding_id)
    metadata = read_metadata(target, finding_id)
    print(json.dumps({"ok": True, "vault": root.relative_to(repo_root()).as_posix(), "metadata": metadata}, indent=2))


def main() -> None:
    parser = argparse.ArgumentParser(description="Create and manage a finding evidence vault.")
    sub = parser.add_subparsers(dest="command", required=True)
    init = sub.add_parser("init")
    init.add_argument("target")
    init.add_argument("finding_id")
    init.add_argument("--title", required=True)
    init.add_argument("--severity", required=True)
    init.add_argument("--type", required=True)
    init.add_argument("--endpoint", required=True)
    init.set_defaults(func=command_init)

    add = sub.add_parser("add")
    add.add_argument("target")
    add.add_argument("finding_id")
    add.add_argument("--file", required=True)
    add.add_argument("--kind", required=True, choices=sorted(KINDS))
    add.add_argument("--description", default="")
    add.set_defaults(func=command_add)

    list_cmd = sub.add_parser("list")
    list_cmd.add_argument("target")
    list_cmd.add_argument("finding_id")
    list_cmd.set_defaults(func=command_list)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
