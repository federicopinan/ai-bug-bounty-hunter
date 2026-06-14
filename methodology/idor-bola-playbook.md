# IDOR / BOLA Playbook

## Goal

Find server-side authorization failures where one actor can access or modify another actor's object by changing an identifier. Focus on real impact: cross-tenant records, private files, invoices, exports, role changes, API keys, and sensitive user data.

## Best Targets

| Target Pattern | Why It Matters |
|---|---|
| B2B SaaS with organizations/workspaces | Cross-tenant bugs often become P1/P2 |
| REST APIs with numeric or UUID object IDs | Direct ID swaps are easy to test |
| GraphQL APIs with global object IDs | Resolver-level auth is often inconsistent |
| Mobile APIs | Often expose endpoints hidden from web UI |
| Export/download/report systems | Authorization may be checked at job creation but not download |
| Legacy API versions | Old handlers may miss newer auth checks |

## Required Test Accounts/Data

- User A: Org 1 owner/admin
- User B: Org 1 member/viewer
- User C: Org 2 owner/admin
- Optional: removed user, expired token, API-only token
- Controlled resources in both orgs: project, file, invoice, export, invite, API key, integration

Use `auth-matrix.md` to track actors, resources, and replay results.

## 30-Minute Triage

| Time | Action | Signal |
|---:|---|---|
| 0-5 | Capture 5 sensitive admin requests | Object IDs in path/body/query |
| 5-10 | Replay as same-org member | Admin-only action works |
| 10-15 | Swap Org 1 IDs into Org 2 session | Cross-tenant read/write |
| 15-20 | Test export/download endpoints | File or report leaks |
| 20-25 | Test GraphQL/mobile/old API equivalents | Inconsistent auth |
| 25-30 | Validate smallest safe impact | Controlled private data exposed or changed |

## Manual Testing Workflow

1. Create equivalent resources in Org 1 and Org 2.
2. Capture legitimate requests as User A.
3. Mark every identifier:
   - `user_id`
   - `account_id`
   - `org_id`
   - `team_id`
   - `project_id`
   - `file_id`
   - `invoice_id`
   - `export_id`
   - `invite_id`
   - GraphQL `id` / `nodeId`
4. Replay the same request with User B, User C, anonymous, removed user, and expired token.
5. Swap only one identifier at a time.
6. Record expected vs actual result.
7. Validate impact using only controlled records.

## High-Signal Checks

### REST ID Swaps

- `GET /api/users/{user_id}`
- `PATCH /api/users/{user_id}`
- `GET /api/orgs/{org_id}/members`
- `PATCH /api/orgs/{org_id}/settings`
- `GET /api/projects/{project_id}`
- `DELETE /api/projects/{project_id}`
- `GET /api/files/{file_id}/download`
- `GET /api/invoices/{invoice_id}`
- `GET /api/exports/{export_id}/download`

### Body Parameter Swaps

- `org_id`
- `team_id`
- `owner_id`
- `created_by`
- `billing_account_id`
- `role`
- `permissions[]`
- `is_admin`

### GraphQL Checks

- `node(id: "...")`
- `user(id: "...")`
- `organization(id: "...")`
- `project(id: "...")`
- mutations accepting nested input objects
- bulk operations accepting arrays of IDs

### Indirect Object References

- Signed URLs
- CDN URLs
- Preview thumbnails
- Export polling URLs
- WebSocket channel names
- Webhook delivery logs
- Integration connection IDs

## Evidence to Capture

- Authorized baseline request and response.
- Unauthorized replay request and response.
- Actor roles and tenants.
- Controlled victim resource ownership.
- Screenshot or HTTP log showing exposed private field or unauthorized mutation.
- Expected product rule from UI, docs, or role model.

## Validation Rules

Report only if:

- The server returns protected data or performs a protected action.
- The actor is outside the allowed tenant/role/resource boundary.
- Impact is visible using controlled test data.
- The issue is not just UI exposure with server-side denial.

## Kill Criteria

Stop this path if:

- All sensitive ID swaps return consistent `401`, `403`, or object-scoped `404`.
- Errors are identical across tenants and reveal no metadata.
- Export/download URLs are scoped and expire correctly.
- Role changes invalidate access immediately.

## Severity Guidance

| Finding | Typical Severity |
|---|---|
| Cross-tenant read/write of private records | P1/P2 |
| Cross-tenant file, invoice, or export download | P1/P2 |
| Member performs owner/admin action | P1/P2 |
| Metadata leak only | P3/P2 depending sensitivity |
| Self-ID change only with no impact | Low / invalid |

## Report Notes

Good title format:

`[High] BOLA in Export Download Allows Cross-Tenant Access to Private Reports`

Lead with business impact: what data or action is exposed, who can do it, and why the product model forbids it.
