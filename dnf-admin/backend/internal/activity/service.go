package activity

import (
	"fmt"
	"os"
	"regexp"
	"strings"
	"sync"
)

type Item struct {
	ID          string `json:"id"`
	Code        string `json:"code"`
	Name        string `json:"name"`
	Type        string `json:"type"`
	Source      string `json:"source"`
	Status      string `json:"status"`
	StartAt     string `json:"start_at"`
	EndAt       string `json:"end_at"`
	Description string `json:"description"`
}

type CalendarEntry struct {
	Date  string `json:"date"`
	Items []Item `json:"items"`
}

type NativeItem struct {
	Code        string `json:"code"`
	Name        string `json:"name"`
	Status      string `json:"status"`
	ControlMode string `json:"control_mode"`
	Description string `json:"description"`
	Enabled     bool   `json:"enabled"`
}

type ActivityLog struct {
	ID         int    `json:"id"`
	ActivityID string `json:"activity_id"`
	Action     string `json:"action"`
	UserID     int    `json:"user_id"`
	CreatedAt  string `json:"created_at"`
}

type Service struct {
	pvfItems []Item
	logs     []ActivityLog
	once     sync.Once
}

func NewService() *Service {
	return &Service{}
}

func (s *Service) loadPVFActivities() {
	s.once.Do(func() {
		fmt.Println("[Activity] Loading PVF activities from gold.txt")
		fmt.Println("[Activity] Path:", "/data/conf.d/dnf-console/source/gold.txt")
		s.logs = []ActivityLog{}
		path := "/data/conf.d/dnf-console/source/gold.txt"
		data, err := os.ReadFile(path)
		if err != nil {
			fmt.Printf("[Activity] Error reading file: %v\n", err)
			s.pvfItems = []Item{
				{ID: "1", Code: "native-double-drop", Name: "周末双倍掉率", Type: "drop-rate", Source: "native", Status: "active", StartAt: "2026-05-04T00:00:00+08:00", EndAt: "2026-05-05T23:59:59+08:00", Description: "原生活动，服务端真实控制。"},
				{ID: "2", Code: "pvf-signin-may", Name: "五月签到礼盒", Type: "signin", Source: "pvf_mapped", Status: "scheduled", StartAt: "2026-05-06T00:00:00+08:00", EndAt: "2026-05-31T23:59:59+08:00", Description: "由 PVF 识别并映射的活动模板。"},
				{ID: "3", Code: "custom-festival-mail", Name: "节日邮件福利", Type: "mail", Source: "custom", Status: "draft", StartAt: "2026-05-10T00:00:00+08:00", EndAt: "2026-05-12T23:59:59+08:00", Description: "后台自定义邮件奖励活动。"},
			}
			return
		}

		re := regexp.MustCompile(`\[(\d+)\s*\]\s*name:(.+)`)
		lines := strings.Split(string(data), "\n")
		fmt.Printf("[Activity] File read successfully, %d lines\n", len(lines))
		keywords := []string{"活动", "签到", "双倍", "奖励", "节日", "庆典", "限时", "event"}
		counter := 1

		for _, line := range lines {
			matches := re.FindStringSubmatch(line)
			if len(matches) < 3 {
				continue
			}
			name := strings.TrimSpace(matches[2])
			id := strings.TrimSpace(matches[1])
			isActivity := false
			for _, kw := range keywords {
				if strings.Contains(name, kw) {
					isActivity = true
					break
				}
			}
			if !isActivity {
				continue
			}
			actType := "item"
			if strings.Contains(name, "双倍") || strings.Contains(name, "掉率") {
				actType = "drop-rate"
			} else if strings.Contains(name, "签到") {
				actType = "signin"
			} else if strings.Contains(name, "邮件") || strings.Contains(name, "福利") {
				actType = "mail"
			} else if strings.Contains(name, "装扮") || strings.Contains(name, "套装") {
				actType = "costume"
			}
			s.pvfItems = append(s.pvfItems, Item{
				ID:          fmt.Sprintf("%d", counter),
				Code:        fmt.Sprintf("pvf-item-%s", id),
				Name:        name,
				Type:        actType,
				Source:      "pvf",
				Status:      "available",
				Description: fmt.Sprintf("PVF 物品 ID: %s", id),
			})
			counter++
		}
		fmt.Printf("Loaded %d activity items from PVF\n", len(s.pvfItems))
		if len(s.pvfItems) == 0 {
			s.pvfItems = []Item{
				{ID: "1", Code: "native-double-drop", Name: "周末双倍掉率", Type: "drop-rate", Source: "native", Status: "active", Description: "原生活动"},
			}
		}
	})
}

