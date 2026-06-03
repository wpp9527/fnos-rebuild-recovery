package gm

import (
	"fmt"
	"log"

	"dnf-admin/internal/audit"
	"dnf-admin/internal/database"
)

// Service handles GM operations
type Service struct {
	auditService *audit.Service
}

// NewService creates a new GM service
func NewService(auditSvc *audit.Service) *Service {
	return &Service{
		auditService: auditSvc,
	}
}

// MailRequest represents a mail send request
type MailRequest struct {
	CharacterName string `json:"character_name" binding:"required"`
	Title         string `json:"title" binding:"required"`
	Content       string `json:"content" binding:"required"`
	Gold          int    `json:"gold"`
	Items         []Item `json:"items"`
}

// Item represents an item to send
type Item struct {
	ItemID int `json:"item_id" binding:"required"`
	Count  int `json:"count" binding:"required"`
}

// GoldRequest represents a gold/currency modification
type GoldRequest struct {
	CharacterName string `json:"character_name" binding:"required"`
	Amount        int    `json:"amount" binding:"required"`
}

// LevelRequest represents a level change request
type LevelRequest struct {
	CharacterName string `json:"character_name" binding:"required"`
	Level         int    `json:"level" binding:"required"`
}

// BanRequest represents a ban/unban request
type BanRequest struct {
	UID    int    `json:"uid" binding:"required"`
	Reason string `json:"reason"`
	Days   int    `json:"days"`
}

// SendMail sends a mail to a character
func (s *Service) SendMail(operatorID int, req *MailRequest) error {
	// Get character ID
	var cNo int
	err := database.DB.QueryRow(
		"SELECT c_no FROM characters WHERE c_name = ? LIMIT 1",
		req.CharacterName,
	).Scan(&cNo)
	if err != nil {
		return fmt.Errorf("character not found: %s", req.CharacterName)
	}

	// Insert mail
	result, err := database.DB.Exec(
		`INSERT INTO mail (c_no, mail_title, mail_content, gold, sender_name, mail_date, is_read, is_has_item)
		 VALUES (?, ?, ?, ?, 'GM', NOW(), 0, 0)`,
		cNo, req.Title, req.Content, req.Gold,
	)
	if err != nil {
		return fmt.Errorf("insert mail: %w", err)
	}

	mailID, _ := result.LastInsertId()

	// Insert mail items
	for _, item := range req.Items {
		_, err := database.DB.Exec(
			`INSERT INTO mail_items (mail_id, item_id, count) VALUES (?, ?, ?)`,
			mailID, item.ItemID, item.Count,
		)
		if err != nil {
			return fmt.Errorf("insert mail item: %w", err)
		}
	}

	// Log the operation
	s.auditService.Log(audit.LogEntry{
		OperatorID: operatorID,
		Action:     "send_mail",
		Target:     req.CharacterName,
		Detail:     fmt.Sprintf("Title: %s, Gold: %d, Items: %d", req.Title, req.Gold, len(req.Items)),
	})

	log.Printf("Mail sent to %s: title=%s, gold=%d, items=%d", req.CharacterName, req.Title, req.Gold, len(req.Items))
	return nil
}

// SendGold adds gold to a character
func (s *Service) SendGold(operatorID int, req *GoldRequest) error {
	// Get character and account
	var uid int
	err := database.DB.QueryRow(
		"SELECT uid FROM characters WHERE c_name = ? LIMIT 1",
		req.CharacterName,
	).Scan(&uid)
	if err != nil {
		return fmt.Errorf("character not found: %s", req.CharacterName)
	}

	// Update gold
	_, err = database.DB.Exec(
		"UPDATE accounts SET coin = coin + ? WHERE uid = ?",
		req.Amount, uid,
	)
	if err != nil {
		return fmt.Errorf("update gold: %w", err)
	}

	s.auditService.Log(audit.LogEntry{
		OperatorID: operatorID,
		Action:     "send_gold",
		Target:     req.CharacterName,
		Detail:     fmt.Sprintf("Amount: %d", req.Amount),
	})

	log.Printf("Gold added to %s: amount=%d", req.CharacterName, req.Amount)
	return nil
}

// SendCera adds cera (cash currency) to an account
func (s *Service) SendCera(operatorID int, req *GoldRequest) error {
	var uid int
	err := database.DB.QueryRow(
		"SELECT uid FROM characters WHERE c_name = ? LIMIT 1",
		req.CharacterName,
	).Scan(&uid)
	if err != nil {
		return fmt.Errorf("character not found: %s", req.CharacterName)
	}

	_, err = database.DB.Exec(
		"UPDATE accounts SET cera = cera + ? WHERE uid = ?",
		req.Amount, uid,
	)
	if err != nil {
		return fmt.Errorf("update cera: %w", err)
	}

	s.auditService.Log(audit.LogEntry{
		OperatorID: operatorID,
		Action:     "send_cera",
		Target:     req.CharacterName,
		Detail:     fmt.Sprintf("Amount: %d", req.Amount),
	})

	log.Printf("Cera added to %s: amount=%d", req.CharacterName, req.Amount)
	return nil
}

