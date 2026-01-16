const API_BASE_URL = typeof window !== 'undefined' ? window.location.origin : 'http://localhost:8000';

function getOrCreateSessionId() {
    let sessionId = localStorage.getItem('calculator_session_id');
    if (!sessionId) {
        sessionId = crypto.randomUUID();
        localStorage.setItem('calculator_session_id', sessionId);
    }
    return sessionId;
}

async function apiRequest(path, options = {}) {
    const headers = {
        'Content-Type': 'application/json',
        'X-Session-ID': getOrCreateSessionId(),
        ...options.headers
    };

    try {
        const response = await fetch(`${API_BASE_URL}${path}`, { ...options, headers });
        const data = await response.json();

        if (!response.ok) {
            throw new Error(data.error || 'Request failed');
        }
        return data;
    } catch (error) {
        if (error.message.includes('fetch')) {
            throw new Error('Connection error');
        }
        throw error;
    }
}

async function calculate(operand1, operand2, operator) {
    return apiRequest('/calculate', {
        method: 'POST',
        body: JSON.stringify({ operand1, operand2, operator })
    });
}

async function memoryAdd(value) {
    return apiRequest('/memory/add', {
        method: 'POST',
        body: JSON.stringify({ value })
    });
}

async function memorySubtract(value) {
    return apiRequest('/memory/subtract', {
        method: 'POST',
        body: JSON.stringify({ value })
    });
}

async function memoryRecall() {
    return apiRequest('/memory', { method: 'GET' });
}

async function memoryClear() {
    return apiRequest('/memory', { method: 'DELETE' });
}

if (typeof module !== 'undefined' && module.exports) {
    module.exports = { getOrCreateSessionId, calculate, memoryAdd, memorySubtract, memoryRecall, memoryClear, API_BASE_URL };
}

