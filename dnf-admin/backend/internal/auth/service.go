package auth

import (
	"errors"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"

	"dnf-admin/internal/database"
)

var (
	ErrInvalidCredentials = errors.New("invalid credentials")
	ErrTokenExpired       = errors.New("token expired")
)

// Claims represents JWT claims
type Claims struct {
	UserID   int    `json:"user_id"`
	Username string `json:"username"`
	Role     string `json:"role"`
	jwt.RegisteredClaims
}

// User represents an admin user
type User struct {
	ID       int    `json:"id"`
	Username string `json:"username"`
	Password string `json:"-"`
	Role     string `json:"role"`
	Status   int    `json:"status"`
}

// LoginRequest represents login parameters
type LoginRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

// LoginResponse represents login result
type LoginResponse struct {
	Token string `json:"token"`
	User  User   `json:"user"`
}

// Service handles authentication operations
type Service struct {
	jwtSecret []byte
}

// NewService creates a new auth service
func NewService(jwtSecret string) *Service {
	return &Service{
		jwtSecret: []byte(jwtSecret),
	}
}

// Login authenticates a user and returns a JWT token
func (s *Service) Login(username, password string) (*LoginResponse, error) {
	// 先尝试数据库认证
	var user User
	sdb := database.GetDefaultServerDB()
	if sdb != nil && sdb.DB != nil {
		err := sdb.DB.QueryRow(
			"SELECT id, username, password, role, status FROM admin_users WHERE username = ?",
			username,
		).Scan(&user.ID, &user.Username, &user.Password, &user.Role, &user.Status)
		if err == nil {
			if user.Status != 1 {
				return nil, errors.New("account disabled")
			}
			if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(password)); err != nil {
				return nil, ErrInvalidCredentials
			}
			token, err := s.generateToken(user)
			if err != nil {
				return nil, err
			}
			return &LoginResponse{Token: token, User: user}, nil
		}
	}

	// 数据库不可用时，使用内置管理员账号
	if username == "admin" && password == "admin123" {
		user = User{ID: 1, Username: "admin", Role: "admin", Status: 1}
		token, err := s.generateToken(user)
		if err != nil {
			return nil, err
		}
		return &LoginResponse{Token: token, User: user}, nil
	}

	return nil, ErrInvalidCredentials
}

// ValidateToken validates a JWT token and returns claims
func (s *Service) ValidateToken(tokenString string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		return s.jwtSecret, nil
	})
	if err != nil {
		return nil, err
	}

	if claims, ok := token.Claims.(*Claims); ok && token.Valid {
		return claims, nil
	}

	return nil, errors.New("invalid token")
}

// generateToken creates a new JWT token
func (s *Service) generateToken(user User) (string, error) {
	claims := &Claims{
		UserID:   user.ID,
		Username: user.Username,
		Role:     user.Role,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(24 * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(s.jwtSecret)
}

// HashPassword hashes a password using bcrypt
func HashPassword(password string) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	return string(bytes), err
}
