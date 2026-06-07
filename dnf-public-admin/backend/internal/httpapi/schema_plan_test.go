package httpapi

import (
    "encoding/json"
    "net/http"
    "net/http/httptest"
    "testing"
)

func TestLlnutReadOnlyPlansEndpoint(t *testing.T) {
    r := NewRouter("dnf-public-admin")
    req := httptest.NewRequest(http.MethodGet, "/api/v1/meta/llnut-readonly-plans", nil)
    resp := httptest.NewRecorder()

    r.ServeHTTP(resp, req)

    if resp.Code != http.StatusOK {
        t.Fatalf("expected 200, got %d", resp.Code)
    }

    var payload struct {
        Plans []struct {
            Name string `json:"name"`
            Mode string `json:"mode"`
        } `json:"plans"`
    }
    if err := json.Unmarshal(resp.Body.Bytes(), &payload); err != nil {
        t.Fatalf("decode response: %v", err)
    }
    if len(payload.Plans) < 3 {
        t.Fatalf("expected account, character and billing read-only plans")
    }
    for _, plan := range payload.Plans {
        if plan.Mode == "" || plan.Mode == "write" {
            t.Fatalf("unsafe or missing mode for plan %#v", plan)
        }
    }
}
