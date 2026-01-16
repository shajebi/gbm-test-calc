"""FastAPI calculator application."""

from pathlib import Path

from fastapi import FastAPI, Request
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles

from src.exceptions import CalculatorError
from src.routes.calculate import router as calculate_router
from src.routes.memory import router as memory_router

STATIC_DIR = Path(__file__).parent.parent / "static"

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

# Mount static files for frontend
if STATIC_DIR.exists():
    app.mount("/static", StaticFiles(directory=str(STATIC_DIR)), name="static")


@app.get("/")
def serve_index() -> FileResponse:
    """Serve the calculator frontend."""
    return FileResponse(STATIC_DIR / "index.html")


@app.get("/health")
def health_check() -> dict[str, str]:
    """Health check endpoint."""
    return {"status": "healthy"}
