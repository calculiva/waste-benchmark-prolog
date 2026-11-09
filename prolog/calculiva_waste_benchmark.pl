/*  Read-only lookup of the summary table of the Calculiva plank waste study v1.0.0
    (doi:10.7910/DVN/8VL3MW). Computes nothing; the layout engine is not included.
    Code: MIT. Data: CC BY 4.0, see calculiva_waste_benchmark_data.pl for the attribution.
*/
:- module(calculiva_waste_benchmark,
          [ waste_dataset_version/1,   % -Version
            waste_allowances/1,        % -ListOfPercent
            waste_rows/1,              % -Rows
            waste_lookup/5,            % +FormatId, +Offset, +Reuse, +KerfMm, -Row
            waste_shortfall_pct/3      % +Row, +Allowance, -Pct
          ]).
:- use_module(library(error)).
:- use_module(library(lists)).
:- use_module(calculiva_waste_benchmark_data).

%! waste_dataset_version(-Version:atom) is det.
waste_dataset_version(V) :- dataset_version(V).

%! waste_allowances(-Allowances:list(integer)) is det.
waste_allowances([5, 8, 10, 15]).

%! waste_rows(-Rows:list) is det.
%  All 42 rows, in the order of summary.csv, as
%  waste_row(FormatId, FormatOrigin, Offset, Reuse, KerfMm, ReferenceOnly, Cases,
%            waste(Min,Median,Mean,Max), [allowance(Pct,Short,Exact,Excess,ShortPct,ExcessPct), ...]).
waste_rows(Rows) :-
    findall(waste_row(F, Or, O, R, K, Ref, C, W, A),
            summary_row(F, Or, O, R, K, Ref, C, W, A), Rows).

%! waste_lookup(+FormatId:atom, +Offset:atom, +Reuse:boolean, +KerfMm:integer, -Row) is semidet.
%  Offset is '0', '1/2' or '1/3'; Reuse is true or false. Fails when the combination is absent.
waste_lookup(F, O, R, K, waste_row(F, Or, O, R, K, Ref, C, W, A)) :-
    summary_row(F, Or, O, R, K, Ref, C, W, A), !.

%! waste_shortfall_pct(+Row, +Allowance:integer, -Pct:float) is det.
%  Share of rooms (percent) where a flat 5, 8, 10 or 15 % allowance orders less than the
%  engine count. Raises a domain error for any other allowance.
waste_shortfall_pct(waste_row(_, _, _, _, _, _, _, _, A), Allowance, Pct) :-
    must_be(integer, Allowance),
    (   memberchk(Allowance, [5, 8, 10, 15])
    ->  true
    ;   domain_error(oneof([5, 8, 10, 15]), Allowance)
    ),
    memberchk(allowance(Allowance, _, _, _, Pct, _), A).
