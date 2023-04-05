(* -*- mode:math -*- *)

(* A special package to help study the local unitary equivalence between
   quantum states. *)

Get["Q3`"]

BeginPackage["Q3`"]

`QuissoPlus`$Version = StringJoin[
  $Input, " v",
  StringSplit["$Revision: 1.13 $"][[2]], " (",
  StringSplit["$Date: 2023-04-06 07:30:59+09 $"][[2]], ") ",
  "Mahn-Soo Choi"
 ];

ClearAll @@ Evaluate @ Unprotect[
  QuissoCorrelationTensor, QuissoCorrelationMatrix,
  QuissoCoefficientTensor, QuissoAssemble,
  QuissoReduced,
  ReducedDensityMatrix, DensityMatrix, DensityOperator,
  QuissoNormalState
 ];


Begin["`Private`"]

(**** <QuissoCoefficientTensor> ****)

QuissoCoefficientTensor::usage = "QuissoCoefficientTensor[expr] gives the Pauli decomposition of the Quisso expression expr, by finding the coefficients to operators."


(* Method 1: One can use a similar method as in PauliDecompose[]. But it
   becomse very slow as the number of qubits increases.
   Note Added: PauliDecompose[] is now faster than the previous version.
   This new implementation of PauliDecompose has not been tested yet.*)

(* Method 2: This results in "Recursion depth of 1024 exceeded
   during evaluation of ..." error when the state vector includes many terms
   for a large number of qubits. *)

QuissoCoefficientTensor[op_] := With[
  { ss = Qubits @ op },
  QuissoCoefficientTensor[op, Length[ss]]
 ]

QuissoCoefficientTensor[op_, n_Integer] :=
  Join @@ Table[ QuissoCoefficientTensor[op, {k}], {k, 0, n} ]

QuissoCoefficientTensor[op_, {0}] := With[
  { cn = Elaborate[op] /. {_Symbol?QubitQ[___,(1|2|3)] -> 0} },
  Association[ {1} -> cn ]
 ]

