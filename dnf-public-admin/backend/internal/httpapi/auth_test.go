package httpapi

import (
    "bytes"
    "encoding/json"
    "net/http"
    "net/http/httptest"
    "testing"
)

func TestLoginValidation(t *testing.T) {
    r := NewRouter("dnf-public-admin")
    req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/login", bytes.NewBufferString(`{}`))
    req.Header.Set("Content-Type", "application/json")
    resp := httptest.NewRecorder()

    r.ServeHTTP(resp, req)

    if resp.Code != http.StatusBadRequest {
        t.Fatalf("expected 400, got %d", resp.Code)
    }
}

func TestLoginSuccess(t *testing.T) {
    r := NewRouter("dnf-public-admin")
    body := map[string]string{"username": "admin", "password": "admin123"}
    raw, _ := json.Marshal(body)
    req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/login", bytes.NewReader(raw))
    req.Header.Set("Content-Type", "application/json")
    resp := httptest.NewRecorder()

    r.ServeHTTP(resp, req)

    if resp.Code != http.StatusOK {
        t.Fatalf("expected 200, got %d", resp.Code)
    }

    var payload map[string]any
    if err := json.Unmarshal(resp.Body.Bytes(), &payload); err != nil {
        t.Fatalf("decode response: %v", err)
    }
    if payload["token"] == "" {
        t.Fatalf("expected token")
    }
}

func TestCurrentAdminEndpoint(t *testing.T) {
    r := NewRouter("dnf-public-admin")
    req := httptest.NewRequest(http.MethodGet, "/api/v1/auth/me", nil)
    req.Header.Set("Authorization", "Bearer demo-admin-token")
    resp := httptest.NewRecorder()

    r.ServeHTTP(resp, req)

    if resp.Code != http.StatusOK {
        t.Fatalf("expected 200, got %d", resp.Code)
    }
}
