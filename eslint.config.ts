//-- NPM Packages
import globals from 'globals';
import {defineConfig} from 'eslint/config';
import eslint from '@eslint/js';
import tseslint from 'typescript-eslint';
import configsPrettier from 'eslint-config-prettier';
import pluginPlaywright from 'eslint-plugin-playwright';
import pluginVitest from '@vitest/eslint-plugin';

export default defineConfig(
    {
        files: ['**/*.ts', '**/**/*.ts'],
        ignores: ['**/tests/**', '**/e2e/**'],
        languageOptions: {
            parserOptions: {
                projectService: true,
                tsconfigRootDir: import.meta.dirname
            },
            globals: {
                ...globals.builtin,
                ...globals.es2026,
                ...globals.browser
            }
        },
        extends: [
            eslint.configs.recommended,
            tseslint.configs.recommendedTypeChecked,
            configsPrettier
        ]
    },
    {
        files: ['**/*.js', '**/**/*.js'],
        extends: [
            eslint.configs.recommended,
            tseslint.configs.disableTypeChecked,
            configsPrettier,
        ]
    },
    {
        files: ['**/tests/*.ts', '**/tests/**/*.ts'],
        ignores: ['**/src/**', '**/e2e/**'],
        languageOptions: {
            parserOptions: {
                projectService: true,
                tsconfigRootDir: import.meta.dirname
            },
            globals: {
                ...globals.builtin,
                ...globals.es2026,
                ...globals.browser,
                ...globals.vitest
            }
        },
        extends: [
            eslint.configs.recommended,
            tseslint.configs.recommendedTypeChecked,
            pluginVitest.configs.recommended,
            configsPrettier,
        ],
        rules: {
            '@typescript-eslint/no-unused-expressions': 'off'
        }
    },
    {
        files: ['**/e2e/*.ts', '**/e2e/**/*.ts'],
        ignores: ['**/src/**', '**/tests/**'],
        languageOptions: {
            parserOptions: {
                projectService: true,
                tsconfigRootDir: import.meta.dirname
            },
            globals: {
                ...globals.builtin,
                ...globals.es2026,
                ...globals.browser,
                ...globals.vitest
            }
        },
        extends: [
            eslint.configs.recommended,
            tseslint.configs.recommendedTypeChecked,
            pluginVitest.configs.recommended,
            pluginPlaywright.configs['flat/recommended'],
            configsPrettier,
        ]
    }
);
