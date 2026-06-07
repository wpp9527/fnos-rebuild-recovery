package llnut

import "testing"

func TestNewRepositoryDefaultsToDemoMode(t *testing.T) {
    repo := NewRepository(nil, ModeDemo)
    accounts, err := repo.ListAccounts()
    if err != nil {
        t.Fatalf("list demo accounts: %v", err)
    }
    if len(accounts) == 0 {
        t.Fatalf("expected demo accounts")
    }
}

func TestRepositoryRejectsLiveModeWithoutDB(t *testing.T) {
    repo := NewRepository(nil, ModeLiveReadOnly)
    _, err := repo.ListAccounts()
    if err == nil {
        t.Fatalf("expected live mode without db to fail")
    }
}

func TestRepositoryModeRejectsWrites(t *testing.T) {
    if ModeLiveReadOnly.AllowsWrite() {
        t.Fatalf("live read-only mode must not allow writes")
    }
    if ModeDemo.AllowsWrite() {
        t.Fatalf("demo mode must not allow writes")
    }
}


func TestNormalizeLimitOffset(t *testing.T) {
    limit, offset := NormalizeLimitOffset(0, -1)
    if limit != 50 || offset != 0 {
        t.Fatalf("expected safe defaults, got limit=%d offset=%d", limit, offset)
    }
    limit, offset = NormalizeLimitOffset(1000, 5)
    if limit != 200 || offset != 5 {
        t.Fatalf("expected max limit clamp, got limit=%d offset=%d", limit, offset)
    }
}
