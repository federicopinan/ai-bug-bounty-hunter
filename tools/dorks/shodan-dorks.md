# Shodan and Censys Dorks for Bug Bounty Recon

Internet-wide scan data for finding exposed services, default configs,
and forgotten infrastructure on in-scope IP ranges and ASNs.

---

## Legal Scope Reminder

> **Shodan and Censys index the entire internet, not just your target.**
> Use them to find assets belonging to the in-scope organization only.
> Confirm the IP range / ASN ownership via WHOIS and the program's
> scope file before testing or reporting any finding.

Confirming ownership:

```bash
# Find org's ASN
whois -h whois.radb.net -- '-i origin AS<num>' | grep descr
# or
curl -s "https://stat.ripe.net/data/as-overview/data.json?resource=AS<num>"
```

The ASN's announced prefixes are the only Shodan/Censys surface to test.

---

## 1. Web Servers with Default Configs

Default banners, server-status pages, and sample apps are the lowest
hanging fruit.

```text
# Apache default page
http.title:"It works" org:"{org}"

# nginx default page
http.title:"Welcome to nginx" org:"{org}"

# IIS default page
http.title:"IIS Windows Server" org:"{org}"

# Tomcat default page
http.title:"Apache Tomcat" org:"{org}"

# Server-status / server-info (Apache)
http.title:"Apache Status" OR http.title:"Apache Server Status" org:"{org}"

# phpinfo
http.title:"phpinfo()" org:"{org}"

# Default WordPress install
http.component:"wordpress" http.title:"WordPress > " org:"{org}"
```

### Censys equivalent

```text
services.http.response.html_title: "It works" AND autonomous_system.organization: "{org}"
```

---

## 2. Exposed Databases

Exposed databases on the public internet are Critical. Filter by the
target's ASN to find theirs.

### MongoDB

```text
# MongoDB on default port, no auth
product:"MongoDB" port:27017 org:"{org}"

# MongoDB Express (web UI)
http.title:"Mongo Express" org:"{org}"
```

### Redis

```text
# Redis with no auth
product:"Redis" port:6379 org:"{org}"

# Redis with PING banner exposed
product:"Redis" port:6379 -authentication org:"{org}"
```

### Elasticsearch

```text
# ES with cluster health accessible
product:"Elastic" port:9200 org:"{org}"

# ES with no auth (Kibana often behind it)
http.component:"ElasticSearch" org:"{org}"
```

### PostgreSQL

```text
# Postgres banner exposed
product:"PostgreSQL" port:5432 org:"{org}"
```

### MySQL

```text
product:"MySQL" port:3306 org:"{org}"
```

### Microsoft SQL Server

```text
product:"Microsoft SQL Server" port:1433 org:"{org}"
```

### Memcached

```text
# Memcached stats port exposed
product:"Memcached" port:11211 org:"{org}"
```

---

## 3. IoT and Network Devices

Printers, IP cameras, routers, and other IoT devices are the classic
"exposed on the internet by accident" finding.

```text
# HP and Canon printers
product:"HP" http.title:"HP" port:80,443,9100,515 org:"{org}"
http.title:"Canon" org:"{org}"

# IP cameras
product:"Hikvision" OR product:"Dahua" org:"{org}"
http.title:"webcamXP" OR http.title:"iSpy" org:"{org}"

# Network devices (Cisco, Juniper, MikroTik)
product:"Cisco" port:"23,80,443,161" org:"{org}"
product:"MikroTik" org:"{org}"

# Default router admin pages
http.title:"RouterOS" OR http.title:"RouterOS configuration" org:"{org}"

# UPnP / SSDP exposed
upnp:true org:"{org}"
```

### Censys equivalent

```text
services.http.response.html_title: "RouterOS" AND autonomous_system.organization: "{org}"
```

---

## 4. Admin Panels and DevOps Tools

Internal admin tools that ended up exposed to the internet.

```text
# Jenkins
http.title:"Dashboard [Jenkins]" org:"{org}"
http.component:"Jenkins" port:8080 org:"{org}"

# Grafana
http.title:"Grafana" org:"{org}"
http.component:"Grafana" org:"{org}"

# Kibana
http.title:"Kibana" org:"{org}"
http.component:"Kibana" port:5601 org:"{org}"

# Prometheus
http.title:"Prometheus" org:"{org}"
http.component:"Prometheus" port:9090 org:"{org}"

# Kubernetes Dashboard
http.title:"Kubernetes Dashboard" org:"{org}"
http.component:"Kubernetes" port:8001,8443,10250 org:"{org}"

# Portainer (Docker management)
http.title:"Portainer" org:"{org}"

# RabbitMQ management
http.title:"RabbitMQ Management" org:"{org}"

# GitLab self-hosted
http.title:"GitLab" org:"{org}"

# Argo CD
http.title:"Argo CD" org:"{org}"

# Apache NiFi
http.title:"NiFi" org:"{org}"

# Consul
http.component:"Consul" port:8500 org:"{org}"

# Traefik
http.title:"Traefik" org:"{org}"
```

