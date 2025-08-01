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

    completions: {
      # Available since 0.104.0
      # - https://github.com/nushell/nushell.github.io/pull/1897
      # - https://github.com/nushell/nushell/pull/15511
      # Not available on History yet: https://github.com/nushell/nushell/discussions/7968#discussioncomment-13730988
      algorithm: "substring"
    }
}

# https://github.com/nushell/nushell/issues/7988
const WINDOWS_CONFIG = "windows_config.nu"
const UNIX_CONFIG = "unix_config.nu"

const OS_SPECIFIC_CONFIG = if $nu.os-info.name == "windows" {
  $WINDOWS_CONFIG
} else {
  $UNIX_CONFIG
}

source $OS_SPECIFIC_CONFIG

def --env cdtemp [] {
  cd (mktemp --directory)
}

alias g = git

# https://github.com/NixOS/nixpkgs/pull/344193
alias zed = zeditor

alias gH = git show HEAD

