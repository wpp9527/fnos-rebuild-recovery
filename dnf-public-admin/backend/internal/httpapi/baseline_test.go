package httpapi

import (
    "encoding/json"
    "net/http"
    "net/http/httptest"
    "testing"
)

func TestLlnutBaselineEndpoint(t *testing.T) {
    r := NewRouter("dnf-public-admin")
    req := httptest.NewRequest(http.MethodGet, "/api/v1/meta/llnut-baseline", nil)
    resp := httptest.NewRecorder()

    r.ServeHTTP(resp, req)

    if resp.Code != http.StatusOK {
        t.Fatalf("expected 200, got %d", resp.Code)
    }

    var payload struct {
        ProjectName string         `json:"project_name"`
        Ports       map[string]int `json:"ports"`
        Databases   map[string]string `json:"databases"`
        DataPolicy  string         `json:"data_policy"`
    }
    if err := json.Unmarshal(resp.Body.Bytes(), &payload); err != nil {
        t.Fatalf("decode response: %v", err)
    }
    if payload.ProjectName != "dnf-llnut" {
        t.Fatalf("expected dnf-llnut project, got %q", payload.ProjectName)
    }
    if payload.Ports["admin"] != 882 || payload.Ports["supervisor"] != 2000 || payload.Ports["game_login"] != 3000 {
        t.Fatalf("legacy ports drifted: %#v", payload.Ports)
    }
    if payload.Databases["accounts"] != "d_taiwan" || payload.Databases["billing"] != "taiwan_billing" {
        t.Fatalf("legacy database names drifted: %#v", payload.Databases)
    }
    if payload.DataPolicy == "" {
        t.Fatalf("expected explicit data policy")
    }
}
