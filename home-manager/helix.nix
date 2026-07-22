{
  lib,
  pkgs,
  ...
}:

{
  # https://github.com/nix-community/home-manager/blob/release-26.05/modules/programs/helix.nix
  # keybinds: https://docs.helix-editor.com/keymap.html
  programs.helix = {
    # Enabling this may cause collisions. Do not add in packages list
    enable = true;

    settings = {
      theme = "base16_transparent";

      editor = {
        soft-wrap = {
          enable = true;
        };

        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };

        lsp = {
          display-inlay-hints = false;
          display-messages = true;
        };

        color-modes = true;

        # like tab
        # how to move: gn, gp, <space>-b/
        # Not available with mouse click movement for now. https://github.com/helix-editor/helix/issues/4942
        bufferline = "always";

        file-picker = {
          # This option makes much confusion, actually working `false = show dotfiles but respecting .gitignore`
          hidden = false;
        };

        # https://github.com/helix-editor/helix/pull/11430#issuecomment-2593580148
        default-yank-register = "+";
      };

      keys =
        let
          shared_keymaps = {
            # "C-c" by helix default. And Using "C-/" is not simple. It requires Kitty keyboard protocol and be different on each terminal.
            # See https://github.com/helix-editor/helix/discussions/12899
            "C-/" = "toggle_comments"; # Such as vscode. Simply works on ghostty.
            "C-7" = "toggle_comments"; # Trick for realizing "C-/" in Windows Terminal. See https://github.com/helix-editor/helix/issues/1369#issuecomment-1749330353. And not working on ghostty.

            "C-p" = "file_picker";
            "C-F" = "global_search"; # "<space>-/" by default. Use Ctrl+Shift+f like modeless editors

            # https://github.com/sxyazi/yazi/pull/2461#issue-2905199790
            "C-y" = [
              ":sh rm -f /tmp/helix-and-yazi-integration"
              ":insert-output ${lib.getExe pkgs.yazi} %{buffer_name} --chooser-file=/tmp/helix-and-yazi-integration"
              ''
                :insert-output echo "\x1b[?1049h\x1b[?2004h" > /dev/tty
              ''
              ":open %sh{cat /tmp/helix-and-yazi-integration}"
              ":redraw"
            ];
          };
        in
        {
          normal = shared_keymaps // {
            space = {
              # https://github.com/helix-editor/helix/issues/6338
              # https://github.com/helix-editor/helix/discussions/7690
              H = ":toggle lsp.display-inlay-hints";
            };
          };

          insert = shared_keymaps // { };
        };
    };

    ignores = [
      ".git/"
      ".direnv/"
      ".node_modules/"
    ];
  };
}
