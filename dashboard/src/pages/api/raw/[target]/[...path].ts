import type { APIRoute } from 'astro';
import { readProgramFile } from '../../../../lib/scanner.ts';

export const prerender = false;

export const GET: APIRoute = async ({ params }) => {
  const target = params.target;
  const rawPath = params.path;
  if (!target) {
    return new Response(JSON.stringify({ error: 'missing_target' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }
  const relPath = Array.isArray(rawPath) ? rawPath.join('/') : (rawPath ?? '');
  if (!relPath) {
    return new Response(JSON.stringify({ error: 'missing_path' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const file = await readProgramFile(target, relPath);
  if (!file) {
    return new Response(JSON.stringify({ error: 'not_found', target, path: relPath }), {
      status: 404,
      headers: { 'Content-Type': 'application/json' },
    });
  }
  return new Response(JSON.stringify(file, null, 2), {
    status: 200,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      'Cache-Control': 'no-store',
    },
  });
};