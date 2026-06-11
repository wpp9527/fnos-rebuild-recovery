package tieba

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"net/url"
	"time"
	
	_ "github.com/go-sql-driver/mysql"
)

// Post represents a Tieba post
type Post struct {
	ID          int64     `json:"id"`
	TiebaName   string    `json:"tieba_name"`
	Title       string    `json:"title"`
	Content     string    `json:"content"`
	Author      string    `json:"author"`
	AuthorLevel int       `json:"author_level"`
	ReplyCount  int       `json:"reply_count"`
	ViewCount   int       `json:"view_count"`
	PostTime    time.Time `json:"post_time"`
	LastReply   time.Time `json:"last_reply"`
	URL         string    `json:"url"`
	CreatedAt   time.Time `json:"created_at"`
}

// SearchResult represents search results
type SearchResult struct {
	Posts []Post `json:"posts"`
	Total int    `json:"total"`
	Page  int    `json:"page"`
	Size  int    `json:"size"`
}

// Service provides Tieba operations
type Service struct {
	db        *sql.DB
	client    *http.Client
	userAgent string
	proxyURL  string
}

// NewService creates a new Tieba service
func NewService(db *sql.DB) *Service {
	s := &Service{
		client: &http.Client{
			Timeout: 30 * time.Second,
		},
		userAgent: "bdtb for Android 12.57.4.0",
		proxyURL:  "http://192.168.1.213:7890", // Default proxy
	}

	// If db is provided, use it; otherwise try to connect to default database
	if db != nil {
		s.db = db
	} else {
		// Try to connect to the Tieba database (MySQL in Docker container)
		dsn := "root:88888888@tcp(172.18.0.2:3306)/dnf_tieba?charset=utf8mb4&parseTime=True&loc=Local"
		var err error
		s.db, err = sql.Open("mysql", dsn)
		if err != nil {
			log.Printf("Warning: failed to open Tieba database: %v", err)
		} else {
			s.db.SetMaxOpenConns(5)
			s.db.SetMaxIdleConns(2)
			if err := s.db.Ping(); err != nil {
				log.Printf("Warning: failed to ping Tieba database: %v", err)
				s.db = nil
			}
		}
	}

	return s
}

// NewServiceWithDB creates a new Tieba service with database connection
func NewServiceWithDB() (*Service, error) {
	s := &Service{
		client: &http.Client{
			Timeout: 30 * time.Second,
		},
		userAgent: "bdtb for Android 12.57.4.0",
		proxyURL:  "http://192.168.1.213:7890", // Default proxy
	}

	// Connect to the Tieba database (MySQL in Docker container)
	dsn := "root:88888888@tcp(172.18.0.2:3306)/dnf_tieba?charset=utf8mb4&parseTime=True&loc=Local"
	var err error
	s.db, err = sql.Open("mysql", dsn)
	if err != nil {
		return nil, fmt.Errorf("failed to open Tieba database: %v", err)
	}

	s.db.SetMaxOpenConns(5)
	s.db.SetMaxIdleConns(2)
	if err := s.db.Ping(); err != nil {
		s.db.Close()
		return nil, fmt.Errorf("failed to ping Tieba database: %v", err)
	}

	// Initialize database tables
	if err := s.InitDB(); err != nil {
		s.db.Close()
		return nil, fmt.Errorf("failed to initialize Tieba database: %v", err)
	}

	return s, nil
}

// InitDB initializes the database tables
func (s *Service) InitDB() error {
	query := `
	CREATE TABLE IF NOT EXISTS tieba_posts (
		id BIGINT PRIMARY KEY AUTO_INCREMENT,
		tieba_name VARCHAR(100) NOT NULL,
		title VARCHAR(500) NOT NULL,
		content TEXT,
		author VARCHAR(100),
		author_level INT DEFAULT 0,
		reply_count INT DEFAULT 0,
		view_count INT DEFAULT 0,
		post_time DATETIME,
		last_reply DATETIME,
		url VARCHAR(500),
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		FULLTEXT INDEX idx_title_content (title, content),
		INDEX idx_tieba_name (tieba_name),
		INDEX idx_post_time (post_time),
		INDEX idx_author (author)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
	`
	_, err := s.db.Exec(query)
	return err
}

