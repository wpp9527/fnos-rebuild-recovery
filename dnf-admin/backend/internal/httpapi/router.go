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
	"dnf-admin/internal/database"
	"dnf-admin/internal/gm"
	"dnf-admin/internal/guild"
	"dnf-admin/internal/postal"
	"dnf-admin/internal/punish"
	"dnf-admin/internal/pve"
	"dnf-admin/internal/pvf"
	"dnf-admin/internal/skill"
	"dnf-admin/internal/stat"
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
	guildService     *guild.Service
	skillService     *skill.Service
	postalService    *postal.Service
	punishService    *punish.Service
	statService      *stat.Service
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

// getServerID extracts server_id from query parameter or uses default
func (r *Router) getServerID(c *gin.Context) string {
	serverID := c.Query("server_id")
	if serverID == "" {
		sdb := database.GetDefaultServerDB()
		if sdb != nil {
			serverID = sdb.ID
		}
	}
	return serverID
}

// getGuildService returns guild service for server
func (r *Router) getGuildService(serverID string) *guild.Service {
	return guild.NewService(serverID)
}

// getSkillService returns skill service for server
func (r *Router) getSkillService(serverID string) *skill.Service {
	return skill.NewService(serverID)
}

// getPostalService returns postal service for server
func (r *Router) getPostalService(serverID string) *postal.Service {
	return postal.NewService(serverID)
}

// getPunishService returns punish service for server
func (r *Router) getPunishService(serverID string) *punish.Service {
	return punish.NewService(serverID)
}

// getStatService returns stat service for server
func (r *Router) getStatService(serverID string) *stat.Service {
	return stat.NewService(serverID)
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

	// 静态文件服务（前端）
	engine.StaticFile("/", "./frontend/dist/index.html")
	engine.Static("/assets", "./frontend/dist/assets")
	engine.NoRoute(func(c *gin.Context) {
		if len(c.Request.URL.Path) < 4 || c.Request.URL.Path[:4] != "/api" {
			c.File("./frontend/dist/index.html")
		} else {
			c.JSON(http.StatusNotFound, gin.H{"error": "not found"})
		}
	})

	v1 := engine.Group("/api/v1")
	{
		auth := v1.Group("/auth")
		{
			auth.POST("/login", r.login)
		}

		v1.GET("/servers", r.listServers)

		protected := v1.Group("")
		protected.Use(r.authMiddleware())
		{
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
				characters.GET("/search", r.searchCharacters)
				characters.GET("/online", r.getOnlineCharacters)
				characters.GET("/:cNo", r.getCharacter)
				characters.GET("/:cNo/detail", r.getCharacterDetail)
				characters.GET("/:cNo/items", r.getCharacterItems)
				characters.GET("/:cNo/equipment", r.getCharacterEquipment)
				characters.GET("/:cNo/equipment/detail", r.getCharacterEquipmentDetail)
				characters.GET("/:cNo/skills", r.getCharacterSkills)
			}

			// Dashboard
			dashboard := protected.Group("/dashboard")
			{
				dashboard.GET("/stats", r.getDashboardStats)
			}

			// GM operations
			gmGroup := protected.Group("/gm")
			{
				gmGroup.POST("/mail", r.sendMail)
				gmGroup.POST("/item", r.sendItem)
				gmGroup.POST("/gold", r.sendGold)
				gmGroup.POST("/cera", r.sendCera)
				gmGroup.POST("/character/level", r.setLevel)
				gmGroup.POST("/character/fatigue", r.resetFatigue)
				gmGroup.POST("/account/ban", r.banAccount)
				gmGroup.POST("/account/unban", r.unbanAccount)
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
			pvfGroup := protected.Group("/pvf")
			{
				pvfGroup.GET("/items", r.searchPVFItems)
				pvfGroup.GET("/items/:id", r.getPVFItem)
				pvfGroup.GET("/equipments", r.searchPVFEquipments)
				pvfGroup.GET("/skills", r.searchPVFSkills)
				pvfGroup.GET("/stats", r.getPVFStats)
				pvfGroup.POST("/reload", r.reloadPVF)
			}

			// PVE
			pveGroup := protected.Group("/pve")
			{
				pveGroup.GET("/status", r.getPVEStatus)
				pveGroup.POST("/service/:name/start", r.startPVEService)
				pveGroup.POST("/service/:name/stop", r.stopPVEService)
				pveGroup.GET("/files", r.getPVEFiles)
				pveGroup.POST("/exec", r.execPVECommand)
			}

			// Guild
			guildGroup := protected.Group("/guilds")
			{
				guildGroup.GET("", r.listGuilds)
				guildGroup.GET("/:id/members", r.getGuildMembers)
			}

			// Postal (GM Mail)
			postalGroup := protected.Group("/postal")
			{
				postalGroup.POST("", r.sendPostal)
				postalGroup.GET("/history", r.getPostalHistory)
			}

			// Punish
			punishGroup := protected.Group("/punish")
			{
				punishGroup.GET("", r.listPunish)
				punishGroup.POST("", r.addPunish)
				punishGroup.DELETE("/:mId", r.removePunish)
			}

			// Stats
			statsGroup := protected.Group("/stats")
			{
				statsGroup.GET("/online", r.getOnlineStat)
				statsGroup.GET("/pvp", r.getPVPRankings)
				statsGroup.GET("/dungeon", r.getDungeonStats)
			}

			// Skill Info (百科)
			skillInfoGroup := protected.Group("/skill-info")
			{
				skillInfoGroup.GET("", r.listSkillInfo)
			}

			// Audit logs
			protected.GET("/audit/logs", r.getAuditLogs)

			// 兼容旧接口
			charac := protected.Group("/charac")
			{
				charac.GET("", r.listCharactersCompat)
				charac.PUT("", r.updateCharacterCompat)
			}
			account := protected.Group("/account")
			{
				account.GET("", r.listAccountsCompat)
				account.GET("/:uid", r.getAccountCompat)
			}
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

// --- Auth ---
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
	c.JSON(http.StatusOK, gin.H{"user_id": userID, "username": username, "role": role})
}

// --- Servers ---
func (r *Router) listServers(c *gin.Context) {
	c.JSON(http.StatusOK, database.ListServers())
}

// --- Accounts ---
func (r *Router) searchAccounts(c *gin.Context) {
	serverID := r.getServerID(c)
	q := c.DefaultQuery("q", "")
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))
	accounts, total, err := r.accountService.Search(serverID, q, page, pageSize)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"data": accounts, "total": total, "page": page, "size": pageSize})
}

