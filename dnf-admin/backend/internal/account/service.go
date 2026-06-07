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
	ServerID  string    `json:"server_id"`
	ServerName string  `json:"server_name"`
}

// Service handles account operations
type Service struct{}

// NewService creates a new account service
func NewService() *Service {
	return &Service{}
}

// Search searches for accounts by UID or username, or lists all if query is empty
func (s *Service) Search(serverID string, query string, page, pageSize int) ([]Account, int, error) {
	if serverID == "" {
		sdb := database.GetDefaultServerDB()
		if sdb == nil {
			return nil, 0, fmt.Errorf("no server connected")
		}
		serverID = sdb.ID
	}

	sdb, err := database.GetServerDB(serverID)
	if err != nil {
		return nil, 0, fmt.Errorf("server not found: %s", serverID)
	}

	offset := (page - 1) * pageSize

	var rows *sql.Rows
	var total int

	if query == "" {
		// List all accounts with cera from billing
		rows, err = sdb.DB.Query(
			`SELECT a.UID, a.accountname, COALESCE(a.admin, 0) as level, 1 as status,
				COALESCE(b.cera, 0) as cera, COALESCE(cp.cera_point, 0) as cera_point
			 FROM d_taiwan.accounts a
			 LEFT JOIN taiwan_billing.cash_cera b ON a.UID = b.account
			 LEFT JOIN taiwan_billing.cash_cera_point cp ON a.UID = cp.account
			 ORDER BY a.UID DESC LIMIT ? OFFSET ?`,
			pageSize, offset,
		)
		if err != nil {
			return nil, 0, fmt.Errorf("query accounts: %w", err)
		}
		defer rows.Close()

		err = sdb.DB.QueryRow("SELECT COUNT(*) FROM d_taiwan.accounts").Scan(&total)
		if err != nil {
			return nil, 0, fmt.Errorf("count accounts: %w", err)
		}
	} else {
		// Search by UID or username
		rows, err = sdb.DB.Query(
			`SELECT a.UID, a.accountname, COALESCE(a.admin, 0) as level, 1 as status,
				COALESCE(b.cera, 0) as cera, COALESCE(cp.cera_point, 0) as cera_point
			 FROM d_taiwan.accounts a
			 LEFT JOIN taiwan_billing.cash_cera b ON a.UID = b.account
			 LEFT JOIN taiwan_billing.cash_cera_point cp ON a.UID = cp.account
			 WHERE a.UID = ? OR a.accountname LIKE ?
			 ORDER BY a.UID DESC LIMIT ? OFFSET ?`,
			query, "%"+query+"%", pageSize, offset,
		)
		if err != nil {
			return nil, 0, fmt.Errorf("query accounts: %w", err)
		}
		defer rows.Close()

		err = sdb.DB.QueryRow(
			"SELECT COUNT(*) FROM d_taiwan.accounts WHERE UID = ? OR accountname LIKE ?",
			query, "%"+query+"%",
		).Scan(&total)
		if err != nil {
			return nil, 0, fmt.Errorf("count accounts: %w", err)
		}
	}

	var accounts []Account
	for rows.Next() {
		var a Account
		if err := rows.Scan(&a.UID, &a.UName, &a.Level, &a.Status, &a.Cera, &a.CeraPoint); err != nil {
			return nil, 0, fmt.Errorf("scan account: %w", err)
		}
		a.ServerID = serverID
		a.ServerName = sdb.Name
		accounts = append(accounts, a)
	}

	return accounts, total, nil
}

// GetByUID retrieves an account by UID
func (s *Service) GetByUID(serverID string, uid int) (*Account, error) {
	sdb, err := database.GetServerDB(serverID)
	if err != nil {
		return nil, fmt.Errorf("server not found: %s", serverID)
	}

	var a Account
	err = sdb.DB.QueryRow(
		`SELECT a.UID, a.accountname, COALESCE(a.admin, 0) as level, 1 as status,
			COALESCE(b.cera, 0) as cera, COALESCE(cp.cera_point, 0) as cera_point
		 FROM d_taiwan.accounts a
		 LEFT JOIN taiwan_billing.cash_cera b ON a.UID = b.account
		 LEFT JOIN taiwan_billing.cash_cera_point cp ON a.UID = cp.account
		 WHERE a.UID = ?`, uid,
	).Scan(&a.UID, &a.UName, &a.Level, &a.Status, &a.Cera, &a.CeraPoint)

	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("get account: %w", err)
	}

	a.ServerID = serverID
	a.ServerName = sdb.Name
	return &a, nil
}

// GetCharacters retrieves characters for an account
func (s *Service) GetCharacters(serverID string, uid int) ([]map[string]interface{}, error) {
	sdb, err := database.GetServerDB(serverID)
	if err != nil {
		return nil, fmt.Errorf("server not found: %s", serverID)
	}

	rows, err := sdb.DB.Query(
		`SELECT charac_no, charac_name, lev, job, fatigue, 0 as c_server, create_time
		 FROM taiwan_cain.charac_info WHERE m_id = ? ORDER BY charac_no`,
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
			"server_id":   serverID,
			"server_name": sdb.Name,
		})
	}
	return characters, nil
}
