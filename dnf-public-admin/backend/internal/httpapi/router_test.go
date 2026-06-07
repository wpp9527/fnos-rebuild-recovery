package httpapi

import (
    "encoding/json"
    "net/http"
    "net/http/httptest"
    "testing"
)

func TestHealthEndpoint(t *testing.T) {
    r := NewRouter("dnf-public-admin")
    req := httptest.NewRequest(http.MethodGet, "/api/v1/health", nil)
    resp := httptest.NewRecorder()

    r.ServeHTTP(resp, req)

    if resp.Code != http.StatusOK {
        t.Fatalf("expected 200, got %d", resp.Code)
    }

    var body map[string]string
    if err := json.Unmarshal(resp.Body.Bytes(), &body); err != nil {
        t.Fatalf("unmarshal response: %v", err)
    }

    if body["status"] != "ok" {
        t.Fatalf("expected status ok, got %q", body["status"])
    }
    if body["service"] != "dnf-public-admin" {
        t.Fatalf("expected service dnf-public-admin, got %q", body["service"])
    }
}


func TestModulesEndpoint(t *testing.T) {
    r := NewRouter("dnf-public-admin")
    req := httptest.NewRequest(http.MethodGet, "/api/v1/meta/modules", nil)
    resp := httptest.NewRecorder()

    r.ServeHTTP(resp, req)

    if resp.Code != http.StatusOK {
        t.Fatalf("expected 200, got %d", resp.Code)
    }

    var body struct {
        Modules []map[string]string `json:"modules"`
    }
    if err := json.Unmarshal(resp.Body.Bytes(), &body); err != nil {
        t.Fatalf("unmarshal response: %v", err)
    }
    if len(body.Modules) < 4 {
        t.Fatalf("expected at least 4 modules, got %d", len(body.Modules))
    }
}
