FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY tiannara_saas/package*.json ./
RUN npm ci

# Copy source code
COPY tiannara_saas/ .

# Build production bundle
RUN npm run build

# Production stage
FROM nginx:alpine

# Copy custom nginx config
COPY docker/saas/nginx.conf /etc/nginx/conf.d/default.conf

# Copy built assets
COPY --from=builder /app/out /usr/share/nginx/html

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD wget -qO- http://localhost:3000 || exit 1

CMD ["nginx", "-g", "daemon off;"]
