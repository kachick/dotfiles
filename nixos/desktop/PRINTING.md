# Printing

## Setup via CUPS Web UI

1. Open `http://localhost:631/admin/` and click **Add Printer**.
2. Select your network printer with **IPP Everywhere** (driverless).
3. Set the default paper size to A4 if needed:
   ```bash
   lpoptions -p <Printer-Name> -o PageSize=A4
   ```

## Troubleshooting & Tips

### Quarter-sized Prints (Scaling issues)

Some network printers lack a built-in PDF interpreter. Sending raw PDF files directly can cause the printer to misinterpret 72 dpi coordinates as 360 dpi, shrinking the output to roughly 1/4 size.

- **Solution**: Enable **"Print as Image" (画像として印刷)** in the print dialog (e.g. Evince, Chrome). GTK dialogs will remember this option per printer.

### Check if a printer supports PDF or requires rasterization (CLI)

1. Check the printer's supported formats via mDNS/DNS-SD:
   ```bash
   avahi-browse -rt _ipp._tcp
   ```
   Inspect the `pdl=` field in the TXT record:
   - If `application/pdf` is **missing** (e.g. only `image/urf`, `image/pwg-raster`, `image/jpeg`), the printer cannot directly interpret PDF files and requires rasterized input (Print as Image).

2. Inspect how CUPS processes a PDF job:
   ```bash
   cupsfilter -p /etc/cups/ppd/<Printer-Name>.ppd test.pdf > /dev/null
   ```
   Check the `DEBUG` logs on stderr:
   - **Rasterized (Image mode)**: `FINAL_CONTENT_TYPE=image/urf` (or `application/vnd.cups-raster`) with filters like `pdftopdf` and `ghostscript`.
   - **Raw Passthrough (Missing rasterization)**: `FINAL_CONTENT_TYPE=application/pdf` with only `gziptoany` (raw PDF sent directly, leading to 1/4 scaling).
