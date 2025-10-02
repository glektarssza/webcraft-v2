import {type RestEndpointMethodTypes} from '@octokit/rest';
import {type CommonScriptArguments} from './lib/common-types.js';
import {initializeOctokit} from './lib/octokit.js';

/**
 * An interface defining the input arguments to the script.
 *
 * @see {@link ScriptArguments}
 * @see {@link ScriptArgumentsJobName}
 * @see {@link ScriptArgumentsJobNamePattern}
 */
interface ScriptArgumentsBase {
    /**
     * The run ID for the current workflow run.
     */
    run_id: number;

    /**
     * The job name to match against.
     */
    job_name?: string;

    /**
     * The job name pattern to match against, in regular expression format.
     *
     * @see job_name_pattern_flags
     */
    job_name_pattern?: string;

    /**
     * The regular expression flags to apply.
     *
     * Only valid when using {@link job_name_pattern}.
     *
     * @see {@link job_name_pattern}
     */
    job_name_pattern_flags?: string;
}

/**
 * An extension of the {@link ScriptArgumentsBase} interface for when specifically
 * using the {@link ScriptArgumentsBase.job_name job_name} property.
 *
 * @see {@link ScriptArguments}
 * @see {@link ScriptArgumentsBase}
 * @see {@link ScriptArgumentsJobNamePattern}
 */
interface ScriptArgumentsJobName extends ScriptArgumentsBase {
    /**
     * @inheritdoc
     */
    job_name: string;

    /**
     * @inheritdoc
     */
    job_name_pattern: never;

    /**
     * @inheritdoc
     */
    job_name_pattern_flags: never;
}

/**
 * An extension of the {@link ScriptArgumentsBase} interface for when specifically
 * using the {@link ScriptArgumentsBase.job_name_pattern job_name_pattern}
 * property.
 *
 * @see {@link ScriptArguments}
 * @see {@link ScriptArgumentsBase}
 * @see {@link ScriptArgumentsJobName}
 */
interface ScriptArgumentsJobNamePattern extends ScriptArgumentsBase {
    /**
     * @inheritdoc
     */
    job_name: never;

    /**
     * @inheritdoc
     */
    job_name_pattern: string;

    /**
     * @inheritdoc
     */
    job_name_pattern_flags?: string;
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
    const {run_id} = args;
    const octokit = initializeOctokit({
        octokit: github
    });
    core.startGroup('init');
    let matcher: (name: string) => boolean;
    if (args.job_name_pattern) {
        const pattern = new RegExp(
            args.job_name_pattern,
            args.job_name_pattern_flags
        );
        matcher = (name) => pattern.test(name);
    } else {
        matcher = (name) => name === args.job_name;
    }
    let data:
        | RestEndpointMethodTypes['actions']['listJobsForWorkflowRun']['response']['data']
        | null = null;
    core.endGroup();
    core.startGroup('list_jobs_for_workflow');
    core.info(`Fetching jobs for workflow run "${run_id}"...`);
    try {
        data = (
            await octokit.rest.actions.listJobsForWorkflowRun({
                ...context.repo,
                run_id
            })
        ).data;
    } catch (ex) {
        core.error(`Failed to fetch jobs for workflow run "${run_id}"!`);
        throw new Error('E_FETCH_FAILED', {
            cause: ex
        });
    }
    if (data.total_count <= 0) {
        core.error(`No jobs found for workflow run "${run_id}"!`);
        throw new Error('E_NO_RESULTS');
    }
    core.info(`Fetched ${data.total_count} jobs for workflow run "${run_id}".`);
    core.endGroup();
    core.startGroup('find_job_id');
    core.info(
        `Finding job from workflow run "${run_id}" matching "${args.job_name_pattern ?? args.job_name}"...`
    );
    const results = data.jobs.filter((job) => matcher(job.name));
    if (results.length <= 0) {
        core.error(`No matching jobs found for workflow run "${run_id}"!`);
        throw new Error('E_NO_RESULTS');
    }
    core.info(`Found ${results.length} matching jobs.`);
    if (results.length > 1) {
        core.warning(`Picking first match job!`);
    }
    core.setOutput('job-id', results[0]?.id);
    core.endGroup();
}
