import type { APIRoute } from 'astro';
import { scanAllPrograms } from '../../lib/scanner.ts';

export const prerender = false;

export const GET: APIRoute = async () => {
  try {
    const programs = await scanAllPrograms();
    return new Response(JSON.stringify({ programs }, null, 2), {
      status: 200,
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Cache-Control': 'no-store',
      },
    });
  } catch (err) {
    return new Response(
      JSON.stringify({ error: 'scan_failed', message: (err as Error).message }, null, 2),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    );
  }
};