func (r *Router) getAccount(c *gin.Context) {
	serverID := r.getServerID(c)
	uid, _ := strconv.Atoi(c.Param("uid"))
	account, err := r.accountService.GetByUID(serverID, uid)
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
	serverID := r.getServerID(c)
	uid, _ := strconv.Atoi(c.Param("uid"))
	characters, err := r.accountService.GetCharacters(serverID, uid)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, characters)
}

// --- Characters ---
func (r *Router) getCharacter(c *gin.Context) {
	serverID := r.getServerID(c)
	cNo, _ := strconv.Atoi(c.Param("cNo"))
	character, err := r.characterService.GetByCNo(serverID, cNo)
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

func (r *Router) getCharacterDetail(c *gin.Context) {
	serverID := r.getServerID(c)
	cNo, _ := strconv.Atoi(c.Param("cNo"))
	detail, err := r.characterService.GetDetail(serverID, cNo)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	if detail == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "character not found"})
		return
	}
	c.JSON(http.StatusOK, detail)
}

func (r *Router) getCharacterItems(c *gin.Context) {
	serverID := r.getServerID(c)
	cNo, _ := strconv.Atoi(c.Param("cNo"))
	items, err := r.characterService.GetItems(serverID, cNo)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, items)
}

func (r *Router) getCharacterEquipment(c *gin.Context) {
	serverID := r.getServerID(c)
	cNo, _ := strconv.Atoi(c.Param("cNo"))
	equipment, err := r.characterService.GetEquipment(serverID, cNo)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, equipment)
}

func (r *Router) getCharacterEquipmentDetail(c *gin.Context) {
	serverID := r.getServerID(c)
	cNo, _ := strconv.Atoi(c.Param("cNo"))
	equipment, err := r.characterService.GetEquipmentDetail(serverID, cNo)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, equipment)
}

func (r *Router) getCharacterSkills(c *gin.Context) {
	serverID := r.getServerID(c)
	cNo, _ := strconv.Atoi(c.Param("cNo"))
	skills, err := r.getSkillService(serverID).GetSkills(cNo)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, skills)
}

func (r *Router) getOnlineCharacters(c *gin.Context) {
	serverID := r.getServerID(c)
	characters, err := r.characterService.GetOnline(serverID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, characters)
}

