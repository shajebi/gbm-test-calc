function createInitialState() {
    return {
        displayValue: '0',
        firstOperand: null,
        operator: null,
        waitingForSecond: false
    };
}

function getDisplayValue(state) {
    return state.displayValue;
}

function inputDigit(state, digit) {
    if (state.waitingForSecond) {
        return { ...state, displayValue: digit, waitingForSecond: false };
    }
    return {
        ...state,
        displayValue: state.displayValue === '0' ? digit : state.displayValue + digit
    };
}

function inputDecimal(state) {
    if (state.waitingForSecond) {
        return { ...state, displayValue: '0.', waitingForSecond: false };
    }
    if (state.displayValue.includes('.')) {
        return state;
    }
    return { ...state, displayValue: state.displayValue + '.' };
}

function inputOperator(state, operator) {
    const inputValue = parseFloat(state.displayValue);
    return {
        ...state,
        firstOperand: inputValue,
        operator: operator,
        waitingForSecond: true
    };
}

function clear(state) {
    return createInitialState();
}

function setDisplayValue(state, value) {
    return { ...state, displayValue: String(value) };
}

if (typeof module !== 'undefined' && module.exports) {
    module.exports = { createInitialState, getDisplayValue, inputDigit, inputDecimal, inputOperator, clear, setDisplayValue };
}

