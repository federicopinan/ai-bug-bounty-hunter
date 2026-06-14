# Auth Matrix

Use this matrix to prove authorization behavior across roles, tenants, ownership states, and authentication levels. Fill it before reporting IDOR/BOLA, privilege escalation, or auth bypass findings.

## Target

- Program:
- Target:
- Date:
- Tester:
- Scope reference:

## Accounts / Roles

| Label | Role | Tenant / Org | Owns Resource? | MFA? | Notes |
|---|---|---|---|---|---|
| User A | | | Yes | | |
| User B | | | No | | |
| Admin | | | N/A | | |
| Anonymous | Unauthenticated | N/A | No | N/A | |

## Test Matrix

| Endpoint / Action | Resource Owner | Session Used | Expected Result | Actual Result | Evidence ID | Status |
|---|---|---|---|---|---|---|
| `GET /api/resource/{id}` | User A | User B | `403` / `404` | | | TODO |
| `PUT /api/resource/{id}` | User A | User B | `403` / `404` | | | TODO |
| `POST /api/admin/action` | Admin | User A | `403` | | | TODO |
| `GET /api/resource/{id}` | User A | Anonymous | `401` | | | TODO |

## Notes

- Confirm every asset is in scope before testing.
- Do not access or retain more data than required to prove impact.
- Pair each failed authorization control with a sanitized request/response in the evidence log.
