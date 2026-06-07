package character

import (
	"database/sql"
	"fmt"
	"time"

	"dnf-admin/internal/database"
)

// Character represents a game character
type Character struct {
	CNo         int       `json:"c_no"`
	CName       string    `json:"c_name"`
	CLevel      int       `json:"c_level"`
	CJob        int       `json:"c_job"`
	CFatigue    int       `json:"c_fatigue"`
	CServer     int       `json:"c_server"`
	UID         int       `json:"uid"`
	GrowType    int       `json:"grow_type"`
	Sex         int       `json:"sex"`
	MaxHP       int       `json:"max_hp"`
	MaxMP       int       `json:"max_mp"`
	PhyAttack   int       `json:"phy_attack"`
	PhyDefense  int       `json:"phy_defense"`
	MagAttack   int       `json:"mag_attack"`
	MagDefense  int       `json:"mag_defense"`
	MoveSpeed   int       `json:"move_speed"`
	AttackSpeed int       `json:"attack_speed"`
	CastSpeed   int       `json:"cast_speed"`
	Jump        int       `json:"jump"`
	HitRecovery int       `json:"hit_recovery"`
	Exp         int       `json:"exp"`
	CLastLogin  time.Time `json:"c_last_login"`
	CreateTime  time.Time `json:"create_time"`
	ServerID    string    `json:"server_id"`
	ServerName  string    `json:"server_name"`
}

// CharacterItem represents an item in character's inventory
type CharacterItem struct {
	SlotNo   int    `json:"slot"`
	ItemId   int    `json:"it_id"`
	ItemName string `json:"item_name"`
	Count    int    `json:"count"`
	Enhance  int    `json:"enhance"`
	Rarity   int    `json:"rarity"`
}

// Service handles character operations
type Service struct{}

// NewService creates a new character service
func NewService() *Service {
	return &Service{}
}

// Search searches for characters by name, account, job, level range
func (s *Service) Search(serverID string, query string, page, pageSize int) ([]Character, int, error) {
	sdb, err := database.GetServerDB(serverID)
	if err != nil {
		return nil, 0, fmt.Errorf("server not found: %s", serverID)
	}

	offset := (page - 1) * pageSize

	// Build WHERE clause based on query
	where := "1=1"
	args := []interface{}{}
	if query != "" {
		// Try to parse as UID first
		var uid int
		_, err := fmt.Sscanf(query, "%d", &uid)
		if err == nil && uid > 0 {
			where += " AND (m_id = ? OR charac_name LIKE ?)"
			args = append(args, uid, "%"+query+"%")
		} else {
			where += " AND charac_name LIKE ?"
			args = append(args, "%"+query+"%")
		}
	}

	// Count total
	var total int
	countSQL := fmt.Sprintf("SELECT COUNT(*) FROM taiwan_cain.charac_info WHERE %s", where)
	err = sdb.DB.QueryRow(countSQL, args...).Scan(&total)
	if err != nil {
		return nil, 0, fmt.Errorf("count characters: %w", err)
	}

	// Query with pagination
	querySQL := fmt.Sprintf(
		`SELECT charac_no, charac_name, lev, job, fatigue, 0, m_id, grow_type, sex,
			maxHP, maxMP, phy_attack, phy_defense, mag_attack, mag_defense,
			move_speed, attack_speed, cast_speed, jump, hit_recovery, exp, create_time, last_play_time
		 FROM taiwan_cain.charac_info WHERE %s
		 ORDER BY charac_no DESC LIMIT ? OFFSET ?`, where)
	args = append(args, pageSize, offset)

	rows, err := sdb.DB.Query(querySQL, args...)
	if err != nil {
		return nil, 0, fmt.Errorf("query characters: %w", err)
	}
	defer rows.Close()

	var characters []Character
	for rows.Next() {
		var c Character
		if err := rows.Scan(&c.CNo, &c.CName, &c.CLevel, &c.CJob, &c.CFatigue, &c.CServer, &c.UID,
			&c.GrowType, &c.Sex, &c.MaxHP, &c.MaxMP, &c.PhyAttack, &c.PhyDefense, &c.MagAttack, &c.MagDefense,
			&c.MoveSpeed, &c.AttackSpeed, &c.CastSpeed, &c.Jump, &c.HitRecovery, &c.Exp, &c.CreateTime, &c.CLastLogin); err != nil {
			return nil, 0, fmt.Errorf("scan character: %w", err)
		}
		c.ServerID = serverID
		c.ServerName = sdb.Name
		characters = append(characters, c)
	}
	return characters, total, nil
}

