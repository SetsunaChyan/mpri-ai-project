(*
  Cours "Typage et Analyse Statique"
  Université Pierre et Marie Curie
  Antoine Miné 2015
*)

(*
  Lexer for a very simple C-like "curly bracket" language.
*)
    
{
open Lexing
open Parser

(* keyword table *)
let kwd_table = Hashtbl.create 10
let _ = 
  List.iter (fun (a,b) -> Hashtbl.add kwd_table a b)
    [
     (* types *)
     "int",    TOK_INT;
     
     (* constants *)
     "true",   TOK_TRUE; 
     "false",  TOK_FALSE;

     (* expression operators *)
     "rand",   TOK_RAND;

     (* control flow *)
     "while",  TOK_WHILE;
     "if",     TOK_IF;
     "else",   TOK_ELSE;
     "halt",   TOK_HALT;

     (* special statements *)
     "assert", TOK_ASSERT;
     "print",  TOK_PRINT;
   ]
}

(* special character classes *)
let space = [' ' '\t' '\r']+
let newline = "\n" | "\r" | "\r\n"

(* utilities *)
let digit = ['0'-'9']
let digit_ = ['0'-'9' '_']

(* integers *)
let int_dec = digit digit_*
let int_bin = ("0b" | "0B") ['0'-'1'] ['0'-'1' '_']*
let int_oct = ("0o" | "0O") ['0'-'7'] ['0'-'7' '_']*
let int_hex = ("0x" | "0X") ['0'-'9' 'a'-'f' 'A'-'F'] ['0'-'9' 'a'-'f' 'A'-'F' '_']*
let const_int = int_bin | int_oct | int_dec | int_hex


(* tokens *)
rule token = parse

(* identifier (TOK_id) or reserved keyword *)
| ['a'-'z' 'A'-'Z' '_'] ['a'-'z' 'A'-'Z' '0'-'9' '_']* as id
{ try Hashtbl.find kwd_table id with Not_found -> TOK_id id }

(* symbols *)
| "("    { TOK_LPAREN }
| ")"    { TOK_RPAREN }
| "{"    { TOK_LCURLY }
| "}"    { TOK_RCURLY }
| "*"    { TOK_STAR }
| "+"    { TOK_PLUS }
| "-"    { TOK_MINUS }
| "!"    { TOK_EXCLAIM }
| "/"    { TOK_DIVIDE }
| "<"    { TOK_LESS }
| ">"    { TOK_GREATER }
| "<="   { TOK_LESS_EQUAL }
| ">="   { TOK_GREATER_EQUAL }
| "=="   { TOK_EQUAL_EQUAL }
| "!="   { TOK_NOT_EQUAL }
| "&&"   { TOK_AND_AND }
| "||"   { TOK_BAR_BAR }
| ";"    { TOK_SEMICOLON }
| ","    { TOK_COMMA }
| "="    { TOK_EQUAL }

(* literals *)
| const_int    as c { TOK_int c }

(* spaces, comments *)
| "/*" { comment lexbuf; token lexbuf }
| "//" [^ '\n' '\r']* { token lexbuf }
| newline { new_line lexbuf; token lexbuf }
| space { token lexbuf }

(* end of files *)
| eof { TOK_EOF }


(* nested comments (handled recursively)  *)
and comment = parse
| "*/" { () }
| [^ '\n' '\r'] { comment lexbuf }
| newline { new_line lexbuf; comment lexbuf }
