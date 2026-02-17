# macOS - darwin

Extracted to [wiki](https://github.com/kachick/dotfiles/wiki/macOS)

## Maintenance Note (2026-02)

As of early 2026, this repository prioritizes Linux, and macOS (Darwin) maintenance is on a "best-effort" basis due to high CI costs and low usage (less than 10%).

- **CI Strategy**: We use the slow `macos-15-intel` runners for Darwin.
- **Experimental Failure**: We attempted to use fast ARM runners (`macos-26`) with Rosetta 2 emulation to build/test Intel binaries, but it was much slower than native Intel runners and failed some tests (e.g., `lima`) that require native architecture detection.
- **Future**: We are looking for a better way to maintain Darwin, but for now, we stick with the slow Intel runners.
