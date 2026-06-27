/// <reference path="../.astro/types.d.ts" />
/// <reference types="astro/client" />

interface ImportMetaEnv {
  readonly PROJECT_ROOT?: string;
  readonly REPORTS_ROOT?: string;
  readonly CACHE_TTL_MS?: string;
  readonly PORT?: string;
  readonly HOST?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}