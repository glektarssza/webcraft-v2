/**
 * A module which provides methods for manipulating logging namespaces.
 *
 * @module
 */

import {Namespace, NamespaceComponent} from './types';

/**
 * The character used to separate logging namespaces in a list of namespaces.
 */
export const NAMESPACE_SEPARATOR = ',';

/**
 * The character used to separate namespace components in a logging namespace.
 */
export const NAMESPACE_COMPONENT_SEPARATOR = ':';

/**
 * Check if a value is a logging namespace.
 *
 * @param value The value to check.
 *
 * @returns `true` if the value is a logging namespace, `false` otherwise.
 */
export const isNamespace = (value: unknown): value is Namespace => {
    return typeof value === 'string' && !value.includes(NAMESPACE_SEPARATOR);
};

/**
 * Check if a value is a logging namespace component.
 *
 * @param value The value to check.
 *
 * @returns `true` if the value is a logging namespace component, `false`
 * otherwise.
 */
export const isNamespaceComponent = (
    value: unknown
): value is NamespaceComponent => {
    return (
        typeof value === 'string' &&
        !value.includes(NAMESPACE_SEPARATOR) &&
        !value.includes(NAMESPACE_COMPONENT_SEPARATOR)
    );
};
