/**
 * A module which handles logging namespaces and related logic.
 *
 * @module
 */

import {type Distinct} from '@webcraft/core';

/**
 * A logging namespace.
 */
export type Namespace = Distinct<string, 'Namespace'>;

/**
 * A logging namespace component.
 */
export type NamespaceComponent = Distinct<string, 'NamespaceComponent'>;
