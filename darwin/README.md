# macOS - darwin

Extracted to [wiki](https://github.com/kachick/dotfiles/wiki/macOS)

## Maintenance Note (2026-02)

As of early 2026, this repository prioritizes Linux, and macOS (Darwin) maintenance is on a "best-effort" basis due to high CI costs and low usage (less than 10%).

- **CI Strategy**: We use fast ARM runners (`macos-26`+) to build Intel Mac (`x86_64-darwin`) binaries via Rosetta 2. This significantly reduces CI time compared to using slow Intel runners.
- **Rosetta 2 Lifespan**: It is reported that Rosetta 2 will be removed in `macos-28`. This "ARM-to-Intel" cross-build strategy is a temporary solution until Intel support is completely dropped or migrated to ARM natively.
