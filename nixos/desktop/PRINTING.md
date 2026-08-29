# Printing (CUPS)

## Overview

Modern network printers support **IPP Everywhere (driverless printing)**.
We prefer driverless printing over proprietary CUPS wrapper drivers for the following reasons:

- **Stability across system upgrades**: Proprietary filters often lag behind or fail to handle updated CUPS Raster headers/color spaces when `cups-filters` or `ghostscript` is upgraded in major NixOS releases (e.g. causing jobs to split into multiple blank or distorted pages).
- **Simplicity**: No extra driver packages (`drivers = [ ... ]`) need to be managed in NixOS configurations.

## Persistence in NixOS

Printers registered via the CUPS Web interface (`http://localhost:631/admin/`) are stored in `/etc/cups/printers.conf` and `/etc/cups/ppd/`.

In NixOS, the `/etc/cups/` directory is managed as a stateful directory. Configuration changes made through the CUPS Web UI or CLI (`lpadmin`) **persist across system reboots and `nixos-rebuild switch` invocations**.

## Setup via CUPS Web UI

1. Make sure your printer is powered on and connected to the local network (Wi-Fi or Ethernet).
2. Open `http://localhost:631/admin/` in your browser.
3. Click **Add Printer** (you may be prompted for your local user credentials).
4. Under **Discovered Network Printers**, select your printer model with the `(driverless)` suffix or `ipp://...`.
5. In the model selection step, choose **IPP Everywhere** (or let CUPS auto-generate the driverless PPD).
6. Complete the setup and set default print options if desired.

## Local Pipeline Verification (Testing without Paper/Ink)

To verify the print conversion pipeline without sending jobs to a physical printer or wasting paper and ink, you can simulate CUPS filter chains locally.

### 1. Automated Test Task

Run the test task to automatically generate a sample 1-page PDF, execute `cupsfilter`, and assert the raster page count:

```bash
task test-printer
```

### 2. Custom Testing with Specific PPD or Input PDF

You can also pass custom PPD files or existing PDF documents to verify specific printer definitions:

```bash
# Test with a specific PPD file
go run ./cmd/test-printer --ppd /etc/cups/ppd/<Printer-Name>.ppd

# Test with a specific input PDF
go run ./cmd/test-printer --input /path/to/document.pdf
```
