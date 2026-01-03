FROM python:3.10-slim

WORKDIR /app

# Install uv
RUN pip install uv

# Copy dependency files
COPY pyproject.toml uv.lock ./

# Install dependencies
RUN uv sync --frozen --no-dev

# Copy application code
COPY backend/ ./backend/
COPY .env* ./

# Create data directory
RUN mkdir -p data/conversations

# Expose port
EXPOSE 8001

# Run the application
CMD ["uv", "run", "python", "-m", "backend.main"]