func (r *Router) searchCharacters(c *gin.Context) {
	sID := r.getServerID(c)
	q := c.DefaultQuery("q", "")
	account := c.DefaultQuery("account", "")
	name := c.DefaultQuery("name", "")
	job := c.DefaultQuery("job", "")
	minLev := c.DefaultQuery("minLev", "")
	maxLev := c.DefaultQuery("maxLevel", "")
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}
	searchQuery := q
	if name != "" {
		searchQuery = name
	}
	if account != "" {
		searchQuery = account
	}
	characters, total, err := r.characterService.SearchWithFilters(sID, searchQuery, account, job, minLev, maxLev, page, pageSize)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"data": characters, "total": total, "page": page, "size": pageSize})
}

// --- GM ---
func (r *Router) sendMail(c *gin.Context) {
	serverID := r.getServerID(c)
	var req gm.MailRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	userID, _ := c.Get("user_id")
	if err := r.gmService.SendMail(userID.(int), serverID, &req); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "mail sent"})
}

func (r *Router) sendItem(c *gin.Context) {
	serverID := r.getServerID(c)
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
	if err := r.gmService.SendItem(userID.(int), serverID, req.CharacterName, req.ItemID, req.Count); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "item sent"})
}

func (r *Router) sendGold(c *gin.Context) {
	serverID := r.getServerID(c)
	var req gm.GoldRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	userID, _ := c.Get("user_id")
	if err := r.gmService.SendGold(userID.(int), serverID, &req); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "gold added"})
}

func (r *Router) sendCera(c *gin.Context) {
	serverID := r.getServerID(c)
	var req gm.GoldRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	userID, _ := c.Get("user_id")
	if err := r.gmService.SendCera(userID.(int), serverID, &req); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "cera added"})
}

func (r *Router) setLevel(c *gin.Context) {
	serverID := r.getServerID(c)
	var req gm.LevelRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	userID, _ := c.Get("user_id")
	if err := r.gmService.SetLevel(userID.(int), serverID, &req); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "level set"})
}

func (r *Router) resetFatigue(c *gin.Context) {
	serverID := r.getServerID(c)
	var req struct {
		CharacterName string `json:"character_name" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	userID, _ := c.Get("user_id")
	if err := r.gmService.ResetFatigue(userID.(int), serverID, req.CharacterName); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "fatigue reset"})
}

func (r *Router) banAccount(c *gin.Context) {
	serverID := r.getServerID(c)
	var req gm.BanRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	userID, _ := c.Get("user_id")
	if err := r.gmService.BanAccount(userID.(int), serverID, &req); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "account banned"})
}

func (r *Router) unbanAccount(c *gin.Context) {
	serverID := r.getServerID(c)
	var req struct {
		UID int `json:"uid" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	userID, _ := c.Get("user_id")
	if err := r.gmService.UnbanAccount(userID.(int), serverID, req.UID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "account unbanned"})
}

// --- Activities ---
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

// --- PVF ---
func (r *Router) searchPVFItems(c *gin.Context) {
	q := c.DefaultQuery("q", "")
	category := c.DefaultQuery("category", "")
	rarity := c.DefaultQuery("rarity", "")
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}
	items, total, err := r.pvfService.SearchItems(q, category, rarity, page, pageSize)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"data": items, "total": total, "page": page, "size": pageSize})
}

func (r *Router) getPVFItem(c *gin.Context) {
	id := c.Param("id")
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

// --- PVE ---
func (r *Router) getPVEStatus(c *gin.Context) {
	serverID := r.getServerID(c)
	status, err := r.pveService.GetStatus(serverID)
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

// --- Guild ---
func (r *Router) listGuilds(c *gin.Context) {
	serverID := r.getServerID(c)
	guilds, err := r.getGuildService(serverID).ListGuilds()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, guilds)
}

func (r *Router) getGuildMembers(c *gin.Context) {
	serverID := r.getServerID(c)
	guildID, _ := strconv.Atoi(c.Param("id"))
	members, err := r.getGuildService(serverID).GetGuildMembers(guildID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, members)
}

// --- Postal ---
func (r *Router) sendPostal(c *gin.Context) {
	serverID := r.getServerID(c)
	var req postal.PostalRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := r.getPostalService(serverID).SendPostal(req); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "postal sent"})
}

