system="$1"
nix eval --raw ".#packages.${system}" \
	--apply 'ps: builtins.concatStringsSep "\n" (builtins.filter (n: (builtins.getAttr n ps).passthru.shared-gomod or false) (builtins.attrNames ps))'
