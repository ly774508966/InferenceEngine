%%%%%%%%% DATA 
%% chair
%%%% chair legs
%seg(point(127,517), point(128,757)).
%seg(point(347,510), point(345,749)).
%seg(point(264,516), point(266,657)).
%seg(point(482,422), point(478,654)).
%
%%%% back
%seg(point(129,514), point(128,252)).
%seg(point(129,252), point(266,166)).
%seg(point(262,415), point(262,167)).
%seg(point(258,429), point(125,520)).
%
%%%% sitting part
%seg(point(258,429), point(125,520)).
%seg(point(128,514), point(350,513)).
%seg(point(350,513), point(484,417)).
%seg(point(482,417), point(258,417)).

% chair
%%% chair legs
seg(point(127,517,100), point(128,757,100)).
seg(point(347,510,100), point(345,749,100)).
seg(point(264,516,300), point(266,657,300)).
seg(point(482,422,300), point(478,654,300)).
                                    
%%% back                            
seg(point(129,514,100), point(128,252,100)).
seg(point(129,252,100), point(266,166,300)).
seg(point(262,415,300), point(262,167,300)).
seg(point(258,429,300), point(125,520,100)).

%%% sitting part                    
seg(point(258,429,300), point(125,520,100)).
seg(point(128,514,100), point(350,513,100)).
seg(point(350,513,100), point(484,417,300)).
seg(point(482,417,300), point(258,417,300)).


%%%%%%%% MODEL

% object( name, [attr] ).
% pos(min(X,point(X,_)), min(Y,point(_,Y))). - begin of local coordinate system
% ats() - structure attributes, composition from solids (in local coordinate system ??)

% atf() - feature attributes
% trans(X,Y,Z).
% rot(angleX,angleY,angleZ).
% scale(X,Y,Z).
% colour(R,G,B).
% texture(e.g. soft, solid)

object(sensor, [ pos(0,0,0) ]).

object( back,[ pos( trans(129,252,100), rot(75,0,0), scale(1,1,1)),
               ats(),
               atf( colour(255,255,255), texture(solid) ) ] ).
object( sit,[ pos( trans(129,252,100), rot(0,75,0), scale(1,1,1)),
               ats(),
               atf( colour(255,255,255), texture(solid) ) ] ).
object( leg,[ pos( trans(127,517,100), rot(0,0,0), scale(1,1,1)),
               ats(),
               atf( colour(255,255,255), texture(solid) ) ] ).
object( leg,[ pos( trans(347,510,100), rot(0,0,0), scale(1,1,1)),
               ats(),
               atf( colour(255,255,255), texture(solid) ) ] ).
object( leg,[ pos( trans(264,516,100), rot(0,0,0), scale(1,1,1)),
               ats(),
               atf( colour(255,255,255), texture(solid) ) ] ).
object( leg,[ pos( trans(482,422,100), rot(0,0,0), scale(1,1,1)),
               ats(),
               atf( colour(255,255,255), texture(solid) ) ] ).


part_of(leg, chair).
part_of(back, chair).
part_of(sit, chair).

% concept ??
concept( leg,[ pos( trans(482,422,100), rot(0,0,0), scale(1,1,1)),
               ats(modality_set(), modality_set(),...),
               atf( colour(255,255,255), texture(solid), score() ) ] ).

concept(cube, ConstraintGraph).

concept(cube, graph( [0,1,2,...,11], [arc(1,5,A), arc(1,7,A),...] ) ). 

concept(name, attributes, constraints).

object( leg,[ pos( trans(482,422,100), rot(0,0,0), scale(1,1,1)),
               ats(),
               atf( colour(255,255,255), texture(solid) ) ] ).

