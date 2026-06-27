import type { Finding, FindingStatus, Severity } from './types.ts';

const SEVERITY_ALIASES: Record<string, Severity> = {
  critical: 'Critical',
  crit: 'Critical',
  p0: 'Critical',
  high: 'High',
  p1: 'High',
  medium: 'Medium',
  med: 'Medium',
  p2: 'Medium',
  low: 'Low',
  p3: 'Low',
  info: 'Info',
  informational: 'Info',
  p4: 'Info',
};

const STATUS_ALIASES: Record<string, FindingStatus> = {
  new: 'NEW',
  validated: 'VALIDATED',
  val: 'VALIDATED',
  reported: 'REPORTED',
  rep: 'REPORTED',
  duplicate: 'DUPLICATE',
  dup: 'DUPLICATE',
  closed: 'CLOSED',
  resolved: 'RESOLVED',
  invalid: 'INVALID',
  'n/a': 'INVALID',
  na: 'INVALID',
};

export function normalizeSeverity(raw: string | null | undefined): Severity {
  if (!raw) return 'Info';
  const key = raw.toLowerCase().trim();
  return SEVERITY_ALIASES[key] ?? 'Info';
}

export function normalizeStatus(raw: string | null | undefined): FindingStatus {
  if (!raw) return 'NEW';
  const key = raw.toLowerCase().trim();
  return STATUS_ALIASES[key] ?? 'NEW';
}

const TYPE_KEYWORDS: Array<[string, string]> = [
  ['sql injection', 'SQLi'],
  ['sqli', 'SQLi'],
  ['cross-site scripting', 'XSS'],
  ['xss', 'XSS'],
  ['idor', 'IDOR'],
  ['bola', 'IDOR'],
  ['insecure direct object', 'IDOR'],
  ['server-side request forgery', 'SSRF'],
  ['ssrf', 'SSRF'],
  ['remote code execution', 'RCE'],
  ['rce', 'RCE'],
  ['command injection', 'Command Injection'],
  ['cmdi', 'Command Injection'],
  ['csrf', 'CSRF'],
  ['xxe', 'XXE'],
  ['ssti', 'SSTI'],
  ['template injection', 'SSTI'],
  ['lfi', 'LFI'],
  ['local file inclusion', 'LFI'],
  ['rfi', 'RFI'],
  ['remote file inclusion', 'RFI'],
  ['auth bypass', 'Auth Bypass'],
  ['authentication bypass', 'Auth Bypass'],
  ['authorization bypass', 'Auth Bypass'],
  ['privilege escalation', 'Privilege Escalation'],
  ['open redirect', 'Open Redirect'],
  ['subdomain takeover', 'Subdomain Takeover'],
  ['information disclosure', 'Information Disclosure'],
  ['info disclosure', 'Information Disclosure'],
  ['jwt', 'JWT'],
  ['oauth', 'OAuth'],
  ['saml', 'SAML'],
  ['race condition', 'Race Condition'],
  ['path traversal', 'Path Traversal'],
  ['prototype pollution', 'Prototype Pollution'],
];

export function extractType(title: string, metadata: Record<string, string> = {}): string {
  const haystack = `${title} ${metadata['Type'] ?? metadata['Category'] ?? metadata['Vulnerability'] ?? ''}`.toLowerCase();
  for (const [keyword, label] of TYPE_KEYWORDS) {
    if (haystack.includes(keyword)) return label;
  }
  return 'Other';
}

export interface ParseResult {
  findings: Finding[];
  program?: string;
  scopeUrl?: string;
  started?: string;
  sectionCounts: Record<Severity, number>;
}

