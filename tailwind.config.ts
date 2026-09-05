import type { Config } from 'tailwindcss';

const config: Config = {
  darkMode: 'class',
  content: ['./src/**/*.{js,ts,jsx,tsx,mdx}'],
  theme: {
    extend: {
      colors: {
        bg: '#0E0D12',
        surface: '#17151D',
        'surface-raised': '#201D28',
        border: '#2A2733',
        primary: '#F5F3F0',
        secondary: '#9C97A8',
        accent: {
          DEFAULT: '#E8A33D',
          soft: '#F2C879',
        },
        pulse: {
          DEFAULT: '#6C5CE7',
          soft: '#8B7EF0',
        },
        heart: '#E85D75',
      },
      fontFamily: {
        display: ['var(--font-sora)', 'sans-serif'],
        body: ['var(--font-inter)', 'sans-serif'],
      },
      borderRadius: {
        card: '18px',
      },
    },
  },
  plugins: [],
};

export default config;
