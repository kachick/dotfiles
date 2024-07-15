# Cloudflare WARP

TODO: Replace this document with NixOS module since using [NixOS 24.11](https://github.com/NixOS/nixpkgs/pull/321142)

Just installing as [this](https://github.com/NixOS/nixpkgs/issues/213177#issuecomment-1905556283) does not start connections.

You should <https://developers.cloudflare.com/warp-client/get-started/linux/>

```bash
warp-cli registration new
warp-cli connect

# Make sure warp=on 
curl -OL https://www.cloudflare.com/cdn-cgi/trace/
```
