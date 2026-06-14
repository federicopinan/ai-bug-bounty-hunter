# Authorization Testing Matrix

Use this matrix to turn manual bug bounty testing into a repeatable authorization workflow. The goal is to find real P1/P2 authorization bugs: cross-tenant access, privilege escalation, broken object-level authorization, stale-session abuse, and unsafe sharing/invitation flows.

## Safety Rules

- Test only assets, accounts, and tenants that are explicitly in scope.
- Use your own test accounts and your own test data whenever possible.
- Do not access, download, modify, or delete third-party user data.
- Prove impact with the smallest safe action: metadata visibility, controlled test records, reversible changes, or program-approved evidence.
- Stop immediately if a test exposes real customer data beyond minimal proof.

## Goal

Build a controlled set of users, roles, sessions, organizations, and resources so every sensitive request can be replayed across trust boundaries.

High-value findings usually come from answering one question:

> Can actor X perform action Y on resource Z when the product model says they should not?

## Actor Matrix

Create these accounts before deep testing. Adjust names to match the target product.

| Actor | Tenant / Org | Role | Session State | Purpose |
|---|---:|---|---|---|
| Anonymous | None | None | No session | Public access checks |
| User A | Org 1 | Owner/Admin | Valid | Full legitimate control baseline |
| User B | Org 1 | Member/Low privilege | Valid | Same-tenant privilege boundary |
| User C | Org 2 | Owner/Admin | Valid | Cross-tenant isolation boundary |
| User D | Org 2 | Member/Low privilege | Valid | Cross-tenant + low privilege checks |
| User E | Org 1 | Former member | Removed/disabled | Stale membership checks |
| User F | Org 1 | Any role | Expired token/session | Session invalidation checks |

If the program allows it, add more roles:

- Billing admin
- Read-only viewer
- Support agent
- API-only user
- Service account
- SSO-managed user
- Pending invited user

## Resource Inventory

Create controlled resources with User A in Org 1 and User C in Org 2.

| Resource Type | Org 1 Test ID | Org 2 Test ID | Sensitive Actions |
|---|---|---|---|
| Profile / user object | `user_a_id` | `user_c_id` | read, update email/name/avatar |
| Team / organization | `org_1_id` | `org_2_id` | read settings, update settings |
| Project / workspace | `project_1_id` | `project_2_id` | read, update, delete, export |
| File / attachment | `file_1_id` | `file_2_id` | preview, download, delete |
| Invoice / billing record | `invoice_1_id` | `invoice_2_id` | view, download, change billing |
| Invite link | `invite_1_token` | `invite_2_token` | accept, reuse, escalate role |
| API token | `api_key_1_id` | `api_key_2_id` | list, create, revoke |
| Report / export | `export_1_id` | `export_2_id` | generate, poll status, download |
| Integration | `integration_1_id` | `integration_2_id` | connect, read secrets, disconnect |

## Request Capture Workflow

Capture requests through Burp, ZAP, browser devtools, or application logs.

For each sensitive flow, save:

- HTTP method and path
- Request body
- Query parameters
- Object identifiers
- Tenant identifiers
- Authorization headers/cookies
- Response status and body shape
- Role and account used
- Expected authorization rule

Prioritize requests that mutate data, expose private data, or cross product boundaries.

## Core Replay Matrix

For every sensitive request captured as User A in Org 1, replay it with each actor.

| Original Request Owner | Replay Actor | Expected Result | Bug Signal |
|---|---|---|---|
| User A / Org 1 | Anonymous | `401` or login redirect | Any private data or state change |
| User A / Org 1 | User B / same org member | Role-dependent | Admin-only action succeeds |
| User A / Org 1 | User C / different org admin | `403` or not found | Cross-tenant read/write succeeds |
| User A / Org 1 | User D / different org member | `403` or not found | Cross-tenant access succeeds |
| User A / Org 1 | User E / removed user | `401`/`403` | Former member still accesses org data |
| User A / Org 1 | User F / expired token | `401` | Expired token still works |

## High-Signal Authorization Checks

### 1. Cross-Tenant Object Access

Replace object IDs in Org 2 requests with Org 1 IDs.

Check:

- `/api/projects/{project_id}`
- `/api/orgs/{org_id}/members`
- `/api/files/{file_id}/download`
- `/api/invoices/{invoice_id}`
- `/api/exports/{export_id}`
- GraphQL `node(id: ...)`
- Mobile API object IDs
- Old API versions such as `/v1/`, `/v2/`, `/api/internal/`

Bug signals:

- `200 OK` with another tenant's object
- `204 No Content` after modifying another tenant's object
- Partial metadata leak with names, emails, billing data, file names, or internal IDs
- Export/download URL generated for another tenant's resource

### 2. Same-Tenant Privilege Escalation

Replay admin actions as a member/viewer.

Check:

- Add/remove users
- Change roles
- Change billing settings
- Create/revoke API keys
- Disable MFA or SSO
- Update organization settings
- Delete projects/files
- Generate exports
- Connect/disconnect integrations

Bug signals:

- Low-privilege user changes high-impact settings
- UI hides action but API accepts it
- Role name in body can be changed, such as `role=admin`
- Server trusts client-side feature flags or permissions arrays

### 3. Role Downgrade and Removal

After capturing valid requests, downgrade or remove the user and replay old requests.

Check:

- Old browser tab still works
- API token remains valid after removal
- WebSocket/subscription still receives events
- Download links still work
- Export polling still returns data
- Mobile token remains valid

Bug signals:

- Removed user can read or mutate org resources
- Downgraded user retains admin-only API access
- Session invalidation only affects UI, not API

### 4. Invitation and Share Links

Test invite/share tokens as different actors and states.

Check:

