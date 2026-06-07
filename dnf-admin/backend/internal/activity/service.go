package activity

import (
	"fmt"
	"sync"

	"dnf-admin/internal/database"
)

type Item struct {
	ID          string `json:"id"`
	Code        string `json:"code"`
	Name        string `json:"name"`
	Type        string `json:"type"`
	Source      string `json:"source"`
	Status      string `json:"status"`
	StartAt     string `json:"start_at"`
	EndAt       string `json:"end_at"`
	Description string `json:"description"`
	ApplyType   int    `json:"apply_type"`
}

type Service struct {
	serverID string
	items    []Item
	loaded   bool
	mu       sync.RWMutex
}

func NewService(serverID string) *Service {
	return &Service{serverID: serverID}
}

func (s *Service) loadFromDB() error {
	s.mu.Lock()
	defer s.mu.Unlock()

	if s.loaded {
		return nil
	}

	sdb, err := database.GetServerDB(s.serverID)
	if err != nil {
		return fmt.Errorf("server not found: %s", s.serverID)
	}

	rows, err := sdb.DB.Query(`
		SELECT event_id, event_name, COALESCE(event_explain, ''), apply_type, 
			   COALESCE(start_date, '0000-00-00'), COALESCE(end_date, '0000-00-00')
		FROM d_taiwan.dnf_event_info 
		ORDER BY event_id
	`)
	if err != nil {
		return fmt.Errorf("query events: %w", err)
	}
	defer rows.Close()

	s.items = nil
	for rows.Next() {
		var id int
		var name, explain, startDate, endDate string
		var applyType int
		if err := rows.Scan(&id, &name, &explain, &applyType, &startDate, &endDate); err != nil {
			continue
		}

		// Determine type based on name
		actType := "event"
		if contains(name, "Fatigue") || contains(explain, "疲劳") {
			actType = "fatigue"
		} else if contains(name, "Exp") || contains(explain, "经验") {
			actType = "exp"
		} else if contains(name, "Coin") || contains(explain, "金币") {
			actType = "coin"
		} else if contains(name, "Drop") || contains(explain, "掉率") {
			actType = "drop"
		}

		s.items = append(s.items, Item{
			ID:          fmt.Sprintf("%d", id),
			Code:        name,
			Name:        explain,
			Type:        actType,
			Source:      "database",
			Status:      "available",
			StartAt:     startDate,
			EndAt:       endDate,
			Description: fmt.Sprintf("事件ID: %d, 应用类型: %d", id, applyType),
			ApplyType:   applyType,
		})
	}

	s.loaded = true
	return nil
}

func contains(s, substr string) bool {
	return len(s) >= len(substr) && (s == substr || len(s) > 0 && (s[0:len(substr)] == substr || contains(s[1:], substr)))
}

func (s *Service) List() ([]Item, error) {
	if err := s.loadFromDB(); err != nil {
		return nil, err
	}
	s.mu.RLock()
	defer s.mu.RUnlock()
	return s.items, nil
}

func (s *Service) Start(userID int, id int) error {
	if err := s.loadFromDB(); err != nil {
		return err
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	for i, item := range s.items {
		if fmt.Sprintf("%d", id) == item.ID {
			s.items[i].Status = "active"
			return nil
		}
	}
	return fmt.Errorf("activity %d not found", id)
}

func (s *Service) Stop(userID int, id int) error {
	if err := s.loadFromDB(); err != nil {
		return err
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	for i, item := range s.items {
		if fmt.Sprintf("%d", id) == item.ID {
			s.items[i].Status = "stopped"
			return nil
		}
	}
	return fmt.Errorf("activity %d not found", id)
}

func (s *Service) GetLogs(limit int) ([]ActivityLog, error) {
	return nil, nil
}

type ActivityLog struct {
	ID         int    `json:"id"`
	ActivityID string `json:"activity_id"`
	Action     string `json:"action"`
	UserID     int    `json:"user_id"`
	CreatedAt  string `json:"created_at"`
}

func (s *Service) Reload() error {
	s.mu.Lock()
	s.loaded = false
	s.mu.Unlock()
	return s.loadFromDB()
}
