{ pkgs, ... }:
{
  # Daily desktop GUI apps excluded from the recovery/installer Live CD
  # to keep the ISO smaller and free of Electron runtimes.
  environment.systemPackages = with pkgs; [
    # gnome-music does not support flac.
    # tramhao/termusic and tsirysndr/music-player does not figure how to use.
    rhythmbox

    newsflash # `io.gitlab.news_flash.NewsFlash`

    # calibre # Don't install calibre if possible. It has much of Python and JavaScript dependencies. And it sets the E-book reader for opening markdown files by default.
    readest # ebook(epub) reader. Prefer this than unstable Alexandria and heavy calibre

    # Using unstable to test own patch: https://github.com/NixOS/nixpkgs/pull/463074
    podman-desktop

    # As signal, it heavyly relies on their service, the delay of waiting stable version does not make sense
    signal-desktop
  ];
}
