# plamo

Local PLaMo-3-Translate CLI and `llama-plamo` service controller.

## Architecture

```mermaid
flowchart LR
    trans_bin["trans (symlink)"] -->|"argv[0] == trans"| cmd_trans["plamo trans"]
    plamo_bin["plamo"] --> cmd_trans
    plamo_bin --> cmd_svc["plamo start / stop / status"]

    cmd_trans -->|"no :lang / --to"| detect{"Has Hiragana or Katakana?"}
    detect -->|"Yes"| target_en["target_lang=en"]
    detect -->|"No"| target_ja["target_lang=ja"]
    cmd_trans -->|":LANG / SRC:LANG / --to"| target_explicit["Explicit language"]

    target_en --> api["llama-server (127.0.0.1:18080)"]
    target_ja --> api
    target_explicit --> api

    cmd_svc -->|"systemctl --user"| unit["llama-plamo.service"]
    unit -.->|"runs"| api
```

## Quick Examples

```console
# Auto-detect (English -> Japanese, Japanese -> English)
trans "Hello, world!"
trans "こんにちは"

# Explicit target or source:target
trans :en "おはようございます"
trans en:ja --form polite "Good morning"

# Pipe input
echo "Hello, world!" | trans

# Service control and full options
plamo status
plamo start
trans --help
```
