package account

import (
    "testing"

    "github.com/wpp9527/dnf-public-admin/backend/internal/adapter/llnut"
)

type pageRepo struct{}
func (pageRepo) ListAccounts() ([]llnut.Account, error) { return nil, nil }
func (pageRepo) ListAccountsPage(limit, offset int) ([]llnut.Account, error) {
    return []llnut.Account{{ID: "limit", Username: "offset"}}, nil
}

func TestServiceListPageUsesRepository(t *testing.T) {
    svc := NewService(pageRepo{})
    items, err := svc.ListPage(10, 20)
    if err != nil {
        t.Fatalf("list page: %v", err)
    }
    if len(items) != 1 {
        t.Fatalf("expected items")
    }
}
