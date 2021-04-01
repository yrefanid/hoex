:-lib(lists).
:-lib(cio).
  
:-dynamic dist/2.	% dist(P,T) means that proposition P is achievable since time T
:-dynamic action/2. % action(A,T) means that action A is applicable since time T
:-dynamic m/3.		% m(S,T,T0) means that propositions in S are mutexed until T (starting from T0)
:-dynamic iterations/1.
:-dynamic counter/1.
max_order(4).		% The maximum order of mutexes, inf for global consistency
memoization(yes).

display_messages(off).

cwrite(X):-display_messages(on),!,write(X).
cwrite(_). 

cnl:-display_messages(on),!,nl.
cnl.

retract_all:-
	retract_all(dist(_,_)),
	retract_all(m(_,_,_)),
%	assert((m([in(P1,T),in(P2,T)],inf,1):-package(P1), package(P2),truck(T),P1\=P2,sort([P1,P2],[P1,P2]))),
	retract_all(iterations(_)),
	retract_all(action(_,_)),
	!.
	
% Succeeds if m(S,T) is subsumed by another mutex	
covered_mutex(S,T):-
	m(S1,T1,_), 	
	subset12(S1,S),
	less_equal(T,T1).
/*
covered_mutex(S,T):-
	sort(S,Ssorted),
	subset(S1,Ssorted),
	m(S1,T1,_), 	
	less_equal(T,T1).
*/
	
% Asserts m(S,T,T0), where T0 is the time step 
% at which the new mutex is generated
new_mutex(S,T,T0):-
	max_order(MaxOrder),
	length(S,SL),
	less_equal(SL,MaxOrder),
	sort(S,Ssorted),
	not covered_mutex(Ssorted,T), 	% mutexed sets are always sorted
	!,
	retract_covered_mutexes(Ssorted,T),
	my_assert(m(Ssorted,T,T0)).
new_mutex(_,_,_).

% Asserts m(S,T,T0), where T0 is the time step 
% at which the new mutex is generated
new_mutex_unlimited(S,T,T0):-
	sort(S,Ssorted),
	not covered_mutex(Ssorted,T), 	% mutexed sets are always sorted
	!,
	retract_covered_mutexes(Ssorted,T),
	my_assert(m(Ssorted,T,T0)).
new_mutex_unlimited(_,_,_).



% Provided that m(S,T,_) is not subsumed, this procedure
% retracts other subsumed mutexes.
retract_covered_mutexes(S,T):-
	m(S1,T1,T2),
	subset(S,S1),
	less_equal(T1,T),
	my_retract(m(S1,T1,T2)),
	fail.
retract_covered_mutexes(_,_).


% The starting procedure
go:-
	retract_all,
	initial(Init),
	record_new_facts(Init,0),
	assert(iterations(0)),
	repeat,
		main_loop,	% The main procedure
	iterations(T),

	goal_achieved(T),	% Check condition whether the goal has 
						% been achieved
	%level_off(T),		% Alternatively, check whether the graph
						% is leveled off
	write("Goal achieved at t="), write(T), nl,
	goal(G),
	extract_plan(G,T).


extract_plan(G,_T):-
	initial(Init),
	subset12(G,Init),
	!.
extract_plan(G,T):-
	T1 is T-1,
	find_newly_achieved(G,T,Gnew),
	process_newly_achieved_facts(Gnew,T,GnewMutexFormat),
	subtract(G,Gnew,Gold),
	sort(Gold,GoldSorted),
	find_level_broken_mutexes(GoldSorted,BrokenMutexes,T),
%	display_list(BrokenMutexes),nl,
	append(GnewMutexFormat,BrokenMutexes,AllLevelMutexes),
	serialize_mutexes(AllLevelMutexes,[],Ss),
	% backtracking point ==>
	mutex_achievement_option(AllLevelMutexes,Ss,StepActionsWithMutexes,T),
	extract_actions(StepActionsWithMutexes,StepActions),
	not_deleting_G(StepActions,G),
	extract_retained_goals(Gold,StepActions,NoOp),
	
	add_new_step_actions(BrokenMutexes,G,StepActions,NoOp,NoOp2,[],NewStepActions,T1),
	append(StepActions,NewStepActions,AllStepActions),
	AllStepActions\=[],
	union_preconditions(AllStepActions,[],G1),
	union(G1,NoOp2,G2),
	achieved(G2,T1),
	compatible_propositions(G2,T1),
%	!,
	write("Step "), write(T1), write(" : "), unconditionally_display_list(AllStepActions),nl,
	extract_plan(G2,T1),
	!.
extract_plan(G,T):-
	memoization(yes),
	memoize(G,T),
	fail.
	
memoize(G,T):-
	find_latest_achieved_fact(G,0,Tlatest),
	T1 is T+1,
	new_mutex_unlimited(G,T1,Tlatest).

