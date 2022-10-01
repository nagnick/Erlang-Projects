
-module(project2).

-export([gossipActor/0,superVisor/0,spawnMultipleActors/1, fullLink/2]).

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