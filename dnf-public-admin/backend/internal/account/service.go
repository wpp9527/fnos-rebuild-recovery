package account

import "github.com/wpp9527/dnf-public-admin/backend/internal/adapter/llnut"

type Repository interface {
    ListAccounts() ([]llnut.Account, error)
}

type PageRepository interface {
    Repository
    ListAccountsPage(limit, offset int) ([]llnut.Account, error)
}

type Service struct {
    repository Repository
}

func NewService(repository Repository) Service {
    return Service{repository: repository}
}

func (s Service) List() ([]llnut.Account, error) {
    return s.repository.ListAccounts()
}

func (s Service) ListPage(limit, offset int) ([]llnut.Account, error) {
    if repo, ok := s.repository.(PageRepository); ok {
        return repo.ListAccountsPage(limit, offset)
    }
    return s.repository.ListAccounts()
}
