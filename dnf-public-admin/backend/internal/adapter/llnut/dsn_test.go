package llnut

import "testing"

func TestBuildMySQLDSNRequiresReadOnlyUser(t *testing.T) {
    _, err := BuildMySQLDSN(MySQLConfig{
        Host:     "127.0.0.1",
        Port:     3306,
        Username: "root",
        Password: "secret",
        Database: DatabaseAccounts,
    })
    if err == nil {
        t.Fatalf("expected root user to be rejected for read-only adapter")
    }
}

func TestBuildMySQLDSNUsesLegacyDatabase(t *testing.T) {
    dsn, err := BuildMySQLDSN(MySQLConfig{
        Host:     "127.0.0.1",
        Port:     3306,
        Username: "dnf_readonly",
        Password: "secret",
        Database: DatabaseAccounts,
    })
    if err != nil {
        t.Fatalf("build dsn: %v", err)
    }
    expected := "dnf_readonly:secret@tcp(127.0.0.1:3306)/d_taiwan?charset=utf8mb4&parseTime=true&loc=Local&readTimeout=5s&timeout=5s"
    if dsn != expected {
        t.Fatalf("unexpected dsn:\nwant %s\n got %s", expected, dsn)
    }
}

func TestBuildMySQLDSNRejectsUnknownGameDatabase(t *testing.T) {
    _, err := BuildMySQLDSN(MySQLConfig{
        Host:     "127.0.0.1",
        Port:     3306,
        Username: "dnf_readonly",
        Password: "secret",
        Database: "dnf_service",
    })
    if err == nil {
        t.Fatalf("expected unknown game database to be rejected")
    }
}