find_latest_achieved_fact([],Tlatest,Tlatest):-!.
find_latest_achieved_fact([P|G],T0,Tlatest):-
	dist(P,T1),
	max(T0,T1,Tmax),
	find_latest_achieved_fact(G,Tmax,Tlatest).
	
add_new_step_actions(_BrokenMutexes,_G,_StepActions,NoOp,NoOp,NewStepActions,NewStepActions,_T1).
add_new_step_actions(BrokenMutexes,G,StepActions,NoOp0,NoOp,NewStepActions0,NewStepActions,T1):-
	NoOp0\=[],
	action(A,TA),
	TA=<T1,
	operator(A,_Precs,Dels,Adds),
	intersection(Adds,NoOp0,X),X\=[],
	intersection(Dels,G,[]),
	not hinder_breaking_mutexes(Dels,BrokenMutexes),
	subtract(NoOp0,Adds,NoOp1),
	(
		NewStepActions0=[]
		;
		NewStepActions0=[H|_],
		sort([A,H],[A,H])
	),
	not member(A,StepActions),	
	append(StepActions,NewStepActions0,NewStepActions1),
	not mutexed_actions([A|NewStepActions1],T1),
	add_new_step_actions(BrokenMutexes,G,StepActions,NoOp1,NoOp,[A|NewStepActions0],NewStepActions,T1).
		
hinder_breaking_mutexes(_Dels,[]):-!,fail.
hinder_breaking_mutexes(Dels,[s(M,_AM)|_BrokenMutexes]):-
	intersection(Dels,M,X),X\=[],
	!.
hinder_breaking_mutexes(Dels,[_M|BrokenMutexes]):-
	hinder_breaking_mutexes(Dels,BrokenMutexes).

	
unconditionally_display_list([]):-!.
unconditionally_display_list([H|T]):-write(H),write(", "),unconditionally_display_list(T).
	
	
not_deleting_G([],_G):-!.
not_deleting_G([A|StepActions],G):-
	operator(A,_Precs,Dels,_Adds),
	intersection(Dels,G,[]),
	not_deleting_G(StepActions,G).
	
process_newly_achieved_facts([],_T,[]):-!.
process_newly_achieved_facts([G|Gnew],T,[s([G],AG)|GnewMutexFormat]):-
	T1 is T-1,
	findall(A,(action(A,T1),operator(A,_Precs,_Dels,Adds),member(G,Adds)),AG),
	!,
	process_newly_achieved_facts(Gnew,T,GnewMutexFormat).

find_level_broken_mutexes(Gold,BrokenMutexes,T):-
	findall(S,(m(S,T,_T0),subset(S,Gold)),BrokenMutexes0),
	enhance_with_breaking_actions(BrokenMutexes0,T,BrokenMutexes).
	
enhance_with_breaking_actions([],_T,[]):-!.
enhance_with_breaking_actions([S|BrokenMutexes0],T,[s(S,AS)|BrokenMutexes]):-
	findall(A,(action(A,T1),T1<T,operator(A,_Precs,Dels,Adds),intersection(S,Adds,X),X\=[],intersection(S,Dels,[])),AS),
	enhance_with_breaking_actions(BrokenMutexes0,T,BrokenMutexes).

	
			
extract_retained_goals([],_StepActions,[]):-!.
extract_retained_goals([G|Gold],StepActions,[G|NoOp]):-
	not_achieved_by_any_action(G,StepActions),
	!,
	extract_retained_goals(Gold,StepActions,NoOp).
extract_retained_goals([_G|Gold],StepActions,NoOp):-
	extract_retained_goals(Gold,StepActions,NoOp).

not_achieved_by_any_action(_G,[]):-!.
not_achieved_by_any_action(G,[A|_StepActions]):-
	operator(A,_Precs,_Dels,Adds),
	member(G,Adds),
	!,
	fail.
not_achieved_by_any_action(G,[_A|StepActions]):-
	not_achieved_by_any_action(G,StepActions).


union_preconditions([],G,G):-!.
union_preconditions([A|Actions],G1,G):-
	operator(A,Precs,_Dels,_Adds),
	union(Precs,G1,G2),
	union_preconditions(Actions,G2,G).

			
find_newly_achieved([],_T1,[]):-!.
find_newly_achieved([P|G],T1,[P|Gnew]):-
	dist(P,Tp),
	T1=Tp,
%	less_equal(T1,Tp),
	!,
	find_newly_achieved(G,T1,Gnew).
find_newly_achieved([_P|G],T1,Gnew):-
	find_newly_achieved(G,T1,Gnew).

	
main_loop:-
		retract(iterations(T0)),
		T1 is T0+1,
		assert(iterations(T1)),
		nl, write("ITERATION : "), write(T1), nl,nl,
		find_new_achievements(NewActions0,NewFacts1,T0),
