/** @type {import('tailwindcss').Config} */
export default {
  darkMode: 'class',
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        brand: { 50:'#eef7f2',100:'#d7ecdf',200:'#aed9bf',300:'#7dbf9c',400:'#4aa376',500:'#25855c',600:'#006244',700:'#004f38',800:'#0a3d2d',900:'#072b21' },
      },
      fontFamily: { sans: ['Inter','ui-sans-serif','system-ui','Segoe UI','Roboto','sans-serif'] },
    },
  },
  plugins: [],
};
