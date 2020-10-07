module.exports = {
  purge: {
    mode: 'all',
    content: [
      './app/**/*rb'
    ],
  },
  theme: {
    extend: {},
  },
  variants: {
    padding: ['responsive', 'hover']
  },
  plugins: [
    require('@tailwindcss/typography')
  ],
}
