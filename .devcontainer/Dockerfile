FROM mcr.microsoft.com/devcontainers/base:bookworm

# Install Node.js 20 directly via NodeSource — full control over
# ordering, no feature-layer ambiguity about when/as-whom this runs
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# uv provisions Python itself (3.10+) — no system python package needed
ENV UV_INSTALL_DIR="/usr/local/bin"
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Runtime deps the Swift toolchain links against on Debian — this is the
# exact list `swiftly init` itself asks for after installing on bookworm
RUN apt-get update \
    && apt-get install -y \
       libicu-dev libedit-dev libsqlite3-dev libncurses-dev \
       libpython3-dev libxml2-dev pkg-config uuid-dev \
    && rm -rf /var/lib/apt/lists/*

# Everything from here runs as vscode — no root process touches
# $HOME again after this point, so there's nothing to reconcile
USER vscode

RUN curl -fsSL https://claude.ai/install.sh | bash

# swiftly manages Swift toolchains per-user (like rustup for Rust); init
# with no --skip-install also fetches+activates the latest stable toolchain
RUN curl -o /tmp/swiftly.tar.gz https://download.swift.org/swiftly/linux/swiftly-$(uname -m).tar.gz \
    && tar zxf /tmp/swiftly.tar.gz -C /tmp \
    && /tmp/swiftly init --assume-yes --quiet-shell-followup \
    && rm -f /tmp/swiftly.tar.gz /tmp/swiftly

ENV HOME="/home/vscode"
ENV SWIFTLY_HOME_DIR="/home/vscode/.local/share/swiftly"
ENV PATH="/home/vscode/.local/bin:${SWIFTLY_HOME_DIR}/bin:${PATH}"

WORKDIR /workspace