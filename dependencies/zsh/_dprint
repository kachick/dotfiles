#compdef dprint

autoload -U is-at-least

_dprint() {
    typeset -A opt_args
    typeset -a _arguments_options
    local ret=1

    if is-at-least 5.2; then
        _arguments_options=(-s -S -C)
    else
        _arguments_options=(-s -C)
    fi

    local context curcontext="$curcontext" state line
    _arguments "${_arguments_options[@]}" \
'-c+[Path or url to JSON configuration file. Defaults to dprint.json(c) or .dprint.json(c) in current or ancestor directory when not provided.]: : ' \
'--config=[Path or url to JSON configuration file. Defaults to dprint.json(c) or .dprint.json(c) in current or ancestor directory when not provided.]: : ' \
'--plugins=[List of urls or file paths of plugins to use. This overrides what is specified in the config file.]:urls/files: ' \
'-L+[Set log level]: :(debug info warn error silent)' \
'--log-level=[Set log level]: :(debug info warn error silent)' \
'(-L --log-level)--verbose[Alias for --log-level=debug]' \
'-h[Print help]' \
'--help[Print help]' \
'-V[Print version]' \
'--version[Print version]' \
":: :_dprint_commands" \
"*::: :->dprint" \
&& ret=0
    case $state in
    (dprint)
        words=($line[1] "${words[@]}")
        (( CURRENT += 1 ))
        curcontext="${curcontext%:*:*}:dprint-command-$line[1]:"
        case $line[1] in
            (init)
_arguments "${_arguments_options[@]}" \
'-c+[Path or url to JSON configuration file. Defaults to dprint.json(c) or .dprint.json(c) in current or ancestor directory when not provided.]: : ' \
'--config=[Path or url to JSON configuration file. Defaults to dprint.json(c) or .dprint.json(c) in current or ancestor directory when not provided.]: : ' \
'--plugins=[List of urls or file paths of plugins to use. This overrides what is specified in the config file.]:urls/files: ' \
'-L+[Set log level]: :(debug info warn error silent)' \
'--log-level=[Set log level]: :(debug info warn error silent)' \
'(-L --log-level)--verbose[Alias for --log-level=debug]' \
'-h[Print help]' \
'--help[Print help]' \
&& ret=0
;;
(fmt)
_arguments "${_arguments_options[@]}" \
'--includes-override=[List of file patterns in quotes to format. This overrides what is specified in the config file.]:patterns: ' \
'--excludes=[List of file patterns or directories in quotes to exclude when formatting. This excludes in addition to what is found in the config file.]:patterns: ' \
'--excludes-override=[List of file patterns or directories in quotes to exclude when formatting. This overrides what is specified in the config file.]:patterns: ' \
'--incremental=[Only format files when they change. This may alternatively be specified in the configuration file.]' \
'--stdin=[Format stdin and output the result to stdout. Provide an absolute file path to apply the inclusion and exclusion rules or an extension or file name to always format the text.]:extension/file-name/file-path: ' \
'-c+[Path or url to JSON configuration file. Defaults to dprint.json(c) or .dprint.json(c) in current or ancestor directory when not provided.]: : ' \
'--config=[Path or url to JSON configuration file. Defaults to dprint.json(c) or .dprint.json(c) in current or ancestor directory when not provided.]: : ' \
'--plugins=[List of urls or file paths of plugins to use. This overrides what is specified in the config file.]:urls/files: ' \
'-L+[Set log level]: :(debug info warn error silent)' \
'--log-level=[Set log level]: :(debug info warn error silent)' \
'--allow-node-modules[Allows traversing node module directories (unstable - This flag will be renamed to be non-node specific in the future).]' \
'--diff[Outputs a check-like diff of every formatted file.]' \
'--staged[Format only the staged files.]' \
'--allow-no-files[Causes dprint to exit with exit code 0 when no files are found instead of exit code 14.]' \
'--skip-stable-format[Whether to skip formatting a file multiple times until the output is stable]' \
'(-L --log-level)--verbose[Alias for --log-level=debug]' \
'-h[Print help]' \
'--help[Print help]' \
'*::files -- List of file patterns in quotes to format. This can be a subset of what is found in the config file.:' \
&& ret=0
;;
(check)
_arguments "${_arguments_options[@]}" \
'--includes-override=[List of file patterns in quotes to format. This overrides what is specified in the config file.]:patterns: ' \
'--excludes=[List of file patterns or directories in quotes to exclude when formatting. This excludes in addition to what is found in the config file.]:patterns: ' \
'--excludes-override=[List of file patterns or directories in quotes to exclude when formatting. This overrides what is specified in the config file.]:patterns: ' \
'--incremental=[Only format files when they change. This may alternatively be specified in the configuration file.]' \
'-c+[Path or url to JSON configuration file. Defaults to dprint.json(c) or .dprint.json(c) in current or ancestor directory when not provided.]: : ' \
'--config=[Path or url to JSON configuration file. Defaults to dprint.json(c) or .dprint.json(c) in current or ancestor directory when not provided.]: : ' \
'--plugins=[List of urls or file paths of plugins to use. This overrides what is specified in the config file.]:urls/files: ' \
'-L+[Set log level]: :(debug info warn error silent)' \
'--log-level=[Set log level]: :(debug info warn error silent)' \
'--allow-node-modules[Allows traversing node module directories (unstable - This flag will be renamed to be non-node specific in the future).]' \
'--allow-no-files[Causes dprint to exit with exit code 0 when no files are found instead of exit code 14.]' \
'--staged[Format only the staged files.]' \
'--list-different[Only outputs file paths that aren'\''t formatted and doesn'\''t output diffs.]' \
'(-L --log-level)--verbose[Alias for --log-level=debug]' \
'-h[Print help]' \
'--help[Print help]' \
'*::files -- List of file patterns in quotes to format. This can be a subset of what is found in the config file.:' \
&& ret=0
;;
(config)
_arguments "${_arguments_options[@]}" \
'-c+[Path or url to JSON configuration file. Defaults to dprint.json(c) or .dprint.json(c) in current or ancestor directory when not provided.]: : ' \
'--config=[Path or url to JSON configuration file. Defaults to dprint.json(c) or .dprint.json(c) in current or ancestor directory when not provided.]: : ' \
'--plugins=[List of urls or file paths of plugins to use. This overrides what is specified in the config file.]:urls/files: ' \
'-L+[Set log level]: :(debug info warn error silent)' \
'--log-level=[Set log level]: :(debug info warn error silent)' \
'(-L --log-level)--verbose[Alias for --log-level=debug]' \
'-h[Print help]' \
'--help[Print help]' \
":: :_dprint__config_commands" \
"*::: :->config" \
&& ret=0

    case $state in
    (config)
        words=($line[1] "${words[@]}")
        (( CURRENT += 1 ))
        curcontext="${curcontext%:*:*}:dprint-config-command-$line[1]:"
        case $line[1] in
            (init)
