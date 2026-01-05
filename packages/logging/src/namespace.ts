/**
 * A module for working with logging namespaces.
 *
 * @module
 */

/**
 * A logging namespace.
 */
export type Namespace = string;

/**
 * A component of a logging namespace.
 */
export type NamespaceComponent = string;

/**
 * A collection of logging namespace components as an array.
 */
export type NamespaceComponentList = NamespaceComponent[];

/**
 * A collection of logging namespaces as an array.
 */
export type NamespaceList = Namespace[];

/**
 * A collection of logging namespaces as a single string.
 */
export type NamespaceListString = string;

/**
 * The character or sequence of characters used to separate logging namespaces.
 */
export const NAMESPACE_SEPARATOR = ',';

/**
 * The character or sequence of characters used to separate logging namespace
 * components.
 */
export const NAMESPACE_COMPONENT_SEPARATOR = ':';

/**
 * Check whether a value is a collection of logging namespaces.
 *
 * @param value The value to check.
 *
 * @returns `true` if the value is a logging namespace, `false` otherwise.
 */
export function isNamespace(value: unknown): value is Namespace {
    return typeof value === 'string' && !value.includes(NAMESPACE_SEPARATOR);
}

/**
 * Check whether a value is a logging namespace component.
 *
 * @param value The value to check.
 *
 * @returns `true` if the value is a logging namespace component, `false`
 * otherwise.
 */
export function isNamespaceComponent(
    value: unknown
): value is NamespaceComponent {
    return (
        typeof value === 'string' &&
        !value.includes(NAMESPACE_SEPARATOR) &&
        !value.includes(NAMESPACE_COMPONENT_SEPARATOR)
    );
}

/**
 * Check whether a value is a logging namespace collection.
 *
 * @param value The value to check.
 *
 * @returns `true` if the value is a logging namespace collection, `false`
 * otherwise.
 */
export function isNamespaceCollection(
    value: unknown
): value is NamespaceListString {
    return typeof value === 'string';
}

/**
 * Convert a logging namespace to a collection of logging namespace components.
 *
 * @param namespace The logging namespace to convert.
 *
 * @returns A collection of logging namespace components.
 */
export function namespaceToNamespaceComponentList(
    namespace: Namespace
): NamespaceComponentList {
    return namespace.split(NAMESPACE_COMPONENT_SEPARATOR);
}

/**
 * Convert a collection of logging namespace components to a logging namespace.
 *
 * @param namespace The collection of logging namespace components to convert.
 *
 * @returns A logging namespace.
 */
export function namespaceComponentListToNamespace(
    namespaceComponentList: NamespaceComponentList
): Namespace {
    return namespaceComponentList.join(NAMESPACE_COMPONENT_SEPARATOR);
}
