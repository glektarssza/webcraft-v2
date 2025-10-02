/**
 * An enumeration of available error codes.
 * @enum
 */
export const ErrorCodesEnum = {
    OctokitNotInitialized: 'E_OCTOKIT_NOT_INITIALIZED',
    OctokitNetFetchFailed: 'E_OCTOKIT_NET_FETCH_FAILED',
    OctokitNetFetchNoResults: 'E_OCTOKIT_NET_NO_RESULTS',
    OctokitCheckRunCreateFailed: 'E_OCTOKIT_CHECK_RUN_CREATE_FAILED',
    OctokitCheckRunUpdateFailed: 'E_OCTOKIT_CHECK_RUN_UPDATE_FAILED',
    ExecFailedNonZeroStatus: 'E_EXEC_FAILED_NON_ZERO_STATUS',
    ExecFailedStderrHasContents: 'E_EXEC_FAILED_STDERR_HAS_CONTENTS'
} as const;

/**
 * A type union of known error code values.
 */
export type ErrorCodes = (typeof ErrorCodesEnum)[keyof typeof ErrorCodesEnum];
