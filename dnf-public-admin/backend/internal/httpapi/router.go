package httpapi

import (
    "encoding/json"
    "net/http"
    "strconv"
    "strings"

    "github.com/wpp9527/dnf-public-admin/backend/internal/account"
    "github.com/wpp9527/dnf-public-admin/backend/internal/activity"
    "github.com/wpp9527/dnf-public-admin/backend/internal/adapter/llnut"
    "github.com/wpp9527/dnf-public-admin/backend/internal/audit"
    "github.com/wpp9527/dnf-public-admin/backend/internal/auth"
    "github.com/wpp9527/dnf-public-admin/backend/internal/character"
    "github.com/wpp9527/dnf-public-admin/backend/internal/pvf"
    "github.com/wpp9527/dnf-public-admin/backend/internal/rbac"
)

type loginRequest struct {
    Username string `json:"username"`
    Password string `json:"password"`
}

func NewRouter(appName string) http.Handler {
    mux := http.NewServeMux()
    authService := auth.NewService()
    activityService := activity.NewService()
    auditRecorder := audit.NewRecorder()
    llnutRepository := llnut.NewRepository(nil, llnut.ModeDemo)
    accountService := account.NewService(llnutRepository)
    characterService := character.NewService(llnutRepository)
    pvfService := pvf.NewService()

    mux.HandleFunc("/api/v1/health", func(w http.ResponseWriter, r *http.Request) {
        writeJSON(w, http.StatusOK, map[string]string{
            "status":  "ok",
            "service": appName,
        })
    })

    mux.HandleFunc("/api/v1/meta/modules", func(w http.ResponseWriter, r *http.Request) {
        writeJSON(w, http.StatusOK, map[string]any{
            "modules": []map[string]string{
                {"key": "auth", "name": "认证与权限", "status": "in-progress"},
                {"key": "account", "name": "账号查询", "status": "in-progress"},
                {"key": "character", "name": "角色查询", "status": "in-progress"},
                {"key": "pvf", "name": "PVF 检索", "status": "planned"},
                {"key": "gm", "name": "GM 操作", "status": "planned"},
                {"key": "activity", "name": "活动管理", "status": "in-progress"},
                {"key": "audit", "name": "审计日志", "status": "in-progress"},
            },
            "permissions": rbac.DefaultPermissions(),
        })
    })

    mux.HandleFunc("/api/v1/meta/audit-actions", func(w http.ResponseWriter, r *http.Request) {
        writeJSON(w, http.StatusOK, map[string]any{
            "actions": audit.DefaultActions(),
        })
    })

    mux.HandleFunc("/api/v1/audit/events", func(w http.ResponseWriter, r *http.Request) {
        writeJSON(w, http.StatusOK, map[string]any{"events": auditRecorder.List()})
    })

    mux.HandleFunc("/api/v1/meta/llnut-baseline", func(w http.ResponseWriter, r *http.Request) {
        writeJSON(w, http.StatusOK, llnut.Baseline())
    })

    mux.HandleFunc("/api/v1/meta/llnut-readonly-plans", func(w http.ResponseWriter, r *http.Request) {
        writeJSON(w, http.StatusOK, map[string]any{"plans": llnut.ReadOnlyPlans()})
    })

    mux.HandleFunc("/api/v1/meta/llnut-schema/validate", func(w http.ResponseWriter, r *http.Request) {
        if r.Method != http.MethodPost {
            writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method not allowed"})
            return
        }
        var req struct {
            Tables map[string][]string `json:"tables"`
        }
        if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
            writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid json body"})
            return
        }
        if err := llnut.ValidateReadOnlySchema(req.Tables); err != nil {
            writeJSON(w, http.StatusUnprocessableEntity, map[string]string{"status": "failed", "error": err.Error()})
            return
        }
        writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
    })

    mux.HandleFunc("/api/v1/accounts", func(w http.ResponseWriter, r *http.Request) {
        limit, offset := parsePagination(r)
        items, err := accountService.ListPage(limit, offset)
        if err != nil {
            writeJSON(w, http.StatusServiceUnavailable, map[string]string{"error": err.Error()})
            return
        }
        writeJSON(w, http.StatusOK, map[string]any{
            "items": items,
            "limit": limit,
            "offset": offset,
        })
    })

    mux.HandleFunc("/api/v1/characters", func(w http.ResponseWriter, r *http.Request) {
        limit, offset := parsePagination(r)
        items, err := characterService.ListPage(limit, offset)
        if err != nil {
            writeJSON(w, http.StatusServiceUnavailable, map[string]string{"error": err.Error()})
            return
        }
        writeJSON(w, http.StatusOK, map[string]any{
            "items": items,
            "limit": limit,
            "offset": offset,
        })
    })

    mux.HandleFunc("/api/v1/pvf/items", func(w http.ResponseWriter, r *http.Request) {
        writeJSON(w, http.StatusOK, map[string]any{"items": pvfService.Search(r.URL.Query().Get("q"))})
    })

    mux.HandleFunc("/api/v1/pvf/grant-plan", func(w http.ResponseWriter, r *http.Request) {
        if r.Method != http.MethodPost {
            writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method not allowed"})
            return
        }
        var req struct {
            ItemID      string `json:"item_id"`
            CharacterID string `json:"character_id"`
            Quantity    int    `json:"quantity"`
        }
        if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
            writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid json body"})
            return
        }
        plan, err := pvfService.PlanGrant(req.ItemID, req.CharacterID, req.Quantity)
        if err != nil {
            writeJSON(w, http.StatusUnprocessableEntity, map[string]string{"error": err.Error()})
            return
        }
        writeJSON(w, http.StatusOK, plan)
    })

    mux.HandleFunc("/api/v1/gm/mail/send", disabledWriteHandler)
    mux.HandleFunc("/api/v1/gm/item/send", disabledWriteHandler)
    mux.HandleFunc("/api/v1/gm/currency/grant", disabledWriteHandler)
    mux.HandleFunc("/api/v1/gm/account/ban", disabledWriteHandler)

    mux.HandleFunc("/api/v1/activities", func(w http.ResponseWriter, r *http.Request) {
        writeJSON(w, http.StatusOK, map[string]any{
            "items": activityService.List(),
        })
    })

    mux.HandleFunc("/api/v1/activities/calendar", func(w http.ResponseWriter, r *http.Request) {
        writeJSON(w, http.StatusOK, map[string]any{
            "days": activityService.Calendar(),
        })
    })

    mux.HandleFunc("/api/v1/activities/native", func(w http.ResponseWriter, r *http.Request) {
        writeJSON(w, http.StatusOK, map[string]any{
            "items": activityService.NativeList(),
        })
    })

    mux.HandleFunc("/api/v1/activities/native/sync", func(w http.ResponseWriter, r *http.Request) {
        if r.Method != http.MethodPost {
            writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method not allowed"})
            return
        }
        writeJSON(w, http.StatusOK, activityService.SyncNative())
    })

    mux.HandleFunc("/api/v1/activities/native/toggle", func(w http.ResponseWriter, r *http.Request) {
        if r.Method != http.MethodPost {
            writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method not allowed"})
            return
        }
        if !hasScopeHeader(r, "activity:write") {
            writeJSON(w, http.StatusForbidden, map[string]string{"error": "missing activity:write scope"})
            return
        }
        var req struct {
            Code    string `json:"code"`
            Enabled bool   `json:"enabled"`
        }
        if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
            writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid json body"})
            return
        }
        result, err := activityService.ToggleNative(req.Code, req.Enabled)
        if err != nil {
            writeJSON(w, http.StatusNotFound, map[string]string{"error": err.Error()})
            return
        }
        auditRecorder.Record(audit.Event{Actor: "system", Action: "activity.native.toggle", Target: req.Code, Result: "dry-run"})
        writeJSON(w, http.StatusOK, result)
    })

    mux.HandleFunc("/api/v1/auth/login", func(w http.ResponseWriter, r *http.Request) {
        if r.Method != http.MethodPost {
            writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method not allowed"})
            return
        }
        var req loginRequest
        if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
            writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid json body"})
            return
        }
        result, err := authService.Login(req.Username, req.Password)
        if err != nil {
            status := http.StatusUnauthorized
            if req.Username == "" || req.Password == "" {
                status = http.StatusBadRequest
            }
            writeJSON(w, status, map[string]string{"error": err.Error()})
            return
        }
        writeJSON(w, http.StatusOK, result)
    })

    mux.HandleFunc("/api/v1/auth/me", func(w http.ResponseWriter, r *http.Request) {
        token := strings.TrimSpace(strings.TrimPrefix(r.Header.Get("Authorization"), "Bearer "))
        user, err := authService.Current(token)
        if err != nil {
            writeJSON(w, http.StatusUnauthorized, map[string]string{"error": err.Error()})
            return
        }
        writeJSON(w, http.StatusOK, map[string]any{"user": user})
    })

    return mux
}

func writeJSON(w http.ResponseWriter, status int, payload any) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(status)
    _ = json.NewEncoder(w).Encode(payload)
}


func disabledWriteHandler(w http.ResponseWriter, r *http.Request) {
    writeJSON(w, http.StatusForbidden, map[string]string{
        "error": "write operations are disabled until RBAC, audit logging and legacy data comparison are verified",
    })
}


func hasScopeHeader(r *http.Request, action string) bool {
    raw := strings.TrimSpace(r.Header.Get("X-Scopes"))
    if raw == "" {
        return true
    }
    scopes := strings.Split(raw, ",")
    for i := range scopes {
        scopes[i] = strings.TrimSpace(scopes[i])
    }
    return rbac.Can(scopes, action)
}


func parsePagination(r *http.Request) (int, int) {
    limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
    offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
    return llnut.NormalizeLimitOffset(limit, offset)
}
