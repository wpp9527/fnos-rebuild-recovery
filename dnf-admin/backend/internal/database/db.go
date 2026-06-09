package database

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"strconv"
	"sync"

	_ "github.com/go-sql-driver/mysql"

	"dnf-admin/internal/config"
)

var (
	DB       *sql.DB
	mu       sync.RWMutex
	ServerID string
)

// ServerDB represents a database connection for a specific server
type ServerDB struct {
	ID       string
	Name     string
	DB       *sql.DB
}

// serverDBs stores database connections for multiple servers
var serverDBs = make(map[string]*ServerDB)

// ServerConfig represents a server configuration from JSON
type ServerConfig struct {
	ID          string            `json:"id"`
	Name        string            `json:"name"`
	Description string            `json:"description"`
	DBHost      string            `json:"db_host"`
	DBPort      int               `json:"db_port"`
	DBUser      string            `json:"db_user"`
	DBPassword  string            `json:"db_password"`
	Databases   map[string]string `json:"databases"`
}

// serverConfigs stores all server configurations
var serverConfigs = make(map[string]ServerConfig)

// MultiServerConfig represents the multi-server configuration
type MultiServerConfig struct {
	Servers []ServerConfig `json:"servers"`
}

func Init(cfg *config.Config) error {
	// 数据库列是latin1但实际存UTF-8字节，用latin1读取原始字节
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?charset=utf8&parseTime=True&loc=Local",
		cfg.DBUser, cfg.DBPassword, cfg.DBHost, cfg.DBPort, cfg.DBName)

	var err error
	DB, err = sql.Open("mysql", dsn)
	if err != nil {
		log.Printf("Warning: failed to open database: %v", err)
	} else {
		DB.SetMaxOpenConns(10)
		DB.SetMaxIdleConns(5)

		if err := DB.Ping(); err != nil {
			log.Printf("Warning: failed to ping database: %v", err)
			DB = nil
		}
	}

	ServerID = cfg.ServerID

	// Initialize default server connection
	_, _ = InitServerDB(cfg.ServerID, cfg.ServerName, cfg.DBHost, cfg.DBPort, cfg.DBUser, cfg.DBPassword, cfg.DBName)

	// Load multi-server configs from file
	configPath := os.Getenv("SERVERS_CONFIG")
	if configPath == "" {
		configPath = "multi-server/servers.json"
	}
	if _, err := os.Stat(configPath); err == nil {
		if err := LoadAndInitServers(configPath); err != nil {
			log.Printf("Warning: Failed to load multi-server configs: %v", err)
		}
	}

	log.Println("Database connected successfully")
	return nil
}

// LoadAndInitServers loads server configs from file and initializes connections
func LoadAndInitServers(configPath string) error {
	data, err := os.ReadFile(configPath)
	if err != nil {
		return fmt.Errorf("failed to read config file: %w", err)
	}

	// Replace environment variables in the JSON
	configStr := os.ExpandEnv(string(data))

	var config MultiServerConfig
	if err := json.Unmarshal([]byte(configStr), &config); err != nil {
		return fmt.Errorf("failed to parse config file: %w", err)
	}

	for _, server := range config.Servers {
		// 保存配置
		serverConfigs[server.ID] = server

		port := strconv.Itoa(server.DBPort)
		sdb, _ := InitServerDB(
			server.ID,
			server.Name,
			server.DBHost,
			port,
			server.DBUser,
			server.DBPassword,
			server.Databases["accounts"],
		)
		if sdb == nil {
			// 连接失败也注册，让前端能看到区服
			mu.Lock()
			if _, exists := serverDBs[server.ID]; !exists {
				serverDBs[server.ID] = &ServerDB{ID: server.ID, Name: server.Name}
			}
			mu.Unlock()
			log.Printf("Warning: Server %s (%s) database not available", server.Name, server.ID)
			continue
		}
		log.Printf("Server %s (%s) initialized successfully", server.Name, server.ID)
	}

	return nil
}

