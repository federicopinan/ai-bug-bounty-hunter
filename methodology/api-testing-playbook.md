# API Testing Playbook

## Goal

Find high-impact API flaws across REST, GraphQL, mobile, and legacy endpoints: BOLA, mass assignment, privilege escalation, schema abuse, excessive data exposure, version drift, and inconsistent authorization.

## Best Targets

| Target Pattern | Why It Matters |
|---|---|
| Public web app with JSON APIs | Rich attack surface |
| Mobile apps | Separate endpoints and weaker assumptions |
| GraphQL APIs | Flexible queries can expose hidden objects |
| Legacy `/v1/` or beta APIs | Older auth and validation paths |
| Admin/internal-looking endpoints | Often hidden but reachable |
| Bulk/import/export endpoints | High data impact |

## Required Test Accounts/Data

- Auth matrix accounts and tenants.
- API token if supported.
- Captured web and mobile traffic.
- OpenAPI/Swagger/GraphQL schema if exposed.
- Controlled resources in each tenant.

## 30-Minute Triage

| Time | Action | Signal |
|---:|---|---|
| 0-5 | Enumerate API roots and schemas | `/api`, `/graphql`, `/swagger`, mobile endpoints |
| 5-10 | Capture sensitive requests | IDs, roles, tenant fields, hidden fields |
| 10-15 | Replay across auth matrix | Auth inconsistency |
| 15-20 | Test mass assignment | Server accepts forbidden fields |
| 20-25 | Test GraphQL/bulk/export | Excessive data or BOLA |
| 25-30 | Validate controlled impact | Unauthorized read/write or data exposure |

## Manual Testing Workflow

1. Map API roots from browser, mobile, JS files, docs, and recon output.
2. Capture requests for create/read/update/delete flows.
3. Identify auth headers, cookies, tenant IDs, object IDs, and role fields.
4. Replay requests as other actors from `auth-matrix.md`.
5. Test hidden fields and mass assignment.
6. Compare web, mobile, GraphQL, and old API behavior.
7. Validate impact with controlled data only.

## High-Signal Checks

### API Discovery

- `/api/`
- `/api/v1/`, `/api/v2/`, `/v1/`, `/v2/`
- `/graphql`, `/graphiql`, `/playground`
- `/swagger.json`, `/openapi.json`, `/api-docs`
- mobile API hosts
- admin or internal prefixes
- JS bundle endpoint references

### Authorization Consistency

- Same endpoint works with cookie but not bearer token, or inverse.
- Web UI denies but API allows.
- Mobile API allows action blocked on web API.
- Old API version lacks tenant check.
- Bulk endpoint skips per-object auth.

### Mass Assignment

Add or modify fields in create/update requests:

- `role`
- `is_admin`
- `permissions`
- `org_id`
- `owner_id`
- `plan_id`
- `price_id`
- `verified`
- `mfa_enabled`
- `email_verified`
- `status`

Bug signal: server stores or acts on a field that should be server-controlled.

### Excessive Data Exposure

- API returns hidden fields not shown in UI.
- Search endpoint returns other tenants.
- List endpoint ignores tenant or role filters.
- Export endpoint includes more columns than UI.
- Error response leaks emails, IDs, paths, or secrets.

### GraphQL

- Introspection enabled in production.
- `node(id:)` returns cross-tenant objects.
- Nested queries bypass field-level auth.
- Mutations accept forbidden nested fields.
- Batch queries bypass rate/authorization assumptions.
- Error messages reveal object existence.

### Bulk and Import/Export

- Bulk update accepts IDs from multiple tenants.
- Import assigns resources to attacker-chosen org.
- Export job can be polled/downloaded by another actor.
- Delete/archive bulk action skips per-object authorization.
- CSV/JSON import triggers privileged state changes.

### API Tokens and Keys

- Token scopes not enforced.
- User token works after role downgrade/removal.
- API key can access another org.
- Keys can be listed/revoked by low-privilege user.
- Token prefix or ID leaks enough to enumerate metadata.

## Evidence to Capture

- Endpoint inventory.
- Actor/token used.
- Original and replay request.
- Forbidden field or object ID changed.
- Response proving unauthorized read/write.
- Before/after state for mutations.
- Comparison across web/mobile/legacy if relevant.

## Validation Rules

A valid API finding needs:

- Server-side acceptance or disclosure.
- Clear authorization, validation, or data minimization failure.
- Controlled proof of sensitive impact.
- Reproducible request sequence.

## Kill Criteria

Stop if:

- API consistently enforces auth across actors, clients, and versions.
- Server ignores forbidden fields.
- GraphQL field/object resolvers enforce tenant and role checks.
- Bulk/export endpoints enforce per-object authorization.
- No sensitive fields are exposed beyond UI/product needs.

## Severity Guidance

| Finding | Typical Severity |
|---|---|
| Cross-tenant API read/write | P1/P2 |
| Mass assignment to admin/verified/billing fields | P1/P2 |
| API key scope bypass | P1/P2 |
| GraphQL exposes private objects | P1/P2 |
| Excessive metadata only | P3/P2 depending sensitivity |

## Report Notes

Good title format:

`[High] Mobile API v1 Missing Tenant Authorization Allows Cross-Organization Project Access`

State which client/version is affected and whether newer APIs behave correctly.
