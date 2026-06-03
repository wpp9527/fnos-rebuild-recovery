package httpapi

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"dnf-admin/internal/account"
	"dnf-admin/internal/activity"
	"dnf-admin/internal/audit"
	"dnf-admin/internal/auth"
	"dnf-admin/internal/character"
	"dnf-admin/internal/gm"
	"dnf-admin/internal/pvf"
	"dnf-admin/internal/pve"
)

// Router holds all service dependencies
type Router struct {
	authService      *auth.Service
	accountService   *account.Service
	characterService *character.Service
	gmService        *gm.Service
	activityService  *activity.Service
	pvfService       *pvf.Service
	pveService       *pve.Service
	auditService     *audit.Service
}

// NewRouter creates a new router with all dependencies
func NewRouter(
	authSvc *auth.Service,
	accountSvc *account.Service,
	characterSvc *character.Service,
	gmSvc *gm.Service,
	activitySvc *activity.Service,
	pvfSvc *pvf.Service,
	pveSvc *pve.Service,
	auditSvc *audit.Service,
) *Router {
	return &Router{
		authService:      authSvc,
		accountService:   accountSvc,
		characterService: characterSvc,
		gmService:        gmSvc,
		activityService:  activitySvc,
		pvfService:       pvfSvc,
		pveService:       pveSvc,
		auditService:     auditSvc,
	}
}

// Setup sets up all routes
func (r *Router) Setup() *gin.Engine {
	gin.SetMode(gin.ReleaseMode)
	engine := gin.New()
	engine.Use(gin.Recovery(), gin.Logger())

	// CORS middleware
	engine.Use(func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Content-Type, Authorization")
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}
		c.Next()
	})

	v1 := engine.Group("/api/v1")
	{
		// Auth routes (no auth required)
		auth := v1.Group("/auth")
		{
			auth.POST("/login", r.login)
		}

		// Protected routes
		protected := v1.Group("")
		protected.Use(r.authMiddleware())
		{
			// Auth
			protected.GET("/auth/me", r.me)

			// Accounts
			accounts := protected.Group("/accounts")
			{
				accounts.GET("/search", r.searchAccounts)
				accounts.GET("/:uid", r.getAccount)
				accounts.GET("/:uid/characters", r.getAccountCharacters)
			}

			// Characters
			characters := protected.Group("/characters")
			{
				characters.GET("/:cNo", r.getCharacter)
				characters.GET("/:cNo/items", r.getCharacterItems)
				characters.GET("/online", r.getOnlineCharacters)
			}

			// GM operations
			gm := protected.Group("/gm")
			{
				gm.POST("/mail", r.sendMail)
				gm.POST("/item", r.sendItem)
				gm.POST("/gold", r.sendGold)
				gm.POST("/cera", r.sendCera)
				gm.POST("/character/level", r.setLevel)
				gm.POST("/character/fatigue", r.resetFatigue)
				gm.POST("/account/ban", r.banAccount)
				gm.POST("/account/unban", r.unbanAccount)
			}

			// Activities
			activities := protected.Group("/activities")
			{
				activities.GET("", r.listActivities)
				activities.POST("/:id/start", r.startActivity)
				activities.POST("/:id/stop", r.stopActivity)
				activities.GET("/logs", r.getActivityLogs)
			}

			// PVF
			pvf := protected.Group("/pvf")
			{
				pvf.GET("/items", r.searchPVFItems)
				pvf.GET("/items/:id", r.getPVFItem)
				pvf.GET("/equipments", r.searchPVFEquipments)
				pvf.GET("/skills", r.searchPVFSkills)
				pvf.GET("/stats", r.getPVFStats)
				pvf.POST("/reload", r.reloadPVF)
			}

			// PVE
			pve := protected.Group("/pve")
			{
				pve.GET("/status", r.getPVEStatus)
				pve.POST("/service/:name/start", r.startPVEService)
				pve.POST("/service/:name/stop", r.stopPVEService)
				pve.GET("/files", r.getPVEFiles)
				pve.POST("/exec", r.execPVECommand)
			}

			// Audit logs
			protected.GET("/audit/logs", r.getAuditLogs)
		}
	}

	return engine
}

