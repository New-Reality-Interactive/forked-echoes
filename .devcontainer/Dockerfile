FROM mcr.microsoft.com/devcontainers/base:bookworm

# Install Node.js 20 directly via NodeSource — full control over
# ordering, no feature-layer ambiguity about when/as-whom this runs
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# uv provisions Python itself (3.10+) — no system python package needed
ENV UV_INSTALL_DIR="/usr/local/bin"
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Everything from here runs as vscode — no root process touches
# $HOME again after this point, so there's nothing to reconcile
USER vscode

RUN curl -fsSL https://claude.ai/install.sh | bash

ENV HOME="/home/vscode"
ENV PATH="/home/vscode/.local/bin:${PATH}"

WORKDIR /workspace