%		sort(NewActions0,SortedNewActions0),
%		sort(NewFacts1,SortedNewFacts1),
		record_new_actions(NewActions0,T0),
		record_new_facts(NewFacts1,T1),
		process_new_facts(NewFacts1,NewActions0,Facts_as_Mutexes),
		find_broken_mutexes(BrokenMutexes,T1),
%		unconditionally_display_list(BrokenMutexes),nl,
		record_broken_mutexes(BrokenMutexes,T1),
		append(Facts_as_Mutexes,BrokenMutexes,AllMutexes),
%		display_broken_mutexes(BrokenMutexes),
		find_mutexes_between_broken_mutexes(AllMutexes,T1).
	
% This procedure gets the list of the newly achieved propositions and the newly
% applicable actions and returns a list of pais s([F],AF), where each newly
% achieved proposition F is accompanied by the alternative new actions AF 
% that can achieve it.
process_new_facts([],_NewActions0,[]):-!.
process_new_facts([F|NewFacts1],NewActions0,[s([F],AF)|Facts_as_Mutexes]):-
	findall(A,(member(A,NewActions0),operator(A,_Precs,_Dels,Adds),member(F,Adds)),AF),
	process_new_facts(NewFacts1,NewActions0,Facts_as_Mutexes).

goal_achieved(T):-
	goal(Goal),
	achieved(Goal,T),
	compatible_propositions(Goal,T).

level_off(T):-dist(_,T),!,fail.
level_off(T):-T1 is T-1, action(_,T1),!,fail.
level_off(T):-m(_,_,T),!, fail.
level_off(T):-m(_,T,_),!, fail.
level_off(_):-write("Graph leveled-off!!!"),nl.


% This procedure breaks a list of mutexes at time T2
record_broken_mutexes([],_T2):-!.
record_broken_mutexes([s(S,_Actions)|BrokenMutexes],T2):-
	my_retract(m(S,_T,T0)),
	my_assert(m(S,T2,T0)),
	!,
	record_broken_mutexes(BrokenMutexes,T2).

% This procedure returns a list of broken mutexes at T, 
% where each broken mutex is accompanied by a set of actions.
% Note that a single action is enough to break a mutex, so
% these are the alternative actions to break the mutex.
find_broken_mutexes(BrokenMutexes,T):-
	findall(s(S,A),broken_mutex(S,A,T),BrokenMutexes0),
	sort(BrokenMutexes0,BrokenMutexes1),
	group(BrokenMutexes1,[],BrokenMutexes).

display_broken_mutexes([]):-!.
display_broken_mutexes([s(S,Actions)|BrokenMutexes]):-
	cwrite(S), cwrite(" from "), cwrite(Actions),cnl,
	display_broken_mutexes(BrokenMutexes).


% This procedure checks in BrokenMutexes1 for alternative ways to 
% break the same mutex, and puts the alternative actions in the same list
% for each broken mutex.
group([],BrokenMutexes,BrokenMutexes):-!.
group([s(S,A)|BrokenMutexes1],[],BrokenMutexes):-
	group(BrokenMutexes1, [s(S,[A])],BrokenMutexes).
group([s(S,A)|BrokenMutexes1], [s(S,Actions)|BrokenMutexes2],BrokenMutexes):-
	!,
	group(BrokenMutexes1, [s(S,[A|Actions])|BrokenMutexes2],BrokenMutexes).
group([s(S,A)|BrokenMutexes1], [s(S1,Actions)|BrokenMutexes2],BrokenMutexes):-
	!,
	group(BrokenMutexes1, [s(S,[A]), s(S1,Actions)|BrokenMutexes2],BrokenMutexes).


% This procedure checks whether m(S,T1,_), where T1>T, breaks at T.
% Action A is one way to break the mutex.
broken_mutex(S,A,T):-
	m(S,Ts,Ts0),
	less(Ts0,T),
	less(T,Ts),
	T1 is T-1,
	action(A,Ta),
	less_equal(Ta,T1),
	operator(A,Precs,Dels,Adds),
	intersection(S,Adds,X1),X1\=[],
	intersection(S,Dels,[]),
	subtract(S,Precs,S1),
	subtract(S1,X1,S2),
	not mutexed_sets_of_facts(Precs,S2,T1).

% This rule checks whether two sets of propositions (i.e., their union)
% are mutexed, i.e., they cannot be true together at T
mutexed_sets_of_facts(S1,S2,T):-
	append(S1,S2,S),
	m(S0,T1,_),
	subset12(S0,S),
	less(T,T1).

counter_zero:-
	retract_all(counter(_)),
	assert(counter(0)).
	
increase_counter:-
	retract(counter(X)),
	X1 is X+1,
	assert(counter(X1)).
	
% The main procedure to create new mutexes		
process_options(S,Options,T):-
	flatten_options(Options,FlattedOptions),
	cartesian_product(FlattedOptions,Products),
	create_mutexes(S,Products,T).

