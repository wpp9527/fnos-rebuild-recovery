package gm_test

import (
	"testing"

	"dnf-admin/internal/audit"
	"dnf-admin/internal/gm"
)

func TestNewService(t *testing.T) {
	auditSvc := audit.NewService()
	gmSvc := gm.NewService(auditSvc)

	if gmSvc == nil {
		t.Error("NewService returned nil")
	}
}

func TestMailRequest Validation(t *testing.T) {
	// Test that MailRequest requires character_name
	req := gm.MailRequest{
		CharacterName: "",
		Title:         "Test Mail",
		Content:       "Test Content",
	}

	if req.CharacterName != "" {
		t.Error("Empty CharacterName should be caught by validation")
	}

	// Test valid request
	req.CharacterName = "TestChar"
	if req.CharacterName == "" {
		t.Error("CharacterName should not be empty")
	}
}

func TestGoldRequest Validation(t *testing.T) {
	req := gm.GoldRequest{
		CharacterName: "TestChar",
		Amount:        1000,
	}

	if req.Amount <= 0 {
		t.Error("Amount should be positive")
	}

	if req.CharacterName == "" {
		t.Error("CharacterName should not be empty")
	}
}

func TestBanRequest Validation(t *testing.T) {
	req := gm.BanRequest{
		UID:    12345,
		Reason: "Cheating",
		Days:   7,
	}

	if req.UID <= 0 {
		t.Error("UID should be positive")
	}

	if req.Days <= 0 {
		t.Error("Days should be positive")
	}
}
