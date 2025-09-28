# Google Japanese Input on Windows

This document contains notes specific to configuring Google Japanese Input on Windows, which is based on the open-source Mozc project.

---

### Why is this configuration separate from the main Mozc config?

Although the configuration is similar to the one used for Mozc on Linux, it is kept in a separate file for two main reasons:

1. **Platform-Specific Customizations:** The keymap configurations provided by Google for Windows and Linux have platform-specific differences.
2. **Line Endings:** Configuration files on Windows require CRLF line endings, whereas Linux files use LF.

### Keymap changes are not applied after modifying the configuration.

Similar to Mozc on GNOME, changes to the configuration are not always applied immediately. On Windows, you may need to sign out and sign back in for the new keymap to take effect. A full reboot of the Desktop Environment (or the OS) is often the most reliable way to apply changes.
