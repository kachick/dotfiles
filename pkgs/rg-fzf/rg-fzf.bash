# Imported from https://github.com/junegunn/fzf/blob/6444cc7905a5459b5346d069ec2465df83b82793/ADVANCED.md#L468-L501

# Switch between Ripgrep mode and fzf filtering mode (CTRL-T)
# Using mktemp is hard for quotation in bash. So keeping original code for now.
rm -f /tmp/rg-fzf-{r,f}
RG_PREFIX="rg --column --line-number --no-heading --color=always --smart-case "
INITIAL_QUERY="${*:-}"
# shellcheck disable=SC2016
fzf --ansi --disabled --query "$INITIAL_QUERY" \
	--bind "start:reload:$RG_PREFIX {q}" \
	--bind "change:reload:sleep 0.1; $RG_PREFIX {q} || true" \
	--bind 'ctrl-t:transform:[[ ! $FZF_PROMPT =~ ripgrep ]] &&
      echo "rebind(change)+change-prompt(1. ripgrep> )+disable-search+transform-query:echo \{q} > /tmp/rg-fzf-f; cat /tmp/rg-fzf-r" ||
      echo "unbind(change)+change-prompt(2. fzf> )+enable-search+transform-query:echo \{q} > /tmp/rg-fzf-r; cat /tmp/rg-fzf-f"' \
	--color "hl:-1:underline,hl+:-1:underline:reverse" \
	--prompt '1. ripgrep> ' \
	--delimiter : \
	--header 'CTRL-T: Switch between ripgrep/fzf' \
	--preview 'bat --color=always {1} --highlight-line {2}' \
	--preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
	--bind 'enter:become(command "$EDITOR" {1}:{2}:{3})'
