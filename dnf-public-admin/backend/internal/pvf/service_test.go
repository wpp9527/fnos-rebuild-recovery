package pvf

import "testing"

func TestSearchFindsDemoItemByName(t *testing.T) {
    svc := NewService()
    items := svc.Search("礼盒")
    if len(items) == 0 {
        t.Fatalf("expected demo PVF item")
    }
}

func TestAddToGrantPlanIsDryRun(t *testing.T) {
    svc := NewService()
    plan, err := svc.PlanGrant("1001", "char-1", 1)
    if err != nil {
        t.Fatalf("plan grant: %v", err)
    }
    if plan.Mode != "dry-run" {
        t.Fatalf("expected dry-run plan, got %#v", plan)
    }
}
