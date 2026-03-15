/** @type {import("eslint").Linter.Config} */
module.exports = {
  parser: "@typescript-eslint/parser",
  plugins: ["@typescript-eslint"],
  extends: [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
    "plugin:@typescript-eslint/recommended-requiring-type-checking",
  ],
  rules: {
    // Error on unused variables (except those prefixed with _)
    "@typescript-eslint/no-unused-vars": [
      "error",
      { argsIgnorePattern: "^_", varsIgnorePattern: "^_" },
    ],
    // Require explicit return types on exported functions
    "@typescript-eslint/explicit-module-boundary-types": "warn",
    // Disallow any
    "@typescript-eslint/no-explicit-any": "error",
    // Require nullish coalescing
    "@typescript-eslint/prefer-nullish-coalescing": "error",
    // Require optional chaining
    "@typescript-eslint/prefer-optional-chain": "error",
    // Consistent type imports
    "@typescript-eslint/consistent-type-imports": [
      "error",
      { prefer: "type-imports", fixStyle: "inline-type-imports" },
    ],
    // No floating promises
    "@typescript-eslint/no-floating-promises": "error",
    // No misused promises
    "@typescript-eslint/no-misused-promises": "error",
    // Prefer const
    "prefer-const": "error",
    // No var
    "no-var": "error",
    // Eqeqeq
    eqeqeq: ["error", "always", { null: "ignore" }],
  },
  ignorePatterns: ["node_modules/", "dist/", ".next/", "build/", "*.config.*"],
};
