/**
 * Integration tests for API client
 * Tests AC-004, AC-006, AC-007, AC-008, AC-E01, AC-E02, session persistence
 */

// Mock fetch for testing
global.fetch = jest.fn();
global.localStorage = {
    store: {},
    getItem: function(key) { return this.store[key] || null; },
    setItem: function(key, value) { this.store[key] = value; },
    clear: function() { this.store = {}; }
};
global.crypto = { randomUUID: () => 'test-uuid-123' };

const {
    getOrCreateSessionId,
    calculate,
    memoryAdd,
    memoryRecall,
    memoryClear,
    API_BASE_URL
} = require('../../../static/js/api.js');

beforeEach(() => {
    fetch.mockClear();
    localStorage.clear();
});

describe('API Client', () => {
    // AC-004: API called on equals, result displayed
    test('test_calculate_success', async () => {
        fetch.mockResolvedValueOnce({
            ok: true,
            json: () => Promise.resolve({ result: 8, operation: '5 + 3' })
        });

        const result = await calculate(5, 3, '+');
        expect(result.result).toBe(8);
        expect(fetch).toHaveBeenCalledWith(
            expect.stringContaining('/calculate'),
            expect.objectContaining({ method: 'POST' })
        );
    });

    // AC-E01: Division by zero shows error
    test('test_calculate_division_by_zero', async () => {
        fetch.mockResolvedValueOnce({
            ok: false,
            json: () => Promise.resolve({ error: 'Division by zero', code: 'DIVISION_BY_ZERO' })
        });

        await expect(calculate(5, 0, '/')).rejects.toThrow('Division by zero');
    });

    // AC-E02: Network error handling
    test('test_calculate_network_error', async () => {
        fetch.mockRejectedValueOnce(new Error('Network error'));

        await expect(calculate(5, 3, '+')).rejects.toThrow('Connection error');
    });

    // AC-006: M+ calls API and updates memory
    test('test_memory_add_success', async () => {
        fetch.mockResolvedValueOnce({
            ok: true,
            json: () => Promise.resolve({ memory: 10, operation: 'M+ 10' })
        });

        const result = await memoryAdd(10);
        expect(result.memory).toBe(10);
        expect(fetch).toHaveBeenCalledWith(
            expect.stringContaining('/memory/add'),
            expect.objectContaining({ method: 'POST' })
        );
    });

    // AC-007: MR recalls memory value
    test('test_memory_recall_success', async () => {
        fetch.mockResolvedValueOnce({
            ok: true,
            json: () => Promise.resolve({ memory: 5 })
        });

        const result = await memoryRecall();
        expect(result.memory).toBe(5);
        expect(fetch).toHaveBeenCalledWith(
            expect.stringContaining('/memory'),
            expect.objectContaining({ method: 'GET' })
        );
    });

    // AC-008: MC clears memory
    test('test_memory_clear_success', async () => {
        fetch.mockResolvedValueOnce({
            ok: true,
            json: () => Promise.resolve({ memory: 0, operation: 'MC' })
        });

        const result = await memoryClear();
        expect(result.memory).toBe(0);
        expect(fetch).toHaveBeenCalledWith(
            expect.stringContaining('/memory'),
            expect.objectContaining({ method: 'DELETE' })
        );
    });

    // Session ID persistence
    test('test_session_id_persistence', () => {
        const id1 = getOrCreateSessionId();
        const id2 = getOrCreateSessionId();
        expect(id1).toBe(id2);
        expect(id1).toBe('test-uuid-123');
    });
});

