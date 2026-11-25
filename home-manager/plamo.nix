{
  pkgs,
  lib,
  ...
}:

{
  home.packages = [
    # PLaMo-3 tokenizer ('plamo3') requires llama.cpp v0.8.0+
    pkgs.llama-cpp
    pkgs.local.plamo-trans
  ];

  home.shellAliases = {
    "plamo-start" = "systemctl --user start llama-plamo";
    "plamo-stop" = "systemctl --user stop llama-plamo";
    "plamo-status" = "systemctl --user status llama-plamo";
  };

  # Background server for local translation using PLaMo-3-Translate 0.8B.
  systemd.user.services.llama-plamo = {
    Unit = {
      Description = "PLaMo-3-Translate 0.8B server via llama.cpp";
      After = [ "network.target" ];
    };

    Service = {
      Type = "simple";
      # Downloads and caches the GGUF model automatically into ~/.cache/huggingface/hub/ on first start.
      # -np 4 -c 8192 -kvu: Provide 4 parallel slots sharing a unified KV buffer for concurrent requests and lookahead prefetching.
      # -fa on: Enable Flash Attention to speed up prompt and batch evaluation.
      # WHY NOT -t / -tb: llama-server detects physical CPU cores automatically at runtime, which works across hosts with different core counts (e.g. 8 cores on algae, 6 cores on moss).
      # WHY NOT port 8080: Port 8080 is commonly used by local web development servers; 18080 avoids conflicts.
      ExecStart = "${lib.getExe' pkgs.llama-cpp "llama-server"} -hf pfnet/plamo-3-translate-0.8b-GGUF:Q4_K_M --host 127.0.0.1 --port 18080 -c 8192 -np 4 -kvu -fa on";
      # WHY NOT Restart = "on-failure": Keep startup simple; fail once if offline before the first model download, instead of retrying in the background.
      Restart = "no";
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
