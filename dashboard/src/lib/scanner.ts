import { createReadStream } from 'node:fs';
import { lstat, readdir, readFile, realpath, stat } from 'node:fs/promises';
import { createInterface } from 'node:readline';
import path from 'node:path';
import type {
  ActivityEvent,
  ActivityKind,
  EvidenceVaultSummary,
  Finding,
  FindingStatus,
  FlightRecorderEvent,
  ProgramDetail,
  ProgramSummary,
  ReconCounts,
  Severity,
  ScopeGuardSummary,
} from './types.ts';
import { ALL_STATUSES, SEVERITY_ORDER } from './types.ts';
import { parseTracker } from './parser.ts';
import { getCache } from './cache.ts';
import { formatRelativeTime } from './format.ts';

const PROJECT_ROOT = process.env.PROJECT_ROOT ?? path.resolve(process.cwd(), '..');
const REPORTS_ROOT = process.env.REPORTS_ROOT ?? path.join(PROJECT_ROOT, 'reports');

const RECON_FILES: Array<{ key: keyof ReconCounts; filename: string }> = [
  { key: 'subdomains', filename: 'subdomains.txt' },
  { key: 'liveHosts', filename: 'live-hosts.txt' },
  { key: 'ports', filename: 'ports.txt' },
  { key: 'techStack', filename: 'tech-stack.txt' },
  { key: 'endpoints', filename: 'endpoints.txt' },
  { key: 'jsFiles', filename: 'js-files.txt' },
  { key: 'wayback', filename: 'wayback.txt' },
];

function emptyCounts(): ReconCounts {
  return {
    subdomains: 0,
    liveHosts: 0,
    ports: 0,
    techStack: 0,
    endpoints: 0,
    jsFiles: 0,
    wayback: 0,
  };
}

function emptyStatusCounts(): Record<FindingStatus, number> {
  const out = {} as Record<FindingStatus, number>;
  for (const s of ALL_STATUSES) out[s] = 0;
  return out;
}

function emptySeverityCounts(): Record<Severity, number> {
  const out = {} as Record<Severity, number>;
  for (const s of SEVERITY_ORDER) out[s] = 0;
  return out;
}

async function countLines(filePath: string): Promise<number> {
  try {
    const content = await readFile(filePath, 'utf-8');
    return content.split(/\r?\n/).filter((l) => l.trim().length > 0).length;
  } catch {
    return 0;
  }
}

async function safeStat(filePath: string) {
  try {
    return await stat(filePath);
  } catch {
    return null;
  }
}

export async function listTargetDirs(): Promise<string[]> {
  const programsDir = path.join(PROJECT_ROOT, 'programs');
  try {
    const entries = await readdir(programsDir, { withFileTypes: true });
    return entries
      .filter((e) => e.isDirectory())
      .filter((e) => !e.name.startsWith('{'))
      .filter((e) => !e.name.startsWith('.'))
      .map((e) => e.name)
      .sort((a, b) => a.localeCompare(b));
  } catch {
    return [];
  }
}

async function listFilesRecursive(root: string, maxDepth: number = 5): Promise<string[]> {
  const out: string[] = [];
  async function walk(dir: string, depth: number): Promise<void> {
    if (depth > maxDepth) return;
    let entries;
    try {
      entries = await readdir(dir, { withFileTypes: true });
    } catch {
      return;
    }
    for (const entry of entries) {
      if (entry.name.startsWith('.git')) continue;
      const full = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        await walk(full, depth + 1);
      } else if (entry.isFile()) {
        out.push(full);
      }
    }
  }
  await walk(root, 0);
  return out;
}

async function latestMtime(paths: string[]): Promise<string | null> {
  let latest = 0;
  for (const p of paths) {
    const s = await safeStat(p);
    if (s && s.mtimeMs > latest) latest = s.mtimeMs;
  }
  return latest > 0 ? new Date(latest).toISOString() : null;
}

export async function scanAllPrograms(): Promise<ProgramSummary[]> {
  const cache = getCache();
  const cacheKey = 'programs:all';
  const cached = cache.get(cacheKey) as ProgramSummary[] | undefined;
  if (cached) return cached;

  const targets = await listTargetDirs();
  const summaries: ProgramSummary[] = [];

  for (const target of targets) {
    summaries.push(await buildProgramSummary(target));
  }

  cache.set(cacheKey, summaries);
  return summaries;
}

export async function getProgramDetail(target: string): Promise<ProgramDetail | null> {
  const cache = getCache();
  const cacheKey = `program:${target}`;
  const cached = cache.get(cacheKey) as ProgramDetail | undefined;
  if (cached) return cached;

  const targets = await listTargetDirs();
  if (!targets.includes(target)) return null;

  const detail = await buildProgramDetail(target);
  cache.set(cacheKey, detail);
  return detail;
}

