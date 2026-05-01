# Scope Template — New Bug Bounty Target

```markdown
# [TARGET] — [PROGRAM] Scope

## Target Information
- **Target**: example.com
- **Program**: [hackerone/auto/offer]
- **Scope URL**: [link to program scope]
- **Rewards**: [bounty range, or "vulnerability based"]
- **Last Updated**: [date]

## In-Scope Targets

| Target | Type | Notes |
|--------|------|-------|
| *.example.com | domain | Wildcard domain |
| api.example.com | api | API endpoint |
| app.example.com | webapp | Main application |

## Out-of-Scope Targets

| Target | Reason |
|--------|--------|
| staging.example.com | Testing environment |
| dev.example.com | Development systems |
| lab.example.com | Isolated lab |

## Allowed Testing Methods

- [x] SQL Injection (SQLi)
- [x] Cross-Site Scripting (XSS)
- [x] IDOR / Authorization flaws
- [x] SSRF
- [x] Command Injection
- [x] API testing

## Excluded Techniques

- [ ] Denial of Service (DoS)
- [ ] Social Engineering
- [ ] Physical Attacks
- [ ] Logout/expired session testing

## Report Requirements

- Format: Markdown (HackerOne standard)
- Language: English / Spanish
- Initial report language: [language]
- Response time: [SLA]

## Critical Assets

- User database (PII, credentials)
- Payment processing (financial data)
- Admin panel (/admin, /dashboard)
- API endpoints (/api/v1, /graphql)

## Notes

- [date]: Initial scope review
- [Add observations about scope]
```

## Quick Checklist

- [ ] Read full scope document
- [ ] Identified all in-scope targets
- [ ] Identified out-of-scope targets
- [ ] Confirmed allowed techniques match my toolkit
- [ ] Located critical assets (high-value targets)
- [ ] Checked for program-specific rules
- [ ] Saved scope to `config/[target]-scope.md`