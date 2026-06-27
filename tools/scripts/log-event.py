#!/usr/bin/env python3
"""Append a Flight Recorder event to programs/{target}/activity/events.jsonl."""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


TARGET_RE = re.compile(r"^[A-Za-z0-9._-]+$")


def fail(message: str) -> None:
    print(f"[-] {message}", file=sys.stderr)
    raise SystemExit(1)


def clean_target(raw: str) -> str:
    target = raw.removeprefix("http://").removeprefix("https://").rstrip("/")
    if not target:
        fail("target cannot be empty")
    if target.startswith("/") or ".." in target or "/" in target or "\\" in target:
        fail(f"unsafe target name: {raw}")
    if not TARGET_RE.fullmatch(target):
        fail("target may only contain letters, numbers, dots, underscores, and dashes")
    return target


def parse_metadata(raw: str | None) -> dict[str, Any]:
    if raw is None or raw.strip() == "":
        return {}
    try:
        parsed = json.loads(raw)
    except json.JSONDecodeError as exc:
        fail(f"invalid metadata JSON: {exc.msg}")
    if not isinstance(parsed, dict):
        fail("metadata must be a JSON object")
    return parsed


def clean_output_path(raw: str) -> str:
    path = Path(raw)
    if path.is_absolute():
        fail("output path must be relative")
    parts = path.parts
    if not parts or any(part in ("", ".", "..") for part in parts):
        fail("output path must not contain empty, current, or parent segments")
    if any(part.startswith("~") for part in parts):
        fail("output path must be project-relative, not home-relative")
    return path.as_posix()


def iso_now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")


def repo_root() -> Path:
    return Path(__file__).resolve().parents[2]


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Append a structured Flight Recorder event for a target."
    )
    parser.add_argument("target", help="Target directory under programs/")
    parser.add_argument("phase", help="Workflow phase, e.g. recon, hunt, validate, report")
    parser.add_argument("action", help="Action name, e.g. subfinder, manual-note, nuclei")
    parser.add_argument("status", help="Action status, e.g. started, success, failed")
    parser.add_argument("message", nargs="?", default="", help="Short human-readable message")
    parser.add_argument("--command", help="Command that produced the event")
    parser.add_argument("--output-path", help="Repo-relative output path created or updated")
    parser.add_argument("--metadata", help='Additional JSON object, e.g. \'{"count": 12}\'')
    args = parser.parse_args()

    target = clean_target(args.target)
    metadata = parse_metadata(args.metadata)
    event = {
        "id": f"evt_{uuid.uuid4().hex}",
        "target": target,
        "phase": args.phase,
        "action": args.action,
        "status": args.status,
        "message": args.message,
        "timestamp": iso_now(),
        "metadata": metadata,
    }
    if args.command:
        event["command"] = args.command
    if args.output_path:
        event["outputPath"] = clean_output_path(args.output_path)

    activity_dir = repo_root() / "programs" / target / "activity"
    activity_dir.mkdir(parents=True, exist_ok=True)
    events_path = activity_dir / "events.jsonl"
    with events_path.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(event, ensure_ascii=False, separators=(",", ":")) + "\n")

    print(f"[+] logged event: {os.path.relpath(events_path, repo_root())}")


if __name__ == "__main__":
    main()
