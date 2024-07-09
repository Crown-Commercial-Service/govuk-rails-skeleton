// @ts-check

import eslint from '@eslint/js'
import tseslint from 'typescript-eslint'
import stylisticJs from '@stylistic/eslint-plugin-js'
import stylisticTs from '@stylistic/eslint-plugin-ts'

export default tseslint.config(
  eslint.configs.recommended,
  ...tseslint.configs.recommended,
  {
    plugins: {
      '@stylistic/js': stylisticJs,
      '@stylistic/ts': stylisticTs
    },
    rules: {
      '@stylistic/ts/indent': [
        'error',
        2
      ],
      '@stylistic/js/linebreak-style': [
        'error',
        'unix'
      ],
      '@stylistic/ts/quotes': [
        'error',
        'single'
      ],
      '@stylistic/ts/semi': [
        'error',
        'never'
      ]
    }
  }
)
