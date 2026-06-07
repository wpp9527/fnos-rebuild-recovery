package auth

import "errors"

type User struct {
    Username string   `json:"username"`
    Role     string   `json:"role"`
    Scopes   []string `json:"scopes"`
}

type LoginResult struct {
    Token string `json:"token"`
    User  User   `json:"user"`
}

type Service struct{}

func NewService() Service {
    return Service{}
}

func (s Service) Login(username, password string) (LoginResult, error) {
    if username == "" || password == "" {
        return LoginResult{}, errors.New("username and password are required")
    }
    if username != "admin" || password != "admin123" {
        return LoginResult{}, errors.New("invalid credentials")
    }
    return LoginResult{
        Token: "demo-admin-token",
        User: User{
            Username: "admin",
            Role:     "super_admin",
            Scopes:   []string{"auth:read", "account:read", "character:read", "gm:write", "audit:read"},
        },
    }, nil
}

func (s Service) Current(token string) (User, error) {
    if token != "demo-admin-token" {
        return User{}, errors.New("unauthorized")
    }
    return User{
        Username: "admin",
        Role:     "super_admin",
        Scopes:   []string{"auth:read", "account:read", "character:read", "gm:write", "audit:read"},
    }, nil
}
