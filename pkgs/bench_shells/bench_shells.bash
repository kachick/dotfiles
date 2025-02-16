# zsh should be first, because it often makes much slower with the completion
hyperfine --warmup 1 --runs 3 --shell none "$@" \
	'zsh --interactive -c exit' \
	'zsh --no-rcs --interactive -c exit' \
	'bash -i -c exit' \
	'bash --norc -i -c exit' \
	'nu --interactive --commands exit' \
	'nu --no-config-file --interactive --commands exit'
