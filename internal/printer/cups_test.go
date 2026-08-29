package printer_test

import (
	"bytes"
	"testing"

	"github.com/kachick/dotfiles/internal/printer"
)

func TestGenerateSampleA4PDF(t *testing.T) {
	pdf := printer.GenerateSampleA4PDF()
	if len(pdf) == 0 {
		t.Fatal("generated PDF is empty")
	}

	if !bytes.HasPrefix(pdf, []byte("%PDF-1.4")) {
		t.Errorf("expected PDF header, got %q", string(pdf[:8]))
	}

	if !bytes.Contains(pdf, []byte("%%EOF")) {
		t.Errorf("expected EOF marker in PDF")
	}
}

func TestCountRasterPages_InvalidMagic(t *testing.T) {
	invalid := bytes.NewReader([]byte("INVALID_DATA_STREAM"))
	_, err := printer.CountRasterPages(invalid)
	if err == nil {
		t.Error("expected error for invalid raster magic, got nil")
	}
}
