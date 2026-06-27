import type { APIRoute } from 'astro';
import { getScopeGuardSummary } from '../../../../lib/scanner.ts';

export const prerender = false;

export const GET: APIRoute = async ({ params }) => {
  let target = '';
  try {
    target = params.target ? decodeURIComponent(params.target) : '';
  } catch {
    return new Response(JSON.stringify({ error: 'invalid_target_encoding' }), {
      status: 400,
      headers: { 'content-type': 'application/json' },
    });
  }
  const scopeGuard = await getScopeGuardSummary(target);
  if (!scopeGuard) {
    return new Response(JSON.stringify({ error: 'target not found' }), {
      status: 404,
      headers: { 'content-type': 'application/json' },
    });
  }
  return new Response(JSON.stringify({ target, scopeGuard }), {
    status: 200,
    headers: { 'content-type': 'application/json' },
  });
};
