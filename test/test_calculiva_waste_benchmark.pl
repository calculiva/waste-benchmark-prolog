/*  vectors.json is generated from summary.csv by tools/ports/gen_waste_benchmark.py
    (calculiva repository). The tests compare the whole Prolog table to it; no value is
    typed by hand. Run from the pack root:
        swipl -g run_tests -t halt test/test_calculiva_waste_benchmark.pl
*/
:- use_module(library(plunit)).
:- use_module(library(http/json)).
:- use_module(library(apply)).
:- use_module(library(lists)).

:- prolog_load_context(directory, Dir),
   atomic_list_concat([Dir, '/../prolog'], Lib),
   asserta(user:file_search_path(library, Lib)),
   atomic_list_concat([Dir, '/vectors.json'], V),
   asserta(user:vectors_file(V)).
:- use_module(library(calculiva_waste_benchmark)).

vectors(D) :-
    user:vectors_file(F),
    setup_call_cleanup(open(F, read, S, [encoding(utf8)]), json_read_dict(S, D), close(S)).

close_to(A, B) :- abs(A - B) < 1.0e-9.

key(J, F, O, R, K) :-
    atom_string(F, J.format_id), atom_string(O, J.offset),
    atom_string(R, J.reuse), K = J.kerf_mm.

check_row(Row, J) :-
    key(J, F, O, R, K),
    waste_lookup(F, O, R, K, Found),
    Found == Row,
    Row = waste_row(F, Or, O, R, K, Ref, C, waste(Mi, Md, Mn, Mx), Outs),
    atom_string(Or, J.format_origin),
    atom_string(Ref, J.reference_only),
    C =:= J.cases,
    J.waste_pct = [JMi, JMd, JMn, JMx],
    close_to(Mi, JMi), close_to(Md, JMd), close_to(Mn, JMn), close_to(Mx, JMx),
    maplist(check_allowance(Row), Outs, J.allowances).

check_allowance(Row, allowance(P, S, E, X, _, XP), JA) :-
    P =:= JA.allowance, S =:= JA.short, E =:= JA.exact, X =:= JA.excess,
    close_to(XP, JA.excess_pct),
    waste_shortfall_pct(Row, P, SP),
    close_to(SP, JA.short_pct).

:- begin_tests(calculiva_waste_benchmark).

test(version) :-
    vectors(V), waste_dataset_version(Ver), atom_string(Ver, V.dataset_version).

test(allowances) :-
    vectors(V), waste_allowances(A), A == V.allowances.

test(every_row) :-
    vectors(V), waste_rows(Rows),
    length(Rows, N), N =:= V.count,
    maplist(check_row, Rows, V.rows).

test(missing_keys) :-
    vectors(V),
    forall(member(M, V.missing_keys),
           ( key(M, F, O, R, K), \+ waste_lookup(F, O, R, K, _) )).

test(invalid_allowances) :-
    vectors(V), waste_rows([Row|_]),
    forall(member(B, V.invalid_allowances),
           catch(( waste_shortfall_pct(Row, B, _), fail ), error(domain_error(_, B), _), true)).

:- end_tests(calculiva_waste_benchmark).
