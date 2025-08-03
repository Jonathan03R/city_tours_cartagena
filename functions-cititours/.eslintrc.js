const js = require("@eslint/js")
const globals = require("globals")

module.exports = {
  ignorePatterns: ["node_modules"],

  overrides: [
    {
      files: ["**/*.js"],
      env: {
        node: true,
        es2023: true
      },
      parserOptions: {
        ecmaVersion: "latest",
        sourceType: "module"
      },
      globals: globals.node,
      extends: [
        "eslint:recommended"
      ],
      rules: {
        ...js.configs.recommended.rules,
        "quotes": ["error", "double", { allowTemplateLiterals: true }],
        "prefer-arrow-callback": "error",
        "require-jsdoc": "off",
        "max-len": "off"
      }
    },
    {
      files: ["**/*.spec.js"],
      env: { mocha: true },
      rules: {}
    }
  ]
}