### Censys equivalent

```text
services.http.response.html_title: "Dashboard [Jenkins]" AND autonomous_system.organization: "{org}"
services.http.response.html_title: "Grafana" AND autonomous_system.organization: "{org}"
```

---

## 5. Cloud Metadata Services

A small number of cloud-hosted assets still expose the IMDS on the
public internet. When found, the metadata service returns credentials
with no further exploitation required.

```text
# AWS EC2 IMDS
http.status:200 http.body:"169.254.169.254" org:"{org}"

# AWS instance metadata in HTTP body
product:"AWS" http.body:"ami-id" org:"{org}"

# Azure IMDS
http.body:"metadata.azure.com" org:"{org}"

# GCP metadata
http.body:"metadata.google.internal" org:"{org}"

# Generic IMDSv1 reachable on port 80
port:80 http.body:"latest/meta-data/" org:"{org}"
```

> **Note:** Most modern providers have moved to IMDSv2 which requires a
> token. The above surfaces *IMDSv1-style* leaks only.

---

## 6. SSL / TLS Misconfigurations

```text
# Self-signed certs
ssl.cert.issuer.cn:self-signed ssl.cert.subject.cn:"{target}" OR ssl.cert.subject.o:"{org}"

# Expired certs (still serving traffic)
ssl.cert.expired:true ssl.cert.subject.cn:"*.{target}"

# Heartbleed-vulnerable
vuln:CVE-2014-0160 org:"{org}"

# TLS 1.0 / 1.1 enabled
tls.version:"TLS 1.0" ssl.cert.subject.cn:"*.{target}"
```

### Censys equivalent

```text
services.tls.version: "TLS 1.0" AND services.tls.certificate.leaf.subject.common_name: "*.{target}"
```

---

## 7. SSH and Remote Access

```text
# SSH banner grabs
product:"OpenSSH" org:"{org}"

# Telnet open
port:23 org:"{org}"

# RDP exposed
port:3389 product:"msrdp" org:"{org}"

# VNC exposed
product:"VNC" port:5900,5901,5902,5903 org:"{org}"

# Cisco Smart Install (often abused)
port:4786 product:"Cisco Smart Install" org:"{org}"
```

---

## 8. Filter by Org, ASN, or Netrange

The most useful filter is the org's ASN. Combine with `org:` for
recon-only queries.

```text
# Shodan: by org name (whatever they registered as)
org:"{org}"                              # exact match
org:"{org}" -http.status:404            # any open service

# Shodan: by ASN
asn:"AS<num>"

# Shodan: by netrange (CIDR)
net:"{ip}/24"

# Censys: by ASN owner
autonomous_system.asn: <num> AND autonomous_system.organization: "{org}"

# Censys: by country or hosting provider
services.port: 22 AND autonomous_system.organization: "{org}"
```

To find the right `org:` string on Shodan, search first without it:

```text
# Find assets the org is already aware of
ssl.cert.subject.o:"{org}"
ssl.cert.subject.cn:"*.{target}"
```

Then build targeted queries on the matching ASN.

---

## 9. Quick Combos

```text
# Combo 1: Anything that looks like a forgotten internal tool
org:"{org}" (http.title:"Grafana" OR http.title:"Kibana" OR http.title:"Prometheus" OR http.title:"Dashboard [Jenkins]")

# Combo 2: Any exposed database
org:"{org}" (product:"MongoDB" OR product:"Redis" OR product:"Elastic" OR product:"PostgreSQL" OR product:"Memcached")

# Combo 3: Open admin panels on non-standard ports
org:"{org}" (http.title:"Admin" OR http.title:"Login") -port:80,443

# Combo 4: Default web server pages
org:"{org}" (http.title:"It works" OR http.title:"Welcome to nginx" OR http.title:"IIS Windows Server")
```

---

## Tooling Helpers

```bash
# Shodan CLI (requires API key)
shodan search 'org:"{org}" port:27017' --fields ip_str,port,hostnames

# Censys CLI / API
censys search 'autonomous_system.organization:"{org}" AND services.port: 22'

# nmap + Shodan correlation (verify a finding is real, not stale index data)
nmap -Pn -p <port> <ip>
```

> **Index lag.** Shodan and Censys data is days to weeks old. Always
> re-verify with a direct probe (nmap or curl) before reporting.

---

## Safety Notes

- **Test only the org's own ASN / netranges.** Shodan data is global —
  the queries above return only what belongs to `{org}`. Do not run
  them to find "neighbors" on the same cloud provider.
- **Cloud-hosted assets move IPs constantly.** A finding tied to a
  single IP at index time is rarely enough for a Critical report.
  Pin the report to the hostname and the *fact* of the exposure
  (e.g. "Kibana on `*.{target}` with no auth"), not to the IP.
- **No DoS.** Even on default-credential instances, do not run scans
  heavier than the indexer already did.
- **No exfiltration of real customer data.** If an exposed DB returns
  rows, count rows and stop. Do not download.
