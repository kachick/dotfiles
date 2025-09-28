# Input Method Editor (IME) Choices

This document explains the rationale for using Google Japanese Input over the default Microsoft IME on Windows.

## Comparison: Google Japanese Input vs. Microsoft IME

### Microsoft IME: Pros

- **Pre-installed:** Comes bundled with Windows.
- **Cloud Suggestions:** Includes cloud-based predictive suggestions (予測変換).

### Microsoft IME: Cons

- **Platform-Specific:** It is not a cross-platform solution. In contrast, Mozc (the open-source version of Google Japanese Input) is available on Linux, Windows, and macOS, allowing for a consistent experience.
- **Date Conversion:** To convert "きょう" to the current date, you must press the `Tab` key instead of the `Space` key.
- **No ISO 8601 Date Format:** There is no built-in way to convert text to the ISO 8601 date format (e.g., `2023-10-27`).

## How to Disable Microsoft IME

After installing Google Japanese Input, you can follow the steps in [issue #300](https://github.com/kachick/dotfiles/issues/300) to completely disable Microsoft IME.
