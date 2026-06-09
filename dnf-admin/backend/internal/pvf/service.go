package pvf

import (
	"encoding/json"
	"fmt"
	"os"
	"strings"
	"sync"
)

// Item represents a PVF item
type Item struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	Category    string `json:"category"`
	Type        string `json:"type"`
	Level       int    `json:"level"`
	Rarity      string `json:"rarity"`
	Description string `json:"description"`
	Stats       string `json:"stats,omitempty"`
}

// Service provides PVF item operations
type Service struct {
	items    []Item
	filepath string
	mu       sync.RWMutex
}

// NewService creates a new PVF service
func NewService(filepath string) *Service {
	s := &Service{
		filepath: filepath,
	}
	s.LoadItems()
	return s
}

// rawItem is used to unmarshal items where type can be either string or int
type rawItem struct {
	ID          string      `json:"id"`
	Name        string      `json:"name"`
	Category    string      `json:"category"`
	Type        interface{} `json:"type"`
	Level       int         `json:"level"`
	Rarity      string      `json:"rarity"`
	Description string      `json:"description"`
	Stats       string      `json:"stats,omitempty"`
}

// LoadItems loads items from a JSON file
func (s *Service) LoadItems() error {
	s.mu.Lock()
	defer s.mu.Unlock()

	data, err := os.ReadFile(s.filepath)
	if err != nil {
		return fmt.Errorf("read items file: %w", err)
	}

	var rawItems []rawItem
	if err := json.Unmarshal(data, &rawItems); err != nil {
		return fmt.Errorf("parse items file: %w", err)
	}

	items := make([]Item, 0, len(rawItems))
	for _, r := range rawItems {
		var typeStr string
		switch v := r.Type.(type) {
		case string:
			typeStr = v
		case float64:
			typeStr = fmt.Sprintf("%d", int(v))
		default:
			typeStr = fmt.Sprintf("%v", v)
		}
		items = append(items, Item{
			ID:          r.ID,
			Name:        r.Name,
			Category:    r.Category,
			Type:        typeStr,
			Level:       r.Level,
			Rarity:      r.Rarity,
			Description: r.Description,
			Stats:       r.Stats,
		})
	}

	// Add descriptions to items
	for i := range items {
		items[i].Description = generateDescription(items[i])
	}

	s.items = items
	return nil
}

// Reload reloads the PVF data
func (s *Service) Reload() error {
	return s.LoadItems()
}

// generateDescription generates a description for an item based on its properties
func generateDescription(item Item) string {
	var desc string
	
	// Rarity description
	rarityDesc := map[string]string{
		"普通": "普通的物品",
		"稀有": "稀有品质的物品，属性较好",
		"神器": "神器品质的物品，属性优秀",
		"传说": "传说品质的物品，属性极佳",
		"史诗": "史诗品质的物品，属性顶级",
	}
	if rd, ok := rarityDesc[item.Rarity]; ok {
		desc = rd
	} else {
		desc = "游戏物品"
	}
	
	// Category specific description
	switch item.Category {
	case "武器":
		desc += fmt.Sprintf("\n类型: %s", item.Type)
		desc += fmt.Sprintf("\n等级要求: %d", item.Level)
	case "防具":
		desc += fmt.Sprintf("\n部位: %s", item.Type)
		desc += fmt.Sprintf("\n等级要求: %d", item.Level)
	case "首饰":
		desc += fmt.Sprintf("\n部位: %s", item.Type)
		desc += fmt.Sprintf("\n等级要求: %d", item.Level)
	case "消耗品":
		desc += fmt.Sprintf("\n类型: %s", item.Type)
	case "材料":
		desc = "可用于制作或升级的材料"
	case "时装":
		desc = "装扮物品，可改变角色外观"
	case "称号":
		desc = "称号物品，可显示在角色名上方"
	case "宠物":
		desc = "宠物物品，可召唤宠物协助战斗"
	}
	
	return desc
}

// s2tMap maps simplified Chinese characters to traditional for search
var s2tMap = map[rune]rune{
	'剑': '劍', '枪': '槍', '链': '鏈', '铠': '鎧', '锤': '錘',
	'铁': '鐵', '钢': '鋼', '银': '銀', '铜': '銅', '头': '頭',
	'颈': '頸', '脸': '臉', '齿': '齒', '龙': '龍', '凤': '鳳',
	'鹰': '鷹', '兽': '獸', '鸟': '鳥', '鱼': '魚', '风': '風',
	'云': '雲', '电': '電', '圣': '聖', '斗': '鬥', '战': '戰',
	'体': '體', '运': '運', '术': '術', '宝': '寶', '壳': '殼',
	'鳞': '鱗', '丝': '絲', '线': '線', '裤': '褲', '药': '藥',
	'矿': '礦', '书': '書', '图': '圖', '币': '幣', '环': '環',
	'项': '項', '锁': '鎖', '镜': '鏡', '钟': '鐘', '灵': '靈',
}

func toTraditional(s string) string {
	var result []rune
	for _, r := range s {
		if t, ok := s2tMap[r]; ok {
			result = append(result, t)
		} else {
			result = append(result, r)
		}
	}
	return string(result)
}

// SearchItems searches for items by query with optional filters
func (s *Service) SearchItems(query string, category string, rarity string, page, pageSize int) ([]Item, int, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	query = strings.ToLower(query)
	queryTrad := toTraditional(query)
	var filtered []Item

	for _, item := range s.items {
		if category != "" && item.Category != category {
			continue
		}
		if rarity != "" && item.Rarity != rarity {
			continue
		}
		if query != "" {
			nameLower := strings.ToLower(item.Name)
			if !strings.Contains(nameLower, query) &&
			   !strings.Contains(nameLower, queryTrad) &&
			   !strings.Contains(strings.ToLower(item.ID), query) {
				continue
			}
		}
		filtered = append(filtered, item)
	}

	total := len(filtered)

	// Paginate
	start := (page - 1) * pageSize
	if start >= total {
		return nil, total, nil
	}
	end := start + pageSize
	if end > total {
		end = total
	}

	return filtered[start:end], total, nil
}

// GetItem gets an item by ID
func (s *Service) GetItem(id string) (*Item, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	for _, item := range s.items {
		if item.ID == id {
			return &item, nil
		}
	}
	return nil, fmt.Errorf("item not found: %s", id)
}

// SearchEquipments searches for equipment items
func (s *Service) SearchEquipments(query string) ([]Item, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	query = strings.ToLower(query)
	var result []Item

	equipCategories := map[string]bool{
		"武器": true,
		"防具": true,
		"首饰": true,
		"特殊装备": true,
	}

	for _, item := range s.items {
		if !equipCategories[item.Category] {
			continue
		}
		if query == "" || strings.Contains(strings.ToLower(item.Name), query) {
			result = append(result, item)
			if len(result) >= 100 {
				break
			}
		}
	}

	return result, nil
}

// SearchSkills searches for skill items (placeholder)
func (s *Service) SearchSkills(query string) ([]Item, error) {
	// Skills are not in the current item list
	return nil, nil
}

// GetStats returns PVF statistics
func (s *Service) GetStats() (map[string]interface{}, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	categories := make(map[string]int)
	rarities := make(map[string]int)

	for _, item := range s.items {
		categories[item.Category]++
		rarities[item.Rarity]++
	}

	return map[string]interface{}{
		"total_items": len(s.items),
		"categories":  categories,
		"rarities":    rarities,
	}, nil
}
