/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./src/**/*.{astro,html,js,jsx,ts,tsx,md,mdx}'],
  theme: {
    extend: {
      colors: {
        kg: {
          bg: '#1F1F28',
          'bg-elevated': '#2A2A37',
          'bg-card': '#363646',
          border: '#54546D',
          fg: '#DCD7BA',
          'fg-muted': '#C8C093',
          'fg-faded': '#A6A69C',
          'wave-blue': '#7E9CD8',
          ononokami: '#957FB8',
          autumn: '#FFC777',
          'dragon-red': '#E82424',
          'dragon-green': '#87A987',
          'boat-yellow': '#B6927B',
          'wave-aqua': '#6A9589',
        },
      },
      fontFamily: {
        mono: ['"JetBrains Mono"', '"Fira Code"', 'ui-monospace', 'SFMono-Regular', 'Menlo', 'Consolas', 'monospace'],
        sans: ['"Inter"', 'ui-sans-serif', 'system-ui', '-apple-system', 'sans-serif'],
      },
      boxShadow: {
        kanagawa: '0 4px 20px rgba(0, 0, 0, 0.4)',
      },
    },
  },
  plugins: [],
};