"""FastAPI calculator application."""

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

from src.exceptions import CalculatorError
from src.routes.calculate import router as calculate_router
from src.routes.memory import router as memory_router

app = FastAPI(
    title="Calculator API",
    description="REST API for basic arithmetic operations and memory management",
    version="1.0.0",
)


@app.exception_handler(CalculatorError)
async def calculator_error_handler(
    request: Request, exc: CalculatorError
) -> JSONResponse:
    """Handle calculator-specific errors."""
    return JSONResponse(
        status_code=400,
        content={"error": exc.message, "code": exc.code},
    )


app.include_router(calculate_router)
app.include_router(memory_router)


@app.get("/health")
def health_check() -> dict[str, str]:
    """Health check endpoint."""
    return {"status": "healthy"}

