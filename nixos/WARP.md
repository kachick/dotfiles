Just installing as [this](https://github.com/NixOS/nixpkgs/issues/213177#issuecomment-1905556283) does not start connections.

You should https://developers.cloudflare.com/warp-client/get-started/linux/

```bash
warp-cli registration new
warp-cli connect

# Make sure warp=on 
curl -OL https://www.cloudflare.com/cdn-cgi/trace/
```
