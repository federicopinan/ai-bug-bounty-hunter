import assert from 'node:assert/strict';
import { execFile } from 'node:child_process';
import { mkdtemp, mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { promisify } from 'node:util';
import test, { after } from 'node:test';

const execFileAsync = promisify(execFile);
const repoRoot = path.resolve(import.meta.dirname, '../..');
const loggerPath = path.join(repoRoot, 'tools/scripts/log-event.py');
let projectRoot: string | undefined;

async function makeProjectRoot(): Promise<string> {
  if (projectRoot) return projectRoot;
  const root = await mkdtemp(path.join(tmpdir(), 'hunter-dashboard-'));
  await mkdir(path.join(root, 'programs'), { recursive: true });
  await mkdir(path.join(root, 'reports'), { recursive: true });
  process.env.PROJECT_ROOT = root;
  process.env.REPORTS_ROOT = path.join(root, 'reports');
  projectRoot = root;
  return root;
}

after(async () => {
  if (projectRoot) await rm(projectRoot, { recursive: true, force: true });
});

async function writeEvents(root: string, target: string, lines: string[]): Promise<void> {
  const activityDir = path.join(root, 'programs', target, 'activity');
  await mkdir(activityDir, { recursive: true });
  await writeFile(path.join(activityDir, 'events.jsonl'), `${lines.join('\n')}\n`, 'utf-8');
}

test('GET /api/activity defaults invalid limit and treats blank target as all targets', async () => {
  const root = await makeProjectRoot();
  const { getCache } = await import('../src/lib/cache.ts');
  const { GET } = await import('../src/pages/api/activity.ts');
  getCache().clear();
  await writeEvents(root, 'alpha.test', [
    JSON.stringify({ target: 'alpha.test', phase: 'recon', action: 'subfinder', status: 'success', timestamp: '2026-01-01T00:00:00Z' }),
  ]);

  const response = await GET({ url: new URL('http://dashboard.local/api/activity?limit=abc&target=') } as never);
  const body = await response.json();

  assert.equal(response.status, 200);
  assert.equal(body.limit, 30);
  assert.equal(body.target, null);
  assert.equal(body.events.filter((event: { source: string }) => event.source === 'flight-recorder').length, 1);
});

test('GET /api/activity clamps finite limits to 1..100', async () => {
  const root = await makeProjectRoot();
  const { getCache } = await import('../src/lib/cache.ts');
  const { GET } = await import('../src/pages/api/activity.ts');
  getCache().clear();

  const tooHigh = await GET({ url: new URL('http://dashboard.local/api/activity?limit=500') } as never);
  assert.equal((await tooHigh.json()).limit, 100);

  const tooLow = await GET({ url: new URL('http://dashboard.local/api/activity?limit=0') } as never);
  assert.equal((await tooLow.json()).limit, 1);
});

test('scanner streams JSONL, skips malformed lines, normalizes folder target, and sorts newest first', async () => {
  const root = await makeProjectRoot();
  const { getCache } = await import('../src/lib/cache.ts');
  const { getRecentActivityForTarget } = await import('../src/lib/scanner.ts');
  getCache().clear();

  await writeEvents(root, 'alpha.test', [
    JSON.stringify({ target: 'evil.test', phase: 'hunt', action: 'older', status: 'success', timestamp: '2026-01-01T00:00:00Z' }),
    '{not-json',
    JSON.stringify({ target: 'alpha.test', phase: 'hunt', action: 'newer', status: 'success', timestamp: '2026-01-02T00:00:00Z' }),
  ]);

  const events = await getRecentActivityForTarget(10, 'alpha.test');

  const recorderEvents = events.filter((event) => event.source === 'flight-recorder');
  assert.equal(recorderEvents.length, 2);
  assert.deepEqual(recorderEvents.map((event) => event.event?.action), ['newer', 'older']);
  assert.ok(recorderEvents.every((event) => event.target === 'alpha.test'));
  assert.equal(recorderEvents[1].event?.metadata.originalTarget, 'evil.test');
});

test('log-event writes compact JSONL and validates metadata object', async () => {
  const target = `test-flight-${Date.now()}`;
  const targetRoot = path.join(repoRoot, 'programs', target);
  await rm(targetRoot, { recursive: true, force: true });

  await execFileAsync('python3', [
    loggerPath,
    target,
    'recon',
    'subfinder',
    'success',
    'found hosts',
    '--output-path',
    `programs/${target}/recon/subdomains.txt`,
    '--metadata',
    '{"count":2}',
  ]);

  const eventsPath = path.join(targetRoot, 'activity/events.jsonl');
  const line = (await readFile(eventsPath, 'utf-8')).trim();
  const event = JSON.parse(line);
  assert.equal(event.target, target);
  assert.equal(event.outputPath, `programs/${target}/recon/subdomains.txt`);
  assert.deepEqual(event.metadata, { count: 2 });

  await assert.rejects(
    execFileAsync('python3', [loggerPath, target, 'recon', 'bad', 'failed', '--metadata', '[1,2]']),
    /metadata must be a JSON object/,
  );
  await rm(targetRoot, { recursive: true, force: true });
});

test('log-event rejects unsafe output paths', async () => {
  const target = `test-flight-${Date.now()}`;

  await assert.rejects(
    execFileAsync('python3', [loggerPath, target, 'recon', 'bad', 'failed', '--output-path', '/tmp/out.txt']),
    /output path must be relative/,
  );
  await assert.rejects(
    execFileAsync('python3', [loggerPath, target, 'recon', 'bad', 'failed', '--output-path', '../out.txt']),
    /output path must not contain.*parent/,
  );
});
