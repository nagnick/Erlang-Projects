
-module(project2).

-export([gossipActor/0,superVisor/0,spawnMultipleActors/1]).

linkInLine(1,List)->
  hd(List)! [self()],
  io:format("DONE~n");
linkInLine(NumberInList,List)->
  PID = hd(List),
  Rest = tl(List),
  io:format("~p~n",[PID]),
  PID ! [self()| hd(Rest)],
  linkInLine(NumberInList-1,Rest).

superVisor()->
  Actors = spawnMultipleActors(8),
  messageStructure(8,Actors,line).

messageStructure(NumberOfActors,Actors, line)->
  linkInLine(NumberOfActors,Actors).

gossipActor()->
  receive
    ListOfNeighbors->
      gossipActor(ListOfNeighbors)
  end.
gossipActor(ListOfNeighbors)->
  io:format("~p",[ListOfNeighbors]).

spawnMultipleActors(NumberOfActorsToSpawn)->
  spawnMultipleActors(NumberOfActorsToSpawn,[]).
spawnMultipleActors(0,ListOfPid)->
  io:format("~p~n",[ListOfPid]),
  ListOfPid;
spawnMultipleActors(NumberOfActorsToSpawn,ListOfPid)->
  spawnMultipleActors(NumberOfActorsToSpawn-1,[spawn(project2,gossipActor,[]) | ListOfPid]).