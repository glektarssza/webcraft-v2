//-- NPM Packages
import globals from 'globals';
import {defineConfig} from 'eslint/config';
import eslint from '@eslint/js';
import tseslint from 'typescript-eslint';
import configsPrettier from 'eslint-config-prettier';
import pluginPlaywright from 'eslint-plugin-playwright';
import pluginVitest from '@vitest/eslint-plugin';

/**
 * The base ESLint configuration that all other configurations extend from.
 */
const baseConfig = defineConfig({
    name: 'Base Config',
    languageOptions: {
        globals: {
            ...globals.builtin,
            ...globals.es2026,
            ...globals.browser
        }
    },
    extends: [eslint.configs.recommended, configsPrettier]
});

/**
 * The base TypeScript ESLint configuration that all other TypeScript
 * configurations extend from.
 */
const baseTypescriptConfig = defineConfig({
    name: 'Base TypeScript Config',
    extends: [baseConfig, tseslint.configs.recommendedTypeChecked],
    languageOptions: {
        parserOptions: {
            projectService: true,
            tsconfigRootDir: import.meta.dirname
        }
    }
});

/**
 * The base project JavaScript source ESLint configuration.
 */
const baseProjectJavaScriptSourceConfig = defineConfig({
    files: ['**/src/**/*.js'],
    extends: [baseConfig]
});

/**
 * The base project TypeScript source ESLint configuration.
 */
const baseProjectTypeScriptSourceConfig = defineConfig({
    files: ['**/src/**/*.ts'],
    extends: [baseTypescriptConfig]
});

/**
 * The base project JavaScript tests ESLint configuration.
 */
const baseProjectJavaScriptTestsConfig = defineConfig({
    files: ['**/tests/**/*.js'],
    extends: [
        pluginVitest.configs.recommended,
        pluginPlaywright.configs['flat/recommended']
    ],
    rules: {
        '@typescript-eslint/no-unused-expressions': 'off',
        'vitest/valid-expect': 'off'
    }
});

/**
 * The base project TypeScript tests ESLint configuration.
 */
const baseProjectTypeScriptTestsConfig = defineConfig({
    files: ['**/tests/**/*.ts'],
    extends: [baseTypescriptConfig, pluginVitest.configs.recommended],
    rules: {
        '@typescript-eslint/no-unused-expressions': 'off',
        'vitest/valid-expect': 'off'
    }
});

/**
 * The project-level JavaScript source ESLint configuration.
 */
const projectJavaScriptSourceConfig = defineConfig({
    name: 'Project JavaScript Config',
    ignores: ['**/tests/**'],
    extends: [baseProjectJavaScriptSourceConfig]
});

/**
 * The project-level source TypeScript ESLint configuration.
 */
const projectTypescriptSourceConfig = defineConfig({
    name: 'Project TypeScript Config',
    ignores: ['**/tests/**'],
    extends: [baseProjectTypeScriptSourceConfig]
});

/**
 * The project-level JavaScript tests ESLint configuration.
 */
const projectTestsJavaScriptConfig = defineConfig({
    name: 'Project Tests JavaScript Config',
    extends: [baseProjectJavaScriptTestsConfig]
});

/**
 * The project-level TypeScript ESLint configuration.
 */
const projectTestsTypescriptConfig = defineConfig({
    name: 'Project Tests TypeScript Config',
    extends: [baseProjectTypeScriptTestsConfig]
});

export default defineConfig([
    projectJavaScriptSourceConfig,
    projectTypescriptSourceConfig,
    projectTestsJavaScriptConfig,
    projectTestsTypescriptConfig
]);
