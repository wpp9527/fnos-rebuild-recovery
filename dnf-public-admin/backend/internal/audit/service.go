package audit

type Action struct {
    Key         string `json:"key"`
    Name        string `json:"name"`
    RiskLevel   string `json:"risk_level"`
    Description string `json:"description"`
}

func DefaultActions() []Action {
    return []Action{
        {Key: "login", Name: "管理员登录", RiskLevel: "low", Description: "记录登录行为与结果摘要"},
        {Key: "account.search", Name: "账号查询", RiskLevel: "low", Description: "记录查询条件摘要"},
        {Key: "character.inspect", Name: "角色查看", RiskLevel: "low", Description: "记录角色浏览行为"},
        {Key: "gm.mail.send", Name: "发送邮件", RiskLevel: "high", Description: "高风险，必须审计"},
        {Key: "gm.item.grant", Name: "发放物品", RiskLevel: "high", Description: "高风险，必须审计"},
    }
}

type Event struct {
    ID     int    `json:"id"`
    Actor  string `json:"actor"`
    Action string `json:"action"`
    Target string `json:"target"`
    Result string `json:"result"`
}

type Recorder struct {
    events []Event
}

func NewRecorder() *Recorder {
    return &Recorder{events: []Event{}}
}

func (r *Recorder) Record(event Event) Event {
    event.ID = len(r.events) + 1
    if event.Action == "" {
        event.Result = "rejected"
    }
    if event.Result == "" {
        event.Result = "recorded"
    }
    r.events = append(r.events, event)
    return event
}

func (r *Recorder) List() []Event {
    events := make([]Event, len(r.events))
    copy(events, r.events)
    return events
}