// SearchWithFilters searches characters with multiple filter conditions
func (s *Service) SearchWithFilters(serverID string, query string, account string, job string, minLev string, maxLev string, page, pageSize int) ([]Character, int, error) {
	sdb, err := database.GetServerDB(serverID)
	if err != nil {
		return nil, 0, fmt.Errorf("server not found: %s", serverID)
	}

	offset := (page - 1) * pageSize

	// Build WHERE clause
	where := "1=1"
	args := []interface{}{}

	// Name or UID search
	if query != "" {
		var uid int
		_, err := fmt.Sscanf(query, "%d", &uid)
		if err == nil && uid > 0 {
			where += " AND (m_id = ? OR charac_name LIKE ?)"
			args = append(args, uid, "%"+query+"%")
		} else {
			where += " AND charac_name LIKE ?"
			args = append(args, "%"+query+"%")
		}
	}

	// Account filter
	if account != "" {
		var uid int
		_, err := fmt.Sscanf(account, "%d", &uid)
		if err == nil && uid > 0 {
			where += " AND m_id = ?"
			args = append(args, uid)
		}
	}

	// Job filter
	if job != "" {
		var jobID int
		_, err := fmt.Sscanf(job, "%d", &jobID)
		if err == nil {
			where += " AND job = ?"
			args = append(args, jobID)
		}
	}

	// Level range
	if minLev != "" {
		var minL int
		_, err := fmt.Sscanf(minLev, "%d", &minL)
		if err == nil && minL > 0 {
			where += " AND lev >= ?"
			args = append(args, minL)
		}
	}
	if maxLev != "" {
		var maxL int
		_, err := fmt.Sscanf(maxLev, "%d", &maxL)
		if err == nil && maxL > 0 {
			where += " AND lev <= ?"
			args = append(args, maxL)
		}
	}

	// Count total
	var total int
	countSQL := fmt.Sprintf("SELECT COUNT(*) FROM taiwan_cain.charac_info WHERE %s", where)
	err = sdb.DB.QueryRow(countSQL, args...).Scan(&total)
	if err != nil {
		return nil, 0, fmt.Errorf("count characters: %w", err)
	}

	// Query with pagination
	querySQL := fmt.Sprintf(
		`SELECT charac_no, charac_name, lev, job, fatigue, 0, m_id, grow_type, sex,
			maxHP, maxMP, phy_attack, phy_defense, mag_attack, mag_defense,
			move_speed, attack_speed, cast_speed, jump, hit_recovery, exp, create_time, last_play_time
		 FROM taiwan_cain.charac_info WHERE %s
		 ORDER BY charac_no DESC LIMIT ? OFFSET ?`, where)
	args = append(args, pageSize, offset)

	rows, err := sdb.DB.Query(querySQL, args...)
	if err != nil {
		return nil, 0, fmt.Errorf("query characters: %w", err)
	}
	defer rows.Close()

	var characters []Character
	for rows.Next() {
		var c Character
		if err := rows.Scan(&c.CNo, &c.CName, &c.CLevel, &c.CJob, &c.CFatigue, &c.CServer, &c.UID,
			&c.GrowType, &c.Sex, &c.MaxHP, &c.MaxMP, &c.PhyAttack, &c.PhyDefense, &c.MagAttack, &c.MagDefense,
			&c.MoveSpeed, &c.AttackSpeed, &c.CastSpeed, &c.Jump, &c.HitRecovery, &c.Exp, &c.CreateTime, &c.CLastLogin); err != nil {
			return nil, 0, fmt.Errorf("scan character: %w", err)
		}
		c.ServerID = serverID
		c.ServerName = sdb.Name
		characters = append(characters, c)
	}
	return characters, total, nil
}

