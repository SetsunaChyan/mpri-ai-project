(*
  Cours "Typage et Analyse Statique"
  Université Pierre et Marie Curie
  Antoine Miné 2015
*)

(* 
  Pretty-printer for abstract syntax trees.
*)

open Format
open Abstract_syntax_tree

(* locations *)
val string_of_position : position -> string
val string_of_extent : extent -> string

(* printers *)
val print_typ : formatter -> typ -> unit
val print_var : formatter -> var -> unit
val print_int_expr : formatter -> int_expr -> unit
val print_bool_expr : formatter -> bool_expr -> unit
val print_stat : string -> formatter -> stat -> unit

val print_block :
  string -> formatter -> (typ * var) ext list -> stat ext list -> unit

val print_prog : formatter -> prog -> unit
