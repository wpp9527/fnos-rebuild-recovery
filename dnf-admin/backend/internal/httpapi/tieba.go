package httpapi

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"dnf-admin/internal/tieba"
)

// TiebaHandler handles Tieba API requests
type TiebaHandler struct {
	service *tieba.Service
}

// NewTiebaHandler creates a new Tieba handler
func NewTiebaHandler(service *tieba.Service) *TiebaHandler {
	return &TiebaHandler{service: service}
}

// Search searches Tieba posts
func (h *TiebaHandler) Search(c *gin.Context) {
	query := c.DefaultQuery("q", "")
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	size, _ := strconv.Atoi(c.DefaultQuery("size", "20"))
	
	if query == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "query parameter 'q' is required"})
		return
	}
	
	result, err := h.service.Search(query, page, size)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	
	c.JSON(http.StatusOK, result)
}

// GetHotPosts gets hot posts from a specific Tieba
func (h *TiebaHandler) GetHotPosts(c *gin.Context) {
	tiebaName := c.Param("name")
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	
	if tiebaName == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "tieba name is required"})
		return
	}
	
	posts, err := h.service.GetHotPosts(tiebaName, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	
	c.JSON(http.StatusOK, gin.H{"posts": posts})
}

// GetPost gets a single post by ID
func (h *TiebaHandler) GetPost(c *gin.Context) {
	id, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid post id"})
		return
	}
	
	post, err := h.service.GetPost(id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	
	if post == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "post not found"})
		return
	}
	
	c.JSON(http.StatusOK, post)
}

// ScrapeTieba scrapes posts from a Tieba forum
func (h *TiebaHandler) ScrapeTieba(c *gin.Context) {
	tiebaName := c.Param("name")
	pages, _ := strconv.Atoi(c.DefaultQuery("pages", "1"))
	
	if tiebaName == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "tieba name is required"})
		return
	}
	
	posts, err := h.service.ScrapeTieba(tiebaName, pages)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	
	// Save to database
	if err := h.service.SavePosts(posts); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	
	c.JSON(http.StatusOK, gin.H{
		"message": "scraping completed",
		"posts":   len(posts),
	})
}

// GetStats gets statistics about Tieba posts
func (h *TiebaHandler) GetStats(c *gin.Context) {
	stats, err := h.service.GetStats()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	
	c.JSON(http.StatusOK, stats)
}

// ExportToJSON exports posts to JSON
func (h *TiebaHandler) ExportToJSON(c *gin.Context) {
	query := c.DefaultQuery("q", "")
	
	if query == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "query parameter 'q' is required"})
		return
	}
	
	data, err := h.service.ExportToJSON(query)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	
	c.Header("Content-Type", "application/json")
	c.Header("Content-Disposition", "attachment; filename=tieba_export.json")
	c.Data(http.StatusOK, "application/json", data)
}
