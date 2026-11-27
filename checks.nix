{
  pkgs,
  system,
  outputs,
}:

let
  inherit (pkgs) lib;
  systemPackages = outputs.packages.${system};
  devShell = outputs.devShells.${system}.default;

  majorMinor =
    ver:
    let
      parts = lib.splitVersion ver;
    in
    "${builtins.elemAt parts 0}.${builtins.elemAt parts 1}";

  goModContent = builtins.readFile ./go.mod;
  goModMatch = builtins.match ".*\ngo ([0-9]+\\.[0-9]+(\\.[0-9]+)?).*" goModContent;
  goModMinor =
    if goModMatch == null then
      throw "checks.nix: could not find go directive in go.mod"
    else
      majorMinor (builtins.head goModMatch);

  findGoInput =
    inputs:
    let
      matches = builtins.filter (x: (x.pname or null) == "go") inputs;
    in
    if matches == [ ] then null else builtins.head matches;

  devShellGo = findGoInput (devShell.buildInputs or [ ]);
  devShellGoMinor =
    if devShellGo == null then
      throw "checks.nix: go package not found in devShells.${system}.default"
    else
      majorMinor devShellGo.version;

  localGoPackages = lib.pipe systemPackages [
    (lib.mapAttrsToList (
      name: drv:
      let
        goInput = findGoInput (drv.nativeBuildInputs or [ ]);
        isLocalGo = goInput != null && (drv.vendorHash or "external") == null;
      in
      {
        inherit name isLocalGo goInput;
      }
    ))
    (builtins.filter (entry: entry.isLocalGo))
  ];

  goVersionErrors =
    (lib.optional (
      devShellGoMinor != goModMinor
    ) "devShells.${system}.default uses Go ${devShellGoMinor}, but go.mod uses Go ${goModMinor}")
    ++ (lib.optional (
      localGoPackages == [ ]
    ) "checks.nix: found no local Go packages to verify against Go ${goModMinor}")
    ++ (builtins.concatMap (
      entry:
      let
        pkgGoMinor = majorMinor entry.goInput.version;
      in
      lib.optional (
        pkgGoMinor != goModMinor
      ) "packages.${system}.${entry.name} uses Go ${pkgGoMinor}, but go.mod uses Go ${goModMinor}"
    ) localGoPackages);

  listJSON = builtins.fromJSON (builtins.readFile ./pkgs/list.json);
  missingPackages = builtins.filter (name: !(systemPackages ? ${name})) (
    builtins.attrNames listJSON.packages
  );
in
{
  pkgs-list-exists =
    if missingPackages != [ ] then
      throw "pkgs/list.json references unknown packages: ${lib.concatStringsSep ", " missingPackages}"
    else
      pkgs.runCommandLocal "check-pkgs-list-exists" { } "touch $out";

  go-toolchain-sync =
    if goVersionErrors != [ ] then
      throw "Go toolchain version mismatch:\n- ${lib.concatStringsSep "\n- " goVersionErrors}"
    else
      pkgs.runCommandLocal "check-go-toolchain-sync" { } "touch $out";
}