_arguments "${_arguments_options[@]}" \
'-c+[Path or url to JSON configuration file. Defaults to dprint.json(c) or .dprint.json(c) in current or ancestor directory when not provided.]: : ' \
'--config=[Path or url to JSON configuration file. Defaults to dprint.json(c) or .dprint.json(c) in current or ancestor directory when not provided.]: : ' \
'--plugins=[List of urls or file paths of plugins to use. This overrides what is specified in the config file.]:urls/files: ' \
'-L+[Set log level]: :(debug info warn error silent)' \
'--log-level=[Set log level]: :(debug info warn error silent)' \
'(-L --log-level)--verbose[Alias for --log-level=debug]' \
'-h[Print help]' \
'--help[Print help]' \
&& ret=0
;;
(update)
_arguments "${_arguments_options[@]}" \
'-c+[Path or url to JSON configuration file. Defaults to dprint.json(c) or .dprint.json(c) in current or ancestor directory when not provided.]: : ' \
'--config=[Path or url to JSON configuration file. Defaults to dprint.json(c) or .dprint.json(c) in current or ancestor directory when not provided.]: : ' \
'--plugins=[List of urls or file paths of plugins to use. This overrides what is specified in the config file.]:urls/files: ' \
'-L+[Set log level]: :(debug info warn error silent)' \
'--log-level=[Set log level]: :(debug info warn error silent)' \
'-y[Upgrade process plugins without prompting to confirm checksums.]' \
'--yes[Upgrade process plugins without prompting to confirm checksums.]' \
'(-L --log-level)--verbose[Alias for --log-level=debug]' \
'-h[Print help]' \
'--help[Print help]' \
&& ret=0
;;
(add)
_arguments "${_arguments_options[@]}" \
'-c+[Path or url to JSON configuration file. Defaults to dprint.json(c) or .dprint.json(c) in current or ancestor directory when not provided.]: : ' \
'--config=[Path or url to JSON configuration file. Defaults to dprint.json(c) or .dprint.json(c) in current or ancestor directory when not provided.]: : ' \
'--plugins=[List of urls or file paths of plugins to use. This overrides what is specified in the config file.]:urls/files: ' \
'-L+[Set log level]: :(debug info warn error silent)' \
'--log-level=[Set log level]: :(debug info warn error silent)' \
'(-L --log-level)--verbose[Alias for --log-level=debug]' \
'-h[Print help]' \
'--help[Print help]' \
'::url-or-plugin-name:' \
&& ret=0
;;
(help)
_arguments "${_arguments_options[@]}" \
":: :_dprint__config__help_commands" \
"*::: :->help" \
&& ret=0

    case $state in
    (help)
        words=($line[1] "${words[@]}")
        (( CURRENT += 1 ))
        curcontext="${curcontext%:*:*}:dprint-config-help-command-$line[1]:"
        case $line[1] in
            (init)