export async function getAllFindings(): Promise<Finding[]> {
  const cache = getCache();
  const cacheKey = 'findings:all';
  const cached = cache.get(cacheKey) as Finding[] | undefined;
  if (cached) return cached;

  const programs = await scanAllPrograms();
  const allFindings: Finding[] = [];
  for (const p of programs) {
    const detail = await getProgramDetail(p.target);
    if (detail) allFindings.push(...detail.findings);
  }
  cache.set(cacheKey, allFindings);
  return allFindings;
}

export async function getRecentActivity(limit: number = 30): Promise<ActivityEvent[]> {
  return getRecentActivityForTarget(limit);
}

export async function getRecentActivityForTarget(limit: number = 30, targetFilter?: string): Promise<ActivityEvent[]> {
  const cache = getCache();
  const cacheKey = `activity:${targetFilter ?? 'all'}:${limit}`;
  const cached = cache.get(cacheKey) as ActivityEvent[] | undefined;
  if (cached) return cached;

  const targets = targetFilter ? (await listTargetDirs()).filter((t) => t === targetFilter) : await listTargetDirs();
  const events: ActivityEvent[] = [];

  for (const target of targets) {
    const targetRoot = path.join(PROJECT_ROOT, 'programs', target);
    const recorded = await readFlightRecorderEvents(target);
    for (const event of recorded) {
      events.push({
        source: 'flight-recorder',
        target: event.target,
        kind: 'event',
        path: event.outputPath,
        mtime: event.endedAt ?? event.timestamp ?? event.startedAt ?? new Date(0).toISOString(),
        relTime: formatRelativeTime(event.endedAt ?? event.timestamp ?? event.startedAt),
        event,
      });
    }

    const files = await listFilesRecursive(targetRoot, 4);
    for (const file of files) {
      const s = await safeStat(file);
      if (!s) continue;
      const rel = path.relative(targetRoot, file);
      events.push({
        source: 'file-mtime',
        target,
        kind: classifyActivity(rel),
        path: rel,
        mtime: new Date(s.mtimeMs).toISOString(),
        relTime: formatRelativeTime(new Date(s.mtimeMs).toISOString()),
      });
    }
  }

  // Reports dir
  if (!targetFilter) try {
    const reportEntries = await readdir(REPORTS_ROOT, { withFileTypes: true });
    for (const entry of reportEntries) {
      if (!entry.isFile()) continue;
      const full = path.join(REPORTS_ROOT, entry.name);
      const s = await safeStat(full);
      if (!s) continue;
      events.push({
        source: 'file-mtime',
        target: '(reports)',
        kind: 'report',
        path: entry.name,
        mtime: new Date(s.mtimeMs).toISOString(),
        relTime: formatRelativeTime(new Date(s.mtimeMs).toISOString()),
      });
    }
  } catch {
    // ignore
  }

  events.sort((a, b) => (a.mtime < b.mtime ? 1 : a.mtime > b.mtime ? -1 : 0));
  const sliced = events.slice(0, limit);
  cache.set(cacheKey, sliced);
  return sliced;
}

async function readFlightRecorderEvents(target: string): Promise<FlightRecorderEvent[]> {
  const eventsPath = path.join(PROJECT_ROOT, 'programs', target, 'activity', 'events.jsonl');
  const fileStat = await safeStat(eventsPath);
  if (!fileStat || !fileStat.isFile()) {
    return [];
  }

  const events: FlightRecorderEvent[] = [];
  const lines = createInterface({
    input: createReadStream(eventsPath, { encoding: 'utf-8' }),
    crlfDelay: Infinity,
  });

  for await (const line of lines) {
    if (!line.trim()) continue;
    try {
      const raw = JSON.parse(line) as Record<string, unknown>;
      const event = normalizeFlightRecorderEvent(raw, target);
      if (event) events.push(event);
    } catch {
      // Skip malformed JSONL lines; one bad event must not break the dashboard.
    }
  }
  return events;
}

