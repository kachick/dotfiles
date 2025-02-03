# Since nushell 0.101, we can only specify changed values from default
# See https://github.com/nushell/nushell/pull/14249 for detail

$env.config = {
    show_banner: false

    keybindings: [
        {
            name: history_menu
            modifier: control_shift # Changed from original control to avoid conflict with fzf integration
            keycode: char_r
            mode: [emacs, vi_insert, vi_normal]
            event: { send: menu name: history_menu }
        }
        # https://github.com/nushell/nushell/issues/1616#issuecomment-2120164422
        {
          name: fuzzy_history
          modifier: control
          keycode: char_r
          mode: [emacs, vi_normal, vi_insert]
          event: [
            {
              send: ExecuteHostCommand
              cmd: "commandline edit (
                history
                  | get command
                  | reverse
                  | uniq
                  | str join (char -i 0)
                  | fzf
                    --preview '{}'
                    --preview-window 'right:30%'
                    --scheme history
                    --read0
                    --layout reverse
                    --height 40%
                    --query (commandline)
                  | decode utf-8
                  | str trim
              )"
            }
          ]
        }
    ]
}

if $nu.os-info.name == "windows" {
  # nushell and handling dir symlink looks strange. Might be broken. And adjusted to same results with other environments
  def la [...paths: string] {
    eza --long --all --group-directories-first --time-style=iso --color=always --no-user --sort=modified ...$paths
  }
}