// ScrapeTieba scrapes posts from a Tieba forum
func (s *Service) ScrapeTieba(tiebaName string, pages int) ([]Post, error) {
	var allPosts []Post

	// Create HTTP client with proxy support
	client := &http.Client{
		Timeout: 30 * time.Second,
	}

	// Configure proxy if available
	if s.proxyURL != "" {
		proxyURL, err := url.Parse(s.proxyURL)
		if err == nil {
			client.Transport = &http.Transport{
				Proxy: http.ProxyURL(proxyURL),
			}
		}
	}

	for page := 0; page < pages; page++ {
		// Use mobile API which is more reliable
		apiURL := fmt.Sprintf("https://tieba.baidu.com/mo/q/m?kw=%s&pn=%d&rn=50", tiebaName, page*50)

		req, err := http.NewRequest("GET", apiURL, nil)
		if err != nil {
			return nil, err
		}
		req.Header.Set("User-Agent", s.userAgent)
		req.Header.Set("Accept", "application/json")
		req.Header.Set("Accept-Language", "zh-CN,zh;q=0.9,en;q=0.8")

		resp, err := client.Do(req)
		if err != nil {
			return nil, err
		}
		defer resp.Body.Close()

		if resp.StatusCode != 200 {
			return nil, fmt.Errorf("HTTP %d", resp.StatusCode)
		}

		body, err := ioutil.ReadAll(resp.Body)
		if err != nil {
			return nil, err
		}

		// Parse JSON response from mobile API
		posts, err := s.parseMobileAPIResponse(body, tiebaName)
		if err != nil {
			return nil, err
		}
		allPosts = append(allPosts, posts...)

		// Be polite and don't hammer the server
		if page < pages-1 {
			time.Sleep(2 * time.Second)
		}
	}

	return allPosts, nil
}

// parseMobileAPIResponse parses the mobile API JSON response
func (s *Service) parseMobileAPIResponse(data []byte, tiebaName string) ([]Post, error) {
	var posts []Post

	// Parse JSON response
	var response struct {
		Data struct {
			ThreadList []struct {
				ID        int64  `json:"id"`
				Title     string `json:"title"`
				Content   string `json:"content"`
				Author    struct {
					Name string `json:"name"`
				} `json:"author"`
				ReplyNum  int    `json:"reply_num"`
				ViewNum   int    `json:"view_num"`
				CreatedAt int64  `json:"create_time"`
				LastTime  string `json:"last_time"`
			} `json:"thread_list"`
		} `json:"data"`
	}

	if err := json.Unmarshal(data, &response); err != nil {
		// Try alternative parsing if the structure is different
		var altResponse struct {
			Data []struct {
				ID        int64  `json:"id"`
				Title     string `json:"title"`
				Author    struct {
					Name string `json:"name"`
				} `json:"author"`
				ReplyNum  int    `json:"reply_num"`
				ViewNum   int    `json:"view_num"`
				CreatedAt int64  `json:"create_time"`
			} `json:"data"`
		}

		if err := json.Unmarshal(data, &altResponse); err != nil {
			return nil, fmt.Errorf("failed to parse mobile API response: %v", err)
		}

		for _, item := range altResponse.Data {
			post := Post{
				ID:          item.ID,
				TiebaName:   tiebaName,
				Title:       item.Title,
				Content:     "",
				Author:      item.Author.Name,
				ReplyCount:  item.ReplyNum,
				ViewCount:   item.ViewNum,
				PostTime:    time.Unix(item.CreatedAt, 0),
				URL:         fmt.Sprintf("https://tieba.baidu.com/p/%d", item.ID),
			}
			posts = append(posts, post)
		}

		return posts, nil
	}

	for _, item := range response.Data.ThreadList {
		post := Post{
			ID:          item.ID,
			TiebaName:   tiebaName,
			Title:       item.Title,
			Content:     item.Content,
			Author:      item.Author.Name,
			ReplyCount:  item.ReplyNum,
			ViewCount:   item.ViewNum,
			PostTime:    time.Unix(item.CreatedAt, 0),
			URL:         fmt.Sprintf("https://tieba.baidu.com/p/%d", item.ID),
		}
		posts = append(posts, post)
	}

	return posts, nil
}

// SavePosts saves posts to database
func (s *Service) SavePosts(posts []Post) error {
	if s.db == nil {
		return fmt.Errorf("database not initialized")
	}

	stmt, err := s.db.Prepare(`
		INSERT INTO tieba_posts (tieba_name, title, content, author, author_level, reply_count, view_count, post_time, last_reply, url)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		ON DUPLICATE KEY UPDATE
			content = VALUES(content),
			reply_count = VALUES(reply_count),
			view_count = VALUES(view_count),
			last_reply = VALUES(last_reply)
	`)
	if err != nil {
		return err
	}
	defer stmt.Close()

	for _, post := range posts {
		_, err := stmt.Exec(
			post.TiebaName,
			post.Title,
			post.Content,
			post.Author,
			post.AuthorLevel,
			post.ReplyCount,
			post.ViewCount,
			post.PostTime,
			post.LastReply,
			post.URL,
		)
		if err != nil {
			log.Printf("Warning: failed to save post %d: %v", post.ID, err)
		}
	}

	return nil
}