// authMiddleware validates JWT tokens
func (r *Router) authMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		tokenString := c.GetHeader("Authorization")
		if len(tokenString) > 7 && tokenString[:7] == "Bearer " {
			tokenString = tokenString[7:]
		}

		claims, err := r.authService.ValidateToken(tokenString)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
			c.Abort()
			return
		}

		c.Set("user_id", claims.UserID)
		c.Set("username", claims.Username)
		c.Set("role", claims.Role)
		c.Next()
	}
}

// --- Auth handlers ---

func (r *Router) login(c *gin.Context) {
	var req auth.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	resp, err := r.authService.Login(req.Username, req.Password)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, resp)
}

func (r *Router) me(c *gin.Context) {
	userID, _ := c.Get("user_id")
	username, _ := c.Get("username")
	role, _ := c.Get("role")

	c.JSON(http.StatusOK, gin.H{
		"user_id":  userID,
		"username": username,
		"role":     role,
	})
}

// --- Account handlers ---

func (r *Router) searchAccounts(c *gin.Context) {
	q := c.DefaultQuery("q", "")
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))

	accounts, total, err := r.accountService.Search(q, page, pageSize)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"data":  accounts,
		"total": total,
		"page":  page,
		"size":  pageSize,
	})
}

func (r *Router) getAccount(c *gin.Context) {
	uid, _ := strconv.Atoi(c.Param("uid"))
	account, err := r.accountService.GetByUID(uid)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	if account == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "account not found"})
		return
	}
	c.JSON(http.StatusOK, account)
}

func (r *Router) getAccountCharacters(c *gin.Context) {
	uid, _ := strconv.Atoi(c.Param("uid"))
	characters, err := r.accountService.GetCharacters(uid)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, characters)
}

// --- Character handlers ---

func (r *Router) getCharacter(c *gin.Context) {
	cNo, _ := strconv.Atoi(c.Param("cNo"))
	character, err := r.characterService.GetByCNo(cNo)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	if character == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "character not found"})
		return
	}
	c.JSON(http.StatusOK, character)
}

func (r *Router) getCharacterItems(c *gin.Context) {
	cNo, _ := strconv.Atoi(c.Param("cNo"))
	items, err := r.characterService.GetItems(cNo)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, items)
}

func (r *Router) getOnlineCharacters(c *gin.Context) {
	characters, err := r.characterService.GetOnline()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, characters)
}

// --- GM handlers ---

func (r *Router) sendMail(c *gin.Context) {
	var req gm.MailRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	userID, _ := c.Get("user_id")
	if err := r.gmService.SendMail(userID.(int), &req); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "mail sent"})
}

func (r *Router) sendItem(c *gin.Context) {
	var req struct {
		CharacterName string `json:"character_name" binding:"required"`
		ItemID        int    `json:"item_id" binding:"required"`
		Count         int    `json:"count" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	userID, _ := c.Get("user_id")
	if err := r.gmService.SendItem(userID.(int), req.CharacterName, req.ItemID, req.Count); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "item sent"})
}

func (r *Router) sendGold(c *gin.Context) {
	var req gm.GoldRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	userID, _ := c.Get("user_id")
	if err := r.gmService.SendGold(userID.(int), &req); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "gold added"})
}

func (r *Router) sendCera(c *gin.Context) {
	var req gm.GoldRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	userID, _ := c.Get("user_id")
	if err := r.gmService.SendCera(userID.(int), &req); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "cera added"})
}

func (r *Router) setLevel(c *gin.Context) {
	var req gm.LevelRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	userID, _ := c.Get("user_id")
	if err := r.gmService.SetLevel(userID.(int), &req); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "level set"})
}

func (r *Router) resetFatigue(c *gin.Context) {
	var req struct {
		CharacterName string `json:"character_name" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	userID, _ := c.Get("user_id")
	if err := r.gmService.ResetFatigue(userID.(int), req.CharacterName); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "fatigue reset"})
}

