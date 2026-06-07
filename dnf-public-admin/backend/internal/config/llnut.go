package config

import (
    "fmt"
    "os"
    "strconv"

    "github.com/wpp9527/dnf-public-admin/backend/internal/adapter/llnut"
)

func LlnutMySQLConfigFromEnv(database string) llnut.MySQLConfig {
    port := 3306
    if raw := os.Getenv("LLNUT_MYSQL_PORT"); raw != "" {
        if parsed, err := strconv.Atoi(raw); err == nil {
            port = parsed
        }
    }
    return llnut.MySQLConfig{
        Host:     getenv("LLNUT_MYSQL_HOST", "127.0.0.1"),
        Port:     port,
        Username: getenv("LLNUT_MYSQL_READONLY_USER", "dnf_readonly"),
        Password: os.Getenv("LLNUT_MYSQL_READONLY_PASSWORD"),
        Database: database,
    }
}

func getenv(key, fallback string) string {
    if value := os.Getenv(key); value != "" {
        return value
    }
    return fallback
}

func LlnutModeFromEnv() string {
    switch os.Getenv("LLNUT_MODE") {
    case "live-readonly":
        return "live-readonly"
    default:
        return "demo"
    }
}

func LlnutDSN() string {
    host := os.Getenv("LLNUT_MYSQL_HOST")
    if host == "" {
        return ""
    }
    port := os.Getenv("LLNUT_MYSQL_PORT")
    if port == "" {
        port = "3306"
    }
    user := os.Getenv("LLNUT_MYSQL_READONLY_USER")
    pass := os.Getenv("LLNUT_MYSQL_READONLY_PASSWORD")
    if user == "" {
        return ""
    }
    return fmt.Sprintf("%s:%s@tcp(%s:%s)/?parseTime=true", user, pass, host, port)
}
