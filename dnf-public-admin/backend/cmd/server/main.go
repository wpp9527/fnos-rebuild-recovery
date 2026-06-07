package main

import (
    "log"
    "net/http"

    "github.com/wpp9527/dnf-public-admin/backend/internal/app"
    "github.com/wpp9527/dnf-public-admin/backend/internal/config"
)

func main() {
    cfg := config.Load()
    server := app.NewServer(cfg)
    log.Printf("starting %s on %s", cfg.AppName, cfg.HTTPAddr)
    if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
        log.Fatal(err)
    }
}
