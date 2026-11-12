# MicroVM Sandbox

```bash
nix run .#microvm-sandbox

# Inside the guest
sudo poweroff
```

- `/home/user/repos/github.com/kachick` is shared read-write with the host.
- `/nix/store` uses a volatile `tmpfs` overlay (`2G`) and resets on shutdown.
