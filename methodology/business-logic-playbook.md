# Business Logic Playbook

## Goal

Find flaws where the application follows valid syntax but violates business rules. Focus on financial impact, unauthorized workflow transitions, limit bypasses, role confusion, inventory abuse, and state-machine errors.

## Best Targets

| Target Pattern | Why It Matters |
|---|---|
| Billing, subscriptions, coupons, trials | Direct financial impact |
| Marketplaces, orders, refunds | Money movement and abuse paths |
| Approval workflows | State transitions may be bypassed |
| Usage limits and quotas | Plan enforcement bugs are common |
| Invite/team management | Role and tenant rules matter |
| Import/export systems | Scope and billing controls may be weak |

## Required Test Accounts/Data

- Two accounts in different tenants.
- Admin and low-privilege role.
- Free/trial and paid plan if allowed.
- Test coupons, trial flows, or sandbox payment method if program permits.
- Controlled records for orders, projects, files, exports, or workflows.

## 30-Minute Triage

| Time | Action | Signal |
|---:|---|---|
| 0-5 | Identify money, quota, role, and approval flows | Clear business rule exists |
| 5-10 | Capture normal state transitions | Client sends state, price, role, or limits |
| 10-15 | Modify one business field | Server trusts client value |
| 15-20 | Replay steps out of order | State machine accepts invalid transition |
| 20-25 | Test concurrent duplicate actions | Race condition or double-spend |
| 25-30 | Validate minimal impact | Free benefit, unauthorized action, or rule bypass |

## Manual Testing Workflow

1. Write the expected business rule in one sentence.
2. Capture the normal flow.
3. Identify all client-controlled business fields.
4. Try skipping steps, repeating steps, reversing order, and changing actors.
5. Try same flow across plan tiers or roles.
6. Test concurrency only with harmless controlled records.
7. Validate financial or authorization impact without causing loss or damage.

## High-Signal Checks

### Billing and Plans

- Change `plan_id`, `price_id`, `amount`, `currency`, `interval`, or `quantity` in requests.
- Apply expired, single-use, or higher-tier coupons.
- Start multiple trials.
- Downgrade after using paid-only features.
- Generate billing portal session for another tenant.
- Change payment method or tax details as low-privilege user.

### Coupons and Discounts

- Reuse single-use coupon.
- Stack incompatible coupons.
- Apply coupon after checkout calculation.
- Change discount value client-side.
- Apply internal/test coupons in production.

### Workflow State Bypass

- Move `draft -> approved` without reviewer.
- Submit after deadline.
- Edit after approval/lock.
- Access paid feature after cancellation.
- Skip email/identity verification step.
- Reuse old approval token after revocation.

### Quotas and Rate Limits

- Create more resources than plan allows.
- Use API/mobile endpoint to bypass UI limit.
- Race two requests that should be mutually exclusive.
- Change `limit`, `page_size`, or `quantity` fields.
- Continue using resources after downgrade or removal.

### Role and Tenant Logic

- Member performs owner-only business operation.
- Invite lower role but accept as higher role.
- Transfer resource ownership across tenants.
- Use stale session after role downgrade.
- Trigger webhook/integration action in another tenant.

### Race Conditions

Use low-impact controlled records only.

- Double redeem coupon.
- Double spend credit.
- Double submit approval.
- Double invite / role update.
- Double export generation beyond quota.

Stop immediately after proving the race with safe evidence.

## Evidence to Capture

- Business rule statement.
- Normal flow request/response.
- Modified request/response.
- Before/after state.
- Financial, quota, or authorization impact.
- Proof that impact uses only controlled data.

## Validation Rules

A valid finding needs:

- A clear expected rule.
- Server-side acceptance of a forbidden state/action.
- Concrete benefit or damage potential.
- Reproducible steps without excessive exploitation.

## Kill Criteria

Stop if:

- Server recalculates all prices, roles, and limits.
- State transitions are enforced server-side.
- Duplicate requests are idempotent.
- Low-privilege and cross-tenant actors are consistently denied.
- No business impact remains after UI inconsistency.

## Severity Guidance

| Finding | Typical Severity |
|---|---|
| Free paid plan, payment bypass, credit abuse | P1/P2 |
| Unauthorized approval or administrative workflow action | P1/P2 |
| Quota bypass with resource or cost impact | P2/P3 |
| Coupon misuse with small discount | P3/Low |
| UI-only inconsistency | Informational / invalid |

## Report Notes

Good title format:

`[High] Subscription Upgrade API Trusts Client-Supplied Price ID Allowing Paid Plan Access for Free`

Explain the business rule first, then show how the API violates it.
