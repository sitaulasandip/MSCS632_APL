(* stats.ml - Functional statistics calculator (mean, median, mode).

   Build:  ocamlopt stats.ml -o stats   (or run directly: ocaml stats.ml)
   Usage:  ./stats                 runs the built-in sample datasets
           ./stats 4 8 15 16 23    computes statistics for the given integers

   Every value is immutable; statistics are built from List.fold_left,
   List.map, List.filter_map and recursion instead of loops and counters. *)

(* Each statistic returns an option so an empty list is handled explicitly. *)

let mean = function
  | [] -> None
  | xs ->
      let sum = List.fold_left ( + ) 0 xs in
      Some (float_of_int sum /. float_of_int (List.length xs))

let median xs =
  match List.sort compare xs with
  | [] -> None
  | sorted ->
      let n = List.length sorted in
      let at i = float_of_int (List.nth sorted i) in
      if n mod 2 = 1 then Some (at (n / 2))
      else Some ((at (n / 2 - 1) +. at (n / 2)) /. 2.0)

(* Run-length encodes a sorted list: [1; 1; 2] -> [(1, 2); (2, 1)]. *)
let frequencies sorted =
  List.fold_right
    (fun x acc ->
      match acc with
      | (y, count) :: rest when y = x -> (y, count + 1) :: rest
      | _ -> (x, 1) :: acc)
    sorted []

(* Returns every value tied for the highest frequency, plus that frequency. *)
let mode = function
  | [] -> None
  | xs ->
      let freqs = frequencies (List.sort compare xs) in
      let highest = List.fold_left (fun best (_, c) -> max best c) 0 freqs in
      let modes =
        List.filter_map (fun (v, c) -> if c = highest then Some v else None) freqs
      in
      Some (modes, highest)

let mean_of_floats = function
  | [] -> None
  | fs -> Some (List.fold_left ( +. ) 0.0 fs /. float_of_int (List.length fs))

(* Population standard deviation, built on top of mean. *)
let std_dev xs =
  match mean xs with
  | None -> None
  | Some m ->
      let squared_diffs = List.map (fun x -> (float_of_int x -. m) ** 2.0) xs in
      Option.map sqrt (mean_of_floats squared_diffs)

let show_list xs = "[" ^ String.concat ", " (List.map string_of_int xs) ^ "]"

let show_float = function
  | None -> "undefined"
  | Some f -> Printf.sprintf "%.2f" f

let show_mode = function
  | None -> "undefined"
  | Some (modes, count) ->
      Printf.sprintf "%s (appears %d time%s)" (show_list modes) count
        (if count = 1 then "" else "s")

let report (label, xs) =
  let sorted = List.sort compare xs in
  Printf.printf "=== %s ===\n" label;
  Printf.printf "Input   : %s\n" (show_list xs);
  Printf.printf "Sorted  : %s\n" (show_list sorted);
  Printf.printf "Count   : %d\n" (List.length xs);
  Printf.printf "Mean    : %s\n" (show_float (mean xs));
  Printf.printf "Median  : %s\n" (show_float (median xs));
  Printf.printf "Mode    : %s\n" (show_mode (mode xs));
  (match sorted with
   | [] -> ()
   | lowest :: _ ->
       let highest = List.fold_left max lowest sorted in
       Printf.printf "Range   : %d to %d (spread %d)\n" lowest highest
         (highest - lowest));
  Printf.printf "Std Dev : %s\n\n" (show_float (std_dev xs))

let samples =
  [
    ("Sample A: odd count, single mode", [ 4; 8; 15; 16; 23; 42; 8; 15; 8 ]);
    ("Sample B: even count, two modes", [ 10; 20; 20; 30; 30; 40 ]);
    ("Sample C: negative values", [ -5; 3; -5; 7; 0; 3; -2; 12 ]);
  ]

(* Parses every argument, or returns the first one that is not an integer. *)
let parse_args args =
  List.fold_right
    (fun arg acc ->
      match (int_of_string_opt arg, acc) with
      | Some n, Ok ns -> Ok (n :: ns)
      | None, _ -> Error arg
      | Some _, (Error _ as err) -> err)
    args (Ok [])

let () =
  match List.tl (Array.to_list Sys.argv) with
  | [] ->
      print_string "OCaml (functional) statistics calculator\n\n";
      List.iter report samples
  | args -> (
      match parse_args args with
      | Ok xs -> report ("User input", xs)
      | Error bad ->
          Printf.eprintf "Error: '%s' is not a valid integer\n" bad;
          exit 1)
