package activity

import (
	"fmt"
	"log"
	"time"

	"dnf-admin/internal/audit"
	"dnf-admin/internal/database"
)

// Activity represents a game activity
type Activity struct {
	ID          int       `json:"id"`
	Name        string    `json:"name"`
	Description string    `json:"description"`
	Status      int       `json:"status"` // 0=inactive, 1=active
	StartTime   time.Time `json:"start_time"`
	EndTime     time.Time `json:"end_time"`
	CreatedAt   time.Time `json:"created_at"`
}

// Service handles activity operations
type Service struct {
	auditService *audit.Service
}

// NewService creates a new activity service
func NewService(auditSvc *audit.Service) *Service {
	return &Service{
		auditService: auditSvc,
	}
}

// List retrieves all activities
func (s *Service) List() ([]Activity, error) {
	rows, err := database.DB.Query(
		`SELECT id, name, description, status, start_time, end_time, created_at
		 FROM activities ORDER BY id DESC`,
	)
	if err != nil {
		return nil, fmt.Errorf("query activities: %w", err)
	}
	defer rows.Close()

	var activities []Activity
	for rows.Next() {
		var a Activity
		if err := rows.Scan(&a.ID, &a.Name, &a.Description, &a.Status, &a.StartTime, &a.EndTime, &a.CreatedAt); err != nil {
			return nil, fmt.Errorf("scan activity: %w", err)
		}
		activities = append(activities, a)
	}
	return activities, nil
}

// Start activates an activity
func (s *Service) Start(operatorID int, activityID int) error {
	_, err := database.DB.Exec(
		"UPDATE activities SET status = 1 WHERE id = ?",
		activityID,
	)
	if err != nil {
		return fmt.Errorf("start activity: %w", err)
	}

	s.auditService.Log(audit.LogEntry{
		OperatorID: operatorID,
		Action:     "start_activity",
		Target:     fmt.Sprintf("Activity:%d", activityID),
		Detail:     "Activity started",
	})

	log.Printf("Activity started: ID=%d", activityID)
	return nil
}

// Stop deactivates an activity
func (s *Service) Stop(operatorID int, activityID int) error {
	_, err := database.DB.Exec(
		"UPDATE activities SET status = 0 WHERE id = ?",
		activityID,
	)
	if err != nil {
		return fmt.Errorf("stop activity: %w", err)
	}

	s.auditService.Log(audit.LogEntry{
		OperatorID: operatorID,
		Action:     "stop_activity",
		Target:     fmt.Sprintf("Activity:%d", activityID),
		Detail:     "Activity stopped",
	})

	log.Printf("Activity stopped: ID=%d", activityID)
	return nil
}

// GetLogs retrieves activity logs
func (s *Service) GetLogs(limit int) ([]map[string]interface{}, error) {
	if limit <= 0 {
		limit = 100
	}
	rows, err := database.DB.Query(
		`SELECT id, activity_id, action, detail, operator_id, created_at
		 FROM activity_logs ORDER BY id DESC LIMIT ?`,
		limit,
	)
	if err != nil {
		return nil, fmt.Errorf("query logs: %w", err)
	}
	defer rows.Close()

	var logs []map[string]interface{}
	for rows.Next() {
		var (
			id          int
			activityID  int
			action      string
			detail      string
			operatorID  int
			createdAt   time.Time
		)
		if err := rows.Scan(&id, &activityID, &action, &detail, &operatorID, &createdAt); err != nil {
			return nil, fmt.Errorf("scan log: %w", err)
		}
		logs = append(logs, map[string]interface{}{
			"id":           id,
			"activity_id":  activityID,
			"action":       action,
			"detail":       detail,
			"operator_id":  operatorID,
			"created_at":   createdAt,
		})
	}
	return logs, nil
}
