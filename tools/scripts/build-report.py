#!/usr/bin/env python3
"""Build a Markdown report draft from an evidence vault."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

SAFE_RE = re.compile(r"^[A-Za-z0-9._-]+$")


def repo_root() -> Path:
    return Path(__file__).resolve().parents[2]


def clean_name(raw: str, label: str) -> str:
    value = raw.strip().removeprefix("http://").removeprefix("https://").rstrip("/")
    if not value or value.startswith("/") or ".." in value or "/" in value or "\\" in value:
        raise ValueError(f"unsafe {label}: {raw}")
    if not SAFE_RE.fullmatch(value):
        raise ValueError(f"{label} may only contain letters, numbers, dots, underscores, and dashes")
    return value


def read_text_or_missing(path: Path, label: str) -> str:
    if not path.is_file():
        return f"TODO: Missing {label}. Add `{path.name}` to the evidence vault."
    text = path.read_text(encoding="utf-8").strip()
    return text or f"TODO: {label} is empty. Add validated, in-scope details."


def load_metadata(root: Path) -> dict[str, Any]:
    path = root / "metadata.json"
    if not path.is_file():
        raise ValueError("evidence vault missing metadata.json")
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise ValueError("metadata.json must be an object")
    return data


def validate_strict(root: Path, meta: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    for key in ["title", "severity", "type", "endpoint"]:
        if not isinstance(meta.get(key), str) or not meta[key].strip():
            errors.append(f"metadata.{key} is required")
    evidence = meta.get("evidence")
    if not isinstance(evidence, list) or not evidence:
        errors.append("metadata.evidence must contain at least one evidence item")
    else:
        for index, item in enumerate(evidence):
            if not isinstance(item, dict):
                errors.append(f"metadata.evidence[{index}] must be an object")
                continue
            item_path = item.get("path")
            if not isinstance(item_path, str) or not item_path.strip():
                errors.append(f"metadata.evidence[{index}].path is required")
                continue
            evidence_path = (root / item_path).resolve()
            try:
                evidence_path.relative_to(root.resolve())
            except ValueError:
                errors.append(f"metadata.evidence[{index}].path escapes the vault")
                continue
            if not evidence_path.is_file():
                errors.append(f"metadata.evidence[{index}].path does not exist: {item_path}")
    for filename, label in [("reproduction.md", "reproduction"), ("impact.md", "impact")]:
        path = root / filename
        if not path.is_file() or not path.read_text(encoding="utf-8").strip():
            errors.append(f"{label} file is required and cannot be empty")
    return errors


def safe_report_output(target: str, finding_id: str) -> Path:
    reports = repo_root() / "reports"
    reports.mkdir(parents=True, exist_ok=True)
    repo_real = repo_root().resolve()
    reports_real = reports.resolve()
    try:
        reports_real.relative_to(repo_real)
    except ValueError as exc:
        raise ValueError("reports directory resolves outside repository") from exc
    out = reports / f"{target}-{finding_id}.md"
    out_resolved = out.resolve() if out.exists() else reports_real / out.name
    try:
        out_resolved.relative_to(reports_real)
    except ValueError as exc:
        raise ValueError("report output path escapes reports directory") from exc
    return out


def build_markdown(target: str, finding_id: str) -> str:
    root = repo_root() / "programs" / target / "vulns" / "poc" / finding_id
    if not root.is_dir():
        raise ValueError("evidence vault not found")
    meta = load_metadata(root)
    title = meta.get("title") or "TODO: Missing finding title"
    severity = meta.get("severity") or "TODO"
    vuln_type = meta.get("type") or "TODO"
    endpoint = meta.get("endpoint") or "TODO: Missing affected endpoint"
    evidence = meta.get("evidence", [])
    if not isinstance(evidence, list):
        evidence = []

    evidence_lines = []
    if evidence:
        for item in evidence:
            if not isinstance(item, dict):
                continue
            path = item.get("path", "unknown")
            kind = item.get("kind", "other")
            desc = item.get("description") or "No description provided."
            evidence_lines.append(f"- `{path}` ({kind}) — {desc}")
    else:
        evidence_lines.append("- TODO: No evidence files registered in metadata.json.")

    return f"""## Title
[{severity}] {vuln_type} in {endpoint} — {title}

## Summary
TODO: Summarize only the behavior proven by the evidence vault. Do not invent exploit details.

## Steps to Reproduce
{read_text_or_missing(root / 'reproduction.md', 'Steps to Reproduce')}

## Impact
{read_text_or_missing(root / 'impact.md', 'Impact')}

## Evidence
Target: `{target}`

Finding ID: `{finding_id}`

Vault: `programs/{target}/vulns/poc/{finding_id}/`

{chr(10).join(evidence_lines)}

## Mitigation
TODO: Provide a specific fix tied to the validated root cause.

## References
- TODO: Add CWE/OWASP/vendor references relevant to {vuln_type}.
"""


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate a Markdown report draft from a finding evidence vault.")
    parser.add_argument("target")
    parser.add_argument("finding_id")
    parser.add_argument("--stdout", action="store_true")
    parser.add_argument("--strict", action="store_true", help="Fail if required metadata, reproduction/impact text, or evidence files are missing.")
    args = parser.parse_args()
    try:
        target = clean_name(args.target, "target")
        finding_id = clean_name(args.finding_id, "finding_id")
        if args.strict:
            root = repo_root() / "programs" / target / "vulns" / "poc" / finding_id
            if not root.is_dir():
                raise ValueError("evidence vault not found")
            strict_errors = validate_strict(root, load_metadata(root))
            if strict_errors:
                raise ValueError("strict report validation failed: " + "; ".join(strict_errors))
        markdown = build_markdown(target, finding_id)
        if args.stdout:
            print(markdown)
            return
        out = safe_report_output(target, finding_id)
        out.write_text(markdown, encoding="utf-8")
        print(json.dumps({"ok": True, "report": out.relative_to(repo_root()).as_posix()}, indent=2))
    except (ValueError, json.JSONDecodeError) as exc:
        print(json.dumps({"ok": False, "error": str(exc)}, indent=2), file=sys.stderr)
        raise SystemExit(1)


if __name__ == "__main__":
    main()
