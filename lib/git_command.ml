open Base

(* INTERNALS *)

(* Prepare a command to invoke as a string, with the HOME environment variable set *)
let mk_command (arguments : string) : string =
  let home_dir = Unix.getenv "HOME" in
  Printf.sprintf "HOME=%s %s" home_dir arguments

(* Prepare a git command to invoke as a string. Make sure that the HOME environment variable is set *)
let git_command (arguments : string) : string =
  mk_command @@ Printf.sprintf "git %s" arguments

(* Invoke a git command with arguments *)
let git_silent (arguments : string) : unit =
  Process.proc_silent @@ git_command arguments

(* Invoke a git command with arguments and print the result to stdout *)
let git (arguments : string) : unit =
  Process.proc @@ git_command arguments

(* Invoke a git command with arguments and capture the stdout output *)
let git_stdout (arguments : string) : string =
  Process.proc_stdout @@ git_command arguments
