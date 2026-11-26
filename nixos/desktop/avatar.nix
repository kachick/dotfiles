{
  config,
  pkgs,
  lib,
  ...
}:

let
  normalUsers = lib.attrNames (lib.filterAttrs (_: user: user.isNormalUser) config.users.users);

  # Assign a one-time random avatar from GNOME's stock faces to normal users
  # who do not have an avatar yet.
  #
  # WHY activationScript instead of systemd.tmpfiles.rules:
  # - tmpfiles `L+`/`f+` overwrites manual changes made later by the user.
  # - Picking among the least-used faces (matched by SHA-256) avoids duplicate
  #   avatars across users without persisting extra state.
  assignUserAvatars = pkgs.writeShellApplication {
    name = "assign-user-avatars";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnugrep
      pkgs.gnused
    ];
    text = ''
      set -euo pipefail

      if [[ $# -lt 3 ]]; then
        exit 0
      fi

      faces_dir="$1"
      accounts_dir="$2"
      shift 2
      users=("$@")

      if [[ ! -d "$faces_dir" ]]; then
        exit 0
      fi

      faces=()
      for file in "$faces_dir"/*; do
        if [[ -f "$file" ]]; then
          faces+=("$file")
        fi
      done

      if [[ ''${#faces[@]} -eq 0 ]]; then
        exit 0
      fi

      icons_dir="$accounts_dir/icons"
      users_dir="$accounts_dir/users"
      mkdir --parents "$icons_dir" "$users_dir"

      declare -A face_hash=()
      declare -A hash_count=()
      for face in "''${faces[@]}"; do
        hash=$(sha256sum "$face" | cut --delimiter=' ' --fields=1)
        face_hash["$face"]="$hash"
        hash_count["$hash"]=0
      done

      declare -A counted_users=()
      for user_file in "$users_dir"/*; do
        [[ -f "$user_file" ]] || continue
        user_name=$(basename "$user_file")
        icon_path=$(sed --silent --regexp-extended 's/^Icon=(.+)$/\1/p' "$user_file" | head --lines=1)
        if [[ -n "$icon_path" && -f "$icon_path" ]]; then
          hash=$(sha256sum "$icon_path" | cut --delimiter=' ' --fields=1)
          if [[ -n "''${hash_count[$hash]+x}" ]]; then
            hash_count["$hash"]=$((hash_count["$hash"] + 1))
          fi
          counted_users["$user_name"]=1
        fi
      done

      for icon_file in "$icons_dir"/*; do
        [[ -f "$icon_file" ]] || continue
        user_name=$(basename "$icon_file")
        [[ -n "''${counted_users[$user_name]+x}" ]] && continue
        hash=$(sha256sum "$icon_file" | cut --delimiter=' ' --fields=1)
        if [[ -n "''${hash_count[$hash]+x}" ]]; then
          hash_count["$hash"]=$((hash_count["$hash"] + 1))
        fi
      done

      for user in "''${users[@]}"; do
        icon_file="$icons_dir/$user"
        user_file="$users_dir/$user"

        if [[ -e "$icon_file" ]]; then
          continue
        fi
        if [[ -f "$user_file" ]] && grep --quiet --extended-regexp '^Icon=.+' "$user_file"; then
          continue
        fi

        min_count=""
        for face in "''${faces[@]}"; do
          count="''${hash_count[''${face_hash[$face]}]}"
          if [[ -z "$min_count" || "$count" -lt "$min_count" ]]; then
            min_count="$count"
          fi
        done

        candidates=()
        for face in "''${faces[@]}"; do
          if [[ "''${hash_count[''${face_hash[$face]}]}" -eq "$min_count" ]]; then
            candidates+=("$face")
          fi
        done

        chosen=$(printf '%s\0' "''${candidates[@]}" | shuf --zero-terminated --head-count=1 | tr --delete '\0')
        install --mode=0644 "$chosen" "$icon_file"

        if [[ ! -f "$user_file" ]]; then
          printf '[User]\nIcon=%s\nSystemAccount=false\n' "$icon_file" >"$user_file"
          chmod 0600 "$user_file"
        elif grep --quiet --extended-regexp '^Icon=$' "$user_file"; then
          sed --in-place --regexp-extended "s|^Icon=$|Icon=$icon_file|" "$user_file"
        elif grep --quiet --fixed-strings '[User]' "$user_file"; then
          sed --in-place "0,/^\[User\]$/s|^\[User\]$|[User]\nIcon=$icon_file|" "$user_file"
        else
          printf '\n[User]\nIcon=%s\n' "$icon_file" >>"$user_file"
        fi

        chosen_hash="''${face_hash[$chosen]}"
        hash_count["$chosen_hash"]=$((hash_count["$chosen_hash"] + 1))
      done
    '';
  };
in
{
  system.activationScripts.assignUserAvatars = {
    deps = [ "users" ];
    text = lib.optionalString (normalUsers != [ ]) ''
      ${lib.getExe assignUserAvatars} \
        ${pkgs.gnome-control-center}/share/pixmaps/faces \
        /var/lib/AccountsService \
        ${lib.escapeShellArgs normalUsers}
    '';
  };
}
