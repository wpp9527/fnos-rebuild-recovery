package activity

import "testing"

func TestToggleNativeRequiresKnownActivity(t *testing.T) {
    svc := NewService()
    _, err := svc.ToggleNative("missing", true)
    if err == nil {
        t.Fatalf("expected unknown native activity to fail")
    }
}

func TestToggleNativeIsDryRunByDefault(t *testing.T) {
    svc := NewService()
    result, err := svc.ToggleNative("native-online-gift", true)
    if err != nil {
        t.Fatalf("toggle native: %v", err)
    }
    if result["mode"] != "dry-run" {
        t.Fatalf("expected dry-run mode, got %#v", result)
    }
    if result["status"] != "planned" {
        t.Fatalf("expected planned status, got %#v", result)
    }
}
