# Target Notes Template

```markdown
# [TARGET] — Notes

## Overview
- **Program**: [program name]
- **Target**: [target domain/IP]
- **Started**: [date]
- **Status**: 🔴 In Progress

## Program Details
- **Scope**: [link or summary]
- **Rewards**: [bounty range]
- **Last Hunt**: [date]

## Recon Data

### Subdomains
```
[subdomain list]
```

### Technology Stack
```
[tech: nginx, php 7.4, mysql, wordpress, etc.]
```

### Discovered Endpoints
```
[endpoint list]
```

## Vulnerabilities Found

### P0 — Critical
**IDOR in invoice download**
- Location: `/api/invoices/{id}/download`
- Status: Validated → Reported
- Report: [link]

### P1 — High
**Stored XSS in profile bio**
- Location: `/settings/profile`
- Status: Testing
- PoC: `"><script>alert(1)</script>`

### P2 — Medium
-

## Session Timeline

| Date | Activity |
|------|----------|
| 2026-04-30 | Target init, basic recon |
| 2026-05-01 | Found IDOR, validating |

## TODO

- [ ] Complete full port scan
- [ ] Test password reset flow
- [ ] Check for GraphQL endpoints
- [ ] Review JavaScript for secrets

## References

- [Program Scope](link)
- [Similar reports](link)
- [Vulnerability writeups](link)

---

*Last updated: [timestamp]*
```