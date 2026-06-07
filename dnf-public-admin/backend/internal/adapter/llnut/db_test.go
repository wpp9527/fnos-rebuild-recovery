package llnut

import "testing"

func TestOpenDBReturnsNilWhenDSNEmpty(t *testing.T) {
    db := OpenDB("")
    if db != nil {
        t.Fatalf("expected nil db without DSN")
    }
}