sort_lists([],[]):-!.
sort_lists([H|T],[SortedH|SortedT]):-
	sort(H,SortedH),
	sort_lists(T,SortedT).
	
flatten_options([],[]):-!.
flatten_options([Option|Options],[FlattedOption|FlattedOptions]):-
	flatten_option(Option,[],FlattedOption0),
	sort(FlattedOption0,FlattedOption),
	flatten_options(Options,FlattedOptions).
	
flatten_option([],Flat,Flat):-!.
flatten_option([a(A,M,_)|Option],Flat0, Flat):-
	operator(A,_Precs,Dels,_Adds),
	list_of_lists(Dels,DelsLoL),
	union(DelsLoL,Flat0,Flat1),
	sort_lists(M,SortedM),
	union(SortedM,Flat1,Flat2),				% carefull on the ordering 
	flatten_option(Option,Flat2,Flat).


cartesian_product([],[]):-!.
cartesian_product([Product], Product):-!.
cartesian_product([Option1,Option2], Product):-
	!,
	binary_cartesian(Option1,Option2,Product1),
	Product1=Product2,
%	length(Product1,L_product1),
%	remove_dublicates(Product1,Product2),
%	length(Product2,L_product2),
	remove_covered_items(Product2,Product3),
%	Product3=Product.
	remove_subsumed_items(Product3,Product).
%	length(Product,L_product).
cartesian_product(Options,Product):-
	length(Options,L),
	L1 is truncate(L/2),
	integer(L1,L1int) ,
	L2 is L-L1int,
	length(Options1,L1int), length(Options2,L2),
	append(Options1,Options2,Options),
	!,
	cartesian_product(Options1,Product1),
	cartesian_product(Options2,Product2),
	cartesian_product([Product1,Product2],Product).

binary_cartesian(Option1,Option2,Product):-
%	length(Option1,L1),length(Option2,L2),
	findall(S,(member(S1,Option1), member(S2,Option2), union(S1,S2,S0), sort(S0,S)), Product0),
	!,
	small_to_large_subsets(Product0,Product).
%binary_cartesian(_Option1,_Option2,[]):-!.

	
remove_subsumed_items([],[]):-!.
remove_subsumed_items([S|Product3],Product):-
	m(S1,inf,_),
	subset(S1,S),
	!,
%	write(bingo),nl,
	remove_subsumed_items(Product3,Product).
remove_subsumed_items([S|Product3],[S|Product]):-
	remove_subsumed_items(Product3,Product).
	

remove_dublicates([],[]):-!.
remove_dublicates([H|T0],[H|T]):-
	not exists_in_ordered_subsets(H,T0),
	!,
	remove_dublicates(T0,T).
remove_dublicates([_H|T0],T):-
	!,
	remove_dublicates(T0,T).
	
exists_in_ordered_subsets(_H,[]):-!,fail.
exists_in_ordered_subsets(H,[H1|_]):-
	length(H,L),
	length(H1,L1),
	L<L1,
	!,
	fail.
exists_in_ordered_subsets(H,[H1|_]):-
	H=H1,
	!.
exists_in_ordered_subsets(H,[_H1|T1]):-
	exists_in_ordered_subsets(H,T1).


	
remove_covered_items([],[]):-!.
remove_covered_items([S|Option1], [S|Option]):-
	delete_all_covered(S,Option1,Option2),
	!,
	remove_covered_items(Option2, Option).
%remove_covered_items([S|Option1], [S|Option]):-
%	remove_covered_items(Option1, Option).

delete_all_covered(_S,[],[]):-!.
delete_all_covered(S,[S1|Option1],Option2):-
	subset(S,S1),
	!,
	delete_all_covered(S,Option1,Option2).
delete_all_covered(S,[S1|Option1],[S1|Option2]):-
	!,
	delete_all_covered(S,Option1,Option2).
	

% For the union of the propositions of a set of broken mutexes S,
% for the cartesian product of the negated propositions of a set
% of breaking actions, create new mutexes...
create_mutexes(_S,[],_T):-!.
create_mutexes(S,[Product|Products],T):-
	Product\=[],
	!,
	union(S,Product,M),
	new_mutex(M,inf,T),
	create_mutexes(S,Products,T).
create_mutexes(S,[[]|Products],T):-
	create_mutexes(S,Products,T).


% Give a list of 'Options', i.e., a list of sets of actions that can break
% a set of mutexes simultaneously, this procedure tries to find a
% reduced set of actions with the same achievements...
reduce_options(_Options, [],[]):-!.
reduce_options(Options,[Option|Options0],[Option|ReducedOptions]):-
	not covered_option(Option,Options,Options0),
	!,
	reduce_options(Options,Options0,ReducedOptions).
reduce_options(Options,[_|Options0],ReducedOptions):-
	reduce_options(Options,Options0,ReducedOptions).
			
