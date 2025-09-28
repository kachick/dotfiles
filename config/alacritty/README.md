# Alacritty Configuration FAQ

This document provides answers to frequently asked questions about configuring Alacritty.

---

### Why is my Alacritty configuration not being applied?

There are two common reasons for this:

1. **Incorrect Format (YAML vs. TOML):**
   - Check your Alacritty version with `alacritty --version`.
   - Versions `0.13.0` and newer use TOML (`alacritty.toml`).
   - Older versions use YAML (`alacritty.yml`). Ensure your configuration file uses the correct format for your version.

2. **Incorrect Configuration File Location:**
   - The expected location of the main configuration file depends on your operating system.
   - **Linux/macOS:** `~/.config/alacritty/alacritty.toml`
   - **Windows:** `%APPDATA%\alacritty\alacritty.toml` (e.g., `C:\Users\YourUser\AppData\Roaming\alacritty\alacritty.toml`)
   - While imported files can be placed elsewhere (e.g., under `~/.config/alacritty/`), the main `alacritty.toml` must be in the correct location.
   - You can temporarily specify a different configuration file using the `--config-file` flag for testing purposes.

### How do I copy and paste in Alacritty?

By default, `Ctrl+C` sends an interrupt signal. To use `Ctrl+C` and `Ctrl+V` for copy-paste, you typically need to add `Shift` (i.e., `Ctrl+Shift+C` and `Ctrl+Shift+V`). This behavior is intentional to avoid conflicting with standard terminal signals. See [alacritty/alacritty#2383](https://github.com/alacritty/alacritty/issues/2383) for discussion.

### How can I test different settings or themes?

There are two main ways to test settings without modifying your main configuration file:

1. **Command-line Overrides:**
   Use the `-o` flag to override specific settings on launch.

   ```bash
   # Test a different font and opacity
   alacritty -o window.opacity=0.85 -o font.size=12 -o font.normal.family='"IosevkaTerm NFM"'

   # Test window size and position
   alacritty -o window.dimensions.columns=180 -o window.dimensions.lines=50 -o window.position.x=10 -o window.position.y=10
   ```

2. **Local Configuration File:**
   Create a `~/.config/alacritty/local.toml` file. Settings in this file will override the main `alacritty.toml` and can be used for local testing or machine-specific tweaks.

### Can I view the final, merged runtime configuration?

No, Alacritty does not currently have a feature to print the final configuration after all sources (main config, local config, CLI overrides) have been merged. See [alacritty/alacritty#7147](https://github.com/alacritty/alacritty/issues/7147) for details.
