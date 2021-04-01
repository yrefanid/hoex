truck(t1).
truck(t2).

package(p1).
package(p2).
package(p3).
package(p4).
package(p5).
package(p6).

location(a).
location(b).

connected(a,b).
connected(b,a).

initial([at(t1,a), at(t2,a), at(p1,a), at(p2,a), at(p3,a), at(p4,a), at(p5,a), at(p6,a), empty(t1), empty(t2)]).
goal([at(p1,b), at(p2,b), at(p3,b), at(p4,b), at(p5,b), at(p6,b)]).

operator(load(T,P,L),
	[at(T,L), at(P,L), empty(T)],
	[at(P,L), empty(T)],
	[not_empty(T), in(P,T)])	:-truck(T), package(P), location(L).

operator(unload(T,P,L),
	[at(T,L), in(P,T), not_empty(T)],
	[in(P,T), not_empty(T)],
	[empty(T), at(P,L)])	:-truck(T), package(P), location(L).
	
	
operator(move(T,L1,L2),
	[at(T,L1)],
	[at(T,L1)],
	[at(T,L2)])		:-truck(T), location(L1), location(L2), connected(L1,L2), L1\=L2.
