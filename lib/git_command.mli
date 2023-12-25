val git_silent : string -> unit
(** Invoke a git command with arguments *)

val git:  string -> unit
(** Invoke a git command with arguments and print the result to stdout *)

val git_stdout: string -> string
(** Invoke a git command with arguments and capture the stdout output *)
