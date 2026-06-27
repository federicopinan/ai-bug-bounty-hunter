#!/usr/bin/env python3
"""Validate target/action candidates against programs/{target}/scope.json."""

from __future__ import annotations

import argparse
import fnmatch
import json
import re
import sys
from pathlib import Path
from typing import Any
from urllib.parse import urlparse

TARGET_RE = re.compile(r"^[A-Za-z0-9._-]+$")
ALLOWED_ACTIONS = {"recon", "scan", "fuzz", "exploit", "validate", "report"}


def repo_root() -> Path:
    return Path(__file__).resolve().parents[2]


def clean_name(raw: str, label: str) -> str:
    value = raw.removeprefix("http://").removeprefix("https://").rstrip("/")
    if not value or value.startswith("/") or ".." in value or "/" in value or "\\" in value:
        raise ValueError(f"unsafe {label}: {raw}")
    if not TARGET_RE.fullmatch(value):
        raise ValueError(f"{label} may only contain letters, numbers, dots, underscores, and dashes")
    return value


def decision(**kwargs: Any) -> dict[str, Any]:
    base = {
        "allowed": False,
        "reason": "denied",
        "matchedRule": None,
        "action": None,
        "target": None,
        "host": None,
        "url": None,
    }
    base.update(kwargs)
    return base


def load_config(target: str) -> dict[str, Any]:
    path = repo_root() / "programs" / target / "scope.json"
    if not path.is_file():
        raise ValueError("scope.json missing")
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise ValueError(f"scope.json invalid JSON: {exc.msg}") from exc
    if not isinstance(data, dict):
        raise ValueError("scope.json must be an object")
    return data


def normalize_url_host(raw_url: str | None, raw_host: str | None) -> tuple[str | None, str | None, str | None]:
    if raw_url:
        if any(char in raw_url for char in "*?[]"):
            raise ValueError("url candidate must be concrete and cannot contain wildcard characters")
        parsed = urlparse(raw_url)
        if parsed.scheme not in {"http", "https"} or not parsed.netloc:
            raise ValueError("url must be an absolute http(s) URL")
        return raw_url, (parsed.hostname or "").lower(), parsed.path or "/"
    if raw_host:
        if any(char in raw_host for char in "*?[]"):
            raise ValueError("host candidate must be concrete and cannot contain wildcard characters")
        if "/" in raw_host or "\\" in raw_host or ".." in raw_host or raw_host.startswith("-"):
            raise ValueError("unsafe host")
        host = raw_host.lower().rstrip(".")
        if not re.fullmatch(r"[a-z0-9._-]+(?:\.[a-z0-9_-]+)*", host):
            raise ValueError("host contains unsupported characters")
        return None, host, None
    raise ValueError("either --url or --host is required")


def actions_for(config: dict[str, Any], rule: dict[str, Any]) -> set[str]:
    raw = rule.get("actions", config.get("defaultActions", config.get("allowedActions", [])))
    if not isinstance(raw, list) or not all(isinstance(item, str) for item in raw):
        return set()
    return {item for item in raw if item in ALLOWED_ACTIONS}


def out_of_scope_actions_for(rule: dict[str, Any]) -> set[str] | None:
    if "actions" not in rule:
        return None
    raw = rule.get("actions")
    if not isinstance(raw, list) or not all(isinstance(item, str) for item in raw):
        return set()
    return {item for item in raw if item in ALLOWED_ACTIONS}


def rule_matches(rule: dict[str, Any], *, host: str, url: str | None, path: str | None) -> bool:
    kind = rule.get("type", "host")
    pattern = rule.get("pattern")
    if not isinstance(kind, str) or not isinstance(pattern, str) or not pattern:
        return False
    if kind == "host":
        return fnmatch.fnmatchcase(host, pattern.lower())
    if kind == "url":
        return bool(url) and fnmatch.fnmatchcase(url, pattern)
    if kind == "path":
        return bool(path) and fnmatch.fnmatchcase(path, pattern)
    return False


def first_match(rules: Any, *, host: str, url: str | None, path: str | None, action: str, config: dict[str, Any]) -> dict[str, Any] | None:
    if not isinstance(rules, list):
        return None
    for index, raw_rule in enumerate(rules):
        if not isinstance(raw_rule, dict):
            continue
        if not rule_matches(raw_rule, host=host, url=url, path=path):
            continue
        if action in actions_for(config, raw_rule):
            rule = dict(raw_rule)
            rule.setdefault("index", index)
            return rule
    return None


def first_out_of_scope_match(rules: Any, *, host: str, url: str | None, path: str | None, action: str) -> dict[str, Any] | None:
    if not isinstance(rules, list):
        return None
    for index, raw_rule in enumerate(rules):
        if not isinstance(raw_rule, dict):
            continue
        if not rule_matches(raw_rule, host=host, url=url, path=path):
            continue
        actions = out_of_scope_actions_for(raw_rule)
        if actions is None or action in actions:
            rule = dict(raw_rule)
            rule.setdefault("index", index)
            return rule
    return None


def evaluate(target: str, action: str, url: str | None, host: str) -> dict[str, Any]:
    if action not in ALLOWED_ACTIONS:
        return decision(target=target, action=action, host=host, url=url, reason="unsupported action")
    config = load_config(target)
    parsed_path = urlparse(url).path or "/" if url else None

    out_rule = first_out_of_scope_match(config.get("outOfScope"), host=host, url=url, path=parsed_path, action=action)
    if out_rule:
        return decision(target=target, action=action, host=host, url=url, reason="matched out-of-scope rule", matchedRule=out_rule)

    in_rule = first_match(config.get("inScope"), host=host, url=url, path=parsed_path, action=action, config=config)
    if in_rule:
        return decision(allowed=True, target=target, action=action, host=host, url=url, reason="matched in-scope rule", matchedRule=in_rule)

    return decision(target=target, action=action, host=host, url=url, reason="no matching in-scope rule for host/url/action")


def main() -> None:
    parser = argparse.ArgumentParser(description="Gate bug bounty automation with machine-readable target scope.")
    parser.add_argument("target")
    parser.add_argument("--url")
    parser.add_argument("--host")
    parser.add_argument("--action", required=True, choices=sorted(ALLOWED_ACTIONS))
    parser.add_argument("--json", action="store_true", help="Emit JSON (default).")
    args = parser.parse_args()

    try:
        target = clean_name(args.target, "target")
        url, host, _ = normalize_url_host(args.url, args.host)
        result = evaluate(target, args.action, url, host or "")
    except ValueError as exc:
        result = decision(action=args.action, target=args.target, url=args.url, host=args.host, reason=str(exc))

    print(json.dumps(result, indent=2, sort_keys=True))
    raise SystemExit(0 if result["allowed"] else 1)


if __name__ == "__main__":
    main()
