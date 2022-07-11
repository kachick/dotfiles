#
# Defines environment variables.
#

# See https://qiita.com/eumesy/items/3bb39fc783c8d4863c5f

export PATH
export MANPATH
# -U: keep only the first occurrence of each duplicated value
# ref. http://zsh.sourceforge.net/Doc/Release/Shell-Builtin-Commands.html#index-typeset
typeset -U PATH path MANPATH manpath

# ignore /etc/zprofile, /etc/zshrc, /etc/zlogin, and /etc/zlogout
# ref. http://zsh.sourceforge.net/Doc/Release/Files.html
# ref. http://zsh.sourceforge.net/Doc/Release/Options.html#index-GLOBALRCS
unsetopt GLOBAL_RCS
# copied from /etc/zprofile
# system-wide environment settings for zsh(1)
if [ -x /usr/libexec/path_helper ]; then
    eval `/usr/libexec/path_helper -s`
fi

# https://qiita.com/vintersnow/items/7343b9bf60ea468a4180
# zmodload zsh/zprof && zprof

# Ensure that a non-login, non-interactive shell has a defined environment.
if [[ ( "$SHLVL" -eq 1 && ! -o LOGIN ) && -s "${ZDOTDIR:-$HOME}/.zprofile" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprofile"
fi

# To use GNU `ls` in Mac OS X. Required to prepare with `brew install coreutils`
# https://qiita.com/eumesy/items/3bb39fc783c8d4863c5f
path=(
    /usr/local/opt/coreutils/libexec/gnubin(N-/) # coreutils
    # /usr/local/opt/ed/libexec/gnubin(N-/) # ed
    # /usr/local/opt/findutils/libexec/gnubin(N-/) # findutils
    # /usr/local/opt/gnu-sed/libexec/gnubin(N-/) # sed
    # /usr/local/opt/gnu-tar/libexec/gnubin(N-/) # tar
    # /usr/local/opt/grep/libexec/gnubin(N-/) # grep
    /Users/kachick/bin(N-/)
    ${path}
)
manpath=(
    /usr/local/opt/coreutils/libexec/gnuman(N-/) # coreutils
    # /usr/local/opt/ed/libexec/gnuman(N-/) # ed
    # /usr/local/opt/findutils/libexec/gnuman(N-/) # findutils
    # /usr/local/opt/gnu-sed/libexec/gnuman(N-/) # sed
    # /usr/local/opt/gnu-tar/libexec/gnuman(N-/) # tar
    # /usr/local/opt/grep/libexec/gnuman(N-/) # grep
    ${manpath}
)
. "$HOME/.cargo/env"
