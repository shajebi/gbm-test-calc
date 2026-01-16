(function() {
    'use strict';

    let state = createInitialState();
    const display = document.getElementById('display');
    const memoryIndicator = document.getElementById('memory-indicator');

    function updateDisplay() {
        display.textContent = getDisplayValue(state);
    }

    function updateMemoryIndicator(hasMemory) {
        memoryIndicator.hidden = !hasMemory;
    }

    async function handleEquals() {
        if (!state.operator || state.firstOperand === null) return;

        try {
            const result = await calculate(state.firstOperand, parseFloat(state.displayValue), state.operator);
            state = setDisplayValue(createInitialState(), result.result);
            updateDisplay();
        } catch (error) {
            display.textContent = 'Error';
            setTimeout(() => { state = createInitialState(); updateDisplay(); }, 1500);
        }
    }

    async function handleMemoryAdd() {
        try {
            const result = await memoryAdd(parseFloat(state.displayValue));
            updateMemoryIndicator(result.value !== 0);
        } catch (error) {
            console.error('Memory add failed:', error);
        }
    }

    async function handleMemorySubtract() {
        try {
            const result = await memorySubtract(parseFloat(state.displayValue));
            updateMemoryIndicator(result.value !== 0);
        } catch (error) {
            console.error('Memory subtract failed:', error);
        }
    }

    async function handleMemoryRecall() {
        try {
            const result = await memoryRecall();
            state = setDisplayValue(state, result.value);
            updateDisplay();
        } catch (error) {
            console.error('Memory recall failed:', error);
        }
    }

    async function handleMemoryClear() {
        try {
            await memoryClear();
            updateMemoryIndicator(false);
        } catch (error) {
            console.error('Memory clear failed:', error);
        }
    }

    document.querySelector('.button-grid').addEventListener('click', async (e) => {
        const btn = e.target.closest('.btn');
        if (!btn) return;

        if (btn.dataset.digit) {
            state = inputDigit(state, btn.dataset.digit);
            updateDisplay();
        } else if (btn.dataset.operator) {
            state = inputOperator(state, btn.dataset.operator);
        } else if (btn.dataset.action) {
            switch (btn.dataset.action) {
                case 'clear': state = clear(state); updateDisplay(); break;
                case 'decimal': state = inputDecimal(state); updateDisplay(); break;
                case 'equals': await handleEquals(); break;
                case 'memory-add': await handleMemoryAdd(); break;
                case 'memory-subtract': await handleMemorySubtract(); break;
                case 'memory-recall': await handleMemoryRecall(); break;
                case 'memory-clear': await handleMemoryClear(); break;
            }
        }
    });

    updateDisplay();
})();

