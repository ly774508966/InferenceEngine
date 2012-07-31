%% OCTREE
%  by Michal Lisicki (2012)

% find bounding box
bb_max(object(vertex,graph([],[]),[X,Y,Z])) :-
    object(vertex,_,[X,_,_]),not((object(vertex,_,[X1,_,_]),X1>X)),
    object(vertex,_,[_,Y,_]),not((object(vertex,_,[_,Y1,_]),Y1>Y)),
    object(vertex,_,[_,_,Z]),not((object(vertex,_,[_,_,Z1]),Z1>Z)),!.

bb_min(object(vertex,graph([],[]),[X,Y,Z])) :-
    object(vertex,_,[X,_,_]),not((object(vertex,_,[X1,_,_]),X1<X)),
    object(vertex,_,[_,Y,_]),not((object(vertex,_,[_,Y1,_]),Y1<Y)),
    object(vertex,_,[_,_,Z]),not((object(vertex,_,[_,_,Z1]),Z1<Z)),!.

%  bb_min(V1),bb_max(V2),findall(object(vertex,G,[X,Y,Z]),object(vertex,G,[X,Y,Z]),Vs),add_list(ot(V1,V2,[],[]),Vs,NewTree,1),show(NewTree).
%  bb_min(V1),bb_max(V2),findall(object(vertex,G,[X,Y,Z]),object(vertex,G,[X,Y,Z]),Vs),add_list(ot(V1,V2,[],[]),Vs,NewTree,4),findall(object(segment,GS,[XS,YS,ZS]),object(segment,GS,[XS,YS,ZS]),Vs2),add_list(NewTree,Vs2,NewTree2,_),show(NewTree2).
add_list(Tree,[],Tree,_).

add_list(Tree,[X|R],NewTree,LeafCapacity) :-
    add(Tree,X,NewTree1,LeafCapacity),
    add_list(NewTree1,R,NewTree,LeafCapacity).

% Add object to the tree. Try to find leaves where children of the object belong.
% If found - add the object to the same leaves. If object has no children it must
% be on the lowest level of hierarchy, so add the object to the place it should 
% belong based on position
add(Tree,Object,NewTree,LeafCapacity) :-
    Object =.. [object,_,graph(Vs,_),_],
    (Vs == [],!,
    add(Tree,Object,[Object],NewTree,LeafCapacity);
    add(Tree,Object,Vs,NewTree,LeafCapacity)).

add(Tree,Object,[],Tree,LeafCapacity).

add(Tree,Object,[V|R],NewTree,LeafCapacity) :-
    add(Tree,Object,V,NewTree1,LeafCapacity),
    add(NewTree1,Object,R,NewTree,LeafCapacity).

%add(ot(BB_min,BB_max,Nodes,Elements),X,NewTree,LeafCapacity) :-
%    ot_geq(X,BB_min),
%    ot_geq(BB_max,X),
%    add_node(ot(BB_min,BB_max,Nodes,Elements),X,NewTree,LeafCapacity).

% Add Object to the leaf determined by V
add(ot(BB_min,BB_max,Nodes,Elements),Object,V,NewTree,LeafCapacity) :-
    ot_geq(V,BB_min),
    ot_geq(BB_max,V),
    add_node(ot(BB_min,BB_max,Nodes,Elements),Object,V,NewTree,LeafCapacity).

% Following is the case of addition of the lowest level element
add_node(ot(BB_min,BB_max,[],Elements),Object,Object,
    ot(BB_min,BB_max,[],[NewBucket|NewElements]),LeafCapacity) :-
    Object =.. [object,Name,_,_],
    Bucket =.. [Name,L],
    (del(Bucket,Elements,NewElements);
     not(del(Bucket,Elements,_)),
     L=[], NewElements = Elements),
    length([Object|L],N),
    N =< LeafCapacity,!,
    NewBucket =.. [Name,[Object|L]].

% extend if leaf capacity reached
add_node(ot(BB_min,BB_max,[],Elements),Object,Object,
         ot(BB_min,BB_max,NewNodes,[]),LeafCapacity) :-
    Object =.. [object,Name,_,_],
    Bucket =.. [Name,L],
    del(Bucket,Elements,_),
    length([Object|L],N),
    N > LeafCapacity,
    BB_min = object(vertex,graph([],[]),[XA,YA,ZA]),
    BB_max = object(vertex,graph([],[]),[XB,YB,ZB]),
    MNX is 0.5*(XA+XB), MNY is 0.5*(YA+YB), MNZ is 0.5*(ZA+ZB), 
    MiddleNode = object(vertex,graph([],[]),[MNX,MNY,MNZ]),
    Nodes = [ot(MiddleNode,BB_max,[],[]),
             ot(object(vertex,graph([],[]),[XA,MNY,ZA]),object(vertex,graph([],[]),[MNX,YB,MNZ]),[],[]),
	     ot(object(vertex,graph([],[]),[XA,MNY,MNZ]),object(vertex,graph([],[]),[MNX,YB,ZB]),[],[]),
             ot(object(vertex,graph([],[]),[MNX,MNY,ZA]),object(vertex,graph([],[]),[XB,YB,MNZ]),[],[]),
             ot(BB_min,MiddleNode,[],[]),
             ot(object(vertex,graph([],[]),[MNX,YA,ZA]),object(vertex,graph([],[]),[XB,MNY,MNZ]),[],[]),
	     ot(object(vertex,graph([],[]),[XA,YA,MNZ]),object(vertex,graph([],[]),[MNX,MNY,ZB]),[],[]),
             ot(object(vertex,graph([],[]),[MNX,YA,MNZ]),object(vertex,graph([],[]),[XB,MNY,ZB]),[],[])],
    allocate([Object|L],Nodes,NewNodes,LeafCapacity).

