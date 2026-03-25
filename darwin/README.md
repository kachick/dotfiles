# macOS - darwin

Extracted to [wiki](https://github.com/kachick/dotfiles/wiki/macOS)

## Maintenance Note (2026-02)

As of early 2026, this repository prioritizes Linux, and macOS (Darwin) maintenance is on a "best-effort" basis due to high CI costs and low usage (less than 10%).

- **CI Strategy**: We use the slow `macos-15-intel` runners for Darwin.
- **Experimental Failure**: We attempted to use fast ARM runners (`macos-26`) with Rosetta 2 emulation to build/test Intel binaries to reduce CI costs. However, it was not adopted for the following reasons:
  - **Performance**: Emulation was significantly slower than native Intel runners. For example, building the `lima` package took about 26 minutes, compared to 14 minutes on a native Intel runner.
  - **Compatibility**: Some tools and tests (e.g., `lima`) detect the host architecture and fail when running under Rosetta 2.
- **Future**: This is a temporary situation until Rosetta 2 is removed (reportedly in `macos-28`).

## CI Optimization: Cache Detection on Linux

To minimize the usage of the slow and expensive Darwin runners, we use a "Planning Job" on a fast Linux runner (`ubuntu-24.04`) to detect if a rebuild is actually necessary.

### How it works

We leverage the native `nix build --dry-run` command. Since Nix can calculate the derivation of any platform (including Darwin) on Linux, we can check if the resulting store path exists in any of the configured substituters (Cachix, etc.) without performing the actual build.

### Rationale

While we could check specific cache URLs (like `cache.nixos.org` or `kachick-dotfiles.cachix.org`) using `curl`, the `--dry-run` approach is superior because:

- **Automatic Resolution**: It respects all substituters defined in `flake.nix` (`nixConfig.extra-substituters`) and system configs.
- **Maintainability**: No need to update the CI script when adding new cache providers (e.g., Garnix).
- **Comprehensive**: It checks for both the package itself and its entire dependency tree.

### Output Patterns to Check

The logic looks for the string `will be built` in the standard error output:

1. **Cached (Skip Build)**:

   ```text
   these 5 paths will be fetched (29.17 MiB download, 83.40 MiB unpacked):
     /nix/store/...-rclone-1.73.0
   ```

   (The string `will be built` is absent.)

2. **Rebuild Required (Trigger Darwin Job)**:

   ```text
   this derivation will be built:
     /nix/store/...-package.drv
   ```

   (The string `will be built` is present.)

3. **Local Store (Already evaluated/built on the runner)**:
   (Output is empty or only includes minor logs; `will be built` is absent.)

### Implementation Example

```bash
if nix build ".#packages.x86_64-darwin.pname" --dry-run 2>&1 | grep -q "will be built"; then
  echo "Rebuild required on Darwin"
else
  echo "Cached or already exists"
fi
```

## Troubleshooting: Binary Cache and Trusted Users

If Nix builds packages from source instead of fetching from Cachix on Darwin, it's often because the user is not recognized as a "trusted user", which prevents the use of flake-provided binary caches (`accept-flake-config`).

### 1. Check if you are a "trusted-user" in Nix

Run the following command to see the current Nix configuration:

```bash
nix show-config | grep trusted-users
```

The output should include `@admin` or your username. If not, you need to edit `/etc/nix/nix.conf`.

### 2. Verify your group membership

On macOS, administrators are typically in the `admin` group, not `wheel`. Check your groups:

```bash
id -Gn | tr ' ' '\n' | grep -E 'admin|wheel'
```

### 3. Test if --accept-flake-config is allowed

Run a metadata check on this flake. If you are NOT a trusted user, Nix will show a warning or ignore the custom cache settings:

```bash
nix flake metadata . --accept-flake-config
```

If you see `warning: ignoring untrusted flake configuration`, it means you are not trusted.

### 4. How to fix

1. Edit `/etc/nix/nix.conf` (requires sudo) and ensure `trusted-users` includes `@admin`:

   ```conf
   trusted-users = root @admin @wheel <your-username>
   ```

2. Restart the Nix daemon:

   ```bash
   sudo launchctl kickstart -k system/org.nixos.nix-daemon
   ```

3. (Optional) Update your local cache configuration:

   ```bash
   nix run --accept-flake-config ".#gen-nix-cache-conf" | sudo tee /etc/nix/nix.custom.conf
   ```

## Removed: Devshell on Darwin

The `devshell-darwin.yml` workflow was removed in 2026-02 because implementing a reliable "Planning Job" (cache detection) for `devShells` proved to be excessively complex.

Unlike regular packages or Home Manager configurations, `devShell` derivations (`nix-shell.drv`) are not typically cached in binary substituters. Even if all underlying dependencies are cached, Nix often wants to "rebuild" the temporary shell derivation itself. This makes it difficult to differentiate between a simple environment setup and an actual change in the development tools without significant overhead or unreliable heuristics (like `git diff`). Given the low usage of Darwin development in this repo, we decided to drop the automated devshell check on Darwin.
