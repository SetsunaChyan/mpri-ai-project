(lang dune 2.8)
(name ai_proj)
(version 0.0.0)

(using menhir 2.1)
(generate_opam_files)
(license "Unlicense")

(package
  (name ai_proj)
  (synopsis "An abstract interpretation project from MPRI M2-6 course")
  (description "\
This is an abstract interpretation project from [MPRI M2-6 Course](https://www-apr.lip6.fr/~mine/enseignement/mpri/2023-2024/)\n\
See [pdf](https://www-apr.lip6.fr/~mine/enseignement/mpri/2018-2019/project/sujet_ok.pdf) for details.")
  (depends
    (ocaml (>= 5.0))
    ocamlformat
    alcotest
    menhir
    zarith
    mlgmpidl
    apron
  )
)