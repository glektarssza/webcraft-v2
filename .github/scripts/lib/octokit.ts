import {getOctokit} from '@actions/github';
import {type GitHubOctokit} from './common-types.js';
import {ErrorCodesEnum} from './errors.js';

let octokitInstance: GitHubOctokit | null = null;

/**
 * Check whether the Octokit instance is initialized.
 *
 * @returns `true` if the Octokit instance is initialized, `false` otherwise.
 */
export function isOctokitInitialized(): boolean {
    return octokitInstance !== null;
}

/**
 * Get the currently active Octokit instance.
 *
 * @returns The currently active Octokit instance.
 *
 * @throws {Error} Thrown if there is no currently active Octokit instance.
 */
export function getOctokitInstance(): GitHubOctokit {
    if (isOctokitInitialized()) {
        return octokitInstance!;
    }
    throw new Error(ErrorCodesEnum.OctokitNotInitialized);
}

/**
 * Try to get the currently active Octokit instance.
 *
 * @returns The currently active Octokit instance if one is available, `null`
 * otherwise.
 */
export function tryGetOctokitInstance(): GitHubOctokit | null {
    return octokitInstance;
}

/**
 * Inputs to use when initializing the Octokit instance with an existing Octokit
 * instance.
 */
export interface InitializeOctokitOptionsExistingOctokit {
    octokit: GitHubOctokit;
    githubToken?: never;
    accessToken?: never;
}

/**
 * Inputs to use when initializing the Octokit instance with a GitHub Actions
 * Token (GAT).
 */
export interface InitializeOctokitOptionsGitHubToken {
    octokit?: never;
    githubToken: string;
    accessToken?: never;
}

/**
 * Inputs to use when initializing the Octokit instance with a Personal Access
 * Token (PAT).
 */
export interface InitializeOctokitOptionsPAT {
    octokit?: never;
    githubToken?: never;
    accessToken: string;
}

/**
 * A type union of possible inputs to use when initializing the Octokit instance.
 */
export type InitializeOctokitOptions =
    | InitializeOctokitOptionsExistingOctokit
    | InitializeOctokitOptionsGitHubToken
    | InitializeOctokitOptionsPAT;

/**
 * Initialize the Octokit instance.
 *
 * @param options The options to use to initialize the Octokit instance.
 *
 * @returns The existing Octokit instance, if one was available, the newly created
 * Octokit instance otherwise.
 */
export function initializeOctokit(
    options: InitializeOctokitOptions
): GitHubOctokit {
    if (isOctokitInitialized()) {
        return getOctokitInstance();
    }
    if (options.octokit) {
        octokitInstance = options.octokit;
    } else if (options.githubToken) {
        octokitInstance = getOctokit(options.githubToken);
    } else if (options.accessToken) {
        octokitInstance = getOctokit(options.accessToken);
    }
    return getOctokitInstance();
}
