/**
 * A module that provides various type utilities.
 *
 * @module
 */

/**
 * Check if a value is a string.
 *
 * @param value The value to check.
 *
 * @returns `true` if the value is a string, or `false` otherwise.
 */
export function isString(value: unknown): value is string {
    return typeof value === 'string';
}

/**
 * Check if a value is a number.
 *
 * @param value The value to check.
 *
 * @returns `true` if the value is a number, or `false` otherwise.
 */
export function isNumber(value: unknown): value is number {
    return typeof value === 'number';
}

/**
 * Check if a value is a big integer.
 *
 * @param value The value to check.
 *
 * @returns `true` if the value is a big integer, or `false` otherwise.
 */
export function isBigInt(value: unknown): value is bigint {
    return typeof value === 'bigint';
}

/**
 * Check if a value is a boolean.
 *
 * @param value The value to check.
 *
 * @returns `true` if the value is a boolean, or `false` otherwise.
 */
export function isBoolean(value: unknown): value is boolean {
    return typeof value === 'boolean';
}

/**
 * Check if a value is a symbol.
 *
 * @param value The value to check.
 *
 * @returns `true` if the value is a symbol, or `false` otherwise.
 */
export function isSymbol(value: unknown): value is symbol {
    return typeof value === 'symbol';
}

/**
 * Check if a value is a function.
 *
 * @param value The value to check.
 *
 * @returns `true` if the value is a function, or `false` otherwise.
 */
export function isFunction(
    value: unknown
): value is (...args: unknown[]) => unknown {
    return typeof value === 'function';
}

/**
 * Check if a value is an object.
 *
 * @param value The value to check.
 *
 * @returns `true` if the value is an object, or `false` otherwise.
 */
export function isObject(value: unknown): value is object {
    return typeof value === 'object' && value !== null;
}

/**
 * Check if a value is a plain object.
 *
 * @param value The value to check.
 *
 * @returns `true` if the value is a plain object, or `false` otherwise.
 */
export function isPlainObject(
    value: unknown
): value is Record<string | symbol, unknown> {
    return isObject(value) && Object.getPrototypeOf(value) === Object.prototype;
}

/**
 * Check if a value is `null`.
 *
 * @param value The value to check.
 *
 * @returns `true` if the value is `null`, or `false` otherwise.
 */
export function isNull(value: unknown): value is null {
    return value === null;
}

/**
 * Check if a value is `undefined`.
 *
 * @param value The value to check.
 *
 * @returns `true` if the value is `undefined`, or `false` otherwise.
 */
export function isUndefined(value: unknown): value is undefined {
    return value === undefined;
}

/**
 * Check if a value is `null` or `undefined`.
 *
 * @param value The value to check.
 *
 * @returns `true` if the value is `null` or `undefined`, or `false` otherwise.
 */
export function isNullOrUndefined(value: unknown): value is null | undefined {
    return isNull(value) || isUndefined(value);
}
