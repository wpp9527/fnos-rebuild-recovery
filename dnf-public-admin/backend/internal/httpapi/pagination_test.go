package httpapi

import (
    "encoding/json"
    "net/http"
    "net/http/httptest"
    "testing"
)

func TestAccountsEndpointReturnsPagination(t *testing.T) {
    r := NewRouter("dnf-public-admin")
    req := httptest.NewRequest(http.MethodGet, "/api/v1/accounts?limit=1&offset=2", nil)
    resp := httptest.NewRecorder()

    r.ServeHTTP(resp, req)

    if resp.Code != http.StatusOK {
        t.Fatalf("expected 200, got %d", resp.Code)
    }
    var payload struct {
        Limit int `json:"limit"`
        Offset int `json:"offset"`
    }
    if err := json.Unmarshal(resp.Body.Bytes(), &payload); err != nil {
        t.Fatalf("decode response: %v", err)
    }
    if payload.Limit != 1 || payload.Offset != 2 {
        t.Fatalf("unexpected pagination: %#v", payload)
    }
}
