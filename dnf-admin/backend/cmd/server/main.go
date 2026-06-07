package main

import (
	"log"

	"dnf-admin/internal/account"
	"dnf-admin/internal/activity"
	"dnf-admin/internal/audit"
	"dnf-admin/internal/auth"
	"dnf-admin/internal/character"
	"dnf-admin/internal/config"
	"dnf-admin/internal/database"
	"dnf-admin/internal/gm"
	"dnf-admin/internal/httpapi"
	"dnf-admin/internal/pvf"
	"dnf-admin/internal/pve"
)

func main() {
	// Load configuration
	cfg := config.Load()

	// Initialize database (allow failure for graceful startup)
	if err := database.Init(cfg); err != nil {
		log.Printf("Warning: Database initialization failed: %v", err)
		log.Println("Server will start but database operations will fail")
	} else {
		defer database.Close()
	}

	// Initialize services
	authSvc := auth.NewService(cfg.JWTSecret)
	accountSvc := account.NewService()
	characterSvc := character.NewService()
	auditSvc := audit.NewService()
	gmSvc := gm.NewService(auditSvc)
	activitySvc := activity.NewService("local")
	var pvfSvc *pvf.Service
	if cfg.PVFFile != "" {
		pvfSvc = pvf.NewService(cfg.PVFFile)
	} else {
		pvfSvc = pvf.NewService("/opt/dnf-admin/items_10000.json")
	}
	pveSvc := pve.NewService(auditSvc)

	// Setup router
	router := httpapi.NewRouter(
		authSvc, accountSvc, characterSvc, gmSvc,
		activitySvc, pvfSvc, pveSvc, auditSvc,
	)

	engine := router.Setup()

	// Start server
	addr := ":" + cfg.ServerPort
	log.Printf("Starting DNF Admin Pro server on %s", addr)
	if err := engine.Run(addr); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