covered_option(Option,Options,Options0):-
	member(Option0,Options),
%	Option0\=Option,
	extract_sets(Option0,Option0Sets),
	extract_sets(Option,OptionSets),
	all_covered(Option0Sets, OptionSets),
	(
		not all_covered(OptionSets,Option0Sets),
		!
		;
		member(Option0,Options0)
	).
		
extract_sets([],[]):-!.
extract_sets([a(A,Mutexes,_)|Option],OptionSets):-
	operator(A,_Precs,Dels,_Adds),
	list_of_lists(Dels,DelsLoL),
	append(DelsLoL,Mutexes,Sets1),
	append(Sets1,OptionSets1,OptionSets),
	extract_sets(Option,OptionSets1).
	
all_covered([],_Sets2):-!.
all_covered([S1|Sets1],Sets2):-
	member(S2,Sets2),
	subset12(S2,S1),
	!,
	all_covered(Sets1,Sets2).
	
list_of_lists([],[]):-!.
list_of_lists([H|Dels],[[H]|DelsLoL]):-
	list_of_lists(Dels,DelsLoL).
	
add_new_actions(Option1,Option,T,Ss):-
	T1 is T-1,
	find_mutexed_propositions(Option1,Option1WithMutexes,T1),
	remove_mutexed_propositions(Option1,Option1WithMutexes,Option1WithMutexes,Option2WithMutexes),
	enhance_set_of_actions(Option2WithMutexes,Option3WithMutexes,[],T1,Ss),
%	append(NewActions,Option2WithMutexes,Option3WithMutexes),
	Option=Option3WithMutexes.	
	
cond_break([move_from_table(e,c)],move_from_table(d,b)):-
	raise_breakpoint.
	
cond_break(_,_).

% Enhances a set of actions (consisting of terms of the form a(A,Mutexes,RemovedMutexes))
% with new interesting actions...
enhance_set_of_actions(Option3WithMutexes,Option3WithMutexes,_NewActions,_T1,_Ss).
enhance_set_of_actions(Option2WithMutexes,Option3WithMutexes,NewActions,T1,Ss):-
	extract_actions(Option2WithMutexes,AllActions),
	action(A,TA),		% Consider a new actions that might be interesting...
	less_equal(TA,T1),
	% New actions are added in lexicographic order to avoid duplicates
	(
		NewActions=[]
	;
		NewActions=[a(A0,_)|_],
		A>A0
	),
%	cond_break(AllActions,A),
	not member(A,AllActions),
	achieves_something(A,Option2WithMutexes),
	not deletes_something_achieved(A,Option2WithMutexes),
	operator(A,_Precs,Dels,_Adds), 
	intersection(Ss,Dels,[]),
	not mutexed_actions([A|AllActions],T1),
	findall(M,mutexed_propositions_with_action(A,M,T1),Mutexes),
	remove_mutexed_propositions([A|AllActions],[a(A,Mutexes,[])|Option2WithMutexes],[a(A,Mutexes,[])|Option2WithMutexes],Option21WithMutexes),
	enhance_set_of_actions(Option21WithMutexes,Option3WithMutexes,[A|NewActions],T1, Ss).
	
achieves_something(_A,[]):-!,fail.
achieves_something(A,[a(_A1,Mutexes,_)|_Option2WithMutexes]):-
	achieves_something2(A,Mutexes),
	!.
achieves_something(A,[_|Option2WithMutexes]):-
	achieves_something(A,Option2WithMutexes).
	
achieves_something2(_A,[]):-!,fail.
achieves_something2(A,[M|_Mutexes]):-
	operator(A,_Precs,Dels,Adds),
	intersection(Dels,M,[]),
	intersection(Adds,M,X),X\=[],
	!.
achieves_something2(A,[_M|Mutexes]):-
	achieves_something2(A,Mutexes).
		
deletes_something_achieved(_A,[]):-!,fail.
deletes_something_achieved(A,[a(_A1,_,Mutexes)|_Option2WithMutexes]):-
	deletes_something_achieved2(A,Mutexes),
	!.
deletes_something_achieved(A,[_|Option2WithMutexes]):-
	deletes_something_achieved(A,Option2WithMutexes).
	
deletes_something_achieved2(_A,[]):-!,fail.
deletes_something_achieved2(A,[M|_Mutexes]):-
	operator(A,_Precs,Dels,_Adds),
	intersection(Dels,M,X),
	X\=[],
	!.
deletes_something_achieved2(A,[_M|Mutexes]):-
	deletes_something_achieved2(A,Mutexes).
	

extract_actions([],[]):-!.	
extract_actions([a(A,_,_)|Option2WithMutexes],[A|Option2]):-
	extract_actions(Option2WithMutexes,Option2).

