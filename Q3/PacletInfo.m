(* Paclet Info File *)

(* created 2021/02/11*)

Paclet[
  Name -> "Q3",
  Version -> "1.9.3",
  WolframVersion -> "12+",
  Description -> "Mathematica application to help study quantum information processing, quantum many-body systems, and quantum spin systems.",
  Creator -> "Mahn-Soo Choi (Korea University)",
  Updating -> Automatic,
  Extensions -> {
    { "Kernel",
      Root -> "Kernel",
      Context -> {
        "Q3`", "Q3`FockPlus`", "Q3`GellMann`"
       }
      (* Context specifies the package context or list of contexts . Used by
         FindFile. Also causes documentation links to be added to usage
         messages when documentation is present. *)
     },
    { "Documentation",
      Language -> "English",
      MainPage -> "Guides/Q3" }
   },
  URL -> "https://github.com/quantum-mob/Q3App",
  Category -> "Physics",
  Keywords -> {
    "Quantum Computation",
    "Quantum Many-Body Systems",
    "Quantum Spins"
   }
]

