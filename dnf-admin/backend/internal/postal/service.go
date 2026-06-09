package postal

import (
	"fmt"
	"sync"

	"dnf-admin/internal/database"
)

type PostalRequest struct {
	ReceiveCharacNo int    `json:"receive_charac_no"`
	ItemID          int    `json:"item_id"`
	AddInfo         int    `json:"add_info"`
	Endurance       int    `json:"endurance"`
	Upgrade         int    `json:"upgrade"`
	Gold            int    `json:"gold"`
	Message         string `json:"message"`
}

type PostalHistory struct {
	PostalID        int    `json:"postal_id"`
	OccTime         string `json:"occ_time"`
	SendCharacName  string `json:"send_charac_name"`
	ReceiveCharacNo int    `json:"receive_charac_no"`
	ItemID          int    `json:"item_id"`
	Gold            int    `json:"gold"`
	DeleteFlag      int    `json:"delete_flag"`
}

type Service struct {
	serverID string
	mu       sync.RWMutex
}

func NewService(serverID string) *Service {
	return &Service{serverID: serverID}
}

func (s *Service) SendPostal(req PostalRequest) error {
	sdb, err := database.GetServerDB(s.serverID)
	if err != nil {
		return fmt.Errorf("server not found: %s", s.serverID)
	}

	_, err = sdb.DB.Exec(`
		INSERT INTO taiwan_cain_2nd.postal 
		(occ_time, send_charac_no, send_charac_name, receive_charac_no, 
		 item_id, add_info, endurance, upgrade, gold, delete_flag)
		VALUES (NOW(), 0, 'GM', ?, ?, ?, ?, ?, ?, 0)
	`, req.ReceiveCharacNo, req.ItemID, req.AddInfo, req.Endurance, req.Upgrade, req.Gold)
	if err != nil {
		return fmt.Errorf("send postal: %w", err)
	}
	return nil
}

func (s *Service) GetPostalHistory(characNo int, limit int) ([]PostalHistory, error) {
	sdb, err := database.GetServerDB(s.serverID)
	if err != nil {
		return nil, fmt.Errorf("server not found: %s", s.serverID)
	}

	if limit <= 0 {
		limit = 50
	}

	rows, err := sdb.DB.Query(`
		SELECT postal_id, COALESCE(occ_time,''), COALESCE(send_charac_name,''), 
		       receive_charac_no, item_id, gold, delete_flag
		FROM taiwan_cain_2nd.postal
		WHERE receive_charac_no = ?
		ORDER BY occ_time DESC
		LIMIT ?
	`, characNo, limit)
	if err != nil {
		return nil, fmt.Errorf("query postal: %w", err)
	}
	defer rows.Close()

	var list []PostalHistory
	for rows.Next() {
		var p PostalHistory
		if err := rows.Scan(&p.PostalID, &p.OccTime, &p.SendCharacName,
			&p.ReceiveCharacNo, &p.ItemID, &p.Gold, &p.DeleteFlag); err != nil {
			continue
		}
		list = append(list, p)
	}
	return list, nil
}
