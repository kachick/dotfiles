# Mozc Configuration Notes

This document contains notes for configuring Mozc (Google Japanese Input).

---

### Keymap changes are not applied on GNOME

If you have modified the Mozc configuration but the keymap changes are not taking effect, you may need to restart the IBus daemon.

Run the following command in your terminal to clear the cache and restart IBus:

```bash
ibus write-cache && ibus restart
```
