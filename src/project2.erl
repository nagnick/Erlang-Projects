
-module(project2).

-export([gossipActor/0,superVisor/0,spawnMultipleActors/1, fullLink/2]).

fullLink(1,List)-> %give every actor a list of all actors first element is the supervisor PID
  PID = lists:nth(1,List),
  PID ! [self()| List];
fullLink(NumberInList,List)->
  PID = lists:nth(NumberInList,List),
  PID ! [self() | List],
  fullLink(NumberInList-1,List).

linkInLine(1,List)-> % give each actor its neighbor to the right & supervisor PID, last actor get only supervisor PID
  hd(List)! [self()],
  io:format("DONE~n");
linkInLine(NumberInList,List)->
  PID = hd(List),
  Rest = tl(List),
  io:format("~p~n",[PID]),
  PID ! [self()| hd(Rest)],
  linkInLine(NumberInList-1,Rest).

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