function normalizeFlightRecorderEvent(raw: Record<string, unknown>, fallbackTarget: string): FlightRecorderEvent | null {
  const timestamp = pickString(raw.timestamp) ?? pickString(raw.startedAt) ?? pickString(raw.endedAt);
  if (!timestamp || Number.isNaN(Date.parse(timestamp))) return null;

  const rawTarget = pickString(raw.target);
  const target = fallbackTarget;
  const metadata = raw.metadata && typeof raw.metadata === 'object' && !Array.isArray(raw.metadata)
    ? (raw.metadata as Record<string, unknown>)
    : {};
  if (rawTarget && rawTarget !== fallbackTarget) {
    metadata.originalTarget = rawTarget;
  }

  return {
    id: pickString(raw.id) ?? `${target}:${timestamp}:${eventsHash(raw)}`,
    target,
    phase: pickString(raw.phase) ?? 'unknown',
    action: pickString(raw.action) ?? 'unknown',
    status: pickString(raw.status) ?? 'unknown',
    message: pickString(raw.message) ?? '',
    timestamp,
    startedAt: pickString(raw.startedAt),
    endedAt: pickString(raw.endedAt),
    command: pickString(raw.command),
    outputPath: pickString(raw.outputPath),
    metadata,
  };
}

function pickString(value: unknown): string | undefined {
  return typeof value === 'string' && value.trim().length > 0 ? value : undefined;
}

function eventsHash(value: unknown): string {
  let hash = 0;
  const text = JSON.stringify(value);
  for (let i = 0; i < text.length; i++) hash = (hash * 31 + text.charCodeAt(i)) >>> 0;
  return hash.toString(16);
}

function classifyActivity(relPath: string): ActivityKind {
  if (relPath.startsWith('recon/')) return 'recon';
  if (relPath.startsWith('screenshots/')) return 'screenshot';
  if (relPath.startsWith('vulns/poc')) return 'poc';
  if (relPath.startsWith('vulns/confirmed')) return 'poc';
  if (relPath.includes('tracker')) return 'finding';
  if (relPath.includes('findings')) return 'finding';
  if (relPath.includes('notes')) return 'note';
  if (relPath.includes('scope')) return 'scope';
  return 'other';
}

async function buildProgramSummary(target: string): Promise<ProgramSummary> {
  const targetDir = path.join(PROJECT_ROOT, 'programs', target);
  const trackerPath = path.join(targetDir, 'vulns', 'tracker.md');
  const notesPath = path.join(targetDir, 'notes.md');
  const scopePath = path.join(targetDir, 'scope.md');
  const scopeGuard = await readScopeGuardSummary(targetDir);

  const [hasTracker, hasNotes, hasScope] = await Promise.all([
    safeStat(trackerPath).then((s) => !!s),
    safeStat(notesPath).then((s) => !!s),
    safeStat(scopePath).then((s) => !!s),
  ]);

  // Recon counts
  const recon = emptyCounts();
  const reconDir = path.join(targetDir, 'recon');
  for (const { key, filename } of RECON_FILES) {
    recon[key] = await countLines(path.join(reconDir, filename));
  }

  // Findings from tracker
  const findingsByStatus = emptyStatusCounts();
  const findingsBySeverity = emptySeverityCounts();
  let program: string | undefined;
  let scopeUrl: string | undefined;
  let started: string | undefined;
  let findingsCount = 0;

  if (hasTracker) {
    const content = await readFile(trackerPath, 'utf-8');
    const parsed = parseTracker(content, target, 'vulns/tracker.md');
    findingsCount = parsed.findings.length;
    for (const f of parsed.findings) {
      findingsByStatus[f.status]++;
      findingsBySeverity[f.severity]++;
    }
    program = parsed.program;
    scopeUrl = parsed.scopeUrl;
    started = parsed.started;
  }

  // Latest activity: union of stat mtimes
  const targetFiles = await listFilesRecursive(targetDir, 3);
  const lastActivity = await latestMtime(targetFiles);
  const lastActivityRel = formatRelativeTime(lastActivity);

  return {
    target,
    scopePath: hasScope ? 'scope.md' : '',
    hasTracker,
    hasNotes,
    hasScope,
    program,
    started,
    scopeUrl,
    recon,
    findingsCount,
    findingsByStatus,
    findingsBySeverity,
    lastActivity,
    lastActivityRel,
    scopeGuard,
  };
}

export async function getScopeGuardSummary(target: string): Promise<ScopeGuardSummary | null> {
  const targets = await listTargetDirs();
  if (!targets.includes(target)) return null;
  return readScopeGuardSummary(path.join(PROJECT_ROOT, 'programs', target));
}

async function readScopeGuardSummary(targetDir: string): Promise<ScopeGuardSummary> {
  const scopeJsonPath = path.join(targetDir, 'scope.json');
  const fileStat = await safeStat(scopeJsonPath);
  if (!fileStat?.isFile()) {
    return { available: false, path: '', allowedActions: [], inScopeRules: 0, outOfScopeRules: 0 };
  }
  try {
    const raw = JSON.parse(await readFile(scopeJsonPath, 'utf-8')) as Record<string, unknown>;
    const allowedActions = Array.isArray(raw.allowedActions)
      ? raw.allowedActions.filter((a): a is string => typeof a === 'string')
      : [];
    return {
      available: true,
      path: 'scope.json',
      policyUrl: pickString(raw.policyUrl),
      allowedActions,
      inScopeRules: Array.isArray(raw.inScope) ? raw.inScope.length : 0,
      outOfScopeRules: Array.isArray(raw.outOfScope) ? raw.outOfScope.length : 0,
    };
  } catch (error) {
    return {
      available: false,
      path: 'scope.json',
      allowedActions: [],
      inScopeRules: 0,
      outOfScopeRules: 0,
      error: error instanceof Error ? error.message : 'invalid scope.json',
    };
  }
}

