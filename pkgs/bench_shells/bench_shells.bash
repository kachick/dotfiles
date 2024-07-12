# ~ my feeling ~
# 50ms : blazing fast!
# 110ms : acceptable
# 150ms : slow
# 200ms : 1980s?
# 300ms : much slow!

# zsh should be first, because it often makes much slower with the completion
hyperfine --warmup 1 --runs 5 \
	'zsh --interactive -c exit' \
	'bash -i -c exit' \
	'fish --interactive --command exit'
