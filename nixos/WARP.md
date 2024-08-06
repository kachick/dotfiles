# Cloudflare WARP

Basically connecting when you login with GDM, and GNOME shows the status badge that will be active if you connected to WARP.

If not, or if you want to disconnect, follow <https://developers.cloudflare.com/warp-client/get-started/linux/> steps

## First connections

```bash
warp-cli registration new
warp-cli connect
```

## Make sure the connection status

```bash
warp-cli status
curl -sL https://www.cloudflare.com/cdn-cgi/trace/ | grep -F 'warp=on'
```

Or use <https://github.com/jason5ng32/MyIP> with accessing to <https://ipcheck.ing/>

## Disconnect if you want

```bash
warp-cli disconnect
```
