{
  pkgs,
  config,
  ...
}:
{
  # This module enables Cloudflare WARP.
  # While it is suitable for both servers and desktops, we separate it into a module
  # to opt-out on environments where it is unnecessary (e.g., WSL2 or other VM guests).
  #

  services.cloudflare-warp = {
    enable = true;
    package = pkgs.local.cloudflare-warp;
  };

  # Avoid DNS conflicts with local DNS resolvers and Tailscale MagicDNS.
  # Using tunnel_only mode keeps the IP tunnel without breaking local DNS routing.
  #
  # WHY NOT MDM (mdm.xml service_mode: tunnelonly)?
  # - Cloudflare MDM's "tunnelonly" parameter is strictly for Cloudflare Zero Trust (Teams).
  #   On Consumer (Free) registrations, MDM tunnelonly fails to connect.
  # - CLI's "warp-cli mode tunnel_only" works on Consumer accounts, so set it via postStart.
  systemd.services.cloudflare-warp.postStart = ''
    for _ in $(seq 1 10); do
      if ${config.services.cloudflare-warp.package}/bin/warp-cli mode tunnel_only 2>/dev/null; then
        break
      fi
      sleep 1
    done

    # Exclude Tailscale control plane and DERP relay endpoints from split tunnel.
    # WARP requires both apex and wildcard entries to match apex and subdomains.
    for host in "tailscale.com" "*.tailscale.com" "ts.net" "*.ts.net"; do
      ${config.services.cloudflare-warp.package}/bin/warp-cli tunnel host add "$host" 2>/dev/null || true
    done
  '';

  nixpkgs.allowedUnfreePackageNames = [ "cloudflare-warp" ];

  # https://github.com/tailscale/tailscale/issues/4432#issuecomment-1112819111
  # https://github.com/NixOS/nixpkgs/issues/504119#issuecomment-4143108440
  networking.firewall.checkReversePath = "loose";

  # Ensure tailscaled starts after cloudflare-warp finishes its postStart
  # split tunnel configuration. If cloudflare-warp is stopped or disabled,
  # systemd's `After` has no effect and tailscaled starts immediately.
  systemd.services.tailscaled.after = [ "cloudflare-warp.service" ];
}
