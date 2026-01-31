# ==============================================
# 🚀 HeadlessX Frontend - Next.js Dashboard
# ==============================================
# Build context: project root (.)
# ==============================================

# Stage 1: Dependencies
FROM node:22-slim AS deps

# Install pnpm
RUN corepack enable && corepack prepare pnpm@9.15.0 --activate

WORKDIR /app

# Copy workspace and frontend package files
COPY pnpm-workspace.yaml package.json pnpm-lock.yaml ./
COPY frontend/package.json ./frontend/

# Install ONLY frontend dependencies
RUN pnpm install --frozen-lockfile --filter headlessx-frontend...

# ==============================================
# Stage 2: Builder
# ==============================================
FROM node:22-slim AS builder

# Install pnpm
RUN corepack enable && corepack prepare pnpm@9.15.0 --activate

WORKDIR /app

# Copy dependencies from deps stage
COPY --from=deps /app/node_modules ./node_modules
COPY --from=deps /app/frontend/node_modules ./frontend/node_modules

# Copy ONLY frontend source code and workspace config
COPY frontend ./frontend
COPY pnpm-workspace.yaml package.json ./

WORKDIR /app/frontend

# Disable Next.js telemetry
ENV NEXT_TELEMETRY_DISABLED=1

# Build arguments for runtime environment variables
ARG NEXT_PUBLIC_API_URL
ENV NEXT_PUBLIC_API_URL=${NEXT_PUBLIC_API_URL}

ARG INTERNAL_API_URL
ENV INTERNAL_API_URL=${INTERNAL_API_URL}

# Build Next.js application
RUN npm run build

# ==============================================
# Stage 3: Production Runtime
# ==============================================
FROM node:22-slim AS runner

WORKDIR /app

# Set production environment
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Create non-root user
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

# Copy public assets
COPY --from=builder /app/frontend/public ./public

# Create .next directory with correct permissions
RUN mkdir .next && chown nextjs:nodejs .next

# Copy standalone server and static files
COPY --from=builder --chown=nextjs:nodejs /app/frontend/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/frontend/.next/static ./frontend/.next/static

# Switch to non-root user
USER nextjs

# Expose port
EXPOSE 3000

# Set environment variables
ENV HOSTNAME="0.0.0.0"
ENV PORT=3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})" || exit 1

# Start Next.js application
# The standalone build creates a minimal server.js in the root
CMD ["node", "frontend/server.js"]
