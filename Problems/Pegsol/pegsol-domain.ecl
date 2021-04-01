operator(jump_new_move(From,Over,To),
	[move_ended, occupied(From), occupied(Over), free(To)],
	[move_ended, occupied(From), occupied(Over), free(To)],
	[free(From),free(Over),occupied(To), last_visited(To)]):-
		location(From), location(Over), location(To), in_line(From, Over, To), in_line(From, Over, To).
    
operator(jump_continue_move(From, Over, To),
    [last_visited(From), occupied(From), occupied(Over), free(To)],
	[occupied(From), occupied(Over), free(To), last_visited(From)],
	[free(From), free(Over), occupied(To), last_visited(To)]):-
		location(From),location(Over),location(To), in_line(From,Over,To).
    
operator(end_move(Loc),
	[last_visited(Loc)],
	[last_visited(Loc)],
    [move_ended]):-
    	location(Loc).