# Use Python 3.13 as base image
FROM --platform=linux/amd64 python:3.13.1-slim as python-base

# Python environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PIP_DEFAULT_TIMEOUT=100 \
    POETRY_VERSION=2.0.1 \
    POETRY_HOME="/opt/poetry" \
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    POETRY_NO_INTERACTION=1 \
    PYSETUP_PATH="/opt/pysetup" \
    VENV_PATH="/opt/pysetup/.venv"

# Add Poetry to PATH
ENV PATH="$POETRY_HOME/bin:$VENV_PATH/bin:$PATH"

# Builder stage
FROM python-base as builder

# Install system dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
        build-essential

# Install Poetry
RUN curl -sSL https://install.python-poetry.org | python3 - --version ${POETRY_VERSION}

# Copy project files
WORKDIR $PYSETUP_PATH
COPY poetry.lock pyproject.toml ./
COPY single_ai ./single_ai/

# Install runtime dependencies
RUN poetry install --only main --no-root

# Final stage
FROM python-base as final

# Install system dependencies and Poetry
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
    && curl -sSL https://install.python-poetry.org | python3 - --version ${POETRY_VERSION} \
    && apt-get remove -y curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Add Poetry to PATH
ENV PATH="$POETRY_HOME/bin:$VENV_PATH/bin:$PATH"

# Copy virtual environment from builder
COPY --from=builder $PYSETUP_PATH $PYSETUP_PATH

# Set working directory
WORKDIR $PYSETUP_PATH

# Copy project files
COPY --from=builder $PYSETUP_PATH/single_ai ./single_ai/
COPY --from=builder $PYSETUP_PATH/poetry.lock $PYSETUP_PATH/pyproject.toml ./

# Create non-root user
RUN groupadd -g 1001 single-ai && \
    useradd -u 1001 -g single-ai single-ai && \
    chown -R single-ai:single-ai $PYSETUP_PATH

USER single-ai

# Expose port
EXPOSE 8000

# Run the application
CMD ["poetry", "run", "uvicorn", "single_ai.server:app", "--host", "0.0.0.0", "--port", "8000"]
