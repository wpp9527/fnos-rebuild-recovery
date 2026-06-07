package llnut

import "testing"

func TestAccountListQueryUsesLegacyAccountsTable(t *testing.T) {
    query := AccountListQuery()
    if query != "SELECT UID, accountname, COALESCE(admin, 0) AS admin, COALESCE(parent_uid, 0) AS parent_uid FROM d_taiwan.accounts ORDER BY UID LIMIT ? OFFSET ?" {
        t.Fatalf("unexpected query: %s", query)
    }
}

func TestCharacterListQueryUsesCainDatabase(t *testing.T) {
    query := CharacterListQuery()
    if query == "" {
        t.Fatalf("expected character query")
    }
    if !containsAll(query, []string{"taiwan_cain", "charac", "LIMIT ? OFFSET ?"}) {
        t.Fatalf("query does not look like llnut cain read query: %s", query)
    }
}

func containsAll(value string, parts []string) bool {
    for _, part := range parts {
        found := false
        for i := 0; i+len(part) <= len(value); i++ {
            if value[i:i+len(part)] == part {
                found = true
                break
            }
        }
        if !found {
            return false
        }
    }
    return true
}
