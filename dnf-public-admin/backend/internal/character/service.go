package character

import "github.com/wpp9527/dnf-public-admin/backend/internal/adapter/llnut"

type Repository interface {
    ListCharacters() ([]llnut.Character, error)
}

type PageRepository interface {
    Repository
    ListCharactersPage(limit, offset int) ([]llnut.Character, error)
}

type Service struct {
    repository Repository
}

func NewService(repository Repository) Service {
    return Service{repository: repository}
}

func (s Service) List() ([]llnut.Character, error) {
    return s.repository.ListCharacters()
}

func (s Service) ListPage(limit, offset int) ([]llnut.Character, error) {
    if repo, ok := s.repository.(PageRepository); ok {
        return repo.ListCharactersPage(limit, offset)
    }
    return s.repository.ListCharacters()
}
