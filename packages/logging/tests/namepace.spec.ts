import {type faker, Faker, en, en_CA, en_US} from '@faker-js/faker';
import {beforeAll, describe, expect, it} from 'vitest';
import * as m from '@src/namespace';

/**
 * The fake data source.
 */
const fakeDataSource = new Faker({
    locale: [en_CA, en_US, en]
});

const createFakeNamespace = (
    components?: Parameters<(typeof faker)['helpers']['multiple']>[1],
    componentOptions?: Parameters<(typeof faker)['string']['alpha']>[0]
) => {
    return fakeDataSource.helpers
        .multiple(
            () => fakeDataSource.string.alpha(componentOptions),
            components
        )
        .join(m.NAMESPACE_COMPONENT_SEPARATOR);
};

describe('module:namespace', () => {
    beforeAll(() => {
        let seed: number | null = null;
        if (typeof FAKER_SEED === 'string') {
            seed = parseInt(FAKER_SEED);
        }
        if (isFinite(seed) && seed > 0) {
            fakeDataSource.seed(seed);
        }
    });
    describe('.isNamespace', () => {
        it('should return `true` if the value is a namespace', () => {
            // -- Given
            const ns = createFakeNamespace();

            // -- When
            const r = m.isNamespace(ns);

            // -- Then
            expect(r).toBeTruthy();
        });
        it('should return `false` if the value is not a namespace', () => {
            // -- Given
            const nsData = [false, null, {}, []];

            // -- When
            let r = m.isNamespace(nsData[0]);

            // -- Then
            expect(r).toBeFalsy();

            // -- When
            r = m.isNamespace(nsData[1]);

            // -- Then
            expect(r).toBeFalsy();

            // -- When
            r = m.isNamespace(nsData[2]);

            // -- Then
            expect(r).toBeFalsy();

            // -- When
            r = m.isNamespace(nsData[3]);

            // -- Then
            expect(r).toBeFalsy();
        });
    });
    describe('.isNamespaceComponent', () => {
        it.todo('should return `true` if the value is a namespace component');
        it.todo(
            'should return `false` if the value is not a namespace component'
        );
    });
});
