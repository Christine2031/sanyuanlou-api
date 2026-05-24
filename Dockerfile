# ── Build stage ───────────────────────────────────────────────────────────────
FROM node:20-alpine AS builder
WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

# ── Production stage ──────────────────────────────────────────────────────────
FROM node:20-alpine AS runner
WORKDIR /app

# Only production dependencies
COPY package*.json ./
RUN npm ci --omit=dev

COPY --from=builder /app/dist/server.cjs ./dist/server.cjs

# Cloud Run injects PORT=8080 automatically
ENV PORT=8080
ENV NODE_ENV=production

EXPOSE 8080
CMD ["node", "dist/server.cjs"]
