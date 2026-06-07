package config

import (
    "testing"

    "github.com/wpp9527/dnf-public-admin/backend/internal/adapter/llnut"
)

func TestLlnutMySQLConfigFromEnvDefaultsToReadonlyUser(t *testing.T) {
    t.Setenv("LLNUT_MYSQL_HOST", "")
    t.Setenv("LLNUT_MYSQL_PORT", "")
    t.Setenv("LLNUT_MYSQL_READONLY_USER", "")

    cfg := LlnutMySQLConfigFromEnv(llnut.DatabaseAccounts)
    if cfg.Username != "dnf_readonly" {
        t.Fatalf("expected readonly user, got %q", cfg.Username)
    }
    if cfg.Database != llnut.DatabaseAccounts {
        t.Fatalf("expected legacy account database, got %q", cfg.Database)
    }
}
