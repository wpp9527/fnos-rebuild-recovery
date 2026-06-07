package httpapi

import (
    "bytes"
    "net/http"
    "net/http/httptest"
    "testing"
)

func TestLlnutSchemaValidateEndpoint(t *testing.T) {
    r := NewRouter("dnf-public-admin")
    body := bytes.NewBufferString(`{"tables":{"d_taiwan.accounts":["UID","accountname","admin","parent_uid"]}}`)
    req := httptest.NewRequest(http.MethodPost, "/api/v1/meta/llnut-schema/validate", body)
    resp := httptest.NewRecorder()

    r.ServeHTTP(resp, req)

    if resp.Code != http.StatusOK {
        t.Fatalf("expected 200, got %d: %s", resp.Code, resp.Body.String())
    }
}

func TestLlnutSchemaValidateEndpointRejectsUnsafeSchema(t *testing.T) {
    r := NewRouter("dnf-public-admin")
    body := bytes.NewBufferString(`{"tables":{"d_taiwan.accounts":["UID"]}}`)
    req := httptest.NewRequest(http.MethodPost, "/api/v1/meta/llnut-schema/validate", body)
    resp := httptest.NewRecorder()

    r.ServeHTTP(resp, req)

    if resp.Code != http.StatusUnprocessableEntity {
        t.Fatalf("expected 422, got %d: %s", resp.Code, resp.Body.String())
    }
}
