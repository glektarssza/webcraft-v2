import {type ActionsExecModule} from './common-types.js';
import {ErrorCodesEnum} from './errors.js';

export async function revParse(
    rev: string,
    execModule: ActionsExecModule
): Promise<string> {
    const result = await execModule.getExecOutput('git', [
        'rev-parse',
        '--revs-only',
        rev
    ]);
    if (result.exitCode !== 0) {
        throw new Error(ErrorCodesEnum.ExecFailedNonZeroStatus);
    }
    if (result.stderr) {
        throw new Error(ErrorCodesEnum.ExecFailedStderrHasContents);
    }
    return result.stdout.trim();
}

export async function getCurrentBranch(
    execModule: ActionsExecModule
): Promise<string> {
    const result = await execModule.getExecOutput('git', [
        'branch',
        '--show-current'
    ]);
    if (result.exitCode !== 0) {
        throw new Error(ErrorCodesEnum.ExecFailedNonZeroStatus);
    }
    if (result.stderr) {
        throw new Error(ErrorCodesEnum.ExecFailedStderrHasContents);
    }
    return result.stdout.trim();
}
