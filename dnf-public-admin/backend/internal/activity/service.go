package activity

import "fmt"

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
}

type Service struct{}

func NewService() Service {
    return Service{}
}

func (s Service) List() []Item {
    return []Item{
        {
            ID: "act-1", Code: "native-double-drop", Name: "周末双倍掉率", Type: "drop-rate", Source: "native", Status: "active",
            StartAt: "2026-05-04T00:00:00+08:00", EndAt: "2026-05-05T23:59:59+08:00", Description: "原生活动，服务端真实控制。",
        },
        {
            ID: "act-2", Code: "pvf-signin-may", Name: "五月签到礼盒", Type: "signin", Source: "pvf_mapped", Status: "scheduled",
            StartAt: "2026-05-06T00:00:00+08:00", EndAt: "2026-05-31T23:59:59+08:00", Description: "由 PVF 识别并映射的活动模板。",
        },
        {
            ID: "act-3", Code: "custom-festival-mail", Name: "节日邮件福利", Type: "mail", Source: "custom", Status: "draft",
            StartAt: "2026-05-10T00:00:00+08:00", EndAt: "2026-05-12T23:59:59+08:00", Description: "后台自定义邮件奖励活动。",
        },
    }
}

func (s Service) Calendar() []CalendarEntry {
    items := s.List()
    return []CalendarEntry{
        {Date: "2026-05-04", Items: []Item{items[0]}},
        {Date: "2026-05-06", Items: []Item{items[1]}},
        {Date: "2026-05-10", Items: []Item{items[2]}},
    }
}

func (s Service) NativeList() []NativeItem {
    return []NativeItem{
        {Code: "native-double-drop", Name: "周末双倍掉率", Status: "active", ControlMode: "native", Description: "掉率提升类原生活动"},
        {Code: "native-online-gift", Name: "在线时长奖励", Status: "disabled", ControlMode: "native", Description: "在线奖励类原生活动"},
    }
}

func (s Service) SyncNative() map[string]any {
    return map[string]any{
        "status": "ok",
        "synced": 2,
        "message": "native activities synced",
    }
}


func (s Service) ToggleNative(code string, enabled bool) (map[string]any, error) {
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
        "mode": "dry-run",
        "status": "planned",
        "code": code,
        "current_status": found.Status,
        "target_status": targetStatus,
        "message": "native activity toggle is planned only; write operation remains disabled until audit gate passes",
    }, nil
}
