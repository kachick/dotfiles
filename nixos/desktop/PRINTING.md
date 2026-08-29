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

### 1. Dump Intermediate CUPS Raster

Run `cupsfilter` to convert a test PDF into a CUPS Raster file:

```bash
cupsfilter -p /etc/cups/ppd/<Printer-Name>.ppd -m application/vnd.cups-raster test_page.pdf > /tmp/test.raster
```

### 2. Inspect and Assert Page Counts

You can programmatically verify that a 1-page input produces exactly 1 page in the raster output by reading the CUPS Raster header using Python:

```python
import ctypes

class CupsHeader2(ctypes.Structure):
    _fields_ = [
        ('MediaClass', ctypes.c_char * 64),
        ('MediaColor', ctypes.c_char * 64),
        ('MediaType', ctypes.c_char * 64),
        ('OutputType', ctypes.c_char * 64),
        ('AdvanceDistance', ctypes.c_uint32),
        ('AdvanceMedia', ctypes.c_uint32),
        ('Collate', ctypes.c_uint32),
        ('CutMedia', ctypes.c_uint32),
        ('Duplex', ctypes.c_uint32),
        ('HWResolution', ctypes.c_uint32 * 2),
        ('ImagingBoundingBox', ctypes.c_uint32 * 4),
        ('InsertSheet', ctypes.c_uint32),
        ('Jog', ctypes.c_uint32),
        ('LeadingEdge', ctypes.c_uint32),
        ('Margins', ctypes.c_uint32 * 2),
        ('ManualFeed', ctypes.c_uint32),
        ('MediaPosition', ctypes.c_uint32),
        ('MediaWeight', ctypes.c_uint32),
        ('MirrorPrint', ctypes.c_uint32),
        ('NegativePrint', ctypes.c_uint32),
        ('NumCopies', ctypes.c_uint32),
        ('Orientation', ctypes.c_uint32),
        ('OutputFaceUp', ctypes.c_uint32),
        ('PageSize', ctypes.c_uint32 * 2),
        ('Separations', ctypes.c_uint32),
        ('TraySwitch', ctypes.c_uint32),
        ('Tumble', ctypes.c_uint32),
        ('cupsWidth', ctypes.c_uint32),
        ('cupsHeight', ctypes.c_uint32),
        ('cupsMediaType', ctypes.c_uint32),
        ('cupsBitsPerColor', ctypes.c_uint32),
        ('cupsBitsPerPixel', ctypes.c_uint32),
        ('cupsBytesPerLine', ctypes.c_uint32),
        ('cupsColorOrder', ctypes.c_uint32),
        ('cupsColorSpace', ctypes.c_uint32),
        ('cupsCompression', ctypes.c_uint32),
        ('cupsRowCount', ctypes.c_uint32),
        ('cupsRowFeed', ctypes.c_uint32),
        ('cupsRowStep', ctypes.c_uint32),
        ('cupsNumColors', ctypes.c_uint32),
        ('cupsBorderlessScalingFactor', ctypes.c_float),
        ('cupsPageSize', ctypes.c_float * 2),
        ('cupsImagingBBox', ctypes.c_float * 4),
        ('cupsInteger', ctypes.c_uint32 * 16),
        ('cupsReal', ctypes.c_float * 16),
        ('cupsString', (ctypes.c_char * 64) * 16),
        ('cupsMarkerType', ctypes.c_char * 64),
        ('cupsRenderingIntent', ctypes.c_char * 64),
        ('cupsPageSizeName', ctypes.c_char * 64)
    ]

with open('/tmp/test.raster', 'rb') as f:
    data = f.read()

offset = 4  # Skip magic bytes
pages = 0
while offset + ctypes.sizeof(CupsHeader2) <= len(data):
    hdr = CupsHeader2.from_buffer_copy(data[offset:offset+ctypes.sizeof(CupsHeader2)])
    pages += 1
    bitmap_size = hdr.cupsBytesPerLine * hdr.cupsHeight
    offset += ctypes.sizeof(CupsHeader2) + bitmap_size

assert pages == 1, f"Expected 1 page, got {pages}"
print(f"Verified: raster contains exactly {pages} page(s).")
```
