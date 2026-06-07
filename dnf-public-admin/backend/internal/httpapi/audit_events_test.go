package httpapi

import (
    "bytes"
    "encoding/json"
    "net/http"
    "net/http/httptest"
    "testing"
)

func TestAuditEventsEndpointIncludesDryRunEvents(t *testing.T) {
    r := NewRouter("dnf-public-admin")

    toggleReq := httptest.NewRequest(http.MethodPost, "/api/v1/activities/native/toggle", bytes.NewBufferString(`{"code":"native-online-gift","enabled":true}`))
    toggleResp := httptest.NewRecorder()
    r.ServeHTTP(toggleResp, toggleReq)
    if toggleResp.Code != http.StatusOK {
        t.Fatalf("toggle expected 200, got %d", toggleResp.Code)
    }

    req := httptest.NewRequest(http.MethodGet, "/api/v1/audit/events", nil)
    resp := httptest.NewRecorder()
    r.ServeHTTP(resp, req)

    if resp.Code != http.StatusOK {
        t.Fatalf("expected 200, got %d", resp.Code)
    }
    var payload struct { Events []map[string]any `json:"events"` }
    if err := json.Unmarshal(resp.Body.Bytes(), &payload); err != nil {
        t.Fatalf("decode response: %v", err)
    }
    if len(payload.Events) == 0 {
        t.Fatalf("expected audit event for dry-run activity toggle")
    }
}
