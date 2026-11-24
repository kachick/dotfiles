{
  stdenvNoCC,
  fetchurl,
  antigravity-cli,
  writeShellApplication,
  coreutils,
  curl,
  git,
  jq,
  gnused,
  nix,
  runCommand,
  writableTmpDirAsHomeHook,
}:

let
  version = "1.5.16";
  buildId = "5250855658717184";
  wholeVersion = "${version}-${buildId}";

  throwSystem = throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}";

  sourceData = {
    x86_64-linux = fetchurl {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/${wholeVersion}/linux-x64/cli_linux_x64.tar.gz";
      hash = "sha256-m9qyNNBrrRphviMhByZS6wa+eLr/Gsv65HMx2loJCrw=";
    };
    aarch64-linux = fetchurl {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/${wholeVersion}/linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha256-fd7seQCE5VCvGK2wSltsX98ts+ECaFT0mQGgTLQmXH4=";
    };
    aarch64-darwin = fetchurl {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/${wholeVersion}/darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha256-ukcgL3Et5MSnj9eH2BuiBtc+Ecl1cvxpQg8pp378jZU=";
    };
  };

  agyWrapper = writeShellApplication {
    name = "agy";

    runtimeInputs = [
      coreutils
      git
      jq
    ];

    text = builtins.readFile ./wrapper.bash;
  };
in
antigravity-cli.overrideAttrs (old: {
  inherit version;

  src = sourceData.${stdenvNoCC.hostPlatform.system} or throwSystem;

  # Wrap agy so linked git worktrees (such as clean-bare layouts) automatically mount
  # their shared .git directory read-only inside the terminal sandbox.
  postInstall = (old.postInstall or "") + ''
    mv "$out/bin/agy" "$out/bin/.agy-wrapped"
    install -m755 "${agyWrapper}/bin/agy" "$out/bin/agy"
  '';

  passthru = (old.passthru or { }) // {
    inherit wholeVersion;
    tests = (old.passthru.tests or { }) // {
      worktreeWrapper =
        runCommand "antigravity-cli-worktree-wrapper-test"
          {
            nativeBuildInputs = [
              git
              jq
              writableTmpDirAsHomeHook
            ];
          }
          ''
            mkdir -p "$TMPDIR/bin" "$HOME/.gemini/antigravity-cli"
            install -m755 "${agyWrapper}/bin/agy" "$TMPDIR/bin/agy"
            cat <<'EOF' > "$TMPDIR/bin/.agy-wrapped"
            #!/bin/sh
            printf '%s\n' "$@"
            EOF
            chmod +x "$TMPDIR/bin/.agy-wrapped"

            cat <<'EOF' > "$HOME/.gemini/antigravity-cli/settings.json"
            {
              "permissions": {
                "allow": ["command(git)", "read_file(/nix/store)"],
                "ask": ["command(rm)"],
                "deny": ["command(sudo)"]
              }
            }
            EOF

            git config --global user.name "Test"
            git config --global user.email "test@example.com"
            git config --global init.defaultBranch main

            mkdir -p "$TMPDIR/normal"
            git -C "$TMPDIR/normal" init -q
            git -C "$TMPDIR/normal" commit --allow-empty -m "init" -q

            out_normal="$(cd "$TMPDIR/normal" && "$TMPDIR/bin/agy" --mode=auto)"
            if [[ "$out_normal" != "--mode=auto" ]]; then
              echo "normal repo should pass through unchanged, got: $out_normal" >&2
              exit 1
            fi

            mkdir -p "$TMPDIR/bare"
            git init --bare -q "$TMPDIR/bare/.git"
            git --git-dir="$TMPDIR/bare/.git" symbolic-ref HEAD refs/heads/main
            git -C "$TMPDIR/normal" push -q "$TMPDIR/bare/.git" main
            git --git-dir="$TMPDIR/bare/.git" worktree add -q "$TMPDIR/bare/main" main
            mkdir -p "$TMPDIR/bare/main/sub"

            mapfile -t out_wt < <(cd "$TMPDIR/bare/main/sub" && "$TMPDIR/bin/agy" --mode=auto)
            if [[ "''${out_wt[0]}" != "--settings" || "''${out_wt[2]}" != "--mode=auto" ]]; then
              echo "worktree should inject --settings before args, got: ''${out_wt[*]}" >&2
              exit 1
            fi

            expected_rule="read_file($TMPDIR/bare/.git)"
            jq -e --arg rule "$expected_rule" '
              (.permissions.allow | index($rule) != null)
              and (.permissions.allow | index("read_file(/nix/store)") != null)
              and (.permissions.ask == ["command(rm)"])
              and (.permissions.deny == ["command(sudo)"])
            ' <<< "''${out_wt[1]}" > /dev/null

            out_subcmd="$(cd "$TMPDIR/bare/main" && "$TMPDIR/bin/agy" models)"
            if [[ "$out_subcmd" != "models" ]]; then
              echo "subcommand should pass through unchanged, got: $out_subcmd" >&2
              exit 1
            fi

            out_explicit="$(cd "$TMPDIR/bare/main" && "$TMPDIR/bin/agy" --settings '{}')"
            if [[ "$out_explicit" != $'--settings\n{}' ]]; then
              echo "explicit --settings should pass through unchanged, got: $out_explicit" >&2
              exit 1
            fi

            touch "$out"
          '';
    };
    updateScript = writeShellApplication {
      name = "antigravity-cli-updater";

      runtimeInputs = [
        curl
        jq
        gnused
        nix
      ];

      text = builtins.readFile ./update.bash;
    };
  };

  meta = (old.meta or { }) // {
    changelog = "https://antigravity.google/docs/changelog?tab=cli";
  };
})
