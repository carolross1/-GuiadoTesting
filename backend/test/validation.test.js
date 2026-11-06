'use strict';

const { validateTitle } = require('../src/tasks/validation');

describe('validateTitle', () => {
  // Original examples from Document Section 4 (Page 5-6)
  test('trims a valid title', () => {
    expect(validateTitle(' Plan tests ')).toBe('Plan tests');
  });

  test('rejects a blank title', () => {
    expect(() => validateTitle(' ')).toThrow('Enter a valid title.');
  });

  test('rejects a title longer than the limit', () => {
    expect(() => validateTitle('a'.repeat(121))).toThrow('Enter a valid title.');
  });

  // Practice Exercise (Document Section 4, Page 7):
  // "Add a unit test for a missing ID and one for a valid title at the maximum allowed length."
  test('accepts a valid title at the exact maximum allowed length (120 characters)', () => {
    const maxTitle = 'x'.repeat(120);
    expect(validateTitle(maxTitle)).toBe(maxTitle);
    expect(validateTitle(maxTitle).length).toBe(120);
  });

  test('rejects a missing or non-string title', () => {
    expect(() => validateTitle(undefined)).toThrow('Enter a valid title.');
    expect(() => validateTitle(null)).toThrow('Enter a valid title.');
    expect(() => validateTitle(12345)).toThrow('Enter a valid title.');
    expect(() => validateTitle({})).toThrow('Enter a valid title.');
  });

  test('accepts a valid title at minimum length (1 character)', () => {
    expect(validateTitle('A')).toBe('A');
  });
});
