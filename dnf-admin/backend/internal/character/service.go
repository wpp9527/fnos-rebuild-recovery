package character

import (
	"bytes"
	"compress/zlib"
	"database/sql"
	"fmt"
	"golang.org/x/text/encoding/traditionalchinese"
	"golang.org/x/text/transform"
	"io"
	"regexp"
	"strconv"
	"time"
	"unicode/utf8"

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

	// Each equipment slot is 122 bytes
	// item_no is at local offset 2-4 (3-byte LE)
	slotSize := 122
	slotNames := []string{"武器", "上衣", "下裝", "頭肩", "腰帶", "鞋子", "項鏈", "手鐲", "戒指", "輔助裝備", "魔法石", "耳環"}

	var equipment []Equipment
	for slot := 0; slot < 12; slot++ {
		start := slot * slotSize
		if start+slotSize > len(decompressed) {
			break
		}

		block := decompressed[start : start+slotSize]
		itemNo := int(block[2]) | int(block[3])<<8 | int(block[4])<<16  // 3-byte LE
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

// fixEncoding repairs strings from dnf_item_info where UTF-8 bytes were
// stored in latin1 columns. The MySQL driver with charset=utf8 partially
// decodes high bytes into Latin Extended Unicode chars via cp1252.
func fixEncoding(s string) string {
	if len(s) == 0 {
		return s
	}

	// 把每个 rune 转回 byte
	var b []byte
	for _, r := range s {
		if r > 255 {
			orig, ok := unicodeToByte(r)
			if ok {
				b = append(b, orig)
			} else {
				b = append(b, byte(r&0xFF))
			}
		} else {
			b = append(b, byte(r))
		}
	}

	// 如果原始字符串和转换后的字节不同，尝试解码
	if string(b) != s {
		// 尝试 UTF-8 解码
		if utf8.Valid(b) {
			return string(b)
		}
		// 尝试 Big5 解码
		decoder := traditionalchinese.Big5.NewDecoder()
		decoded, _, err := transform.Bytes(decoder, b)
		if err == nil && utf8.Valid(decoded) {
			return string(decoded)
		}
	}

	// 即使字符串相同，也尝试 Big5 解码（可能是纯 ASCII 或 latin1）
	decoder := traditionalchinese.Big5.NewDecoder()
	decoded, _, err := transform.Bytes(decoder, b)
	if err == nil && utf8.Valid(decoded) && string(decoded) != s {
		return string(decoded)
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

// decodeUnicode decodes \uXXXX escape sequences and handles latin1-encoded UTF-8
func decodeUnicode(s string) string {
	// First fix encoding
	s = fixEncoding(s)
	// Then decode \uXXXX escape sequences
	re := regexp.MustCompile(`\\u([0-9a-fA-F]{4})`)
	result := re.ReplaceAllStringFunc(s, func(match string) string {
		hexStr := match[2:]
		r, err := strconv.ParseInt(hexStr, 16, 32)
		if err != nil {
			return match
		}
		return string(rune(r))
	})
	return result
}

// CharacterDetail represents detailed character info with stats
// swagger:model CharacterDetail
type CharacterDetail struct {
	Character
	MaxFatigue        int    `json:"max_fatigue" example:"70"`
	UsedFatigue       int    `json:"used_fatigue" example:"45"`
	PremiumFatigue    int    `json:"premium_fatigue" example:"0"`
	DungeonClearPoint int    `json:"dungeon_clear_point" example:"150"`
	TradeGoldTotal    int    `json:"trade_gold_total" example:"50000"`
	DungeonPlayCount  int    `json:"dungeon_play_count" example:"320"`
	TotalPlayTime     int    `json:"total_play_time" example:"7200"`
	LuckPoint         int    `json:"luck_point" example:"5000"`
	GuildID           int    `json:"guild_id" example:"1"`
	GuildName         string `json:"guild_name" example:"測試公會"`
	GuildLevel        int    `json:"guild_level" example:"5"`
	Money             int    `json:"money" example:"1000000"`
	Coin              int    `json:"coin" example:"500"`
}

// EquipmentDetail represents a equipped item with full stats
// swagger:model EquipmentDetail
type EquipmentDetail struct {
	Equipment
	PhyAtt        int     `json:"phy_att"`
	MagAtt        int     `json:"mag_att"`
	PhyDef        int     `json:"phy_def"`
	MagDef        int     `json:"mag_def"`
	HPMax         int     `json:"hp_max"`
	MPMax         int     `json:"mp_max"`
	MovSpeed      int     `json:"mov_speed"`
	AtkSpeed      int     `json:"att_speed"`
	CastSpd       int     `json:"cast_speed"`
	JumpBonus     int     `json:"jump_bonus"`
	HitRecBonus   int     `json:"hit_recovery_bonus"`
	CritRate      float64 `json:"criticalhit_rate"`
	StuckRate     float64 `json:"stuck_rate"`
	RefFire       int     `json:"ref_fire"`
	RefWater      int     `json:"ref_water"`
	RefDark       int     `json:"ref_dark"`
	RefLight      int     `json:"ref_light"`
	RefAll        int     `json:"ref_all"`
	Explain       string  `json:"explain"`
	DetailExplain string  `json:"detail_explain"`
	FlavorText    string  `json:"flavor_text"`
	SetName       string  `json:"set_name"`
	SetItem       string  `json:"set_item"`
	SkillLevelUp  string  `json:"skill_levelup"`
	AmplifyOption int     `json:"amplify_option"`
	AmplifyValue  int     `json:"amplify_value"`
}

// GetDetail retrieves detailed character info with stats, guild, money
func (s *Service) GetDetail(serverID string, cNo int) (*CharacterDetail, error) {
	sdb, err := database.GetServerDB(serverID)
	if err != nil {
		return nil, fmt.Errorf("server not found: %s", serverID)
	}

	var d CharacterDetail
	err = sdb.DB.QueryRow(`
		SELECT c.charac_no, c.charac_name, c.lev, c.job, c.grow_type, c.sex,
		  c.maxHP, c.maxMP, c.phy_attack, c.phy_defense, c.mag_attack, c.mag_defense,
		  c.move_speed, c.attack_speed, c.cast_speed, c.jump, c.hit_recovery, c.exp,
		  c.fatigue, c.max_fatigue, c.create_time, c.last_play_time, c.guild_id,
		  COALESCE(s.used_fatigue,0), COALESCE(s.premium_fatigue,0), COALESCE(s.dungeon_clear_point,0),
		  COALESCE(s.trade_gold_total,0), COALESCE(s.dungeon_play_count,0), COALESCE(s.total_play_time,0), COALESCE(s.luck_point,0),
		  COALESCE(i.money,0), COALESCE(i.coin,0)
		FROM taiwan_cain.charac_info c
		LEFT JOIN taiwan_cain.charac_stat s ON c.charac_no = s.charac_no
		LEFT JOIN taiwan_cain_2nd.inventory i ON c.charac_no = i.charac_no
		WHERE c.charac_no = ?
	`, cNo).Scan(
		&d.CNo, &d.CName, &d.CLevel, &d.CJob, &d.GrowType, &d.Sex,
		&d.MaxHP, &d.MaxMP, &d.PhyAttack, &d.PhyDefense, &d.MagAttack, &d.MagDefense,
		&d.MoveSpeed, &d.AttackSpeed, &d.CastSpeed, &d.Jump, &d.HitRecovery, &d.Exp,
		&d.CFatigue, &d.MaxFatigue, &d.CreateTime, &d.CLastLogin, &d.GuildID,
		&d.UsedFatigue, &d.PremiumFatigue, &d.DungeonClearPoint,
		&d.TradeGoldTotal, &d.DungeonPlayCount, &d.TotalPlayTime, &d.LuckPoint,
		&d.Money, &d.Coin,
	)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("get character detail: %w", err)
	}

	d.ServerID = serverID
	d.ServerName = sdb.Name

	// 获取公会名
	if d.GuildID > 0 {
		var guildName string
		sdb.DB.QueryRow(`SELECT guild_name FROM d_guild.guild_info WHERE guild_id = ?`, d.GuildID).Scan(&guildName)
		d.GuildName = fixEncoding(guildName)
		sdb.DB.QueryRow(`SELECT lev FROM d_guild.guild_info WHERE guild_id = ?`, d.GuildID).Scan(&d.GuildLevel)
	}

	return &d, nil
}

// GetEquipmentDetail retrieves equipped items with full stats from dnf_item_info
func (s *Service) GetEquipmentDetail(serverID string, cNo int) ([]EquipmentDetail, error) {
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

	decompressed, err := decompressZlib(equipslotBlob[4:])
	if err != nil {
		return nil, fmt.Errorf("decompress equipslot: %w", err)
	}

	slotSize := 122
	slotNames := []string{"武器", "上衣", "下裝", "頭肩", "腰帶", "鞋子", "項鏈", "手鐲", "戒指", "輔助裝備", "魔法石", "耳環"}

	var equipment []EquipmentDetail
	for slot := 0; slot < 12; slot++ {
		start := slot * slotSize
		if start+slotSize > len(decompressed) {
			break
		}
		block := decompressed[start : start+slotSize]
		itemNo := int(block[2]) | int(block[3])<<8 | int(block[4])<<16  // 3-byte LE
		enhance := int(block[6])
		ampOpt := int(block[48])
		ampVal := int(block[49]) | int(block[50])<<8

		eq := EquipmentDetail{
			Equipment: Equipment{
				SlotNo:   slot,
				SlotName: slotNames[slot],
				ItemId:   itemNo,
				Enhance:  enhance,
			},
			AmplifyOption: ampOpt,
			AmplifyValue:  ampVal,
		}
		equipment = append(equipment, eq)
	}

	// Get full item details from dnf_item_info
	if len(equipment) > 0 {
		itIDs := make([]int, 0, len(equipment))
		for _, eq := range equipment {
			if eq.ItemId > 0 {
				itIDs = append(itIDs, eq.ItemId)
			}
		}
		if len(itIDs) > 0 {
			inClause := buildInClause(itIDs)
			rows, err := sdb.DB.Query(fmt.Sprintf(`
				SELECT it_no, it_name, rarity, level,
				  COALESCE(equip_phy_att,0), COALESCE(equip_mag_att,0), COALESCE(equip_phy_def,0), COALESCE(equip_mag_def,0),
				  COALESCE(hp_max,0), COALESCE(mp_max,0),
				  COALESCE(mov_speed,0), COALESCE(att_speed,0),
				  COALESCE(jump,0), COALESCE(hit_recovery,0),
				  COALESCE(criticalhit_rate,0), COALESCE(stuck_rate,0),
				  COALESCE(ref_fire,0), COALESCE(ref_water,0), COALESCE(ref_dark,0), COALESCE(ref_light,0), COALESCE(ref_all,0),
				  COALESCE(it_explain,''), COALESCE(detail_explain,''), COALESCE(flavor_text,''),
				  COALESCE(set_name,''), COALESCE(set_item,''), COALESCE(skill_levelup,'')
				FROM taiwan_cain_web.dnf_item_info WHERE it_no IN (%s)
			`, inClause))
			if err == nil {
				defer rows.Close()
				type itemFull struct {
					Name, Explain, DetailExplain, FlavorText string
					SetName, SetItem, SkillLevelUp string
					Rarity, Level int
					PhyAtt, MagAtt, PhyDef, MagDef int
					HPMax, MPMax int
					MovSpeed, AtkSpeed, CastSpd int
					Jump, HitRec int
					CritRate, StuckRate float64
					RefFire, RefWater, RefDark, RefLight, RefAll int
				}
				infoMap := make(map[int]itemFull)
				for rows.Next() {
					var itNo int
					var info itemFull
					if err := rows.Scan(&itNo, &info.Name, &info.Rarity, &info.Level,
						&info.PhyAtt, &info.MagAtt, &info.PhyDef, &info.MagDef,
						&info.HPMax, &info.MPMax,
						&info.MovSpeed, &info.AtkSpeed,
						&info.Jump, &info.HitRec,
						&info.CritRate, &info.StuckRate,
						&info.RefFire, &info.RefWater, &info.RefDark, &info.RefLight, &info.RefAll,
						&info.Explain, &info.DetailExplain, &info.FlavorText,
						&info.SetName, &info.SetItem, &info.SkillLevelUp,
					); err == nil {
						infoMap[itNo] = info
					}
				}
				for i := range equipment {
					if info, ok := infoMap[equipment[i].ItemId]; ok {
						equipment[i].ItemName = decodeUnicode(info.Name)
						equipment[i].Rarity = info.Rarity
						equipment[i].Level = info.Level
						equipment[i].PhyAtk = info.PhyAtt
						equipment[i].MagAtk = info.MagAtt
						equipment[i].PhyDef = info.PhyDef
						equipment[i].MagDef = info.MagDef
						equipment[i].HPMax = info.HPMax
						equipment[i].MPMax = info.MPMax
						equipment[i].MovSpeed = info.MovSpeed
						equipment[i].AtkSpeed = info.AtkSpeed
						equipment[i].CastSpd = info.CastSpd
						equipment[i].JumpBonus = info.Jump
						equipment[i].HitRecBonus = info.HitRec
						equipment[i].CritRate = info.CritRate
						equipment[i].StuckRate = info.StuckRate
						equipment[i].RefFire = info.RefFire
						equipment[i].RefWater = info.RefWater
						equipment[i].RefDark = info.RefDark
						equipment[i].RefLight = info.RefLight
						equipment[i].RefAll = info.RefAll
						equipment[i].Explain = decodeUnicode(info.Explain)
						equipment[i].DetailExplain = decodeUnicode(info.DetailExplain)
						equipment[i].FlavorText = decodeUnicode(info.FlavorText)
						equipment[i].SetName = decodeUnicode(info.SetName)
						equipment[i].SetItem = decodeUnicode(info.SetItem)
						equipment[i].SkillLevelUp = decodeUnicode(info.SkillLevelUp)
					}
				}
			}
		}
	}

	return equipment, nil
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
