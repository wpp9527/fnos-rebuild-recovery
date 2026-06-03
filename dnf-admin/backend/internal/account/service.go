package account

import (
	"database/sql"
	"fmt"
	"time"

	"dnf-admin/internal/database"
)

// Account represents a game account
type Account struct {
	UID       int       `json:"uid"`
	UName     string    `json:"uname"`
	Level     int       `json:"level"`
	Status    int       `json:"status"`
	Coin      int       `json:"coin"`
	Cera      int       `json:"cera"`
	CeraPoint int       `json:"cera_point"`
	LoginIP   string    `json:"login_ip"`
	LastLogin time.Time `json:"last_login"`
}

// Service handles account operations
type Service struct{}

// NewService creates a new account service
func NewService() *Service {
	return &Service{}
}

// Search searches for accounts by UID or username
func (s *Service) Search(query string, page, pageSize int) ([]Account, int, error) {
	offset := (page - 1) * pageSize

	// Search by UID or username
	rows, err := database.DB.Query(
		`SELECT uid, uname, level, status, coin, cera, cera_point, login_ip, last_login 
		 FROM accounts WHERE uid = ? OR uname LIKE ? 
		 ORDER BY uid DESC LIMIT ? OFFSET ?`,
		query, "%"+query+"%", pageSize, offset,
	)
	if err != nil {
		return nil, 0, fmt.Errorf("query accounts: %w", err)
	}
	defer rows.Close()

	var accounts []Account
	for rows.Next() {
		var a Account
		if err := rows.Scan(&a.UID, &a.UName, &a.Level, &a.Status, &a.Coin, &a.Cera, &a.CeraPoint, &a.LoginIP, &a.LastLogin); err != nil {
			return nil, 0, fmt.Errorf("scan account: %w", err)
		}
		accounts = append(accounts, a)
	}

	// Get total count
	var total int
	err = database.DB.QueryRow(
		"SELECT COUNT(*) FROM accounts WHERE uid = ? OR uname LIKE ?",
		query, "%"+query+"%",
	).Scan(&total)
	if err != nil {
		return nil, 0, fmt.Errorf("count accounts: %w", err)
	}

	return accounts, total, nil
}

// GetByUID retrieves an account by UID
func (s *Service) GetByUID(uid int) (*Account, error) {
	var a Account
	err := database.DB.QueryRow(
		`SELECT uid, uname, level, status, coin, cera, cera_point, login_ip, last_login 
		 FROM accounts WHERE uid = ?`, uid,
	).Scan(&a.UID, &a.UName, &a.Level, &a.Status, &a.Coin, &a.Cera, &a.CeraPoint, &a.LoginIP, &a.LastLogin)

	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("get account: %w", err)
	}
	return &a, nil
}

// GetCharacters retrieves characters for an account
func (s *Service) GetCharacters(uid int) ([]map[string]interface{}, error) {
	rows, err := database.DB.Query(
		`SELECT c_no, c_name, c_level, c_job, c_fatigue, c_server, c_last_login
		 FROM characters WHERE uid = ? ORDER BY c_no`,
		uid,
	)
	if err != nil {
		return nil, fmt.Errorf("query characters: %w", err)
	}
	defer rows.Close()

	var characters []map[string]interface{}
	for rows.Next() {
		var (
			cNo        int
			cName      string
			cLevel     int
			cJob       int
			cFatigue   int
			cServer    int
			cLastLogin time.Time
		)
		if err := rows.Scan(&cNo, &cName, &cLevel, &cJob, &cFatigue, &cServer, &cLastLogin); err != nil {
			return nil, fmt.Errorf("scan character: %w", err)
		}
		characters = append(characters, map[string]interface{}{
			"c_no":        cNo,
			"c_name":      cName,
			"c_level":     cLevel,
			"c_job":       cJob,
			"c_fatigue":   cFatigue,
			"c_server":    cServer,
			"c_last_login": cLastLogin,
		})
	}
	return characters, nil
}