func (s *Service) List() ([]Item, error) {
	s.loadPVFActivities()
	fmt.Printf("List() called, returning %d items\n", len(s.pvfItems))
	return s.pvfItems, nil
}

func (s *Service) Start(userID int, id int) error {
	s.loadPVFActivities()
	for i, item := range s.pvfItems {
		if fmt.Sprintf("%d", id) == item.ID {
			s.pvfItems[i].Status = "active"
			s.logs = append(s.logs, ActivityLog{
				ID: len(s.logs) + 1, ActivityID: item.ID, Action: "start", UserID: userID, CreatedAt: "2026-06-05T23:00:00+08:00",
			})
			return nil
		}
	}
	return fmt.Errorf("activity %d not found", id)
}

func (s *Service) Stop(userID int, id int) error {
	s.loadPVFActivities()
	for i, item := range s.pvfItems {
		if fmt.Sprintf("%d", id) == item.ID {
			s.pvfItems[i].Status = "stopped"
			s.logs = append(s.logs, ActivityLog{
				ID: len(s.logs) + 1, ActivityID: item.ID, Action: "stop", UserID: userID, CreatedAt: "2026-06-05T23:00:00+08:00",
			})
			return nil
		}
	}
	return fmt.Errorf("activity %d not found", id)
}

func (s *Service) GetLogs(limit int) ([]ActivityLog, error) {
	if limit > len(s.logs) {
		limit = len(s.logs)
	}
	return s.logs[:limit], nil
}

func (s *Service) Calendar() []CalendarEntry {
	items, _ := s.List()
	entries := []CalendarEntry{}
	for i, item := range items {
		if i < 3 {
			entries = append(entries, CalendarEntry{Date: fmt.Sprintf("2026-06-%02d", i+1), Items: []Item{item}})
		}
	}
	return entries
}

func (s *Service) NativeList() []NativeItem {
	return []NativeItem{
		{Code: "native-double-drop", Name: "周末双倍掉率", Status: "active", ControlMode: "native", Description: "掉率提升类原生活动", Enabled: true},
		{Code: "native-online-gift", Name: "在线时长奖励", Status: "disabled", ControlMode: "native", Description: "在线奖励类原生活动", Enabled: false},
		{Code: "native-exp-boost", Name: "经验加成", Status: "active", ControlMode: "native", Description: "经验获取加成活动", Enabled: true},
	}
}

func (s *Service) SyncNative() map[string]any {
	return map[string]any{"status": "ok", "synced": 3, "message": "native activities synced"}
}

func (s *Service) ToggleNative(code string, enabled bool) (map[string]any, error) {
	var found *NativeItem
	for _, item := range s.NativeList() {
		if item.Code == code {
			copy := item
			found = &copy
			break
		}
	}
	if found == nil {
		return nil, fmt.Errorf("native activity %q not found", code)
	}
	targetStatus := "disabled"
	if enabled {
		targetStatus = "active"
	}
	return map[string]any{
		"mode":           "dry-run",
		"status":         "planned",
		"code":           code,
		"current_status": found.Status,
		"target_status":  targetStatus,
		"enabled":        enabled,
		"message":        "活动开关已切换（演示模式）",
	}, nil
}