% Given a list of actions that break a set of mutexes at T1, this procedure
% returns a list of terms a(A,Mutexes,[]), where A is an action and Mutexes
% are lists of propositions that are mutexed with A's preconditions.	
find_mutexed_propositions([],[],_T1):-!.
find_mutexed_propositions([A|Option1],[a(A,Mutexes,[])|Option1WithMutexes],T1):-
	findall(M,mutexed_propositions_with_action(A,M,T1),Mutexes),
	find_mutexed_propositions(Option1,Option1WithMutexes,T1).

% Given a list of terms of the form a(A,Mutexes,[]), this procedure
% eliminates some of the Mutexes for each action A, that are either "achieved" by other actions
% or subsumed by other mutexes
remove_mutexed_propositions(_Option1,_Option10WithMutexes,[],[]):-!.
remove_mutexed_propositions(Option1, Option10WithMutexes,[a(A,Mutexes,RemovedMutexes)|Option1WithMutexes],[a(A,Mutexes1,RemovedMutexes1)|Option2WithMutexes]):-
	remove_mutexed_propositions2(A,Mutexes,Option1,Option10WithMutexes,Mutexes1),
	subtract(Mutexes1,Mutexes,Mutexes2),
	append(Mutexes2,RemovedMutexes,RemovedMutexes1),
	remove_mutexed_propositions(Option1, Option10WithMutexes, Option1WithMutexes,Option2WithMutexes).
	
remove_mutexed_propositions2(_A,[],_Option1,_Option10WithMutexes,[]):-!.
remove_mutexed_propositions2(A,[M|Mutexes],Option1,Option10WithMutexes,[M|Mutexes1]):-
	not action_achieves_it(M,A,Option1),
	not action_deletes_it(M,Option1),
	not action_subsumes_it(M,A,Option10WithMutexes),
	!,
	remove_mutexed_propositions2(A,Mutexes,Option1,Option10WithMutexes,Mutexes1).
remove_mutexed_propositions2(A,[_M|Mutexes],Option1,Option10WithMutexes,Mutexes1):-
	remove_mutexed_propositions2(A,Mutexes,Option1,Option10WithMutexes,Mutexes1).
	
% If the mutex is achieved by some action A1, then its propositions can hold together after
% the execution of all actions
action_achieves_it(M,A,Option1):-
	member(A1,Option1),
	A1\=A,
	operator(A1,_Precs1,Dels1,Adds1),
	intersection(M,Dels1,[]),
	intersection(M,Adds1,X),X\=[].

% If any actions of the set deletes a member of the mutex, then the mutex is subsumed.
action_deletes_it(M,Option1):-
	member(A1,Option1),
	operator(A1,_Precs1,Dels1,_Adds1),
	intersection(M,Dels1,X),X\=[].

% If the mutex is subsumed by another mutex, of less size.
action_subsumes_it(M,_A,Option10WithMutexes):-
	member(a(_A10,A10Mutexes,_), Option10WithMutexes),
	member(A10Mutex,A10Mutexes),
	subset12(A10Mutex,M),
	length(A10Mutex,L1),
	length(M,L2),
	L1<L2.
	

% Given an action A applicable at T1, this rule returns sets of propositions M
% that are mutexed with the action, i.e. its preconditions...
mutexed_propositions_with_action(A,M,T1):-
	operator(A,Precs,_Dels,Adds),
	m(M1,T,_),
	less(T1,T),		
	intersection(M1,Precs,X), X\=[],
	subtract(M1,Precs,M), M\=[],
%	intesect(M,Dels,[]),		% cannot intersect with Dels without intersecting with Precs
	intersection(M,Adds,[]).

delete_nobacktracking(A,Actions,Actions1):-
	delete(A,Actions,Actions1),!.

record_new_actions([],_T):-!.
record_new_actions([A|NewActions],T):-
	my_assert(action(A,T)),
	record_new_actions(NewActions,T).
	
record_new_facts([],_T):-!.
record_new_facts([P|NewFacts],T):-
	my_assert(dist(P,T)),
	record_new_facts(NewFacts,T).
		
my_assert(X):-
	assert(X),
	cwrite('Asserting:   '), cwrite(X), cnl.

my_retract(X):-
	retract(X),
	cwrite('Retracting:   '), cwrite(X), cnl.
	
achieved([],_T):-!.
achieved([P|Precs],T):-
	dist(P,T1),			% SOS: No cut '!' should be placed here!
	less_equal(T1,T),
	achieved(Precs,T).

compatible_propositions(M,T):-
	m(M1,T1,_),
	less(T,T1),
	subset12(M1,M),
	!,
	fail.
/*compatible_propositions(M,T):-
	sort(M,MSorted),
	subset(M1,MSorted),	
	m(M1,T1,_),
	less(T,T1),
	!,
	fail.*/
compatible_propositions(_S,_T).
	
applicable(A,T):-
	operator(A,Precs,_Dels,_Adds),
	achieved(Precs,T),
	compatible_propositions(Precs,T).

