(*
  Cours "Typage et Analyse Statique"
  Université Pierre et Marie Curie
  Antoine Miné 2015
*)

(* 
   Concrete execution domain
 *)

open Frontend.Abstract_syntax_tree
open Domain

module Concrete : DOMAIN = struct
  (* types *)
  (* ***** *)

  (* a map, with variables (strings) as keys *)
  module Env = Mapext.Make (String)

  (* an environment maps each variable to an integer value *)
  type env = Z.t Env.t

  (* a set of environments *)
  module EnvSet = Set.Make (struct
    type t = env

    let compare = Env.compare Z.compare
  end)

  (* an element is a set of possible environments *)
  type t = EnvSet.t

  (* a set of integer values (not exported, useful internally) *)
  module ValSet = Set.Make (struct
    type t = Z.t

    let compare = Z.compare
  end)

  (* expression evaluation *)
  (* ********************* *)

  (* applies f to each element of a set of integers *)
  let int_map (f : Z.t -> Z.t) (s : ValSet.t) : ValSet.t =
    ValSet.fold (fun x acc -> ValSet.add (f x) acc) s ValSet.empty

  (* construct a set by applying f to each pair of integers in the sets *)
  let int2_map (f : Z.t -> Z.t -> Z.t) (s1 : ValSet.t) (s2 : ValSet.t) :
      ValSet.t =
    ValSet.fold
      (fun x1 acc ->
        ValSet.fold (fun x2 acc -> ValSet.add (f x1 x2) acc) s2 acc)
      s1 ValSet.empty

  (* evaluates an integer expression in a given environment;
     returns a set of integer values
     sets are required because expressions are non-determinisic!
   *)
  let rec eval_expr (e : int_expr) (m : env) : ValSet.t =
    match e with
    | AST_int_unary (op, (e1, _)) ->
        (* evaluate the sub-expression *)
        let s1 = eval_expr e1 m in
        (* then, apply the operation to each integer *)
        int_map
          (match op with
          | AST_UNARY_PLUS -> fun x -> x
          | AST_UNARY_MINUS -> Z.neg)
          s1
    | AST_int_binary (op, (e1, _), (e2, _)) ->
        (* evaluate the sub-expressions *)
        let s1 = eval_expr e1 m and s2 = eval_expr e2 m in
        (* update s2 to avoid a division by zero! *)
        let s2 = if op = AST_DIVIDE then ValSet.remove Z.zero s2 else s2 in
        (* then, apply the operation to each pair of elements *)
        int2_map
          (match op with
          | AST_PLUS -> Z.add
          | AST_MINUS -> Z.sub
          | AST_MULTIPLY -> Z.mul
          | AST_DIVIDE -> Z.div)
          s1 s2
    | AST_identifier (v, _) ->
        (* value of the variable in the environment: a singleton *)
        ValSet.singleton (Env.find v m)
    | AST_int_const (s, _) ->
        (* constant: a singleton *)
        ValSet.singleton (Z.of_string s)
    | AST_rand ((l1, _), (l2, _)) ->
        (* converst the bounds to integer *)
        let l1 = Z.of_string l1 and l2 = Z.of_string l2 in
        (* construct the set [l1;l2] *)
        let rec acc cur set =
          if cur > l2 then set else acc (Z.succ cur) (ValSet.add cur set)
        in
        acc l1 ValSet.empty

  (* whether the comparison can ealuate to true *)
  let eval_compare (e1 : int_expr) (op : compare_op) (e2 : int_expr) (m : env) :
      bool =
    (* operation to apply to compare two integers *)
    let f =
      match op with
      | AST_EQUAL -> Z.equal
      | AST_NOT_EQUAL -> fun x y -> not (Z.equal x y)
      | AST_LESS -> Z.lt
      | AST_LESS_EQUAL -> Z.leq
      | AST_GREATER -> Z.gt
      | AST_GREATER_EQUAL -> Z.geq
    in
    (* evaluate the sub-expressions *)
    let s1 = eval_expr e1 m and s2 = eval_expr e2 m in
    (* test each pair of values for a match *)
    ValSet.fold
      (fun v1 acc -> ValSet.fold (fun v2 acc -> acc || f v1 v2) s2 acc)
      s1 false

  (* interface implementation *)
  (* ************************ *)

  (* initial environment, without any variable *)
  let init () = EnvSet.singleton Env.empty

  (* empty set *)
  let bottom () = EnvSet.empty

  (* utility: applies f to a Set *)
  let env_set_map f m =
    EnvSet.fold (fun x acc -> EnvSet.add (f x) acc) m EnvSet.empty

  (* add a variable *)
  let add_var m v = env_set_map (Env.add v Z.zero) m

  (* remove a variable *)
  let del_var m v = env_set_map (Env.remove v) m

  (* assign an integer expression to a variable *)
  let assign m var e =
    (* for each environment *)
    EnvSet.fold
      (fun env acc ->
        (* for each possible value in the environment *)
        let s = eval_expr e env in
        ValSet.fold
          (fun v acc ->
            (* create a new, updated environment *)
            EnvSet.add (Env.add var v env) acc)
          s acc)
      m EnvSet.empty

  (* filter environments to keep only those satisfying the comparison *)
  let compare m e1 op e2 =
    EnvSet.filter (fun env -> eval_compare e1 op e2 env) m

  (* abstract join *)
  let join m1 m2 = EnvSet.union m1 m2
  let widen = join

  (* abstract intersection *)
  let meet m1 m2 = EnvSet.inter m1 m2

  (* whether an abstract element is included in another one *)
  let subset m1 m2 = EnvSet.subset m1 m2

  (* whether the abstract element represents the empty set *)
  let is_bottom m = EnvSet.is_empty m

  (* print a set of variables *)
  let print fmt m vars =
    Format.fprintf fmt "{ ";
    EnvSet.iter
      (fun env ->
        Format.fprintf fmt "[";
        List.iter
          (fun var ->
            let v = Env.find var env in
            Format.fprintf fmt "%s=%s;" var (Z.to_string v))
          vars;
        Format.fprintf fmt "]; ")
      m;
    Format.fprintf fmt "}"

  (* print all variable *)
  let print_all fmt m =
    Format.fprintf fmt "{ ";
    EnvSet.iter
      (fun env ->
        Format.fprintf fmt "[";
        Env.iter
          (fun var v -> Format.fprintf fmt "%s=%s;" var (Z.to_string v))
          env;
        Format.fprintf fmt "]; ")
      m;
    Format.fprintf fmt "}"
end
