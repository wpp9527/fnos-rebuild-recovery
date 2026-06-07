package account

import (
    "testing"

    "github.com/wpp9527/dnf-public-admin/backend/internal/adapter/llnut"
)

func TestServicePropagatesRepositoryErrors(t *testing.T) {
    svc := NewService(llnut.NewRepository(nil, llnut.ModeLiveReadOnly))
    _, err := svc.List()
    if err == nil {
        t.Fatalf("expected repository error")
    }
}
