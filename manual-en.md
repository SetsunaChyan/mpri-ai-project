## Project: Static analysis via abstract interpretation for a simple numerical language

Antoine Miné

September 11, 2018

> Translated from https://www-apr.lip6.fr/~mine/enseignement/mpri/2018-2019/project/sujet_ok.pdf
>
> The project can now be built with `dune`, with some modifications, mainly related to the project structure
>
> It is assumed that the reader has installed `opam` and the OCaml compiler, the project has only been tested on OCaml 5.2.1, other versions are unknown
>
> Setsuna 2025.2.10

### 1 Introduction

The goal of this project is to get familiar with the design and programming of static analyzers based on abstract interpretation in the OCaml language. To do this, we will extend a small analyzer that allows numerical analysis of a very simple imperative toy language. The syntax is inspired by C, but greatly simplified. The language contains only integers (in $\mathbb{Z}$) as data types, and `if then else` and `while` loops as control structures. The language does not contain pointers, functions, arrays, dynamic allocation, or objects.

This project assumes that you have prior knowledge of abstract interpretation and OCaml programming. For the abstract interpretation part, you can refer to the following two courses:

+ M2-6 course of MPRI Paris 7 (in English);

+ TAS course of Master STL of Sorbonne University (in French).

This project is inspired by a project given in École normale supérieure and Master STL of Sorbonne University.

#### 1.1 Basic Code

You will find in the project archives a basic framework to facilitate the development of the analysis:

+ A parser that converts the text of the program into an abstract syntax tree;

+ An interpreter based on grammar induction, parameterized by the choice of the interpretation domain;

+ Signatures of the environment domain and the value domain;

+ Concrete domains that allow collecting the precise set of states accessible to the program;

+ Constants abstract domain.

The interpreter and constants domain are not yet complete. Therefore, the first task is to complete them.

#### 1.2 Dependencies

The following dependencies must be installed to compile the project:

+ OCaml language;

+ Menhir: OCaml parser generator;

+ GMP: A C library for multiple precision integers (needed by Zarith and Apron);

+ MPFR: A C library for multiple precision floating point numbers (needed by Apron);

+ Zarith: An OCaml multiple precision integer library;

+ CamlIDL: An OCaml C interface library;

+ Apron: A C/OCaml numeric domain library.

In Ubuntu (and derivatives), you can use `apt-get` and `opam` to install dependencies:

```shell
# Assuming you have installed opam and at least one valid switch
sudo apt-get update
sudo apt-get install -y m4 libgmp3-dev libmpfr-dev
opam install -y menhir zarith mlgmpidl apron
```

#### 1.3 Compile and test

After installing the dependencies, execute `dune bulid` to compile. The generated executable file is `_build/install/default/bin/analyzer`. If the compilation succeeds, you can test the binary in the project root directory:

+ `dune exec analyzer --root=. -- tests/0011_rand.c` should display the text of the program `tests/01_concrete/0111_rand.c` on the console (actually, the program has been converted to AST and back to text by the parser);

+ `dune exec analyzer --root=. -- tests/0011_rand.c -concrete` should display the results of all possible executions of the test program on the console, here the values of `x` between $1$ and $5$.

### 2 Project Architecture

The source code directory structure is as follows:

+ `Makefile`: compile file for the analyzer, modified as you add source files;

+ `src/main.ml`: entry point, parses command line options, starts syntax and semantic analysis; used to connect new analysis and add options;

+ `libs/`: library files
  + `libs/mapext`: contains a slightly improved version of the OCaml `Map` module;

  + `libs/frontend/`: convert source (text) to abstract syntax tree:
    + `libs/frontend/abstract_syntax_tree.ml`: type of syntax tree;

    + `libs/frontend/lexer.mll`: `OCamlLex` lexer;

    + `libs/frontend/parser.mly`: `Menhir` syntax analyzer;

    + `libs/frontend/file_parser.ml`: entry point for converting source to syntax tree;

    + `libs/frontend/abstract_syntax_printer.ml`: reverse transformation, displaying the syntax tree in source form;

  + `libs/domains/`: semantic interpretation domain;
    + `libs/domains/domain.ml`: signature of a domain representing a collection of environments;

    + `libs/domains/concrete_domain.ml`: concrete domain, environments are represented as a collection of tables, associating each variable with its value;

    + `libs/domains/value_domain.ml`: signature of a domain representing a collection of integers;

    + `libs/domains/constant_domain.ml`: an example of a domain for a collection of integers (thus conforming to the `Value_domain.VALUE_DOMAIN` signature): the constant domain;

    + `libs/domains/non_relational_domain.ml`: a functor that, given a domain representing a collection of integers (`Value_domain.VALUE_DOMAIN`), constructs a domain representing a collection of environments (`Domain.DOMAIN`), by associating each variable with a set of abstract integers;

  + `libs/interpreter/interpreter.ml`: a generic interpreter for programs, parameterized by the environment domain (`Domain.DOMAIN`);

