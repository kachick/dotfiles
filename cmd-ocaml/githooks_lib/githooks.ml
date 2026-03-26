type linter = {
  tag : string;
  script : unit -> (unit, string) result
}

let make_skip_checker () =
  let skip_env = try Sys.getenv "SKIP" with Not_found -> "" in
  let skips = String.split_on_char ',' skip_env |> List.map String.trim in
  fun tag -> List.mem tag skips

let run_linters linters should_skip =
  let running = ref [] in
  List.iter (fun (desc, linter) ->
    if not (should_skip linter.tag) then begin
      prerr_endline desc;
      let d = Domain.spawn (fun () ->
        match linter.script () with
        | Ok () -> None
        | Error e -> Some (desc, e)
      ) in
      running := d :: !running
    end
  ) linters;
  let errors =
    List.fold_left (fun acc d ->
      match Domain.join d with
      | None -> acc
      | Some err -> err :: acc
    ) [] !running
  in
  match errors with
  | [] -> Ok ()
  | errs -> Error errs
