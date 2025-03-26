# Cloudflare WARP

Don't add warp-cli into "gdm/PostLogin", the first execution requires agreement for their policy with y/n interactive mode.\
It blocks the starting GNOME with black screen with white and frozen cursor after login via GDM.

## First connections

```bash
warp-cli registration new
warp-cli connect
```

GNOME shows the status badge that will be active if you connected to WARP.

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

## Split Tunnels

If you encounter connection problems such as [GH-749](https://github.com/kachick/dotfiles/issues/749), you can eclude specific addresses from WARP

```bash
warp-cli tunnel host add plugins.dprint.dev
```

See [official document](https://developers.cloudflare.com/cloudflare-one/connections/connect-devices/warp/configure-warp/route-traffic/split-tunnels/) for detail.
