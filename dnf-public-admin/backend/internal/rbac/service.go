package rbac

type ModulePermission struct {
    Key    string `json:"key"`
    Name   string `json:"name"`
    Access string `json:"access"`
}

func DefaultPermissions() []ModulePermission {
    return []ModulePermission{
        {Key: "auth", Name: "认证与权限", Access: "manage"},
        {Key: "account", Name: "账号查询", Access: "read"},
        {Key: "character", Name: "角色查询", Access: "read"},
        {Key: "pvf", Name: "PVF 检索", Access: "read"},
        {Key: "gm", Name: "GM 操作", Access: "write"},
        {Key: "audit", Name: "审计日志", Access: "read"},
    }
}

func Can(scopes []string, action string) bool {
    for _, scope := range scopes {
        if scope == action || scope == "*" {
            return true
        }
    }
    return false
}
