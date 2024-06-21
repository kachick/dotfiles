## How to bulk install extensions without cloud sync

```bash
xargs --no-run-if-empty --max-lines=1 code --install-extension <./config/vscode/extensions.txt
```

This is same method as [tips](https://stackoverflow.com/a/60805086)

## How to backup the extensions

```bash
code --list-extensions | sort > ./config/vscode/extensions.txt
```
