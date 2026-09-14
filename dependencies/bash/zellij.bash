_zellij() {
    local i cur prev opts cmd
    COMPREPLY=()
    if [[ "${BASH_VERSINFO[0]}" -ge 4 ]]; then
        cur="$2"
    else
        cur="${COMP_WORDS[COMP_CWORD]}"
    fi
    prev="$3"
    cmd=""
    opts=""

    for i in "${COMP_WORDS[@]:0:COMP_CWORD}"
    do
        case "${cmd},${i}" in
            ",$1")
                cmd="zellij"
                ;;
            zellij,a)
                cmd="zellij__subcmd__attach"
                ;;
            zellij,ac)
                cmd="zellij__subcmd__action"
                ;;
            zellij,action)
                cmd="zellij__subcmd__action"
                ;;
            zellij,attach)
                cmd="zellij__subcmd__attach"
                ;;
            zellij,d)
                cmd="zellij__subcmd__delete__subcmd__session"
                ;;
            zellij,da)
                cmd="zellij__subcmd__delete__subcmd__all__subcmd__sessions"
                ;;
            zellij,delete-all-sessions)
                cmd="zellij__subcmd__delete__subcmd__all__subcmd__sessions"
                ;;
            zellij,delete-session)
                cmd="zellij__subcmd__delete__subcmd__session"
                ;;
            zellij,e)
                cmd="zellij__subcmd__edit"
                ;;
            zellij,edit)
                cmd="zellij__subcmd__edit"
                ;;
            zellij,help)
                cmd="zellij__subcmd__help"
                ;;
            zellij,k)
                cmd="zellij__subcmd__kill__subcmd__session"
                ;;
            zellij,ka)
                cmd="zellij__subcmd__kill__subcmd__all__subcmd__sessions"
                ;;
            zellij,kill-all-sessions)
                cmd="zellij__subcmd__kill__subcmd__all__subcmd__sessions"
                ;;
            zellij,kill-session)
                cmd="zellij__subcmd__kill__subcmd__session"
                ;;
            zellij,la)
                cmd="zellij__subcmd__list__subcmd__aliases"
                ;;
            zellij,list-aliases)
                cmd="zellij__subcmd__list__subcmd__aliases"
                ;;
            zellij,list-sessions)
                cmd="zellij__subcmd__list__subcmd__sessions"
                ;;
            zellij,ls)
                cmd="zellij__subcmd__list__subcmd__sessions"
                ;;
            zellij,options)
                cmd="zellij__subcmd__options"
                ;;
            zellij,p)
                cmd="zellij__subcmd__plugin"
                ;;
            zellij,pipe)
                cmd="zellij__subcmd__pipe"
                ;;
            zellij,plugin)
                cmd="zellij__subcmd__plugin"
                ;;
            zellij,r)
                cmd="zellij__subcmd__run"
                ;;
            zellij,run)
                cmd="zellij__subcmd__run"
                ;;
            zellij,setup)
                cmd="zellij__subcmd__setup"
                ;;
            zellij,subscribe)
                cmd="zellij__subcmd__subscribe"
                ;;
            zellij,w)
                cmd="zellij__subcmd__watch"
                ;;
            zellij,watch)
                cmd="zellij__subcmd__watch"
                ;;
            zellij,web)
                cmd="zellij__subcmd__web"
                ;;
            zellij__subcmd__action,are-floating-panes-visible)
                cmd="zellij__subcmd__action__subcmd__are__subcmd__floating__subcmd__panes__subcmd__visible"
                ;;
            zellij__subcmd__action,change-floating-pane-coordinates)
                cmd="zellij__subcmd__action__subcmd__change__subcmd__floating__subcmd__pane__subcmd__coordinates"
                ;;
            zellij__subcmd__action,clear)
                cmd="zellij__subcmd__action__subcmd__clear"
                ;;
            zellij__subcmd__action,close-pane)
                cmd="zellij__subcmd__action__subcmd__close__subcmd__pane"
                ;;
            zellij__subcmd__action,close-tab)
                cmd="zellij__subcmd__action__subcmd__close__subcmd__tab"
                ;;
            zellij__subcmd__action,close-tab-by-id)
                cmd="zellij__subcmd__action__subcmd__close__subcmd__tab__subcmd__by__subcmd__id"
                ;;
            zellij__subcmd__action,current-tab-info)
                cmd="zellij__subcmd__action__subcmd__current__subcmd__tab__subcmd__info"
                ;;
            zellij__subcmd__action,detach)
                cmd="zellij__subcmd__action__subcmd__detach"
                ;;
            zellij__subcmd__action,dump-layout)
                cmd="zellij__subcmd__action__subcmd__dump__subcmd__layout"
                ;;
            zellij__subcmd__action,dump-screen)
                cmd="zellij__subcmd__action__subcmd__dump__subcmd__screen"
                ;;
            zellij__subcmd__action,edit)
                cmd="zellij__subcmd__action__subcmd__edit"
                ;;
            zellij__subcmd__action,edit-scrollback)
                cmd="zellij__subcmd__action__subcmd__edit__subcmd__scrollback"
                ;;
            zellij__subcmd__action,focus-last-pane)
                cmd="zellij__subcmd__action__subcmd__focus__subcmd__last__subcmd__pane"
                ;;
            zellij__subcmd__action,focus-next-pane)
                cmd="zellij__subcmd__action__subcmd__focus__subcmd__next__subcmd__pane"
                ;;
            zellij__subcmd__action,focus-pane-id)
                cmd="zellij__subcmd__action__subcmd__focus__subcmd__pane__subcmd__id"
                ;;
            zellij__subcmd__action,focus-previous-pane)
                cmd="zellij__subcmd__action__subcmd__focus__subcmd__previous__subcmd__pane"
                ;;
            zellij__subcmd__action,go-to-next-tab)
                cmd="zellij__subcmd__action__subcmd__go__subcmd__to__subcmd__next__subcmd__tab"
                ;;
            zellij__subcmd__action,go-to-previous-tab)
                cmd="zellij__subcmd__action__subcmd__go__subcmd__to__subcmd__previous__subcmd__tab"
                ;;
            zellij__subcmd__action,go-to-tab)
                cmd="zellij__subcmd__action__subcmd__go__subcmd__to__subcmd__tab"
                ;;
            zellij__subcmd__action,go-to-tab-by-id)
                cmd="zellij__subcmd__action__subcmd__go__subcmd__to__subcmd__tab__subcmd__by__subcmd__id"
                ;;
            zellij__subcmd__action,go-to-tab-name)
                cmd="zellij__subcmd__action__subcmd__go__subcmd__to__subcmd__tab__subcmd__name"
                ;;
            zellij__subcmd__action,half-page-scroll-down)
                cmd="zellij__subcmd__action__subcmd__half__subcmd__page__subcmd__scroll__subcmd__down"
                ;;
            zellij__subcmd__action,half-page-scroll-up)
                cmd="zellij__subcmd__action__subcmd__half__subcmd__page__subcmd__scroll__subcmd__up"
                ;;
            zellij__subcmd__action,help)
                cmd="zellij__subcmd__action__subcmd__help"
                ;;
            zellij__subcmd__action,hide-floating-panes)
                cmd="zellij__subcmd__action__subcmd__hide__subcmd__floating__subcmd__panes"
                ;;
            zellij__subcmd__action,launch-or-focus-plugin)
                cmd="zellij__subcmd__action__subcmd__launch__subcmd__or__subcmd__focus__subcmd__plugin"
                ;;
            zellij__subcmd__action,launch-plugin)
                cmd="zellij__subcmd__action__subcmd__launch__subcmd__plugin"
                ;;
            zellij__subcmd__action,list-clients)
                cmd="zellij__subcmd__action__subcmd__list__subcmd__clients"
                ;;
            zellij__subcmd__action,list-panes)
                cmd="zellij__subcmd__action__subcmd__list__subcmd__panes"
                ;;
            zellij__subcmd__action,list-tabs)
                cmd="zellij__subcmd__action__subcmd__list__subcmd__tabs"
                ;;
            zellij__subcmd__action,move-focus)
                cmd="zellij__subcmd__action__subcmd__move__subcmd__focus"
                ;;
            zellij__subcmd__action,move-focus-or-tab)
                cmd="zellij__subcmd__action__subcmd__move__subcmd__focus__subcmd__or__subcmd__tab"
                ;;
            zellij__subcmd__action,move-pane)
                cmd="zellij__subcmd__action__subcmd__move__subcmd__pane"
                ;;
            zellij__subcmd__action,move-pane-backwards)
                cmd="zellij__subcmd__action__subcmd__move__subcmd__pane__subcmd__backwards"
                ;;
            zellij__subcmd__action,move-tab)
                cmd="zellij__subcmd__action__subcmd__move__subcmd__tab"
                ;;
            zellij__subcmd__action,new-pane)
                cmd="zellij__subcmd__action__subcmd__new__subcmd__pane"
                ;;
            zellij__subcmd__action,new-tab)
                cmd="zellij__subcmd__action__subcmd__new__subcmd__tab"
                ;;
            zellij__subcmd__action,next-swap-layout)
                cmd="zellij__subcmd__action__subcmd__next__subcmd__swap__subcmd__layout"
                ;;
            zellij__subcmd__action,override-layout)
                cmd="zellij__subcmd__action__subcmd__override__subcmd__layout"
                ;;
            zellij__subcmd__action,page-scroll-down)
                cmd="zellij__subcmd__action__subcmd__page__subcmd__scroll__subcmd__down"
                ;;
            zellij__subcmd__action,page-scroll-up)
                cmd="zellij__subcmd__action__subcmd__page__subcmd__scroll__subcmd__up"
                ;;
            zellij__subcmd__action,paste)
                cmd="zellij__subcmd__action__subcmd__paste"
                ;;
            zellij__subcmd__action,pipe)
                cmd="zellij__subcmd__action__subcmd__pipe"
                ;;
            zellij__subcmd__action,previous-swap-layout)
                cmd="zellij__subcmd__action__subcmd__previous__subcmd__swap__subcmd__layout"
                ;;
            zellij__subcmd__action,query-tab-names)
                cmd="zellij__subcmd__action__subcmd__query__subcmd__tab__subcmd__names"
                ;;
            zellij__subcmd__action,rename-pane)
                cmd="zellij__subcmd__action__subcmd__rename__subcmd__pane"
                ;;
            zellij__subcmd__action,rename-session)
                cmd="zellij__subcmd__action__subcmd__rename__subcmd__session"
                ;;
            zellij__subcmd__action,rename-tab)
                cmd="zellij__subcmd__action__subcmd__rename__subcmd__tab"
                ;;
            zellij__subcmd__action,rename-tab-by-id)
                cmd="zellij__subcmd__action__subcmd__rename__subcmd__tab__subcmd__by__subcmd__id"
                ;;
            zellij__subcmd__action,resize)
                cmd="zellij__subcmd__action__subcmd__resize"
                ;;
            zellij__subcmd__action,save-session)
                cmd="zellij__subcmd__action__subcmd__save__subcmd__session"
                ;;
            zellij__subcmd__action,scroll-down)
                cmd="zellij__subcmd__action__subcmd__scroll__subcmd__down"
                ;;
            zellij__subcmd__action,scroll-to-bottom)
                cmd="zellij__subcmd__action__subcmd__scroll__subcmd__to__subcmd__bottom"
                ;;
            zellij__subcmd__action,scroll-to-top)
                cmd="zellij__subcmd__action__subcmd__scroll__subcmd__to__subcmd__top"
                ;;
            zellij__subcmd__action,scroll-up)
                cmd="zellij__subcmd__action__subcmd__scroll__subcmd__up"
                ;;
            zellij__subcmd__action,send-keys)
                cmd="zellij__subcmd__action__subcmd__send__subcmd__keys"
                ;;
            zellij__subcmd__action,set-dark-theme)
                cmd="zellij__subcmd__action__subcmd__set__subcmd__dark__subcmd__theme"
                ;;
            zellij__subcmd__action,set-light-theme)
                cmd="zellij__subcmd__action__subcmd__set__subcmd__light__subcmd__theme"
                ;;
            zellij__subcmd__action,set-pane-borderless)
                cmd="zellij__subcmd__action__subcmd__set__subcmd__pane__subcmd__borderless"
                ;;
            zellij__subcmd__action,set-pane-color)
                cmd="zellij__subcmd__action__subcmd__set__subcmd__pane__subcmd__color"
                ;;
            zellij__subcmd__action,set-pane-frame-style)
                cmd="zellij__subcmd__action__subcmd__set__subcmd__pane__subcmd__frame__subcmd__style"
                ;;
            zellij__subcmd__action,show-floating-panes)
                cmd="zellij__subcmd__action__subcmd__show__subcmd__floating__subcmd__panes"
                ;;
            zellij__subcmd__action,stack-panes)
                cmd="zellij__subcmd__action__subcmd__stack__subcmd__panes"
                ;;
            zellij__subcmd__action,start-or-reload-plugin)
                cmd="zellij__subcmd__action__subcmd__start__subcmd__or__subcmd__reload__subcmd__plugin"
                ;;
            zellij__subcmd__action,switch-mode)
                cmd="zellij__subcmd__action__subcmd__switch__subcmd__mode"
                ;;
            zellij__subcmd__action,switch-session)
                cmd="zellij__subcmd__action__subcmd__switch__subcmd__session"
                ;;
            zellij__subcmd__action,toggle-active-sync-tab)
                cmd="zellij__subcmd__action__subcmd__toggle__subcmd__active__subcmd__sync__subcmd__tab"
                ;;
            zellij__subcmd__action,toggle-floating-panes)
                cmd="zellij__subcmd__action__subcmd__toggle__subcmd__floating__subcmd__panes"
                ;;
            zellij__subcmd__action,toggle-fullscreen)
                cmd="zellij__subcmd__action__subcmd__toggle__subcmd__fullscreen"
                ;;
            zellij__subcmd__action,toggle-no-ui-fullscreen)
                cmd="zellij__subcmd__action__subcmd__toggle__subcmd__no__subcmd__ui__subcmd__fullscreen"
                ;;
            zellij__subcmd__action,toggle-pane-borderless)
                cmd="zellij__subcmd__action__subcmd__toggle__subcmd__pane__subcmd__borderless"
                ;;
            zellij__subcmd__action,toggle-pane-embed-or-floating)
                cmd="zellij__subcmd__action__subcmd__toggle__subcmd__pane__subcmd__embed__subcmd__or__subcmd__floating"
                ;;
            zellij__subcmd__action,toggle-pane-frames)
                cmd="zellij__subcmd__action__subcmd__toggle__subcmd__pane__subcmd__frames"
                ;;
            zellij__subcmd__action,toggle-pane-pinned)
                cmd="zellij__subcmd__action__subcmd__toggle__subcmd__pane__subcmd__pinned"
                ;;
            zellij__subcmd__action,toggle-theme)
                cmd="zellij__subcmd__action__subcmd__toggle__subcmd__theme"
                ;;
            zellij__subcmd__action,undo-rename-pane)
                cmd="zellij__subcmd__action__subcmd__undo__subcmd__rename__subcmd__pane"
                ;;
            zellij__subcmd__action,undo-rename-tab)
                cmd="zellij__subcmd__action__subcmd__undo__subcmd__rename__subcmd__tab"
                ;;
            zellij__subcmd__action,write)
                cmd="zellij__subcmd__action__subcmd__write"
                ;;
            zellij__subcmd__action,write-chars)
                cmd="zellij__subcmd__action__subcmd__write__subcmd__chars"
                ;;
            zellij__subcmd__action__subcmd__help,are-floating-panes-visible)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__are__subcmd__floating__subcmd__panes__subcmd__visible"
                ;;
            zellij__subcmd__action__subcmd__help,change-floating-pane-coordinates)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__change__subcmd__floating__subcmd__pane__subcmd__coordinates"
                ;;
            zellij__subcmd__action__subcmd__help,clear)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__clear"
                ;;
            zellij__subcmd__action__subcmd__help,close-pane)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__close__subcmd__pane"
                ;;
            zellij__subcmd__action__subcmd__help,close-tab)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__close__subcmd__tab"
                ;;
            zellij__subcmd__action__subcmd__help,close-tab-by-id)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__close__subcmd__tab__subcmd__by__subcmd__id"
                ;;
            zellij__subcmd__action__subcmd__help,current-tab-info)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__current__subcmd__tab__subcmd__info"
                ;;
            zellij__subcmd__action__subcmd__help,detach)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__detach"
                ;;
            zellij__subcmd__action__subcmd__help,dump-layout)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__dump__subcmd__layout"
                ;;
            zellij__subcmd__action__subcmd__help,dump-screen)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__dump__subcmd__screen"
                ;;
            zellij__subcmd__action__subcmd__help,edit)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__edit"
                ;;
            zellij__subcmd__action__subcmd__help,edit-scrollback)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__edit__subcmd__scrollback"
                ;;
            zellij__subcmd__action__subcmd__help,focus-last-pane)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__focus__subcmd__last__subcmd__pane"
                ;;
            zellij__subcmd__action__subcmd__help,focus-next-pane)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__focus__subcmd__next__subcmd__pane"
                ;;
            zellij__subcmd__action__subcmd__help,focus-pane-id)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__focus__subcmd__pane__subcmd__id"
                ;;
            zellij__subcmd__action__subcmd__help,focus-previous-pane)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__focus__subcmd__previous__subcmd__pane"
                ;;
            zellij__subcmd__action__subcmd__help,go-to-next-tab)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__go__subcmd__to__subcmd__next__subcmd__tab"
                ;;
            zellij__subcmd__action__subcmd__help,go-to-previous-tab)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__go__subcmd__to__subcmd__previous__subcmd__tab"
                ;;
            zellij__subcmd__action__subcmd__help,go-to-tab)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__go__subcmd__to__subcmd__tab"
                ;;
            zellij__subcmd__action__subcmd__help,go-to-tab-by-id)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__go__subcmd__to__subcmd__tab__subcmd__by__subcmd__id"
                ;;
            zellij__subcmd__action__subcmd__help,go-to-tab-name)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__go__subcmd__to__subcmd__tab__subcmd__name"
                ;;
            zellij__subcmd__action__subcmd__help,half-page-scroll-down)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__half__subcmd__page__subcmd__scroll__subcmd__down"
                ;;
            zellij__subcmd__action__subcmd__help,half-page-scroll-up)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__half__subcmd__page__subcmd__scroll__subcmd__up"
                ;;
            zellij__subcmd__action__subcmd__help,help)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__help"
                ;;
            zellij__subcmd__action__subcmd__help,hide-floating-panes)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__hide__subcmd__floating__subcmd__panes"
                ;;
            zellij__subcmd__action__subcmd__help,launch-or-focus-plugin)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__launch__subcmd__or__subcmd__focus__subcmd__plugin"
                ;;
            zellij__subcmd__action__subcmd__help,launch-plugin)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__launch__subcmd__plugin"
                ;;
            zellij__subcmd__action__subcmd__help,list-clients)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__list__subcmd__clients"
                ;;
            zellij__subcmd__action__subcmd__help,list-panes)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__list__subcmd__panes"
                ;;
            zellij__subcmd__action__subcmd__help,list-tabs)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__list__subcmd__tabs"
                ;;
            zellij__subcmd__action__subcmd__help,move-focus)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__move__subcmd__focus"
                ;;
            zellij__subcmd__action__subcmd__help,move-focus-or-tab)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__move__subcmd__focus__subcmd__or__subcmd__tab"
                ;;
            zellij__subcmd__action__subcmd__help,move-pane)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__move__subcmd__pane"
                ;;
            zellij__subcmd__action__subcmd__help,move-pane-backwards)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__move__subcmd__pane__subcmd__backwards"
                ;;
            zellij__subcmd__action__subcmd__help,move-tab)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__move__subcmd__tab"
                ;;
            zellij__subcmd__action__subcmd__help,new-pane)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__new__subcmd__pane"
                ;;
            zellij__subcmd__action__subcmd__help,new-tab)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__new__subcmd__tab"
                ;;
            zellij__subcmd__action__subcmd__help,next-swap-layout)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__next__subcmd__swap__subcmd__layout"
                ;;
            zellij__subcmd__action__subcmd__help,override-layout)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__override__subcmd__layout"
                ;;
            zellij__subcmd__action__subcmd__help,page-scroll-down)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__page__subcmd__scroll__subcmd__down"
                ;;
            zellij__subcmd__action__subcmd__help,page-scroll-up)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__page__subcmd__scroll__subcmd__up"
                ;;
            zellij__subcmd__action__subcmd__help,paste)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__paste"
                ;;
            zellij__subcmd__action__subcmd__help,pipe)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__pipe"
                ;;
            zellij__subcmd__action__subcmd__help,previous-swap-layout)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__previous__subcmd__swap__subcmd__layout"
                ;;
            zellij__subcmd__action__subcmd__help,query-tab-names)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__query__subcmd__tab__subcmd__names"
                ;;
            zellij__subcmd__action__subcmd__help,rename-pane)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__rename__subcmd__pane"
                ;;
            zellij__subcmd__action__subcmd__help,rename-session)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__rename__subcmd__session"
                ;;
            zellij__subcmd__action__subcmd__help,rename-tab)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__rename__subcmd__tab"
                ;;
            zellij__subcmd__action__subcmd__help,rename-tab-by-id)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__rename__subcmd__tab__subcmd__by__subcmd__id"
                ;;
            zellij__subcmd__action__subcmd__help,resize)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__resize"
                ;;
            zellij__subcmd__action__subcmd__help,save-session)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__save__subcmd__session"
                ;;
            zellij__subcmd__action__subcmd__help,scroll-down)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__scroll__subcmd__down"
                ;;
            zellij__subcmd__action__subcmd__help,scroll-to-bottom)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__scroll__subcmd__to__subcmd__bottom"
                ;;
            zellij__subcmd__action__subcmd__help,scroll-to-top)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__scroll__subcmd__to__subcmd__top"
                ;;
            zellij__subcmd__action__subcmd__help,scroll-up)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__scroll__subcmd__up"
                ;;
            zellij__subcmd__action__subcmd__help,send-keys)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__send__subcmd__keys"
                ;;
            zellij__subcmd__action__subcmd__help,set-dark-theme)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__set__subcmd__dark__subcmd__theme"
                ;;
            zellij__subcmd__action__subcmd__help,set-light-theme)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__set__subcmd__light__subcmd__theme"
                ;;
            zellij__subcmd__action__subcmd__help,set-pane-borderless)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__set__subcmd__pane__subcmd__borderless"
                ;;
            zellij__subcmd__action__subcmd__help,set-pane-color)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__set__subcmd__pane__subcmd__color"
                ;;
            zellij__subcmd__action__subcmd__help,set-pane-frame-style)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__set__subcmd__pane__subcmd__frame__subcmd__style"
                ;;
            zellij__subcmd__action__subcmd__help,show-floating-panes)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__show__subcmd__floating__subcmd__panes"
                ;;
            zellij__subcmd__action__subcmd__help,stack-panes)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__stack__subcmd__panes"
                ;;
            zellij__subcmd__action__subcmd__help,start-or-reload-plugin)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__start__subcmd__or__subcmd__reload__subcmd__plugin"
                ;;
            zellij__subcmd__action__subcmd__help,switch-mode)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__switch__subcmd__mode"
                ;;
            zellij__subcmd__action__subcmd__help,switch-session)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__switch__subcmd__session"
                ;;
            zellij__subcmd__action__subcmd__help,toggle-active-sync-tab)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__toggle__subcmd__active__subcmd__sync__subcmd__tab"
                ;;
            zellij__subcmd__action__subcmd__help,toggle-floating-panes)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__toggle__subcmd__floating__subcmd__panes"
                ;;
            zellij__subcmd__action__subcmd__help,toggle-fullscreen)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__toggle__subcmd__fullscreen"
                ;;
            zellij__subcmd__action__subcmd__help,toggle-no-ui-fullscreen)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__toggle__subcmd__no__subcmd__ui__subcmd__fullscreen"
                ;;
            zellij__subcmd__action__subcmd__help,toggle-pane-borderless)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__toggle__subcmd__pane__subcmd__borderless"
                ;;
            zellij__subcmd__action__subcmd__help,toggle-pane-embed-or-floating)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__toggle__subcmd__pane__subcmd__embed__subcmd__or__subcmd__floating"
                ;;
            zellij__subcmd__action__subcmd__help,toggle-pane-frames)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__toggle__subcmd__pane__subcmd__frames"
                ;;
            zellij__subcmd__action__subcmd__help,toggle-pane-pinned)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__toggle__subcmd__pane__subcmd__pinned"
                ;;
            zellij__subcmd__action__subcmd__help,toggle-theme)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__toggle__subcmd__theme"
                ;;
            zellij__subcmd__action__subcmd__help,undo-rename-pane)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__undo__subcmd__rename__subcmd__pane"
                ;;
            zellij__subcmd__action__subcmd__help,undo-rename-tab)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__undo__subcmd__rename__subcmd__tab"
                ;;
            zellij__subcmd__action__subcmd__help,write)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__write"
                ;;
            zellij__subcmd__action__subcmd__help,write-chars)
                cmd="zellij__subcmd__action__subcmd__help__subcmd__write__subcmd__chars"
                ;;
            zellij__subcmd__attach,help)
                cmd="zellij__subcmd__attach__subcmd__help"
                ;;
            zellij__subcmd__attach,options)
                cmd="zellij__subcmd__attach__subcmd__options"
                ;;
            zellij__subcmd__attach__subcmd__help,help)
                cmd="zellij__subcmd__attach__subcmd__help__subcmd__help"
                ;;
            zellij__subcmd__attach__subcmd__help,options)
                cmd="zellij__subcmd__attach__subcmd__help__subcmd__options"
                ;;
            zellij__subcmd__help,action)
                cmd="zellij__subcmd__help__subcmd__action"
                ;;
            zellij__subcmd__help,attach)
                cmd="zellij__subcmd__help__subcmd__attach"
                ;;
            zellij__subcmd__help,delete-all-sessions)
                cmd="zellij__subcmd__help__subcmd__delete__subcmd__all__subcmd__sessions"
                ;;
            zellij__subcmd__help,delete-session)
                cmd="zellij__subcmd__help__subcmd__delete__subcmd__session"
                ;;
            zellij__subcmd__help,edit)
                cmd="zellij__subcmd__help__subcmd__edit"
                ;;
            zellij__subcmd__help,help)
                cmd="zellij__subcmd__help__subcmd__help"
                ;;
            zellij__subcmd__help,kill-all-sessions)
                cmd="zellij__subcmd__help__subcmd__kill__subcmd__all__subcmd__sessions"
                ;;
            zellij__subcmd__help,kill-session)
                cmd="zellij__subcmd__help__subcmd__kill__subcmd__session"
                ;;
            zellij__subcmd__help,list-aliases)
                cmd="zellij__subcmd__help__subcmd__list__subcmd__aliases"
                ;;
            zellij__subcmd__help,list-sessions)
                cmd="zellij__subcmd__help__subcmd__list__subcmd__sessions"
                ;;
            zellij__subcmd__help,options)
                cmd="zellij__subcmd__help__subcmd__options"
                ;;
            zellij__subcmd__help,pipe)
                cmd="zellij__subcmd__help__subcmd__pipe"
                ;;
            zellij__subcmd__help,plugin)
                cmd="zellij__subcmd__help__subcmd__plugin"
                ;;
            zellij__subcmd__help,run)
                cmd="zellij__subcmd__help__subcmd__run"
                ;;
            zellij__subcmd__help,setup)
                cmd="zellij__subcmd__help__subcmd__setup"
                ;;
            zellij__subcmd__help,subscribe)
                cmd="zellij__subcmd__help__subcmd__subscribe"
                ;;
            zellij__subcmd__help,watch)
                cmd="zellij__subcmd__help__subcmd__watch"
                ;;
            zellij__subcmd__help,web)
                cmd="zellij__subcmd__help__subcmd__web"
                ;;
            zellij__subcmd__help__subcmd__action,are-floating-panes-visible)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__are__subcmd__floating__subcmd__panes__subcmd__visible"
                ;;
            zellij__subcmd__help__subcmd__action,change-floating-pane-coordinates)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__change__subcmd__floating__subcmd__pane__subcmd__coordinates"
                ;;
            zellij__subcmd__help__subcmd__action,clear)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__clear"
                ;;
            zellij__subcmd__help__subcmd__action,close-pane)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__close__subcmd__pane"
                ;;
            zellij__subcmd__help__subcmd__action,close-tab)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__close__subcmd__tab"
                ;;
            zellij__subcmd__help__subcmd__action,close-tab-by-id)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__close__subcmd__tab__subcmd__by__subcmd__id"
                ;;
            zellij__subcmd__help__subcmd__action,current-tab-info)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__current__subcmd__tab__subcmd__info"
                ;;
            zellij__subcmd__help__subcmd__action,detach)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__detach"
                ;;
            zellij__subcmd__help__subcmd__action,dump-layout)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__dump__subcmd__layout"
                ;;
            zellij__subcmd__help__subcmd__action,dump-screen)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__dump__subcmd__screen"
                ;;
            zellij__subcmd__help__subcmd__action,edit)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__edit"
                ;;
            zellij__subcmd__help__subcmd__action,edit-scrollback)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__edit__subcmd__scrollback"
                ;;
            zellij__subcmd__help__subcmd__action,focus-last-pane)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__focus__subcmd__last__subcmd__pane"
                ;;
            zellij__subcmd__help__subcmd__action,focus-next-pane)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__focus__subcmd__next__subcmd__pane"
                ;;
            zellij__subcmd__help__subcmd__action,focus-pane-id)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__focus__subcmd__pane__subcmd__id"
                ;;
            zellij__subcmd__help__subcmd__action,focus-previous-pane)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__focus__subcmd__previous__subcmd__pane"
                ;;
            zellij__subcmd__help__subcmd__action,go-to-next-tab)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__go__subcmd__to__subcmd__next__subcmd__tab"
                ;;
            zellij__subcmd__help__subcmd__action,go-to-previous-tab)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__go__subcmd__to__subcmd__previous__subcmd__tab"
                ;;
            zellij__subcmd__help__subcmd__action,go-to-tab)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__go__subcmd__to__subcmd__tab"
                ;;
            zellij__subcmd__help__subcmd__action,go-to-tab-by-id)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__go__subcmd__to__subcmd__tab__subcmd__by__subcmd__id"
                ;;
            zellij__subcmd__help__subcmd__action,go-to-tab-name)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__go__subcmd__to__subcmd__tab__subcmd__name"
                ;;
            zellij__subcmd__help__subcmd__action,half-page-scroll-down)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__half__subcmd__page__subcmd__scroll__subcmd__down"
                ;;
            zellij__subcmd__help__subcmd__action,half-page-scroll-up)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__half__subcmd__page__subcmd__scroll__subcmd__up"
                ;;
            zellij__subcmd__help__subcmd__action,hide-floating-panes)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__hide__subcmd__floating__subcmd__panes"
                ;;
            zellij__subcmd__help__subcmd__action,launch-or-focus-plugin)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__launch__subcmd__or__subcmd__focus__subcmd__plugin"
                ;;
            zellij__subcmd__help__subcmd__action,launch-plugin)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__launch__subcmd__plugin"
                ;;
            zellij__subcmd__help__subcmd__action,list-clients)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__list__subcmd__clients"
                ;;
            zellij__subcmd__help__subcmd__action,list-panes)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__list__subcmd__panes"
                ;;
            zellij__subcmd__help__subcmd__action,list-tabs)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__list__subcmd__tabs"
                ;;
            zellij__subcmd__help__subcmd__action,move-focus)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__move__subcmd__focus"
                ;;
            zellij__subcmd__help__subcmd__action,move-focus-or-tab)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__move__subcmd__focus__subcmd__or__subcmd__tab"
                ;;
            zellij__subcmd__help__subcmd__action,move-pane)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__move__subcmd__pane"
                ;;
            zellij__subcmd__help__subcmd__action,move-pane-backwards)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__move__subcmd__pane__subcmd__backwards"
                ;;
            zellij__subcmd__help__subcmd__action,move-tab)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__move__subcmd__tab"
                ;;
            zellij__subcmd__help__subcmd__action,new-pane)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__new__subcmd__pane"
                ;;
            zellij__subcmd__help__subcmd__action,new-tab)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__new__subcmd__tab"
                ;;
            zellij__subcmd__help__subcmd__action,next-swap-layout)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__next__subcmd__swap__subcmd__layout"
                ;;
            zellij__subcmd__help__subcmd__action,override-layout)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__override__subcmd__layout"
                ;;
            zellij__subcmd__help__subcmd__action,page-scroll-down)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__page__subcmd__scroll__subcmd__down"
                ;;
            zellij__subcmd__help__subcmd__action,page-scroll-up)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__page__subcmd__scroll__subcmd__up"
                ;;
            zellij__subcmd__help__subcmd__action,paste)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__paste"
                ;;
            zellij__subcmd__help__subcmd__action,pipe)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__pipe"
                ;;
            zellij__subcmd__help__subcmd__action,previous-swap-layout)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__previous__subcmd__swap__subcmd__layout"
                ;;
            zellij__subcmd__help__subcmd__action,query-tab-names)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__query__subcmd__tab__subcmd__names"
                ;;
            zellij__subcmd__help__subcmd__action,rename-pane)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__rename__subcmd__pane"
                ;;
            zellij__subcmd__help__subcmd__action,rename-session)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__rename__subcmd__session"
                ;;
            zellij__subcmd__help__subcmd__action,rename-tab)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__rename__subcmd__tab"
                ;;
            zellij__subcmd__help__subcmd__action,rename-tab-by-id)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__rename__subcmd__tab__subcmd__by__subcmd__id"
                ;;
            zellij__subcmd__help__subcmd__action,resize)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__resize"
                ;;
            zellij__subcmd__help__subcmd__action,save-session)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__save__subcmd__session"
                ;;
            zellij__subcmd__help__subcmd__action,scroll-down)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__scroll__subcmd__down"
                ;;
            zellij__subcmd__help__subcmd__action,scroll-to-bottom)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__scroll__subcmd__to__subcmd__bottom"
                ;;
            zellij__subcmd__help__subcmd__action,scroll-to-top)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__scroll__subcmd__to__subcmd__top"
                ;;
            zellij__subcmd__help__subcmd__action,scroll-up)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__scroll__subcmd__up"
                ;;
            zellij__subcmd__help__subcmd__action,send-keys)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__send__subcmd__keys"
                ;;
            zellij__subcmd__help__subcmd__action,set-dark-theme)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__set__subcmd__dark__subcmd__theme"
                ;;
            zellij__subcmd__help__subcmd__action,set-light-theme)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__set__subcmd__light__subcmd__theme"
                ;;
            zellij__subcmd__help__subcmd__action,set-pane-borderless)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__set__subcmd__pane__subcmd__borderless"
                ;;
            zellij__subcmd__help__subcmd__action,set-pane-color)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__set__subcmd__pane__subcmd__color"
                ;;
            zellij__subcmd__help__subcmd__action,set-pane-frame-style)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__set__subcmd__pane__subcmd__frame__subcmd__style"
                ;;
            zellij__subcmd__help__subcmd__action,show-floating-panes)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__show__subcmd__floating__subcmd__panes"
                ;;
            zellij__subcmd__help__subcmd__action,stack-panes)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__stack__subcmd__panes"
                ;;
            zellij__subcmd__help__subcmd__action,start-or-reload-plugin)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__start__subcmd__or__subcmd__reload__subcmd__plugin"
                ;;
            zellij__subcmd__help__subcmd__action,switch-mode)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__switch__subcmd__mode"
                ;;
            zellij__subcmd__help__subcmd__action,switch-session)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__switch__subcmd__session"
                ;;
            zellij__subcmd__help__subcmd__action,toggle-active-sync-tab)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__toggle__subcmd__active__subcmd__sync__subcmd__tab"
                ;;
            zellij__subcmd__help__subcmd__action,toggle-floating-panes)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__toggle__subcmd__floating__subcmd__panes"
                ;;
            zellij__subcmd__help__subcmd__action,toggle-fullscreen)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__toggle__subcmd__fullscreen"
                ;;
            zellij__subcmd__help__subcmd__action,toggle-no-ui-fullscreen)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__toggle__subcmd__no__subcmd__ui__subcmd__fullscreen"
                ;;
            zellij__subcmd__help__subcmd__action,toggle-pane-borderless)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__toggle__subcmd__pane__subcmd__borderless"
                ;;
            zellij__subcmd__help__subcmd__action,toggle-pane-embed-or-floating)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__toggle__subcmd__pane__subcmd__embed__subcmd__or__subcmd__floating"
                ;;
            zellij__subcmd__help__subcmd__action,toggle-pane-frames)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__toggle__subcmd__pane__subcmd__frames"
                ;;
            zellij__subcmd__help__subcmd__action,toggle-pane-pinned)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__toggle__subcmd__pane__subcmd__pinned"
                ;;
            zellij__subcmd__help__subcmd__action,toggle-theme)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__toggle__subcmd__theme"
                ;;
            zellij__subcmd__help__subcmd__action,undo-rename-pane)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__undo__subcmd__rename__subcmd__pane"
                ;;
            zellij__subcmd__help__subcmd__action,undo-rename-tab)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__undo__subcmd__rename__subcmd__tab"
                ;;
            zellij__subcmd__help__subcmd__action,write)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__write"
                ;;
            zellij__subcmd__help__subcmd__action,write-chars)
                cmd="zellij__subcmd__help__subcmd__action__subcmd__write__subcmd__chars"
                ;;
            zellij__subcmd__help__subcmd__attach,options)
                cmd="zellij__subcmd__help__subcmd__attach__subcmd__options"
                ;;
            *)
                ;;
        esac
    done

    case "${cmd}" in
        zellij)
            opts="-s -l -n -c -d -h -V --max-panes --data-dir --server --session --layout --layout-string --new-session-with-layout --config --config-dir --debug --help --version options setup web action ac list-sessions ls list-aliases la attach a watch w kill-session k delete-session d kill-all-sessions ka delete-all-sessions da run r plugin p edit e pipe subscribe help"
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
        zellij__subcmd__action)
            opts="-h --help write write-chars paste send-keys resize focus-next-pane focus-previous-pane focus-pane-id focus-last-pane move-focus move-focus-or-tab move-pane move-pane-backwards clear dump-screen dump-layout save-session edit-scrollback scroll-up scroll-down scroll-to-bottom scroll-to-top page-scroll-up page-scroll-down half-page-scroll-up half-page-scroll-down toggle-fullscreen toggle-no-ui-fullscreen toggle-pane-frames set-pane-frame-style toggle-active-sync-tab new-pane edit switch-mode toggle-pane-embed-or-floating toggle-floating-panes show-floating-panes hide-floating-panes are-floating-panes-visible close-pane rename-pane undo-rename-pane go-to-next-tab go-to-previous-tab close-tab go-to-tab go-to-tab-name rename-tab undo-rename-tab go-to-tab-by-id close-tab-by-id rename-tab-by-id new-tab move-tab previous-swap-layout next-swap-layout override-layout query-tab-names start-or-reload-plugin launch-or-focus-plugin launch-plugin rename-session pipe list-clients list-panes list-tabs current-tab-info toggle-pane-pinned stack-panes change-floating-pane-coordinates toggle-pane-borderless set-pane-borderless detach set-dark-theme set-light-theme toggle-theme switch-session set-pane-color help"
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
        zellij__subcmd__action__subcmd__are__subcmd__floating__subcmd__panes__subcmd__visible)
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
        zellij__subcmd__action__subcmd__change__subcmd__floating__subcmd__pane__subcmd__coordinates)
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
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
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
        zellij__subcmd__action__subcmd__clear)
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
        zellij__subcmd__action__subcmd__close__subcmd__pane)
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
        zellij__subcmd__action__subcmd__close__subcmd__tab)
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
        zellij__subcmd__action__subcmd__close__subcmd__tab__subcmd__by__subcmd__id)
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
        zellij__subcmd__action__subcmd__current__subcmd__tab__subcmd__info)
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
        zellij__subcmd__action__subcmd__detach)
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
        zellij__subcmd__action__subcmd__dump__subcmd__layout)
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
        zellij__subcmd__action__subcmd__dump__subcmd__screen)
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
        zellij__subcmd__action__subcmd__edit)
            opts="-d -l -f -i -x -y -b -h --direction --line-number --floating --in-place --close-replaced-pane --cwd --x --y --width --height --pinned --near-current-pane --no-focus --borderless --tab-id --help"
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
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
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
        zellij__subcmd__action__subcmd__edit__subcmd__scrollback)
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
        zellij__subcmd__action__subcmd__focus__subcmd__last__subcmd__pane)
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
        zellij__subcmd__action__subcmd__focus__subcmd__next__subcmd__pane)
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
        zellij__subcmd__action__subcmd__focus__subcmd__pane__subcmd__id)
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
        zellij__subcmd__action__subcmd__focus__subcmd__previous__subcmd__pane)
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
        zellij__subcmd__action__subcmd__go__subcmd__to__subcmd__next__subcmd__tab)
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
        zellij__subcmd__action__subcmd__go__subcmd__to__subcmd__previous__subcmd__tab)
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
        zellij__subcmd__action__subcmd__go__subcmd__to__subcmd__tab)
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
        zellij__subcmd__action__subcmd__go__subcmd__to__subcmd__tab__subcmd__by__subcmd__id)
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
        zellij__subcmd__action__subcmd__go__subcmd__to__subcmd__tab__subcmd__name)
            opts="-c -h --create --help"
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
        zellij__subcmd__action__subcmd__half__subcmd__page__subcmd__scroll__subcmd__down)
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
        zellij__subcmd__action__subcmd__half__subcmd__page__subcmd__scroll__subcmd__up)
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
        zellij__subcmd__action__subcmd__help)
            opts="write write-chars paste send-keys resize focus-next-pane focus-previous-pane focus-pane-id focus-last-pane move-focus move-focus-or-tab move-pane move-pane-backwards clear dump-screen dump-layout save-session edit-scrollback scroll-up scroll-down scroll-to-bottom scroll-to-top page-scroll-up page-scroll-down half-page-scroll-up half-page-scroll-down toggle-fullscreen toggle-no-ui-fullscreen toggle-pane-frames set-pane-frame-style toggle-active-sync-tab new-pane edit switch-mode toggle-pane-embed-or-floating toggle-floating-panes show-floating-panes hide-floating-panes are-floating-panes-visible close-pane rename-pane undo-rename-pane go-to-next-tab go-to-previous-tab close-tab go-to-tab go-to-tab-name rename-tab undo-rename-tab go-to-tab-by-id close-tab-by-id rename-tab-by-id new-tab move-tab previous-swap-layout next-swap-layout override-layout query-tab-names start-or-reload-plugin launch-or-focus-plugin launch-plugin rename-session pipe list-clients list-panes list-tabs current-tab-info toggle-pane-pinned stack-panes change-floating-pane-coordinates toggle-pane-borderless set-pane-borderless detach set-dark-theme set-light-theme toggle-theme switch-session set-pane-color help"
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
        zellij__subcmd__action__subcmd__help__subcmd__are__subcmd__floating__subcmd__panes__subcmd__visible)
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
        zellij__subcmd__action__subcmd__help__subcmd__change__subcmd__floating__subcmd__pane__subcmd__coordinates)
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
        zellij__subcmd__action__subcmd__help__subcmd__clear)
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
        zellij__subcmd__action__subcmd__help__subcmd__close__subcmd__pane)
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
        zellij__subcmd__action__subcmd__help__subcmd__close__subcmd__tab)
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
        zellij__subcmd__action__subcmd__help__subcmd__close__subcmd__tab__subcmd__by__subcmd__id)
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
        zellij__subcmd__action__subcmd__help__subcmd__current__subcmd__tab__subcmd__info)
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
        zellij__subcmd__action__subcmd__help__subcmd__detach)
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
        zellij__subcmd__action__subcmd__help__subcmd__dump__subcmd__layout)
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
        zellij__subcmd__action__subcmd__help__subcmd__dump__subcmd__screen)
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
        zellij__subcmd__action__subcmd__help__subcmd__edit)
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
        zellij__subcmd__action__subcmd__help__subcmd__edit__subcmd__scrollback)
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
        zellij__subcmd__action__subcmd__help__subcmd__focus__subcmd__last__subcmd__pane)
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
        zellij__subcmd__action__subcmd__help__subcmd__focus__subcmd__next__subcmd__pane)
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
        zellij__subcmd__action__subcmd__help__subcmd__focus__subcmd__pane__subcmd__id)
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
        zellij__subcmd__action__subcmd__help__subcmd__focus__subcmd__previous__subcmd__pane)
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
        zellij__subcmd__action__subcmd__help__subcmd__go__subcmd__to__subcmd__next__subcmd__tab)
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
        zellij__subcmd__action__subcmd__help__subcmd__go__subcmd__to__subcmd__previous__subcmd__tab)
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
        zellij__subcmd__action__subcmd__help__subcmd__go__subcmd__to__subcmd__tab)
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
        zellij__subcmd__action__subcmd__help__subcmd__go__subcmd__to__subcmd__tab__subcmd__by__subcmd__id)
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
        zellij__subcmd__action__subcmd__help__subcmd__go__subcmd__to__subcmd__tab__subcmd__name)
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
        zellij__subcmd__action__subcmd__help__subcmd__half__subcmd__page__subcmd__scroll__subcmd__down)
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
        zellij__subcmd__action__subcmd__help__subcmd__half__subcmd__page__subcmd__scroll__subcmd__up)
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
        zellij__subcmd__action__subcmd__help__subcmd__help)
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
        zellij__subcmd__action__subcmd__help__subcmd__hide__subcmd__floating__subcmd__panes)
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
        zellij__subcmd__action__subcmd__help__subcmd__launch__subcmd__or__subcmd__focus__subcmd__plugin)
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
        zellij__subcmd__action__subcmd__help__subcmd__launch__subcmd__plugin)
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
        zellij__subcmd__action__subcmd__help__subcmd__list__subcmd__clients)
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
        zellij__subcmd__action__subcmd__help__subcmd__list__subcmd__panes)
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
        zellij__subcmd__action__subcmd__help__subcmd__list__subcmd__tabs)
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
        zellij__subcmd__action__subcmd__help__subcmd__move__subcmd__focus)
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
        zellij__subcmd__action__subcmd__help__subcmd__move__subcmd__focus__subcmd__or__subcmd__tab)
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
        zellij__subcmd__action__subcmd__help__subcmd__move__subcmd__pane)
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
        zellij__subcmd__action__subcmd__help__subcmd__move__subcmd__pane__subcmd__backwards)
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
        zellij__subcmd__action__subcmd__help__subcmd__move__subcmd__tab)
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
        zellij__subcmd__action__subcmd__help__subcmd__new__subcmd__pane)
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
        zellij__subcmd__action__subcmd__help__subcmd__new__subcmd__tab)
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
        zellij__subcmd__action__subcmd__help__subcmd__next__subcmd__swap__subcmd__layout)
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
        zellij__subcmd__action__subcmd__help__subcmd__override__subcmd__layout)
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
        zellij__subcmd__action__subcmd__help__subcmd__page__subcmd__scroll__subcmd__down)
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
        zellij__subcmd__action__subcmd__help__subcmd__page__subcmd__scroll__subcmd__up)
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
        zellij__subcmd__action__subcmd__help__subcmd__paste)
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
        zellij__subcmd__action__subcmd__help__subcmd__pipe)
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
        zellij__subcmd__action__subcmd__help__subcmd__previous__subcmd__swap__subcmd__layout)
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
        zellij__subcmd__action__subcmd__help__subcmd__query__subcmd__tab__subcmd__names)
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
        zellij__subcmd__action__subcmd__help__subcmd__rename__subcmd__pane)
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
        zellij__subcmd__action__subcmd__help__subcmd__rename__subcmd__session)
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
        zellij__subcmd__action__subcmd__help__subcmd__rename__subcmd__tab)
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
        zellij__subcmd__action__subcmd__help__subcmd__rename__subcmd__tab__subcmd__by__subcmd__id)
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
        zellij__subcmd__action__subcmd__help__subcmd__resize)
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
        zellij__subcmd__action__subcmd__help__subcmd__save__subcmd__session)
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
        zellij__subcmd__action__subcmd__help__subcmd__scroll__subcmd__down)
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
        zellij__subcmd__action__subcmd__help__subcmd__scroll__subcmd__to__subcmd__bottom)
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
        zellij__subcmd__action__subcmd__help__subcmd__scroll__subcmd__to__subcmd__top)
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
        zellij__subcmd__action__subcmd__help__subcmd__scroll__subcmd__up)
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
        zellij__subcmd__action__subcmd__help__subcmd__send__subcmd__keys)
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
        zellij__subcmd__action__subcmd__help__subcmd__set__subcmd__dark__subcmd__theme)
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
        zellij__subcmd__action__subcmd__help__subcmd__set__subcmd__light__subcmd__theme)
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
        zellij__subcmd__action__subcmd__help__subcmd__set__subcmd__pane__subcmd__borderless)
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
        zellij__subcmd__action__subcmd__help__subcmd__set__subcmd__pane__subcmd__color)
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
        zellij__subcmd__action__subcmd__help__subcmd__set__subcmd__pane__subcmd__frame__subcmd__style)
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
        zellij__subcmd__action__subcmd__help__subcmd__show__subcmd__floating__subcmd__panes)
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
        zellij__subcmd__action__subcmd__help__subcmd__stack__subcmd__panes)
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
        zellij__subcmd__action__subcmd__help__subcmd__start__subcmd__or__subcmd__reload__subcmd__plugin)
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
        zellij__subcmd__action__subcmd__help__subcmd__switch__subcmd__mode)
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
        zellij__subcmd__action__subcmd__help__subcmd__switch__subcmd__session)
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
        zellij__subcmd__action__subcmd__help__subcmd__toggle__subcmd__active__subcmd__sync__subcmd__tab)
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
        zellij__subcmd__action__subcmd__help__subcmd__toggle__subcmd__floating__subcmd__panes)
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
        zellij__subcmd__action__subcmd__help__subcmd__toggle__subcmd__fullscreen)
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
        zellij__subcmd__action__subcmd__help__subcmd__toggle__subcmd__no__subcmd__ui__subcmd__fullscreen)
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
        zellij__subcmd__action__subcmd__help__subcmd__toggle__subcmd__pane__subcmd__borderless)
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
        zellij__subcmd__action__subcmd__help__subcmd__toggle__subcmd__pane__subcmd__embed__subcmd__or__subcmd__floating)
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
        zellij__subcmd__action__subcmd__help__subcmd__toggle__subcmd__pane__subcmd__frames)
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
        zellij__subcmd__action__subcmd__help__subcmd__toggle__subcmd__pane__subcmd__pinned)
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
        zellij__subcmd__action__subcmd__help__subcmd__toggle__subcmd__theme)
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
        zellij__subcmd__action__subcmd__help__subcmd__undo__subcmd__rename__subcmd__pane)
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
        zellij__subcmd__action__subcmd__help__subcmd__undo__subcmd__rename__subcmd__tab)
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
        zellij__subcmd__action__subcmd__help__subcmd__write)
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
        zellij__subcmd__action__subcmd__help__subcmd__write__subcmd__chars)
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
        zellij__subcmd__action__subcmd__hide__subcmd__floating__subcmd__panes)
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
        zellij__subcmd__action__subcmd__launch__subcmd__or__subcmd__focus__subcmd__plugin)
            opts="-f -i -m -c -s -h --floating --in-place --close-replaced-pane --move-to-focused-tab --configuration --skip-plugin-cache --tab-id --help"
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
        zellij__subcmd__action__subcmd__launch__subcmd__plugin)
            opts="-f -i -c -s -h --floating --in-place --close-replaced-pane --configuration --skip-plugin-cache --no-focus --tab-id --help"
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
        zellij__subcmd__action__subcmd__list__subcmd__clients)
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
        zellij__subcmd__action__subcmd__list__subcmd__panes)
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
        zellij__subcmd__action__subcmd__list__subcmd__tabs)
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
        zellij__subcmd__action__subcmd__move__subcmd__focus)
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
        zellij__subcmd__action__subcmd__move__subcmd__focus__subcmd__or__subcmd__tab)
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
        zellij__subcmd__action__subcmd__move__subcmd__pane)
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
        zellij__subcmd__action__subcmd__move__subcmd__pane__subcmd__backwards)
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
        zellij__subcmd__action__subcmd__move__subcmd__tab)
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
        zellij__subcmd__action__subcmd__new__subcmd__pane)
            opts="-d -p -f -i -n -c -s -x -y -b -h --direction --plugin --cwd --floating --in-place --close-replaced-pane --pane-id --name --close-on-exit --start-suspended --configuration --skip-plugin-cache --x --y --width --height --pinned --stacked --blocking --block-until-exit-success --block-until-exit-failure --block-until-exit --near-current-pane --no-focus --borderless --tab-id --help"
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
                --pane-id)
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
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
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
        zellij__subcmd__action__subcmd__new__subcmd__tab)
            opts="-l -n -c -h --layout --layout-string --layout-dir --name --cwd --initial-plugin --close-on-exit --start-suspended --block-until-exit-success --block-until-exit-failure --block-until-exit --no-focus --help"
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
        zellij__subcmd__action__subcmd__next__subcmd__swap__subcmd__layout)
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
        zellij__subcmd__action__subcmd__override__subcmd__layout)
            opts="-h --layout-string --layout-dir --retain-existing-terminal-panes --retain-existing-plugin-panes --apply-only-to-active-tab --help"
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
        zellij__subcmd__action__subcmd__page__subcmd__scroll__subcmd__down)
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
        zellij__subcmd__action__subcmd__page__subcmd__scroll__subcmd__up)
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
        zellij__subcmd__action__subcmd__paste)
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
        zellij__subcmd__action__subcmd__pipe)
            opts="-n -a -p -c -l -s -f -i -w -t -h --name --args --plugin --plugin-configuration --force-launch-plugin --skip-plugin-cache --floating-plugin --in-place-plugin --plugin-cwd --plugin-title --help"
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
        zellij__subcmd__action__subcmd__previous__subcmd__swap__subcmd__layout)
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
        zellij__subcmd__action__subcmd__query__subcmd__tab__subcmd__names)
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
        zellij__subcmd__action__subcmd__rename__subcmd__pane)
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
        zellij__subcmd__action__subcmd__rename__subcmd__session)
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
        zellij__subcmd__action__subcmd__rename__subcmd__tab)
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
        zellij__subcmd__action__subcmd__rename__subcmd__tab__subcmd__by__subcmd__id)
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
        zellij__subcmd__action__subcmd__resize)
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
        zellij__subcmd__action__subcmd__save__subcmd__session)
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
        zellij__subcmd__action__subcmd__scroll__subcmd__down)
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
        zellij__subcmd__action__subcmd__scroll__subcmd__to__subcmd__bottom)
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
        zellij__subcmd__action__subcmd__scroll__subcmd__to__subcmd__top)
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
        zellij__subcmd__action__subcmd__scroll__subcmd__up)
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
        zellij__subcmd__action__subcmd__send__subcmd__keys)
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
        zellij__subcmd__action__subcmd__set__subcmd__dark__subcmd__theme)
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
        zellij__subcmd__action__subcmd__set__subcmd__light__subcmd__theme)
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
        zellij__subcmd__action__subcmd__set__subcmd__pane__subcmd__borderless)
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
        zellij__subcmd__action__subcmd__set__subcmd__pane__subcmd__color)
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
        zellij__subcmd__action__subcmd__set__subcmd__pane__subcmd__frame__subcmd__style)
            opts="-h --help full titles none"
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
        zellij__subcmd__action__subcmd__show__subcmd__floating__subcmd__panes)
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
        zellij__subcmd__action__subcmd__stack__subcmd__panes)
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
        zellij__subcmd__action__subcmd__start__subcmd__or__subcmd__reload__subcmd__plugin)
            opts="-c -h --configuration --help"
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
        zellij__subcmd__action__subcmd__switch__subcmd__mode)
            opts="-h --help normal locked resize pane tab scroll enter-search search rename-tab rename-pane session move prompt tmux"
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
        zellij__subcmd__action__subcmd__switch__subcmd__session)
            opts="-l -c -h --tab-position --pane-id --layout --layout-string --layout-dir --cwd --help"
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
        zellij__subcmd__action__subcmd__toggle__subcmd__active__subcmd__sync__subcmd__tab)
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
        zellij__subcmd__action__subcmd__toggle__subcmd__floating__subcmd__panes)
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
        zellij__subcmd__action__subcmd__toggle__subcmd__fullscreen)
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
        zellij__subcmd__action__subcmd__toggle__subcmd__no__subcmd__ui__subcmd__fullscreen)
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
        zellij__subcmd__action__subcmd__toggle__subcmd__pane__subcmd__borderless)
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
        zellij__subcmd__action__subcmd__toggle__subcmd__pane__subcmd__embed__subcmd__or__subcmd__floating)
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
        zellij__subcmd__action__subcmd__toggle__subcmd__pane__subcmd__frames)
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
        zellij__subcmd__action__subcmd__toggle__subcmd__pane__subcmd__pinned)
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
        zellij__subcmd__action__subcmd__toggle__subcmd__theme)
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
        zellij__subcmd__action__subcmd__undo__subcmd__rename__subcmd__pane)
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
        zellij__subcmd__action__subcmd__undo__subcmd__rename__subcmd__tab)
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
        zellij__subcmd__action__subcmd__write)
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
        zellij__subcmd__action__subcmd__write__subcmd__chars)
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
        zellij__subcmd__attach)
            opts="-c -b -f -t -r -h --create --create-background --index --force-run-commands --token --remember --forget --ca-cert --insecure --close-on-exit --start-suspended --help options help"
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
        zellij__subcmd__attach__subcmd__help)
            opts="options help"
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
        zellij__subcmd__attach__subcmd__help__subcmd__help)
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
        zellij__subcmd__attach__subcmd__help__subcmd__options)
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
        zellij__subcmd__attach__subcmd__options)
            opts="-h --simplified-ui --theme --theme-dark --theme-light --explicit-theme-hue --default-mode --default-shell --default-cwd --default-layout --layout-dir --theme-dir --mouse-mode --pane-frames --pane-frame-style --mirror-session --on-force-close --scroll-buffer-size --copy-command --copy-clipboard --copy-on-select --osc8-hyperlinks --scrollback-editor --session-name --attach-to-session --auto-layout --session-serialization --serialize-pane-viewport --scrollback-lines-to-serialize --styled-underlines --serialization-interval --disable-session-metadata --support-kitty-keyboard-protocol --support-kitty-graphics-protocol --web-server --web-sharing --stacked-resize --stacked-pane-list --show-startup-tips --show-release-notes --advanced-mouse-actions --mouse-scroll-resize --scroll-mode-sync --mouse-hover-effects --mouse-hover-tips --visual-bell --focus-follows-mouse --mouse-click-through --osc133-command-selection --word-separators --host-notification-protocol --post-command-discovery-hook --client-async-worker-tasks --nested-session-handling --dangerously-enable-paste-buffer-read --help true false"
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
                --explicit-theme-hue)
                    COMPREPLY=($(compgen -W "light dark" -- "${cur}"))
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
                --pane-frame-style)
                    COMPREPLY=($(compgen -W "full titles none" -- "${cur}"))
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
                --support-kitty-graphics-protocol)
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
                --stacked-pane-list)
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
                --mouse-scroll-resize)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --scroll-mode-sync)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --mouse-hover-effects)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --mouse-hover-tips)
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
                --osc133-command-selection)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --word-separators)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --host-notification-protocol)
                    COMPREPLY=($(compgen -W "auto osc9 osc99 bell off" -- "${cur}"))
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
                --nested-session-handling)
                    COMPREPLY=($(compgen -W "ask fullscreen descend never" -- "${cur}"))
                    return 0
                    ;;
                --dangerously-enable-paste-buffer-read)
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
        zellij__subcmd__delete__subcmd__all__subcmd__sessions)
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
        zellij__subcmd__delete__subcmd__session)
            opts="-f -h --force --help"
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
        zellij__subcmd__edit)
            opts="-l -d -i -f -x -y -b -h --line-number --direction --in-place --close-replaced-pane --floating --cwd --x --y --width --height --pinned --near-current-pane --no-focus --borderless --tab-id --help"
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
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
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
        zellij__subcmd__help)
            opts="options setup web action list-sessions list-aliases attach watch kill-session delete-session kill-all-sessions delete-all-sessions run plugin edit pipe subscribe help"
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
        zellij__subcmd__help__subcmd__action)
            opts="write write-chars paste send-keys resize focus-next-pane focus-previous-pane focus-pane-id focus-last-pane move-focus move-focus-or-tab move-pane move-pane-backwards clear dump-screen dump-layout save-session edit-scrollback scroll-up scroll-down scroll-to-bottom scroll-to-top page-scroll-up page-scroll-down half-page-scroll-up half-page-scroll-down toggle-fullscreen toggle-no-ui-fullscreen toggle-pane-frames set-pane-frame-style toggle-active-sync-tab new-pane edit switch-mode toggle-pane-embed-or-floating toggle-floating-panes show-floating-panes hide-floating-panes are-floating-panes-visible close-pane rename-pane undo-rename-pane go-to-next-tab go-to-previous-tab close-tab go-to-tab go-to-tab-name rename-tab undo-rename-tab go-to-tab-by-id close-tab-by-id rename-tab-by-id new-tab move-tab previous-swap-layout next-swap-layout override-layout query-tab-names start-or-reload-plugin launch-or-focus-plugin launch-plugin rename-session pipe list-clients list-panes list-tabs current-tab-info toggle-pane-pinned stack-panes change-floating-pane-coordinates toggle-pane-borderless set-pane-borderless detach set-dark-theme set-light-theme toggle-theme switch-session set-pane-color"
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
        zellij__subcmd__help__subcmd__action__subcmd__are__subcmd__floating__subcmd__panes__subcmd__visible)
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
        zellij__subcmd__help__subcmd__action__subcmd__change__subcmd__floating__subcmd__pane__subcmd__coordinates)
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
        zellij__subcmd__help__subcmd__action__subcmd__clear)
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
        zellij__subcmd__help__subcmd__action__subcmd__close__subcmd__pane)
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
        zellij__subcmd__help__subcmd__action__subcmd__close__subcmd__tab)
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
        zellij__subcmd__help__subcmd__action__subcmd__close__subcmd__tab__subcmd__by__subcmd__id)
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
        zellij__subcmd__help__subcmd__action__subcmd__current__subcmd__tab__subcmd__info)
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
        zellij__subcmd__help__subcmd__action__subcmd__detach)
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
        zellij__subcmd__help__subcmd__action__subcmd__dump__subcmd__layout)
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
        zellij__subcmd__help__subcmd__action__subcmd__dump__subcmd__screen)
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
        zellij__subcmd__help__subcmd__action__subcmd__edit)
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
        zellij__subcmd__help__subcmd__action__subcmd__edit__subcmd__scrollback)
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
        zellij__subcmd__help__subcmd__action__subcmd__focus__subcmd__last__subcmd__pane)
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
        zellij__subcmd__help__subcmd__action__subcmd__focus__subcmd__next__subcmd__pane)
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
        zellij__subcmd__help__subcmd__action__subcmd__focus__subcmd__pane__subcmd__id)
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
        zellij__subcmd__help__subcmd__action__subcmd__focus__subcmd__previous__subcmd__pane)
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
        zellij__subcmd__help__subcmd__action__subcmd__go__subcmd__to__subcmd__next__subcmd__tab)
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
        zellij__subcmd__help__subcmd__action__subcmd__go__subcmd__to__subcmd__previous__subcmd__tab)
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
        zellij__subcmd__help__subcmd__action__subcmd__go__subcmd__to__subcmd__tab)
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
        zellij__subcmd__help__subcmd__action__subcmd__go__subcmd__to__subcmd__tab__subcmd__by__subcmd__id)
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
        zellij__subcmd__help__subcmd__action__subcmd__go__subcmd__to__subcmd__tab__subcmd__name)
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
        zellij__subcmd__help__subcmd__action__subcmd__half__subcmd__page__subcmd__scroll__subcmd__down)
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
        zellij__subcmd__help__subcmd__action__subcmd__half__subcmd__page__subcmd__scroll__subcmd__up)
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
        zellij__subcmd__help__subcmd__action__subcmd__hide__subcmd__floating__subcmd__panes)
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
        zellij__subcmd__help__subcmd__action__subcmd__launch__subcmd__or__subcmd__focus__subcmd__plugin)
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
        zellij__subcmd__help__subcmd__action__subcmd__launch__subcmd__plugin)
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
        zellij__subcmd__help__subcmd__action__subcmd__list__subcmd__clients)
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
        zellij__subcmd__help__subcmd__action__subcmd__list__subcmd__panes)
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
        zellij__subcmd__help__subcmd__action__subcmd__list__subcmd__tabs)
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
        zellij__subcmd__help__subcmd__action__subcmd__move__subcmd__focus)
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
        zellij__subcmd__help__subcmd__action__subcmd__move__subcmd__focus__subcmd__or__subcmd__tab)
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
        zellij__subcmd__help__subcmd__action__subcmd__move__subcmd__pane)
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
        zellij__subcmd__help__subcmd__action__subcmd__move__subcmd__pane__subcmd__backwards)
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
        zellij__subcmd__help__subcmd__action__subcmd__move__subcmd__tab)
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
        zellij__subcmd__help__subcmd__action__subcmd__new__subcmd__pane)
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
        zellij__subcmd__help__subcmd__action__subcmd__new__subcmd__tab)
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
        zellij__subcmd__help__subcmd__action__subcmd__next__subcmd__swap__subcmd__layout)
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
        zellij__subcmd__help__subcmd__action__subcmd__override__subcmd__layout)
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
        zellij__subcmd__help__subcmd__action__subcmd__page__subcmd__scroll__subcmd__down)
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
        zellij__subcmd__help__subcmd__action__subcmd__page__subcmd__scroll__subcmd__up)
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
        zellij__subcmd__help__subcmd__action__subcmd__paste)
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
        zellij__subcmd__help__subcmd__action__subcmd__pipe)
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
        zellij__subcmd__help__subcmd__action__subcmd__previous__subcmd__swap__subcmd__layout)
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
        zellij__subcmd__help__subcmd__action__subcmd__query__subcmd__tab__subcmd__names)
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
        zellij__subcmd__help__subcmd__action__subcmd__rename__subcmd__pane)
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
        zellij__subcmd__help__subcmd__action__subcmd__rename__subcmd__session)
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
        zellij__subcmd__help__subcmd__action__subcmd__rename__subcmd__tab)
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
        zellij__subcmd__help__subcmd__action__subcmd__rename__subcmd__tab__subcmd__by__subcmd__id)
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
        zellij__subcmd__help__subcmd__action__subcmd__resize)
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
        zellij__subcmd__help__subcmd__action__subcmd__save__subcmd__session)
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
        zellij__subcmd__help__subcmd__action__subcmd__scroll__subcmd__down)
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
        zellij__subcmd__help__subcmd__action__subcmd__scroll__subcmd__to__subcmd__bottom)
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
        zellij__subcmd__help__subcmd__action__subcmd__scroll__subcmd__to__subcmd__top)
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
        zellij__subcmd__help__subcmd__action__subcmd__scroll__subcmd__up)
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
        zellij__subcmd__help__subcmd__action__subcmd__send__subcmd__keys)
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
        zellij__subcmd__help__subcmd__action__subcmd__set__subcmd__dark__subcmd__theme)
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
        zellij__subcmd__help__subcmd__action__subcmd__set__subcmd__light__subcmd__theme)
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
        zellij__subcmd__help__subcmd__action__subcmd__set__subcmd__pane__subcmd__borderless)
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
        zellij__subcmd__help__subcmd__action__subcmd__set__subcmd__pane__subcmd__color)
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
        zellij__subcmd__help__subcmd__action__subcmd__set__subcmd__pane__subcmd__frame__subcmd__style)
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
        zellij__subcmd__help__subcmd__action__subcmd__show__subcmd__floating__subcmd__panes)
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
        zellij__subcmd__help__subcmd__action__subcmd__stack__subcmd__panes)
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
        zellij__subcmd__help__subcmd__action__subcmd__start__subcmd__or__subcmd__reload__subcmd__plugin)
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
        zellij__subcmd__help__subcmd__action__subcmd__switch__subcmd__mode)
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
        zellij__subcmd__help__subcmd__action__subcmd__switch__subcmd__session)
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
        zellij__subcmd__help__subcmd__action__subcmd__toggle__subcmd__active__subcmd__sync__subcmd__tab)
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
        zellij__subcmd__help__subcmd__action__subcmd__toggle__subcmd__floating__subcmd__panes)
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
        zellij__subcmd__help__subcmd__action__subcmd__toggle__subcmd__fullscreen)
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
        zellij__subcmd__help__subcmd__action__subcmd__toggle__subcmd__no__subcmd__ui__subcmd__fullscreen)
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
        zellij__subcmd__help__subcmd__action__subcmd__toggle__subcmd__pane__subcmd__borderless)
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
        zellij__subcmd__help__subcmd__action__subcmd__toggle__subcmd__pane__subcmd__embed__subcmd__or__subcmd__floating)
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
        zellij__subcmd__help__subcmd__action__subcmd__toggle__subcmd__pane__subcmd__frames)
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
        zellij__subcmd__help__subcmd__action__subcmd__toggle__subcmd__pane__subcmd__pinned)
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
        zellij__subcmd__help__subcmd__action__subcmd__toggle__subcmd__theme)
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
        zellij__subcmd__help__subcmd__action__subcmd__undo__subcmd__rename__subcmd__pane)
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
        zellij__subcmd__help__subcmd__action__subcmd__undo__subcmd__rename__subcmd__tab)
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
        zellij__subcmd__help__subcmd__action__subcmd__write)
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
        zellij__subcmd__help__subcmd__action__subcmd__write__subcmd__chars)
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
        zellij__subcmd__help__subcmd__attach)
            opts="options"
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
        zellij__subcmd__help__subcmd__attach__subcmd__options)
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
        zellij__subcmd__help__subcmd__delete__subcmd__all__subcmd__sessions)
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
        zellij__subcmd__help__subcmd__delete__subcmd__session)
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
        zellij__subcmd__help__subcmd__edit)
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
        zellij__subcmd__help__subcmd__help)
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
        zellij__subcmd__help__subcmd__kill__subcmd__all__subcmd__sessions)
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
        zellij__subcmd__help__subcmd__kill__subcmd__session)
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
        zellij__subcmd__help__subcmd__list__subcmd__aliases)
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
        zellij__subcmd__help__subcmd__list__subcmd__sessions)
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
        zellij__subcmd__help__subcmd__options)
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
        zellij__subcmd__help__subcmd__pipe)
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
        zellij__subcmd__help__subcmd__plugin)
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
        zellij__subcmd__help__subcmd__run)
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
        zellij__subcmd__help__subcmd__setup)
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
        zellij__subcmd__help__subcmd__subscribe)
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
        zellij__subcmd__help__subcmd__watch)
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
        zellij__subcmd__help__subcmd__web)
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
        zellij__subcmd__kill__subcmd__all__subcmd__sessions)
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
        zellij__subcmd__kill__subcmd__session)
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
        zellij__subcmd__list__subcmd__aliases)
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
        zellij__subcmd__list__subcmd__sessions)
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
        zellij__subcmd__options)
            opts="-h --simplified-ui --theme --theme-dark --theme-light --explicit-theme-hue --default-mode --default-shell --default-cwd --default-layout --layout-dir --theme-dir --mouse-mode --pane-frames --pane-frame-style --mirror-session --on-force-close --scroll-buffer-size --copy-command --copy-clipboard --copy-on-select --osc8-hyperlinks --scrollback-editor --session-name --attach-to-session --auto-layout --session-serialization --serialize-pane-viewport --scrollback-lines-to-serialize --styled-underlines --serialization-interval --disable-session-metadata --support-kitty-keyboard-protocol --support-kitty-graphics-protocol --web-server --web-sharing --stacked-resize --stacked-pane-list --show-startup-tips --show-release-notes --advanced-mouse-actions --mouse-scroll-resize --scroll-mode-sync --mouse-hover-effects --mouse-hover-tips --visual-bell --focus-follows-mouse --mouse-click-through --osc133-command-selection --word-separators --host-notification-protocol --post-command-discovery-hook --client-async-worker-tasks --nested-session-handling --dangerously-enable-paste-buffer-read --help true false"
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
                --explicit-theme-hue)
                    COMPREPLY=($(compgen -W "light dark" -- "${cur}"))
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
                --pane-frame-style)
                    COMPREPLY=($(compgen -W "full titles none" -- "${cur}"))
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
                --support-kitty-graphics-protocol)
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
                --stacked-pane-list)
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
                --mouse-scroll-resize)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --scroll-mode-sync)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --mouse-hover-effects)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --mouse-hover-tips)
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
                --osc133-command-selection)
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
                    return 0
                    ;;
                --word-separators)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --host-notification-protocol)
                    COMPREPLY=($(compgen -W "auto osc9 osc99 bell off" -- "${cur}"))
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
                --nested-session-handling)
                    COMPREPLY=($(compgen -W "ask fullscreen descend never" -- "${cur}"))
                    return 0
                    ;;
                --dangerously-enable-paste-buffer-read)
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
        zellij__subcmd__pipe)
            opts="-n -a -p -c -h --name --args --plugin --plugin-configuration --help"
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
        zellij__subcmd__plugin)
            opts="-c -f -i -s -x -y -b -h --configuration --floating --in-place --close-replaced-pane --skip-plugin-cache --x --y --width --height --pinned --no-focus --borderless --tab-id --help"
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
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
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
        zellij__subcmd__run)
            opts="-d -f -i -n -c -s -x -y -b -h --direction --cwd --floating --in-place --close-replaced-pane --name --close-on-exit --start-suspended --x --y --width --height --pinned --stacked --blocking --block-until-exit-success --block-until-exit-failure --block-until-exit --near-current-pane --no-focus --borderless --tab-id --help"
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
                    COMPREPLY=($(compgen -W "true false" -- "${cur}"))
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
        zellij__subcmd__setup)
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
        zellij__subcmd__subscribe)
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
        zellij__subcmd__watch)
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
        zellij__subcmd__web)
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

if [[ "${BASH_VERSINFO[0]}" -eq 4 && "${BASH_VERSINFO[1]}" -ge 4 || "${BASH_VERSINFO[0]}" -gt 4 ]]; then
    complete -F _zellij -o nosort -o bashdefault -o default zellij
else
    complete -F _zellij -o bashdefault -o default zellij
fi
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