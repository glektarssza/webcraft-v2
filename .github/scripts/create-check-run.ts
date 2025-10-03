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
     * The job ID to create the check run for.
     */
    jobId: number;

    /**
     * The external ID to submit for the check run.
     */
    externalId: number;

    /**
     * The name to submit for the check run.
     */
    checkName: string;

    /**
     * The title to submit for the check run.
     */
    checkTitle: string;

    /**
     * The summary to submit for the check run.
     */
    checkSummary: string;

    /**
     * The text to submit for the check run.
     */
    checkText: string;
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
    const {jobId, checkName, checkSummary, checkText, checkTitle, externalId} =
        args;
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
        | OctokitRESTResponse<typeof octokit.rest.checks.create>['data']
        | null = null;
    core.info('Initializing Octokit...');
    const octokit = initializeOctokit({
        octokit: github
    });
    core.endGroup();
    core.startGroup('create_check_run');
    core.info(`Creating check runs for head reference "${headSHA}"...`);
    try {
        data = (
            await octokit.rest.checks.create({
                ...context.repo,
                head_sha: headSHA,
                name: `${checkName}`,
                output: {
                    summary: checkSummary,
                    title: checkTitle,
                    text: checkText
                },
                external_id: `${externalId}`,
                started_at: new Date().toISOString(),
                status: 'in_progress',
                details_url: `https://github.com/${context.repo.owner}/${context.repo.repo}/actions/runs/${context.runId}/job/${jobId}`
            })
        ).data;
    } catch (ex) {
        core.error(
            `Failed to create check runs for head reference "${headSHA}"!`
        );
        throw new Error(ErrorCodesEnum.OctokitCheckRunCreateFailed, {
            cause: ex
        });
    }
    core.info(
        `Created check run for head reference "${headSHA}" with ID "${data.id}".`
    );
    core.endGroup();
    core.setOutput('has-existing-check-run', true);
    core.setOutput('check-run-id', data.id);
    process.exitCode = 0;
    process.exit();
}