func (r *Router) banAccount(c *gin.Context) {
	var req gm.BanRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	userID, _ := c.Get("user_id")
	if err := r.gmService.BanAccount(userID.(int), &req); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "account banned"})
}

func (r *Router) unbanAccount(c *gin.Context) {
	var req struct {
		UID int `json:"uid" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	userID, _ := c.Get("user_id")
	if err := r.gmService.UnbanAccount(userID.(int), req.UID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "account unbanned"})
}

// --- Activity handlers ---

func (r *Router) listActivities(c *gin.Context) {
	activities, err := r.activityService.List()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, activities)
}

func (r *Router) startActivity(c *gin.Context) {
	id, _ := strconv.Atoi(c.Param("id"))
	userID, _ := c.Get("user_id")
	if err := r.activityService.Start(userID.(int), id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "activity started"})
}

func (r *Router) stopActivity(c *gin.Context) {
	id, _ := strconv.Atoi(c.Param("id"))
	userID, _ := c.Get("user_id")
	if err := r.activityService.Stop(userID.(int), id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "activity stopped"})
}

func (r *Router) getActivityLogs(c *gin.Context) {
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "100"))
	logs, err := r.activityService.GetLogs(limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, logs)
}

// --- PVF handlers ---

func (r *Router) searchPVFItems(c *gin.Context) {
	q := c.DefaultQuery("q", "")
	items, err := r.pvfService.SearchItems(q)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, items)
}

func (r *Router) getPVFItem(c *gin.Context) {
	id, _ := strconv.Atoi(c.Param("id"))
	item, err := r.pvfService.GetItem(id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, item)
}

func (r *Router) searchPVFEquipments(c *gin.Context) {
	q := c.DefaultQuery("q", "")
	equipments, err := r.pvfService.SearchEquipments(q)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, equipments)
}

func (r *Router) searchPVFSkills(c *gin.Context) {
	q := c.DefaultQuery("q", "")
	skills, err := r.pvfService.SearchSkills(q)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, skills)
}

func (r *Router) getPVFStats(c *gin.Context) {
	stats, err := r.pvfService.GetStats()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, stats)
}

func (r *Router) reloadPVF(c *gin.Context) {
	if err := r.pvfService.Reload(); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "pvf reloaded"})
}

// --- PVE handlers ---

func (r *Router) getPVEStatus(c *gin.Context) {
	status, err := r.pveService.GetStatus()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, status)
}

func (r *Router) startPVEService(c *gin.Context) {
	name := c.Param("name")
	userID, _ := c.Get("user_id")
	if err := r.pveService.StartService(userID.(int), name); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "service started"})
}

func (r *Router) stopPVEService(c *gin.Context) {
	name := c.Param("name")
	userID, _ := c.Get("user_id")
	if err := r.pveService.StopService(userID.(int), name); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "service stopped"})
}

func (r *Router) getPVEFiles(c *gin.Context) {
	path := c.DefaultQuery("path", "/")
	files, err := r.pveService.ListFiles(path)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, files)
}

func (r *Router) execPVECommand(c *gin.Context) {
	var req struct {
		Command string `json:"command" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	userID, _ := c.Get("user_id")
	output, err := r.pveService.ExecCommand(userID.(int), req.Command)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"output": output})
}

// --- Audit handlers ---

func (r *Router) getAuditLogs(c *gin.Context) {
	operatorID, _ := strconv.Atoi(c.DefaultQuery("operator_id", "0"))
	action := c.DefaultQuery("action", "")
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "100"))

	logs, err := r.auditService.GetLogs(operatorID, action, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, logs)
}
