_zellij() {
    local i cur prev opts cmds
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    cmd=""
    opts=""

    for i in ${COMP_WORDS[@]}
    do
        case "${i}" in
            "$1")
                cmd="zellij"
                ;;
            action)
                cmd+="__action"
                ;;
            are-floating-panes-visible)
                cmd+="__are__floating__panes__visible"
                ;;
            attach)
                cmd+="__attach"
                ;;
            change-floating-pane-coordinates)
                cmd+="__change__floating__pane__coordinates"
                ;;
            clear)
                cmd+="__clear"
                ;;
            close-pane)
                cmd+="__close__pane"
                ;;
            close-tab)
                cmd+="__close__tab"
                ;;
            close-tab-by-id)
                cmd+="__close__tab__by__id"
                ;;
            convert-config)
                cmd+="__convert__config"
                ;;
            convert-layout)
                cmd+="__convert__layout"
                ;;
            convert-theme)
                cmd+="__convert__theme"
                ;;
            current-tab-info)
                cmd+="__current__tab__info"
                ;;
            delete-all-sessions)
                cmd+="__delete__all__sessions"
                ;;
            delete-session)
                cmd+="__delete__session"
                ;;
            detach)
                cmd+="__detach"
                ;;
            dump-layout)
                cmd+="__dump__layout"
                ;;
            dump-screen)
                cmd+="__dump__screen"
                ;;
            edit)
                cmd+="__edit"
                ;;
            edit-scrollback)
                cmd+="__edit__scrollback"
                ;;
            focus-next-pane)
                cmd+="__focus__next__pane"
                ;;
            focus-pane-id)
                cmd+="__focus__pane__id"
                ;;
            focus-previous-pane)
                cmd+="__focus__previous__pane"
                ;;
            go-to-next-tab)
                cmd+="__go__to__next__tab"
                ;;
            go-to-previous-tab)
                cmd+="__go__to__previous__tab"
                ;;
            go-to-tab)
                cmd+="__go__to__tab"
                ;;
            go-to-tab-by-id)
                cmd+="__go__to__tab__by__id"
                ;;
            go-to-tab-name)
                cmd+="__go__to__tab__name"
                ;;
            half-page-scroll-down)
                cmd+="__half__page__scroll__down"
                ;;
            half-page-scroll-up)
                cmd+="__half__page__scroll__up"
                ;;
            help)
                cmd+="__help"
                ;;
            hide-floating-panes)
                cmd+="__hide__floating__panes"
                ;;
            kill-all-sessions)
                cmd+="__kill__all__sessions"
                ;;
            kill-session)
                cmd+="__kill__session"
                ;;
            launch-or-focus-plugin)
                cmd+="__launch__or__focus__plugin"
                ;;
            launch-plugin)
                cmd+="__launch__plugin"
                ;;
            list-aliases)
                cmd+="__list__aliases"
                ;;
            list-clients)
                cmd+="__list__clients"
                ;;
            list-panes)
                cmd+="__list__panes"
                ;;
            list-sessions)
                cmd+="__list__sessions"
                ;;
            list-tabs)
                cmd+="__list__tabs"
                ;;
            move-focus)
                cmd+="__move__focus"
                ;;
            move-focus-or-tab)
                cmd+="__move__focus__or__tab"
                ;;
            move-pane)
                cmd+="__move__pane"
                ;;
            move-pane-backwards)
                cmd+="__move__pane__backwards"
                ;;
            move-tab)
                cmd+="__move__tab"
                ;;
            new-pane)
                cmd+="__new__pane"
                ;;
            new-tab)
                cmd+="__new__tab"
                ;;
            next-swap-layout)
                cmd+="__next__swap__layout"
                ;;
            options)
                cmd+="__options"
                ;;
            override-layout)
                cmd+="__override__layout"
                ;;
            page-scroll-down)
                cmd+="__page__scroll__down"
                ;;
            page-scroll-up)
                cmd+="__page__scroll__up"
                ;;
            paste)
                cmd+="__paste"
                ;;
            pipe)
                cmd+="__pipe"
                ;;
            plugin)
                cmd+="__plugin"
                ;;
            previous-swap-layout)
                cmd+="__previous__swap__layout"
                ;;
            query-tab-names)
                cmd+="__query__tab__names"
                ;;
            rename-pane)
                cmd+="__rename__pane"
                ;;
            rename-session)
                cmd+="__rename__session"
                ;;
            rename-tab)
                cmd+="__rename__tab"
                ;;
            rename-tab-by-id)
                cmd+="__rename__tab__by__id"
                ;;
            resize)
                cmd+="__resize"
                ;;
            run)
                cmd+="__run"
                ;;
            save-session)
                cmd+="__save__session"
                ;;
            scroll-down)
                cmd+="__scroll__down"
                ;;
            scroll-to-bottom)
                cmd+="__scroll__to__bottom"
                ;;
            scroll-to-top)
                cmd+="__scroll__to__top"
                ;;
            scroll-up)
                cmd+="__scroll__up"
                ;;
            send-keys)
                cmd+="__send__keys"
                ;;
            set-dark-theme)
                cmd+="__set__dark__theme"
                ;;
            set-light-theme)
                cmd+="__set__light__theme"
                ;;
            set-pane-borderless)
                cmd+="__set__pane__borderless"
                ;;
            set-pane-color)
                cmd+="__set__pane__color"
                ;;
            setup)
                cmd+="__setup"
                ;;
            show-floating-panes)
                cmd+="__show__floating__panes"
                ;;
            stack-panes)
                cmd+="__stack__panes"
                ;;
            start-or-reload-plugin)
                cmd+="__start__or__reload__plugin"
                ;;
            subscribe)
                cmd+="__subscribe"
                ;;
            switch-mode)
                cmd+="__switch__mode"
                ;;
            switch-session)
                cmd+="__switch__session"
                ;;
            toggle-active-sync-tab)
                cmd+="__toggle__active__sync__tab"
                ;;
            toggle-floating-panes)
                cmd+="__toggle__floating__panes"
                ;;
            toggle-fullscreen)
                cmd+="__toggle__fullscreen"
                ;;
            toggle-pane-borderless)
                cmd+="__toggle__pane__borderless"
                ;;
            toggle-pane-embed-or-floating)
                cmd+="__toggle__pane__embed__or__floating"
                ;;
            toggle-pane-frames)
                cmd+="__toggle__pane__frames"
                ;;
            toggle-pane-pinned)
                cmd+="__toggle__pane__pinned"
                ;;
            toggle-theme)
                cmd+="__toggle__theme"
                ;;
            undo-rename-pane)
                cmd+="__undo__rename__pane"
                ;;
            undo-rename-tab)
                cmd+="__undo__rename__tab"
                ;;
            watch)
                cmd+="__watch"
                ;;
            web)
                cmd+="__web"
                ;;
            write)
                cmd+="__write"
                ;;
            write-chars)
                cmd+="__write__chars"
                ;;
            *)
                ;;
        esac
    done

    case "${cmd}" in
        zellij)
            opts="-h -V -s -l -n -c -d --help --version --max-panes --data-dir --server --session --layout --layout-string --new-session-with-layout --config --config-dir --debug options setup web action list-sessions list-aliases attach watch kill-session delete-session kill-all-sessions delete-all-sessions run plugin edit convert-config convert-layout convert-theme pipe subscribe help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 1 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --max-panes)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --data-dir)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --server)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --session)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -s)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --layout)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -l)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --layout-string)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --new-session-with-layout)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -n)
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
                --config-dir)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__action)
            opts="-h --help write write-chars paste send-keys resize focus-next-pane focus-previous-pane focus-pane-id move-focus move-focus-or-tab move-pane move-pane-backwards clear dump-screen dump-layout save-session edit-scrollback scroll-up scroll-down scroll-to-bottom scroll-to-top page-scroll-up page-scroll-down half-page-scroll-up half-page-scroll-down toggle-fullscreen toggle-pane-frames toggle-active-sync-tab new-pane edit switch-mode toggle-pane-embed-or-floating toggle-floating-panes show-floating-panes hide-floating-panes are-floating-panes-visible close-pane rename-pane undo-rename-pane go-to-next-tab go-to-previous-tab close-tab go-to-tab go-to-tab-name rename-tab undo-rename-tab go-to-tab-by-id close-tab-by-id rename-tab-by-id new-tab move-tab previous-swap-layout next-swap-layout override-layout query-tab-names start-or-reload-plugin launch-or-focus-plugin launch-plugin rename-session pipe list-clients list-panes list-tabs current-tab-info toggle-pane-pinned stack-panes change-floating-pane-coordinates toggle-pane-borderless set-pane-borderless detach set-dark-theme set-light-theme toggle-theme switch-session set-pane-color help"
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
        zellij__action__are__floating__panes__visible)
            opts="-t -h --tab-id --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --tab-id)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -t)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__action__change__floating__pane__coordinates)
            opts="-p -x -y -b -h --pane-id --x --y --width --height --pinned --borderless --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --pane-id)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -p)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --x)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -x)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --y)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -y)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --width)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --height)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --pinned)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --borderless)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                -b)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__action__clear)
            opts="-p -h --pane-id --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --pane-id)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -p)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__action__close__pane)
            opts="-p -h --pane-id --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --pane-id)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -p)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__action__close__tab)
            opts="-t -h --tab-id --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --tab-id)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -t)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__action__close__tab__by__id)
            opts="-h --help <ID>"
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
        zellij__action__current__tab__info)
            opts="-j -h --json --help"
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
        zellij__action__detach)
            opts="-h --help"
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
        zellij__action__dump__layout)
            opts="-h --help"
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
        zellij__action__dump__screen)
            opts="-f -p -a -h --path --full --pane-id --ansi --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --path)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --pane-id)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -p)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__action__edit)
            opts="-d -l -f -i -x -y -b -h --direction --line-number --floating --in-place --close-replaced-pane --cwd --x --y --width --height --pinned --near-current-pane --borderless --tab-id --help <FILE>"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --direction)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -d)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --line-number)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -l)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --cwd)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --x)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -x)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --y)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -y)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --width)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --height)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --pinned)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --borderless)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                -b)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --tab-id)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__action__edit__scrollback)
            opts="-p -a -h --pane-id --ansi --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --pane-id)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -p)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__action__focus__next__pane)
            opts="-h --help"
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
        zellij__action__focus__pane__id)
            opts="-h --help <PANE_ID>"
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
        zellij__action__focus__previous__pane)
            opts="-h --help"
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
        zellij__action__go__to__next__tab)
            opts="-h --help"
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
        zellij__action__go__to__previous__tab)
            opts="-h --help"
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
        zellij__action__go__to__tab)
            opts="-h --help <INDEX>"
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
        zellij__action__go__to__tab__by__id)
            opts="-h --help <ID>"
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
        zellij__action__go__to__tab__name)
            opts="-c -h --create --help <NAME>"
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
        zellij__action__half__page__scroll__down)
            opts="-p -h --pane-id --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --pane-id)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -p)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__action__half__page__scroll__up)
            opts="-p -h --pane-id --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --pane-id)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -p)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__action__help)
            opts="<SUBCOMMAND>..."
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
        zellij__action__hide__floating__panes)
            opts="-t -h --tab-id --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --tab-id)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -t)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__action__launch__or__focus__plugin)
            opts="-f -i -m -c -s -h --floating --in-place --close-replaced-pane --move-to-focused-tab --configuration --skip-plugin-cache --tab-id --help <URL>"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --configuration)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -c)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --tab-id)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__action__launch__plugin)
            opts="-f -i -c -s -h --floating --in-place --close-replaced-pane --configuration --skip-plugin-cache --tab-id --help <URL>"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --configuration)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -c)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --tab-id)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__action__list__clients)
            opts="-h --help"
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
        zellij__action__list__panes)
            opts="-t -c -s -g -a -j -h --tab --command --state --geometry --all --json --help"
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
        zellij__action__list__tabs)
            opts="-s -d -p -l -a -j -h --state --dimensions --panes --layout --all --json --help"
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
        zellij__action__move__focus)
            opts="-h --help <DIRECTION>"
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
        zellij__action__move__focus__or__tab)
            opts="-h --help <DIRECTION>"
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
        zellij__action__move__pane)
            opts="-p -h --pane-id --help <DIRECTION>"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --pane-id)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -p)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__action__move__pane__backwards)
            opts="-p -h --pane-id --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --pane-id)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -p)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__action__move__tab)
            opts="-t -h --tab-id --help <DIRECTION>"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --tab-id)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -t)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__action__new__pane)
            opts="-d -p -f -i -n -c -s -x -y -b -h --direction --plugin --cwd --floating --in-place --close-replaced-pane --name --close-on-exit --start-suspended --configuration --skip-plugin-cache --x --y --width --height --pinned --stacked --blocking --block-until-exit-success --block-until-exit-failure --block-until-exit --near-current-pane --borderless --tab-id --help <COMMAND>..."
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --direction)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -d)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --plugin)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -p)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --cwd)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --name)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -n)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --configuration)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --x)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -x)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --y)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -y)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --width)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --height)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --pinned)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --borderless)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --tab-id)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__action__new__tab)
            opts="-l -n -c -h --layout --layout-string --layout-dir --name --cwd --initial-plugin --close-on-exit --start-suspended --block-until-exit-success --block-until-exit-failure --block-until-exit --help <INITIAL_COMMAND>..."
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --layout)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -l)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --layout-string)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --layout-dir)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --name)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -n)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --cwd)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -c)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --initial-plugin)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__action__next__swap__layout)
            opts="-t -h --tab-id --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --tab-id)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -t)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__action__override__layout)
            opts="-h --layout-string --layout-dir --retain-existing-terminal-panes --retain-existing-plugin-panes --apply-only-to-active-tab --help <LAYOUT>"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --layout-string)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --layout-dir)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__action__page__scroll__down)
            opts="-p -h --pane-id --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --pane-id)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -p)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__action__page__scroll__up)
            opts="-p -h --pane-id --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --pane-id)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -p)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__action__paste)
            opts="-p -h --pane-id --help <CHARS>"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --pane-id)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -p)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__action__pipe)
            opts="-n -a -p -c -l -s -f -i -w -t -h --name --args --plugin --plugin-configuration --force-launch-plugin --skip-plugin-cache --floating-plugin --in-place-plugin --plugin-cwd --plugin-title --help <PAYLOAD>"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --name)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -n)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --args)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -a)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --plugin)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -p)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --plugin-configuration)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -c)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --floating-plugin)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                -f)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --in-place-plugin)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                -i)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --plugin-cwd)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -w)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --plugin-title)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -t)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__action__previous__swap__layout)
            opts="-t -h --tab-id --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --tab-id)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -t)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__action__query__tab__names)
            opts="-h --help"
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
        zellij__action__rename__pane)
            opts="-p -h --pane-id --help <NAME>"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --pane-id)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -p)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__action__rename__session)
            opts="-h --help <NAME>"
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
        zellij__action__rename__tab)
            opts="-t -h --tab-id --help <NAME>"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --tab-id)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -t)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__action__rename__tab__by__id)
            opts="-h --help <ID> <NAME>"
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
        zellij__action__resize)
            opts="-p -h --pane-id --help <RESIZE> <DIRECTION>"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --pane-id)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -p)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__action__save__session)
            opts="-h --help"
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
        zellij__action__scroll__down)
            opts="-p -h --pane-id --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --pane-id)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -p)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__action__scroll__to__bottom)
            opts="-p -h --pane-id --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --pane-id)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -p)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__action__scroll__to__top)
            opts="-p -h --pane-id --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --pane-id)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -p)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__action__scroll__up)
            opts="-p -h --pane-id --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --pane-id)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -p)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__action__send__keys)
            opts="-p -h --pane-id --help <KEYS>..."
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --pane-id)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -p)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__action__set__dark__theme)
            opts="-h --help"
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
        zellij__action__set__light__theme)
            opts="-h --help"
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
        zellij__action__set__pane__borderless)
            opts="-p -b -h --pane-id --borderless --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --pane-id)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -p)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__action__set__pane__color)
            opts="-p -h --pane-id --fg --bg --reset --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --pane-id)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -p)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --fg)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --bg)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__action__show__floating__panes)
            opts="-t -h --tab-id --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --tab-id)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -t)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__action__stack__panes)
            opts="-h --help <PANE_IDS>..."
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
        zellij__action__start__or__reload__plugin)
            opts="-c -h --configuration --help <URL>"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --configuration)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -c)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__action__switch__mode)
            opts="-h --help <INPUT_MODE>"
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
        zellij__action__switch__session)
            opts="-l -c -h --tab-position --pane-id --layout --layout-string --layout-dir --cwd --help <NAME>"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --tab-position)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --pane-id)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --layout)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -l)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --layout-string)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --layout-dir)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --cwd)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -c)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__action__toggle__active__sync__tab)
            opts="-t -h --tab-id --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --tab-id)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -t)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__action__toggle__floating__panes)
            opts="-t -h --tab-id --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --tab-id)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -t)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__action__toggle__fullscreen)
            opts="-p -h --pane-id --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --pane-id)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -p)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__action__toggle__pane__borderless)
            opts="-p -h --pane-id --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --pane-id)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -p)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__action__toggle__pane__embed__or__floating)
            opts="-p -h --pane-id --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --pane-id)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -p)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__action__toggle__pane__frames)
            opts="-h --help"
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
        zellij__action__toggle__pane__pinned)
            opts="-p -h --pane-id --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --pane-id)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -p)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__action__toggle__theme)
            opts="-h --help"
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
        zellij__action__undo__rename__pane)
            opts="-p -h --pane-id --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --pane-id)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -p)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__action__undo__rename__tab)
            opts="-t -h --tab-id --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --tab-id)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -t)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__action__write)
            opts="-p -h --pane-id --help <BYTES>..."
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --pane-id)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -p)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__action__write__chars)
            opts="-p -h --pane-id --help <CHARS>"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --pane-id)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -p)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__attach)
            opts="-c -b -f -t -r -h --create --create-background --index --force-run-commands --token --remember --forget --ca-cert --insecure --help <SESSION_NAME> options help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --index)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --token)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -t)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --ca-cert)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__attach__help)
            opts="<SUBCOMMAND>..."
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
        zellij__attach__options)
            opts="-h --simplified-ui --theme --theme-dark --theme-light --default-mode --default-shell --default-cwd --default-layout --layout-dir --theme-dir --mouse-mode --pane-frames --mirror-session --on-force-close --scroll-buffer-size --copy-command --copy-clipboard --copy-on-select --osc8-hyperlinks --scrollback-editor --session-name --attach-to-session --auto-layout --session-serialization --serialize-pane-viewport --scrollback-lines-to-serialize --styled-underlines --serialization-interval --disable-session-metadata --support-kitty-keyboard-protocol --web-server --web-sharing --stacked-resize --show-startup-tips --show-release-notes --advanced-mouse-actions --mouse-hover-effects --visual-bell --focus-follows-mouse --mouse-click-through --post-command-discovery-hook --client-async-worker-tasks --help <WEB_SERVER_IP> <WEB_SERVER_PORT> <WEB_SERVER_CERT> <WEB_SERVER_KEY> <ENFORCE_HTTPS_FOR_LOCALHOST>"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --simplified-ui)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --theme)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --theme-dark)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --theme-light)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --default-mode)
                    COMPREPLY=($(compgen -W "normal locked resize pane tab scroll enter-search search rename-tab rename-pane session move prompt tmux" -- "${cur}"))
                    return 0
                    ;;
                --default-shell)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --default-cwd)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --default-layout)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --layout-dir)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --theme-dir)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --mouse-mode)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --pane-frames)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --mirror-session)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --on-force-close)
                    COMPREPLY=($(compgen -W "quit detach" -- "${cur}"))
                    return 0
                    ;;
                --scroll-buffer-size)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --copy-command)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --copy-clipboard)
                    COMPREPLY=($(compgen -W "system primary" -- "${cur}"))
                    return 0
                    ;;
                --copy-on-select)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --osc8-hyperlinks)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --scrollback-editor)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --session-name)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --attach-to-session)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --auto-layout)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --session-serialization)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --serialize-pane-viewport)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --scrollback-lines-to-serialize)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --styled-underlines)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --serialization-interval)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --disable-session-metadata)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --support-kitty-keyboard-protocol)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --web-server)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --web-sharing)
                    COMPREPLY=($(compgen -W "on off disabled" -- "${cur}"))
                    return 0
                    ;;
                --stacked-resize)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --show-startup-tips)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --show-release-notes)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --advanced-mouse-actions)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --mouse-hover-effects)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --visual-bell)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --focus-follows-mouse)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --mouse-click-through)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --post-command-discovery-hook)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --client-async-worker-tasks)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__convert__config)
            opts="-h --help <OLD_CONFIG_FILE>"
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
        zellij__convert__layout)
            opts="-h --help <OLD_LAYOUT_FILE>"
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
        zellij__convert__theme)
            opts="-h --help <OLD_THEME_FILE>"
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
        zellij__delete__all__sessions)
            opts="-y -f -h --yes --force --help"
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
        zellij__delete__session)
            opts="-f -h --force --help <TARGET_SESSION>"
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
        zellij__edit)
            opts="-l -d -i -f -x -y -b -h --line-number --direction --in-place --close-replaced-pane --floating --cwd --x --y --width --height --pinned --near-current-pane --borderless --tab-id --help <FILE>"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --line-number)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -l)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --direction)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -d)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --cwd)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --x)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -x)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --y)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -y)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --width)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --height)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --pinned)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --borderless)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                -b)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --tab-id)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__help)
            opts="<SUBCOMMAND>..."
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
        zellij__kill__all__sessions)
            opts="-y -h --yes --help"
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
        zellij__kill__session)
            opts="-h --help <TARGET_SESSION>"
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
        zellij__list__aliases)
            opts="-h --help"
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
        zellij__list__sessions)
            opts="-n -s -r -h --no-formatting --short --reverse --help"
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
        zellij__options)
            opts="-h --simplified-ui --theme --theme-dark --theme-light --default-mode --default-shell --default-cwd --default-layout --layout-dir --theme-dir --mouse-mode --pane-frames --mirror-session --on-force-close --scroll-buffer-size --copy-command --copy-clipboard --copy-on-select --osc8-hyperlinks --scrollback-editor --session-name --attach-to-session --auto-layout --session-serialization --serialize-pane-viewport --scrollback-lines-to-serialize --styled-underlines --serialization-interval --disable-session-metadata --support-kitty-keyboard-protocol --web-server --web-sharing --stacked-resize --show-startup-tips --show-release-notes --advanced-mouse-actions --mouse-hover-effects --visual-bell --focus-follows-mouse --mouse-click-through --post-command-discovery-hook --client-async-worker-tasks --help <WEB_SERVER_IP> <WEB_SERVER_PORT> <WEB_SERVER_CERT> <WEB_SERVER_KEY> <ENFORCE_HTTPS_FOR_LOCALHOST>"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --simplified-ui)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --theme)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --theme-dark)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --theme-light)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --default-mode)
                    COMPREPLY=($(compgen -W "normal locked resize pane tab scroll enter-search search rename-tab rename-pane session move prompt tmux" -- "${cur}"))
                    return 0
                    ;;
                --default-shell)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --default-cwd)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --default-layout)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --layout-dir)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --theme-dir)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --mouse-mode)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --pane-frames)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --mirror-session)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --on-force-close)
                    COMPREPLY=($(compgen -W "quit detach" -- "${cur}"))
                    return 0
                    ;;
                --scroll-buffer-size)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --copy-command)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --copy-clipboard)
                    COMPREPLY=($(compgen -W "system primary" -- "${cur}"))
                    return 0
                    ;;
                --copy-on-select)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --osc8-hyperlinks)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --scrollback-editor)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --session-name)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --attach-to-session)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --auto-layout)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --session-serialization)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --serialize-pane-viewport)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --scrollback-lines-to-serialize)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --styled-underlines)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --serialization-interval)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --disable-session-metadata)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --support-kitty-keyboard-protocol)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --web-server)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --web-sharing)
                    COMPREPLY=($(compgen -W "on off disabled" -- "${cur}"))
                    return 0
                    ;;
                --stacked-resize)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --show-startup-tips)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --show-release-notes)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --advanced-mouse-actions)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --mouse-hover-effects)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --visual-bell)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --focus-follows-mouse)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --mouse-click-through)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --post-command-discovery-hook)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --client-async-worker-tasks)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__pipe)
            opts="-n -a -p -c -h --name --args --plugin --plugin-configuration --help <PAYLOAD>"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --name)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -n)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --args)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -a)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --plugin)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -p)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --plugin-configuration)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -c)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__plugin)
            opts="-c -f -i -s -x -y -b -h --configuration --floating --in-place --close-replaced-pane --skip-plugin-cache --x --y --width --height --pinned --borderless --tab-id --help <URL>"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --configuration)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -c)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --x)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -x)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --y)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -y)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --width)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --height)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --pinned)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --borderless)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                -b)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --tab-id)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__run)
            opts="-d -f -i -n -c -s -x -y -b -h --direction --cwd --floating --in-place --close-replaced-pane --name --close-on-exit --start-suspended --x --y --width --height --pinned --stacked --blocking --block-until-exit-success --block-until-exit-failure --block-until-exit --near-current-pane --borderless --tab-id --help <COMMAND>..."
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --direction)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -d)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --cwd)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --name)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -n)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --x)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -x)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --y)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -y)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --width)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --height)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --pinned)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --borderless)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                -b)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --tab-id)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__setup)
            opts="-h --dump-config --clean --check --dump-layout --dump-swap-layout --dump-plugins --generate-completion --generate-auto-start --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --dump-layout)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --dump-swap-layout)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --dump-plugins)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --generate-completion)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --generate-auto-start)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__subscribe)
            opts="-p -s -f -h --pane-id --scrollback --format --ansi --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --pane-id)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -p)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --scrollback)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -s)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --format)
                    COMPREPLY=($(compgen -W "raw json" -- "${cur}"))
                    return 0
                    ;;
                -f)
                    COMPREPLY=($(compgen -W "raw json" -- "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        zellij__watch)
            opts="-h --help <SESSION_NAME>"
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
        zellij__web)
            opts="-d -h --start --stop --status --timeout --daemonize --server-startup-timeout --create-token --token-name --create-read-only-token --revoke-token --revoke-all-tokens --list-tokens --ip --port --cert --key --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --timeout)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --server-startup-timeout)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --token-name)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --revoke-token)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --ip)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --port)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --cert)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --key)
                    COMPREPLY=($(compgen -f "${cur}"))
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

complete -F _zellij -o bashdefault -o default zellij
function zr () { zellij run --name "$*" -- bash -ic "$*";}
function zrf () { zellij run --name "$*" --floating -- bash -ic "$*";}
function zri () { zellij run --name "$*" --in-place -- bash -ic "$*";}
function ze () { zellij edit "$*";}
function zef () { zellij edit --floating "$*";}
function zei () { zellij edit --in-place "$*";}
function zpipe () { 
  if [ -z "$1" ]; then
    zellij pipe;
  else 
    zellij pipe -p $1;
  fi
}