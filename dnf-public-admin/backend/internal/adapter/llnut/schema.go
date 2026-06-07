package llnut

type ColumnRef struct {
    Database string `json:"database"`
    Table    string `json:"table"`
    Column   string `json:"column"`
    Purpose  string `json:"purpose"`
}

type ReadOnlyQueryPlan struct {
    Name        string      `json:"name"`
    Mode        string      `json:"mode"`
    Description string      `json:"description"`
    Columns     []ColumnRef `json:"columns"`
}

func ReadOnlyPlans() []ReadOnlyQueryPlan {
    return []ReadOnlyQueryPlan{
        {
            Name:        "accounts",
            Mode:        "read-only",
            Description: "List existing llnut account rows from the legacy accounts database without changing admin, password, or parent fields.",
            Columns: []ColumnRef{
                {Database: DatabaseAccounts, Table: "accounts", Column: "UID", Purpose: "stable account id"},
                {Database: DatabaseAccounts, Table: "accounts", Column: "accountname", Purpose: "login account name"},
                {Database: DatabaseAccounts, Table: "accounts", Column: "admin", Purpose: "legacy GM flag, read only"},
                {Database: DatabaseAccounts, Table: "accounts", Column: "parent_uid", Purpose: "legacy parent account relation, read only"},
            },
        },
        {
            Name:        "characters",
            Mode:        "read-only",
            Description: "Read character overview from the current llnut Cain databases. Exact table names are resolved by the llnut adapter after live schema inspection.",
            Columns: []ColumnRef{
                {Database: DatabaseCain, Table: "characters", Column: "charac_no", Purpose: "stable character id"},
                {Database: DatabaseCain, Table: "characters", Column: "charac_name", Purpose: "character display name"},
                {Database: DatabaseCain, Table: "characters", Column: "lev", Purpose: "character level"},
                {Database: DatabaseCain2nd, Table: "*", Column: "*", Purpose: "secondary character/account extension data, read only"},
            },
        },
        {
            Name:        "billing",
            Mode:        "read-only-first",
            Description: "Billing and point operations must be audited before write endpoints are enabled.",
            Columns: []ColumnRef{
                {Database: DatabaseBilling, Table: "*", Column: "*", Purpose: "cash/point state and logs, no write in MVP read-only phase"},
            },
        },
    }
}
