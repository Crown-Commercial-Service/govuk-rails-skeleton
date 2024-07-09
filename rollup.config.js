import resolve from '@rollup/plugin-node-resolve'
import commonjs from '@rollup/plugin-commonjs'
import typescript from '@rollup/plugin-typescript'


export default {
  input: 'app/javascript/application.ts',
  output: {
    file: 'app/assets/builds/application.js',
    format: 'esm',
    inlineDynamicImports: true,
    sourcemap: true
  },
  plugins: [
    resolve(),
    commonjs(),
    typescript({
      allowSyntheticDefaultImports: true
    }),
  ]
}
