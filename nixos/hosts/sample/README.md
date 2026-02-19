# NixOS Host Template

This directory contains a standalone template for a NixOS system that inherits from this repository.

## How to use this template

If you want to manage your NixOS configuration in a separate repository (or a separate branch), this is the easiest starting point.

1. **Copy `flake.nix`**: Copy the `flake.nix` in this directory to your project root.
2. **Generate Hardware Config**: Run the following command on your target machine:

   ```bash
   nixos-generate-config --show-hardware-config > hardware-configuration.nix
   ```

3. **Adjust `flake.nix`**:
   - Update the `dotfiles.url` if you want to point to a specific branch or GIT_SHA.
   - Change the `networking.hostName` to your preference.
4. **Apply**:

   ```bash
   sudo nixos-rebuild switch --flake .#sample
   ```

## Development and Testing

The `verify.bash` script in this directory ensures that this template remains valid and evaluatable against the current state of the main repository.

```bash
task test-sample-nixos
```
