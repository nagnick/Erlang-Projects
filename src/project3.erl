-module(project3).
-author("nicol").
-export([superVisor/1,actor/0]).

actor()-> %starter actor decides which type of actor to run
  receive
    List->
      Gossip = hd(List),
      if
        Gossip == true ->
          PIDs = tl(List);
        true -> % pushsum
          Tail = tl(List),
          ActorNum = hd(Tail),
          PIDs = tl(Tail)
      end
  end.

superVisor(NumberOfActors)->
  ListOfActors = spawnMultipleActors(NumberOfActors,[]),
  actorKiller(ListOfActors).

actorKiller([])-> %Tell actors to kill themselves the swarm has converged
  ok;
actorKiller(ListOfActors)->
  exit(hd(ListOfActors),kill),
  actorKiller(tl(ListOfActors)).

spawnMultipleActors(0,ListOfPid)->
  ListOfPid;
spawnMultipleActors(NumberOfActorsToSpawn,ListOfPid)-> % got to broken actor spawn broken one
  spawnMultipleActors(NumberOfActorsToSpawn-1,[spawn(project3,actor,[]) | ListOfPid]).