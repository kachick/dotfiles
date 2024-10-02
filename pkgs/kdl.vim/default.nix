{ pkgs, fetchFromGitHub }:

pkgs.vimUtils.buildVimPlugin {
  pname = "kdl.vim";
  version = "2023-02-20";

  src = fetchFromGitHub {
    owner = "imsnif";
    repo = "kdl.vim";
    rev = "b84d7d3a15d8d30da016cf9e98e2cfbe35cddee5";
    sha256 = "IajKK1EjrKs6b2rotOj+RlBBge9Ii2m/iuIuefnjAE4=";
  };

  meta.homepage = "https://github.com/imsnif/kdl.vim";
}