+ `tests/`: a set of programs written in the parsing language, used to test your parser.

+ `tests/tests-constant/, tests/result-interval/`: parsing results, obtained using a reference parser (not provided!), which can be used as a reference point for comparison with your parser.

### 3 Language Syntax

The toy language follows the syntax described in the grammar file `parser.mly`. We describe it briefly, knowing that the examples in the `tests/` directory also allow you to get familiar with the syntax. In addition, the file `abstract_syntax_tree.ml` gives a precise idea of the language constructs.

A program is a sequence of instructions:

+ tests: `if (bexpr) { block } or if (bexpr) { block } else { block }`;

+ loops: `while (bexpr) { block }`;

+ assignments: `var = expr`;

+ blocks: `{ decl1; ...; decln; inst1; ...; instn }` consisting of a sequence of variable declarations `int var` and a sequence of instructions; only `int` type is recognized; declarations are not initialized (must be followed by assignments); only one variable can be declared at a time (`int a,b;` does not work, must write `int a; int b;`); all declarations must precede all instructions in a block; no global variables, all variables must be declared in a block;

+ integer expressions, used for assignments, consisting of classic operators `+, -, *, /`, variables, constants, and a special operation `rand(l,h)`, where `l` and `h` are two integers, representing The set of integers between `l` and `h`;

+ Boolean expressions, used for testing and looping, consisting of operators `&&, ||, !`, constants `true` and `false`, and comparison of two integer expressions with the help of operators `<, <=, >, >=, ==, !=`;

+ `print(var1,...,varn)` allows to display the values of variables `var1` to `varn`;

+ `halt` stops the program;

+ `assert(bexpr)` stops the program with an error message if the Boolean condition is not verified, otherwise continues execution normally.

A simple valid program example is:

```c
{
int x;
x = 2+2;
print(x);
}
```

For more information on the syntax, you can consult the parser file `libs/frontend/parser.mly`. You can also find program examples in the `tests` directory.

### 4 What needs to be done

#### 4.1 Hands-on, concrete domain

Option `-concrete` allows executing the program in concrete collection semantics.

You can also use option `-trace` to observe the execution of the computation (displaying the environment after each instruction).

##### 4.1.1 Observation

Start concrete profiling on the provided example and create your test case. The goal is to answer the following questions about the program semantics and how it relates to the concrete interpreter behavior, and verify your answers with tests:

+ What is the semantics of the instruction `rand(l,h)` in the program? What is the expected result of the interpreter?

+ Under what conditions does the execution of the program stop? What is the result of the interpreter?

+ If the program contains an infinite loop, can the interpreter still terminate? In what cases?

##### 4.1.2 Assertions

You may have noticed in your tests that the `assert` instruction behaves like the `skip` instruction: it does nothing. In this problem, you will modify `interpreter.ml` to correct its interpretation, that is:

+ Display an error message if an assertion is not proven to be true;

+ And continue parsing under the assumption that it is true (this is done to not indicate multiple errors with the same cause to the user).

##### 4.1.3 Enrichment

Implement the following extensions:

+ Add a modulo operation `%` to the language (requires slight modifications to lexical analysis, syntax analysis, syntax trees, and interpretation domains; hint: start with existing operations such as multiplication to follow the modifications to be made);

+ The `int` type of programs corresponds to perfect mathematical integers; modify this interpretation in `concrete_domain.ml` to correspond to 32-bit signed integers, and illustrate the difference in behavior with program examples (hint: 32-bit operations can be viewed as operations on mathematical integers, followed by correction operations that bring the result back to $[-2^{31}, 2^{31} - 1]$; so just add this step after each calculation).

#### 4.2 Constant Domain

Constant analysis can be accessed with option `-constant`. However, the domain is incomplete. The goal of this exercise is to complete it. You will pay particular attention to the results of the following tests:

+ `0024_mul_rand.c`

+ `0100_if_true.c`

+ `0101_if_false.c`

+ `0209_cmp_eq_ne.c`

In each case, identify the source of imprecision in `constant_domain.ml` and correct it.

In addition, the treatment of division is not as exact as it could be. Identify and correct this imprecision. Propose a test that highlights your correction.

#### 4.3 Interval Domain

In this exercise, you will implement an interval domain. Like the constant domain, it conforms to the signature `Value_domain.VALUE_DOMAIN` and is used as an argument to the functor `Non_relational_domain.NonRelational`. Note that we manage arbitrary mathematical integers. Therefore, the bounds of the intervals are not necessarily integers, but can also be $+∞$ or $-∞$.

