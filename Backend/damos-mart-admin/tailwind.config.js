/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        // Brand = hijau Damos Mart (#018D1A)
        brand: {
          50: '#e9f7eb',
          100: '#c8eccd',
          200: '#9fdfa8',
          300: '#6ccd7a',
          400: '#33b84a',
          500: '#018D1A',
          600: '#017a16',
          700: '#016312',
          800: '#014d0e',
          900: '#013a0b',
          950: '#002606',
        },
        slate: {
          850: '#1e293b',
          950: '#0f172a',
        }
      },
      fontFamily: {
        sans: ['Outfit', 'Inter', 'sans-serif'],
      },
      backdropBlur: {
        xs: '2px',
      }
    },
  },
  plugins: [],
}