_arguments "${_arguments_options[@]}" \
&& ret=0
;;
(update)
_arguments "${_arguments_options[@]}" \
&& ret=0
;;
(add)
_arguments "${_arguments_options[@]}" \
&& ret=0
;;
(help)
_arguments "${_arguments_options[@]}" \
&& ret=0
;;
        esac
    ;;
esac
;;
        esac
    ;;
esac
;;
(output-file-paths)
_arguments "${_arguments_options[@]}" \
'--includes-override=[List of file patterns in quotes to format. This overrides what is specified in the config file.]:patterns: ' \
'--excludes=[List of file patterns or directories in quotes to exclude when formatting. This excludes in addition to what is found in the config file.]:patterns: ' \
'--excludes-override=[List of file patterns or directories in quotes to exclude when formatting. This overrides what is specified in the config file.]:patterns: ' \
'-c+[Path or url to JSON configuration file. Defaults to dprint.json(c) or .dprint.json(c) in current or ancestor directory when not provided.]: : ' \
'--config=[Path or url to JSON configuration file. Defaults to dprint.json(c) or .dprint.json(c) in current or ancestor directory when not provided.]: : ' \
'--plugins=[List of urls or file paths of plugins to use. This overrides what is specified in the config file.]:urls/files: ' \
'-L+[Set log level]: :(debug info warn error silent)' \
'--log-level=[Set log level]: :(debug info warn error silent)' \
'--allow-node-modules[Allows traversing node module directories (unstable - This flag will be renamed to be non-node specific in the future).]' \
'--staged[Format only the staged files.]' \
'(-L --log-level)--verbose[Alias for --log-level=debug]' \
'-h[Print help]' \
'--help[Print help]' \
'*::files -- List of file patterns in quotes to format. This can be a subset of what is found in the config file.:' \
&& ret=0
;;
(output-resolved-config)
_arguments "${_arguments_options[@]}" \
'-c+[Path or url to JSON configuration file. Defaults to dprint.json(c) or .dprint.json(c) in current or ancestor directory when not provided.]: : ' \
'--config=[Path or url to JSON configuration file. Defaults to dprint.json(c) or .dprint.json(c) in current or ancestor directory when not provided.]: : ' \
'--plugins=[List of urls or file paths of plugins to use. This overrides what is specified in the config file.]:urls/files: ' \
'-L+[Set log level]: :(debug info warn error silent)' \
'--log-level=[Set log level]: :(debug info warn error silent)' \
'(-L --log-level)--verbose[Alias for --log-level=debug]' \
'-h[Print help]' \
'--help[Print help]' \
&& ret=0
;;
(output-format-times)
_arguments "${_arguments_options[@]}" \
'--includes-override=[List of file patterns in quotes to format. This overrides what is specified in the config file.]:patterns: ' \
'--excludes=[List of file patterns or directories in quotes to exclude when formatting. This excludes in addition to what is found in the config file.]:patterns: ' \
'--excludes-override=[List of file patterns or directories in quotes to exclude when formatting. This overrides what is specified in the config file.]:patterns: ' \
'-c+[Path or url to JSON configuration file. Defaults to dprint.json(c) or .dprint.json(c) in current or ancestor directory when not provided.]: : ' \
'--config=[Path or url to JSON configuration file. Defaults to dprint.json(c) or .dprint.json(c) in current or ancestor directory when not provided.]: : ' \
'--plugins=[List of urls or file paths of plugins to use. This overrides what is specified in the config file.]:urls/files: ' \
'-L+[Set log level]: :(debug info warn error silent)' \
'--log-level=[Set log level]: :(debug info warn error silent)' \
'--allow-node-modules[Allows traversing node module directories (unstable - This flag will be renamed to be non-node specific in the future).]' \
'--allow-no-files[Causes dprint to exit with exit code 0 when no files are found instead of exit code 14.]' \
'--staged[Format only the staged files.]' \
'(-L --log-level)--verbose[Alias for --log-level=debug]' \
'-h[Print help]' \
'--help[Print help]' \
'*::files -- List of file patterns in quotes to format. This can be a subset of what is found in the config file.:' \
&& ret=0
;;
(clear-cache)
_arguments "${_arguments_options[@]}" \
'-c+[Path or url to JSON configuration file. Defaults to dprint.json(c) or .dprint.json(c) in current or ancestor directory when not provided.]: : ' \
'--config=[Path or url to JSON configuration file. Defaults to dprint.json(c) or .dprint.json(c) in current or ancestor directory when not provided.]: : ' \
'--plugins=[List of urls or file paths of plugins to use. This overrides what is specified in the config file.]:urls/files: ' \
'-L+[Set log level]: :(debug info warn error silent)' \
'--log-level=[Set log level]: :(debug info warn error silent)' \
'(-L --log-level)--verbose[Alias for --log-level=debug]' \
'-h[Print help]' \
'--help[Print help]' \
&& ret=0
;;
(upgrade)
_arguments "${_arguments_options[@]}" \
'-c+[Path or url to JSON configuration file. Defaults to dprint.json(c) or .dprint.json(c) in current or ancestor directory when not provided.]: : ' \
'--config=[Path or url to JSON configuration file. Defaults to dprint.json(c) or .dprint.json(c) in current or ancestor directory when not provided.]: : ' \
'--plugins=[List of urls or file paths of plugins to use. This overrides what is specified in the config file.]:urls/files: ' \
'-L+[Set log level]: :(debug info warn error silent)' \
'--log-level=[Set log level]: :(debug info warn error silent)' \
'(-L --log-level)--verbose[Alias for --log-level=debug]' \
'-h[Print help]' \
'--help[Print help]' \
&& ret=0
;;
(completions)
_arguments "${_arguments_options[@]}" \
'-c+[Path or url to JSON configuration file. Defaults to dprint.json(c) or .dprint.json(c) in current or ancestor directory when not provided.]: : ' \
'--config=[Path or url to JSON configuration file. Defaults to dprint.json(c) or .dprint.json(c) in current or ancestor directory when not provided.]: : ' \
'--plugins=[List of urls or file paths of plugins to use. This overrides what is specified in the config file.]:urls/files: ' \
'-L+[Set log level]: :(debug info warn error silent)' \
'--log-level=[Set log level]: :(debug info warn error silent)' \
'(-L --log-level)--verbose[Alias for --log-level=debug]' \
'-h[Print help]' \
'--help[Print help]' \
':shell:(bash elvish fish powershell zsh)' \
&& ret=0
;;
(license)
_arguments "${_arguments_options[@]}" \
'-c+[Path or url to JSON configuration file. Defaults to dprint.json(c) or .dprint.json(c) in current or ancestor directory when not provided.]: : ' \
'--config=[Path or url to JSON configuration file. Defaults to dprint.json(c) or .dprint.json(c) in current or ancestor directory when not provided.]: : ' \
'--plugins=[List of urls or file paths of plugins to use. This overrides what is specified in the config file.]:urls/files: ' \
'-L+[Set log level]: :(debug info warn error silent)' \
'--log-level=[Set log level]: :(debug info warn error silent)' \
'(-L --log-level)--verbose[Alias for --log-level=debug]' \
'-h[Print help]' \
'--help[Print help]' \
&& ret=0
;;
(editor-info)
_arguments "${_arguments_options[@]}" \
'-c+[Path or url to JSON configuration file. Defaults to dprint.json(c) or .dprint.json(c) in current or ancestor directory when not provided.]: : ' \
'--config=[Path or url to JSON configuration file. Defaults to dprint.json(c) or .dprint.json(c) in current or ancestor directory when not provided.]: : ' \
'--plugins=[List of urls or file paths of plugins to use. This overrides what is specified in the config file.]:urls/files: ' \
'-L+[Set log level]: :(debug info warn error silent)' \
'--log-level=[Set log level]: :(debug info warn error silent)' \
'(-L --log-level)--verbose[Alias for --log-level=debug]' \
'-h[Print help]' \
'--help[Print help]' \
&& ret=0
;;
(editor-service)
_arguments "${_arguments_options[@]}" \
'--parent-pid=[]: : ' \
'-c+[Path or url to JSON configuration file. Defaults to dprint.json(c) or .dprint.json(c) in current or ancestor directory when not provided.]: : ' \
'--config=[Path or url to JSON configuration file. Defaults to dprint.json(c) or .dprint.json(c) in current or ancestor directory when not provided.]: : ' \
'--plugins=[List of urls or file paths of plugins to use. This overrides what is specified in the config file.]:urls/files: ' \
'-L+[Set log level]: :(debug info warn error silent)' \
'--log-level=[Set log level]: :(debug info warn error silent)' \
'(-L --log-level)--verbose[Alias for --log-level=debug]' \
'-h[Print help]' \
'--help[Print help]' \
&& ret=0
;;
(lsp)
_arguments "${_arguments_options[@]}" \
'-c+[Path or url to JSON configuration file. Defaults to dprint.json(c) or .dprint.json(c) in current or ancestor directory when not provided.]: : ' \
'--config=[Path or url to JSON configuration file. Defaults to dprint.json(c) or .dprint.json(c) in current or ancestor directory when not provided.]: : ' \
'--plugins=[List of urls or file paths of plugins to use. This overrides what is specified in the config file.]:urls/files: ' \
'-L+[Set log level]: :(debug info warn error silent)' \
'--log-level=[Set log level]: :(debug info warn error silent)' \
'(-L --log-level)--verbose[Alias for --log-level=debug]' \
'-h[Print help]' \
'--help[Print help]' \
&& ret=0
;;
(help)
_arguments "${_arguments_options[@]}" \
":: :_dprint__help_commands" \
"*::: :->help" \
&& ret=0

    case $state in
    (help)
        words=($line[1] "${words[@]}")
        (( CURRENT += 1 ))
        curcontext="${curcontext%:*:*}:dprint-help-command-$line[1]:"
        case $line[1] in
            (init)
