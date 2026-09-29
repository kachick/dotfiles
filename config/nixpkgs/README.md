# Setup to develop NixOS/nixpkgs

Personal setups, I should ensure these files are still ignored in .gitignore.\
Nixpkgs is globally used and I should setup personal tools if I need.

## Note

If I can simply sync the devcontainer setup.

```bash
echo 'use flake' >.envrc
mkdir -p .vscode
<.devcontainer/devcontainer.json | nu --stdin --commands 'from json | to json' | jq '.customizations.vscode.settings' >.vscode/settings.json
```
