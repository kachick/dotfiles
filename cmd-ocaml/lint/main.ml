open Unix

let ignored_directories = [ ".git"; ".direnv"; "dist"; "result"; "tmp"; "dependencies"; ".rumdl_cache" ]

let is_ignored d = List.mem d ignored_directories

let is_bash f =
  Filename.check_suffix f ".bash" || (String.starts_with ~prefix:"bash" f && not (Filename.check_suffix f ".nix"))

let is_nix f =
  Filename.check_suffix f ".nix"

let get_files root =
  let bash_files = ref [] in
  let nix_files = ref [] in
  let rec walk path =
    let is_dir =
      try (Unix.lstat path).st_kind = S_DIR
      with Unix_error _ -> false
    in
    if is_dir then begin
      let base = Filename.basename path in
      if not (is_ignored base) then begin
        let dir = Unix.opendir path in
        try
          while true do
            let entry = Unix.readdir dir in
            if entry <> "." && entry <> ".." then
              walk (Filename.concat path entry)
          done
        with End_of_file -> Unix.closedir dir
           | e -> Unix.closedir dir; raise e
      end
    end else begin
      let base = Filename.basename path in
      if is_bash base then bash_files := path :: !bash_files;
      if is_nix base then nix_files := path :: !nix_files
    end
  in
  walk root;
  (!bash_files, !nix_files)

type cmd = { path: string; args: string list }

let get_exhaustruct_path () =
  (* Call: go tool -n exhaustruct *)
  let ic = Unix.open_process_in "go tool -n exhaustruct" in
  try
    let line = input_line ic in
    ignore (Unix.close_process_in ic);
    String.trim line
  with End_of_file ->
    ignore (Unix.close_process_in ic);
    failwith "Missing exhaustruct as a vettool"

let truncate s max_len =
  if String.length s > max_len then
    String.sub s 0 (max_len - 3) ^ "..."
  else s

let run_parallel cmds =
  let pids =
    List.map (fun cmd ->
      let args_arr = Array.of_list (cmd.path :: cmd.args) in
      (* We want combined output, but Unix.create_process doesn't capture easily without redirecting to a file.
         To keep it simple and match Go's combined output, we can redirect to a temporary file for each process. *)
      let tmp_out = Filename.temp_file "lint_" ".out" in
      let fd = Unix.openfile tmp_out [O_WRONLY; O_CREAT; O_TRUNC] 0o600 in
      let pid = Unix.create_process cmd.path args_arr Unix.stdin fd fd in
      Unix.close fd;
      (pid, cmd, tmp_out)
    ) cmds
  in
  let errors = ref false in
  List.iter (fun (pid, cmd, tmp_out) ->
    let _, status = Unix.waitpid [] pid in
    let args_str = String.concat " " cmd.args in
    let truncated_args = truncate args_str 60 in
    Printf.printf "%s %s\n" cmd.path truncated_args;
    
    let ic = open_in tmp_out in
    try
      while true do
        print_endline (input_line ic)
      done
    with End_of_file ->
      close_in ic;
      Sys.remove tmp_out;
      match status with
      | WEXITED 0 -> ()
      | _ ->
        errors := true;
        Printf.eprintf "Command failed: %s %s\n" cmd.path args_str
  ) pids;
  if !errors then exit 1

let () =
  let all_flag = ref false in
  Arg.parse [("-all", Arg.Set all_flag, "includes heavy linters")] (fun _ -> ()) "Usage: lint [-all]";

  let bash_files, nix_files = get_files "." in

  let linters =
    [ { path = "shellcheck"; args = bash_files }
    ; { path = "typos"; args = ["."; ".github"; ".vscode"] }
    ; { path = "nixf-diagnose"; args = "--" :: nix_files }
    ]
  in

  let heavy_linters =
    if !all_flag then
      [ { path = "go"; args = ["vet"; "-vettool"; get_exhaustruct_path (); "./..."] }
      ; { path = "rumdl"; args = ["check"; "."] }
      ; { path = "trivy"; args = ["config"; "--exit-code"; "1"; "."] }
      ; { path = "zizmor"; args = ["."] }
      ; { path = "kanata"; args = ["--check"; "--cfg"; "config/keyboards/kanata.kbd"] }
      ; { path = "desktop-file-validate"; args = ["config/keyboards/kanata-tray.desktop"] }
      ]
    else []
  in

  run_parallel (linters @ heavy_linters)
