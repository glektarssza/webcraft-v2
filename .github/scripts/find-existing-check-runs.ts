import {
    type OctokitRESTResponse,
    type CommonScriptArguments
} from './lib/common-types.js';
import {ErrorCodesEnum} from './lib/errors.js';
import {revParse} from './lib/git.js';
import {initializeOctokit} from './lib/octokit.js';

/**
 * The script arguments.
 */
interface ScriptArguments {
    /**
     * The head reference to use instead of the current head reference.
     */
    headRef?: string;

    /**
     * The job ID to fetch check runs for.
     */
    jobId: number;
}

/**
 * The main action script.
 *
 * @param commonArgs The common arguments used in all GitHub Action scripts.
 * @param args The arguments used in this specific GitHub Action script.
 *
 * @returns A promise that resolves once this script has completed or rejects once
 * this script has failed.
 */
export async function script(
    commonArgs: CommonScriptArguments,
    args: ScriptArguments
): Promise<void> {
    const {context, core, github, exec} = commonArgs;
    core.startGroup('init');
    core.info('Initializing variables...');
    const {ref, sha} = context;
    const {jobId} = args;
    let headRef = args.headRef;
    if (!headRef) {
        headRef = ref;
    }
    if (!headRef) {
        headRef = 'HEAD';
    }
    let headSHA = await revParse(headRef, exec);
    if (!headSHA) {
        headSHA = sha;
    }
    let data:
        | OctokitRESTResponse<typeof octokit.rest.checks.listForRef>['data']
        | null = null;
    core.info('Initializing Octokit...');
    const octokit = initializeOctokit({
        octokit: github
    });
    core.endGroup();
    core.startGroup('list_jobs_for_workflow');
    core.info(`Fetching check runs for head reference "${headSHA}"...`);
    try {
        data = (
            await octokit.rest.checks.listForRef({
                ...context.repo,
                ref: headSHA,
                filter: 'latest'
            })
        ).data;
    } catch (ex) {
        core.error(
            `Failed to fetch check runs for head reference "${headSHA}"!`
        );
        throw new Error(ErrorCodesEnum.OctokitNetFetchFailed, {
            cause: ex
        });
    }
    if (data.total_count <= 0) {
        core.error(`No check runs for head reference "${headSHA}"!`);
        throw new Error(ErrorCodesEnum.OctokitNetFetchNoResults);
    }
    core.info(
        `Fetched ${data.total_count} check runs for head reference "${headSHA}".`
    );
    core.endGroup();
    core.startGroup('check_for_check_runs');
    core.info(
        `Finding check runs for head reference "${headSHA}" matching job ID "${jobId}"...`
    );
    const results = data.check_runs.filter(
        (checkRun) => checkRun.external_id === `${jobId}`
    );
    if (results.length <= 0) {
        core.error(`No matching check runs for job ID "${jobId}"!`);
        core.setOutput('has-existing-check-run', false);
        process.exitCode = 0;
        process.exit();
    }
    core.info(`Found ${results.length} matching check runs.`);
    if (results.length > 1) {
        core.warning(`Picking first match check run!`);
    }
    core.info(`Found matching check run ID "${results[0]?.id}"`);
    core.setOutput('has-existing-check-run', true);
    core.setOutput('check-run-id', results[0]?.id);
    core.endGroup();
    process.exitCode = 0;
    process.exit();
}
