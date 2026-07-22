git diff --name-only --diff-filter=U | xargs rg --vimgrep --fixed-strings '<<<<<< HEAD' | cut --delimiter=':' --fields='1-3' | xargs --max-lines='3' hx --hsplit || reset