% should be described in local coordinates
% e.g. each segment in the arc is nnone of the segments in data
object( leg,[ pos( trans(482,422,100), rot(0,0,0), scale(1,1,1)),
               ats(),
               atf( colour(255,255,255), texture(solid) ) ],
	    [  graph( [0,1,2,...,11], [arc(1,5,connected), arc(seg(point(....),point(....)),seg(...),connected), arc(...] ) ).
%model segments

% partial instance
%  RULE 1 - bottom-up rule
i_parital(mdk(A)) :-
   member(B,cind_mdk(A)),
   (instance(B)
   ;
   concept(B)).

instance(A) :-
   i_partial(mdk(A)).

instance(A) :-
   cd_mdk(A,B).

% Content independent k-th modality sets

cind_mdk(A).
%relations

%%%Attribute A - concept, B - value
atr(A,B).

atr(X,B) :-
   member(X,A),
   atr(A,B).

atr(X,Y) :-
   atr(X,B),
   member(Y,B).

%%% Handling default values
def(Atr, A, B).

% part can be named 'concrete' arc
part([SetOfParts], Concept).
spec(BaseConcept, InheritedConcept).


%%% CSP

labelling([seg(...), seg(...), seg(...)], [connected(seg(...),seg(...)), connected(seg(...),seg(...)), parallel(seg(...),seg(...))] )

%%%%%%

labelling(Vars,Cons,RestCons):-
  sort_vars(Vars,NVars),  % we might not need it
  normalize_cons(Cons,NormCons),!, % normalize?
  solve(NVars,NormCons,RestCons).

solve([V::D|Vs],Cons,RCons):-
  domain_mem(V,D),
  test_cons(Cons,Vs,NewCons,NewVs),
                solve(NewVs,NewCons,RCons).
solve([],Cons,RCons):-
  denormalize_cons(Cons,RCons),!.

% test satisfiability of list of constraints
test_cons([C|RiCons],Vs,NewCons,NewVs):-
         test_c(C,Vs,AuxVs,Answ),
  (Answ=true -> NewCons=AuxCons
              ; NewCons=[Answ|AuxCons]),
         test_cons(RCons,AuxVs,AuxCons,NewVs).
test_cons([],Vs,[],Vs).

% test constraint satisfiability
test_c(V-C,Vs,NewVs,Answ):-
         C=..[P|Args],
  select_vars(V,NV),
  (callable(NV,C) -> (CC=..[P,NV,Vs,NewVs|Args],call(CC))
                   ; NewVs=Vs),
  (finished(NV,C) -> Answ=true ; Answ=NV-C).


%%%%%% auxiliary procedures %%%%%%%%%%

% transmit list of constraints to list of pairs Vars-Constraint, where
% Vars is a list of variables in Constraint
normalize_cons([C|Cs],[V-C|NewCs]):-
         find_vars(C,[],V),
         normalize_cons(Cs,NewCs),!.
normalize_cons([],[]).

denormalize_cons([V-C|T],[C|NT]):-
  denormalize_cons(T,NT).
denormalize_cons([],[]).

% select vars from list
select_vars([H|T],[H|NT]):-
        var(H),select_vars(T,NT),!.
select_vars([_|T],NT):-
         select_vars(T,NT).
select_vars([],[]).

% find vars in expression
find_vars(C,Vs,NewVs):-
        nonvar(C),
        C=..[_|Args],
        find_vars_list(Args,Vs,NewVs),!.
find_vars(X,Vs,NewVs):-
        var(X),
        (mem(X,Vs) -> NewVs=Vs ; NewVs=[X|Vs]).

% find vars in list of expressions
find_vars_list([H|T],Vs,NewVs):-
        find_vars(H,Vs,AuxVs),
        find_vars_list(T,AuxVs,NewVs),!.
find_vars_list([],Vs,Vs).

mem(X,[Y|T]):-
         X==Y,!.
mem(X,[_|T]):-
  mem(X,T).




% example of usage:
%  ?-labelling([X::[1<83>10],Y::[1<83>10]],[lt(X,Y),eq(X+5,Y)],_).

:-op(700,xfx,<83>).

% no sorting variables
sort_vars(Vs,Vs).

% generate member/test membership in domain
domain_mem(X,[H|T]):-
        H=(A<83>B) -> gen_num(X,A,B)
                  ; X=H.
domain_mem(X,[_|T]):-
        domain_mem(X,T).

% generate member/test membership in interval
gen_num(A,A,B):-
        A=<B.
gen_num(X,A,B):-
        A<B, A1 is A+1,
        gen_num(X,A1,B).

callable([],_). % only constraint without free variables is callable
finished([],_). % only constraint without free variables is finished

eq([],Vs,Vs,A,B):-
         CA is A, CB is B, CA=CB.
neq([],Vs,Vs,A,B):-
         CA is A, CB is B, CA\=CB.
lt([],Vs,Vs,A,B):-
  CA is A, CB is B, CA<CB.
gt([],Vs,Vs,A,B):-
  CA is A, CB is B, CA>CB.
diff([],Vs,Vs,List):-
  diff(List).
diff([H|T]):-
  mem(H,T) -> fail ; diff(T).
diff([]).

