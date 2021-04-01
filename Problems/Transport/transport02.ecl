location(  city_loc_1 ).
location(  city_loc_2 ).
location(  city_loc_3 ).
location(  city_loc_4 ).
location(  city_loc_5 ).
location(  city_loc_6 ).
vehicle(  truck_1).
vehicle(  truck_2).
package(  package_1 ).
package(  package_2 ).
package(  package_3 ).
capacity_number(  capacity_0 ).
capacity_number(  capacity_1 ).
capacity_number(  capacity_2 ).
capacity_number(  capacity_3 ).
capacity_number(  capacity_4 ).
capacity_predecessor(capacity_0, capacity_1).
capacity_predecessor(capacity_1, capacity_2).
capacity_predecessor(capacity_2, capacity_3).
capacity_predecessor(capacity_3, capacity_4).

road(city_loc_3, city_loc_1).
road(city_loc_1, city_loc_3).
road(city_loc_4, city_loc_1).
road(city_loc_1, city_loc_4).
road(city_loc_5, city_loc_1).
road(city_loc_1, city_loc_5).
road(city_loc_5, city_loc_4).
road(city_loc_4, city_loc_5).
road(city_loc_6, city_loc_2).
road(city_loc_2, city_loc_6).
road(city_loc_6, city_loc_3).
road(city_loc_3, city_loc_6).

initial([
at(package_1, city_loc_5),
at(package_2, city_loc_4),
at(package_3, city_loc_4),
at(truck_1, city_loc_2),
capacity(truck_1, capacity_4),
at(truck_2, city_loc_4),
capacity(truck_2, capacity_3)
]).


goal([
at(package_1, city_loc_4),
at(package_2, city_loc_2),
at(package_3, city_loc_6)
]).