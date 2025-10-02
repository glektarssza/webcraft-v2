import {type exec} from '@actions/exec';
import {type getOctokit} from '@actions/github';

/**
 * The GitHub Actions `exec` routine.
 */
export type ActionsExec = typeof exec;

/**
 * A utility type to get the result type of a promise.
 *
 * @typeParam P The type, which should extend {@link Promise}, to get the result
 * type of.
 */
export type PromiseResult<P> = P extends Promise<infer R> ? R : never;

/**
 * A utility type to get the response type of a call to an Octokit instance..
 *
 * @typeParam R The type, which should be a REST API method in an Octokit
 * instance, to get the response type of.
 */
export type OctokitRESTResponse<R extends (...args: never[]) => unknown> =
    PromiseResult<ReturnType<R>>;

/**
 * The return type of the {@link getOctokit} function from the
 * {@link https://github.com/actions/toolkit/tree/main/packages/github @actions/github}
 * package.
 */
export type GitHubOctokit = ReturnType<typeof getOctokit>;

/**
 * An interface defining the common inputs to a GitHub Actions script.
 */
export interface CommonScriptArguments {
    /**
     * The pre-built Octokit REST object.
     */
    github: GitHubOctokit;

    /**
     * The workflow context.
     */
    context: typeof import('@actions/github').context;

    /**
     * The GitHub Actions core API.
     */
    core: typeof import('@actions/core');

    /**
     * The GitHub Actions file globbing API.
     */
    glob: typeof import('@actions/glob');

    /**
     * The GitHub Actions I/O API.
     */
    io: typeof import('@actions/io');

    /**
     * The GitHub Actions execution API.
     */
    exec: typeof import('@actions/exec');
}
