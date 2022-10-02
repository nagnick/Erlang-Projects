
-module(project2).

-export([gossipActor/0,superVisor/0,spawnMultipleActors/1, fullLink/2,makeGrid/3]).
makeGrid(0,0,_,_,_,Grid,Row)->
  lists:append(Grid,[Row]);
makeGrid(N,0,NumOfCol,NumOfRow,List,Grid,Row)->
  if
    Grid == [] ->
    NewGrid = [Row];
    true ->
      NewGrid = lists:append(Grid,[Row])
  end,
  makeGrid(N-1,NumOfCol,NumOfCol,NumOfRow,List,NewGrid,[]);
makeGrid(N,M,NumOfCol,NumOfRow,List,Grid,Row)->
  if
    length(List) < 2 ->
      makeGrid(0,M-1,NumOfCol,NumOfRow,[],Grid,Row++[hd(List)]);
    true ->
      makeGrid(N,M-1,NumOfCol,NumOfRow,tl(List),Grid,Row++[hd(List)])
  end.
makeGrid(N,M,List)-> % assumes N*M = number of elements in List
  makeGrid(N,M,M,N,List,[],[]).

%%gridLink(N,M,Grid)-> % fix border actors to only have their actual neighbors
%%  Row = lists:nth(N,Grid),
%%  PID = lists:nth(M,Row),
%%  TopRow = lists:nth(N-1,Grid),
%%  Top3 = [lists:nth(M-1,TopRow)|lists:nth(M,TopRow)] ++ [lists:nth(M+1,TopRow)],
%%  BottomRow = lists:nth(N+1,Grid),
%%  Bottom3 = [lists:nth(M-1,BottomRow)|lists:nth(M,BottomRow)] ++ [lists:nth(M+1,BottomRow)],
%%  Sides = [lists:nth(M-1,Row)|lists:nth(M+1,Row)],
%%  PID ! Top3++Bottom3 ++ Sides.

fullLink(1,List)-> %give every actor a list of all actors first element is the supervisor PID
  PID = lists:nth(1,List),
  PID ! [self()| List];
fullLink(N,List)->
  PID = lists:nth(N,List),
  PID ! [self() | List],
  fullLink(N-1,List).

linkInLine(1,List)->
  lists:nth(1,List) ! [self() | lists:nth(2,List)], % first of list
  io:format("DONE~n");
linkInLine(N,List)->
  if
    N == length(List) -> % end of list
      PID = lists:nth(N,List),
      PID ! [self()| lists:nth(N -1,List)];
    true ->
      PID = lists:nth(N,List),
      Neighbors = [lists:nth(N -1,List)| lists:nth(N +1,List)],
      PID ! [self()] ++ Neighbors
  end,
  linkInLine(N -1,List).

superVisor()-> %% work in progress
  Actors = spawnMultipleActors(8),
  messageStructure(8,Actors,line).

messageStructure(NumberOfActors,Actors, line)->
  linkInLine(NumberOfActors,Actors).

gossipActor()-> %% work in progress
  receive
    ListOfNeighbors->
      gossipActor(hd(ListOfNeighbors),tl(ListOfNeighbors))
  end.
gossipActor(Client, ListOfNeighbors)->
  io:format("Client~p~n",[Client]),
  io:format("~p~n",[ListOfNeighbors]).

spawnMultipleActors(NumberOfActorsToSpawn)->
  spawnMultipleActors(NumberOfActorsToSpawn,[]).
spawnMultipleActors(0,ListOfPid)->
  io:format("~p~n",[ListOfPid]),
  ListOfPid;
spawnMultipleActors(NumberOfActorsToSpawn,ListOfPid)->
  spawnMultipleActors(NumberOfActorsToSpawn-1,[spawn(project2,gossipActor,[]) | ListOfPid]).