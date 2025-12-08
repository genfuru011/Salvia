/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./app/views/**/*.erb",
    "./app/islands/**/*.js",
    "./public/assets/javascripts/**/*.js"
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['"Plus Jakarta Sans"', 'sans-serif'],
        display: ['"Inter"', 'sans-serif'],
      },
      borderRadius: {
        'DEFAULT': '7px',
        'md': '7px',
        'lg': '10px',
        'xl': '14px',
      },
      colors: {
        'salvia': {
          50: '#f0f0ff',
          100: '#e4e4ff',
          200: '#cdcdff',
          300: '#a8a8ff',
          400: '#7c7cff',
          500: '#6A5ACD',  // Blue Salvia
          600: '#5a4ab8',
          700: '#4B0082',  // Indigo
          800: '#3d006b',
          900: '#2d0050',
        }
      }
    },
  },
  plugins: [],
}
