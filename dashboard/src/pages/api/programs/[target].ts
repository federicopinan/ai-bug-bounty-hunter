import type { APIRoute } from 'astro';
import { getProgramDetail } from '../../../lib/scanner.ts';

export const prerender = false;

export const GET: APIRoute = async ({ params }) => {
  const target = params.target;
  if (!target) {
    return new Response(JSON.stringify({ error: 'missing_target' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }
  try {
    const detail = await getProgramDetail(target);
    if (!detail) {
      return new Response(JSON.stringify({ error: 'not_found', target }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' },
      });
    }
    return new Response(JSON.stringify(detail, null, 2), {
      status: 200,
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Cache-Control': 'no-store',
      },
    });
  } catch (err) {
    return new Response(
      JSON.stringify({ error: 'detail_failed', message: (err as Error).message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    );
  }
};