open Unix

let usage () =
  print_endline "Usage: run_local_hook <hook_name> [args...]";
  print_endline "You should remove local hooks as `git config --local --unset core.hooksPath` to prefer global hooks for the entry point"

let get_repo_path () =
  let ic = Unix.open_process_in "git rev-parse --show-toplevel" in
  try
    let line = input_line ic in
    ignore (Unix.close_process_in ic);
    String.trim line
  with End_of_file ->
    ignore (Unix.close_process_in ic);
    failwith "failed to get repository path"

let file_exists path =
  try ignore (Unix.stat path); true
  with Unix_error _ -> false

let () =
  if Array.length Sys.argv < 2 then begin
    usage ();
    exit 2
  end;

  let hook_name = Sys.argv.(1) in
  let args = Array.sub Sys.argv 2 (Array.length Sys.argv - 2) in

  let repo_path =
    try get_repo_path ()
    with e ->
      prerr_endline ("failed to get repository path: " ^ Printexc.to_string e);
      exit 1
  in

  let trusted_env = try Sys.getenv "GIT_HOOKS_TRUST_REPOS" with Not_found -> "" in
  let trusted_paths = String.split_on_char ':' trusted_env in

  let hooks_dir = Filename.concat repo_path (Filename.concat ".git" "hooks") in
  let local_hook_path = Filename.concat hooks_dir hook_name in

  (* Basic path traversal check: hook_name shouldn't contain '/' or '\' ideally, 
     or just shouldn't be able to escape hooks_dir. *)
  if String.contains hook_name '/' || String.contains hook_name '\\' || hook_name = ".." || hook_name = "." then begin
    prerr_endline ("invalid hook name: " ^ hook_name);
    exit 1
  end;

  if not (file_exists local_hook_path) then exit 0;

  if not (List.mem repo_path trusted_paths) then begin
    print_endline "Found an ignored local hook.";
    print_endline "You can allow it as:";
    Printf.printf "export GIT_HOOKS_TRUST_REPOS=\"%s:%s\"\n" trusted_env repo_path;
    exit 0
  end;

  (* execute the hook *)
  let cmd_args = Array.append [|local_hook_path|] args in
  let pid = Unix.create_process local_hook_path cmd_args Unix.stdin Unix.stdout Unix.stderr in
  let _, status = Unix.waitpid [] pid in
  match status with
  | WEXITED 0 -> exit 0
  | WEXITED n -> exit n
  | _ -> exit 1
