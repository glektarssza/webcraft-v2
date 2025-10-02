import {
    type OctokitRESTResponse,
    type CommonScriptArguments
} from './lib/common-types.js';
import {initializeOctokit} from './lib/octokit.js';

/**
 * The script arguments for when passing in a job name to match precisely against.
 *
 * @see {@link ScriptArguments}
 * @see {@link ScriptArgumentsJobNamePattern}
 */
interface ScriptArgumentsJobName {
    /**
     * @inheritdoc
     */
    jobName: string;

    /**
     * @inheritdoc
     */
    jobNamePattern?: never;

    /**
     * @inheritdoc
     */
    jobNamePatternFlags?: never;
}

/**
 * The script arguments for when passing in a job name regular expression pattern
 * to match against.
 *
 * @see {@link ScriptArguments}
 * @see {@link ScriptArgumentsJobName}
 */
interface ScriptArgumentsJobNamePattern {
    /**
     * @inheritdoc
     */
    jobName?: never;

    /**
     * @inheritdoc
     */
    jobNamePattern: string;

    /**
     * @inheritdoc
     */
    jobNamePatternFlags?: string;
}

/**
 * A union type of {@link ScriptArgumentsJobName} and
 * {@link ScriptArgumentsJobNamePattern} to form an exclusive type where only one
 * of the two union'd types may be used.
 *
 * @see {@link ScriptArgumentsBase}
 * @see {@link ScriptArgumentsJobName}
 * @see {@link ScriptArgumentsJobNamePattern}
 */
type ScriptArguments = ScriptArgumentsJobName | ScriptArgumentsJobNamePattern;

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
    const {context, core, github} = commonArgs;
    core.startGroup('init');
    core.info('Initializing variables...');
    const {runId} = context;
    let matcher: (name: string) => boolean;
    if (args.jobNamePattern) {
        const pattern = new RegExp(
            args.jobNamePattern,
            args.jobNamePatternFlags
        );
        matcher = (name) => pattern.test(name);
    } else {
        matcher = (name) => name === args.jobName;
    }
    let data:
        | OctokitRESTResponse<
              typeof octokit.rest.actions.listJobsForWorkflowRun
          >['data']
        | null = null;
    core.info('Initializing Octokit...');
    const octokit = initializeOctokit({
        octokit: github
    });
    core.endGroup();
    core.startGroup('list_jobs_for_workflow');
    core.info(`Fetching jobs for workflow run "${runId}"...`);
    try {
        data = (
            await octokit.rest.actions.listJobsForWorkflowRun({
                ...context.repo,
                run_id: runId
            })
        ).data;
    } catch (ex) {
        core.error(`Failed to fetch jobs for workflow run "${runId}"!`);
        throw new Error('E_FETCH_FAILED', {
            cause: ex
        });
    }
    if (data.total_count <= 0) {
        core.error(`No jobs found for workflow run "${runId}"!`);
        throw new Error('E_NO_RESULTS');
    }
    core.info(`Fetched ${data.total_count} jobs for workflow run "${runId}".`);
    core.endGroup();
    core.startGroup('find_job_id');
    core.info(
        `Finding job from workflow run "${runId}" matching "${args.jobNamePattern ?? args.jobName}"...`
    );
    const results = data.jobs.filter((job) => matcher(job.name));
    if (results.length <= 0) {
        core.error(`No matching jobs found for workflow run "${runId}"!`);
        throw new Error('E_NO_RESULTS');
    }
    core.info(`Found ${results.length} matching jobs.`);
    if (results.length > 1) {
        core.warning(`Picking first match job!`);
    }
    core.info(`Found matching job ID "${results[0]?.id}"`);
    core.setOutput('job-id', results[0]?.id);
    core.endGroup();
    process.exitCode = 0;
    process.exit();
}
