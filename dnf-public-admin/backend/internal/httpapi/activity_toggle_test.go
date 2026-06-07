package httpapi

import (
    "bytes"
    "encoding/json"
    "net/http"
    "net/http/httptest"
    "testing"
)

func TestNativeActivityToggleIsDryRun(t *testing.T) {
    r := NewRouter("dnf-public-admin")
    req := httptest.NewRequest(http.MethodPost, "/api/v1/activities/native/toggle", bytes.NewBufferString(`{"code":"native-online-gift","enabled":true}`))
    resp := httptest.NewRecorder()

    r.ServeHTTP(resp, req)

    if resp.Code != http.StatusOK {
        t.Fatalf("expected 200, got %d: %s", resp.Code, resp.Body.String())
    }
    var payload map[string]any
    if err := json.Unmarshal(resp.Body.Bytes(), &payload); err != nil {
        t.Fatalf("decode response: %v", err)
    }
    if payload["mode"] != "dry-run" {
        t.Fatalf("expected dry-run response, got %#v", payload)
    }
}
