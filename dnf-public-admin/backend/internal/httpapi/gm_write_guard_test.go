package httpapi

import (
    "bytes"
    "net/http"
    "net/http/httptest"
    "testing"
)

func TestGMWriteEndpointsAreExplicitlyDisabled(t *testing.T) {
    r := NewRouter("dnf-public-admin")
    req := httptest.NewRequest(http.MethodPost, "/api/v1/gm/mail/send", bytes.NewBufferString(`{}`))
    resp := httptest.NewRecorder()

    r.ServeHTTP(resp, req)

    if resp.Code != http.StatusForbidden {
        t.Fatalf("expected write endpoint to be forbidden during readonly phase, got %d", resp.Code)
    }
}
