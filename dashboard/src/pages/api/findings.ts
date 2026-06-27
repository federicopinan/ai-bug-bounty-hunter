import type { APIRoute } from 'astro';
import { getAllFindings } from '../../lib/scanner.ts';

export const prerender = false;

export const GET: APIRoute = async ({ url }) => {
  try {
    const all = await getAllFindings();
    const severityFilter = url.searchParams.getAll('severity').map((s) => s.toLowerCase());
    const statusFilter = url.searchParams.getAll('status').map((s) => s.toUpperCase());
    const targetFilter = url.searchParams.getAll('target');
    const typeFilter = (url.searchParams.get('type') ?? '').toLowerCase().trim();
    const search = (url.searchParams.get('q') ?? '').toLowerCase().trim();

    const filtered = all.filter((f) => {
      if (severityFilter.length && !severityFilter.includes(f.severity.toLowerCase())) return false;
      if (statusFilter.length && !statusFilter.includes(f.status)) return false;
      if (targetFilter.length && !targetFilter.includes(f.target)) return false;
      if (typeFilter && !f.type.toLowerCase().includes(typeFilter)) return false;
      if (search && !`${f.title} ${f.endpoint ?? ''} ${f.type}`.toLowerCase().includes(search)) return false;
      return true;
    });

    return new Response(JSON.stringify({ findings: filtered, total: all.length, filtered: filtered.length }, null, 2), {
      status: 200,
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Cache-Control': 'no-store',
      },
    });
  } catch (err) {
    return new Response(
      JSON.stringify({ error: 'findings_failed', message: (err as Error).message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    );
  }
};