_arguments "${_arguments_options[@]}" \
&& ret=0
;;
(fmt)
_arguments "${_arguments_options[@]}" \
&& ret=0
;;
(check)
_arguments "${_arguments_options[@]}" \
&& ret=0
;;
(config)
_arguments "${_arguments_options[@]}" \
":: :_dprint__help__config_commands" \
"*::: :->config" \
&& ret=0

    case $state in
    (config)
        words=($line[1] "${words[@]}")
        (( CURRENT += 1 ))
        curcontext="${curcontext%:*:*}:dprint-help-config-command-$line[1]:"
        case $line[1] in
            (init)
_arguments "${_arguments_options[@]}" \
&& ret=0
;;
(update)
_arguments "${_arguments_options[@]}" \
&& ret=0
;;
(add)
_arguments "${_arguments_options[@]}" \
&& ret=0
;;
        esac
    ;;
esac
;;
(output-file-paths)
_arguments "${_arguments_options[@]}" \
&& ret=0
;;
(output-resolved-config)
_arguments "${_arguments_options[@]}" \
&& ret=0
;;
(output-format-times)
_arguments "${_arguments_options[@]}" \
&& ret=0
;;
(clear-cache)
_arguments "${_arguments_options[@]}" \
&& ret=0
;;
(upgrade)
_arguments "${_arguments_options[@]}" \
&& ret=0
;;
(completions)
_arguments "${_arguments_options[@]}" \
&& ret=0
;;
(license)
_arguments "${_arguments_options[@]}" \
&& ret=0
;;
(editor-info)
_arguments "${_arguments_options[@]}" \
&& ret=0
;;
(editor-service)
_arguments "${_arguments_options[@]}" \
&& ret=0
;;
(lsp)
_arguments "${_arguments_options[@]}" \
&& ret=0
;;
(help)
_arguments "${_arguments_options[@]}" \
&& ret=0
;;
        esac
    ;;
