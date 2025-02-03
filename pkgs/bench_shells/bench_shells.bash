# zsh should be first, because it often makes much slower with the completion
hyperfine --warmup 1 --runs 5 \
	'zsh --interactive -c exit' \
	'bash -i -c exit' \
	'nu --interactive --commands exit'
