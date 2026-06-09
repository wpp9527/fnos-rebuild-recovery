package stat

import (
	"fmt"
	"sync"

	"dnf-admin/internal/database"
)

type DungeonStat struct {
	DungeonIndex int `json:"dungeon_index"`
	CharacCount  int `json:"charac_count"`
}

type PVPRank struct {
	CharacNo   int     `json:"charac_no"`
	CharacName string  `json:"charac_name"`
	Level      int     `json:"level"`
	Job        int     `json:"job"`
	Win        int     `json:"win"`
	Lose       int     `json:"lose"`
	PVPGrade   int     `json:"pvp_grade"`
	PVPPoint   int     `json:"pvp_point"`
	WinRate    float64 `json:"win_rate"`
}

type OnlineStat struct {
	TotalChars  int `json:"total_chars"`
	OnlineChars int `json:"online_chars"`
	TotalGuilds int `json:"total_guilds"`
	TotalPVP    int `json:"total_pvp"`
}

type Service struct {
	serverID string
	mu       sync.RWMutex
}

func NewService(serverID string) *Service {
	return &Service{serverID: serverID}
}

func (s *Service) GetOnlineStat() (*OnlineStat, error) {
	sdb, err := database.GetServerDB(s.serverID)
	if err != nil {
		return nil, fmt.Errorf("server not found: %s", s.serverID)
	}

	stat := &OnlineStat{}

	sdb.DB.QueryRow(`SELECT COUNT(*) FROM taiwan_cain.charac_info WHERE delete_flag = 0`).Scan(&stat.TotalChars)
	sdb.DB.QueryRow(`SELECT COUNT(*) FROM taiwan_cain.charac_info WHERE last_play_time > DATE_SUB(NOW(), INTERVAL 1 HOUR) AND delete_flag = 0`).Scan(&stat.OnlineChars)
	sdb.DB.QueryRow(`SELECT COUNT(*) FROM d_guild.guild_info`).Scan(&stat.TotalGuilds)
	sdb.DB.QueryRow(`SELECT COUNT(*) FROM taiwan_cain.pvp_result WHERE win > 0 OR lose > 0`).Scan(&stat.TotalPVP)

	return stat, nil
}

func (s *Service) GetPVPRankings(limit int) ([]PVPRank, error) {
	sdb, err := database.GetServerDB(s.serverID)
	if err != nil {
		return nil, fmt.Errorf("server not found: %s", s.serverID)
	}

	if limit <= 0 {
		limit = 50
	}

	rows, err := sdb.DB.Query(`
		SELECT p.charac_no, COALESCE(c.charac_name,''), COALESCE(c.lev,1), COALESCE(c.job,0),
		       p.win, p.lose, p.pvp_grade, p.pvp_point
		FROM taiwan_cain.pvp_result p
		LEFT JOIN taiwan_cain.charac_info c ON p.charac_no = c.charac_no
		WHERE p.pvp_point > 0
		ORDER BY p.pvp_point DESC
		LIMIT ?
	`, limit)
	if err != nil {
		return nil, fmt.Errorf("query pvp: %w", err)
	}
	defer rows.Close()

	var ranks []PVPRank
	for rows.Next() {
		var r PVPRank
		if err := rows.Scan(&r.CharacNo, &r.CharacName, &r.Level, &r.Job,
			&r.Win, &r.Lose, &r.PVPGrade, &r.PVPPoint); err != nil {
			continue
		}
		total := r.Win + r.Lose
		if total > 0 {
			r.WinRate = float64(r.Win) / float64(total) * 100
		}
		ranks = append(ranks, r)
	}
	return ranks, nil
}

func (s *Service) GetDungeonStats() ([]DungeonStat, error) {
	sdb, err := database.GetServerDB(s.serverID)
	if err != nil {
		return nil, fmt.Errorf("server not found: %s", s.serverID)
	}

	rows, err := sdb.DB.Query(`
		SELECT dungeon_index, COUNT(DISTINCT charac_no) as charac_count
		FROM taiwan_cain_log.log_dungeon_entrance
		GROUP BY dungeon_index
		ORDER BY charac_count DESC
		LIMIT 50
	`)
	if err != nil {
		return nil, fmt.Errorf("query dungeon stats: %w", err)
	}
	defer rows.Close()

	var stats []DungeonStat
	for rows.Next() {
		var ds DungeonStat
		if err := rows.Scan(&ds.DungeonIndex, &ds.CharacCount); err != nil {
			continue
		}
		stats = append(stats, ds)
	}
	return stats, nil
}