// InitServerDB initializes a database connection for a specific server
func InitServerDB(serverID, serverName, host, port, user, password, dbName string) (*ServerDB, error) {
	mu.Lock()
	defer mu.Unlock()

	// Check if already connected
	if sdb, exists := serverDBs[serverID]; exists {
		return sdb, nil
	}

	// 数据库列是latin1但实际存UTF-8字节，用latin1读取原始字节
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?charset=utf8&parseTime=True&loc=Local",
		user, password, host, port, dbName)

	db, err := sql.Open("mysql", dsn)
	if err != nil {
		log.Printf("Warning: failed to open database for server %s: %v", serverID, err)
		return nil, nil
	}

	db.SetMaxOpenConns(10)
	db.SetMaxIdleConns(5)

	if err := db.Ping(); err != nil {
		log.Printf("Warning: failed to ping database for server %s: %v", serverID, err)
		db.Close()
		return nil, nil
	}

	sdb := &ServerDB{
		ID:   serverID,
		Name: serverName,
		DB:   db,
	}
	serverDBs[serverID] = sdb

	log.Printf("Database connected successfully for server: %s (%s)", serverName, serverID)
	return sdb, nil
}

// GetServerDB returns the database connection for a specific server
func GetServerDB(serverID string) (*ServerDB, error) {
	mu.RLock()
	defer mu.RUnlock()

	sdb, exists := serverDBs[serverID]
	if !exists {
		return nil, fmt.Errorf("server %s not found", serverID)
	}
	if sdb == nil || sdb.DB == nil {
		return nil, fmt.Errorf("server %s database not available", serverID)
	}
	return sdb, nil
}

// GetDefaultServerDB returns the default server database connection
func GetDefaultServerDB() *ServerDB {
	mu.RLock()
	defer mu.RUnlock()

	if len(serverDBs) == 0 {
		return nil
	}

	// Return the first available server
	for _, sdb := range serverDBs {
		if sdb != nil && sdb.DB != nil {
			return sdb
		}
	}
	return nil
}

// GetWebDB returns the web database connection for a server
func GetWebDB(serverID string) (*ServerDB, error) {
	mu.RLock()
	defer mu.RUnlock()

	cfg, exists := serverConfigs[serverID]
	if !exists {
		return nil, fmt.Errorf("server %s config not found", serverID)
	}

	webDBName := cfg.Databases["web"]
	if webDBName == "" {
		return nil, fmt.Errorf("web database not configured for server %s", serverID)
	}

	// Create a new connection to web database
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%d)/%s?charset=utf8&parseTime=True&loc=Local",
		cfg.DBUser, cfg.DBPassword, cfg.DBHost, cfg.DBPort, webDBName)

	db, err := sql.Open("mysql", dsn)
	if err != nil {
		return nil, fmt.Errorf("open web db: %w", err)
	}
	db.SetMaxOpenConns(5)
	db.SetMaxIdleConns(2)

	if err := db.Ping(); err != nil {
		db.Close()
		return nil, fmt.Errorf("ping web db: %w", err)
	}

	return &ServerDB{ID: serverID, Name: cfg.Name + "_web", DB: db}, nil
}

// ListServers returns all connected servers
func ListServers() []map[string]interface{} {
	mu.RLock()
	defer mu.RUnlock()

	var servers []map[string]interface{}
	for id, cfg := range serverConfigs {
		entry := map[string]interface{}{
			"id":          id,
			"name":        cfg.Name,
			"description": cfg.Description,
			"connected":   false,
		}
		if sdb, ok := serverDBs[id]; ok && sdb != nil && sdb.DB != nil {
			entry["connected"] = true
		}
		servers = append(servers, entry)
	}
	return servers
}

func Close() {
	if DB != nil {
		DB.Close()
	}

	mu.Lock()
	defer mu.Unlock()
	for _, sdb := range serverDBs {
		if sdb.DB != nil {
			sdb.DB.Close()
		}
	}
}
