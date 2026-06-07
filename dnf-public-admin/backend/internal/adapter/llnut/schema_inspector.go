package llnut

import (
    "fmt"
)

var requiredReadOnlyColumns = map[string][]string{
    DatabaseAccounts + ".accounts": {"UID", "accountname"},
}

func ValidateReadOnlySchema(columnsByTable map[string][]string) error {
    for table, required := range requiredReadOnlyColumns {
        columns, ok := columnsByTable[table]
        if !ok {
            return fmt.Errorf("required table %s not found", table)
        }
        present := map[string]bool{}
        for _, column := range columns {
            present[column] = true
        }
        for _, column := range required {
            if !present[column] {
                return fmt.Errorf("required column %s.%s not found", table, column)
            }
        }
    }
    return nil
}