func (r *Router) getPostalHistory(c *gin.Context) {
	serverID := r.getServerID(c)
	characNo, _ := strconv.Atoi(c.DefaultQuery("charac_no", "0"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "50"))
	history, err := r.getPostalService(serverID).GetPostalHistory(characNo, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, history)
}

// --- Punish ---
func (r *Router) listPunish(c *gin.Context) {
	serverID := r.getServerID(c)
	list, err := r.getPunishService(serverID).ListPunish()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, list)
}

func (r *Router) addPunish(c *gin.Context) {
	serverID := r.getServerID(c)
	var req punish.PunishRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := r.getPunishService(serverID).AddPunish(req); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "punish added"})
}

func (r *Router) removePunish(c *gin.Context) {
	serverID := r.getServerID(c)
	mID, _ := strconv.Atoi(c.Param("mId"))
	if err := r.getPunishService(serverID).RemovePunish(mID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "punish removed"})
}

// --- Stats ---
func (r *Router) getOnlineStat(c *gin.Context) {
	serverID := r.getServerID(c)
	stat, err := r.getStatService(serverID).GetOnlineStat()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, stat)
}

func (r *Router) getPVPRankings(c *gin.Context) {
	serverID := r.getServerID(c)
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "50"))
	ranks, err := r.getStatService(serverID).GetPVPRankings(limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, ranks)
}

func (r *Router) getDungeonStats(c *gin.Context) {
	serverID := r.getServerID(c)
	stats, err := r.getStatService(serverID).GetDungeonStats()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, stats)
}

// --- Skill Info ---
func (r *Router) listSkillInfo(c *gin.Context) {
	serverID := r.getServerID(c)
	jobIndex, _ := strconv.Atoi(c.DefaultQuery("job", "-1"))
	infos, err := r.getSkillService(serverID).ListSkillInfo(jobIndex)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, infos)
}

// --- Audit ---
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

// --- Dashboard ---
func (r *Router) getDashboardStats(c *gin.Context) {
	serverID := r.getServerID(c)
	sdb, err := database.GetServerDB(serverID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	var totalAccounts, totalCharacters, totalGuilds, totalGold int
	sdb.DB.QueryRow("SELECT COUNT(*) FROM d_taiwan.accounts").Scan(&totalAccounts)
	sdb.DB.QueryRow("SELECT COUNT(*) FROM taiwan_cain.charac_info").Scan(&totalCharacters)
	sdb.DB.QueryRow("SELECT COUNT(*) FROM d_guild.guild_info").Scan(&totalGuilds)
	sdb.DB.QueryRow("SELECT COALESCE(SUM(cera), 0) FROM taiwan_billing.cash_cera").Scan(&totalGold)
	c.JSON(http.StatusOK, gin.H{
		"total_accounts": totalAccounts, "total_characters": totalCharacters,
		"total_guilds": totalGuilds, "total_gold": totalGold,
	})
}

// --- Compat ---
func (r *Router) listCharactersCompat(c *gin.Context) {
	serverID := r.getServerID(c)
	q := c.DefaultQuery("name", "")
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("pageSize", "10"))
	characters, total, err := r.characterService.Search(serverID, q, page, pageSize)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"data": characters, "total": total, "page": page, "pageSize": pageSize, "list": characters})
}

func (r *Router) updateCharacterCompat(c *gin.Context) {
	sID := r.getServerID(c)
	var req struct {
		CharacNo int `json:"c_no"`
		Lev      int `json:"c_level"`
		MaxHp    int `json:"max_hp"`
		MaxMp    int `json:"max_mp"`
		Fatigue  int `json:"c_fatigue"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	sdb, err := database.GetServerDB(sID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	_, err = sdb.DB.Exec("UPDATE taiwan_cain.charac_info SET lev=?, maxHP=?, maxMP=?, fatigue=? WHERE charac_no=?",
		req.Lev, req.MaxHp, req.MaxMp, req.Fatigue, req.CharacNo)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "updated"})
}

func (r *Router) listAccountsCompat(c *gin.Context) {
	serverID := r.getServerID(c)
	q := c.DefaultQuery("account", "")
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("pageSize", "10"))
	accounts, total, err := r.accountService.Search(serverID, q, page, pageSize)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"data": accounts, "total": total, "page": page, "pageSize": pageSize, "list": accounts})
}

func (r *Router) getAccountCompat(c *gin.Context) {
	serverID := r.getServerID(c)
	uid, _ := strconv.Atoi(c.Param("uid"))
	account, err := r.accountService.GetByUID(serverID, uid)
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
