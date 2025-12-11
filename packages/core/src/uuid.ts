/**
 * A module that deals with Universally Unique IDs.
 *
 * @module
 */

// -- Project Code
import type {Distinct} from './types';

/**
 * A string representation of a UUID.
 */
export type UUIDString = Distinct<string>;

/**
 * A byte array representation of a UUID.
 */
export type UUIDByteArray = Uint8Array;

/**
 * All valid UUID representations.
 */
export type UUID = UUIDString | UUIDByteArray;

/**
 * An array of valid UUID characters.
 */
const VALID_UUID_CHARS: string[] = [
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    'a',
    'b',
    'c',
    'd',
    'e',
    'f'
] as const;

/**
 * Check whether a value is a string representation of a UUID.
 *
 * @param value The value to check.
 *
 * @returns `true` if the value is a string representing a value UUID.
 */
export function isUUIDString(value: unknown): value is UUIDString {
    return (
        typeof value === 'string' &&
        value
            .replaceAll(/-}{/, '')
            .split('')
            .every((e) => VALID_UUID_CHARS.includes(e))
    );
}
