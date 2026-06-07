package config

import "os"

type Config struct {
	ServerPort  string
	DBHost      string
	DBPort      string
	DBName      string
	DBUser      string
	DBPassword  string
	JWTSecret   string
	PVFService  string
	PVFFile     string
	RedisAddr   string
	RedisPass   string
	ServerID    string
	ServerName  string
}

func Load() *Config {
	return &Config{
		ServerPort: getEnv("SERVER_PORT", "18882"),
		DBHost:     getEnv("DB_HOST", "127.0.0.1"),
		DBPort:     getEnv("DB_PORT", "3306"),
		DBName:     getEnv("DB_NAME", "d_taiwan"),
		DBUser:     getEnv("DB_USER", "root"),
		DBPassword: getEnv("DB_PASSWORD", ""),
		JWTSecret:  getEnv("JWT_SECRET", "dnf-admin-secret-key-change-me"),
		PVFService: getEnv("PVF_SERVICE", "http://127.0.0.1:5000"),
		PVFFile:    getEnv("PVF_FILE", ""),
		RedisAddr:  getEnv("REDIS_ADDR", "127.0.0.1:6379"),
		RedisPass:  getEnv("REDIS_PASS", ""),
		ServerID:   getEnv("SERVER_ID", "local"),
		ServerName: getEnv("SERVER_NAME", "本地区"),
	}
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
