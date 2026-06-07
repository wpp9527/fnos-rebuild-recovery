package httpapi

import (
    "bytes"
    "encoding/json"
    "net/http"
    "net/http/httptest"
    "testing"
)

func TestPVFSearchEndpoint(t *testing.T) {
    r := NewRouter("dnf-public-admin")
    req := httptest.NewRequest(http.MethodGet, "/api/v1/pvf/items?q=礼盒", nil)
    resp := httptest.NewRecorder()

    r.ServeHTTP(resp, req)

    if resp.Code != http.StatusOK {
        t.Fatalf("expected 200, got %d", resp.Code)
    }
    var payload struct { Items []map[string]any `json:"items"` }
    if err := json.Unmarshal(resp.Body.Bytes(), &payload); err != nil {
        t.Fatalf("decode response: %v", err)
    }
    if len(payload.Items) == 0 {
        t.Fatalf("expected pvf items")
    }
}

func TestPVFGrantPlanEndpointIsDryRun(t *testing.T) {
    r := NewRouter("dnf-public-admin")
    req := httptest.NewRequest(http.MethodPost, "/api/v1/pvf/grant-plan", bytes.NewBufferString(`{"item_id":"1001","character_id":"char-1","quantity":1}`))
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
        t.Fatalf("expected dry-run, got %#v", payload)
    }
}
