{ ... }:

{
  programs.starship.enableNushellIntegration = true;
  programs.direnv.enableNushellIntegration = true;
  programs.zoxide.enableNushellIntegration = true;

  programs.nushell = {
    enable = true;

    # fzf manager does not have nushell integration yet.
    # https://github.com/nushell/nushell/issues/1616#issuecomment-1386714173 may help you.

    # Do not set `shell_integration: true for now`
    #   - window title requires `shell_integration: true` - https://github.com/nushell/nushell/issues/2527
    #   - several terminal requires `shell_integration: false` - https://github.com/nushell/nushell/issues/6214
    extraConfig = ''
      let-env config = {
        show_banner: false

        keybindings: [
          # https://github.com/nushell/nushell/issues/1616#issuecomment-1386714173
          {
            name: fuzzy_history
            modifier: control
            keycode: char_r
            mode: [emacs, vi_normal, vi_insert]
            event: [
              {
                send: ExecuteHostCommand
                cmd: "commandline (
                  history
                    | each { |it| $it.command }
                    | uniq
                    | reverse
                    | str join (char -i 0)
                    | fzf --read0 --layout=reverse --height=40% -q (commandline)
                    | decode utf-8
                    | str trim
                )"
              }
            ]
          }
          # Same as above for Up Arrow
          {
            name: fuzzy_history
            modifier: control
            keycode: Up
            mode: [emacs, vi_normal, vi_insert]
            event: [
              {
                send: ExecuteHostCommand
                cmd: "commandline (
                  history
                    | each { |it| $it.command }
                    | uniq
                    | reverse
                    | str join (char -i 0)
                    | fzf --read0 --layout=reverse --height=40% -q (commandline)
                    | decode utf-8
                    | str trim
                )"
              }
            ]
          }
        ]
      }
    '';
  };
}
