package punish

import (
	"fmt"
	"sync"

	"dnf-admin/internal/database"
)

type PunishInfo struct {
	MID        int    `json:"m_id"`
	PunishType int    `json:"punish_type"`
	OccTime    string `json:"occ_time"`
	StartTime  string `json:"start_time"`
	EndTime    string `json:"end_time"`
	AdminID    string `json:"admin_id"`
	Reason     string `json:"reason"`
}

type PunishRequest struct {
	MID        int    `json:"m_id"`
	PunishType int    `json:"punish_type"`
	EndTime    string `json:"end_time"`
	Reason     string `json:"reason"`
}

type Service struct {
	serverID string
	mu       sync.RWMutex
}

func NewService(serverID string) *Service {
	return &Service{serverID: serverID}
}

func (s *Service) ListPunish() ([]PunishInfo, error) {
	sdb, err := database.GetServerDB(s.serverID)
	if err != nil {
		return nil, fmt.Errorf("server not found: %s", s.serverID)
	}

	rows, err := sdb.DB.Query(`
		SELECT m_id, punish_type, COALESCE(occ_time,''), COALESCE(start_time,''), 
		       COALESCE(end_time,''), COALESCE(admin_id,''), COALESCE(reason,'')
		FROM d_taiwan.member_punish_info
		ORDER BY occ_time DESC
		LIMIT 200
	`)
	if err != nil {
		return nil, fmt.Errorf("query punish: %w", err)
	}
	defer rows.Close()

	var list []PunishInfo
	for rows.Next() {
		var p PunishInfo
		if err := rows.Scan(&p.MID, &p.PunishType, &p.OccTime, &p.StartTime,
			&p.EndTime, &p.AdminID, &p.Reason); err != nil {
			continue
		}
		list = append(list, p)
	}
	return list, nil
}

func (s *Service) AddPunish(req PunishRequest) error {
	sdb, err := database.GetServerDB(s.serverID)
	if err != nil {
		return fmt.Errorf("server not found: %s", s.serverID)
	}

	_, err = sdb.DB.Exec(`
		INSERT INTO d_taiwan.member_punish_info (m_id, punish_type, occ_time, start_time, end_time, admin_id, reason)
		VALUES (?, ?, NOW(), NOW(), ?, 'GM', ?)
		ON DUPLICATE KEY UPDATE end_time = VALUES(end_time), reason = VALUES(reason)
	`, req.MID, req.PunishType, req.EndTime, req.Reason)
	if err != nil {
		return fmt.Errorf("add punish: %w", err)
	}
	return nil
}

func (s *Service) RemovePunish(mID int) error {
	sdb, err := database.GetServerDB(s.serverID)
	if err != nil {
		return fmt.Errorf("server not found: %s", s.serverID)
	}

	_, err = sdb.DB.Exec(`DELETE FROM d_taiwan.member_punish_info WHERE m_id = ?`, mID)
	if err != nil {
		return fmt.Errorf("remove punish: %w", err)
	}
	return nil
}
