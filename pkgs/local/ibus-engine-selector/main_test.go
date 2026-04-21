package main

import (
	"strings"
	"testing"
)

func TestParseConfig(t *testing.T) {
	input := `
engines {
  name : "mozc-jp-ansi"
  longname : "ANSI"
}
engines {
  name : "mozc-jp-jis"
  longname : "JIS"
}
# Below engines are defined by default
engines {
  name : "mozc-jp"
  longname : "Mozc"
}
`
	engines, err := parseConfig(strings.NewReader(input))
	if err != nil {
		t.Fatalf("parseConfig failed: %v", err)
	}

	// Should extract ALL engines now
	if len(engines) != 3 {
		t.Errorf("expected 3 engines, got %d", len(engines))
	}

	expected := []struct {
		name     string
		longname string
	}{
		{"mozc-jp-ansi", "ANSI"},
		{"mozc-jp-jis", "JIS"},
		{"mozc-jp", "Mozc"},
	}

	for i, exp := range expected {
		if engines[i].name != exp.name || engines[i].longname != exp.longname {
			t.Errorf("engine %d: expected %+v, got %+v", i, exp, engines[i])
		}
	}
}
