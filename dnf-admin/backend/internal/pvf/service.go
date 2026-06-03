package pvf

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
)

// Service handles PVF parsing operations (calls Python service)
type Service struct {
	baseURL    string
	httpClient *http.Client
}

// Item represents a PVF item
type Item struct {
	ID          int    `json:"id"`
	Name        string `json:"name"`
	Description string `json:"description"`
	Type        string `json:"type"`
	Rarity      int    `json:"rarity"`
	Price       int    `json:"price"`
}

// Equipment represents a PVF equipment
type Equipment struct {
	ID          int    `json:"id"`
	Name        string `json:"name"`
	Description string `json:"description"`
	Type        string `json:"type"`
	Level       int    `json:"level"`
	Job         int    `json:"job"`
	Stats       map[string]int `json:"stats"`
}

// Skill represents a PVF skill
type Skill struct {
	ID          int    `json:"id"`
	Name        string `json:"name"`
	Description string `json:"description"`
	Level       int    `json:"level"`
	Job         int    `json:"job"`
}

// Stats represents PVF statistics
type Stats struct {
	TotalItems     int `json:"total_items"`
	TotalEquipments int `json:"total_equipments"`
	TotalSkills    int `json:"total_skills"`
	LastUpdated    string `json:"last_updated"`
}

// NewService creates a new PVF service
func NewService(baseURL string) *Service {
	return &Service{
		baseURL:    baseURL,
		httpClient: &http.Client{Timeout: 30 * time.Second},
	}
}

// SearchItems searches for items in PVF
func (s *Service) SearchItems(query string) ([]Item, error) {
	var items []Item
	err := s.get("/api/items", map[string]string{"q": query}, &items)
	return items, err
}

// GetItem retrieves item details by ID
func (s *Service) GetItem(id int) (*Item, error) {
	var item Item
	err := s.get(fmt.Sprintf("/api/items/%d", id), nil, &item)
	return &item, err
}

// SearchEquipments searches for equipments in PVF
func (s *Service) SearchEquipments(query string) ([]Equipment, error) {
	var equipments []Equipment
	err := s.get("/api/equipments", map[string]string{"q": query}, &equipments)
	return equipments, err
}

// SearchSkills searches for skills in PVF
func (s *Service) SearchSkills(query string) ([]Skill, error) {
	var skills []Skill
	err := s.get("/api/skills", map[string]string{"q": query}, &skills)
	return skills, err
}

// GetStats retrieves PVF statistics
func (s *Service) GetStats() (*Stats, error) {
	var stats Stats
	err := s.get("/api/stats", nil, &stats)
	return &stats, err
}

// Reload triggers a PVF reload
func (s *Service) Reload() error {
	resp, err := s.httpClient.Post(s.baseURL+"/api/reload", "application/json", nil)
	if err != nil {
		return fmt.Errorf("reload request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("reload failed: status %d", resp.StatusCode)
	}
	return nil
}

// get is a helper for GET requests
func (s *Service) get(path string, params map[string]string, result interface{}) error {
	url := s.baseURL + path

	if len(params) > 0 {
		first := true
		for k, v := range params {
			if first {
				url += "?"
				first = false
			} else {
				url += "&"
			}
			url += k + "=" + v
		}
	}

	resp, err := s.httpClient.Get(url)
	if err != nil {
		return fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("request failed: status %d, body: %s", resp.StatusCode, string(body))
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return fmt.Errorf("read body: %w", err)
	}

	return json.Unmarshal(body, result)
}
