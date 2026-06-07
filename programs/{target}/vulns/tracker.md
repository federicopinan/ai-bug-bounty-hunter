# Findings Tracker

## Usage

Copy this file to `programs/{target}/vulns/tracker.md` for each target.

---

# [Target Name] — Findings Tracker

## Program Info

| Field | Value |
|---|---|
| **Target** | [target.com] |
| **Program** | [HackerOne / Bugcrowd / Intigriti / Immunefi / self-hosted] |
| **Scope URL** | [link to program policy] |
| **Scope** | [in-scope assets] |
| **Rewards** | [reward range] |
| **Started** | [YYYY-MM-DD] |

---

## Summary Stats

| Severity | Total | Validated | Reported | Duplicates | Closed |
|---|---|---|---|---|---|
| Critical | 0 | 0 | 0 | 0 | 0 |
| High | 0 | 0 | 0 | 0 | 0 |
| Medium | 0 | 0 | 0 | 0 | 0 |
| Low | 0 | 0 | 0 | 0 | 0 |
| Informational | 0 | 0 | 0 | 0 | 0 |

---

## P0 — Critical

### [Finding Title]

| Field | Value |
|---|---|
| **Endpoint** | |
| **Status** | [NEW / VALIDATED / REPORTED / DUPLICATE / CLOSED / INVALID] |
| **Severity** | Critical |
| **CVSS** | [vector] → [score] |
| **Found Date** | [YYYY-MM-DD] |
| **Reported Date** | [YYYY-MM-DD / N/A] |
| **Bounty** | [$amount / N/A] |
| **Platform ID** | [H1-123456 / N/A] |

**Description**
[One sentence — what an attacker can do]

**Steps to Reproduce**
1. [Step]
2. [Step]

**Impact**
[Business impact, quantified]

**Evidence**
- [Link to PoC file]
- [Link to screenshot]

**HackerOne / Platform Link**: [URL]

**Notes**
-

---

## P1 — High

### [Finding Title]

| Field | Value |
|---|---|
| **Endpoint** | |
| **Status** | [NEW / VALIDATED / REPORTED / DUPLICATE / CLOSED / INVALID] |
| **Severity** | High |
| **CVSS** | [vector] → [score] |
| **Found Date** | [YYYY-MM-DD] |
| **Reported Date** | [YYYY-MM-DD / N/A] |
| **Bounty** | [$amount / N/A] |
| **Platform ID** | [H1-123456 / N/A] |

**Description**
[One sentence]

**Impact**
[Business impact]

**Evidence**
- [PoC]

---

## P2 — Medium

### [Finding Title]

| Field | Value |
|---|---|
| **Endpoint** | |
| **Status** | [NEW / VALIDATED / REPORTED / DUPLICATE / CLOSED / INVALID] |
| **Severity** | Medium |
| **CVSS** | [vector] → [score] |
| **Found Date** | [YYYY-MM-DD] |
| **Reported Date** | [YYYY-MM-DD / N/A] |
| **Bounty** | [$amount / N/A] |
| **Platform ID** | [H1-123456 / N/A] |

---

## P3 — Low

### [Finding Title]

| Field | Value |
|---|---|
| **Endpoint** | |
| **Status** | [NEW / VALIDATED / REPORTED / DUPLICATE / CLOSED / INVALID] |
| **Severity** | Low |
| **Found Date** | [YYYY-MM-DD] |
| **Reported Date** | [YYYY-MM-DD / N/A] |

---

## P4 — Informational

### [Finding Title]

| Field | Value |
|---|---|
| **Endpoint** | |
| **Status** | [NEW / VALIDATED / REPORTED / DUPLICATE / CLOSED / INVALID] |
| **Severity** | Informational |
| **Found Date** | [YYYY-MM-DD] |

---

## False Positives / Rejected

| Finding | Reason | Date |
|---|---|---|
| [Title] | [Why rejected] | [YYYY-MM-DD] |
| | | |

---

## Status Legend

| Status | Meaning |
|---|---|
| `NEW` | Found, not validated yet |
| `VALIDATED` | Confirmed exploitable |
| `REPORTED` | Submitted to platform |
| `DUPLICATE` | Already reported by another researcher |
| `CLOSED` | Triaged, waiting for fix |
| `RESOLVED` | Fixed by program |
| `INVALID` | Not a valid vulnerability |

---

## Workflow Commands

```
/validate [finding]                                      → Validate before reporting
/report [finding]                                        → Generate report draft
/track [finding] --status=REPORTED --id=H1-XXX          → Update status
```

---

## Activity Log

| Date | Finding | Action | Notes |
|---|---|---|---|
| YYYY-MM-DD | [finding] | [action] | [notes] |
| | | | |

---

## TODO

- [ ] Validate [P1 finding]
- [ ] Write report for [P0 finding]
- [ ] Check duplicates for [endpoint]
- [ ] Re-test [resolved finding]
- [ ] Follow up on [H1-XXX]

---

## Tips

- Run `/validate` before spending time on a report
- Check duplicate reports before testing similar endpoints
- Use sibling endpoint enumeration (Rule 10)
- After finding A, hunt for B within 20 minutes (Rule 11)
