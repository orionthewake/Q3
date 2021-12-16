(* Paclet Info File *)
(* $Date: 2021-12-16 17:25:09+09 $ *)
(* $Revision: 2.1 $ *)

(* created 2021/02/11*)

Paclet[
  "Name" -> "Q3",
  "Version" -> "2.1.2",
  "WolframVersion" -> "12.1+",
  "Description" -> "Mathematica application to help study quantum information processing, quantum many-body systems, and quantum spin systems.",
  "Creator" -> "Mahn-Soo Choi (Korea University)",
  "AutoUpdating" -> True,
  "Extensions" -> {
    { "Kernel",
      "Root" -> "Kernel",
      "Context" -> { "Q3`" }
      (* Context specifies the package context or list of contexts.
         The list is also used by FindFile.
         The list also causes documentation links to be added to usage
         messages when documentation is present. *)
     },
    { "Documentation",
      "Language" -> "English",
      "MainPage" -> "Guides/Q3" }
   }
]