new_applicable(A,T):-
	operator(A,Precs,_Dels,_Adds),
	not action(A,_),
	achieved(Precs,T),
	compatible_propositions(Precs,T).
	
% This procedure checks all the cases a set
% of actions is mutexed...
% Case A: Two actions of the set are eternally mutexes
mutexed_actions(Actions,_T1):-
	member(A1,Actions),
	member(A2,Actions),
	A1\=A2,
	operator(A1,_Precs1,Dels1,_Adds1),
	operator(A2,Precs2,_Dels2,_Adds2),
	intersection(Dels1,Precs2,X),
	X\=[],
	!.
% Case B: Similar to Case A
mutexed_actions(Actions,_T1):-
	member(A1,Actions),
	member(A2,Actions),
	A1\=A2,
	operator(A1,_Precs1,Dels1,_Adds1),
	operator(A2,_Precs2,_Dels2,Adds2),
	intersection(Dels1,Adds2,X),
	X\=[],
	!.
% Case C: Similar to Case A
mutexed_actions(Actions,_T1):-
	member(A1,Actions),
	member(A2,Actions),
	A1\=A2,
	operator(A1,_Precs1,_Dels1,Adds1),
	operator(A2,_Precs2,_Dels2,Adds2),
	intersection(Adds1,Adds2,X),
	X\=[],
	!.
% Case D: A subset of the actions is mutexed due to their preconditions
/*
mutexed_actions(Actions,T1):-
	union_precs(Actions,[],UPrecs),
	sort(UPrecs,UPrecsSorted),
	subset(P,UPrecsSorted),
	m(P,T,_),
	less(T1,T),
	!.
*/
mutexed_actions(Actions,T1):-
	m(P,T,_),
	less(T1,T),
	union_precs(Actions,[],UPrecs),
	subset12(P,UPrecs),
	!.

	
union_precs([],UPrecs,UPrecs):-!.
union_precs([A|Actions],U,UPrecs):-
	operator(A,Precs,_Dels,_Adds),
	union(U,Precs,U1),
	union_precs(Actions,U1,UPrecs).


	
less_equal(_,inf):-!.
less_equal(inf,_):-!,fail.
less_equal(T1,T):-T1=<T.
	
less(T,inf):-T\=inf, !.
less(T1,T2):-T1\=inf, T2\=inf, T1<T2.

find_new_achievements(NewActions,NewFacts,T):-
	findall(A,new_applicable(A,T),NewActions),
	find_new_facts(NewActions,[],NewFacts).
	
find_new_facts([],NewFacts,NewFacts):-!.
find_new_facts([A|Actions],Facts,NewFacts):-
	operator(A,_Precs,_Dels,Adds),
	find_new_facts2(Adds,Facts2),
	union(Facts,Facts2,Facts3),
	find_new_facts(Actions,Facts3,NewFacts).
	
find_new_facts2([],[]):-!.
find_new_facts2([P|Adds],[P|Facts]):-
	not dist(P,_),
	!,
	find_new_facts2(Adds,Facts).
find_new_facts2([_P|Adds],Facts):-
	find_new_facts2(Adds,Facts).
	
subset12(A,B):-
	sort(A,SortedA),
	sort(B,SortedB),
	subset(SortedA,SortedB).
	
subset2(A,B):-
	sort(B,SortedB),
	subset(A,SortedB).
	
small_to_large_subsets(Subsets,OrderedSubsets):-
	enhande_subsets(Subsets,EnhancedSubsets),
	sort(EnhancedSubsets,OrderedEnhancedSubsets),
	enhande_subsets(OrderedSubsets,OrderedEnhancedSubsets).

large_to_small_subsets(Subsets,OrderedSubsets):-
	enhande_subsets(Subsets,EnhancedSubsets),
	sort(0,>,EnhancedSubsets,OrderedEnhancedSubsets),
	enhande_subsets(OrderedSubsets,OrderedEnhancedSubsets).

enhande_subsets([],[]):-!.
enhande_subsets([S|Subsets],[s(N,S)|EnhancedSubsets]):-
	length(S,N),
	enhande_subsets(Subsets,EnhancedSubsets).
	
	
display_list([]):-!.
display_list([H|T]):-cwrite(H), cwrite(", "),display_list(T).

display_list_of_lists([]):-!.
display_list_of_lists([L|T]):-cwrite("["), display_list(L),cwrite("]"),cnl,display_list_of_lists(T).


break_point(42):-
	!,
	raise_breakpoint.
	
break_point(_).

raise_breakpoint.

% Some of the broken mutexes cannot break simultaneously...
find_mutexes_between_broken_mutexes(BrokenMutexes,T):-
		counter_zero,	
		generate_process_mutex_subsets([], BrokenMutexes,T),
		counter(X),
		write("Mutex subsets tested: "), write(X),nl.

