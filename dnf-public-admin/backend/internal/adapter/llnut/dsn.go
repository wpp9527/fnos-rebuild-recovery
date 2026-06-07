package llnut

import (
    "errors"
    "fmt"
    "strings"
)

type MySQLConfig struct {
    Host     string
    Port     int
    Username string
    Password string
    Database string
}

func BuildMySQLDSN(cfg MySQLConfig) (string, error) {
    if strings.TrimSpace(cfg.Host) == "" {
        return "", errors.New("mysql host is required")
    }
    if cfg.Port == 0 {
        cfg.Port = 3306
    }
    if strings.TrimSpace(cfg.Username) == "" {
        return "", errors.New("mysql username is required")
    }
    if strings.EqualFold(cfg.Username, "root") {
        return "", errors.New("read-only llnut adapter must not use root user")
    }
    if !IsLegacyGameDatabase(cfg.Database) {
        return "", fmt.Errorf("database %q is not part of the llnut legacy game baseline", cfg.Database)
    }

    query := "charset=utf8mb4&parseTime=true&loc=Local&readTimeout=5s&timeout=5s"

    return fmt.Sprintf("%s:%s@tcp(%s:%d)/%s?%s", cfg.Username, cfg.Password, cfg.Host, cfg.Port, cfg.Database, query), nil
}

func IsLegacyGameDatabase(name string) bool {
    switch name {
    case DatabaseAccounts, DatabaseLogin, DatabaseCain, DatabaseCain2nd, DatabaseBilling:
        return true
    default:
        return false
    }
}
