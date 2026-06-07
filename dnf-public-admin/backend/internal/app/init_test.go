package app

import (
    "testing"

    "github.com/wpp9527/dnf-public-admin/backend/internal/adapter/llnut"
)


func TestNewRepositoryReturnsDemoRepositoryWithoutDSN(t *testing.T) {
    repo := NewRepository("demo", "")
    if repo == (llnut.Repository{}) {
        t.Fatalf("expected repository")
    }
}
