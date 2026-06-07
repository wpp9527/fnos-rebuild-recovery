package character

import (
    "testing"

    "github.com/wpp9527/dnf-public-admin/backend/internal/adapter/llnut"
)

type pageRepo struct{}
func (pageRepo) ListCharacters() ([]llnut.Character, error) { return nil, nil }
func (pageRepo) ListCharactersPage(limit, offset int) ([]llnut.Character, error) {
    return []llnut.Character{{ID: "limit", Name: "offset"}}, nil
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
