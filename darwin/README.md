# macOS - darwin

Extracted to [wiki](https://github.com/kachick/dotfiles/wiki/macOS)

## Maintenance Note (2026-02)

As of early 2026, this repository prioritizes Linux, and macOS (Darwin) maintenance is on a "best-effort" basis due to high CI costs and low usage (less than 10%).

- **CI Strategy**: We use the slow `macos-15-intel` runners for Darwin.
- **Experimental Failure**: We attempted to use fast ARM runners (`macos-26`) with Rosetta 2 emulation to build/test Intel binaries to reduce CI costs. However, it was not adopted for the following reasons:
  - **Performance**: Emulation was significantly slower than native Intel runners. For example, building the `lima` package took about 26 minutes, compared to 14 minutes on a native Intel runner.
  - **Compatibility**: Some tools and tests (e.g., `lima`) detect the host architecture and fail when running under Rosetta 2.
- **Future**: This is a temporary situation until Rosetta 2 is removed (reportedly in `macos-28`).
