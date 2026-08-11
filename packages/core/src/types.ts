/**
 * A module which provides Typescript types.
 *
 * @module
 *

/**
 * The ID of the property used to make types distinct.
 */
const DISTINCT_PROPERTY_ID: unique symbol = Symbol();

/**
 * A type that is compatible with its base type but considered distinct from it.
 *
 * @template TBase The base type.
 * @template TDistinctID The ID to assign to the distinct type.
 */
export type Distinct<TBase, TDistinctTypeID extends string> = TBase & {
    readonly [DISTINCT_PROPERTY_ID]: TDistinctTypeID;
};

/**
 * A universally unique identifier.
 */
export type UUID = Distinct<string, 'webcraft:core:uuid'>;
