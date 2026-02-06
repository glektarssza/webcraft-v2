import {describe, it, expect} from 'vitest';
import * as m from '@src/namespace';

describe('package:@webcraft/logging', () => {
    describe('module:namespace', () => {
        describe('.isNamespace()', () => {
            it.todo('should return `true` if the value is a valid namespace');
            it.todo(
                'should return `false` if the value is a valid string but not a valid namespace'
            );
            it('should return `false` if the value is not a valid string', () => {
                const data = [
                    false,
                    1,
                    {},
                    [],
                    BigInt(1),
                    Symbol(),
                    new RegExp('')
                ];
                data.forEach((item) => {
                    expect(m.isNamespace(item)).to.toBe(false);
                });
            });
        });
    });
});
