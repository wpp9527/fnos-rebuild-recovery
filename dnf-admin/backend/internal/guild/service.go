package guild

import (
	"fmt"
	"sync"

	"dnf-admin/internal/database"
)

type GuildInfo struct {
	GuildID     int    `json:"guild_id"`
	GuildName   string `json:"guild_name"`
	MasterName  string `json:"master_name"`
	Level       int    `json:"level"`
	MemberCount int    `json:"member_count"`
	GuildExp    int    `json:"guild_exp"`
	GuildPoint  int    `json:"guild_point"`
	CreateTime  string `json:"create_time"`
	GuildFund   int    `json:"guild_fund"`
}

type GuildMember struct {
	CharacNo   int    `json:"charac_no"`
	CharacName string `json:"charac_name"`
	Level      int    `json:"level"`
	Job        int    `json:"job"`
	GuildRight int    `json:"guild_right"`
}

type Service struct {
	serverID string
	mu       sync.RWMutex
}

func NewService(serverID string) *Service {
	return &Service{serverID: serverID}
}

func (s *Service) ListGuilds() ([]GuildInfo, error) {
	sdb, err := database.GetServerDB(s.serverID)
	if err != nil {
		return nil, fmt.Errorf("server not found: %s", s.serverID)
	}

	rows, err := sdb.DB.Query(`
		SELECT g.guild_id, g.guild_name, g.lev, g.member_count, 
		       g.guild_exp, g.guild_point, g.create_time, g.guild_fund
		FROM d_guild.guild_info g
		ORDER BY g.guild_point DESC
	`)
	if err != nil {
		return nil, fmt.Errorf("query guilds: %w", err)
	}
	defer rows.Close()

	var guilds []GuildInfo
	for rows.Next() {
		var g GuildInfo
		if err := rows.Scan(&g.GuildID, &g.GuildName, &g.Level, &g.MemberCount,
			&g.GuildExp, &g.GuildPoint, &g.CreateTime, &g.GuildFund); err != nil {
			continue
		}
		g.GuildName = fixEncoding(g.GuildName)
		guilds = append(guilds, g)
	}
	return guilds, nil
}

func (s *Service) GetGuildMembers(guildID int) ([]GuildMember, error) {
	sdb, err := database.GetServerDB(s.serverID)
	if err != nil {
		return nil, fmt.Errorf("server not found: %s", s.serverID)
	}

	rows, err := sdb.DB.Query(`
		SELECT gm.charac_no, c.charac_name, c.lev, c.job, gm.guild_right
		FROM d_guild.guild_member gm
		LEFT JOIN taiwan_cain.charac_info c ON gm.charac_no = c.charac_no
		WHERE gm.guild_id = ?
		ORDER BY gm.guild_right DESC, c.lev DESC
	`, guildID)
	if err != nil {
		return nil, fmt.Errorf("query guild members: %w", err)
	}
	defer rows.Close()

	var members []GuildMember
	for rows.Next() {
		var m GuildMember
		if err := rows.Scan(&m.CharacNo, &m.CharacName, &m.Level, &m.Job, &m.GuildRight); err != nil {
			continue
		}
		members = append(members, m)
	}
	return members, nil
}

// fixEncoding for guild module
func fixEncoding(s string) string {
	if len(s) == 0 {
		return s
	}
	var b []byte
	needsFix := false
	for _, r := range s {
		if r > 255 {
			orig, ok := unicodeToByte(r)
			if ok {
				b = append(b, orig)
				needsFix = true
			} else {
				return s
			}
		} else {
			b = append(b, byte(r))
		}
	}
	if !needsFix {
		return s
	}
	converted := string(b)
	if isValidUTF8(converted) {
		return converted
	}
	return s
}

func isValidUTF8(s string) bool {
	for _, r := range s {
		if r == 0xFFFD {
			return false
		}
	}
	return true
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