% This procedure generates subsets of broken mutexes and process them,
% i.e., tests whether they can break simultaneously
generate_process_mutex_subsets(_BrokenMutexes,[],_T):-!.
generate_process_mutex_subsets(TestedMutexes,[S|NewMutexes],T):-
	generate_process_mutex_subsets(TestedMutexes,NewMutexes,T),
	serialize_mutexes([S|TestedMutexes],[],Ss),
	process_mutex_subset([S|TestedMutexes],Ss,T,Result),
	(
		Result=ok, !,
		generate_process_mutex_subsets([S|TestedMutexes],NewMutexes,T)
	;
		Result=nil
	).
	
% Given a set of mutexes that can break individually at T, check
% whether they can break together...
process_mutex_subset([],_,_T,ok):-!.
process_mutex_subset(_Subset,Ss,_T,nil):-
	m(S1,inf,_),
	subset(S1,Ss),	% check for the case the set of mutexes cannot break together
	!,
	increase_counter.
process_mutex_subset(_Subset,Ss,_T,nil):-
	length(Ss,L),
	max_order(MaxOrder),
	less(MaxOrder,L),
%	write('FAIL: '), write(Subset), nl,
	!,
	increase_counter.
process_mutex_subset(Subset,Ss,T,Result):-
		increase_counter,
	%	counter(X),
	%	break_point(X),
	%	nl, write("Current subsets : "),write(X),nl,
	%	display_list(Subset),nl,
		
		findall(Option,mutex_achievement_option(Subset,Ss,Option,T),Options),
		(
			Options=[],		% No way to break the mutexes together
			!,
			Result=nil,
			new_mutex(Ss,inf,T)
		;
			Options\=[],	% At least one way to break the mutexes together has been found
			Result=ok,
	%		write("Full list of Options:"),nl,
	
	%		display_list_of_lists(Options),
			reduce_options(Options,Options,ReducedOptions),
	%		ReducedOptions=Options,
	%		write("Reduced list of Options:"),nl,
	%		display_list_of_lists(ReducedOptions),		
			process_options(Ss,ReducedOptions,T)
		).
	
serialize_mutexes([],Ss1,Ss):-sort(Ss1,Ss),!.
serialize_mutexes([s(S,_Actions)|Subset],Ss0,Ss):-
	union(S,Ss0,Ss1),
	serialize_mutexes(Subset,Ss1,Ss).

	 
% Find all the alternative ways to break a set of 
% broken mutexes simultaneously. Add new actions
% whenever possible.
mutex_achievement_option(Subset,Ss,Option,T):-
	break_all_mutexes([],Subset,Ss,[],Option1,T),	% Option1 is just a list of actions
	add_new_actions(Option1,Option,T,Ss).		% Option is an enhanced list of actions, i.e. each
												% action is accompanied with a set of mutexes


% From a list of broken mutexes, accompanied by sets of alternative
% actions than can break them, select a set of compatible actions that
% can break the set of broken mutexes simultaneously
break_all_mutexes(_Subset0,[],_Ss,Option1,Option1,_T):-!.		
break_all_mutexes(Subset0,[s(_S,Actions)|Subset],Ss,Option0,Option1,T):-
	member(A,Actions), 
%	not existing_in_previous_mutexes(A,Subset0),	% Wrong solutions are returned by this condition...
													% Imagine that a mutex can break with A or B and another
													% only with A. In this case, the opportunity B,A will never appear,
													% i.e., we will never be able to break the first mutex using B !!!
	operator(A,_Precs,Dels,Adds),
	intersection(Dels,Ss,[]),
	(
		member(A,Option0),
		break_all_mutexes([s(_S|Actions)|Subset0],Subset,Ss,Option0,Option1,T)		
		;
		not member(A,Option0),
		T1 is T-1,
		not mutexed_actions([A|Option0],T1),
		remove_covered_mutexes(Adds,Subset,Subset1),
%		Subset1=Subset,
		break_all_mutexes([s(_S|Actions)|Subset0],Subset1,Ss,[A|Option0],Option1,T)
	).
	

existing_in_previous_mutexes(_A,[]):-!, fail.
existing_in_previous_mutexes(A,[s(_S|Actions)|_Subset0]):-
	member(A,Actions),
	!.
%	write(bingo),nl.
existing_in_previous_mutexes(A,[_|Subset0]):-
	existing_in_previous_mutexes(A,Subset0).
	
	
remove_covered_mutexes(_Adds,[],[]):-!.
remove_covered_mutexes(Adds,[s(S,Actions)|Subset],[s(S,Actions)|Subset1]):-
	intersection(Adds,S,[]),
	!,
	remove_covered_mutexes(Adds,Subset,Subset1).
remove_covered_mutexes(Adds,[_|Subset],Subset1):-
	!,
	remove_covered_mutexes(Adds,Subset,Subset1).
