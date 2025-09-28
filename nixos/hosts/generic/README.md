# Generic NixOS Host Configuration

This directory provides a generic NixOS host configuration that can be adapted for a new machine without committing its specific `hardware-configuration.nix` to the repository.

## Rationale

Including a machine-specific `/etc/nixos/hardware-configuration.nix` in this repository for every new device is cumbersome. This generic configuration provides a template to bootstrap a new machine, although it requires using Nix's "impure" mode.

## Usage Instructions

1. **Copy Hardware Configuration:**
   After a fresh NixOS installation, copy the generated hardware configuration to this directory.

   ```bash
   cp /etc/nixos/hardware-configuration.nix ./nixos/hosts/generic/
   ```

2. **Update Flake Inputs:**
   You will need to uncomment the line that imports `hardware-configuration.nix` in the relevant flake file within this directory. Search for `UPDATEME` to find the location.

   ```bash
   # Find the line to update
   git grep 'UPDATEME' ./nixos/hosts/generic

   # After uncommenting the line, stage the changes
   git add .
   ```

3. **Build and Apply the Configuration:**
   First, build the configuration to ensure it's valid. Then, apply it to your system.

   ```bash
   # Build the configuration to test it
   nixos-rebuild build --flake .#generic

   # If the build succeeds, apply it to the system
   sudo nixos-rebuild switch --flake .#generic
   ```

4. **Using `task apply`:**
   If you intend to use the `task apply` command, you may need to reboot the machine first for the new hostname to be applied correctly.
