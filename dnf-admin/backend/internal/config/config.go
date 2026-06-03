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
	RedisAddr   string
	RedisPass   string
}

func Load() *Config {
	return &Config{
		ServerPort: getEnv("SERVER_PORT", "8080"),
		DBHost:     getEnv("DB_HOST", "127.0.0.1"),
		DBPort:     getEnv("DB_PORT", "3306"),
		DBName:     getEnv("DB_NAME", "dnf_service"),
		DBUser:     getEnv("DB_USER", "readonly"),
		DBPassword: getEnv("DB_PASSWORD", ""),
		JWTSecret:  getEnv("JWT_SECRET", "dnf-admin-secret-key-change-me"),
		PVFService: getEnv("PVF_SERVICE", "http://127.0.0.1:5000"),
		RedisAddr:  getEnv("REDIS_ADDR", "127.0.0.1:6379"),
		RedisPass:  getEnv("REDIS_PASS", ""),
	}
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