async function buildProgramDetail(target: string): Promise<ProgramDetail> {
  const summary = await buildProgramSummary(target);
  const targetDir = path.join(PROJECT_ROOT, 'programs', target);

  const findings: Finding[] = [];
  const trackerPath = path.join(targetDir, 'vulns', 'tracker.md');
  if (summary.hasTracker) {
    const content = await readFile(trackerPath, 'utf-8');
    findings.push(...parseTracker(content, target, 'vulns/tracker.md').findings);
  }

  // Recon files metadata
  const reconFiles: ProgramDetail['reconFiles'] = [];
  const reconDir = path.join(targetDir, 'recon');
  for (const { filename } of RECON_FILES) {
    const full = path.join(reconDir, filename);
    const s = await safeStat(full);
    if (!s) continue;
    const content = await readFile(full, 'utf-8');
    const lines = content.split(/\r?\n/).filter((l) => l.trim().length > 0).length;
    reconFiles.push({
      name: filename,
      size: s.size,
      lines,
      mtime: new Date(s.mtimeMs).toISOString(),
    });
  }
  reconFiles.sort((a, b) => a.name.localeCompare(b.name));
  const evidenceVaults = await readEvidenceVaults(targetDir);

  return {
    ...summary,
    findings,
    reconFiles,
    evidenceVaults,
  };
}

async function readEvidenceVaults(targetDir: string): Promise<EvidenceVaultSummary[]> {
  const pocDir = path.join(targetDir, 'vulns', 'poc');
  let entries;
  try {
    entries = await readdir(pocDir, { withFileTypes: true });
  } catch {
    return [];
  }
  const vaults: EvidenceVaultSummary[] = [];
  for (const entry of entries) {
    if (!entry.isDirectory() || entry.name.startsWith('.')) continue;
    const metaPath = path.join(pocDir, entry.name, 'metadata.json');
    try {
      const meta = JSON.parse(await readFile(metaPath, 'utf-8')) as Record<string, unknown>;
      vaults.push({
        findingId: pickString(meta.findingId) ?? entry.name,
        path: `vulns/poc/${entry.name}`,
        evidenceCount: Array.isArray(meta.evidence) ? meta.evidence.length : 0,
        title: pickString(meta.title),
        severity: pickString(meta.severity),
        type: pickString(meta.type),
      });
    } catch {
      vaults.push({ findingId: entry.name, path: `vulns/poc/${entry.name}`, evidenceCount: 0 });
    }
  }
  return vaults.sort((a, b) => a.findingId.localeCompare(b.findingId));
}

export async function readProgramFile(target: string, relPath: string): Promise<{ content: string; size: number; mtime: string } | null> {
  // Strict allowlist under programs/{target}/, including symlink escape checks.
  const programsDir = path.join(PROJECT_ROOT, 'programs');
  const targetDir = path.join(programsDir, target);
  const resolved = path.normalize(path.join(targetDir, relPath));
  if (!resolved.startsWith(targetDir + path.sep) && resolved !== targetDir) {
    return null;
  }
  const targetStat = await lstat(targetDir).catch(() => null);
  if (!targetStat?.isDirectory()) {
    return null;
  }
  let targetReal: string;
  let fileReal: string;
  let programsReal: string;
  try {
    [programsReal, targetReal, fileReal] = await Promise.all([realpath(programsDir), realpath(targetDir), realpath(resolved)]);
  } catch {
    return null;
  }
  if (!targetReal.startsWith(programsReal + path.sep) && targetReal !== programsReal) {
    return null;
  }
  if (!fileReal.startsWith(targetReal + path.sep) && fileReal !== targetReal) {
    return null;
  }
  const s = await safeStat(fileReal);
  if (!s || !s.isFile()) return null;
  // Cap at 1MB to prevent abuse
  if (s.size > 1024 * 1024) return null;
  const content = await readFile(fileReal, 'utf-8');
  return { content, size: s.size, mtime: new Date(s.mtimeMs).toISOString() };
}

export function getProjectRoots() {
  return { PROJECT_ROOT, REPORTS_ROOT };
}
