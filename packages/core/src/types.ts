/**
 * A collection of TypeScript utility types.
 *
 * @module
 */

/**
 * Create a subtype of the given type which is considered distinct from the given
 * type but can still be assigned to that base type.
 *
 * @typeParam TBase The base type to make a distinct type from.
 * @typeParam TDistinct The type to use as a distinguishing type.
 *
 * @example
 * ```ts
 * type ID = Distinct<string>;
 * // Create a new ID.
 * const userID: ID = 'someID' as ID;
 * ```
 */
export type Distinct<
    TBase,
    TDistinct extends string | symbol = symbol
> = TBase &
    (TDistinct extends symbol ?
        {
            readonly __TYPE__: unique symbol;
        }
    :   {
            readonly __TYPE__: string;
        });

/**
 * A generic function type.
 *
 * @typeParam TArgs The type of the input arguments to the function.
 * @typeParam TReturn The type of the return from the function.
 */
export type GenericFunction<TArgs extends unknown[], TReturn = unknown> = (
    ...args: TArgs
) => TReturn;

/**
 * A predicate function which returns a boolean based on the inputs indicating if
 * the input passed the predicate conditions.
 *
 * @typeParam TArgs The type of the inputs to the function.
 */
export type Predicate<TArgs extends unknown[]> = GenericFunction<
    TArgs,
    boolean
>;

/**
 * A function which maps one type into another type.
 *
 * @typeParam TArg The type of the input to the function.
 * @typeParam TReturn The type of the return from the function.
 */
export type Mapper<TArg, TReturn> = GenericFunction<[TArg], TReturn>;
