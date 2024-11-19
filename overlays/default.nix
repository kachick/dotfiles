{ edge-nixpkgs, ... }:
[
  (final: _prev: {
    my = import ../pkgs {
      pkgs = final.pkgs;
    };
  })

  (final: _prev: {
    unstable = import edge-nixpkgs {
      system = final.system;
    };
  })
]