// Search searches for posts
func (s *Service) Search(query string, page, size int) (*SearchResult, error) {
	if s.db == nil {
		return &SearchResult{Posts: []Post{}, Total: 0, Page: page, Size: size}, nil
	}

	// Calculate offset
	offset := (page - 1) * size

	// Search with full-text search
	rows, err := s.db.Query(`
		SELECT id, tieba_name, title, content, author, author_level, reply_count, view_count, post_time, last_reply, url
		FROM tieba_posts
		WHERE MATCH(title, content) AGAINST(? IN BOOLEAN MODE)
		ORDER BY post_time DESC
		LIMIT ? OFFSET ?
	`, query, size, offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var posts []Post
	for rows.Next() {
		var post Post
		err := rows.Scan(
			&post.ID,
			&post.TiebaName,
			&post.Title,
			&post.Content,
			&post.Author,
			&post.AuthorLevel,
			&post.ReplyCount,
			&post.ViewCount,
			&post.PostTime,
			&post.LastReply,
			&post.URL,
		)
		if err != nil {
			return nil, err
		}
		posts = append(posts, post)
	}

	// Get total count
	var total int
	err = s.db.QueryRow(`
		SELECT COUNT(*)
		FROM tieba_posts
		WHERE MATCH(title, content) AGAINST(? IN BOOLEAN MODE)
	`, query).Scan(&total)
	if err != nil {
		return nil, err
	}

	return &SearchResult{
		Posts: posts,
		Total: total,
		Page:  page,
		Size:  size,
	}, nil
}

// GetHotPosts gets hot posts from a specific Tieba
func (s *Service) GetHotPosts(tiebaName string, limit int) ([]Post, error) {
	if s.db == nil {
		return []Post{}, nil
	}

	rows, err := s.db.Query(`
		SELECT id, tieba_name, title, content, author, author_level, reply_count, view_count, post_time, last_reply, url
		FROM tieba_posts
		WHERE tieba_name = ?
		ORDER BY reply_count DESC, view_count DESC
		LIMIT ?
	`, tiebaName, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var posts []Post
	for rows.Next() {
		var post Post
		err := rows.Scan(
			&post.ID,
			&post.TiebaName,
			&post.Title,
			&post.Content,
			&post.Author,
			&post.AuthorLevel,
			&post.ReplyCount,
			&post.ViewCount,
			&post.PostTime,
			&post.LastReply,
			&post.URL,
		)
		if err != nil {
			return nil, err
		}
		posts = append(posts, post)
	}

	return posts, nil
}

// GetPost gets a single post by ID
func (s *Service) GetPost(id int64) (*Post, error) {
	if s.db == nil {
		return nil, nil
	}

	var post Post
	err := s.db.QueryRow(`
		SELECT id, tieba_name, title, content, author, author_level, reply_count, view_count, post_time, last_reply, url
		FROM tieba_posts
		WHERE id = ?
	`, id).Scan(
		&post.ID,
		&post.TiebaName,
		&post.Title,
		&post.Content,
		&post.Author,
		&post.AuthorLevel,
		&post.ReplyCount,
		&post.ViewCount,
		&post.PostTime,
		&post.LastReply,
		&post.URL,
	)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}

	return &post, nil
}

// GetStats gets statistics about Tieba posts
func (s *Service) GetStats() (map[string]interface{}, error) {
	if s.db == nil {
		return map[string]interface{}{
			"total_posts":     0,
			"recent_posts_7d": 0,
			"by_tieba":        nil,
		}, nil
	}

	var totalPosts, recentPosts int

	// Get total posts
	err := s.db.QueryRow("SELECT COUNT(*) FROM tieba_posts").Scan(&totalPosts)
	if err != nil {
		return nil, err
	}

	// Get recent posts (last 7 days)
	err = s.db.QueryRow("SELECT COUNT(*) FROM tieba_posts WHERE post_time > DATE_SUB(NOW(), INTERVAL 7 DAY)").Scan(&recentPosts)
	if err != nil {
		return nil, err
	}

	// Get posts by tieba
	rows, err := s.db.Query(`
		SELECT tieba_name, COUNT(*) as count
		FROM tieba_posts
		GROUP BY tieba_name
		ORDER BY count DESC
		LIMIT 10
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var byTieba []map[string]interface{}
	for rows.Next() {
		var name string
		var count int
		if err := rows.Scan(&name, &count); err != nil {
			return nil, err
		}
		byTieba = append(byTieba, map[string]interface{}{
			"name":  name,
			"count": count,
		})
	}

	return map[string]interface{}{
		"total_posts":     totalPosts,
		"recent_posts_7d": recentPosts,
		"by_tieba":        byTieba,
	}, nil
}

// ExportToJSON exports posts to JSON
func (s *Service) ExportToJSON(query string) ([]byte, error) {
	if s.db == nil {
		return []byte("[]"), nil
	}

	rows, err := s.db.Query(`
		SELECT id, tieba_name, title, content, author, author_level, reply_count, view_count, post_time, last_reply, url
		FROM tieba_posts
		WHERE MATCH(title, content) AGAINST(? IN BOOLEAN MODE)
		ORDER BY post_time DESC
		LIMIT 1000
	`, query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var posts []Post
	for rows.Next() {
		var post Post
		err := rows.Scan(
			&post.ID,
			&post.TiebaName,
			&post.Title,
			&post.Content,
			&post.Author,
			&post.AuthorLevel,
			&post.ReplyCount,
			&post.ViewCount,
			&post.PostTime,
			&post.LastReply,
			&post.URL,
		)
		if err != nil {
			return nil, err
		}
		posts = append(posts, post)
	}

	return json.MarshalIndent(posts, "", "  ")
}
