package llnut

import "testing"

func TestValidateReadOnlySchemaAllowsLegacyAccountsColumns(t *testing.T) {
    err := ValidateReadOnlySchema(map[string][]string{
        "d_taiwan.accounts": {"UID", "accountname", "admin", "parent_uid"},
    })
    if err != nil {
        t.Fatalf("validate schema: %v", err)
    }
}

func TestValidateReadOnlySchemaRejectsMissingRequiredColumn(t *testing.T) {
    err := ValidateReadOnlySchema(map[string][]string{
        "d_taiwan.accounts": {"UID", "admin", "parent_uid"},
    })
    if err == nil {
        t.Fatalf("expected missing accountname to fail validation")
    }
}
