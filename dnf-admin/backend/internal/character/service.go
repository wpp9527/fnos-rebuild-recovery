package character

import (
	"bytes"
	"compress/zlib"
	"database/sql"
	"fmt"
	"io"
	"regexp"
	"strconv"
	"strings"
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

// Equipment represents an equipped item
type Equipment struct {
	SlotNo     int    `json:"slot"`
	SlotName   string `json:"slot_name"`
	ItemId     int    `json:"it_id"`
	ItemName   string `json:"item_name"`
	Rarity     int    `json:"rarity"`
	Level      int    `json:"level"`
	Enhance    int    `json:"enhance"`
	PhyAtk     int    `json:"phy_attack"`
	MagAtk     int    `json:"mag_attack"`
	PhyDef     int    `json:"phy_defense"`
	MagDef     int    `json:"mag_defense"`
	Str        int    `json:"str"`
	Int        int    `json:"int"`
	Vit        int    `json:"vit"`
	Spr        int    `json:"spr"`
	PhyCrit    int    `json:"phy_crit"`
	MagCrit    int    `json:"mag_crit"`
	AtkSpeed   int    `json:"atk_speed"`
	MoveSpeed  int    `json:"move_speed"`
	CastSpeed  int    `json:"cast_speed"`
	HP         int    `json:"hp"`
	MP         int    `json:"mp"`
	Stuck      int    `json:"stuck"`
}

// CharacterItem represents an item in character's backpack
type CharacterItem struct {
	SlotNo     int    `json:"slot"`
	ItemId     int    `json:"it_id"`
	ItemName   string `json:"item_name"`
	Count      int    `json:"count"`
	Rarity     int    `json:"rarity"`
	Level      int    `json:"level"`
	Category   string `json:"category"`
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

	where := "1=1"
	args := []interface{}{}
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

	var total int
	countSQL := fmt.Sprintf("SELECT COUNT(*) FROM taiwan_cain.charac_info WHERE %s", where)
	err = sdb.DB.QueryRow(countSQL, args...).Scan(&total)
	if err != nil {
		return nil, 0, fmt.Errorf("count characters: %w", err)
	}

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

	where := "1=1"
	args := []interface{}{}

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

	if account != "" {
		var uid int
		_, err := fmt.Sscanf(account, "%d", &uid)
		if err == nil && uid > 0 {
			where += " AND m_id = ?"
			args = append(args, uid)
		}
	}

	if job != "" {
		var jobID int
		_, err := fmt.Sscanf(job, "%d", &jobID)
		if err == nil {
			where += " AND job = ?"
			args = append(args, jobID)
		}
	}

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

	var total int
	countSQL := fmt.Sprintf("SELECT COUNT(*) FROM taiwan_cain.charac_info WHERE %s", where)
	err = sdb.DB.QueryRow(countSQL, args...).Scan(&total)
	if err != nil {
		return nil, 0, fmt.Errorf("count characters: %w", err)
	}

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

// GetEquipment retrieves equipped items from equipslot blob
func (s *Service) GetEquipment(serverID string, cNo int) ([]Equipment, error) {
	sdb, err := database.GetServerDB(serverID)
	if err != nil {
		return nil, fmt.Errorf("server not found: %s", serverID)
	}

	// Query equipslot blob
	var equipslotBlob []byte
	err = sdb.DB.QueryRow(
		`SELECT equipslot FROM taiwan_cain_2nd.inventory WHERE charac_no = ?`, cNo,
	).Scan(&equipslotBlob)
	if err != nil {
		return nil, fmt.Errorf("query equipslot: %w", err)
	}

	// Parse equipslot blob (zlib compressed, 4-byte header)
	decompressed, err := decompressZlib(equipslotBlob[4:])
	if err != nil {
		return nil, fmt.Errorf("decompress equipslot: %w", err)
	}

	// Each equipment slot is 61 bytes
	// item_no is at local offset 2-3 (16-bit LE)
	slotSize := 61
	slotNames := []string{"武器", "上衣", "下裝", "頭肩", "腰帶", "鞋子", "項鏈", "手鐲", "戒指", "輔助裝備", "魔法石", "耳環"}

	var equipment []Equipment
	for slot := 0; slot < 12; slot++ {
		start := slot * slotSize
		if start+slotSize > len(decompressed) {
			break
		}

		block := decompressed[start : start+slotSize]
		itemNo := int(block[2]) | int(block[3])<<8  // Little-endian
		enhance := int(block[6])

		eq := Equipment{
			SlotNo:   slot,
			SlotName: slotNames[slot],
			ItemId:   itemNo,
			Enhance:  enhance,
		}
		equipment = append(equipment, eq)
	}

	// Get item names from dnf_item_info
	if len(equipment) > 0 {
		itIDs := make([]int, 0, len(equipment))
		for _, eq := range equipment {
			if eq.ItemId > 0 {
				itIDs = append(itIDs, eq.ItemId)
			}
		}
		if len(itIDs) > 0 {
			inClause := buildInClause(itIDs)
			nameRows, err := sdb.DB.Query(
				fmt.Sprintf("SELECT it_no, it_name, rarity FROM taiwan_cain_web.dnf_item_info WHERE it_no IN (%s)", inClause),
			)
			if err == nil {
				defer nameRows.Close()
				nameMap := make(map[int]struct {
					Name   string
					Rarity int
				})
				for nameRows.Next() {
					var itID int
					var name string
					var rarity int
					if err := nameRows.Scan(&itID, &name, &rarity); err == nil {
						nameMap[itID] = struct {
							Name   string
							Rarity int
						}{Name: decodeUnicode(name), Rarity: rarity}
					}
				}
				for i := range equipment {
					if info, ok := nameMap[equipment[i].ItemId]; ok {
						equipment[i].ItemName = info.Name
						equipment[i].Rarity = info.Rarity
					}
				}
			}
		}
	}

	return equipment, nil
}

// GetItems retrieves items from inventory blob (backpack)
func (s *Service) GetItems(serverID string, cNo int) ([]CharacterItem, error) {
	sdb, err := database.GetServerDB(serverID)
	if err != nil {
		return nil, fmt.Errorf("server not found: %s", serverID)
	}

	// Query inventory blob
	var inventoryBlob []byte
	err = sdb.DB.QueryRow(
		`SELECT inventory FROM taiwan_cain_2nd.inventory WHERE charac_no = ?`, cNo,
	).Scan(&inventoryBlob)
	if err != nil {
		return nil, fmt.Errorf("query inventory: %w", err)
	}

	// Parse inventory blob (zlib compressed, 4-byte header)
	decompressed, err := decompressZlib(inventoryBlob[4:])
	if err != nil {
		return nil, fmt.Errorf("decompress inventory: %w", err)
	}

	// Parse items: each item is 8 bytes
	// Format: flag(1) + item_no(2 LE) + padding(3) + count(1) + padding(1)
	var items []CharacterItem
	seen := make(map[int]bool)
	for offset := 0; offset < len(decompressed)-7; offset++ {
		itemNo := int(decompressed[offset+1]) | int(decompressed[offset+2])<<8
		count := int(decompressed[offset+6])

		// Validate item
		if itemNo >= 1000 && itemNo <= 99999 && count > 0 && count < 1000 {
			if decompressed[offset+3] == 0 && decompressed[offset+4] == 0 && decompressed[offset+5] == 0 {
				if !seen[itemNo] {
					seen[itemNo] = true
					items = append(items, CharacterItem{
						SlotNo:   offset,
						ItemId:   itemNo,
						Count:    count,
						Category: categorizeItem(itemNo),
					})
				}
			}
		}
	}

	// Get item names from dnf_item_info
	if len(items) > 0 {
		itemNos := make([]int, 0, len(items))
		for _, item := range items {
			itemNos = append(itemNos, item.ItemId)
		}
		inClause := buildInClause(itemNos)
		nameRows, err := sdb.DB.Query(
			fmt.Sprintf("SELECT it_no, it_name, rarity FROM taiwan_cain_web.dnf_item_info WHERE it_no IN (%s)", inClause),
		)
		if err == nil {
			defer nameRows.Close()
			type itemMeta struct {
				Name   string
				Rarity int
			}
			metaMap := make(map[int]itemMeta)
			for nameRows.Next() {
				var itNo int
				var name string
				var rarity int
				if err := nameRows.Scan(&itNo, &name, &rarity); err == nil {
					metaMap[itNo] = itemMeta{Name: decodeUnicode(name), Rarity: rarity}
				}
			}
			for i := range items {
				if m, ok := metaMap[items[i].ItemId]; ok {
					items[i].ItemName = m.Name
					items[i].Rarity = m.Rarity
				}
			}
		}
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

// --- Internal helpers ---

// decompressZlib decompresses zlib data
func decompressZlib(data []byte) ([]byte, error) {
	reader, err := zlib.NewReader(bytes.NewReader(data))
	if err != nil {
		return nil, err
	}
	defer reader.Close()
	return io.ReadAll(reader)
}

// buildInClause builds a SQL IN clause from a list of ints
func buildInClause(ids []int) string {
	result := ""
	for i, id := range ids {
		if i > 0 {
			result += ","
		}
		result += fmt.Sprintf("%d", id)
	}
	return result
}

// decodeUnicode decodes \uXXXX escape sequences and handles latin1-encoded UTF-8
func decodeUnicode(s string) string {
	// First, try to decode \uXXXX escape sequences
	re := regexp.MustCompile(`\\u([0-9a-fA-F]{4})`)
	result := re.ReplaceAllStringFunc(s, func(match string) string {
		hexStr := match[2:]
		r, err := strconv.ParseInt(hexStr, 16, 32)
		if err != nil {
			return match
		}
		return string(rune(r))
	})
	
	// If still has \u escapes, try hex decoding
	if strings.Contains(result, "\\u") {
		re2 := regexp.MustCompile(`\\u([0-9a-fA-F]{4})`)
		result = re2.ReplaceAllStringFunc(result, func(match string) string {
			hexStr := match[2:]
			r, err := strconv.ParseInt(hexStr, 16, 32)
			if err != nil {
				return match
			}
			return string(rune(r))
		})
	}
	
	return result
}

// categorizeItem categorizes an item by its it_no range
func categorizeItem(itNo int) string {
	switch {
	case itNo >= 1000 && itNo < 2000:
		return "材料"
	case itNo >= 2000 && itNo < 3000:
		return "任務"
	case itNo >= 3000 && itNo < 4000:
		return "副職業"
	case itNo >= 4000 && itNo < 5000:
		return "消耗品"
	case itNo >= 5000 && itNo < 10000:
		return "裝備"
	case itNo >= 10000:
		return "裝備"
	default:
		return "其他"
	}
}
