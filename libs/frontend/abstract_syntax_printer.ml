(*
  Cours "Typage et Analyse Statique"
  Université Pierre et Marie Curie
  Antoine Miné 2015
*)

(* 
  Pretty-printer for abstract syntax trees.
*)

open Abstract_syntax_tree
open Lexing

(* locations *)
(* ********* *)

let string_of_position p =
  Printf.sprintf "%s:%i:%i" p.pos_fname p.pos_lnum (p.pos_cnum - p.pos_bol)

let string_of_extent (p, q) =
  if p.pos_fname = q.pos_fname then
    if p.pos_lnum = q.pos_lnum then
      if p.pos_cnum = q.pos_cnum then
        Printf.sprintf "%s:%i.%i" p.pos_fname p.pos_lnum (p.pos_cnum - p.pos_bol)
      else
        Printf.sprintf "%s:%i.%i-%i" p.pos_fname p.pos_lnum
          (p.pos_cnum - p.pos_bol) (q.pos_cnum - q.pos_bol)
    else
      Printf.sprintf "%s:%i.%i-%i.%i" p.pos_fname p.pos_lnum
        (p.pos_cnum - p.pos_bol) q.pos_lnum (q.pos_cnum - q.pos_bol)
  else
    Printf.sprintf "%s:%i.%i-%s:%i.%i" p.pos_fname p.pos_lnum
      (p.pos_cnum - p.pos_bol) q.pos_fname q.pos_lnum (q.pos_cnum - q.pos_bol)

(* operators *)
(* ********* *)

let string_of_int_unary_op = function
  | AST_UNARY_PLUS -> "+"
  | AST_UNARY_MINUS -> "-"

let string_of_bool_unary_op = function AST_NOT -> "!"

let string_of_int_binary_op = function
  | AST_MULTIPLY -> "*"
  | AST_DIVIDE -> "/"
  | AST_PLUS -> "+"
  | AST_MINUS -> "-"

let string_of_compare_op = function
  | AST_EQUAL -> "=="
  | AST_NOT_EQUAL -> "!="
  | AST_LESS -> "<"
  | AST_LESS_EQUAL -> "<="
  | AST_GREATER -> ">"
  | AST_GREATER_EQUAL -> ">="

let string_of_bool_binary_op = function AST_AND -> "&&" | AST_OR -> "||"

(* precedence of the operator at the root of the expression;
   this is used to avoid printing unnecessary parentheses
 *)

let int_expr_precedence = function
  | AST_int_unary (_, _) -> 99
  | AST_int_binary ((AST_MULTIPLY | AST_DIVIDE), _, _) -> 6
  | AST_int_binary ((AST_PLUS | AST_MINUS), _, _) -> 5
  | _ -> 100

let bool_expr_precedence = function
  | AST_compare (_, _, _) -> 3
  | AST_bool_binary (AST_AND, _, _) -> 2
  | AST_bool_binary (AST_OR, _, _) -> 1
  | _ -> 100

(* utility to print lists *)
let print_list f sep fmt l =
  let rec aux = function
    | [] -> ()
    | [ a ] -> f fmt a
    | a :: b ->
        f fmt a;
        Format.pp_print_string fmt sep;
        aux b
  in
  aux l

(* types *)
(* ***** *)

let print_typ fmt t = match t with AST_INT -> Format.pp_print_string fmt "int"

(* expressions *)
(* *********** *)

let print_var fmt v = Format.pp_print_string fmt v

let rec print_int_expr fmt e =
  match e with
  | AST_int_unary (op, (e1, _)) ->
      Format.pp_print_string fmt (string_of_int_unary_op op);
      if int_expr_precedence e1 <= int_expr_precedence e then
        Format.fprintf fmt " (%a)" print_int_expr e1
      else Format.fprintf fmt " %a" print_int_expr e1
  | AST_int_binary (op, (e1, _), (e2, _)) ->
      if int_expr_precedence e1 < int_expr_precedence e then
        Format.fprintf fmt "(%a) " print_int_expr e1
      else Format.fprintf fmt "%a " print_int_expr e1;
      Format.pp_print_string fmt (string_of_int_binary_op op);
      if int_expr_precedence e2 <= int_expr_precedence e then
        Format.fprintf fmt " (%a)" print_int_expr e2
      else Format.fprintf fmt " %a" print_int_expr e2
  | AST_int_const (i, _) -> Format.pp_print_string fmt i
  | AST_rand ((i1, _), (i2, _)) -> Format.fprintf fmt "rand(%s,%s)" i1 i2
  | AST_identifier (v, _) -> print_var fmt v

