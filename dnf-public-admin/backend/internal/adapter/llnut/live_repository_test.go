package llnut

import "testing"

func TestScanAccountRow(t *testing.T) {
    account := AccountFromRow(100, "player", 0, 0)
    if account.ID != "100" || account.Username != "player" || account.Status != "active" {
        t.Fatalf("unexpected account: %#v", account)
    }
}

func TestAdminAccountStatus(t *testing.T) {
    account := AccountFromRow(1, "admin", 1, 0)
    if account.Status != "admin" {
        t.Fatalf("expected admin status, got %#v", account)
    }
}

func TestCharacterFromRow(t *testing.T) {
    character := CharacterFromRow(10, "角色", 70, 2, 100)
    if character.ID != "10" || character.AccountID != "100" || character.Level != 70 {
        t.Fatalf("unexpected character: %#v", character)
    }
}
