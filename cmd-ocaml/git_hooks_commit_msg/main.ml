open Unix
open Githooks_lib.Githooks

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

let run_cmd_stdin path args stdin_file =
  let fd_in = Unix.openfile stdin_file [O_RDONLY] 0 in
  let res = run_cmd path args fd_in in
  Unix.close fd_in;
  res

let run_cmd_no_stdin path args =
  let fd_in = Unix.openfile "/dev/null" [O_RDONLY] 0 in
  let res = run_cmd path args fd_in in
  Unix.close fd_in;
  res

let () =
  if Array.length Sys.argv < 2 then begin
    prerr_endline "Body of commit message is not given with $1";
    exit 1
  end;
  let msg_path = Sys.argv.(1) in
  let typos_config_path = try Sys.getenv "TYPOS_CONFIG_PATH" with Not_found -> "typos.toml" in

  let should_skip = make_skip_checker () in

  let linters = [
    ("prevent secrets in the message", {
      tag = "betterleaks";
      script = (fun () ->
        prerr_endline ("betterleaks --verbose stdin " ^ msg_path);
        run_cmd_stdin "betterleaks" ["--verbose"; "stdin"; msg_path] msg_path
      )
    });
    ("prevent typos in the message", {
      tag = "typos";
      script = (fun () ->
        prerr_endline ("typos --config " ^ typos_config_path ^ " " ^ msg_path);
        run_cmd_no_stdin "typos" ["--config"; typos_config_path; msg_path]
      )
    })
  ] in

  match run_linters linters should_skip with
  | Error _ ->
      prerr_endline "Failed to run global hook";
      exit 1
  | Ok () ->
      if not (should_skip "localhook") then begin
        prerr_endline "run local hook";
        let res = run_cmd_no_stdin "run_local_hook" ["commit-msg"; msg_path] in
        match res with
        | Ok () -> ()
        | Error _ ->
            prerr_endline "Failed to run local hook";
            exit 1
      end
