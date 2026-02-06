//-- NodeJS
import os from 'node:os';
import path from 'node:path';

//-- NPM Packages
import {playwright as browserPlaywright} from '@vitest/browser-playwright';
import {type ViteUserConfig, defineConfig} from 'vitest/config';
import replacePlugin from '@rollup/plugin-replace';

const config = defineConfig(({mode}) => {
    const conf: ViteUserConfig = {
        mode,
        resolve: {
            extensions: ['.ts', '.js']
        },
        build: {
            minify: mode !== 'development',
            sourcemap: mode !== 'development' ? 'hidden' : true,
            emptyOutDir: true
        },
        test: {
            projects: [
                path.resolve(import.meta.dirname, './app/'),
                path.resolve(import.meta.dirname, './packages/*')
            ],
            browser: {
                enabled: true,
                provider: browserPlaywright(),
                instances: [
                    {
                        browser: 'chromium',
                        headless: true
                    }
                ]
            },
            mockReset: true,
            clearMocks: true,
            unstubGlobals: true,
            unstubEnvs: true,
            maxConcurrency: Math.max(Math.floor(os.cpus().length / 2), 1),
            coverage: {
                enabled: true,
                provider: 'istanbul',
                reporter: ['text'],
                exclude: [
                    'scripts/**',
                    'templates/**',
                    'coverage/**',
                    '**/dist/**',
                    '**/[.]**',
                    'packages/*/test?(s)/**',
                    '**/*.d.ts',
                    '**/virtual:*',
                    '**/__x00__*',
                    '**/\x00*',
                    'cypress/**',
                    'test?(s)/**',
                    'test?(-*).?(c|m)[jt]s?(x)',
                    '**/*{.,-}{test,spec}?(-d).?(c|m)[jt]s?(x)',
                    '**/__tests__/**',
                    '**/{karma,rollup,webpack,vite,vitest,jest,ava,babel,nyc,cypress,tsup,build}.config.*',
                    '**/vitest.{workspace,projects}.[jt]s?(on)',
                    '**/.{eslint,mocha,prettier}rc.{?(c|m)js,yml}'
                ]
            },
            passWithNoTests: true,
            reporters: 'default'
        },
        server: {
            fs: {
                strict: process.env['VITEST_VSCODE'] === undefined
            }
        },
        plugins: [
            replacePlugin({
                preventAssignment: true,
                values: {
                    FAKER_SEED: JSON.stringify(process.env['FAKER_SEED'])
                }
            })
        ]
    };
    return conf;
});

export default config;
