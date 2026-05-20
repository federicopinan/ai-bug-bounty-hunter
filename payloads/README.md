# Payload Library

Centralized repository of payloads for bug bounty hunting. Sourced and curated from [PayloadsAllTheThings](https://github.com/swisskyrepo/PayloadsAllTheThings).

## Structure

```
payloads/
├── README.md           # This file
├── xss.md             # Cross-Site Scripting
├── sqli.md            # SQL Injection
├── ssrf.md            # Server-Side Request Forgery
├── idor.md            # Insecure Direct Object Reference
├── cmd-injection.md   # OS Command Injection
├── jwt.md             # JWT Authentication Attacks
├── auth-bypass.md     # Authentication Bypass
├── ssti.md            # Server-Side Template Injection
├── lfi-rfi.md         # Local/Remote File Inclusion
├── xxe.md             # XML External Entity
└── oauth.md           # OAuth Vulnerabilities
```

## Quick Access by Vulnerability

| Vulnerability | File | Priority |
|---------------|------|----------|
| XSS | `xss.md` | P2 |
| SQL Injection | `sqli.md` | P0 |
| SSRF | `ssrf.md` | P2 |
| IDOR | `idor.md` | P1 |
| Command Injection | `cmd-injection.md` | P0 |
| JWT Attacks | `jwt.md` | P1 |
| Auth Bypass | `auth-bypass.md` | P1 |
| SSTI | `ssti.md` | P1 |
| LFI/RFI | `lfi-rfi.md` | P1 |
| XXE | `xxe.md` | P2 |
| OAuth | `oauth.md` | P1 |

## Usage in Hunt Workflow

```
1. RECON → Map attack surface
2. HUNT → Use payloads from this library
3. VALIDATE → Confirm with /validate
4. REPORT → Document with bug-bounty-report
```

## Sources

- [PayloadsAllTheThings](https://github.com/swisskyrepo/PayloadsAllTheThings)
- [PortSwigger Web Academy](https://portswigger.net/web-security)
- [OWASP Testing Guide](https://owasp.org/www-project-web-security-testing-guide/)

## Contributing

Add new payloads with:
- Description of context
- Expected behavior
- Testing notes