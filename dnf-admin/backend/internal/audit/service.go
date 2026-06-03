package audit

import (
	"fmt"
	"log"
	"time"

	"dnf-admin/internal/database"
)

// LogEntry represents an audit log entry
type LogEntry struct {
	ID         int       `json:"id"`
	OperatorID int       `json:"operator_id"`
	Action     string    `json:"action"`
	Target     string    `json:"target"`
	Detail     string    `json:"detail"`
	IPAddress  string    `json:"ip_address"`
	CreatedAt  time.Time `json:"created_at"`
}

// Service handles audit logging
type Service struct{}

// NewService creates a new audit service
func NewService() *Service {
	return &Service{}
}

// Log records an audit log entry
func (s *Service) Log(entry LogEntry) error {
	_, err := database.DB.Exec(
		`INSERT INTO audit_logs (operator_id, action, target, detail, ip_address, created_at)
		 VALUES (?, ?, ?, ?, ?, NOW())`,
		entry.OperatorID, entry.Action, entry.Target, entry.Detail, entry.IPAddress,
	)
	if err != nil {
		log.Printf("Failed to write audit log: %v", err)
		return fmt.Errorf("insert audit log: %w", err)
	}
	return nil
}

// GetLogs retrieves audit logs
func (s *Service) GetLogs(operatorID int, action string, limit int) ([]LogEntry, error) {
	if limit <= 0 {
		limit = 100
	}

	query := `SELECT id, operator_id, action, target, detail, ip_address, created_at
	          FROM audit_logs WHERE 1=1`
	args := []interface{}{}

	if operatorID > 0 {
		query += " AND operator_id = ?"
		args = append(args, operatorID)
	}
	if action != "" {
		query += " AND action = ?"
		args = append(args, action)
	}

	query += " ORDER BY id DESC LIMIT ?"
	args = append(args, limit)

	rows, err := database.DB.Query(query, args...)
	if err != nil {
		return nil, fmt.Errorf("query audit logs: %w", err)
	}
	defer rows.Close()

	var logs []LogEntry
	for rows.Next() {
		var entry LogEntry
		if err := rows.Scan(&entry.ID, &entry.OperatorID, &entry.Action, &entry.Target, &entry.Detail, &entry.IPAddress, &entry.CreatedAt); err != nil {
			return nil, fmt.Errorf("scan audit log: %w", err)
		}
		logs = append(logs, entry)
	}
	return logs, nil
}