% recursively add to some of the nodes
add_node(ot(BB_min,BB_max,Nodes,[]),Object,Object,
         ot(BB_min,BB_max,NewNodes,[]),LeafCapacity) :-
    allocate([Object],Nodes,NewNodes,LeafCapacity). 

add_node(_,Object,Object,_,_) :-
    !,false.    % cut if object equal to V

% add to leaf
add_node(ot(BB_min,BB_max,[],Elements),Object,_,
    ot(BB_min,BB_max,[],[NewBucket|NewElements]),_) :-
    Object =.. [object,Name,_,_],
    Bucket =.. [Name,L],
    (del(Bucket,Elements,NewElements),!;
     L=[], NewElements = Elements),
    NewBucket =.. [Name,[Object|L]].

% recursively add to some of the nodes
add_node(ot(BB_min,BB_max,Nodes,[]),Object,V,
         ot(BB_min,BB_max,NewNodes,[]),LeafCapacity) :-
    add_to_nodes(Object,V,Nodes,NewNodes,LeafCapacity).

allocate([],Nodes,Nodes,_).

allocate([X|R],Nodes,NewNodes,LeafCapacity) :-
    add_to_nodes(X,X,Nodes,NewNodes1,LeafCapacity),
    allocate(R,NewNodes1,NewNodes,LeafCapacity).

% adds element to each node which fulfils requirements
add_to_nodes(_,_,[],[],_).

add_to_nodes(Object,V,[Node|RNodes],[NewNode|RNNodes],LeafCapacity) :-
    add(Node,Object,V,NewNode,LeafCapacity),!,
    add_to_nodes(Object,V,RNodes,RNNodes,LeafCapacity).

%add_to_nodes(Object,[Node|RNodes],[NewNode|RNNodes],LeafCapacity) :-
%    Node = ot(_,BB_max,_,_),
%    add(Node,Object,Object,NewNode,LeafCapacity),!,
%    (gt(BB_max,X);	                   % prevent further search if addition succeeded
%    add_to_nodes(Object,RNodes,RNNodes,LeafCapacity).

add_to_nodes(Object,V,[Node|RNodes],[Node|RNNodes],LeafCapacity) :-
    add_to_nodes(Object,V,RNodes,RNNodes,LeafCapacity).

list_call([X|R]) :-
    call(X),
    list_call(R).

ot_geq(Object1,Object2) :-
    Object1 =.. [object,_,_,[XA,YA,ZA]],
    Object2 =.. [object,_,_,[XB,YB,ZB]],
    XA >= XB, YA >= YB, ZA >= ZB.

ot_gt(Object1,Object2) :-
    Object1 =.. [object,_,_,[XA,YA,ZA]],
    Object2 =.. [object,_,_,[XB,YB,ZB]],
    XA > XB, YA > YB, ZA > ZB.

find(Tree,Object,Nodes) :-
    Object =.. [object,_,graph(Vs,_),_],
    (Vs == [],!,
    find_node(Tree,Object,Nodes);
    find_list(Tree,Vs,Nodes)).

find_list(_,[],[]).

find_list(Tree,[Object|R],Nodes) :-
    find(Tree,Object,Node),
    find_list(Tree,R,RNodes),
    conc(Node,RNodes,Nodes).

find_node(ot(BB_min,BB_max,[],Elements),Object,ot(BB_min,BB_max,[],Elements)) :-
    Object =.. [object,Name,_,_],
    Bucket =.. [Name,L],
    del(Bucket,Elements,_),
    member(Object,L).

find_node(ot(BB_min,BB_max,Nodes,[]),Object,FNodes) :-
    find_nodes(Object,Nodes,FNodes).

find_nodes(_,[],[]).

find_nodes(Object,[Node|RNodes],FNodes) :-
    find_node(Node,Object,FNode),!,
    find_nodes(Object,RNodes,FRNodes),
    conc(FNode,FRNodes,FNodes)..

find_nodes(Object,[Node|RNodes],FRNodes) :-
    find_nodes(Object,RNodes,FRNodes).

% Display the tree
show(Tree) :-
    show(Tree,0).

show(ot(BB_min,BB_max,[],Elements),Indent) :-
    tab(Indent), write(n(BB_min,BB_max,Elements)),nl.

show(ot(BB_min,BB_max,[N1,N2,N3,N4,N5,N6,N7,N8],Elements),Indent) :-
    Ind2 is Indent+40,
    show_list([N1,N2,N3,N4],Ind2),
    tab(Indent), write(n(BB_min,BB_max,Elements)),nl,
    show_list([N5,N6,N7,N8],Ind2).

show_list([],_).

show_list([X|L],Indent) :-
    show(X,Indent),
    show_list(L,Indent).
