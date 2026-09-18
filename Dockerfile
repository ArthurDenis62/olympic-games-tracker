# syntax=docker/dockerfile:1

# =========================================================
# Stage 1 - Build : compile l'application Angular (Node)
# =========================================================
FROM node:22-alpine AS builder

WORKDIR /app

# Dépendances d'abord : couche mise en cache tant que package*.json ne change pas
COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci --no-audit --no-fund

COPY . .
RUN npm run build

# =========================================================
# Stage 2 - Runtime : Nginx (non-root) sert uniquement dist/
# =========================================================
FROM nginxinc/nginx-unprivileged:1.27-alpine

LABEL org.opencontainers.image.title="olympic-games-tracker" \
      org.opencontainers.image.description="Olympic Participation Tracker (Angular + Nginx)"

COPY nginx/nginx.conf /etc/nginx/nginx.conf
# Le builder "application" d'Angular produit dist/<projet>/browser
COPY --from=builder --chown=nginx:nginx /app/dist/olympic-games-starter/browser /app

EXPOSE 8080

HEALTHCHECK --interval=15s --timeout=3s --start-period=5s --retries=3 \
    CMD ["wget", "-qO-", "http://127.0.0.1:8080/health"]

CMD ["nginx", "-g", "daemon off;"]
