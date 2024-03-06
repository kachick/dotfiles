package config

import (
	"path"
	"testing"
)

func TestAssets(t *testing.T) {
	// why NOT filepath: https://github.com/golang/go/blob/f048829d706df6c1ca4d6fd22de9bd2609d3ed7c/src/io/fs/fs.go#L49
	_, err := WindowsAssets.ReadFile(path.Join("starship", "starship.toml"))
	if err != nil {
		t.Fatalf("embed file not found: %v", err)
	}
}
