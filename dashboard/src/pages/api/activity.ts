import type { APIRoute } from 'astro';
import { getRecentActivityForTarget } from '../../lib/scanner.ts';

export const prerender = false;

function parseLimit(raw: string | null): number {
  const parsed = Number(raw ?? '30');
  if (!Number.isFinite(parsed)) return 30;
  return Math.min(100, Math.max(1, Math.trunc(parsed)));
}

function parseTarget(raw: string | null): string | undefined {
  const target = raw?.trim();
  return target ? target : undefined;
}

export const GET: APIRoute = async ({ url }) => {
  try {
    const limit = parseLimit(url.searchParams.get('limit'));
    const target = parseTarget(url.searchParams.get('target'));
    const events = await getRecentActivityForTarget(limit, target);
    return new Response(JSON.stringify({ events, limit, target: target ?? null }, null, 2), {
      status: 200,
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Cache-Control': 'no-store',
      },
    });
  } catch (err) {
    return new Response(
      JSON.stringify({ error: 'activity_failed', message: (err as Error).message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    );
  }
};
