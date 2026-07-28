/**
 * A module which provides general typings for the logging package.
 *
 * @module
 */

import {type Distinct} from '@webcraft/core';

/**
 * A universally unique identifier.
 */
export type UUID = Distinct<string, 'UUID'>;

/**
 * A logging namespace.
 */
export type Namespace = Distinct<string, 'Namespace'>;

/**
 * A logging namespace component.
 */
export type NamespaceComponent = Distinct<string, 'NamespaceComponent'>;

/**
 * A base record of a logging call.
 */
export interface BaseLogRecord {
    /**
     * The ID of the record.
     */
    readonly id: UUID;

    /**
     * The timestamp of when the record was created.
     */
    readonly timestamp: number;

    /**
     * The name of the logger which created the record.
     */
    readonly loggerName: string;

    /**
     * The message to be logged.
     */
    readonly message: string;

    /**
     * The data being logged with the message.
     */
    readonly data: Record<string, unknown>;
}

/**
 * A record of a logging call which includes the formatted version of the message.
 */
export interface FormattedLogRecord extends BaseLogRecord {
    /**
     * The formatted version of the message to be logged.
     */
    readonly formattedMessage: string;
}

/**
 * A record of a logging call.
 */
export type LogRecord = BaseLogRecord | FormattedLogRecord;

/**
 * A logging record formatter.
 */
export interface Formatter {
    /**
     * Format a logging record.
     *
     * @param record The logging record to format.
     *
     * @returns The formatted logging record.
     */
    format(record: LogRecord): FormattedLogRecord;
}

/**
 * A destination for logging records.
 */
export interface Sink {
    /**
     * Write a logging record to the instance asynchronously.
     *
     * @param record The logging record to write.
     */
    writeAsync?(record: LogRecord): Promise<void>;

    /**
     * Write a logging record to the instance.
     *
     * @param record The logging record to write.
     */
    write(record: LogRecord): void;
}
