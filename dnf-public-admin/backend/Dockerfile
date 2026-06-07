FROM golang:1.19 AS test
WORKDIR /src
COPY backend/go.mod ./
COPY backend/cmd ./cmd
COPY backend/internal ./internal
RUN go test ./...

FROM golang:1.19 AS build
WORKDIR /src
COPY backend/go.mod ./
COPY backend/cmd ./cmd
COPY backend/internal ./internal
RUN CGO_ENABLED=0 GOOS=linux go build -o /out/dnf-public-admin ./cmd/server

FROM alpine:3.20
RUN adduser -D -H appuser
USER appuser
COPY --from=build /out/dnf-public-admin /usr/local/bin/dnf-public-admin
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/dnf-public-admin"]
