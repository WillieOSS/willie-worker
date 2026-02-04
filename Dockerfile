FROM docker.io/cloudflare/sandbox:0.7.0

# Using direct binary download for reliability
ENV NODE_VERSION=24.13.0
RUN ARCH="$(dpkg --print-architecture)" \
    && case "${ARCH}" in \
    amd64) NODE_ARCH="x64" ;; \
    arm64) NODE_ARCH="arm64" ;; \
    *) echo "Unsupported architecture: ${ARCH}" >&2; exit 1 ;; \
    esac \
    && apt-get update && apt-get install -y xz-utils ca-certificates rsync \
    && curl -fsSLk https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz -o /tmp/node.tar.xz \
    && tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1 \
    && rm /tmp/node.tar.xz \
    && node --version \
    && npm --version

# Install pnpm globally
RUN npm install -g pnpm

# Install openclaw (CLI is still named openclaw until upstream renames)
# Pin to specific version for reproducible builds
RUN npm install -g openclaw@2026.2.2 \
    && openclaw --version

# Create openclaw directories (paths still use openclaw until upstream renames)
# Templates are stored in /root/.openclaw-templates for initialization
RUN mkdir -p /root/.openclaw \
    && mkdir -p /root/.openclaw-templates \
    && mkdir -p /root/openclaw \
    && mkdir -p /root/openclaw/skills

# Copy startup script
# Build cache bust: 2026-01-28-v26-browser-skill
COPY start-openclaw.sh /usr/local/bin/start-openclaw.sh
RUN chmod +x /usr/local/bin/start-openclaw.sh

# Copy default configuration template
COPY openclaw.json.template /root/.openclaw-templates/openclaw.json.template

# Copy custom skills
COPY skills/ /root/openclaw/skills/

# Set working directory
WORKDIR /root/openclaw

# Expose the gateway port
EXPOSE 18789
