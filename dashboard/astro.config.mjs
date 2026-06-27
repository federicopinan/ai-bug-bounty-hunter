import { defineConfig } from 'astro/config';
import node from '@astrojs/node';
import tailwind from '@astrojs/tailwind';

export default defineConfig({
  output: 'server',
  adapter: node({ mode: 'standalone' }),
  integrations: [tailwind({ applyBaseStyles: false })],
  server: {
    host: '0.0.0.0',
    port: Number(process.env.PORT) || 4321,
  },
  vite: {
    server: {
      host: '0.0.0.0',
      hmr: { protocol: 'ws' },
    },
  },
});