count(n0).
count(n1).
count(n2).
count(n3).
count(n4).
count(n5).
count(n6).
count(n7).
count(n8).

passenger(p0).
passenger(p1).
passenger(p2).

fast_elevator(fast0).

slow_elevator(slow0_0).
slow_elevator(slow1_0).

next(n0, n1).
next(n1, n2).
next(n2, n3).
next(n3, n4). 
next(n4, n5) .
next(n5, n6). 
next(n6, n7). 
next(n7, n8). 

above(n0, n1) .
above(n0, n2) .
above(n0, n3) .
above(n0, n4) .
above(n0, n5) .
above(n0, n6) .
above(n0, n7) .
above(n0, n8) .
above(n1, n2).
above(n1, n3) .
above(n1, n4).
above(n1, n5) .
above(n1 ,n6) .
above(n1, n7) .
above(n1, n8) .
above(n2, n3).
above(n2, n4) .
above(n2, n5) .
above(n2, n6).
above(n2, n7) .
above(n2, n8) .
above(n3, n4).
above(n3, n5).
above(n3, n6).
above(n3, n7).
above(n3 ,n8) .
above(n4, n5).
above(n4, n6) .
above(n4, n7).
above(n4, n8) .
above(n5, n6) .
above(n5, n7).
above(n5, n8) .
above(n6, n7).
above(n6, n8) .
above(n7, n8) .

can_hold(fast0, n1) .
can_hold(fast0, n2) .
can_hold(fast0, n3) .
can_hold(slow0_0, n1) .
can_hold(slow0_0, n2) .
can_hold(slow1_0, n1) .
can_hold(slow1_0 ,n2) .


reachable_floor(fast0, n0).
reachable_floor(fast0, n2).
reachable_floor(fast0, n4).
reachable_floor(fast0, n6).
reachable_floor(fast0, n8).

reachable_floor(slow0_0, n0).
reachable_floor(slow0_0, n1).
reachable_floor(slow0_0, n2).
reachable_floor(slow0_0, n3).
reachable_floor(slow0_0, n4).

reachable_floor(slow1_0, n4).
reachable_floor(slow1_0, n5).
reachable_floor(slow1_0, n6).
reachable_floor(slow1_0, n7).
reachable_floor(slow1_0, n8).

initial([lift_at(fast0, n0), passengers(fast0, n0), lift_at(slow0_0, n2), passengers(slow0_0,n0),
lift_at(slow1_0,n4),passengers(slow1_0, n0), passenger_at(p0,n8),passenger_at(p1, n3),
passenger_at(p2, n2)]).

goal([passenger_at(p0,n4), passenger_at(p1,n6), passenger_at(p2,n1)]).