// SetLevel sets a character's level
func (s *Service) SetLevel(operatorID int, req *LevelRequest) error {
	_, err := database.DB.Exec(
		"UPDATE characters SET c_level = ? WHERE c_name = ?",
		req.Level, req.CharacterName,
	)
	if err != nil {
		return fmt.Errorf("update level: %w", err)
	}

	s.auditService.Log(audit.LogEntry{
		OperatorID: operatorID,
		Action:     "set_level",
		Target:     req.CharacterName,
		Detail:     fmt.Sprintf("Level: %d", req.Level),
	})

	log.Printf("Level set for %s: level=%d", req.CharacterName, req.Level)
	return nil
}

// ResetFatigue resets a character's fatigue
func (s *Service) ResetFatigue(operatorID int, characterName string) error {
	_, err := database.DB.Exec(
		"UPDATE characters SET c_fatigue = 0 WHERE c_name = ?",
		characterName,
	)
	if err != nil {
		return fmt.Errorf("reset fatigue: %w", err)
	}

	s.auditService.Log(audit.LogEntry{
		OperatorID: operatorID,
		Action:     "reset_fatigue",
		Target:     characterName,
		Detail:     "Fatigue reset to 0",
	})

	log.Printf("Fatigue reset for %s", characterName)
	return nil
}

// BanAccount bans a game account
func (s *Service) BanAccount(operatorID int, req *BanRequest) error {
	_, err := database.DB.Exec(
		"UPDATE accounts SET status = 2 WHERE uid = ?",
		req.UID,
	)
	if err != nil {
		return fmt.Errorf("ban account: %w", err)
	}

	// Record ban
	database.DB.Exec(
		`INSERT INTO ban_logs (uid, reason, operator_id, ban_time, expire_time)
		 VALUES (?, ?, ?, NOW(), DATE_ADD(NOW(), INTERVAL ? DAY))`,
		req.UID, req.Reason, operatorID, req.Days,
	)

	s.auditService.Log(audit.LogEntry{
		OperatorID: operatorID,
		Action:     "ban_account",
		Target:     fmt.Sprintf("UID:%d", req.UID),
		Detail:     fmt.Sprintf("Reason: %s, Days: %d", req.Reason, req.Days),
	})

	log.Printf("Account banned: UID=%d, reason=%s, days=%d", req.UID, req.Reason, req.Days)
	return nil
}

// UnbanAccount unbans a game account
func (s *Service) UnbanAccount(operatorID int, uid int) error {
	_, err := database.DB.Exec(
		"UPDATE accounts SET status = 1 WHERE uid = ?",
		uid,
	)
	if err != nil {
		return fmt.Errorf("unban account: %w", err)
	}

	s.auditService.Log(audit.LogEntry{
		OperatorID: operatorID,
		Action:     "unban_account",
		Target:     fmt.Sprintf("UID:%d", uid),
		Detail:     "Account unbanned",
	})

	log.Printf("Account unbanned: UID=%d", uid)
	return nil
}

// SendItem sends an item directly to a character
func (s *Service) SendItem(operatorID int, characterName string, itemID int, count int) error {
	var cNo int
	err := database.DB.QueryRow(
		"SELECT c_no FROM characters WHERE c_name = ? LIMIT 1",
		characterName,
	).Scan(&cNo)
	if err != nil {
		return fmt.Errorf("character not found: %s", characterName)
	}

	// Find empty slot
	var maxSlot int
	database.DB.QueryRow(
		"SELECT COALESCE(MAX(slot_no), 0) FROM character_items WHERE c_no = ?",
		cNo,
	).Scan(&maxSlot)

	_, err = database.DB.Exec(
		`INSERT INTO character_items (c_no, slot_no, item_id, item_name, count, enhance, rarity)
		 VALUES (?, ?, ?, '', ?, 0, 0)`,
		cNo, maxSlot+1, itemID, count,
	)
	if err != nil {
		return fmt.Errorf("insert item: %w", err)
	}

	s.auditService.Log(audit.LogEntry{
		OperatorID: operatorID,
		Action:     "send_item",
		Target:     characterName,
		Detail:     fmt.Sprintf("ItemID: %d, Count: %d", itemID, count),
	})

	log.Printf("Item sent to %s: itemID=%d, count=%d", characterName, itemID, count)
	return nil
}
