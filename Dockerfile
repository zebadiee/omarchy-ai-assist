FROM python:3.12-slim AS base
RUN apt-get update && apt-get install -y --no-install-recommends git jq bash ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY . /app
# Palimpsest optional
RUN if [ -f pyproject.toml ]; then pip install -e .; fi
# Mitq optional
# (Build separately and COPY in if you want the Go binary inside)

CMD ["bash"]