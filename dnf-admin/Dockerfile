# 前端构建阶段
FROM node:20-alpine AS frontend-builder

WORKDIR /build/frontend

COPY frontend/package.json frontend/package-lock.json* ./
RUN npm install

COPY frontend/ .
RUN npm run build

# 后端构建阶段
FROM golang:1.21-alpine AS backend-builder

WORKDIR /build

RUN apk add --no-cache git

COPY backend/go.mod backend/go.sum ./
RUN go mod download

COPY backend/ .

RUN CGO_ENABLED=0 GOOS=linux go build -o dnf-admin-server ./cmd/server

# 运行阶段
FROM alpine:latest

WORKDIR /app

RUN apk add --no-cache ca-certificates tzdata

# 复制后端二进制
COPY --from=backend-builder /build/dnf-admin-server .

# 复制前端构建产物
COPY --from=frontend-builder /build/frontend/dist ./frontend/dist/

# 复制配置文件
COPY multi-server/ ./multi-server/

RUN adduser -D -u 1000 appuser
USER appuser

EXPOSE 18882

CMD ["./dnf-admin-server"]
