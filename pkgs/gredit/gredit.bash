rg --vimgrep "$@" | cut --delimiter=':' --fields='1-3' | xargs --max-lines='10' hx --hsplit || reset
