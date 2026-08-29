package printer

import (
	"bytes"
	"encoding/binary"
	"errors"
	"fmt"
	"io"
)

// CupsHeader represents cups_page_header2_t (1792 bytes).
type CupsHeader struct {
	MediaClass                  [64]byte
	MediaColor                  [64]byte
	MediaType                   [64]byte
	OutputType                  [64]byte
	AdvanceDistance             uint32
	AdvanceMedia                uint32
	Collate                     uint32
	CutMedia                    uint32
	Duplex                      uint32
	HWResolution                [2]uint32
	ImagingBoundingBox          [4]uint32
	InsertSheet                 uint32
	Jog                         uint32
	LeadingEdge                 uint32
	Margins                     [2]uint32
	ManualFeed                  uint32
	MediaPosition               uint32
	MediaWeight                 uint32
	MirrorPrint                 uint32
	NegativePrint               uint32
	NumCopies                   uint32
	Orientation                 uint32
	OutputFaceUp                uint32
	PageSize                    [2]uint32
	Separations                 uint32
	TraySwitch                  uint32
	Tumble                      uint32
	CupsWidth                   uint32
	CupsHeight                  uint32
	CupsMediaType               uint32
	CupsBitsPerColor            uint32
	CupsBitsPerPixel            uint32
	CupsBytesPerLine            uint32
	CupsColorOrder              uint32
	CupsColorSpace              uint32
	CupsCompression             uint32
	CupsRowCount                uint32
	CupsRowFeed                 uint32
	CupsRowStep                 uint32
	CupsNumColors               uint32
	CupsBorderlessScalingFactor float32
	CupsPageSize                [2]float32
	CupsImagingBBox             [4]float32
	CupsInteger                 [16]uint32
	CupsReal                    [16]float32
	CupsString                  [16][64]byte
	CupsMarkerType              [64]byte
	CupsRenderingIntent         [64]byte
	CupsPageSizeName            [64]byte
}

// CountRasterPages parses a CUPS/PWG raster stream and returns the number of pages found.
func CountRasterPages(r io.Reader) (int, error) {
	var magic [4]byte
	if _, err := io.ReadFull(r, magic[:]); err != nil {
		return 0, fmt.Errorf("failed to read raster magic bytes: %w", err)
	}

	var byteOrder binary.ByteOrder
	switch string(magic[:]) {
	case "RaSt", "RaS2", "RaS3":
		byteOrder = binary.BigEndian
	case "tSaR", "2SaR", "3SaR":
		byteOrder = binary.LittleEndian
	default:
		return 0, fmt.Errorf("invalid raster magic header: %v (%q)", magic, magic[:])
	}

	pageCount := 0
	for {
		var header CupsHeader
		if err := binary.Read(r, byteOrder, &header); err != nil {
			if errors.Is(err, io.EOF) || errors.Is(err, io.ErrUnexpectedEOF) {
				break
			}
			return pageCount, fmt.Errorf("failed to read raster page %d header: %w", pageCount+1, err)
		}

		pageCount++
		bitmapSize := int64(header.CupsBytesPerLine) * int64(header.CupsHeight)
		if bitmapSize < 0 {
			return pageCount, fmt.Errorf("invalid bitmap size for page %d", pageCount)
		}

		if _, err := io.CopyN(io.Discard, r, bitmapSize); err != nil {
			if errors.Is(err, io.EOF) {
				break
			}
			return pageCount, fmt.Errorf("failed to skip page %d bitmap data: %w", pageCount, err)
		}
	}

	return pageCount, nil
}

// GenerateSampleA4PDF generates a minimal valid single-page A4 PDF binary.
func GenerateSampleA4PDF() []byte {
	body := bytes.NewBuffer(nil)
	body.WriteString("%PDF-1.4\n")
	body.WriteString("1 0 obj\n<</Type /Catalog /Pages 2 0 R>>\nendobj\n")
	body.WriteString("2 0 obj\n<</Type /Pages /Kids [3 0 R] /Count 1>>\nendobj\n")
	body.WriteString("3 0 obj\n<</Type /Page /Parent 2 0 R /MediaBox [0 0 595.28 841.89] /Contents 4 0 R>>\nendobj\n")
	body.WriteString("4 0 obj\n<</Length 44>>\nstream\n1 0 0 rg\n50 50 100 100 re f\n0 1 0 rg\n200 200 100 100 re f\nendstream\nendobj\n")

	rawBody := body.Bytes()
	xrefPos := len(rawBody)

	xref := fmt.Sprintf(
		"xref\n0 5\n0000000000 65535 f \n%010d 00000 n \n%010d 00000 n \n%010d 00000 n \n%010d 00000 n \ntrailer\n<</Size 5 /Root 1 0 R>>\nstartxref\n%d\n%%%%EOF\n",
		bytes.Index(rawBody, []byte("1 0 obj")),
		bytes.Index(rawBody, []byte("2 0 obj")),
		bytes.Index(rawBody, []byte("3 0 obj")),
		bytes.Index(rawBody, []byte("4 0 obj")),
		xrefPos,
	)

	return append(rawBody, []byte(xref)...)
}

// GenerateGenericRasterPPD returns a minimal PPD for driverless CUPS raster conversion.
func GenerateGenericRasterPPD() []byte {
	return []byte(`*PPD-Adobe: "4.3"
*FormatVersion: "4.3"
*FileVersion: "1.1"
*LanguageVersion: English
*LanguageEncoding: ISOLatin1
*PCFileName: "GENRAST.PPD"
*Manufacturer: "Generic"
*Product: "(Generic Raster Printer)"
*ModelName: "Generic Raster Printer"
*ShortNickName: "Generic Raster Printer"
*NickName: "Generic Raster Printer"
*PSVersion: "(3010.000) 0"
*LanguageLevel: "3"
*ColorDevice: True
*DefaultColorSpace: RGB
*FileSystem: False
*Throughput: "1"
*cupsVersion: 1.2
*cupsFilter: "application/vnd.cups-raster 0 -"
*OpenUI *PageSize/Media Size: PickOne
*DefaultPageSize: A4
*PageSize A4/A4: "<</PageSize[595 842]/ImagingBBox null>>setpagedevice"
*CloseUI: *PageSize
*OpenUI *PageRegion/PageRegion: PickOne
*DefaultPageRegion: A4
*PageRegion A4/A4: "<</PageSize[595 842]/ImagingBBox null>>setpagedevice"
*CloseUI: *PageRegion
*DefaultImageableArea: A4
*ImageableArea A4/A4: "0 0 595 842"
*DefaultPaperDimension: A4
*PaperDimension A4/A4: "595 842"
`)
}
