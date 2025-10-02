import {Duplex} from 'node:stream';
import {text} from 'node:stream/consumers';
import {type ActionsExec} from './common-types.js';

export async function revParse(
    rev: string,
    exec: ActionsExec
): Promise<string> {
    const stdout = new Duplex();
    await exec('git', ['rev-parse', '--revs-only', rev], {
        outStream: stdout
    });
    return await text(stdout);
}
