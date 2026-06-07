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

// ListServers returns all connected servers
func (s *Service) ListServers() []map[string]interface{} {
	return database.ListServers()
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
func (s *Service) SendMail(operatorID int, serverID string, req *MailRequest) error {
	if req == nil {
		return fmt.Errorf("mail request is nil")
	}

	// Get character ID from the specified server
	sdb, err := database.GetServerDB(serverID)
	if err != nil {
		return fmt.Errorf("server not found: %s", serverID)
	}
	if sdb == nil || sdb.DB == nil {
		return fmt.Errorf("server %s database not available", serverID)
	}

	var cNo int
	err = sdb.DB.QueryRow(
		"SELECT charac_no FROM taiwan_cain.charac_info WHERE charac_name = ? LIMIT 1",
		req.CharacterName,
	).Scan(&cNo)
	if err != nil {
		return fmt.Errorf("character not found: %s", req.CharacterName)
	}

	// Insert mail into taiwan_cain_2nd.postal
	var itemID, itemCount int
	if len(req.Items) > 0 {
		itemID = req.Items[0].ItemID
		itemCount = req.Items[0].Count
	}
	result, err := sdb.DB.Exec(
		`INSERT INTO taiwan_cain_2nd.postal 
			(occ_time, send_charac_name, receive_charac_no, item_id, add_info, upgrade, gold, letter_id)
		 VALUES (NOW(), 'GM', ?, ?, ?, 0, ?, 0)`,
		cNo, itemID, itemCount, req.Gold,
	)
	if err != nil {
		return fmt.Errorf("insert mail: %w", err)
	}

	_, _ = result.LastInsertId()

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
func (s *Service) SendGold(operatorID int, serverID string, req *GoldRequest) error {
	if req == nil {
		return fmt.Errorf("gold request is nil")
	}

	sdb, err := database.GetServerDB(serverID)
	if err != nil {
		return fmt.Errorf("server not found: %s", serverID)
	}
	if sdb == nil || sdb.DB == nil {
		return fmt.Errorf("server %s database not available", serverID)
	}

	// Get character and account
	var mID int
	err = sdb.DB.QueryRow(
		"SELECT m_id FROM taiwan_cain.charac_info WHERE charac_name = ? LIMIT 1",
		req.CharacterName,
	).Scan(&mID)
	if err != nil {
		return fmt.Errorf("character not found: %s", req.CharacterName)
	}

	// Update gold in taiwan_billing.cash_cera
	_, err = sdb.DB.Exec(
		"UPDATE taiwan_billing.cash_cera SET cera = cera + ? WHERE account = ?",
		req.Amount, mID,
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
func (s *Service) SendCera(operatorID int, serverID string, req *GoldRequest) error {
	if req == nil {
		return fmt.Errorf("cera request is nil")
	}

	sdb, err := database.GetServerDB(serverID)
	if err != nil {
		return fmt.Errorf("server not found: %s", serverID)
	}
	if sdb == nil || sdb.DB == nil {
		return fmt.Errorf("server %s database not available", serverID)
	}

	var mID int
	err = sdb.DB.QueryRow(
		"SELECT m_id FROM taiwan_cain.charac_info WHERE charac_name = ? LIMIT 1",
		req.CharacterName,
	).Scan(&mID)
	if err != nil {
		return fmt.Errorf("character not found: %s", req.CharacterName)
	}

	_, err = sdb.DB.Exec(
		"UPDATE taiwan_billing.cash_cera SET cera = cera + ? WHERE account = ?",
		req.Amount, mID,
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
func (s *Service) SetLevel(operatorID int, serverID string, req *LevelRequest) error {
	if req == nil {
		return fmt.Errorf("level request is nil")
	}

	sdb, err := database.GetServerDB(serverID)
	if err != nil {
		return fmt.Errorf("server not found: %s", serverID)
	}
	if sdb == nil || sdb.DB == nil {
		return fmt.Errorf("server %s database not available", serverID)
	}

	_, err = sdb.DB.Exec(
		"UPDATE taiwan_cain.charac_info SET lev = ? WHERE charac_name = ?",
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
func (s *Service) ResetFatigue(operatorID int, serverID string, characterName string) error {
	if characterName == "" {
		return fmt.Errorf("character name is empty")
	}

	sdb, err := database.GetServerDB(serverID)
	if err != nil {
		return fmt.Errorf("server not found: %s", serverID)
	}
	if sdb == nil || sdb.DB == nil {
		return fmt.Errorf("server %s database not available", serverID)
	}

	_, err = sdb.DB.Exec(
		"UPDATE taiwan_cain.charac_info SET fatigue = 0 WHERE charac_name = ?",
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
func (s *Service) BanAccount(operatorID int, serverID string, req *BanRequest) error {
	if req == nil {
		return fmt.Errorf("ban request is nil")
	}

	sdb, err := database.GetServerDB(serverID)
	if err != nil {
		return fmt.Errorf("server not found: %s", serverID)
	}
	if sdb == nil || sdb.DB == nil {
		return fmt.Errorf("server %s database not available", serverID)
	}

	_, err = sdb.DB.Exec(
		"INSERT INTO d_taiwan.member_punish_info (m_id, punish_type, occ_time, punish_value, apply_flag, start_time, end_time, reason) VALUES (?, 1, NOW(), 101, 2, NOW(), DATE_ADD(NOW(), INTERVAL ? DAY), ?)",
		req.UID, req.Days, req.Reason,
	)
	if err != nil {
		return fmt.Errorf("ban account: %w", err)
	}

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
func (s *Service) UnbanAccount(operatorID int, serverID string, uid int) error {
	sdb, err := database.GetServerDB(serverID)
	if err != nil {
		return fmt.Errorf("server not found: %s", serverID)
	}
	if sdb == nil || sdb.DB == nil {
		return fmt.Errorf("server %s database not available", serverID)
	}

	_, err = sdb.DB.Exec(
		"DELETE FROM d_taiwan.member_punish_info WHERE m_id = ?",
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
func (s *Service) SendItem(operatorID int, serverID string, characterName string, itemID int, count int) error {
	if characterName == "" {
		return fmt.Errorf("character name is empty")
	}
	if itemID <= 0 {
		return fmt.Errorf("invalid item ID: %d", itemID)
	}
	if count <= 0 {
		return fmt.Errorf("invalid item count: %d", count)
	}

	sdb, err := database.GetServerDB(serverID)
	if err != nil {
		return fmt.Errorf("server not found: %s", serverID)
	}
	if sdb == nil || sdb.DB == nil {
		return fmt.Errorf("server %s database not available", serverID)
	}

	var cNo int
	err = sdb.DB.QueryRow(
		"SELECT charac_no FROM taiwan_cain.charac_info WHERE charac_name = ? LIMIT 1",
		characterName,
	).Scan(&cNo)
	if err != nil {
		return fmt.Errorf("character not found: %s", characterName)
	}

	// Send via postal system
	_, err = sdb.DB.Exec(
		`INSERT INTO taiwan_cain_2nd.postal 
			(occ_time, send_charac_name, receive_charac_no, item_id, add_info, upgrade, gold, letter_id)
		 VALUES (NOW(), 'GM', ?, ?, ?, 0, 0, 0)`,
		cNo, itemID, count,
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
