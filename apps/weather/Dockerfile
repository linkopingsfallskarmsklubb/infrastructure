# syntax=docker/dockerfile:1

FROM python:3.13-slim AS builder

# Install build dependencies and uv
RUN apt-get update && apt-get install -y --no-install-recommends \
  gcc \
  libpq-dev \
  curl \
  && rm -rf /var/lib/apt/lists/*
RUN pip install uv

WORKDIR /app
COPY pyproject.toml uv.lock ./

# Create virtual environment and install dependencies
RUN python -m venv /venv \
  && /venv/bin/pip install --upgrade pip \
  && /venv/bin/pip install uv \
  && /venv/bin/pip install .

FROM python:3.13-slim

# Install runtime PostgreSQL libraries
RUN apt-get update && apt-get install -y --no-install-recommends \
  libpq5 \
  curl \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy virtual environment from builder
COPY --from=builder /venv /venv

# Copy application code
COPY app ./app

ENV PATH="/venv/bin:$PATH"

CMD ["python", "-m", "app.main"]



