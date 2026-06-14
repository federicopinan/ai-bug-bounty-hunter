# Evidence Log

Use one row per evidence artifact. Keep entries sanitized and reproducible. Never commit real user PII, secrets, session cookies, or excessive data.

## Target

- Program:
- Target:
- Date:
- Evidence directory:

## Evidence

| ID | Finding / Lead | Artifact Path | Type | Sanitized? | Description | Repro Step |
|---|---|---|---|---|---|---|
| EV-001 | | | HTTP request/response | No | | |
| EV-002 | | | Screenshot | No | | |
| EV-003 | | | PoC output | No | | |

## Safety Reminders

- Capture the minimum data needed to prove impact.
- Redact cookies, tokens, passwords, emails, phone numbers, addresses, and unrelated user data.
- Keep raw exploit output in `programs/<target>/vulns/poc/` or a finding-specific evidence folder.
- Link evidence IDs from the finding draft and auth matrix.
