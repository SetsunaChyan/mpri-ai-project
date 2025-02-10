(*
  Cours "Typage et Analyse Statique"
  Université Pierre et Marie Curie
  Antoine Miné 2015
*)

(* 
   Lifts a value domain (abstracting sets of integers)
   into a non-relational domain (abstracting sets of maps, 
   from variables to integers)
 *)

open Frontend.Abstract_syntax_tree
open Value_domain
open Domain

(* The module is parameterized by a domain V abstracting sets of integers *)
module NonRelational (V : VALUE_DOMAIN) : DOMAIN = struct
  (* types *)
  (* ***** *)

  (* a map, with variables (strings) as keys *)
  module VarMap = Mapext.Make (String)

  (* type of non-bottom abstract elements:
     maps each variable to an abstract value
   *)
  type env = V.t VarMap.t

  (* type of abstract elements;
     either a map from variables to (non-bottom) abstract values;
     or bottom (empty set)
   *)
  type t = Val of env | BOT

  (* propagates bottom *)
  exception Empty

  (* utilities *)
  (* ********* *)

  (* an integer expression tree, where each node is annotated
     with an abstract set of integers, in V;
     useful for assignemnt and compare
   *)
  type atree =
    | A_unary of int_unary_op * atree * V.t
    | A_binary of int_binary_op * atree * V.t * atree * V.t
    | A_var of var * V.t
    | A_cst of V.t

  (* evaluates an integer expression, by calling the abstract operator from V;
     returns an abstract value for the expression, 
     but also an expression tree with each node annotated by an abstract value
   *)
  let rec eval (m : env) (e : int_expr) : atree * V.t =
    match e with
    | AST_int_unary (op, (e1, _)) ->
        let a1, v1 = eval m e1 in
        (A_unary (op, a1, v1), V.unary v1 op)
    | AST_int_binary (op, (e1, _), (e2, _)) ->
        let a1, v1 = eval m e1 in
        let a2, v2 = eval m e2 in
        (A_binary (op, a1, v1, a2, v2), V.binary v1 v2 op)
    | AST_identifier (var, _) ->
        let v = VarMap.find var m in
        (A_var (var, v), v)
    | AST_int_const (c, _) ->
        let v = V.const (Z.of_string c) in
        (A_cst v, v)
    | AST_rand ((c1, _), (c2, _)) ->
        let v = V.rand (Z.of_string c1) (Z.of_string c2) in
        (A_cst v, v)

  (* backward refinement of integer expressions;
     given an annotated tree, and a target value,
     refine the environment using the variables in the expression

     it can sometimes detect that the target value is not reachable
     (e.g., unsatisfiable comparison)
     in which case it raises Empty
   *)
  let rec refine (m : env) (a : atree) (r : V.t) : env =
    match a with
    | A_unary (op, a1, v1) ->
        (* propagate downward *)
        refine m a1 (V.bwd_unary v1 op r)
    | A_binary (op, a1, v1, a2, v2) ->
        (* propagate downward *)
        let w1, w2 = V.bwd_binary v1 v2 op r in
        refine (refine m a1 w1) a2 w2
    | A_var (var, v) ->
        (* refine the variable value *)
        let w = V.meet v r in
        if V.is_bottom w then raise Empty;
        VarMap.add var w m
    | A_cst v ->
        (* test for satisfiability *)
        if V.is_bottom (V.meet v r) then raise Empty;
        m

  (* implements the comparison
     may raise Empty
   *)
  let apply_compare (m : env) (e1 : int_expr) (op : compare_op) (e2 : int_expr)
      : env =
    (* evaluate forward each argument expression *)
    let a1, v1 = eval m e1 and a2, v2 = eval m e2 in
    (* apply comparison *)
    let r1, r2 = V.compare v1 v2 op in
    (* propagate backward on both argument expressions *)
    refine (refine m a1 r1) a2 r2

  (* interface implementation *)
  (* ************************ *)

  (* initial environment *)
  let init () = Val VarMap.empty

  (* empty environment *)
  let bottom () = BOT

  (* add a (0-initialized) variable to the environment *)
  let add_var a var =
    match a with BOT -> BOT | Val m -> Val (VarMap.add var (V.const Z.zero) m)

  (* remove a variable from the environment *)
  let del_var a var =
    match a with BOT -> BOT | Val m -> Val (VarMap.remove var m)

  (* assignment *)
  let assign a var e =
    match a with
    | BOT -> BOT
    | Val m ->
        let _, v = eval m e in
        if V.is_bottom v then BOT else Val (VarMap.add var v m)

  (* compare *)
  let compare a e1 op e2 =
    match a with
    | BOT -> BOT
    | Val m -> ( try Val (apply_compare m e1 op e2) with Empty -> BOT)

  (* join *)
  let join a b =
    match (a, b) with
    | BOT, x | x, BOT -> x
    | Val m, Val n -> Val (VarMap.map2z (fun _ x y -> V.join x y) m n)

  (* meet *)
  let meet a b =
    match (a, b) with
    | BOT, x | x, BOT -> x
    | Val m, Val n -> (
        try
          Val
            (VarMap.map2z
               (fun _ x y ->
                 let r = V.meet x y in
                 if V.is_bottom r then raise Empty;
                 r)
               m n)
        with Empty -> BOT)

  (* widening, similar to join *)
  let widen a b =
    match (a, b) with
    | BOT, x | x, BOT -> x
    | Val m, Val n -> Val (VarMap.map2z (fun _ x y -> V.widen x y) m n)

  (* check inclusion *)
  let subset a b =
    match (a, b) with
    | BOT, _ -> true
    | _, BOT -> false
    | Val m, Val n -> VarMap.for_all2z (fun _ x y -> V.subset x y) m n

  (* check the emptyness *)
  let is_bottom a = a = BOT

  (* print the abstract element on some variables *)
  let print fmt a vars =
    match a with
    | BOT -> Format.fprintf fmt "bottom"
    | Val m ->
        Format.fprintf fmt "[";
        let first = ref true in
        List.iter
          (fun var ->
            let v = VarMap.find var m in
            if !first then first := false else Format.fprintf fmt ",";
            Format.fprintf fmt " %s in %a" var V.print v)
          vars;
        Format.fprintf fmt " ]"

  (* print the abstract element on all variables *)
  let print_all fmt a =
    match a with
    | BOT -> Format.fprintf fmt "bottom"
    | Val m ->
        Format.fprintf fmt "[";
        let first = ref true in
        VarMap.iter
          (fun var v ->
            if !first then first := false else Format.fprintf fmt ",";
            Format.fprintf fmt " %s in %a" var V.print v)
          m;
        Format.fprintf fmt " ]"
end
