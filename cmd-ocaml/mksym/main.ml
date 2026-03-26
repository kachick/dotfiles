open Unix

let linker_flag = ref ""
let linked_flag = ref ""

let usage_msg = "Usage: mksym -linker <path> -linked <path>"

let speclist =
  [ ("-linker", Arg.Set_string linker_flag, "path - from")
  ; ("-linked", Arg.Set_string linked_flag, "path - to")
  ]

let fail msg =
  prerr_endline msg;
  exit 1

let mkdir_all path perm =
  let rec build p =
    if not (Sys.file_exists p) then begin
      let parent = Filename.dirname p in
      if parent <> p then build parent;
      Unix.mkdir p perm
    end
  in
  build path

let () =
  Arg.parse speclist (fun _ -> ()) usage_msg;

  let linker = !linker_flag in
  let linked = !linked_flag in

  if linker = "" || linked = "" then begin
    Arg.usage speclist usage_msg;
    fail "empty path is given"
  end;

  let linked_abs =
    if Filename.is_relative linked then
      Filename.concat (Sys.getcwd ()) linked
    else
      linked
  in

  let fi =
    try Unix.lstat linked_abs
    with Unix_error (e, _, _) ->
      fail (Printf.sprintf "target does not exist, fix `linked` option - %s" (Unix.error_message e))
  in

  if fi.st_kind = S_LNK then
    fail "path for linked to is a symlink, you should be wrong how to use this command!";

  let linker_exists =
    try
      ignore (Unix.lstat linker);
      true
    with Unix_error (ENOENT, _, _) -> false
       | Unix_error (e, _, _) ->
           fail (Printf.sprintf "error checking linker: %s" (Unix.error_message e))
  in

  if linker_exists then
    fail "this script does not override existing symlinker files, fix `linker` option or manually remove the file";

  let parent = Filename.dirname linker in
  (try mkdir_all parent 0o755
   with Unix_error (e, _, _) ->
     fail (Printf.sprintf "failed in creating directory structure - %s" (Unix.error_message e)));

  try Unix.symlink linked_abs linker
  with Unix_error (e, _, _) ->
    fail (Printf.sprintf "failed in symlink creation - %s" (Unix.error_message e))
