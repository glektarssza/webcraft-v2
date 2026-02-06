/// <reference types="vitest" />

//-- NodeJS
import path from 'node:path';

//-- NPM Packages
import {type UserWorkspaceConfig, defineProject} from 'vitest/config';

/**
 * The project name.
 */
const PROJECT_NAME = 'webcraft-package-template';

/**
 * The ViteJS configuration.
 */
const config = defineProject(({mode}) => {
    const conf: UserWorkspaceConfig = {
        root: path.resolve(import.meta.dirname, './src/'),
        build: {
            lib: {
                name: PROJECT_NAME,
                entry: [path.resolve(import.meta.dirname, './src/index.ts')],
                formats: ['cjs', 'es', 'umd'],
                fileName(format, entry) {
                    return mode !== 'development' ?
                            `${format}/${entry}.min.js`
                        :   `${format}/${entry}.js`;
                }
            },
            outDir: path.resolve(import.meta.dirname, './dist/')
        },
        test: {
            alias: [
                {
                    find: /^@src(.*)$/,
                    replacement: path.resolve(import.meta.dirname, './src$1')
                }
            ],
            dir: path.resolve(import.meta.dirname, './tests/'),
            name: 'Webcraft - Package Template'
        }
    };
    return conf;
});

export default config;
