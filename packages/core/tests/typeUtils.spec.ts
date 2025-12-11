// -- NPM Packages
import {describe, it, expect} from 'vitest';

// -- Project Code
import * as m from '@src/typeUtils';

describe('module:typeUtils', () => {
    describe('.isObject()', () => {
        it('should return `false` if the input is not an object', () => {
            // -- Given
            const inputs: unknown[] = [
                'string',
                Symbol('symbol'),
                100,
                BigInt(100),
                true,
                false,
                () => {},
                null,
                undefined
            ];

            // -- When
            inputs.forEach((input) => {
                // -- Then
                expect(input).to.not.satisfy(m.isObject);
            });
        });
        it('should return `true` if the input is an object', () => {
            // -- Given
            const inputs: unknown[] = [{}, [], new RegExp('')];

            // -- When
            inputs.forEach((input) => {
                // -- Then
                expect(input).to.satisfy(m.isObject);
            });
        });
    });
    describe('.isPlainObject()', () => {
        it('should return `false` if the input is not a plain object', () => {
            // -- Given
            const inputs: unknown[] = [
                'string',
                Symbol('symbol'),
                100,
                BigInt(100),
                true,
                false,
                () => {},
                null,
                undefined,
                [],
                new RegExp('')
            ];

            // -- When
            inputs.forEach((input) => {
                // -- Then
                expect(input).to.not.satisfy(m.isPlainObject);
            });
        });
        it('should return `true` if the input is a plain object', () => {
            // -- Given
            const inputs: unknown[] = [{}];

            // -- When
            inputs.forEach((input) => {
                // -- Then
                expect(input).to.satisfy(m.isPlainObject);
            });
        });
    });
});
