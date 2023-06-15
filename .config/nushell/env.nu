# Nushell Environment Config File
#
# version = 0.79.0

# https://www.nushell.sh/book/3rdpartyprompts.html#starship
def create_left_prompt [] {
    starship prompt --cmd-duration $env.CMD_DURATION_MS $'--status=($env.LAST_EXIT_CODE)'
}

### Original before using starship

# def create_left_prompt [] {
#     mut home = ""
#     try {
#         if $nu.os-info.name == "windows" {
#             $home = $env.USERPROFILE
#         } else {
#             $home = $env.HOME
#         }
#     }

#     let dir = ([
#         ($env.PWD | str substring 0..($home | str length) | str replace -s $home "~"),
#         ($env.PWD | str substring ($home | str length)..)
#     ] | str join)

#     let path_segment = if (is-admin) {
#         $"(ansi red_bold)($dir)"
#     } else {
#         $"(ansi green_bold)($dir)"
#     }

#     $path_segment
# }

# def create_right_prompt [] {
#     let time_segment = ([
#         (ansi reset)
#         (ansi magenta)
#         (date now | date format '%m/%d/%Y %r')
#     ] | str join)

#     let last_exit_code = if ($env.LAST_EXIT_CODE != 0) {([
#         (ansi rb)
#         ($env.LAST_EXIT_CODE)
#     ] | str join)
#     } else { "" }

#     ([$last_exit_code, (char space), $time_segment] | str join)
# }

# # Use nushell functions to define your right and left prompt
# let-env PROMPT_COMMAND = {|| create_left_prompt }
# let-env PROMPT_COMMAND_RIGHT = {|| create_right_prompt }

# # The prompt indicators are environmental variables that represent
# # the state of the prompt
# let-env PROMPT_INDICATOR = {|| "> " }
# let-env PROMPT_INDICATOR_VI_INSERT = {|| ": " }
# let-env PROMPT_INDICATOR_VI_NORMAL = {|| "> " }
# let-env PROMPT_MULTILINE_INDICATOR = {|| "::: " }

# Specifies how environment variables are:
# - converted from a string to a value on Nushell startup (from_string)
# - converted from a value back to a string when running external commands (to_string)
# Note: The conversions happen *after* config.nu is loaded
let-env ENV_CONVERSIONS = {
  "PATH": {
    from_string: { |s| $s | split row (char esep) | path expand -n }
    to_string: { |v| $v | path expand -n | str join (char esep) }
  }
  "Path": {
    from_string: { |s| $s | split row (char esep) | path expand -n }
    to_string: { |v| $v | path expand -n | str join (char esep) }
  }
}

# Directories to search for scripts when calling source or use
#
# By default, <nushell-config-dir>/scripts is added
let-env NU_LIB_DIRS = [
    ($nu.default-config-dir | path join 'scripts')
]

# Directories to search for plugin binaries when calling register
#
# By default, <nushell-config-dir>/plugins is added
let-env NU_PLUGIN_DIRS = [
    ($nu.default-config-dir | path join 'plugins')
]

# To add entries to PATH (on Windows you might use Path), you can use the following pattern:
# let-env PATH = ($env.PATH | split row (char esep) | prepend '/some/path')

### Custom for starship

# https://github.com/starship/starship/tree/0cffd59b72adbc4c2c33d6bb14dbca170c775fc4#step-2-setup-your-shell-to-use-starship
mkdir $"($env.XDG_CACHE_HOME)/starship"
starship init nu | save -f $"($env.XDG_CACHE_HOME)/starship/init.nu"

# https://github.com/ajeetdsouza/zoxide/tree/6dedfcd74aef9c8484d6d921869b34a0d4395c38
mkdir $"($env.XDG_CACHE_HOME)/zoxide"
zoxide init nushell | save -f $"($env.XDG_CACHE_HOME)/zoxide/init.nu"

