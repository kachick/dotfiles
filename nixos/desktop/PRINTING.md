# Printing

## Setup via CUPS Web UI

1. Open `http://localhost:631/admin/` and add a network printer with IPP Everywhere (driverless).
1. Set default paper size to A4 if needed:

   ```bash
   lpoptions -p '<Printer-Name>' -o PageSize=A4
   ```

## Quarter-sized Prints (Scaling Issues)

Some network printers lack a built-in PDF interpreter and misinterpret 72 dpi PDF coordinates as 360 dpi, shrinking output to 1/4 size.
Enable "Print as Image" (画像として印刷) in the print dialog (GTK dialogs remember this per printer).

```bash
# 1. Inspect supported formats in the `pdl=` TXT field (if `application/pdf` is missing, rasterization is required)
avahi-browse -rt _ipp._tcp

# 2. Check `FINAL_CONTENT_TYPE=` in CUPS filter debug output (`image/urf` = rasterized, `application/pdf` = raw passthrough)
cupsfilter -p '/etc/cups/ppd/<Printer-Name>.ppd' test.pdf >/dev/null
```
