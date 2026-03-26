open Unix
open Githooks_lib.Githooks

let get_output cmd args =
  let ic = Unix.open_process_args_in cmd (Array.of_list (cmd :: args)) in
  let res = try Some (input_line ic) with End_of_file -> None in
  ignore (Unix.close_process_in ic);
  match res with
  | Some s -> String.trim s
  | None -> failwith ("Command failed: " ^ cmd)

let run_cmd path args stdin_fd =
  let tmp_out = Filename.temp_file "hook_" ".out" in
  let fd_out = Unix.openfile tmp_out [O_WRONLY; O_CREAT; O_TRUNC] 0o600 in
  let pid = Unix.create_process path (Array.of_list (path :: args)) stdin_fd fd_out fd_out in
  Unix.close fd_out;
  let _, status = Unix.waitpid [] pid in
  
  let ic = open_in tmp_out in
  try
    while true do
      prerr_endline (input_line ic)
    done
  with End_of_file ->
    close_in ic;
    Sys.remove tmp_out;
    match status with
    | WEXITED 0 -> Ok ()
    | _ -> Error "command failed"

let run_cmd_no_stdin path args =
  let fd_in = Unix.openfile "/dev/null" [O_RDONLY] 0 in
  let res = run_cmd path args fd_in in
  Unix.close fd_in;
  res

let run_cmd_string_stdin path args input_str =
  let tmp_in = Filename.temp_file "hook_in_" ".txt" in
  let oc = open_out tmp_in in
  output_string oc input_str;
  close_out oc;
  let fd_in = Unix.openfile tmp_in [O_RDONLY] 0 in
  let res = run_cmd path args fd_in in
  Unix.close fd_in;
  Sys.remove tmp_in;
  res

let run_pipeline cmd1 args1 cmd2 args2 =
  (* git log ... | typos ... *)
  let tmp_out = Filename.temp_file "hook_" ".out" in
  let fd_out = Unix.openfile tmp_out [O_WRONLY; O_CREAT; O_TRUNC] 0o600 in
  let fd_null = Unix.openfile "/dev/null" [O_RDONLY] 0 in
  
  let pipe_in, pipe_out = Unix.pipe () in
  
  let pid1 = Unix.create_process cmd1 (Array.of_list (cmd1 :: args1)) fd_null pipe_out pipe_out in
  let pid2 = Unix.create_process cmd2 (Array.of_list (cmd2 :: args2)) pipe_in fd_out fd_out in
  
  Unix.close pipe_out;
  Unix.close pipe_in;
  Unix.close fd_null;
  Unix.close fd_out;
  
  let _, _ = Unix.waitpid [] pid1 in
  let _, status2 = Unix.waitpid [] pid2 in
  
  let ic = open_in tmp_out in
  try
    while true do prerr_endline (input_line ic) done
  with End_of_file ->
    close_in ic;
    Sys.remove tmp_out;
    match status2 with
    | WEXITED 0 -> Ok ()
    | _ -> Error "pipeline failed"

let initialize_linters line remote_branch email typos_config_path =
  let fields = String.split_on_char ' ' line |> List.filter (fun s -> s <> "") in
  if List.length fields <> 4 then
    failwith ("parsing error for given line: " ^ line);
  let local_ref = List.nth fields 0 in
  let remote_ref = List.nth fields 2 in
  
  [
    ("prevent secrets in log and diff", {
      tag = "betterleaks";
      script = (fun () ->
        prerr_endline "betterleaks ...";
        run_cmd_no_stdin "betterleaks" [
          "--verbose"; "git"; 
          Printf.sprintf "--log-opts=--author=%s %s..%s" email remote_branch local_ref
        ]
      )
    });
    ("prevent typos in log and diff", {
      tag = "typos";
      script = (fun () ->
        prerr_endline "git log | typos";
        run_pipeline "git" [
          "log"; "--author=" ^ email; "--patch"; "--unified=0"; Printf.sprintf "%s..%s" remote_branch local_ref
        ] "typos" ["--config"; typos_config_path; "-"]
      )
    });
    ("prevent typos in branch name", {
      tag = "typos";
      script = (fun () ->
        prerr_endline "typos branch name";
        run_cmd_string_stdin "typos" ["--config"; typos_config_path; "-"] (Filename.basename remote_ref)
      )
    })
  ]

let read_lines () =
  let rec loop acc =
    try loop (input_line Stdlib.stdin :: acc)
    with End_of_file -> List.rev acc
  in loop []

let () =
  let remote_default_branch = get_output "git" ["symbolic-ref"; "refs/remotes/origin/HEAD"] in
  let email = get_output "git" ["config"; "user.email"] in
  let typos_config_path = try Sys.getenv "TYPOS_CONFIG_PATH" with Not_found -> "typos.toml" in

  let should_skip = make_skip_checker () in

  let lines = read_lines () in
  let linters = ref [] in
  List.iteri (fun i line ->
    try
      let l = initialize_linters line remote_default_branch email typos_config_path in
      List.iter (fun (desc, linter) ->
        linters := (Printf.sprintf "L%d:%s:%s" (i + 1) line desc, linter) :: !linters
      ) l
    with e -> prerr_endline ("Error: " ^ Printexc.to_string e)
  ) lines;

  match run_linters (List.rev !linters) should_skip with
  | Error _ ->
      prerr_endline "Failed to run global hook";
      exit 1
  | Ok () ->
      if not (should_skip "localhook") then begin
        let args = Array.to_list Sys.argv |> List.tl in
        let res = run_cmd_no_stdin "run_local_hook" ("pre-push" :: args) in
        match res with
        | Ok () -> ()
        | Error _ ->
            prerr_endline "Failed to run local hook";
            exit 1
      end
