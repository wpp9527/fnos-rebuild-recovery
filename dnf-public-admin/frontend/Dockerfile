FROM node:22-alpine AS check
WORKDIR /app
COPY frontend/package.json ./
COPY frontend/scripts ./scripts
COPY frontend/src ./src
COPY frontend/index.html ./
RUN npm run check

FROM nginx:alpine
COPY --from=check /app /usr/share/nginx/html
