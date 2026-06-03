package character

import (
	"database/sql"
	"fmt"
	"time"

	"dnf-admin/internal/database"
)

// Character represents a game character
type Character struct {
	CNo        int       `json:"c_no"`
	CName      string    `json:"c_name"`
	CLevel     int       `json:"c_level"`
	CJob       int       `json:"c_job"`
	CFatigue   int       `json:"c_fatigue"`
	CServer    int       `json:"c_server"`
	UID        int       `json:"uid"`
	CLastLogin time.Time `json:"c_last_login"`
}

// CharacterItem represents an item in character's inventory
type CharacterItem struct {
	SlotNo    int    `json:"slot_no"`
	ItemId    int    `json:"item_id"`
	ItemName  string `json:"item_name"`
	Count     int    `json:"count"`
	Enhance   int    `json:"enhance"`
	Rarity    int    `json:"rarity"`
}

// Service handles character operations
type Service struct{}

// NewService creates a new character service
func NewService() *Service {
	return &Service{}
}

// GetByCNo retrieves a character by c_no
func (s *Service) GetByCNo(cNo int) (*Character, error) {
	var c Character
	err := database.DB.QueryRow(
		`SELECT c_no, c_name, c_level, c_job, c_fatigue, c_server, uid, c_last_login
		 FROM characters WHERE c_no = ?`, cNo,
	).Scan(&c.CNo, &c.CName, &c.CLevel, &c.CJob, &c.CFatigue, &c.CServer, &c.UID, &c.CLastLogin)

	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("get character: %w", err)
	}
	return &c, nil
}

// GetItems retrieves items for a character
func (s *Service) GetItems(cNo int) ([]CharacterItem, error) {
	rows, err := database.DB.Query(
		`SELECT slot_no, item_id, item_name, count, enhance, rarity
		 FROM character_items WHERE c_no = ? ORDER BY slot_no`,
		cNo,
	)
	if err != nil {
		return nil, fmt.Errorf("query items: %w", err)
	}
	defer rows.Close()

	var items []CharacterItem
	for rows.Next() {
		var item CharacterItem
		if err := rows.Scan(&item.SlotNo, &item.ItemId, &item.ItemName, &item.Count, &item.Enhance, &item.Rarity); err != nil {
			return nil, fmt.Errorf("scan item: %w", err)
		}
		items = append(items, item)
	}
	return items, nil
}

// GetOnline retrieves online characters
func (s *Service) GetOnline() ([]Character, error) {
	rows, err := database.DB.Query(
		`SELECT c_no, c_name, c_level, c_job, c_fatigue, c_server, uid, c_last_login
		 FROM characters WHERE is_online = 1 ORDER BY c_last_login DESC`,
	)
	if err != nil {
		return nil, fmt.Errorf("query online characters: %w", err)
	}
	defer rows.Close()

	var characters []Character
	for rows.Next() {
		var c Character
		if err := rows.Scan(&c.CNo, &c.CName, &c.CLevel, &c.CJob, &c.CFatigue, &c.CServer, &c.UID, &c.CLastLogin); err != nil {
			return nil, fmt.Errorf("scan character: %w", err)
		}
		characters = append(characters, c)
	}
	return characters, nil
}
