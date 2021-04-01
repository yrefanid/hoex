elevator(X):-fast_elevator(X).
elevator(X):-slow_elevator(X).

operator(move_up_slow(Lift, F1, F2),
	[lift_at(Lift, F1)],
	[lift_at(Lift, F1)],
	[lift_at(Lift, F2)]):-
    slow_elevator(Lift), count(F1), count(F2), above(F1, F2), reachable_floor(Lift, F2).
 
operator(move_down_slow(Lift,F1,F2),
  [lift_at(Lift, F1)],
  [lift_at(Lift, F1)],
  [lift_at(Lift, F2)]):- 
  slow_elevator(Lift), count(F1), count(F2), above(F2,F1), reachable_floor(Lift,F2).

operator(move_up_fast(Lift, F1, F2),
	[lift_at(Lift, F1)],
	[lift_at(Lift, F1)],
	[lift_at(Lift, F2)]):-
    fast_elevator(Lift), count(F1), count(F2), above(F1, F2), reachable_floor(Lift, F2).
 
operator(move_down_fast(Lift,F1,F2),
  [lift_at(Lift, F1)],
  [lift_at(Lift, F1)],
  [lift_at(Lift, F2)]):-
	fast_elevator(Lift), count(F1), count(F2), above(F2,F1), reachable_floor(Lift,F2).

operator(board(P,Lift,F,N1,N2),
	[lift_at(Lift,F), passenger_at(P, F), passengers(Lift, N1)],
  	[passenger_at(P, F), passengers(Lift,N1)], 
  	[boarded(P,Lift), passengers(Lift,N2)]):-
	passenger(P), elevator(Lift), count(F), count(N1), count(N2), next(N1, N2), can_hold(Lift, N2).
  
operator(leave(P,Lift,F,N1,N2),
	[lift_at(Lift, F), boarded(P, Lift), passengers(Lift,N1)],
  	[boarded(P, Lift),passengers(Lift, N1)],
	[passenger_at(P, F),passengers(Lift, N2)] ):-
  		passenger(P),elevator(Lift), count(F), count(N1), count(N2), next(N2, N1).
