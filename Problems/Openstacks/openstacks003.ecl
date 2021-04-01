count(n0).
count(n1).
count(n2).
count(n3).

next_count(n0, n1).
next_count(n1, n2).
next_count(n2, n3).

/*
includes(o1, p2).
includes(o2, p1).
includes(o2, p2).
includes(o3, p3).
includes(o4, p3).
includes(o4, p4).
includes(o5, p5).
*/

initial([stacks_avail(n0), waiting(o1), waiting(o2), waiting(o3), 
not_made(p1), not_made(p2), not_made(p3)]).

goal([shipped(o1), shipped(o2), shipped(o3)]).

