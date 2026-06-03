package auth_test

import (
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"dnf-admin/internal/auth"
)

func TestHashPassword(t *testing.T) {
	password := "testpassword123"
	hash, err := auth.HashPassword(password)
	if err != nil {
		t.Fatalf("HashPassword failed: %v", err)
	}

	if hash == "" {
		t.Error("HashPassword returned empty hash")
	}

	if hash == password {
		t.Error("HashPassword should not return plaintext")
	}
}

func TestValidateToken(t *testing.T) {
	secret := "test-secret-key"
	service := auth.NewService(secret)

	// Create a valid token
	claims := &auth.Claims{
		UserID:   1,
		Username: "testuser",
		Role:     "admin",
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString([]byte(secret))
	if err != nil {
		t.Fatalf("Failed to sign token: %v", err)
	}

	// Validate the token
	validatedClaims, err := service.ValidateToken(tokenString)
	if err != nil {
		t.Fatalf("ValidateToken failed: %v", err)
	}

	if validatedClaims.UserID != 1 {
		t.Errorf("Expected UserID 1, got %d", validatedClaims.UserID)
	}

	if validatedClaims.Username != "testuser" {
		t.Errorf("Expected Username 'testuser', got '%s'", validatedClaims.Username)
	}

	if validatedClaims.Role != "admin" {
		t.Errorf("Expected Role 'admin', got '%s'", validatedClaims.Role)
	}
}

func TestValidateToken_Expired(t *testing.T) {
	secret := "test-secret-key"
	service := auth.NewService(secret)

	// Create an expired token
	claims := &auth.Claims{
		UserID:   1,
		Username: "testuser",
		Role:     "admin",
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(-time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now().Add(-2 * time.Hour)),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString([]byte(secret))
	if err != nil {
		t.Fatalf("Failed to sign token: %v", err)
	}

	// Try to validate the expired token
	_, err = service.ValidateToken(tokenString)
	if err == nil {
		t.Error("Expected error for expired token, got nil")
	}
}

func TestValidateToken_InvalidSecret(t *testing.T) {
	secret1 := "secret-1"
	secret2 := "secret-2"
	service := auth.NewService(secret1)

	// Create a token with secret2
	claims := &auth.Claims{
		UserID:   1,
		Username: "testuser",
		Role:     "admin",
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString([]byte(secret2))
	if err != nil {
		t.Fatalf("Failed to sign token: %v", err)
	}

	// Try to validate with different secret
	_, err = service.ValidateToken(tokenString)
	if err == nil {
		t.Error("Expected error for invalid secret, got nil")
	}
}
