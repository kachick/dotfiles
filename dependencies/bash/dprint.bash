_dprint() {
    local i cur prev opts cmd
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    cmd=""
    opts=""

    for i in ${COMP_WORDS[@]}
    do
        case "${cmd},${i}" in
            ",$1")
                cmd="dprint"
                ;;
            dprint,check)
                cmd="dprint__check"
                ;;
            dprint,clear-cache)
                cmd="dprint__clear__cache"
                ;;
            dprint,completions)
                cmd="dprint__completions"
                ;;
            dprint,config)
                cmd="dprint__config"
                ;;
            dprint,editor-info)
                cmd="dprint__editor__info"
                ;;
            dprint,editor-service)
                cmd="dprint__editor__service"
                ;;
            dprint,fmt)
                cmd="dprint__fmt"
                ;;
            dprint,help)
                cmd="dprint__help"
                ;;
            dprint,init)
                cmd="dprint__init"
                ;;
            dprint,license)
                cmd="dprint__license"
                ;;
            dprint,lsp)
                cmd="dprint__lsp"
                ;;
            dprint,output-file-paths)
                cmd="dprint__output__file__paths"
                ;;
            dprint,output-format-times)
                cmd="dprint__output__format__times"
                ;;
            dprint,output-resolved-config)
                cmd="dprint__output__resolved__config"
                ;;
            dprint,upgrade)
                cmd="dprint__upgrade"
                ;;
            dprint__config,add)
                cmd="dprint__config__add"
                ;;
            dprint__config,help)
                cmd="dprint__config__help"
                ;;
            dprint__config,init)
                cmd="dprint__config__init"
                ;;
            dprint__config,update)
                cmd="dprint__config__update"
                ;;
            dprint__config__help,add)
                cmd="dprint__config__help__add"
                ;;
            dprint__config__help,help)
                cmd="dprint__config__help__help"
                ;;
            dprint__config__help,init)
                cmd="dprint__config__help__init"
                ;;
            dprint__config__help,update)
                cmd="dprint__config__help__update"
                ;;
            dprint__help,check)
                cmd="dprint__help__check"
                ;;
            dprint__help,clear-cache)
                cmd="dprint__help__clear__cache"
                ;;
            dprint__help,completions)
                cmd="dprint__help__completions"
                ;;
            dprint__help,config)
                cmd="dprint__help__config"
                ;;
            dprint__help,editor-info)
                cmd="dprint__help__editor__info"
                ;;
            dprint__help,editor-service)
                cmd="dprint__help__editor__service"
                ;;
            dprint__help,fmt)
                cmd="dprint__help__fmt"
                ;;
            dprint__help,help)
                cmd="dprint__help__help"
                ;;
            dprint__help,init)
                cmd="dprint__help__init"
                ;;
            dprint__help,license)
                cmd="dprint__help__license"
                ;;
            dprint__help,lsp)
                cmd="dprint__help__lsp"
                ;;
            dprint__help,output-file-paths)
                cmd="dprint__help__output__file__paths"
                ;;
            dprint__help,output-format-times)
                cmd="dprint__help__output__format__times"
                ;;
            dprint__help,output-resolved-config)
                cmd="dprint__help__output__resolved__config"
                ;;
            dprint__help,upgrade)
                cmd="dprint__help__upgrade"
                ;;
            dprint__help__config,add)
                cmd="dprint__help__config__add"
                ;;
            dprint__help__config,init)
                cmd="dprint__help__config__init"
                ;;
            dprint__help__config,update)
                cmd="dprint__help__config__update"
                ;;
            *)
                ;;
        esac
    done

    case "${cmd}" in
        dprint)
            opts="-c -L -h -V --config --config-discovery --plugins --log-level --verbose --help --version init fmt check config output-file-paths output-resolved-config output-format-times clear-cache upgrade completions license editor-info editor-service lsp help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 1 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -c)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config-discovery)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --plugins)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --log-level)
                    COMPREPLY=($(compgen -W "debug info warn error silent" -- "${cur}"))
                    return 0
                    ;;
                -L)
                    COMPREPLY=($(compgen -W "debug info warn error silent" -- "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        dprint__check)
            opts="-c -L -h --includes-override --excludes --excludes-override --allow-node-modules --incremental --allow-no-files --staged --list-different --config --config-discovery --plugins --log-level --verbose --help [files]..."
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --includes-override)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --excludes)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --excludes-override)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --incremental)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -c)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config-discovery)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --plugins)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --log-level)
                    COMPREPLY=($(compgen -W "debug info warn error silent" -- "${cur}"))
                    return 0
                    ;;
                -L)
                    COMPREPLY=($(compgen -W "debug info warn error silent" -- "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        dprint__clear__cache)
            opts="-c -L -h --config --config-discovery --plugins --log-level --verbose --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -c)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config-discovery)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --plugins)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --log-level)
                    COMPREPLY=($(compgen -W "debug info warn error silent" -- "${cur}"))
                    return 0
                    ;;
                -L)
                    COMPREPLY=($(compgen -W "debug info warn error silent" -- "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        dprint__completions)
            opts="-c -L -h --config --config-discovery --plugins --log-level --verbose --help bash elvish fish powershell zsh"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -c)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config-discovery)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --plugins)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --log-level)
                    COMPREPLY=($(compgen -W "debug info warn error silent" -- "${cur}"))
                    return 0
                    ;;
                -L)
                    COMPREPLY=($(compgen -W "debug info warn error silent" -- "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        dprint__config)
            opts="-c -L -h --config --config-discovery --plugins --log-level --verbose --help init update add help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -c)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config-discovery)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --plugins)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --log-level)
                    COMPREPLY=($(compgen -W "debug info warn error silent" -- "${cur}"))
                    return 0
                    ;;
                -L)
                    COMPREPLY=($(compgen -W "debug info warn error silent" -- "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        dprint__config__add)
            opts="-c -L -h --config --config-discovery --plugins --log-level --verbose --help [url-or-plugin-name]"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -c)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config-discovery)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --plugins)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --log-level)
                    COMPREPLY=($(compgen -W "debug info warn error silent" -- "${cur}"))
                    return 0
                    ;;
                -L)
                    COMPREPLY=($(compgen -W "debug info warn error silent" -- "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        dprint__config__help)
            opts="init update add help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        dprint__config__help__add)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        dprint__config__help__help)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        dprint__config__help__init)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        dprint__config__help__update)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        dprint__config__init)
            opts="-c -L -h --config --config-discovery --plugins --log-level --verbose --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -c)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config-discovery)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --plugins)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --log-level)
                    COMPREPLY=($(compgen -W "debug info warn error silent" -- "${cur}"))
                    return 0
                    ;;
                -L)
                    COMPREPLY=($(compgen -W "debug info warn error silent" -- "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        dprint__config__update)
            opts="-y -c -L -h --yes --config --config-discovery --plugins --log-level --verbose --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -c)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config-discovery)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --plugins)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --log-level)
                    COMPREPLY=($(compgen -W "debug info warn error silent" -- "${cur}"))
                    return 0
                    ;;
                -L)
                    COMPREPLY=($(compgen -W "debug info warn error silent" -- "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        dprint__editor__info)
            opts="-c -L -h --config --config-discovery --plugins --log-level --verbose --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -c)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config-discovery)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --plugins)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --log-level)
                    COMPREPLY=($(compgen -W "debug info warn error silent" -- "${cur}"))
                    return 0
                    ;;
                -L)
                    COMPREPLY=($(compgen -W "debug info warn error silent" -- "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        dprint__editor__service)
            opts="-c -L -h --parent-pid --config --config-discovery --plugins --log-level --verbose --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --parent-pid)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -c)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config-discovery)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --plugins)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --log-level)
                    COMPREPLY=($(compgen -W "debug info warn error silent" -- "${cur}"))
                    return 0
                    ;;
                -L)
                    COMPREPLY=($(compgen -W "debug info warn error silent" -- "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        dprint__fmt)
            opts="-c -L -h --includes-override --excludes --excludes-override --allow-node-modules --incremental --stdin --diff --staged --allow-no-files --skip-stable-format --config --config-discovery --plugins --log-level --verbose --help [files]..."
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --includes-override)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --excludes)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --excludes-override)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --incremental)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --stdin)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -c)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config-discovery)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --plugins)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --log-level)
                    COMPREPLY=($(compgen -W "debug info warn error silent" -- "${cur}"))
                    return 0
                    ;;
                -L)
                    COMPREPLY=($(compgen -W "debug info warn error silent" -- "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        dprint__help)
            opts="init fmt check config output-file-paths output-resolved-config output-format-times clear-cache upgrade completions license editor-info editor-service lsp help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        dprint__help__check)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        dprint__help__clear__cache)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        dprint__help__completions)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        dprint__help__config)
            opts="init update add"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        dprint__help__config__add)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        dprint__help__config__init)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        dprint__help__config__update)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        dprint__help__editor__info)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        dprint__help__editor__service)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        dprint__help__fmt)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        dprint__help__help)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        dprint__help__init)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        dprint__help__license)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        dprint__help__lsp)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        dprint__help__output__file__paths)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        dprint__help__output__format__times)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        dprint__help__output__resolved__config)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        dprint__help__upgrade)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        dprint__init)
            opts="-c -L -h --config --config-discovery --plugins --log-level --verbose --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -c)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config-discovery)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --plugins)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --log-level)
                    COMPREPLY=($(compgen -W "debug info warn error silent" -- "${cur}"))
                    return 0
                    ;;
                -L)
                    COMPREPLY=($(compgen -W "debug info warn error silent" -- "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        dprint__license)
            opts="-c -L -h --config --config-discovery --plugins --log-level --verbose --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -c)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config-discovery)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --plugins)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --log-level)
                    COMPREPLY=($(compgen -W "debug info warn error silent" -- "${cur}"))
                    return 0
                    ;;
                -L)
                    COMPREPLY=($(compgen -W "debug info warn error silent" -- "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        dprint__lsp)
            opts="-c -L -h --config --config-discovery --plugins --log-level --verbose --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -c)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config-discovery)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --plugins)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --log-level)
                    COMPREPLY=($(compgen -W "debug info warn error silent" -- "${cur}"))
                    return 0
                    ;;
                -L)
                    COMPREPLY=($(compgen -W "debug info warn error silent" -- "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        dprint__output__file__paths)
            opts="-c -L -h --includes-override --excludes --excludes-override --allow-node-modules --staged --config --config-discovery --plugins --log-level --verbose --help [files]..."
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --includes-override)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --excludes)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --excludes-override)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -c)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config-discovery)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --plugins)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --log-level)
                    COMPREPLY=($(compgen -W "debug info warn error silent" -- "${cur}"))
                    return 0
                    ;;
                -L)
                    COMPREPLY=($(compgen -W "debug info warn error silent" -- "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        dprint__output__format__times)
            opts="-c -L -h --includes-override --excludes --excludes-override --allow-node-modules --allow-no-files --staged --config --config-discovery --plugins --log-level --verbose --help [files]..."
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --includes-override)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --excludes)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --excludes-override)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -c)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config-discovery)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --plugins)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --log-level)
                    COMPREPLY=($(compgen -W "debug info warn error silent" -- "${cur}"))
                    return 0
                    ;;
                -L)
                    COMPREPLY=($(compgen -W "debug info warn error silent" -- "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        dprint__output__resolved__config)
            opts="-c -L -h --config --config-discovery --plugins --log-level --verbose --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -c)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config-discovery)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --plugins)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --log-level)
                    COMPREPLY=($(compgen -W "debug info warn error silent" -- "${cur}"))
                    return 0
                    ;;
                -L)
                    COMPREPLY=($(compgen -W "debug info warn error silent" -- "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        dprint__upgrade)
            opts="-c -L -h --config --config-discovery --plugins --log-level --verbose --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -c)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config-discovery)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --plugins)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --log-level)
                    COMPREPLY=($(compgen -W "debug info warn error silent" -- "${cur}"))
                    return 0
                    ;;
                -L)
                    COMPREPLY=($(compgen -W "debug info warn error silent" -- "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
    esac
}

if [[ "${BASH_VERSINFO[0]}" -eq 4 && "${BASH_VERSINFO[1]}" -ge 4 || "${BASH_VERSINFO[0]}" -gt 4 ]]; then
    complete -F _dprint -o nosort -o bashdefault -o default dprint
else
    complete -F _dprint -o bashdefault -o default dprint
fi
