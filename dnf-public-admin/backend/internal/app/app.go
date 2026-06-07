package app

import (
    "database/sql"
    "log"
    "net/http"

    "github.com/wpp9527/dnf-public-admin/backend/internal/adapter/llnut"
    "github.com/wpp9527/dnf-public-admin/backend/internal/config"
    "github.com/wpp9527/dnf-public-admin/backend/internal/httpapi"
    _ "github.com/go-sql-driver/mysql"
)

func NewServer(cfg config.Config) *http.Server {
    mode := config.LlnutModeFromEnv()
    dsn := config.LlnutDSN()
    
    var db *sql.DB
    var repoMode llnut.Mode
    
    if mode == "live-readonly" && dsn != "" {
        var err error
        db, err = sql.Open("mysql", dsn)
        if err != nil {
            log.Printf("warning: failed to connect to database: %v, falling back to demo mode", err)
            repoMode = llnut.ModeDemo
        } else {
            if err := db.Ping(); err != nil {
                log.Printf("warning: failed to ping database: %v, falling back to demo mode", err)
                db = nil
                repoMode = llnut.ModeDemo
            } else {
                log.Printf("connected to database in live-readonly mode")
                repoMode = llnut.ModeLiveReadOnly
            }
        }
    } else {
        repoMode = llnut.ModeDemo
        log.Printf("running in demo mode (mode=%s, dsn_empty=%v)", mode, dsn == "")
    }
    
    repo := llnut.NewRepository(db, repoMode)
    
    return &http.Server{
        Addr:    cfg.HTTPAddr,
        Handler: httpapi.NewRouterWithRepo(cfg.AppName, repo),
    }
}