and print_bool_expr fmt e =
  match e with
  | AST_bool_unary (op, (e1, _)) ->
      Format.pp_print_string fmt (string_of_bool_unary_op op);
      if bool_expr_precedence e1 <= bool_expr_precedence e then
        Format.fprintf fmt " (%a)" print_bool_expr e1
      else Format.fprintf fmt " %a" print_bool_expr e1
  | AST_bool_binary (op, (e1, _), (e2, _)) ->
      if bool_expr_precedence e1 < bool_expr_precedence e then
        Format.fprintf fmt "(%a) " print_bool_expr e1
      else Format.fprintf fmt "%a " print_bool_expr e1;
      Format.pp_print_string fmt (string_of_bool_binary_op op);
      if bool_expr_precedence e2 <= bool_expr_precedence e then
        Format.fprintf fmt " (%a)" print_bool_expr e2
      else Format.fprintf fmt " %a" print_bool_expr e2
  | AST_compare (op, (e1, _), (e2, _)) ->
      if int_expr_precedence e1 < bool_expr_precedence e then
        Format.fprintf fmt "(%a) " print_int_expr e1
      else Format.fprintf fmt "%a " print_int_expr e1;
      Format.pp_print_string fmt (string_of_compare_op op);
      if int_expr_precedence e2 <= bool_expr_precedence e then
        Format.fprintf fmt " (%a)" print_int_expr e2
      else Format.fprintf fmt " %a" print_int_expr e2
  | AST_bool_const i -> Format.fprintf fmt "%B" i

(* statements *)
(* ********** *)

let indent ind = ind ^ "  "

(* ind is a string of spaces (indentation) to put at the begining of each line
 *)
let rec print_stat ind fmt = function
  | AST_block (d, b) -> print_block ind fmt d b
  | AST_assign ((v, _), (e, _)) ->
      Format.fprintf fmt "%s%a = %a;@\n" ind print_var v print_int_expr e
  | AST_if ((e, _), (b1, _), None) ->
      Format.fprintf fmt "%sif (%a)@\n%a" ind print_bool_expr e
        (print_stat (indent ind))
        b1
  | AST_if ((e, _), (b1, _), Some (b2, _)) ->
      Format.fprintf fmt "%sif (%a)@\n%a%selse@\n%a" ind print_bool_expr e
        (print_stat (indent ind))
        b1 ind
        (print_stat (indent ind))
        b2
  | AST_while ((e, _), (b, _)) ->
      Format.fprintf fmt "%swhile (%a)@\n%a" ind print_bool_expr e
        (print_stat (indent ind))
        b
  | AST_assert (e, _) ->
      Format.fprintf fmt "%sassert (%a);@\n" ind print_bool_expr e
  | AST_print l ->
      Format.fprintf fmt "%sprint (%a);@\n" ind (print_list print_var ",")
        (List.map fst l)
  | AST_HALT -> Format.fprintf fmt "%shalt;@\n" ind

and print_block ind fmt decl inst =
  Format.fprintf fmt "%s{@\n" ind;
  List.iter
    (fun ((t, v), _) ->
      Format.fprintf fmt "%s%a %a;@\n" (indent ind) print_typ t print_var v)
    decl;
  List.iter (fun (bb, _) -> print_stat (indent ind) fmt bb) inst;
  Format.fprintf fmt "%s}@\n" ind

(* programs *)
(* ******** *)

let print_prog fmt p = List.iter (fun (s, _) -> print_stat "" fmt s) p
