package pvf

import (
    "fmt"
    "strings"
)

type Item struct {
    ID       string `json:"id"`
    Name     string `json:"name"`
    Category string `json:"category"`
}

type GrantPlan struct {
    Mode        string `json:"mode"`
    ItemID      string `json:"item_id"`
    CharacterID string `json:"character_id"`
    Quantity    int    `json:"quantity"`
    Message     string `json:"message"`
}

type Service struct {
    items []Item
}

func NewService() Service {
    return Service{items: []Item{
        {ID: "1001", Name: "五月签到礼盒", Category: "event-box"},
        {ID: "1002", Name: "周末活动药剂", Category: "consumable"},
    }}
}

func (s Service) Search(query string) []Item {
    query = strings.TrimSpace(query)
    if query == "" {
        return s.items
    }
    var result []Item
    for _, item := range s.items {
        if strings.Contains(item.ID, query) || strings.Contains(item.Name, query) || strings.Contains(item.Category, query) {
            result = append(result, item)
        }
    }
    return result
}

func (s Service) PlanGrant(itemID, characterID string, quantity int) (GrantPlan, error) {
    if quantity <= 0 {
        return GrantPlan{}, fmt.Errorf("quantity must be positive")
    }
    found := false
    for _, item := range s.items {
        if item.ID == itemID {
            found = true
            break
        }
    }
    if !found {
        return GrantPlan{}, fmt.Errorf("pvf item %q not found", itemID)
    }
    if strings.TrimSpace(characterID) == "" {
        return GrantPlan{}, fmt.Errorf("character id is required")
    }
    return GrantPlan{Mode: "dry-run", ItemID: itemID, CharacterID: characterID, Quantity: quantity, Message: "PVF grant plan only; GM write operation remains disabled"}, nil
}
