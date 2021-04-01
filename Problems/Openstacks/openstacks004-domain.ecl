product(p1).
product(p2).
product(p3).
product(p4).

order(o1).
order(o2).
order(o3).
order(o4).

operator(open_new_stack(Open, NewOpen),
	[stacks_avail(Open)],
	[stacks_avail(Open)],
	[stacks_avail(NewOpen)]):-
	count(Open), count(NewOpen), next_count(Open,NewOpen).

	
operator(start_order(O, Avail,NewAvail),
	[waiting(O), stacks_avail(Avail)],
	[waiting(O), stacks_avail(Avail)],
	[started(O), stacks_avail(NewAvail)]):-
	order(O), count(Avail), count(NewAvail), next_count(NewAvail,Avail).


operator(make_product_p1,
	[not_made(p1), started(o2)],
	[not_made(p1)],
	[made(p1)]).

operator(make_product_p2,
	[not_made(p2), started(o1), started(o2)],
	[not_made(p2)],
	[made(p2)]).

operator(make_product_p3,
	[not_made(p3), started(o3), started(o4)],
	[not_made(p3)],
	[made(p3)]).

operator(make_product_p4,
	[not_made(p4), started(o4)],
	[not_made(p4)],
	[made(p4)]).

	
operator(ship_order_o1(Avail,NewAvail),
	[started(o1), made(p2),stacks_avail(Avail)],
	[started(o1), stacks_avail(Avail)],
	[shipped(o1), stacks_avail(NewAvail)]):-
	count(Avail), count(NewAvail), next_count(Avail, NewAvail).

operator(ship_order_o2(Avail,NewAvail),
	[started(o2), made(p1), made(p2),stacks_avail(Avail)],
	[started(o2), stacks_avail(Avail)],
	[shipped(o2), stacks_avail(NewAvail)]):-
	count(Avail), count(NewAvail), next_count(Avail, NewAvail).

operator(ship_order_o3(Avail,NewAvail),
	[started(o3), made(p3),stacks_avail(Avail)],
	[started(o3), stacks_avail(Avail)],
	[shipped(o3), stacks_avail(NewAvail)]):-
	count(Avail), count(NewAvail), next_count(Avail, NewAvail).

operator(ship_order_o4(Avail,NewAvail),
	[started(o4), made(p3), made(p4), stacks_avail(Avail)],
	[started(o4), stacks_avail(Avail)],
	[shipped(o4), stacks_avail(NewAvail)]):-
	count(Avail), count(NewAvail), next_count(Avail, NewAvail).



