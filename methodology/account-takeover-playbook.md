# Account Takeover Playbook

## Goal

Find flaws that let an attacker gain control of another account or permanently bind their identity to a victim account. Prioritize password reset, email change, MFA, OAuth linking, session invalidation, and identity verification flows.

## Best Targets

| Target Pattern | Why It Matters |
|---|---|
| Apps with password reset and email change | Common ATO entry points |
| OAuth/social login | Account linking confusion can become full takeover |
| Enterprise SSO | Tenant and domain enforcement bugs are high impact |
| MFA flows | Backup/recovery paths often bypass strong auth |
| Mobile + web sessions | Session invalidation may differ by client |
| Invite-based signup | Pending identity states are fragile |

## Required Test Accounts/Data

- Attacker account with controlled email.
- Victim test account with controlled email.
- Optional second email domain if program permits.
- At least one active session before each security-sensitive change.
- Burp/ZAP logs for reset, email change, login, logout, MFA, and OAuth flows.

## 30-Minute Triage

| Time | Action | Signal |
|---:|---|---|
| 0-5 | Map login/reset/email-change endpoints | Token parameters and identity fields |
| 5-10 | Test reset token reuse/expiry | Token remains valid after use/expiry |
| 10-15 | Test email change confirmation model | Account changes before verification |
| 15-20 | Test session invalidation after reset/email/MFA | Old sessions still privileged |
| 20-25 | Test OAuth linking with existing emails | Attacker identity links to victim |
| 25-30 | Validate controlled takeover path | Attacker can log in as victim test account |

## Manual Testing Workflow

1. Create attacker and victim test accounts.
2. Capture password reset request and callback.
3. Capture email change request and confirmation.
4. Capture MFA enrollment/removal and recovery.
5. Capture OAuth/social login and account linking.
6. Capture logout, password change, and session refresh.
7. Test state transitions with old tokens, old sessions, and changed emails.
8. Validate only against your own victim account.

## High-Signal Checks

### Password Reset

- Reset token reuse after successful password change.
- Reset token remains valid after requesting a newer token.
- Reset token not bound to account/email/session.
- Reset link leaks token in referrer or redirects.
- Reset accepts victim identifier in body with attacker's token.
- Reset token has long lifetime or no invalidation.

### Email Change

- New email becomes active before verification.
- Old email confirmation can be skipped.
- `email`, `user_id`, or `account_id` can be changed in request body.
- Existing sessions remain active after email change.
- Email change bypasses SSO/domain restrictions.

### Session Invalidation

After password reset, password change, MFA enablement, MFA removal, email change, or account recovery:

- Old web session should be invalidated or downgraded.
- Refresh token should not revive old access.
- Mobile token should follow the same policy.
- API keys should be reviewed if tied to user identity.

### MFA and Recovery

- MFA removal without current password or MFA proof.
- Backup codes generated/read without re-authentication.
- Recovery flow disables MFA automatically.
- Remembered device token survives password reset.
- MFA enforced in UI but not API.

### OAuth / Social Login Linking

- Social login with same email links to existing account without proof.
- Unverified OAuth email accepted as verified.
- Account linking lacks current session re-auth.
- Attacker can bind their OAuth provider to victim account.
- `redirect_uri`, `state`, or linking callback can be replayed across sessions.

### Invite and Signup Confusion

- Invite accepted with different email than invited.
- Pending invited account can be claimed by attacker.
- Existing account linked to wrong invite tenant.
- Role in invite acceptance body can be upgraded.

## Evidence to Capture

- Timeline of requests.
- Attacker and victim test accounts.
- Token lifecycle: issued, reused, expired, invalidated.
- Before/after account state.
- Proof that attacker can authenticate as or bind identity to victim account.
- Screenshots of controlled victim account only.

## Validation Rules

A valid ATO finding must prove one of:

- Attacker controls victim session.
- Attacker changes victim password/email/MFA.
- Attacker links attacker-controlled OAuth identity to victim.
- Attacker bypasses recovery or verification to access victim account.

Do not test against real users. Do not read real inboxes or exfiltrate secrets.

## Kill Criteria

Stop if:

- Reset/email/MFA tokens are single-use, short-lived, scoped, and invalidated correctly.
- Current password or MFA is required for sensitive changes.
- Sessions are invalidated consistently across web/mobile/API.
- OAuth linking requires authenticated user consent and verified email.

## Severity Guidance

| Finding | Typical Severity |
|---|---|
| Full account takeover without user interaction | P1 |
| Full account takeover with realistic user interaction | P2/P1 depending likelihood |
| Session remains valid after reset but no takeover | P2/P3 |
| Email change before verification with impact | P2 |
| MFA bypass/removal | P1/P2 |

## Report Notes

Good title format:

`[Critical] Password Reset Token Reuse Allows Full Account Takeover`

Show exact takeover chain, but keep proof limited to your controlled victim account.
