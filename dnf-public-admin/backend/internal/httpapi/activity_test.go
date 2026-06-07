package httpapi

import (
    "encoding/json"
    "net/http"
    "net/http/httptest"
    "testing"
)

func TestActivitiesListEndpoint(t *testing.T) {
    r := NewRouter("dnf-public-admin")
    req := httptest.NewRequest(http.MethodGet, "/api/v1/activities", nil)
    resp := httptest.NewRecorder()

    r.ServeHTTP(resp, req)

    if resp.Code != http.StatusOK {
        t.Fatalf("expected 200, got %d", resp.Code)
    }

    var payload struct {
        Items []map[string]any `json:"items"`
    }
    if err := json.Unmarshal(resp.Body.Bytes(), &payload); err != nil {
        t.Fatalf("decode response: %v", err)
    }
    if len(payload.Items) == 0 {
        t.Fatalf("expected activities")
    }
}

func TestActivitiesCalendarEndpoint(t *testing.T) {
    r := NewRouter("dnf-public-admin")
    req := httptest.NewRequest(http.MethodGet, "/api/v1/activities/calendar", nil)
    resp := httptest.NewRecorder()

    r.ServeHTTP(resp, req)

    if resp.Code != http.StatusOK {
        t.Fatalf("expected 200, got %d", resp.Code)
    }
}

func TestNativeActivitiesEndpoint(t *testing.T) {
    r := NewRouter("dnf-public-admin")
    req := httptest.NewRequest(http.MethodGet, "/api/v1/activities/native", nil)
    resp := httptest.NewRecorder()

    r.ServeHTTP(resp, req)

    if resp.Code != http.StatusOK {
        t.Fatalf("expected 200, got %d", resp.Code)
    }
}

func TestSyncNativeActivitiesEndpoint(t *testing.T) {
    r := NewRouter("dnf-public-admin")
    req := httptest.NewRequest(http.MethodPost, "/api/v1/activities/native/sync", nil)
    resp := httptest.NewRecorder()

    r.ServeHTTP(resp, req)

    if resp.Code != http.StatusOK {
        t.Fatalf("expected 200, got %d", resp.Code)
    }
}
