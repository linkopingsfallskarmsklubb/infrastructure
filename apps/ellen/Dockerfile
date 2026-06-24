# syntax=docker/dockerfile:1

FROM python:3.14-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
  gcc \
  curl \
  && rm -rf /var/lib/apt/lists/*
RUN pip install uv

WORKDIR /app
COPY pyproject.toml uv.lock ./

RUN python -m venv /venv \
  && /venv/bin/pip install --upgrade pip \
  && /venv/bin/pip install uv \
  && /venv/bin/pip install .

FROM python:3.14-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
  curl \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /venv /venv

COPY app ./app

ENV PATH="/venv/bin:$PATH"

CMD ["python", "-m", "app.main"]