esac
;;
        esac
    ;;
esac
}

(( $+functions[_dprint_commands] )) ||
_dprint_commands() {
    local commands; commands=(
'init:Initializes a configuration file in the current directory.' \
'fmt:Formats the source files and writes the result to the file system.' \
'check:Checks for any files that haven'\''t been formatted.' \
'config:Functionality related to the configuration file.' \
'output-file-paths:Prints the resolved file paths for the plugins based on the args and configuration.' \
'output-resolved-config:Prints the resolved configuration for the plugins based on the args and configuration.' \
'output-format-times:Prints the amount of time it takes to format each file. Use this for debugging.' \
'clear-cache:Deletes the plugin cache directory.' \
'upgrade:Upgrades the dprint executable.' \
'completions:Generate shell completions script for dprint' \
'license:Outputs the software license.' \
'editor-info:' \
'editor-service:' \
'lsp:Starts up a language server for formatting files.' \
'help:Print this message or the help of the given subcommand(s)' \
    )
    _describe -t commands 'dprint commands' commands "$@"
}
(( $+functions[_dprint__config__add_commands] )) ||
_dprint__config__add_commands() {
    local commands; commands=()
    _describe -t commands 'dprint config add commands' commands "$@"
}
(( $+functions[_dprint__config__help__add_commands] )) ||
_dprint__config__help__add_commands() {
    local commands; commands=()
    _describe -t commands 'dprint config help add commands' commands "$@"
}
(( $+functions[_dprint__help__config__add_commands] )) ||
_dprint__help__config__add_commands() {
    local commands; commands=()
    _describe -t commands 'dprint help config add commands' commands "$@"
}
(( $+functions[_dprint__check_commands] )) ||
_dprint__check_commands() {
    local commands; commands=()
    _describe -t commands 'dprint check commands' commands "$@"
}
(( $+functions[_dprint__help__check_commands] )) ||
_dprint__help__check_commands() {
    local commands; commands=()
    _describe -t commands 'dprint help check commands' commands "$@"
}
(( $+functions[_dprint__clear-cache_commands] )) ||
_dprint__clear-cache_commands() {
    local commands; commands=()
    _describe -t commands 'dprint clear-cache commands' commands "$@"
}
(( $+functions[_dprint__help__clear-cache_commands] )) ||
_dprint__help__clear-cache_commands() {
    local commands; commands=()
    _describe -t commands 'dprint help clear-cache commands' commands "$@"
}
(( $+functions[_dprint__completions_commands] )) ||
_dprint__completions_commands() {
    local commands; commands=()
    _describe -t commands 'dprint completions commands' commands "$@"
}
(( $+functions[_dprint__help__completions_commands] )) ||
_dprint__help__completions_commands() {
    local commands; commands=()
    _describe -t commands 'dprint help completions commands' commands "$@"
}
(( $+functions[_dprint__config_commands] )) ||
_dprint__config_commands() {
    local commands; commands=(
'init:Initializes a configuration file in the current directory.' \
'update:Updates the plugins in the configuration file.' \
'add:Adds a plugin to the configuration file.' \
'help:Print this message or the help of the given subcommand(s)' \
    )
    _describe -t commands 'dprint config commands' commands "$@"
}
(( $+functions[_dprint__help__config_commands] )) ||
_dprint__help__config_commands() {
    local commands; commands=(
'init:Initializes a configuration file in the current directory.' \
'update:Updates the plugins in the configuration file.' \
'add:Adds a plugin to the configuration file.' \
    )
    _describe -t commands 'dprint help config commands' commands "$@"
}
(( $+functions[_dprint__editor-info_commands] )) ||
_dprint__editor-info_commands() {
    local commands; commands=()
    _describe -t commands 'dprint editor-info commands' commands "$@"
}
(( $+functions[_dprint__help__editor-info_commands] )) ||
_dprint__help__editor-info_commands() {
    local commands; commands=()
    _describe -t commands 'dprint help editor-info commands' commands "$@"
}
(( $+functions[_dprint__editor-service_commands] )) ||
_dprint__editor-service_commands() {
    local commands; commands=()
    _describe -t commands 'dprint editor-service commands' commands "$@"
}
(( $+functions[_dprint__help__editor-service_commands] )) ||
_dprint__help__editor-service_commands() {
    local commands; commands=()
    _describe -t commands 'dprint help editor-service commands' commands "$@"
}
(( $+functions[_dprint__fmt_commands] )) ||
_dprint__fmt_commands() {
    local commands; commands=()
    _describe -t commands 'dprint fmt commands' commands "$@"
}
(( $+functions[_dprint__help__fmt_commands] )) ||
_dprint__help__fmt_commands() {
    local commands; commands=()
    _describe -t commands 'dprint help fmt commands' commands "$@"
}
(( $+functions[_dprint__config__help_commands] )) ||
_dprint__config__help_commands() {
    local commands; commands=(
'init:Initializes a configuration file in the current directory.' \
'update:Updates the plugins in the configuration file.' \
'add:Adds a plugin to the configuration file.' \
'help:Print this message or the help of the given subcommand(s)' \
    )
    _describe -t commands 'dprint config help commands' commands "$@"
}
(( $+functions[_dprint__config__help__help_commands] )) ||
_dprint__config__help__help_commands() {
    local commands; commands=()
    _describe -t commands 'dprint config help help commands' commands "$@"
}
(( $+functions[_dprint__help_commands] )) ||
_dprint__help_commands() {
    local commands; commands=(
'init:Initializes a configuration file in the current directory.' \
'fmt:Formats the source files and writes the result to the file system.' \
'check:Checks for any files that haven'\''t been formatted.' \
'config:Functionality related to the configuration file.' \
'output-file-paths:Prints the resolved file paths for the plugins based on the args and configuration.' \
'output-resolved-config:Prints the resolved configuration for the plugins based on the args and configuration.' \
'output-format-times:Prints the amount of time it takes to format each file. Use this for debugging.' \
'clear-cache:Deletes the plugin cache directory.' \
'upgrade:Upgrades the dprint executable.' \
'completions:Generate shell completions script for dprint' \
'license:Outputs the software license.' \
'editor-info:' \
'editor-service:' \
'lsp:Starts up a language server for formatting files.' \
'help:Print this message or the help of the given subcommand(s)' \
    )
    _describe -t commands 'dprint help commands' commands "$@"
}
(( $+functions[_dprint__help__help_commands] )) ||
_dprint__help__help_commands() {
    local commands; commands=()
    _describe -t commands 'dprint help help commands' commands "$@"
}
(( $+functions[_dprint__config__help__init_commands] )) ||
_dprint__config__help__init_commands() {
    local commands; commands=()
    _describe -t commands 'dprint config help init commands' commands "$@"
}
(( $+functions[_dprint__config__init_commands] )) ||
_dprint__config__init_commands() {
    local commands; commands=()
    _describe -t commands 'dprint config init commands' commands "$@"
}
(( $+functions[_dprint__help__config__init_commands] )) ||
_dprint__help__config__init_commands() {
    local commands; commands=()
    _describe -t commands 'dprint help config init commands' commands "$@"
}
(( $+functions[_dprint__help__init_commands] )) ||
_dprint__help__init_commands() {
    local commands; commands=()
    _describe -t commands 'dprint help init commands' commands "$@"
}
(( $+functions[_dprint__init_commands] )) ||
_dprint__init_commands() {
    local commands; commands=()
    _describe -t commands 'dprint init commands' commands "$@"
}
(( $+functions[_dprint__help__license_commands] )) ||
_dprint__help__license_commands() {
    local commands; commands=()
    _describe -t commands 'dprint help license commands' commands "$@"
}
(( $+functions[_dprint__license_commands] )) ||
_dprint__license_commands() {
    local commands; commands=()
    _describe -t commands 'dprint license commands' commands "$@"
}
(( $+functions[_dprint__help__lsp_commands] )) ||
_dprint__help__lsp_commands() {
    local commands; commands=()
    _describe -t commands 'dprint help lsp commands' commands "$@"
}
(( $+functions[_dprint__lsp_commands] )) ||
_dprint__lsp_commands() {
    local commands; commands=()
    _describe -t commands 'dprint lsp commands' commands "$@"
}
(( $+functions[_dprint__help__output-file-paths_commands] )) ||
_dprint__help__output-file-paths_commands() {
    local commands; commands=()
    _describe -t commands 'dprint help output-file-paths commands' commands "$@"
}
(( $+functions[_dprint__output-file-paths_commands] )) ||
_dprint__output-file-paths_commands() {
    local commands; commands=()
    _describe -t commands 'dprint output-file-paths commands' commands "$@"
}
(( $+functions[_dprint__help__output-format-times_commands] )) ||
_dprint__help__output-format-times_commands() {
    local commands; commands=()
    _describe -t commands 'dprint help output-format-times commands' commands "$@"
}
(( $+functions[_dprint__output-format-times_commands] )) ||
_dprint__output-format-times_commands() {
    local commands; commands=()
    _describe -t commands 'dprint output-format-times commands' commands "$@"
}
(( $+functions[_dprint__help__output-resolved-config_commands] )) ||
_dprint__help__output-resolved-config_commands() {
    local commands; commands=()
    _describe -t commands 'dprint help output-resolved-config commands' commands "$@"
}
(( $+functions[_dprint__output-resolved-config_commands] )) ||
_dprint__output-resolved-config_commands() {
    local commands; commands=()
    _describe -t commands 'dprint output-resolved-config commands' commands "$@"
}
(( $+functions[_dprint__config__help__update_commands] )) ||
_dprint__config__help__update_commands() {
    local commands; commands=()
    _describe -t commands 'dprint config help update commands' commands "$@"
}
(( $+functions[_dprint__config__update_commands] )) ||
_dprint__config__update_commands() {
    local commands; commands=()
    _describe -t commands 'dprint config update commands' commands "$@"
}
(( $+functions[_dprint__help__config__update_commands] )) ||
_dprint__help__config__update_commands() {
    local commands; commands=()
    _describe -t commands 'dprint help config update commands' commands "$@"
}
(( $+functions[_dprint__help__upgrade_commands] )) ||
_dprint__help__upgrade_commands() {
    local commands; commands=()
    _describe -t commands 'dprint help upgrade commands' commands "$@"
}
(( $+functions[_dprint__upgrade_commands] )) ||
_dprint__upgrade_commands() {
    local commands; commands=()
    _describe -t commands 'dprint upgrade commands' commands "$@"
}

if [ "$funcstack[1]" = "_dprint" ]; then
    _dprint "$@"
else
    compdef _dprint dprint
fi
