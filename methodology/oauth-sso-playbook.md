# OAuth / SSO Playbook

## Goal

Find identity and authorization bugs in OAuth, OIDC, SAML, and enterprise SSO flows. Focus on account takeover, tenant bypass, redirect abuse with impact, account linking confusion, and SSO enforcement failures.

## Best Targets

| Target Pattern | Why It Matters |
|---|---|
| Social login plus password login | Linking confusion risk |
| Enterprise SSO/SAML | Tenant/domain enforcement is high impact |
| Multiple OAuth providers | Provider identity mismatch risk |
| Invite + SSO onboarding | Pending account states are fragile |
| Mobile OAuth flow | Redirect and token handling may differ |
| Custom redirect domains | Open redirect and callback abuse potential |

## Required Test Accounts/Data

- Local account with controlled email.
- OAuth provider account with controlled email.
- Second controlled account using different email.
- Two organizations/tenants if possible.
- SSO test tenant only if explicitly allowed.
- Captured authorization and callback requests.

## 30-Minute Triage

| Time | Action | Signal |
|---:|---|---|
| 0-5 | Map providers and callback URLs | Multiple identity paths |
| 5-10 | Test `state` handling | Missing or reusable state |
| 10-15 | Test account linking rules | Link without re-auth or verified email |
| 15-20 | Test tenant/domain enforcement | Wrong tenant accepted |
| 20-25 | Test redirect URI validation | Weak matching with impact |
| 25-30 | Validate controlled identity impact | Login/link/bypass succeeds |

## Manual Testing Workflow

1. Capture normal OAuth/SSO login.
2. Identify `client_id`, `redirect_uri`, `state`, `nonce`, `code`, and callback path.
3. Test replay and cross-session use of `state` and callbacks.
4. Test account linking from authenticated and unauthenticated states.
5. Test verified vs unverified provider email behavior.
6. Test tenant/domain restrictions.
7. Validate only with accounts and tenants you control.

## High-Signal Checks

### State and CSRF

- Missing `state`.
- Static or reusable `state`.
- `state` not bound to browser session.
- Callback accepted after logout.
- Callback accepted in different account session.

Bug impact must go beyond theoretical CSRF: prove account linking, login confusion, or sensitive state change.

### Redirect URI

- Partial matching such as prefix/suffix wildcard.
- Open redirect chained through allowed domain.
- `http` accepted where `https` required.
- Subdomain takeover candidate in allowed redirect.
- Mobile deep link accepts arbitrary host/path.

Report only when it enables token/code theft, account linking, or another concrete impact.

### Account Linking

- Link OAuth provider without current password/MFA/re-auth.
- Link provider to wrong logged-in account.
- Link based only on email address.
- Accept unverified provider email.
- Link attacker provider to victim test account.

### Tenant / Domain Enforcement

- Login to enterprise tenant with personal account.
- Join SSO-enforced org without SSO.
- Change email domain after joining SSO org.
- Access org after SSO removal or domain change.
- Bypass SAML/OIDC group/role mapping.

### OIDC / JWT Claims

- Trusts mutable claims without validation.
- Missing issuer/audience validation.
- Uses email as unique identity across providers.
- Accepts unverified email as verified identity.
- Role or tenant claim can be influenced by wrong provider config.

### Logout and Session

- Local logout does not clear OAuth-linked session.
- SSO deprovisioning does not remove app access.
- Password login remains enabled when SSO-only mode is expected.
- Old sessions survive MFA/SSO enforcement.

## Evidence to Capture

- OAuth/SSO flow diagram.
- Authorization URL and callback request.
- Actor account/session before and after.
- Provider account email verification state.
- Tenant/role mapping expected vs actual.
- Minimal proof of login/link/bypass with controlled accounts.

## Validation Rules

Valid findings usually prove:

- Account takeover or unauthorized account linking.
- Login as wrong identity or wrong tenant.
- Bypass of SSO-only enforcement.
- Redirect weakness leading to actual code/token compromise.

Open redirect alone is usually low unless chained to OAuth impact.

## Kill Criteria

Stop if:

- `state` and `nonce` are random, single-use, and session-bound.
- Redirect URI matching is exact and provider-enforced.
- Account linking requires authenticated user consent plus re-auth.
- Email verification and issuer/audience checks are correct.
- SSO tenant/domain restrictions are enforced server-side.

## Severity Guidance

| Finding | Typical Severity |
|---|---|
| OAuth linking causes full account takeover | P1 |
| SSO-only tenant can be accessed without SSO | P1/P2 |
| Redirect URI weakness leaks auth code/token | P1/P2 |
| Missing state with account linking impact | P2 |
| Open redirect only, no OAuth impact | Low/P3 depending program |

## Report Notes

Good title format:

`[High] OAuth Account Linking Accepts Unverified Email Allowing Account Takeover`

Include provider, callback, identity state, and controlled victim proof.
