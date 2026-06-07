package llnut

const (
    DefaultAdminPort      = 882
    DefaultSupervisorPort = 2000
    DefaultGameLoginPort  = 3000

    DefaultProjectName = "dnf-llnut"

    DatabaseAccounts = "d_taiwan"
    DatabaseLogin    = "taiwan_login"
    DatabaseCain     = "taiwan_cain"
    DatabaseCain2nd  = "taiwan_cain_2nd"
    DatabaseBilling  = "taiwan_billing"
)

type RuntimeBaseline struct {
    ProjectName    string            `json:"project_name"`
    Ports          map[string]int    `json:"ports"`
    Databases      map[string]string `json:"databases"`
    DataPolicy     string            `json:"data_policy"`
    Compatibility  string            `json:"compatibility"`
}

func Baseline() RuntimeBaseline {
    return RuntimeBaseline{
        ProjectName: DefaultProjectName,
        Ports: map[string]int{
            "admin":      DefaultAdminPort,
            "supervisor": DefaultSupervisorPort,
            "game_login": DefaultGameLoginPort,
        },
        Databases: map[string]string{
            "accounts": DatabaseAccounts,
            "login":    DatabaseLogin,
            "cain":     DatabaseCain,
            "cain_2nd": DatabaseCain2nd,
            "billing":  DatabaseBilling,
        },
        DataPolicy:    "reuse legacy dnf-console ports and llnut game databases; do not fork or migrate game data by default",
        Compatibility: "104/dnf-llnut baseline: old dnf-console remains source of truth until read-only checks pass",
    }
}
