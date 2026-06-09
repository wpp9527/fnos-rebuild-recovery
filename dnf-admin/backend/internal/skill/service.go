package skill

import (
	"bytes"
	"compress/zlib"
	"encoding/binary"
	"fmt"
	"golang.org/x/text/encoding/traditionalchinese"
	"golang.org/x/text/transform"
	"io"
	"strconv"
	"strings"
	"sync"
	"unicode/utf8"

	"dnf-admin/internal/database"
)

type SkillSlot struct {
	SkillIndex int    `json:"skill_index"`
	Level      int    `json:"level"`
	MaxLevel   int    `json:"max_level"`
	Name       string `json:"name"`
	Explain    string `json:"explain"`
	Icon       string `json:"icon"`
	Type       int    `json:"type"`
}

type SkillInfo struct {
	JobIndex      int    `json:"job_index"`
	SkillIndex    int    `json:"skill_index"`
	Name          string `json:"name"`
	BasicExplain  string `json:"basic_explain"`
	SkillExplain  string `json:"skill_explain"`
	MaxLevel      string `json:"max_level"`
	Type          int    `json:"type"`
	Icon          string `json:"icon"`
	RequiredLevel int    `json:"required_level"`
}

type Service struct {
	serverID string
	mu       sync.RWMutex
}

func NewService(serverID string) *Service {
	return &Service{serverID: serverID}
}

func (s *Service) GetSkills(characNo int) ([]SkillSlot, error) {
	sdb, err := database.GetServerDB(s.serverID)
	if err != nil {
		return nil, fmt.Errorf("server not found: %s", s.serverID)
	}

	// 获取角色的 job
	var job int
	err = sdb.DB.QueryRow(`SELECT job FROM taiwan_cain.charac_info WHERE charac_no = ?`, characNo).Scan(&job)
	if err != nil {
		return nil, fmt.Errorf("query character job: %w", err)
	}

	var skillSlotBlob []byte
	err = sdb.DB.QueryRow(`
		SELECT skill_slot FROM taiwan_cain_2nd.skill WHERE charac_no = ?
	`, characNo).Scan(&skillSlotBlob)
	if err != nil {
		return nil, fmt.Errorf("query skill: %w", err)
	}

	slots := parseSkillBlob(skillSlotBlob)

	// 获取技能详情
	if len(slots) > 0 {
		for i, slot := range slots {
			// 技能索引映射：skill_index = raw_idx % 256
			mappedIndex := slot.SkillIndex % 256
			var name, explain, icon string
			var skillType int
			err := sdb.DB.QueryRow(`
				SELECT COALESCE(name,''), COALESCE(basic_explain,''), COALESCE(icon,''), type
				FROM taiwan_cain_web.skill_info 
				WHERE job_index = ? AND skill_index = ? AND module_type = 0
				LIMIT 1
			`, job, mappedIndex).Scan(&name, &explain, &icon, &skillType)
			if err == nil {
				slots[i].Name = fixEncoding(name)
				slots[i].Explain = fixEncoding(explain)
				slots[i].Icon = icon
				slots[i].Type = skillType
			}
		}
	}

	return slots, nil
}

func (s *Service) ListSkillInfo(jobIndex int) ([]SkillInfo, error) {
	sdb, err := database.GetServerDB(s.serverID)
	if err != nil {
		return nil, fmt.Errorf("server not found: %w", err)
	}

	query := `
		SELECT job_index, skill_index, COALESCE(name,''), COALESCE(basic_explain,''), 
		       COALESCE(skill_explain,''), COALESCE(growtype_maximum_level,''), 
		       type, COALESCE(icon,''), required_level
		FROM taiwan_cain_web.skill_info 
		WHERE module_type = 0`
	args := []interface{}{}
	if jobIndex >= 0 {
		query += " AND job_index = ?"
		args = append(args, jobIndex)
	}
	query += " ORDER BY job_index, skill_index"

	rows, err := sdb.DB.Query(query, args...)
	if err != nil {
		return nil, fmt.Errorf("query skill_info: %w", err)
	}
	defer rows.Close()

	var infos []SkillInfo
	for rows.Next() {
		var si SkillInfo
		if err := rows.Scan(&si.JobIndex, &si.SkillIndex, &si.Name, &si.BasicExplain,
			&si.SkillExplain, &si.MaxLevel, &si.Type, &si.Icon, &si.RequiredLevel); err != nil {
			continue
		}
		si.Name = fixEncoding(si.Name)
		si.BasicExplain = fixEncoding(si.BasicExplain)
		si.SkillExplain = fixEncoding(si.SkillExplain)
		infos = append(infos, si)
	}
	return infos, nil
}

func parseSkillBlob(data []byte) []SkillSlot {
	if len(data) < 4 {
		return nil
	}

	// 跳过4字节头，解压 zlib
	compressed := data[4:]
	r, err := zlib.NewReader(bytes.NewReader(compressed))
	if err != nil {
		// 尝试不跳过头
		r, err = zlib.NewReader(bytes.NewReader(data))
		if err != nil {
			return nil
		}
	}
	defer r.Close()

	decompressed, err := io.ReadAll(r)
	if err != nil {
		return nil
	}

	var slots []SkillSlot
	// 每2字节一个技能条目：uint16 存储 (level << 8) | skill_index
	for i := 0; i+1 < len(decompressed); i += 2 {
		val := binary.LittleEndian.Uint16(decompressed[i : i+2])
		if val == 0 {
			continue
		}
		skillIdx := int(val & 0xFF)  // 低8位是 skill_index
		level := int(val >> 8)       // 高8位是 level

		slots = append(slots, SkillSlot{
			SkillIndex: skillIdx,
			Level:      level,
			MaxLevel:   0,
		})
	}
	return slots
}

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

	// 尝试 UTF-8 解码（处理双重编码）
	if utf8.Valid(b) {
		result := string(b)
		if result != s {
			return result
		}
	}

	// 尝试 Big5 解码
	decoder := traditionalchinese.Big5.NewDecoder()
	decoded, _, err := transform.Bytes(decoder, b)
	if err == nil && utf8.Valid(decoded) {
		result := string(decoded)
		if result != s {
			return result
		}
	}

	return s
}

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

// unused but kept for potential future use
var _ = strconv.Itoa
var _ = strings.Contains
