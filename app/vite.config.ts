// -- NodeJS
import os from 'node:os';
import path from 'node:path';

// -- NPM Packages
import replacePlugin from '@rollup/plugin-replace';
import {playwright as vitestBrowserPlaywright} from '@vitest/browser-playwright';
import {type ViteUserConfig, defineProject} from 'vitest/config';

/**
 * The project name.
 */
const PROJECT_NAME = 'Webcraft';

/**
 * The ViteJS configuration.
 */
const config = defineProject(({mode}) => {
    const conf: ViteUserConfig = {
        mode,
        resolve: {
            extensions: ['.ts', '.js'],
            alias: {
                '@src': path.resolve(import.meta.dirname, './src/')
            }
        },
        root: path.resolve(import.meta.dirname, './src/'),
        build: {
            outDir: path.resolve(import.meta.dirname, './dist/'),
            minify: mode !== 'development',
            sourcemap: mode !== 'development' ? 'hidden' : true,
            emptyOutDir: true
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
        ],
        test: {
            browser: {
                enabled: true,
                provider: vitestBrowserPlaywright(),
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
            dir: './tests/',
            name: PROJECT_NAME,
            maxConcurrency: Math.max(Math.floor(os.cpus().length / 2), 1)
        }
    };
    return conf;
});

export default config;
