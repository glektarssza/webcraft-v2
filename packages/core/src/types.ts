/**
 * A module that provides general purpose utility types.
 *
 * @module
 */

/**
 * A type that creates a new, distinct type from the base given type.
 *
 * @typeParam TType The base type to create a new, distinct type from as a base.
 * @typeParam TDiscriminator The type to use to discriminate the newly created
 * type from other types that use the same base type. If this type is the `symbol`
 * type it will be converted to a `unique symbol` internally.
 */
export type Distinct<
    TType,
    TDiscriminator extends symbol | string = symbol
> = TType &
    (TDiscriminator extends symbol ?
        {
            readonly __TYPE__: unique symbol;
        }
    :   {
            readonly __TYPE__: TDiscriminator;
        });