// GetByCNo retrieves a character by c_no
func (s *Service) GetByCNo(serverID string, cNo int) (*Character, error) {
	sdb, err := database.GetServerDB(serverID)
	if err != nil {
		return nil, fmt.Errorf("server not found: %s", serverID)
	}

	var c Character
	err = sdb.DB.QueryRow(
		`SELECT charac_no, charac_name, lev, job, fatigue, 0, m_id, grow_type, sex,
			maxHP, maxMP, phy_attack, phy_defense, mag_attack, mag_defense,
			move_speed, attack_speed, cast_speed, jump, hit_recovery, exp, create_time, last_play_time
		 FROM taiwan_cain.charac_info WHERE charac_no = ?`, cNo,
	).Scan(&c.CNo, &c.CName, &c.CLevel, &c.CJob, &c.CFatigue, &c.CServer, &c.UID,
		&c.GrowType, &c.Sex, &c.MaxHP, &c.MaxMP, &c.PhyAttack, &c.PhyDefense, &c.MagAttack, &c.MagDefense,
		&c.MoveSpeed, &c.AttackSpeed, &c.CastSpeed, &c.Jump, &c.HitRecovery, &c.Exp, &c.CreateTime, &c.CLastLogin)

	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("get character: %w", err)
	}

	c.ServerID = serverID
	c.ServerName = sdb.Name
	return &c, nil
}

// GetItems retrieves items for a character
func (s *Service) GetItems(serverID string, cNo int) ([]CharacterItem, error) {
	sdb, err := database.GetServerDB(serverID)
	if err != nil {
		return nil, fmt.Errorf("server not found: %s", serverID)
	}

	rows, err := sdb.DB.Query(
		`SELECT u.slot, u.it_id, 1, COALESCE(g.name, '')
		 FROM taiwan_cain_2nd.user_items u
		 LEFT JOIN taiwan_cain_2nd.gold g ON FLOOR(u.it_id/100000) = g.code
		 WHERE u.charac_no = ? ORDER BY u.slot`,
		cNo,
	)
	if err != nil {
		return nil, fmt.Errorf("query items: %w", err)
	}
	defer rows.Close()

	var items []CharacterItem
	for rows.Next() {
		var item CharacterItem
		if err := rows.Scan(&item.SlotNo, &item.ItemId, &item.Count, &item.ItemName); err != nil {
			return nil, fmt.Errorf("scan item: %w", err)
		}
		items = append(items, item)
	}
	return items, nil
}

// GetOnline retrieves online characters
func (s *Service) GetOnline(serverID string) ([]Character, error) {
	sdb, err := database.GetServerDB(serverID)
	if err != nil {
		return nil, fmt.Errorf("server not found: %s", serverID)
	}

	rows, err := sdb.DB.Query(
		`SELECT charac_no, charac_name, lev, job, fatigue, 0, m_id, grow_type, sex,
			maxHP, maxMP, phy_attack, phy_defense, mag_attack, mag_defense,
			move_speed, attack_speed, cast_speed, jump, hit_recovery, exp, create_time, last_play_time
		 FROM taiwan_cain.charac_info ORDER BY last_play_time DESC LIMIT 100`,
	)
	if err != nil {
		return nil, fmt.Errorf("query online characters: %w", err)
	}
	defer rows.Close()

	var characters []Character
	for rows.Next() {
		var c Character
		if err := rows.Scan(&c.CNo, &c.CName, &c.CLevel, &c.CJob, &c.CFatigue, &c.CServer, &c.UID,
			&c.GrowType, &c.Sex, &c.MaxHP, &c.MaxMP, &c.PhyAttack, &c.PhyDefense, &c.MagAttack, &c.MagDefense,
			&c.MoveSpeed, &c.AttackSpeed, &c.CastSpeed, &c.Jump, &c.HitRecovery, &c.Exp, &c.CreateTime, &c.CLastLogin); err != nil {
			return nil, fmt.Errorf("scan character: %w", err)
		}
		c.ServerID = serverID
		c.ServerName = sdb.Name
		characters = append(characters, c)
	}
	return characters, nil
}
