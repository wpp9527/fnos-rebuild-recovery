package config

import "testing"

func TestLlnutDSNReturnsEmptyWhenIncomplete(t *testing.T) {
    t.Setenv("LLNUT_MYSQL_HOST", "")
    if LlnutDSN() != "" {
        t.Fatalf("expected empty DSN without host")
    }
}

func TestLlnutDSNBuildsFromEnv(t *testing.T) {
    t.Setenv("LLNUT_MYSQL_HOST", "192.168.1.104")
    t.Setenv("LLNUT_MYSQL_PORT", "3306")
    t.Setenv("LLNUT_MYSQL_READONLY_USER", "dnf_readonly")
    t.Setenv("LLNUT_MYSQL_READONLY_PASSWORD", "secret")
    dsn := LlnutDSN()
    if dsn == "" {
        t.Fatalf("expected DSN")
    }
    if dsn != "dnf_readonly:secret@tcp(192.168.1.104:3306)/?parseTime=true" {
        t.Fatalf("unexpected DSN: %s", dsn)
    }
}
