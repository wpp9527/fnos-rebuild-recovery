package llnut

import (
    "database/sql"
    "errors"
)

type Mode string

const (
    ModeDemo         Mode = "demo"
    ModeLiveReadOnly Mode = "live-readonly"
)

func (m Mode) AllowsWrite() bool {
    return false
}

type Repository struct {
    db   *sql.DB
    mode Mode
    demo Service
}

func NewRepository(db *sql.DB, mode Mode) Repository {
    if mode == "" {
        mode = ModeDemo
    }
    return Repository{db: db, mode: mode, demo: NewService()}
}

func (r Repository) ListAccounts() ([]Account, error) {
    if r.mode == ModeDemo {
        return r.demo.ListAccounts(), nil
    }
    if r.db == nil {
        return nil, errLiveDBRequired()
    }
    return nil, errors.New("live account query is not enabled until schema inspection passes")
}

func (r Repository) ListCharacters() ([]Character, error) {
    if r.mode == ModeDemo {
        return r.demo.ListCharacters(), nil
    }
    if r.db == nil {
        return nil, errLiveDBRequired()
    }
    return nil, errors.New("live character query is not enabled until schema inspection passes")
}

func NormalizeLimitOffset(limit, offset int) (int, int) {
    if limit <= 0 {
        limit = 50
    }
    if limit > 200 {
        limit = 200
    }
    if offset < 0 {
        offset = 0
    }
    return limit, offset
}


func errLiveDBRequired() error {
    return errors.New("live read-only llnut repository requires database connection")
}
