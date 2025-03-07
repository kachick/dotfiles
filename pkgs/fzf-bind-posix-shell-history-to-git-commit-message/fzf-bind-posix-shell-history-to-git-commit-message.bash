# Why trimming?
# - bash keeps whitespace prefix even specified -n option for fc -l
# - lstrip is not enough for some history
# - Keep line-end in fzf input
# shellcheck disable=SC2016 disable=SC2086
nu --stdin --commands 'lines | each { str trim } | to text' |
	fzf --height ''${FZF_TMUX_HEIGHT:-40%} ''${FZF_DEFAULT_OPTS-} \
		-n2..,.. --scheme=history \
		--bind 'enter:become(safe_quote_backtik {} | git commit -a -F -)'
