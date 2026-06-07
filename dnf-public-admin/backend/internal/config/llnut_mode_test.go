package config

import "testing"

func TestLlnutModeDefaultsToDemo(t *testing.T) {
    t.Setenv("LLNUT_MODE", "")
    if LlnutModeFromEnv() != "demo" {
        t.Fatalf("expected demo mode")
    }
}

func TestLlnutModeAllowsLiveReadonly(t *testing.T) {
    t.Setenv("LLNUT_MODE", "live-readonly")
    if LlnutModeFromEnv() != "live-readonly" {
        t.Fatalf("expected live-readonly")
    }
}

func TestLlnutModeRejectsWriteMode(t *testing.T) {
    t.Setenv("LLNUT_MODE", "write")
    if LlnutModeFromEnv() != "demo" {
        t.Fatalf("unsafe mode should fall back to demo")
    }
}
