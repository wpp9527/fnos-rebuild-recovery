package audit

import "testing"

func TestRecorderStoresEventsInOrder(t *testing.T) {
    recorder := NewRecorder()
    first := recorder.Record(Event{Actor: "admin", Action: "auth.login", Target: "admin", Result: "success"})
    second := recorder.Record(Event{Actor: "admin", Action: "pvf.grant.plan", Target: "char-1", Result: "dry-run"})

    events := recorder.List()
    if len(events) != 2 {
        t.Fatalf("expected 2 events, got %d", len(events))
    }
    if events[0].ID != first.ID || events[1].ID != second.ID {
        t.Fatalf("events not stored in order: %#v", events)
    }
}

func TestRecorderRejectsMissingAction(t *testing.T) {
    recorder := NewRecorder()
    event := recorder.Record(Event{Actor: "admin"})
    if event.Result != "rejected" {
        t.Fatalf("expected rejected event, got %#v", event)
    }
}
