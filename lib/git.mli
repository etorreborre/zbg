(* Set Force when [-f|--force] flag is provided *)
type force_flag = NoForce | Force

(* Action to do with the tag: delete or create *)
type tag_action = Delete | Create

val git_silent : string -> unit
(** Invoke a git command with arguments *)

val git:  string -> unit
(** Invoke a git command with arguments and print the result to stdout *)

val git_stdout: string -> string
(** Invoke a git command with arguments and capture the stdout output *)

val clear : force_flag -> unit
(** Clear all local changes unrecoverably. *)

val commit : string list -> unit
(** Commit all local changes. *)

val done_ : unit -> unit
(** Switch to the main branch and delete the previous one. *)

val log : string -> unit
(** Show pretty log. *)

val new_ : string list -> unit
(** Create new branch. *)

val push : force_flag -> unit
(** Push the current branch to origin. *)

val rebase : string option -> unit
(** Rebase local branch on top of origin/<branch>. *)

val stash : string option -> unit
(** Stash all local changes. *)

val status : string -> unit
(** Show pretty status of local changes. *)

val switch : string option -> unit
(** Switch to a new branch and update to the latest version of origin. *)

val sync : force_flag -> unit
(** Sync local branch with the remote branch. *)

val tag : string -> tag_action -> unit
(** Create or delete tag. *)

val uncommit : unit -> unit
(** Undo last commit. *)

val unstash : unit -> unit
(** Unstash latest changes. *)