QuissoCoefficientTensor[expr_, {n_Integer}] := Module[
  { ss = Qubits @ expr,
    op = Elaborate @ expr,
    kk, cc },
  ss = Subsets[ss, {n}];
  kk = Map[ (#[{1,2,3}])&, ss, {2} ];
  ss = Map[ (#[$])&, ss, {2} ];
  cc = Map[ CoefficientTensor[op, Sequence @@ #]&, kk ];
  Association[ Thread[ss->cc] ]
 ]

(**** </QuissoCoefficientTensor> ****)


(**** <QuissoAssemble> ****)

QuissoAssemble::usage = "QuissoAssemble[a] reassembles the operator expression in terms of operators from the coefficient tensors in the Association a. The association a is usually generated by QuissoCoefficientTensor[] or QuissoCorrelationTensor[]."

QuissoAssemble[ a_Association ] := Total @ KeyValueMap[ QuissoAssemble, a ]

QuissoAssemble[ {1}, m_ ] := m

QuissoAssemble[ ss:{__?QubitQ}, m_?TensorQ ] := Module[
  { kk, op, vv, nL },
  nL = Length[ss]; (* the level of Quisso decomposition *)
  kk = Outer[List, Sequence @@ Table[{1, 2, 3}, {nL}]];
  op = Map[ ( Multiply @@ MapThread[Construct, {ss, #}] )&, kk, {nL} ];
  vv = op * m;
  Total @ Flatten[vv]
 ]

(**** </QuissoAssemble> ****)


ReducedDensityMatrix::usage = "ReducedDensityMatrix is almost the same as QuissoReduced, but returns the matrix representations."


ReducedDensityMatrix[v_, S_?QubitQ] :=
  Matrix[ QuissoReduced[v, {S}], {S} ]

ReducedDensityMatrix[v_, S:{__?QubitQ}] :=
  Matrix[ QuissoReduced[v, S], S ]

ReducedDensityMatrix[v_] := With[
  { ss = Qubits @ v },
  ReducedDensityMatrix[ v, Length[ss]-1 ]
 ]

ReducedDensityMatrix[v_, n_Integer] :=
  Join @@ Table[ ReducedDensityMatrix[v, {k}], {k, 1, n} ]

ReducedDensityMatrix[v_, {n_Integer}] := Module[
  { ss = Qubits @ v,
    rr },
  ss = Subsets[ss, {n}];
  rr = Map[ ReducedDensityMatrix[v,#]&, ss ];
  Association[ Thread[ss->rr] ] /; n < Length[ss]
 ]

ReducedDensityMatrix[v_, {n_Integer}] := Module[
  { ss = Qubits @ v,
    rr },
  rr = Matrix[ v ** Dagger[v], ss ];
  Association[ ss -> rr ] /; n >= Length[ss]
 ]


DensityMatrix::usage = "DensityMatrix[v] constructs the density matrix (in the matrix form) for the pure state v."

DensityMatrix[v_] := Module[
  { vv = Matrix[v] },
  vv = SparseArray[ ArrayRules[vv], Dimensions[vv] ];
  Outer[Times, vv, Conjugate[vv]]
 ]

DensityOperator::usage = "DensityOperator[v] constructs the operator expression for the density matrix corresponding to the pure state v."

DensityOperator[v_] := 
  ExpressionFor[DensityMatrix @ v, Qubits @ v]


QuissoReduced::usage = "QuissoReduced[v, {S}] gives the reduced density operator (in the Ket[...]**Bra[...] form) for the qubits in {S}. For the single-qubit reduced density operator, QuissoReduced[v, S] can be used.\nQuissoReduced[v, {n}] for an integer n gives all n-qubit reduced densitry operators.\nQuissoReduced[v, n] for an integer n gives all k-qubit reduced densitry operators up to k = n.\nQuissoReduced[v] gives all n-qubit reduced densitry operators up to n = the number of qubits in v."

QuissoReduced[v_, S_?QubitQ] :=
  wReduced @ KetFactor[Garner @ v, {S}]

QuissoReduced[v_, ss:{__?QubitQ}] :=
  wReduced @ KetFactor[Garner @ v, ss]

wReduced[ OSlash[a_Ket, b_] ] :=
  Dyad[a, a, NonCommutativeSpecies @ a] * (Dagger[b] ** b)

wReduced[ expr_Plus ] := Module[
  { vv = List @@ expr,
    aa, bb, qq },
  { aa, bb } = Transpose[vv /. {OSlash -> List}];
  qq = NonCommutativeSpecies[aa];
  aa = Outer[Dyad[#1, #2, qq]&, aa, aa];
  bb = Outer[Multiply, Dagger[bb], bb];
  Total @ Flatten[Conjugate[bb] * aa]
 ]


QuissoReduced[v_] := With[
  { ss = Qubits @ v },
  QuissoReduced[ v, Length[ss]-1 ]
 ]

QuissoReduced[v_, n_Integer] :=
  Join @@ Table[ QuissoReduced[v, {k}], {k, 1, n} ]

QuissoReduced[v_, {n_Integer}] := Module[
  { ss = Qubits @ v,
    rr },
  ss = Subsets[ss, {n}];
  rr = Map[QuissoReduced[v,#]&, ss];
  Association[ Thread[ss->rr] ] /; n < Length[ss]
 ]

(* This is not really necessary, but just for completeness. *)
QuissoReduced[v_, {n_Integer}] := Module[
  { ss = Qubits @ v,
    rr },
  rr = v ** Dagger[v];
  Association[ ss -> rr ] /; n >= Length[ss]
 ]


(* QuissoNormalState *)

QuissoNormalState::usage = "QuissoNormalState[expr] or QuissoNormalState[expr, {S1, S2, ...}] gives the normal form (also known as standard form) of the given state specified by expr. See, e.g., Kraus (PRL, 2010; PRA, 2010). In Martins (PRA, 2015), it is called a reference form."

QuissoNormalState[ expr_ ] := Module[
  (* expr: Ket[] expression *)
  { ss = Qubits @ expr },
  Fold[ QuissoNormalState, expr, ss ]
 ]

QuissoNormalState[v_, S_?QubitQ] := Module[
  { p, u, m, op },
  m = Matrix @ QuissoReduced[v, {S}];
  {p, u} = Eigensystem[m];
  u = Transpose[ Normalize /@ u ];
  op = ExpressionFor[ u, {S} ];
  Simplify[ Dagger[op] ** v ]
 ]

(* QuissoCorrelationTensor *)

QuissoCorrelationTensor::usage = "QuissoCorrelationTensor[v] gives the Association of the Pauli decomposition coefficients for the density matrix corresponding to the pure state a. The pure state vector should be given in a Ket expression."

(* Method 1: This is fast, but results in "Recursion depth of 1024 exceeded
   during evaluation of ..." error when the state vector includes many terms
   for a large number of qubits. *)

(*
QuissoCorrelationTensor[v_] :=
  QuissoCoefficientTensor[ ExpressionFor @ Dyad[v, v] ]

QuissoCorrelationTensor[v_, n_Integer] :=
  QuissoCoefficientTensor[ ExpressionFor @ Dyad[v, v], n ]

QuissoCorrelationTensor[v_, {n_Integer}] :=
  QuissoCoefficientTensor[ ExpressionFor @ Dyad[v, v], {n} ]
 *)

(* Method 2: This is slower than Method 1 above, but does not suffer from the
   recursion limit error. *)

QuissoCorrelationTensor[v_] :=  With[
  { qq = Qubits @ v },
  QuissoCorrelationTensor[v, Length[qq]]
 ]

QuissoCorrelationTensor[v_, n_Integer] := 
 Join @@ Table[ QuissoCorrelationTensor[v, {k}], {k, 0, n} ]

QuissoCorrelationTensor[v_, {0}] := With[
  { qq = Qubits @ v },
  Association[{1} -> Multiply[Dagger[v], v] Power[2, -Length[qq]]]
 ]

QuissoCorrelationTensor[v_, {n_Integer}] := Module[
  { qq = Qubits @ v,
    nn, op, jj, cc },
  nn = Length @ qq;
  qq = FlavorNone @ Subsets[qq, {n}];
  jj = Map[(#[All]) &, qq, {2}];
  op = Map[Outer[Multiply, Sequence @@ #, 1] &, jj];
  cc = Dagger[v] ** op ** v;
  Association[Thread[qq -> cc]] Power[2, -nn]
 ]


(* QuissoCorrelationMatrix *)

QuissoCorrelationMatrix::usage = "QuissoCorrelationMatrix[a] analyses the correlation tesnor in the Association a; it takes the product of each tensor with itself and contract over the indices but two belonging to the same quibt. The result is an Association of 3x3 matrices describing the transformation of the state vector (associated with the Association a) under local unitary (LU) transformations. The association a is usually generated by QuissoCoefficientTensor[] or QuissoCorrelationTensor[]."

QuissoCorrelationMatrix[a_Association] := Module[
  { aa },
  aa = DeleteCases[ QuissoCorrelationMatrix /@ a, Nothing ];
  aa = Merge[ KeyValueMap[Thread[#1 -> #2]&, aa], Join ];
  (* DeleteCases[ aa, (ZeroMatrix[3] | IdentityMatrix[3]), 2 ] *)
  Return[aa];
 ]

QuissoCorrelationMatrix[T_] := Nothing /; TensorRank[T] < 2 

QuissoCorrelationMatrix[T_] := Module[
  { n = TensorRank[T],
    TT = TensorProduct[T, T],
    kk, CC },
  kk = Reverse @ Subsets[Range[n], {n - 1}];
  kk = Map[Transpose[{#, # + n}] &, kk];
  CC = TensorContract[TT, #] & /@ kk;
  Power[2,2n] CC (* make elements order of unity *)
 ]


End[]

EndPackage[]


BeginPackage["Q3`"]

Begin["`Private`"]

SetAttributes[Evaluate @ Names["`*"], ReadProtected];

End[]

SetAttributes[Evaluate @ Protect["`*"], ReadProtected];

(* Users are allowed to change variables. *)
Unprotect["`$*"];

(* Too dangerous to allow users to change these. *)
Protect[$GarnerPatterns, $ElaborationPatterns];

EndPackage[]
