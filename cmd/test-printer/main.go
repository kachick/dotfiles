package main

import (
	"bytes"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"

	"github.com/kachick/dotfiles/internal/printer"
)

func main() {
	var (
		ppdPath  string
		pdfPath  string
		pageSize string
	)

	flag.StringVar(&ppdPath, "ppd", "", "Path to PPD file (optional; uses generic driverless raster PPD if omitted)")
	flag.StringVar(&pdfPath, "input", "", "Path to input PDF file (optional; generates 1-page sample A4 PDF if omitted)")
	flag.StringVar(&pageSize, "media", "A4", "Media page size (e.g. A4, Letter)")
	flag.Parse()

	cupsfilterPath, err := exec.LookPath("cupsfilter")
	if err != nil {
		fmt.Fprintf(os.Stderr, "cupsfilter not found in PATH. Skipping CUPS raster test.\n")
		os.Exit(0)
	}

	tmpDir, err := os.MkdirTemp("", "cups-test-*")
	if err != nil {
		fmt.Fprintf(os.Stderr, "failed to create temp dir: %v\n", err)
		os.Exit(1)
	}
	defer os.RemoveAll(tmpDir)

	targetPDF := pdfPath
	if targetPDF == "" {
		samplePDF := filepath.Join(tmpDir, "sample.pdf")
		if err := os.WriteFile(samplePDF, printer.GenerateSampleA4PDF(), 0600); err != nil {
			fmt.Fprintf(os.Stderr, "failed to write sample PDF: %v\n", err)
			os.Exit(1)
		}
		targetPDF = samplePDF
	}

	targetPPD := ppdPath
	if targetPPD == "" {
		genericPPD := filepath.Join(tmpDir, "generic.ppd")
		if err := os.WriteFile(genericPPD, printer.GenerateGenericRasterPPD(), 0600); err != nil {
			fmt.Fprintf(os.Stderr, "failed to write generic PPD: %v\n", err)
			os.Exit(1)
		}
		targetPPD = genericPPD
	}

	args := []string{
		"-p", targetPPD,
		"-m", "application/vnd.cups-raster",
		"-o", fmt.Sprintf("media=%s", pageSize),
		targetPDF,
	}

	cmd := exec.Command(cupsfilterPath, args...)
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	if err := cmd.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "cupsfilter failed: %v\nStderr:\n%s\n", err, stderr.String())
		os.Exit(1)
	}

	pageCount, err := printer.CountRasterPages(&stdout)
	if err != nil {
		fmt.Fprintf(os.Stderr, "failed to parse CUPS raster output: %v\n", err)
		os.Exit(1)
	}

	expectedPages := 1
	if pdfPath == "" {
		if pageCount != expectedPages {
			fmt.Fprintf(os.Stderr, "Error: Expected %d page(s) in CUPS raster, but got %d\n", expectedPages, pageCount)
			os.Exit(1)
		}
	}

	fmt.Printf("✅ CUPS raster pipeline test passed (page count: %d)\n", pageCount)
}
