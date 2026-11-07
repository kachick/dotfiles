{
  pkgs,
  lib,
  ...
}:

{
  home.packages = [
    # PLaMo-3 tokenizer ('plamo3') requires llama.cpp v0.8.0+ in nixpkgs unstable
    pkgs.unstable.llama-cpp
    pkgs.local.plamo-trans
  ];

  home.shellAliases = {
    "plamo-start" = "systemctl --user start llama-plamo";
    "plamo-stop" = "systemctl --user stop llama-plamo";
    "plamo-status" = "systemctl --user status llama-plamo";
  };

  # Background server for local translation using PLaMo-3-Translate 0.8B.
  #
  # WHY NOT wantedBy = [ "default.target" ]:
  # Keep autostart disabled so it does not consume resources on boot.
  # Start on demand via `systemctl --user start llama-plamo` (or `plamo-start`).
  systemd.user.services.llama-plamo = {
    Unit = {
      Description = "PLaMo-3-Translate 0.8B server via llama.cpp";
      After = [ "network.target" ];
    };

    Service = {
      Type = "simple";
      # Downloads and caches the GGUF model automatically into ~/.cache/huggingface/hub/ on first start.
      # -np 4 -c 8192: Provide 4 parallel slots (2048 tokens each) for concurrent requests and lookahead prefetching.
      # -t 8 -tb 16: Use 8 physical cores for memory-bound token generation and all 16 logical threads for compute-bound prompt batching.
      # -fa on: Enable Flash Attention to speed up prompt and batch evaluation.
      # WHY NOT port 8080: Port 8080 is commonly used by local web development servers; 18080 avoids conflicts.
      ExecStart = "${lib.getExe' pkgs.unstable.llama-cpp "llama-server"} -hf pfnet/plamo-3-translate-0.8b-GGUF:Q4_K_M --host 127.0.0.1 --port 18080 -c 8192 -np 4 -t 8 -tb 16 -fa on";
      Restart = "no";
    };
  };
}
