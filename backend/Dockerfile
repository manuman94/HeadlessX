# ==============================================
# 🚀 HeadlessX Backend - Camoufox Scraping API
# ==============================================
# Build context: project root (.)
# ==============================================

# Stage 1: Dependencies
FROM node:22-slim AS deps

# Install pnpm
RUN corepack enable && corepack prepare pnpm@9.15.0 --activate

# Set working directory
WORKDIR /app

# Copy workspace and backend package files
COPY pnpm-workspace.yaml package.json pnpm-lock.yaml ./
COPY backend/package.json ./backend/

# Install ONLY backend dependencies
RUN pnpm install --frozen-lockfile --filter headlessx-backend...

# ==============================================
# Stage 2: Builder
# ==============================================
FROM node:22-slim AS builder

# Install pnpm
RUN corepack enable && corepack prepare pnpm@9.15.0 --activate

WORKDIR /app

# Copy dependencies from deps stage
COPY --from=deps /app/node_modules ./node_modules
COPY --from=deps /app/backend/node_modules ./backend/node_modules

# Copy ONLY backend source code and workspace config
COPY backend ./backend
COPY pnpm-workspace.yaml package.json pnpm-lock.yaml ./

WORKDIR /app/backend

# Generate Prisma Client
RUN npx prisma generate

# Build TypeScript
RUN npm run build

# ==============================================
# Stage 3: Production Runtime
# ==============================================
FROM node:22-slim AS runner

# Install system dependencies for Camoufox/Firefox
RUN apt-get update && apt-get install -y \
    # GTK3 - Required for Firefox
    libgtk-3-0 \
    libgdk-pixbuf2.0-0 \
    # X11 and display libraries
    libx11-6 \
    libx11-xcb1 \
    libxcb1 \
    libxext6 \
    libxrender1 \
    libxi6 \
    libxtst6 \
    # Browser dependencies
    libnss3 \
    libnspr4 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libdbus-1-3 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libpango-1.0-0 \
    libcairo2 \
    libasound2 \
    libatspi2.0-0 \
    libxshmfence1 \
    # System utilities
    ca-certificates \
    fonts-liberation \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install pnpm globally
RUN corepack enable && corepack prepare pnpm@9.15.0 --activate

WORKDIR /app

# Copy package files and lockfile for dependency installation
COPY --from=builder /app/backend/package.json ./package.json
COPY --from=builder /app/pnpm-lock.yaml ./pnpm-lock.yaml
COPY --from=builder /app/backend/prisma ./prisma

# Install PRODUCTION dependencies only (this will run postinstall and fetch Camoufox)
RUN pnpm install --prod

# Copy built application
COPY --from=builder /app/backend/dist ./dist

# Create necessary directories
RUN mkdir -p ./data/profiles ./logs

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3001
ENV HOST=0.0.0.0

# Copy entrypoint script
COPY backend/docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Expose port
EXPOSE 3001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3001/api/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})" || exit 1

# Use entrypoint to initialize database
ENTRYPOINT ["docker-entrypoint.sh"]

# Start application directly with tsx (handles TypeScript ESM module resolution)
CMD ["npx", "tsx", "dist/server_entry.js"]
