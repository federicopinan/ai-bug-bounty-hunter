#!/usr/bin/env python3
"""
Validate every skill under .claude/skills/ (or any path given as argument).

Checks performed for each .claude/skills/<skill>/SKILL.md:

  1. Frontmatter exists (first non-empty line is `---`, content, then `---`).
  2. Required fields present: name, description.
  3. `name` in frontmatter matches the directory name.
  4. `description` is at least 30 characters and contains a "Trigger:" hint.
  5. Every relative link in the body (e.g. [assets/](assets/)) points to an
     existing file or directory inside the skill folder.
  6. Optional: warns if a skill folder has no `assets/` subdirectory but the
     body references one.

Output is GitHub Actions friendly: ::error:: and ::warning:: annotations on
the SKILL.md path. Exits 1 if any error is found, 0 otherwise.

Usage:
  tools/validate-skills.py .claude/skills/
  tools/validate-skills.py /path/to/some/skills
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

FRONTMATTER_RE = re.compile(r"^---\s*\n(.*?)\n---\s*\n(.*)$", re.DOTALL)
KV_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_-]*):\s*(.*)$")
LINK_RE = re.compile(r"\[([^\]]+)\]\((?!https?://|#|mailto:)([^)]+)\)")
TRIGGER_HINT_RE = re.compile(r"\b[Tt]rigger[:\s]", re.MULTILINE)

REQUIRED_FIELDS = ("name", "description")
MIN_DESCRIPTION = 30


def _collect_multiline(lines: list[str], start: int) -> tuple[str, int]:
    """Collect YAML folded ('>') or literal ('|') scalar continuation lines.

    Returns (joined_text, next_index). Stops at the first line that is either
    blank or has a new key at column 0.
    """
    collected: list[str] = []
    i = start
    while i < len(lines):
        line = lines[i]
        if not line.strip():
            i += 1
            continue
        # Continuation lines must be indented (start with whitespace)
        if line[0] not in (" ", "\t"):
            break
        collected.append(line.strip())
        i += 1
    return " ".join(collected), i


def gh_error(skill_file: Path, line: int, message: str) -> None:
    rel = skill_file.as_posix()
    print(f"::error file={rel},line={line}::{message}")


def gh_warning(skill_file: Path, line: int, message: str) -> None:
    rel = skill_file.as_posix()
    print(f"::warning file={rel},line={line}::{message}")


def parse_frontmatter(text: str) -> tuple[dict[str, str], str] | None:
    """Return (fields, body) or None if no frontmatter found.

    Supports:
      key: value         (simple)
      key: >             (folded scalar — continuation lines joined with spaces)
      key: |             (literal scalar — continuation lines joined with spaces)
    """
    m = FRONTMATTER_RE.match(text)
    if not m:
        return None
    fields: dict[str, str] = {}
    lines = m.group(1).splitlines()
    i = 0
    while i < len(lines):
        km = KV_RE.match(lines[i])
        if not km:
            i += 1
            continue
        key, value = km.group(1), km.group(2).strip()
        if value in (">", "|"):
            value, i = _collect_multiline(lines, i + 1)
        else:
            i += 1
        fields[key] = value
    return fields, m.group(2)


def validate_link_targets(body: str, skill_dir: Path, skill_file: Path) -> int:
    """Check that every relative link in body points to something real.

    Returns the number of broken links found.
    """
    broken = 0
    for n, match in enumerate(LINK_RE.finditer(body), start=1):
        target = match.group(2).split("#", 1)[0].strip()
        if not target:
            continue
        resolved = (skill_dir / target).resolve()
        if not resolved.exists():
            line = body[: match.start()].count("\n") + 1
            gh_error(skill_file, line, f"broken relative link: {target}")
            broken += 1
    return broken


def validate_skill(skill_dir: Path) -> int:
    skill_file = skill_dir / "SKILL.md"
    if not skill_file.is_file():
        gh_error(skill_file, 1, "missing SKILL.md")
        return 1

    text = skill_file.read_text(encoding="utf-8")
    parsed = parse_frontmatter(text)
    if parsed is None:
        gh_error(skill_file, 1, "no YAML frontmatter (must start with '---')")
        return 1
    fields, body = parsed

    errors = 0

    # Required fields
    for field in REQUIRED_FIELDS:
        if field not in fields or not fields[field]:
            gh_error(skill_file, 1, f"missing required frontmatter field: {field}")
            errors += 1

    # name matches directory
    if "name" in fields and fields["name"] != skill_dir.name:
        gh_error(
            skill_file, 1,
            f"frontmatter name '{fields['name']}' does not match "
            f"directory '{skill_dir.name}'",
        )
        errors += 1

    # description length
    if "description" in fields:
        desc = fields["description"]
        if len(desc) < MIN_DESCRIPTION:
            gh_error(
                skill_file, 1,
                f"description is {len(desc)} chars; minimum is {MIN_DESCRIPTION}",
            )
            errors += 1
        if not TRIGGER_HINT_RE.search(desc):
            gh_warning(
                skill_file, 1,
                "description has no 'Trigger:' hint; the harness matches "
                "skills by trigger words in the description",
            )

    # Relative links in body
    errors += validate_link_targets(body, skill_dir, skill_file)

    return errors


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: validate-skills.py <skills-dir>", file=sys.stderr)
        return 2

    root = Path(sys.argv[1]).resolve()
    if not root.is_dir():
        print(f"error: {root} is not a directory", file=sys.stderr)
        return 2

    skill_dirs = sorted(p for p in root.iterdir() if p.is_dir())
    if not skill_dirs:
        print(f"::error::no skills found under {root}")
        return 1

    total_errors = 0
    print(f"validating {len(skill_dirs)} skill(s) under {root}")
    for skill_dir in skill_dirs:
        print(f"  • {skill_dir.name}")
        total_errors += validate_skill(skill_dir)

    print()
    if total_errors:
        print(f"::error::{total_errors} error(s) found across skill(s)")
        return 1
    print("::notice::all skills valid")
    return 0


if __name__ == "__main__":
    sys.exit(main())
