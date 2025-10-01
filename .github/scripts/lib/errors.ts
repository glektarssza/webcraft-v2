/**
 * An enumeration of available error codes.
 * @enum
 */
export const ErrorCodesEnum = {
    OctokitNotInitialized: 'E_OCTOKIT_NOT_INITIALIZED'
} as const;

/**
 * A type union of known error code values.
 */
export type ErrorCodes = (typeof ErrorCodesEnum)[keyof typeof ErrorCodesEnum];
