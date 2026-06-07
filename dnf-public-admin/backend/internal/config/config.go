package config

import "os"

type Config struct {
    AppName  string
    HTTPAddr string
}

func Load() Config {
    addr := os.Getenv("HTTP_ADDR")
    if addr == "" {
        addr = ":8080"
    }

    name := os.Getenv("APP_NAME")
    if name == "" {
        name = "dnf-public-admin"
    }

    return Config{AppName: name, HTTPAddr: addr}
}
