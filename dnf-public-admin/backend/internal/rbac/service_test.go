package rbac

import "testing"

func TestCanAllowsScopedAction(t *testing.T) {
    if !Can([]string{"activity:write"}, "activity:write") {
        t.Fatalf("expected activity write scope to allow action")
    }
}

func TestCanRejectsMissingScope(t *testing.T) {
    if Can([]string{"account:read"}, "gm:write") {
        t.Fatalf("expected missing gm write scope to be rejected")
    }
}
