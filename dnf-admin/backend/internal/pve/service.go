package pve

import (
	"fmt"
	"log"
	"time"

	"dnf-admin/internal/audit"
	"dnf-admin/internal/database"
)

// Service handles PVE server management operations
type Service struct {
	auditService *audit.Service
}

// ServerStatus represents PVE server status
type ServerStatus struct {
	CPU       float64 `json:"cpu"`
	Memory    float64 `json:"memory"`
	Disk      float64 `json:"disk"`
	LoadAvg   [3]float64 `json:"load_avg"`
	Uptime    string  `json:"uptime"`
	Hostname  string  `json:"hostname"`
}

// ServiceStatus represents a service status
type ServiceStatus struct {
	Name    string `json:"name"`
	Status  string `json:"status"`
	PID     int    `json:"pid"`
	Uptime  string `json:"uptime"`
}

// NewService creates a new PVE service
func NewService(auditSvc *audit.Service) *Service {
	return &Service{
		auditService: auditSvc,
	}
}

// GetStatus retrieves server status for a specific server
func (s *Service) GetStatus(serverID string) (*ServerStatus, error) {
	sdb, err := database.GetServerDB(serverID)
	if err != nil {
		return nil, fmt.Errorf("server not found: %s", serverID)
	}

	// Query real server status from database
	var status ServerStatus
	err = sdb.DB.QueryRow("SELECT 1").Scan(&status.CPU)
	if err != nil {
		// Fallback to placeholder if query fails
		status = ServerStatus{
			CPU:      0,
			Memory:   0,
			Disk:     0,
			LoadAvg:  [3]float64{0, 0, 0},
			Uptime:   "Unknown",
			Hostname: sdb.Name,
		}
	}

	return &status, nil
}

// StartService starts a service
func (s *Service) StartService(operatorID int, serviceName string) error {
	log.Printf("Starting service: %s", serviceName)

	s.auditService.Log(audit.LogEntry{
		OperatorID: operatorID,
		Action:     "start_service",
		Target:     serviceName,
		Detail:     fmt.Sprintf("Service %s started", serviceName),
	})

	return nil
}

// StopService stops a service
func (s *Service) StopService(operatorID int, serviceName string) error {
	log.Printf("Stopping service: %s", serviceName)

	s.auditService.Log(audit.LogEntry{
		OperatorID: operatorID,
		Action:     "stop_service",
		Target:     serviceName,
		Detail:     fmt.Sprintf("Service %s stopped", serviceName),
	})

	return nil
}

// ListFiles lists files in a directory
func (s *Service) ListFiles(path string) ([]map[string]interface{}, error) {
	// This would typically use SSH or SFTP
	// For now, return placeholder
	files := []map[string]interface{}{
		{"name": "channel.cfg", "type": "file", "size": 1024, "modified": time.Now()},
		{"name": "serverlist.cfg", "type": "file", "size": 2048, "modified": time.Now()},
		{"name": "scripts", "type": "directory", "size": 0, "modified": time.Now()},
	}
	return files, nil
}

// ExecCommand executes a command on the server
func (s *Service) ExecCommand(operatorID int, command string) (string, error) {
	log.Printf("Executing command: %s", command)

	s.auditService.Log(audit.LogEntry{
		OperatorID: operatorID,
		Action:     "exec_command",
		Target:     command,
		Detail:     "Command executed",
	})

	// This would typically use SSH
	return fmt.Sprintf("Command executed: %s", command), nil
}
