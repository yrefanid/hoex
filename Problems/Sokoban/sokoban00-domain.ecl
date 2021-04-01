operator(move(P,From,To,Dir),
   [at(P,From), clear(To)],
   [at(P,From), clear(To)],
   [at(P,To), clear(From)]):-
   
   player(P), location(From), location(To), 
   direction(Dir), move_dir(From,To,Dir).
   
    
operator(push_to_nongoal1(P,S,Ppos, From,To, Dir),
   [at(P,Ppos), at(S,From), clear(To), at_goal(S)],
   [at(P,Ppos), at(S,From), clear(To), at_goal(S)],
   [at(P,From), at(S,To), clear(Ppos),at_nongoal(S)]):-
   
   player(P), stone(S), location(Ppos), location(From), location(To), direction(Dir),
   move_dir(Ppos,From,Dir), move_dir(From, To,Dir), is_nongoal(To).
   
operator(push_to_nongoal2(P,S,Ppos, From,To, Dir),
   [at(P,Ppos), at(S,From), clear(To), at_nongoal(S)],
   [at(P,Ppos), at(S,From), clear(To)],
   [at(P,From), at(S,To), clear(Ppos)]):-
   
   player(P), stone(S), location(Ppos), location(From), location(To), direction(Dir),
   move_dir(Ppos,From,Dir), move_dir(From, To,Dir), is_nongoal(To).
   
operator(push_to_goal1(P,S,Ppos,From,To,Dir),
	[at(P,Ppos), at(S,From), clear(To), at_nongoal(S)], 
	[at(P,Ppos), at(S,From), clear(To), at_nongoal(S)],
	[at(P,From), at(S,to), clear(Ppos), at_goal(S)]):-
	
	player(P), stone(S), location(Ppos), location(From), location(To), direction(Dir),
    move_dir(Ppos,From,Dir), move_dir(From, To,Dir), is_goal(To).

   operator(push_to_goal1(P,S,Ppos,From,To,Dir),
	[at(P,Ppos), at(S,From), clear(To), at_goal(S)], 
	[at(P,Ppos), at(S,From), clear(To)],
	[at(P,From), at(S,to), clear(Ppos)]):-
	
	player(P), stone(S), location(Ppos), location(From), location(To), direction(Dir),
    move_dir(Ppos,From,Dir), move_dir(From, To,Dir), is_goal(To).
