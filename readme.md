This is an abstract interpretation project from [MPRI M2-6 Course](https://www-apr.lip6.fr/~mine/enseignement/mpri/2023-2024/).

See [pdf](https://www-apr.lip6.fr/~mine/enseignement/mpri/2018-2019/project/sujet_ok.pdf) for details.

There is a Chinese machine translated version in [manual-zh.md](./manual-zh.md) for reference, slightly different from the pdf version above.

There is also an English translation in [manual-en.md](./manual-en.md) from the Chinese version.

The project structure has been slightly adjusted and can now be built through `dune`, compiled with the command `dune build`, and run with the command `dune exec analyzer --root=. -- tests/0011_rand.c -concrete`.

Tested in the following environment: `dune = 3.17.2`, `ocaml = 5.2.1`, no guarantee of working properly in other versions, but contributions are welcome.