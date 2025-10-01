/**
 * An interface defining the common inputs to a GitHub Actions script.
 */
export interface CommonScriptArguments {
    /**
     * The pre-built Octokit REST object.
     */
    github: import('@octokit/rest').Octokit;

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

    /**
     * An alternative `require` function for local usage.
     */
    require: typeof require;
}
