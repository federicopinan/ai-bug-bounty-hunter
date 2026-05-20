# OAuth Vulnerabilities

## OAuth Flow Basics

```
1. Authorization Request
   Client → User → Authorization Server
   GET /authorize?client_id=XXX&redirect_uri=YYY&response_type=code&scope=ZZZ

2. Access Token Request
   Client → Authorization Server
   POST /token with authorization code

3. Resource Access
   Client → Resource Server with access_token
```

## OAuth 1.0a

### Session Fixation
```
# 1. Attacker obtains authorization request URL
# 2. Attacker sends victim this URL
# 3. Victim authenticates and authorizes
# 4. Attacker uses same oauth_token to access victim's account
```

### Signature Bypass
```
# HMAC-SHA1 signature manipulation
# Try empty secret
# Try algorithm confusion
```

## OAuth 2.0 Vulnerabilities

### Redirect URI Manipulation

#### Subdomain takeover
```
# If redirect_uri allows subdomains
https://client-app.com/callback → https://client-app.attacker.com/callback
```

#### Path traversal
```
# If redirect_uri validated incorrectly
https://target.com/callback/../attacker.com
https://target.com/callback/evil.com
```

#### Parameter tricks
```
# Fragment not validated
https://target.com#attacker.com
https://target.com%23attacker.com

# Register domain with @
https://target.com@attacker.com
```

#### Unicode bypass
```
https://target.com\u2019attacker.com (right single quote)
https://target.com。attacker.com (full-width period)
```

### State Parameter Issues

#### Missing state (CSRF)
```
# No state parameter → Authorization CSRF
# Use known value to hijack session
```

#### Weak state generation
```
state=12345 (sequential)
state=abc123 (predictable)
state= (empty)
```

### Client Secret Leakage

#### Public clients
```
# Mobile apps, SPAs have exposed client_secret
# Cannot trust client_secret
```

#### Source code exposure
```
# Find in JS, mobile app binaries
# git clone, decompile
```

### Scope Escalation

```
# Request minimal scope, then use token for more
scope=openid → then access /profile, /email, /admin
```

### Token Leakage

#### URL token exposure
```
# Tokens in URL are logged
# Referer header leaks
# Browser history
```

#### Token in Fragment
```
# Fragment not sent to server
# May be accessible to JS via location.hash
```

## Authorization Code Interception

### Via Referer header
```
# If page with code is linked externally
```

### Via open redirect
```
# Redirect to attacker after code is issued
redirect_uri=https://legitimate.com/callback?code=XXX → https://attacker.com
```

### Via response_mode
```
# If response_mode=form_post, code in POST body
```

## Token Replay

```
# Reuse authorization code
# Use after revocation
# Use across applications
```

## CSRF via OAuth

```
# Without state parameter
1. Attacker creates malicious page
2. Victim visits page
3. Victim's browser sends request to OAuth provider
4. Victim authenticates but unknowingly performs action
```

## OAuth Misconfiguration Examples

### Default redirect_uri
```
# If redirect_uri defaults to app domain
# Attacker can register malicious domain
```

### Whitelist bypass
```
# If only checking prefix
https://legitimate.com.attacker.com
# If checking contains
https://attacker.com/legitimate.com
```

### Allow arbitrary subdomain
```
# *.target.com
# attacker.target.com
```

### Path validation
```
# Sometimes only path is validated
# Can use query params
https://target.com/callback?redirect_uri=https://attacker.com
```

## Blind OAuth (SSRF via Redirect URI)

```
# If redirect_uri is validated server-side
# Can cause server to request internal URLs
# Use DNS rebinding or internal network
```

## JWT + OAuth Exploitation

```
# If OAuth uses JWT as access_token
# Algorithm confusion (RS256 → HS256)
# None algorithm
# Key confusion with jku
```

## Access Token Leakage Vectors

```
# HTTP referrer
# Browser history
# Logs (server, proxy, CDN)
# URL parameters in bookmarks
# Screen capture / shoulder surfing
```

## OAuth Security Checklist

- [ ] redirect_uri exact match (not prefix/substring)
- [ ] State parameter present and cryptographically random
- [ ] Client secret properly protected (not in JS/mobile)
- [ ] Authorization codes single-use
- [ ] Tokens expire appropriately
- [ ] PKCE for public clients
- [ ] No over-privileged scopes
- [ ] HTTPS enforced everywhere
- [ ] No sensitive data in URLs

## OAuth Testing Commands

### Check redirect_uri validation
```
# Try external domain
redirect_uri=https://attacker.com

# Try subdomain
redirect_uri=https://client.target.attacker.com

# Try path traversal
redirect_uri=https://target.com/../attacker.com
```

### Check state parameter
```
# Try missing state
# Try predictable state (123, abc)
# Try reused state
```

### Check token endpoint
```
curl -X POST https://target.com/oauth/token \
  -d "grant_type=authorization_code" \
  -d "code=STOLEN_CODE" \
  -d "client_id=YOUR_CLIENT" \
  -d "client_secret=YOUR_SECRET" \
  -d "redirect_uri=https://yourcallback.com"
```

## Common OAuth Endpoints

```
/oauth/authorize
/oauth/token
/oauth/token/revoke
/oauth/userinfo
/.well-known/openid-configuration
/jwks.json
/openid/connect/jwks.json
```

## Real World OAuth Bugs

| Bug | Impact | Where |
|-----|--------|-------|
| redirect_uri allows internal services | SSRF, access to cloud meta | AWS/GCP metadata |
| State parameter missing | Authorization CSRF | Login flows |
| Implicit flow token in URL | Token leakage | Browser history |
| Access token in fragment | Token accessible to JS | Single page apps |
| Client secret in mobile app | Full account takeover | Mobile apps |
| OAuth token for one app works for another | Cross-app authorization | SSO |