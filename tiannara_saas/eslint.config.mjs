import { defineConfig, globalIgnores } from "eslint/config";
import nextVitals from "eslint-config-next/core-web-vitals";
import nextTs from "eslint-config-next/typescript";

const eslintConfig = defineConfig([
  ...nextVitals,
  ...nextTs,
  // Override default ignores of eslint-config-next.
  globalIgnores([
    // Default ignores of eslint-config-next:
    ".next/**",
    "out/**",
    "build/**",
    "next-env.d.ts",
  ]),
  // Custom rules for Tiannara SaaS
  {
    rules: {
      // Prevent console.log in production code (allow console.error for error tracking)
      "no-console": ["error", { allow: ["error", "warn"] }],
      // Enforce better exception handling patterns
      "no-empty": "error",
    }
  }
]);

export default eslintConfig;