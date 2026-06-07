package httpapi

import (
    "bytes"
    "net/http"
    "net/http/httptest"
    "testing"
)

func TestActivityToggleRequiresWriteScope(t *testing.T) {
    r := NewRouter("dnf-public-admin")
    req := httptest.NewRequest(http.MethodPost, "/api/v1/activities/native/toggle", bytes.NewBufferString(`{"code":"native-online-gift","enabled":true}`))
    req.Header.Set("X-Scopes", "account:read")
    resp := httptest.NewRecorder()

    r.ServeHTTP(resp, req)

    if resp.Code != http.StatusForbidden {
        t.Fatalf("expected 403, got %d", resp.Code)
    }
}
