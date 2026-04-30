# Bug Bounty Report Templates

## Critical Severity Template

```markdown
## Title
[Critical] {Vulnerability Type} in {Location} Allows {Impact}

## Summary
A {vulnerability type} was discovered in {location} that allows an attacker to {impact}. The vulnerability affects {scope} and can be exploited without authentication / with low-privilege access.

## Step-by-step Reproduction
1. Navigate to {location}
2. Intercept request with Burp Suite
3. Modify {parameter} to {malicious payload}
4. Submit request
5. Observe {result}

## Impact
- {Direct impact 1}
- {Direct impact 2}
- Potential for {wider impact}

## Business Impact Analysis
**Financial Impact**: {amount} estimated exposure
**Data Breach Risk**: {PII/financial/health} data at risk
**Compliance**: {GDPR/HIPAA/PCI-DSS} violation exposure

## Mitigation
{Detailed fix with code examples}

## Evidence
{Screenshots, HTTP logs, PoC code}

## References
- CWE-{id}
- {CVE if applicable}
- {Similar public reports}
```

## High Severity Template

```markdown
## Title
[High] {Vulnerability Type} in {Location} Allows {Impact}

## Summary
A {vulnerability type} was found at {location}. By exploiting this, an attacker can {impact}.

## Steps to Reproduce
1. {Step 1}
2. {Step 2}
3. {Step 3}

## Impact
{What attacker achieves} → {Business damage}

## Business Impact
- **Financial**: {exposure}
- **Data**: {data at risk}
- **Compliance**: {violations}

## Mitigation
{Implementation details}

## Evidence
{Proof}
```

## Medium Severity Template

```markdown
## Title
[Medium] {Vulnerability Type} in {Location}

## Summary
{What was found}

## Steps to Reproduce
1. {Steps}

## Impact
{Security impact}

## Mitigation
{Fix}

## Evidence
{Logs/screenshots}
```

## Low Severity Template

```markdown
## Title
[Low] {Vulnerability Type} in {Location}

## Summary
{What was found}

## Impact
{Limited impact description}

## Mitigation
{Recommendation}

## Evidence
{Optional}
```