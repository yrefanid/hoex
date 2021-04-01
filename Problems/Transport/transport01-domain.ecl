operator(drive(V,L1,L2),
	[at(V, L1)],
	[at(V, L1)],
	[at(V, L2)]
	):-	vehicle(V), location(L1), location(L2), road(L1, L2).
  
operator(pick_up(V,L,P,S1,S2),
	[at(V, L), at(P, L), capacity(V, S2)],
	[at(P, L), capacity(V, S2)],
    [in(P, V), capacity(V, S1)]):-
    vehicle(V), location(L), package(P), 
    capacity_number(S1), capacity_number(S2), capacity_predecessor(S1, S2).

operator(drop(V,L,P,S1,S2),
	[at(V, L),in(P, V), capacity(V, S1)],
	[in(P, V), capacity(V, S1)],
	[at(P, L), capacity(V, S2)]):-
	vehicle(V), location(L), package(P), capacity_number(S1), capacity_number(S2),
        capacity_predecessor(S1, S2).
