import assert from 'node:assert/strict';
import { execFile } from 'node:child_process';
import { mkdir, readFile, rm, symlink, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { promisify } from 'node:util';
import test, { after } from 'node:test';

const execFileAsync = promisify(execFile);
const repoRoot = path.resolve(import.meta.dirname, '../..');
const scopeGuard = path.join(repoRoot, 'tools/scripts/scope-guard.py');
const evidenceVault = path.join(repoRoot, 'tools/scripts/evidence-vault.py');
const buildReport = path.join(repoRoot, 'tools/scripts/build-report.py');
const createdTargets = new Set<string>();

const { readProgramFile } = await import('../src/lib/scanner.ts');
const scopeApi = await import('../src/pages/api/programs/[target]/scope.ts');

after(async () => {
  for (const target of createdTargets) {
    await rm(path.join(repoRoot, 'programs', target), { recursive: true, force: true });
    const reportsDir = path.join(repoRoot, 'reports');
    try {
      const entries = await import('node:fs/promises').then((fs) => fs.readdir(reportsDir));
      await Promise.all(entries.filter((name) => name.startsWith(`${target}-`)).map((name) => rm(path.join(reportsDir, name), { force: true })));
    } catch {
      // ignore
    }
  }
});

async function makeScopeTarget(suffix: string, scopeJson?: unknown): Promise<string> {
  const target = `test-scope-${Date.now()}-${suffix}`;
  createdTargets.add(target);
  const targetRoot = path.join(repoRoot, 'programs', target);
  await mkdir(targetRoot, { recursive: true });
  if (scopeJson !== undefined) {
    await writeFile(path.join(targetRoot, 'scope.json'), typeof scopeJson === 'string' ? scopeJson : JSON.stringify(scopeJson), 'utf-8');
  }
  return target;
}

test('scope-guard allows in-scope host/url and denies out-of-scope host', async () => {
  const target = await makeScopeTarget('allow', {
    allowedActions: ['recon', 'scan', 'fuzz', 'exploit', 'validate', 'report'],
    defaultActions: ['recon', 'fuzz'],
    inScope: [{ id: 'api', type: 'host', pattern: 'api.acme.test', actions: ['recon', 'fuzz'] }],
    outOfScope: [{ id: 'admin', type: 'host', pattern: 'admin.acme.test', actions: ['recon', 'fuzz'] }],
  });

  const allowed = await execFileAsync('python3', [scopeGuard, target, '--url', 'https://api.acme.test/v1/users', '--action', 'recon']);
  const allowedBody = JSON.parse(allowed.stdout);
  assert.equal(allowedBody.allowed, true);
  assert.equal(allowedBody.matchedRule.id, 'api');

  await assert.rejects(
    execFileAsync('python3', [scopeGuard, target, '--host', 'admin.acme.test', '--action', 'fuzz']),
    (err: any) => {
      const body = JSON.parse(err.stdout);
      assert.equal(body.allowed, false);
      assert.equal(body.reason, 'matched out-of-scope rule');
      return true;
    },
  );
});

test('scope-guard applies out-of-scope deny rules before broad in-scope defaults', async () => {
  const target = await makeScopeTarget('deny-first', {
    defaultActions: ['recon', 'fuzz'],
    inScope: [{ id: 'wildcard', type: 'host', pattern: '*.acme.test', actions: ['recon', 'fuzz', 'exploit', 'validate'] }],
    outOfScope: [{ id: 'admin', type: 'host', pattern: 'admin.acme.test' }],
  });

  for (const action of ['recon', 'exploit', 'validate']) {
    await assert.rejects(execFileAsync('python3', [scopeGuard, target, '--host', 'admin.acme.test', '--action', action]), (err: any) => {
      const body = JSON.parse(err.stdout);
      assert.equal(body.allowed, false);
      assert.equal(body.reason, 'matched out-of-scope rule');
      assert.equal(body.matchedRule.id, 'admin');
      return true;
    });
  }
});

test('scope-guard rejects wildcard host and URL candidates', async () => {
  const target = await makeScopeTarget('candidate-wildcards', {
    allowedActions: ['recon'],
    inScope: [{ id: 'wildcard-config-ok', type: 'host', pattern: '*.acme.test', actions: ['recon'] }],
    outOfScope: [],
  });

  for (const candidate of ['*.acme.test', 'api?.acme.test', 'api[1].acme.test']) {
    await assert.rejects(execFileAsync('python3', [scopeGuard, target, '--host', candidate, '--action', 'recon']), (err: any) => {
      assert.match(JSON.parse(err.stdout).reason, /candidate must be concrete/);
      return true;
    });
  }

  await assert.rejects(execFileAsync('python3', [scopeGuard, target, '--url', 'https://api.acme.test/*', '--action', 'recon']), (err: any) => {
    assert.match(JSON.parse(err.stdout).reason, /candidate must be concrete/);
    return true;
  });
});

test('scope-guard denies missing/invalid config and unsafe target traversal', async () => {
  const missing = await makeScopeTarget('missing');
  await assert.rejects(execFileAsync('python3', [scopeGuard, missing, '--host', 'api.acme.test', '--action', 'recon']), (err: any) => {
    assert.match(JSON.parse(err.stdout).reason, /scope.json missing/);
    return true;
  });

  const invalid = await makeScopeTarget('invalid', '{not-json');
  await assert.rejects(execFileAsync('python3', [scopeGuard, invalid, '--host', 'api.acme.test', '--action', 'recon']), (err: any) => {
    assert.match(JSON.parse(err.stdout).reason, /invalid JSON/);
    return true;
  });

  await assert.rejects(execFileAsync('python3', [scopeGuard, '../evil', '--host', 'api.acme.test', '--action', 'recon']), (err: any) => {
    assert.match(JSON.parse(err.stdout).reason, /unsafe target/);
    return true;
  });
});

test('evidence-vault init creates metadata and default markdown files', async () => {
  const target = await makeScopeTarget('vault-init');
  const result = await execFileAsync('python3', [
    evidenceVault,
    'init',
    target,
    'finding-1',
    '--title',
    'IDOR exposes invoices',
    '--severity',
    'High',
    '--type',
    'IDOR',
    '--endpoint',
    '/api/invoices/123',
  ]);
  const body = JSON.parse(result.stdout);
  assert.equal(body.ok, true);
  const vault = path.join(repoRoot, 'programs', target, 'vulns/poc/finding-1');
  assert.equal(JSON.parse(await readFile(path.join(vault, 'metadata.json'), 'utf-8')).title, 'IDOR exposes invoices');
  assert.match(await readFile(path.join(vault, 'reproduction.md'), 'utf-8'), /Steps to Reproduce/);
  assert.match(await readFile(path.join(vault, 'impact.md'), 'utf-8'), /Impact/);
});

test('evidence-vault add copies evidence safely and list returns JSON summary', async () => {
  const target = await makeScopeTarget('vault-add');
  await execFileAsync('python3', [evidenceVault, 'init', target, 'finding-2', '--title', 'SQLi', '--severity', 'Critical', '--type', 'SQLi', '--endpoint', '/search']);
  const source = path.join(tmpdir(), `request-${Date.now()}.http`);
  await writeFile(source, 'GET /search?q=1 HTTP/1.1\nHost: api.acme.test\n', 'utf-8');
  await execFileAsync('python3', [evidenceVault, 'add', target, 'finding-2', '--file', source, '--kind', 'request', '--description', 'Minimal request PoC']);

  const listed = JSON.parse((await execFileAsync('python3', [evidenceVault, 'list', target, 'finding-2'])).stdout);
  assert.equal(listed.ok, true);
  assert.equal(listed.metadata.evidence.length, 1);
  assert.equal(listed.metadata.evidence[0].kind, 'request');
  assert.match(listed.metadata.evidence[0].path, /^request-request-/);

  await assert.rejects(execFileAsync('python3', [evidenceVault, 'add', target, '../bad', '--file', source, '--kind', 'request']), /unsafe finding_id/);
  await rm(source, { force: true });
});

test('evidence-vault rejects evidence above configured size limit', async () => {
  const target = await makeScopeTarget('vault-size');
  await execFileAsync('python3', [evidenceVault, 'init', target, 'finding-size', '--title', 'Large file', '--severity', 'Low', '--type', 'Info', '--endpoint', '/']);
  const source = path.join(tmpdir(), `large-evidence-${Date.now()}.txt`);
  await writeFile(source, '0123456789', 'utf-8');

  await assert.rejects(
    execFileAsync('python3', [evidenceVault, 'add', target, 'finding-size', '--file', source, '--kind', 'note'], {
      env: { ...process.env, EVIDENCE_VAULT_MAX_BYTES: '5' },
    }),
    (err: any) => {
      assert.match(err.stderr, /evidence file too large/);
      return true;
    },
  );
  await rm(source, { force: true });
});

test('readProgramFile rejects symlink escapes from target directory', async () => {
  const target = await makeScopeTarget('raw-symlink');
  const secret = path.join(tmpdir(), `hunter-secret-${Date.now()}.txt`);
  await writeFile(secret, 'do not read', 'utf-8');
  await symlink(secret, path.join(repoRoot, 'programs', target, 'leak.txt'));

  const result = await readProgramFile(target, 'leak.txt');
  assert.equal(result, null);
  await rm(secret, { force: true });
});

test('readProgramFile reads normal files under target directory', async () => {
  const target = await makeScopeTarget('raw-normal');
  const notesPath = path.join(repoRoot, 'programs', target, 'notes.md');
  await writeFile(notesPath, '# Target notes\n\nnormal file', 'utf-8');

  const result = await readProgramFile(target, 'notes.md');
  assert.ok(result);
  assert.match(result.content, /normal file/);
  assert.equal(result.size, Buffer.byteLength('# Target notes\n\nnormal file'));
});

test('readProgramFile rejects symlinked target directories outside programs', async () => {
  const target = `test-scope-${Date.now()}-raw-target-symlink`;
  createdTargets.add(target);
  const outsideDir = path.join(tmpdir(), `hunter-target-${Date.now()}`);
  await mkdir(outsideDir, { recursive: true });
  await writeFile(path.join(outsideDir, 'notes.md'), 'do not read', 'utf-8');
  await symlink(outsideDir, path.join(repoRoot, 'programs', target));

  const result = await readProgramFile(target, 'notes.md');
  assert.equal(result, null);
  await rm(outsideDir, { recursive: true, force: true });
});

test('scope API returns controlled response for malformed percent encoding', async () => {
  const response = await scopeApi.GET({ params: { target: '%E0%A4%A' } } as any);
  assert.equal(response.status, 400);
  assert.deepEqual(await response.json(), { error: 'invalid_target_encoding' });
});

test('build-report outputs Markdown from evidence and refuses missing vault', async () => {
  const target = await makeScopeTarget('report');
  await execFileAsync('python3', [evidenceVault, 'init', target, 'finding-3', '--title', 'Stored XSS', '--severity', 'Medium', '--type', 'XSS', '--endpoint', '/profile']);
  const markdown = (await execFileAsync('python3', [buildReport, target, 'finding-3', '--stdout'])).stdout;
  assert.match(markdown, /## Title/);
  assert.match(markdown, /Stored XSS/);
  assert.match(markdown, /TODO: No evidence files registered/);
  await assert.rejects(execFileAsync('python3', [buildReport, target, 'finding-3', '--stdout', '--strict']), /strict report validation failed/);

  await assert.rejects(execFileAsync('python3', [buildReport, target, 'missing', '--stdout']), /evidence vault not found/);
  await assert.rejects(execFileAsync('python3', [buildReport, target, '../bad', '--stdout']), /unsafe finding_id/);
});

test('build-report writes normal report output inside reports directory', async () => {
  const target = await makeScopeTarget('report-output');
  const findingId = 'finding-output';
  await execFileAsync('python3', [evidenceVault, 'init', target, findingId, '--title', 'Stored XSS', '--severity', 'Medium', '--type', 'XSS', '--endpoint', '/profile']);

  const result = JSON.parse((await execFileAsync('python3', [buildReport, target, findingId])).stdout);
  assert.equal(result.ok, true);
  assert.equal(result.report, `reports/${target}-${findingId}.md`);

  const reportContent = await readFile(path.join(repoRoot, result.report), 'utf-8');
  assert.match(reportContent, /## Title/);
  assert.match(reportContent, /Stored XSS/);
});

test('build-report refuses report output symlink escapes', async () => {
  const target = await makeScopeTarget('report-symlink');
  const findingId = 'finding-symlink';
  await execFileAsync('python3', [evidenceVault, 'init', target, findingId, '--title', 'Stored XSS', '--severity', 'Medium', '--type', 'XSS', '--endpoint', '/profile']);
  const reportsDir = path.join(repoRoot, 'reports');
  await mkdir(reportsDir, { recursive: true });
  const outside = path.join(tmpdir(), `escaped-report-${Date.now()}.md`);
  const link = path.join(reportsDir, `${target}-${findingId}.md`);
  await writeFile(outside, 'outside', 'utf-8');
  await symlink(outside, link);

  await assert.rejects(execFileAsync('python3', [buildReport, target, findingId]), /report output path escapes reports directory/);
  await rm(link, { force: true });
  await rm(outside, { force: true });
});

test('build-report refuses externally symlinked reports directory', async () => {
  const target = await makeScopeTarget('report-root-symlink');
  const findingId = 'finding-report-root-symlink';
  await execFileAsync('python3', [evidenceVault, 'init', target, findingId, '--title', 'Stored XSS', '--severity', 'Medium', '--type', 'XSS', '--endpoint', '/profile']);
  const reportsDir = path.join(repoRoot, 'reports');
  const backup = path.join(repoRoot, `reports.backup-${Date.now()}`);
  const outsideDir = path.join(tmpdir(), `hunter-reports-${Date.now()}`);
  await rm(backup, { recursive: true, force: true });
  await mkdir(outsideDir, { recursive: true });
  await import('node:fs/promises').then((fs) => fs.rename(reportsDir, backup));
  await symlink(outsideDir, reportsDir);

  try {
    await assert.rejects(execFileAsync('python3', [buildReport, target, findingId]), /reports directory resolves outside repository/);
  } finally {
    await rm(reportsDir, { force: true });
    await import('node:fs/promises').then((fs) => fs.rename(backup, reportsDir));
    await rm(outsideDir, { recursive: true, force: true });
  }
});
