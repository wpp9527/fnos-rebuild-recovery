package llnut

import "database/sql"

func OpenDB(dsn string) *sql.DB {
    if dsn == "" {
        return nil
    }
    db, err := sql.Open("mysql", dsn)
    if err != nil {
        return nil
    }
    return db
}