The signature `Value_domain.VALUE_DOMAIN` contains many functions. You will implement at least the following functions in the most precise way: `top, bottom, const, rand, meet, join, subset, is_bottom, print, unary, binary, compare`. For the function `bwd_unary` and `bwd_binary`, approximate implementations are sufficient. However, it is crucial that all functions return safe results even if the results are inexact.

#### 4.4 Loop Analysis

The treatment of loops in `interpreter.ml` assumes that the abstract domain does not have strictly increasing infinite chains. So what happens during interval analysis?

The goal of this question is to correct this by adding the use of widening. We will do this step by step:

Ensure that the widening operation is correctly implemented in the interval domain;

Modify `interpreter.ml` so that the widening operation is used in each loop;

Add an option `-delay n` that allows replacing the first `n` applications of the widening operation with union (delayed widening);

Add an option `-unroll n` that allows unrolling the first `n` loops before computing with widening; what is the difference with `-delay n`? (Explain with examples);

Add decrementing iterations to refine the result (also explain the accuracy gain with examples).

#### 4.5 Reduced Products

Implement a parity domain that allows reasoning about whether each variable is even or odd.

Then implement a reduced product of intervals and parity. Come up with program examples that show the significance of this reduction. Try, if possible, to define a general "reduced product" functor that takes an abstract domain of arbitrary values as an argument.

### 5 Extensions

This section describes several improvements you can make to the analyzer.

#### 5.1 Machine Integer Analysis

As a supplement to Problem 4.1.3, modify all implemented domains (constants, intervals, parity) so that the semantics correspond to computations in 32-bit signed integers rather than in mathematical integers. Show in examples the differences between these two semantics, especially the impact on the accuracy of the analysis.

#### 5.2 Disjunctive Analysis

Interval analysis is imprecise because it represents only convex valued sets. Several constructions allow correcting this by reasoning about disjunctions of intervals: disjunctive completion, state partitioning, trajectory partitioning. Implement one of these techniques in your analyzer and provide examples to illustrate the precision improvement it brings.

#### 5.3 Relational Analysis

Add support for relational numeric domains. You can rely on the Apron library, which provides all the finished implementations of octagons and polyhedra, with an OCaml interface. Provide examples to illustrate the precision improvement.

#### 5.4 Array Analysis

Add support for arrays in your language and analysis. Each array will be declared with a fixed size, e.g., `int tab[10]`. During access in the array `tab[expr]`, we are interested in:

Verify that the expression `expr` represents a valid index into the array, i.e., evaluates to a value between `0` and `n - 1` (otherwise, an error will be displayed, similar to an assertion failure);

Infer information about the values contained in the array (e.g., the range of the values).

For the second point, two abstract representations of arrays can be used:

+ Treat each cell `tab[0], ..., tab[n-1]` as an independent variable and associate a range with it;

+ Or use a single variable `tab[*]` and a unique range for each array, which represents the set of all possible values of all cells of the array.

You will implement both techniques and provide examples to illustrate the difference in precision and cost.

#### 5.5 Pointer Analysis

Add support for pointers in your language and analysis.

Pointer variables will be declared using `ptr p`. If `x` is an integer variable, then a reference to `x` can be stored in `p` with the instruction `p = &x`. The variable referenced by `p` can be read with `*p` and can be used in any expression (for example, we can write `x = *p + 1`). The variable referenced by `p` can be modified with `*p = expression`. Finally, if `q` is also a reference, it can be copied into `p` via `p = q` (thus, `*p` and `*q` refer to the same variable).

It is an error to read or modify the value referenced by an uninitialized pointer (between `ptr p` and the first assignment `p = ...`). Furthermore, if `p` refers to a variable `x` declared in a block, it is also an error to refer to this pointer after the block exits. The analyzer should detect these errors and display them.

Pointer support can be added to the analyzer via a pointer field that associates each pointer variable with a set of possible reference variables. You will implement this technique and provide examples to illustrate it.

#### 5.6 String Analysis

Add support for strings to your language and analysis.

String variables will be declared via `string s`. We assume that strings are immutable (as in Java, unlike C). To extend our expressions to strings, we add the following syntax:

+ String literal constants, enclosed in quotes, for example: `"toto"`;

+ The concatenation operator `.` (dot): `s = "un " . "mot"`;

+ Extract the length of a string: `i = length(s)`.

String support can be added to the parser via one of the following domains (in order of increasing complexity):

+ A domain that keeps the set of letters that may appear in a string, without remembering their number of occurrences or their positions;

+ A domain that associates to each string its size, and this information can then be abstracted in a numeric domain such as intervals or even a relational numeric domain (to discover relations between string sizes and numeric variables);

+ A domain that approximates the set of all possible strings via a finite automaton;

+ The reduced product of two (or more) domains.