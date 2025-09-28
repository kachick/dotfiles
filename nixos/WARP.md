# Using Cloudflare WARP on NixOS

This guide provides instructions for setting up and using the Cloudflare WARP client on NixOS.

## Important Note for GNOME Users

Do not add `warp-cli` to GDM's `PostLogin` script. The first time `warp-cli` runs, it requires interactive agreement (y/n) to its policy. Running it from a login script will block the GNOME session from starting, resulting in a black screen with a frozen cursor.

---

## Basic Usage

### 1. Initial Setup and Connection

You must perform these steps manually in a terminal for the first-time setup.

```bash
# Register a new device
warp-cli registration new

# Connect to WARP
warp-cli connect
```

After connecting, GNOME should display a status badge indicating that WARP is active.

### 2. Verifying the Connection

You can verify that WARP is active in several ways:

- **Check the CLI status:**

  ```bash
  warp-cli status
  ```

- **Check the Cloudflare trace endpoint:**

  ```bash
  curl -sL https://www.cloudflare.com/cdn-cgi/trace/ | grep -F 'warp=on'
  ```

- **Use a web-based tool:**
  Visit <https://ipcheck.ing/> (powered by [jason5ng32/MyIP](https://github.com/jason5ng32/MyIP)).

### 3. Disconnecting from WARP

To disconnect from the WARP network:

```bash
warp-cli disconnect
```

---

## Split Tunnels

If you encounter connection problems with specific services (e.g., [GH-749](https://github.com/kachick/dotfiles/issues/749)), you can exclude their IP addresses or domains from the WARP tunnel.

```bash
# Example: Exclude the dprint plugin registry
warp-cli tunnel host add plugins.dprint.dev
```

For more detailed information, refer to the [official Split Tunnels documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-devices/warp/configure-warp/route-traffic/split-tunnels/).
