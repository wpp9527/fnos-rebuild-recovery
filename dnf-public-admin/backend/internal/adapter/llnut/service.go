package llnut

type Account struct {
    ID       string `json:"id"`
    Username string `json:"username"`
    Status   string `json:"status"`
    Roles    int    `json:"roles"`
}

type Character struct {
    ID        string `json:"id"`
    Name      string `json:"name"`
    Level     int    `json:"level"`
    Job       string `json:"job"`
    AccountID string `json:"account_id"`
}

type Service struct{}

func NewService() Service {
    return Service{}
}

func (s Service) ListAccounts() []Account {
    return []Account{
        {ID: "acc-1", Username: "player_alpha", Status: "active", Roles: 3},
        {ID: "acc-2", Username: "player_beta", Status: "banned", Roles: 1},
        {ID: "acc-3", Username: "event_tester", Status: "active", Roles: 2},
    }
}

func (s Service) ListCharacters() []Character {
    return []Character{
        {ID: "char-1", Name: "鬼剑士阿修", Level: 70, Job: "阿修罗", AccountID: "acc-1"},
        {ID: "char-2", Name: "神枪夜影", Level: 65, Job: "漫游枪手", AccountID: "acc-1"},
        {ID: "char-3", Name: "魔法学徒星", Level: 60, Job: "元素师", AccountID: "acc-3"},
    }
}