export function parseTracker(content: string, target: string, sourceFile: string): ParseResult {
  const lines = content.split(/\r?\n/);
  const findings: Finding[] = [];
  const sectionCounts: Record<Severity, number> = {
    Critical: 0,
    High: 0,
    Medium: 0,
    Low: 0,
    Info: 0,
  };

  let currentSeverity: Severity | null = null;
  let currentTitle: string | null = null;
  let currentMetadata: Record<string, string> = {};
  let findingIndex = 0;
  let program: string | undefined;
  let scopeUrl: string | undefined;
  let started: string | undefined;

  const flush = (): void => {
    if (!currentTitle) return;
    const meta = currentMetadata;
    const explicitSeverity = normalizeSeverity(meta['Severity']);
    const severity: Severity =
      explicitSeverity !== 'Info' || meta['Severity'] ? explicitSeverity : currentSeverity ?? 'Info';

    sectionCounts[severity]++;

    const status = normalizeStatus(meta['Status']);
    const bountyRaw = (meta['Bounty'] ?? '').trim();
    const platformRaw = (meta['Platform ID'] ?? meta['HackerOne ID'] ?? '').trim();
    const foundRaw = (meta['Found Date'] ?? '').trim();
    const reportedRaw = (meta['Reported Date'] ?? '').trim();

    findings.push({
      id: `${target}-${findingIndex++}`,
      target,
      severity,
      type: extractType(currentTitle, meta),
      title: currentTitle,
      status,
      endpoint: meta['Endpoint']?.trim() || undefined,
      bounty: bountyRaw && !/^(n\/?a|-)?$/i.test(bountyRaw) ? bountyRaw : undefined,
      foundDate: foundRaw || undefined,
      reportedDate: reportedRaw || undefined,
      platformId: platformRaw && !/^(n\/?a|-)?$/i.test(platformRaw) ? platformRaw : undefined,
      pocPaths: [],
      sourceFile,
    });
  };

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const trimmed = line.trim();

    if (!trimmed) continue;

    // Program info table (Program | Value) — only top of file, before first finding
    if (!program && /^\|\s*\*\*Program\*\*\s*\|/i.test(trimmed)) {
      const valueMatch = trimmed.match(/^\|\s*\*\*Program\*\*\s*\|\s*(.+?)\s*\|$/);
      if (valueMatch) program = stripBrackets(valueMatch[1]);
    }
    if (!scopeUrl && /^\|\s*\*\*Scope URL\*\*\s*\|/i.test(trimmed)) {
      const valueMatch = trimmed.match(/^\|\s*\*\*Scope URL\*\*\s*\|\s*(.+?)\s*\|$/);
      if (valueMatch) scopeUrl = extractUrl(valueMatch[1]);
    }
    if (!started && /^\|\s*\*\*Started\*\*\s*\|/i.test(trimmed)) {
      const valueMatch = trimmed.match(/^\|\s*\*\*Started\*\*\s*\|\s*(.+?)\s*\|$/);
      if (valueMatch) started = stripBrackets(valueMatch[1]);
    }

    // Priority section: ## P0 — Critical, ## P1 — High, etc.
    const priorityMatch = trimmed.match(/^##\s*(P\d)\s*[—\-–]\s*(.+)/i);
    if (priorityMatch) {
      flush();
      currentSeverity = severityFromPriorityOrName(priorityMatch[1], priorityMatch[2]);
      currentTitle = null;
      currentMetadata = {};
      continue;
    }

    // H2 without priority marker — also breaks current finding
    if (/^##\s+/.test(trimmed)) {
      flush();
      currentTitle = null;
      currentMetadata = {};
      continue;
    }

    // New finding: ### [title]
    const titleMatch = trimmed.match(/^###\s+(.+)/);
    if (titleMatch) {
      flush();
      currentTitle = titleMatch[1].trim();
      currentMetadata = {};
      continue;
    }

    // Horizontal rule ends a finding block
    if (trimmed === '---' && currentTitle) {
      flush();
      currentTitle = null;
      currentMetadata = {};
      continue;
    }

    // Metadata row: | **Field** | value |
    const metaMatch = trimmed.match(/^\|\s*\*\*([^*]+)\*\*\s*\|\s*(.*?)\s*\|$/);
    if (metaMatch && currentTitle) {
      const key = metaMatch[1].trim();
      const value = metaMatch[2].trim();
      if (key !== 'Field' && key !== 'Value') {
        currentMetadata[key] = value;
      }
    }
  }

  flush();

  return { findings, program, scopeUrl, started, sectionCounts };
}

function severityFromPriorityOrName(priority: string, name: string): Severity {
  const combined = `${priority} ${name}`.toLowerCase();
  if (combined.includes('critical') || combined.includes('p0')) return 'Critical';
  if (combined.includes('high') || combined.includes('p1')) return 'High';
  if (combined.includes('medium') || combined.includes('p2')) return 'Medium';
  if (combined.includes('low') || combined.includes('p3')) return 'Low';
  return 'Info';
}

function stripBrackets(s: string): string {
  return s.replace(/^\[|\]$/g, '').trim();
}

function extractUrl(s: string): string | undefined {
  const m = s.match(/\((https?:\/\/[^\s)]+)\)/);
  if (m) return m[1];
  const m2 = s.match(/(https?:\/\/[^\s)]+)/);
  if (m2) return m2[1];
  return stripBrackets(s) || undefined;
}