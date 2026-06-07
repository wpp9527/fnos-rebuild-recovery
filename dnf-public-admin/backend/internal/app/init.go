package app

import (
    "database/sql"

    "github.com/wpp9527/dnf-public-admin/backend/internal/adapter/llnut"
)

func NewRepository(mode, dsn string) llnut.Repository {
    var db *sql.DB
    if mode == "live-readonly" && dsn != "" {
        db = llnut.OpenDB(dsn)
    }
    return llnut.NewRepository(db, llnut.ModeDemo)
}
