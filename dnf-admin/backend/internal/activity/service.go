package activity

import (
	"fmt"
	"sync"
	"unicode/utf8"

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

// fixEncoding repairs strings from dnf_item_info where UTF-8 bytes were
// stored in latin1 columns. The MySQL driver with charset=utf8 partially
// decodes high bytes into Latin Extended Unicode chars via cp1252.
// Activity tables are proper UTF-8 so this function returns them as-is.
func fixEncoding(s string) string {
	if len(s) == 0 {
		return s
	}
	var b []byte
	needsFix := false
	for _, r := range s {
		if r > 255 {
			orig, ok := unicodeToByte(r)
			if ok {
				b = append(b, orig)
				needsFix = true
			} else {
				return s
			}
		} else {
			b = append(b, byte(r))
		}
	}
	if !needsFix {
		return s
	}
	converted := string(b)
	if utf8.ValidString(converted) {
		return converted
	}
	return s
}

// unicodeToByte maps Unicode chars back to their original byte values.
// The MySQL driver converts 0x80-0xFF bytes using cp1252 encoding.
// Undefined cp1252 positions (0x81,0x8D,0x8F,0x90,0x9D) are passed through.
func unicodeToByte(r rune) (byte, bool) {
	if r <= 0xFF {
		return byte(r), true
	}
	switch r {
	case 0x20AC:
		return 0x80, true
	case 0x201A:
		return 0x82, true
	case 0x0192:
		return 0x83, true
	case 0x201E:
		return 0x84, true
	case 0x2026:
		return 0x85, true
	case 0x2020:
		return 0x86, true
	case 0x2021:
		return 0x87, true
	case 0x02C6:
		return 0x88, true
	case 0x2030:
		return 0x89, true
	case 0x0160:
		return 0x8A, true
	case 0x2039:
		return 0x8B, true
	case 0x0152:
		return 0x8C, true
	case 0x017D:
		return 0x8E, true
	case 0x2018:
		return 0x91, true
	case 0x2019:
		return 0x92, true
	case 0x201C:
		return 0x93, true
	case 0x201D:
		return 0x94, true
	case 0x2022:
		return 0x95, true
	case 0x2013:
		return 0x96, true
	case 0x2014:
		return 0x97, true
	case 0x02DC:
		return 0x98, true
	case 0x2122:
		return 0x99, true
	case 0x0161:
		return 0x9A, true
	case 0x203A:
		return 0x9B, true
	case 0x0153:
		return 0x9C, true
	case 0x017E:
		return 0x9E, true
	case 0x0178:
		return 0x9F, true
	}
	return 0, false
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