- Reuse accepted invite
- Accept invite as a different email
- Modify requested role in invite acceptance body
- Accept invite after revocation
- Accept invite after expiration
- Use share link after resource deletion or permission change
- Change `org_id`, `team_id`, or `role` during invite flow

Bug signals:

- Invite grants higher role than intended
- Invite can be redeemed by wrong account
- Revoked/expired token still works
- Share link exposes private data after access is removed

### 5. File, Export, and Report Access

Files and exports often bypass normal object authorization.

Check:

- Direct file URL
- Signed URL lifetime
- Predictable file IDs
- Export job status endpoint
- Export download endpoint
- Report PDF/CSV/XLSX downloads
- Attachment previews and thumbnails

Bug signals:

- Cross-tenant download succeeds
- Signed URL works after role removal
- Export status leaks row counts, names, or filenames
- Generated export includes data outside actor's scope

### 6. Billing and Invoice Access

Billing often has separate permissions and high business impact.

Check:

- View invoices
- Download invoices
- Change payment method
- Change plan
- Apply coupon
- View tax/business details
- Access billing portal session URLs

Bug signals:

- Member accesses billing without permission
- Cross-tenant invoice readable by ID swap
- Billing portal session generated for another org
- Coupon/plan manipulation changes cost without authorization

### 7. Token and Session State

Test whether auth state changes propagate everywhere.

Check after password reset, logout, MFA enablement, SSO enforcement, role downgrade, org removal:

- Web session cookie
- Bearer token
- Refresh token
- API key
- Mobile token
- WebSocket connection
- Background export/download URL

Bug signals:

- Token still works after security-sensitive state change
- Refresh token rotates incorrectly or revives revoked access
- API key remains active after user/org removal

## 30-Minute Triage Loop

Use this when deciding whether a target is worth deeper manual testing.

| Time | Action | Keep Going If |
|---:|---|---|
| 0-5 min | Create two orgs and two roles | Product supports tenants, teams, roles, or projects |
| 5-10 min | Capture admin request and replay as member | API returns role-specific behavior |
| 10-15 min | Swap Org 1 and Org 2 object IDs | Any `200`, metadata leak, or inconsistent errors |
| 15-20 min | Remove/downgrade user and replay old request | Session/token remains partially valid |
| 20-25 min | Test invite/share/export endpoints | Tokens or downloads are loosely scoped |
| 25-30 min | Validate impact with minimal proof | Private data or unauthorized mutation is confirmed |

Kill the target path if all sensitive APIs consistently return clean `401/403/404`, object IDs are unguessable and scoped, and no state mismatch appears after role/session changes.

## Validation Rules

A finding is reportable only when you can prove all of these:

- The affected asset is in scope.
- The victim resource is controlled by you or testing is explicitly permitted.
- The actor should not have access according to product rules.
- The server, not just the UI, allows the unauthorized action.
- The impact is concrete: data exposure, privilege escalation, account/org takeover, billing impact, or unauthorized state change.
- Evidence is minimal and safe.

## Severity Guidance

| Impact | Typical Severity |
|---|---|
| Cross-tenant access to PII, invoices, exports, private files | P1/P2 depending scale and sensitivity |
| Member can become admin or perform admin-only org actions | P1/P2 |
| Removed user retains access to private org data | P2, sometimes P1 if broad |
| Unauthorized billing portal or payment method access | P1/P2 |
| Metadata-only leak such as names, emails, filenames | P3/P2 depending sensitivity |
| UI-only issue with server-side denial | Informational / invalid |

## Evidence to Capture

For every promising issue, save:

- Actor account and role
- Victim test account/org/resource
- Original request as authorized user
- Replay request as unauthorized user
- Response proving access or mutation
- Expected access rule from UI/docs/product behavior
- Minimal screenshot or HTTP log
- Business impact statement
- Clear mitigation suggestion

Avoid dumping full records. Redact tokens, cookies, secrets, and personal data.

## Report Notes

Strong report titles:

- `[High] Cross-Tenant BOLA Allows Any Organization Admin to Download Private Invoices`
- `[High] Member Role Can Escalate to Admin via Organization Role Update API`
- `[Medium] Removed Users Retain Access to Project Exports via Stale Download URLs`

In the report, lead with impact, not technique. Show the authorization rule, the bypass, and the safe proof.

## Copyable Target Template

Copy this section into `programs/{target}/auth-matrix.md`.

```markdown
# Auth Matrix — {Target}

## Scope Confirmation

- Program:
- In-scope app/API:
- Testing accounts allowed: yes/no
- Multi-account testing allowed: yes/no
- Notes / restrictions:

## Actors

| Actor | Email / Username | Org | Role | Session / Token | Notes |
|---|---|---|---|---|---|
| Anonymous | N/A | N/A | N/A | none | |
| User A | | Org 1 | Owner/Admin | valid | |
| User B | | Org 1 | Member | valid | |
| User C | | Org 2 | Owner/Admin | valid | |
| User D | | Org 2 | Member | valid | |
| User E | | Org 1 | Removed/disabled | old session | |
| User F | | Org 1 | Any | expired token | |

## Controlled Resources

| Resource | Org 1 ID | Org 2 ID | Owner | Notes |
|---|---|---|---|---|
| Organization | | | | |
| Project/workspace | | | | |
| File/attachment | | | | |
| Invoice/billing record | | | | |
| Invite link | | | | |
| Export/report | | | | |
| API token | | | | |

## Captured Sensitive Requests

| ID | Actor | Method | Path | Resource ID | Expected Rule | Replay Actors | Result |
|---|---|---|---|---|---|---|---|
| R1 | User A | | | | | B, C, D, E, F, Anonymous | |

## Findings Candidates

| Candidate | Impact | Evidence Path | Status | Next Step |
|---|---|---|---|---|
| | | | new / validated / invalid | |
```
