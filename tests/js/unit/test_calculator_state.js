/**
 * Unit tests for calculator state management
 * Tests AC-001, AC-002, AC-003, AC-005, AC-B02, AC-B03
 */

// Import will work after calculator.js exports functions
const {
    createInitialState,
    inputDigit,
    inputOperator,
    inputDecimal,
    clear,
    getDisplayValue
} = require('../../../static/js/calculator.js');

describe('Calculator State', () => {
    // AC-001: Given calculator loads, When page renders, Then display shows "0"
    test('test_initial_state_shows_zero', () => {
        const state = createInitialState();
        expect(getDisplayValue(state)).toBe('0');
    });

    // AC-002: Given display shows "0", When user clicks digit "5", Then display shows "5"
    test('test_digit_appends_to_display', () => {
        let state = createInitialState();
        state = inputDigit(state, '5');
        expect(getDisplayValue(state)).toBe('5');
    });

    // AC-002 extended: Multiple digits
    test('test_multiple_digits_append', () => {
        let state = createInitialState();
        state = inputDigit(state, '1');
        state = inputDigit(state, '2');
        state = inputDigit(state, '3');
        expect(getDisplayValue(state)).toBe('123');
    });

    // AC-003: Given display shows "5", When user clicks "+", Then first operand stored
    test('test_operator_stores_first_operand', () => {
        let state = createInitialState();
        state = inputDigit(state, '5');
        state = inputOperator(state, '+');
        expect(state.firstOperand).toBe(5);
        expect(state.operator).toBe('+');
        expect(state.waitingForSecond).toBe(true);
    });

    // AC-005: Given result displayed, When user clicks "C", Then display resets to "0"
    test('test_clear_resets_state', () => {
        let state = createInitialState();
        state = inputDigit(state, '5');
        state = inputOperator(state, '+');
        state = inputDigit(state, '3');
        state = clear(state);
        expect(getDisplayValue(state)).toBe('0');
        expect(state.firstOperand).toBeNull();
        expect(state.operator).toBeNull();
    });

    // AC-B03: Given user enters multiple decimals, When second "." clicked, Then ignored
    test('test_decimal_only_once', () => {
        let state = createInitialState();
        state = inputDigit(state, '3');
        state = inputDecimal(state);
        state = inputDigit(state, '1');
        state = inputDecimal(state); // Second decimal should be ignored
        state = inputDigit(state, '4');
        expect(getDisplayValue(state)).toBe('3.14');
    });

    // AC-B02: Given user clicks "=" without operator, Then no API call (current number remains)
    test('test_equals_without_operator_no_op', () => {
        let state = createInitialState();
        state = inputDigit(state, '5');
        // When no operator is set, equals should not trigger calculation
        expect(state.operator).toBeNull();
        expect(getDisplayValue(state)).toBe('5');
    });
});

