open Base

(* INTERNALS *)

let git_silent = Git_command.git_silent

let git = Git_command.git

let git_stdout = Git_command.git_stdout

let status = Status.status

let get_current_branch () : string =
  git_stdout "rev-parse --abbrev-ref HEAD"

let fetch_main_branch () : string =
  let remote_main_branch =
    git_stdout "rev-parse --abbrev-ref origin/HEAD"
  in
  Process.proc_stdout @@ Printf.sprintf "basename %s" remote_main_branch
(* TODO: use pure function *)

let branch_or_main (branch_opt : string option) : string =
  match branch_opt with
  | Some branch -> branch
  | None -> fetch_main_branch ()

(* Read user login from user.login in git config. *)
let get_login () : string option =
  let login = git_stdout "user.login" in
  if String.is_empty login then None else Some login

let mk_branch_description (description : string list) : string =
  let is_valid_char c =
    Char.is_alphanum c
    || Char.is_whitespace c
    || List.exists ~f:(Char.( = ) c) [ '/'; '-'; '_' ]
  in
  Extended_string.unwords description
  |> String.filter ~f:is_valid_char
  |> Extended_string.words
  |> String.concat ~sep:"-"

(* PUBLIC API *)

type force_flag = NoForce | Force
type tag_action = Delete | Create

let clear force =
  let clear_changes () =
    git "add .";
    git "reset --hard"
  in

  let prompt =
    "'zbg clear' deletes all uncommited changes !!! PERMANENTLY !!!\n\
    \   HINT: If you want to recover them later, use 'zbg stash' instead.\n\
    \   Are you sure you to delete all uncommited changes? (y/N)"
  in

  match force with
  | Force -> clear_changes ()
  | NoForce -> (
      Message.warning prompt;
      let open Prompt in
      match yesno ~def:No with
      | No -> Message.info "Aborting 'zbg clear'"
      | Yes -> clear_changes ())

let commit message_words =
  let message = Extended_string.unwords message_words in
  git "add .";
  match message with
  | "" -> git "commit"
  | message -> git @@ Printf.sprintf "commit --message=%S" message

let log commit =
  (* Log format is:

     ➡️ ecf8c6f: Implement 'uncommit'  (tag: v0.0.0)
        Author: Dmitrii Kovanikov <kovanikov@gmail.com>
          Date: 26 Mar 2023 18:38:58 +0100
  *)
  let log_format =
    "➡️  %C(bold green)%h%C(reset): %C(italic cyan)%s%C(reset) \
     %C(yellow)%d%C(reset)%n     %C(bold blue)Author%C(reset): %an \
     <%ae>%n       %C(bold blue)Date%C(reset): %cd%n"
  in
  let date_format = "%d %b %Y %H:%M:%S %z" in
  git_silent
  @@ Printf.sprintf "log --date='format:%s' --format='format: %s' %s"
       date_format log_format commit

let new_ description =
  let create_branch branch_name =
    git @@ Printf.sprintf "checkout -b %s" branch_name
  in
  let branch_description = mk_branch_description description in
  let branch_name =
    match get_login () with
    | Some login -> login ^ "/" ^ branch_description
    | None ->
        let warning_msg =
          "Unknown user login! Set it globally via:\n\n\
          \    git config --global user.login <your_github_username>"
        in
        Message.warning warning_msg;
        branch_description
  in
  create_branch branch_name

let push force =
  let current_branch = get_current_branch () in
  let flag_option =
    match force with
    | NoForce -> ""
    | Force -> "--force"
  in
  git @@ Printf.sprintf "push --set-upstream origin %s %s" current_branch flag_option

let rebase branch_opt =
  let branch = branch_or_main branch_opt in
  git @@ Printf.sprintf "fetch origin %s" branch;
  git @@ Printf.sprintf "rebase origin/%s" branch

let stash msg_opt =
  let msg_arg =
    match msg_opt with
    | None -> ""
    | Some msg -> Printf.sprintf "--message=%S" msg
  in
  git @@ Printf.sprintf "stash push --include-untracked %s" msg_arg

let switch branch_opt =
  let branch = branch_or_main branch_opt in
  git @@ Printf.sprintf "checkout %s" branch;
  git "pull --ff-only --prune"

let sync force =
  let current_branch = get_current_branch () in
  match force with
  | NoForce ->
      git
      @@ Printf.sprintf "pull --ff-only origin %s" current_branch
  | Force ->
      git @@ Printf.sprintf "fetch origin %s" current_branch;
      git @@ Printf.sprintf "reset --hard origin/%s" current_branch

let tag tag_name tag_action =
  match tag_action with
  | Create ->
      (* create tag locally *)
      git
      @@ Printf.sprintf
           "tag --annotate %s --message='Tag for the %s release'" tag_name
           tag_name;
      (* push tags *)
      git "push origin --tags"
  | Delete ->
      (* delete tag locally *)
      git @@ Printf.sprintf "tag --delete %s" tag_name;
      (* delete tag remotely *)
      git @@ Printf.sprintf "push --delete origin %s" tag_name

let uncommit () = git "reset HEAD~1"
let unstash () = git "stash pop"

let done_ () =
  let prev_branch = get_current_branch () in
  let main_branch = fetch_main_branch () in
  switch (Some main_branch);
  if String.( <> ) prev_branch main_branch then
    git @@ Printf.sprintf "branch --delete %s" prev_branch
