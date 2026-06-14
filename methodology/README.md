# Bug Bounty Methodology Layer

This directory turns the workspace into a repeatable manual testing system for real P1/P2 findings. Use it after recon has mapped the attack surface and before writing reports.

## Workflow Fit

```text
Recon -> Hunt -> Validate -> Report
          ^        ^
          |        |
          methodology playbooks
```

- **Recon** maps domains, endpoints, technologies, APIs, and exposed assets.
- **Hunt** uses the playbooks to test high-impact bug classes manually.
- **Validate** proves exploitability and business impact with minimal safe evidence.
- **Report** converts validated impact into a triage-friendly submission.

## Files

| File | Use When |
|---|---|
| `auth-matrix.md` | Any target with login, roles, teams, orgs, tenants, API keys, exports, or billing |
| `idor-bola-playbook.md` | Testing object-level authorization across users, roles, orgs, GraphQL, mobile, and old APIs |
| `account-takeover-playbook.md` | Testing reset flows, email changes, MFA, sessions, OAuth linking, and identity confusion |
| `business-logic-playbook.md` | Testing payments, coupons, workflows, race conditions, limits, and product rule bypasses |
| `oauth-sso-playbook.md` | Testing OAuth, SAML/SSO, redirect URI, state, account linking, and tenant enforcement |
| `api-testing-playbook.md` | Testing REST, GraphQL, mobile APIs, version drift, mass assignment, and schema abuse |

## Recommended Order

1. Read the program scope and rules.
2. Create `programs/{target}/auth-matrix.md` from `auth-matrix.md`.
3. Create controlled test accounts and tenants.
4. Capture baseline requests with an admin/owner account.
5. Replay requests across the auth matrix.
6. Pick the playbook that matches the strongest signal.
7. Validate only with controlled data and minimal proof.
8. Write the report only after impact is confirmed.

## P1/P2 Bias

Prioritize targets and flows with:

- Multi-tenant SaaS data
- Team/org roles
- Billing, invoices, plans, coupons, or payment methods
- Private files, exports, reports, or attachments
- API keys, webhooks, integrations, and connected apps
- OAuth/SSO or enterprise identity
- Mobile or legacy APIs different from the web UI

Avoid spending too long on static pages, marketing sites, and UI-only issues unless recon shows exposed admin panels, secrets, or sensitive files.

## Safety Boundaries

- Test only in-scope systems.
- Prefer self-owned accounts and records.
- Do not dump real user data.
- Do not persist access, install payloads, or damage data.
- Stop when you have enough proof for impact.
- Redact tokens, cookies, secrets, and PII from evidence.
