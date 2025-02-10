(*
  Cours "Typage et Analyse Statique"
  Université Pierre et Marie Curie
  Antoine Miné 2015
*)

(* 
   Signature of domains (abstract or concrete) representing sets of envrionments
 *)

open Frontend.Abstract_syntax_tree

module type DOMAIN = sig
  (* type of abstract elements *)
  (* an element of type t abstracts a set of mappings from variables
       to integers
     *)
  type t

  (* initial environment, without any variable *)
  val init : unit -> t

  (* empty set *)
  val bottom : unit -> t

  (* add a variable *)
  val add_var : t -> var -> t

  (* remove a variable *)
  val del_var : t -> var -> t

  (* assign an integer expression to a variable *)
  val assign : t -> var -> int_expr -> t

  (* filter environments to keep only those satisfying the comparison *)
  val compare : t -> int_expr -> compare_op -> int_expr -> t

  (* abstract join *)
  val join : t -> t -> t

  (* abstract intersection *)
  val meet : t -> t -> t

  (* widening *)
  val widen : t -> t -> t

  (* whether an abstract element is included in another one *)
  val subset : t -> t -> bool

  (* whether the abstract element represents the empty set *)
  val is_bottom : t -> bool

  (* prints *)
  val print : Format.formatter -> t -> var list -> unit
  val print_all : Format.formatter -> t -> unit
end
