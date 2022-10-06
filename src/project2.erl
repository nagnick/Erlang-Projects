
-module(project2).
-import(rand,[uniform/1]).
-export([actor/0,superVisor/3]).
makeGrid(N,M,List)-> % assumes N*M = number of elements in List true with supervisor creating list %DONE
  makeGrid(N,M,M,N,List,[],[]).

makeGrid(0,0,_,_,_,Grid,Row)->%DONE
  lists:append(Grid,[Row]);
makeGrid(N,0,NumOfCol,NumOfRow,List,Grid,Row)->%DONE
  if
    Grid == [] ->
      NewGrid = [Row];
    true ->
      NewGrid = lists:append(Grid,[Row])
  end,
  makeGrid(N-1,NumOfCol,NumOfCol,NumOfRow,List,NewGrid,[]);
makeGrid(N,M,NumOfCol,NumOfRow,List,Grid,Row)->%DONE
  if
    length(List) < 2 ->
      makeGrid(0,M-1,NumOfCol,NumOfRow,[],Grid,Row++[hd(List)]);
    true ->
      makeGrid(N,M-1,NumOfCol,NumOfRow,tl(List),Grid,Row++[hd(List)])
  end.

getTopNeighbors(Grid,ActorRow,ActorCol,NumCol)->%DONE
  if
    ActorRow == 1 -> % no top row
      [];
    true ->
      TopRow = lists:nth(ActorRow-1,Grid),
      if
        ActorCol == NumCol -> % no Right actor
          Right = [];
        true ->
          Right = [lists:nth(ActorCol+1,TopRow)]
      end,
      if
        ActorCol == 1-> % no Left actor
          Left = [];
        true ->
          Left = [lists:nth(ActorCol-1,TopRow)]
      end,
      Right ++ [lists:nth(ActorCol,TopRow)] ++ Left
  end.

getBottomNeighbors(Grid,ActorRow,ActorCol,NumRow, NumCol)->%DONE
  if
    ActorRow == NumRow -> % no bottom row
      [];
    true ->
      BottomRow = lists:nth(ActorRow+1,Grid),
      if
        ActorCol == NumCol -> % no Right actor
          Right = [];
        true ->
          Right = [lists:nth(ActorCol+1,BottomRow)]
      end,
      if
        ActorCol == 1-> % no Left actor
          Left = [];
        true ->
          Left = [lists:nth(ActorCol-1,BottomRow)]
      end,
      Right ++ [lists:nth(ActorCol,BottomRow)] ++ Left
  end.

gridLink(_,_,_,0,_,_)->%work in progress
  ok;
gridLink(Grid,Rows,Columns,I,Imperfect,Gossip)-> % creates a list of neighbor actors for each actor in grid and sends it to actor%work in progress
  Temp1 = (I div Columns), %calculate actor index in 2d grid
  if Temp1 == 0->
    ActorRowNumber = Rows; % 0 remapped to end
    true ->
      ActorRowNumber = Temp1
      end,
  Temp2 = (I rem Columns),
  if Temp2 == 0 ->
    ActorColNumber = Columns; % 0 remapped to end
    true ->
      ActorColNumber = Temp2
      end,
  if
    Imperfect ->
      Random = [lists:nth(rand:uniform(Columns),lists:nth(rand:uniform(Rows),Grid))];
    true ->
      Random = []
  end,
  ActorRow = lists:nth(ActorRowNumber,Grid), % plus one no zero index
  Actor = lists:nth(ActorColNumber,ActorRow), % plus one no zero index
  TopRow = getTopNeighbors(Grid,ActorRowNumber,ActorColNumber,Columns),
  BottomRow = getBottomNeighbors(Grid,ActorRowNumber,ActorColNumber,Rows,Columns),
  if
    ActorColNumber == 1 -> % no left
      Left = [];
    true ->
      Left = [lists:nth(ActorColNumber -1,ActorRow)]
  end,
  if
    ActorColNumber == Columns -> % no right
      Right = [];
    true ->
      Right = [lists:nth(ActorColNumber+1,ActorRow)]
  end,
  Actor ! [Gossip| self()] ++ TopRow ++ Left ++ Right ++ BottomRow ++ Random, %list[algotype,algoinfo,supervisorPID,NeighborPIDs]
  gridLink(Grid,Rows,Columns,I-1,Imperfect,Gossip).

fullLink(1,List)-> %give every actor a list of all actors first element is the supervisor PID%work in progress
  PID = lists:nth(1,List),
  PID ! [self()| List];
fullLink(N,List)->%work in progress
  PID = lists:nth(N,List),
  PID ! [self() | List],
  fullLink(N-1,List).

linkInLine(1,List)->%work in progress
  lists:nth(1,List) ! [self() | lists:nth(2,List)], % first of list
  io:format("DONE~n");
linkInLine(N,List)->%work in progress
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

superVisor(NumberOfActors,'2D', Algo)-> %work in progress
  %round up to get a square like doc says though square not required by functions below
  if
    Algo == gossip ->
      Gossip = true;
    true ->
      Gossip = false
  end,
  W = round(math:ceil(math:sqrt(NumberOfActors))),
  Actors = spawnMultipleActors(W*W),
  Grid = makeGrid(W,W,Actors),
  gridLink(Grid,3,3,NumberOfActors,false,Gossip);
superVisor(NumberOfActors,'imp2D', Algo)->%work in progress
  %round up to get a square like doc says though square not required by functions below
  if
    Algo == gossip ->
      Gossip = true;
    true ->
      Gossip = false
  end,
  W = round(math:ceil(math:sqrt(NumberOfActors))),
  Actors = spawnMultipleActors(W*W),
  Grid = makeGrid(W,W,Actors),
  gridLink(Grid,3,3,NumberOfActors,true,Gossip);
superVisor(NumberOfActors, full, Algo)->%work in progress
  if
    Algo == gossip ->
      Gossip = true;
    true ->
      Gossip = false
  end,
  Actors = spawnMultipleActors(NumberOfActors),
  fullLink(NumberOfActors,Actors);
superVisor(NumberOfActors, line, Algo)->%work in progress
  if
    Algo == gossip ->
      Gossip = true;
    true ->
      Gossip = false
  end,
  Actors = spawnMultipleActors(NumberOfActors),
  linkInLine(NumberOfActors,Actors).

actor()-> %% work in progress
  receive
    List->
      Gossip = hd(List),
      PIDs = tl(List),
      if
      Gossip == true ->
        gossipActor(hd(PIDs),tl(PIDs));
      true ->
        pushSumActor(hd(PIDs),tl(PIDs))
      end
end.

gossipActor(Client, ListOfNeighbors)->%work in progress
  io:format("Client~p~n",[Client]),
  io:format("~w~n",[ListOfNeighbors]).
pushSumActor(Client,ListOfNeighbors)->%work in progress
  io:format("Client~p~n",[Client]),
  io:format("~w~n",[ListOfNeighbors]).

spawnMultipleActors(NumberOfActorsToSpawn)->
  spawnMultipleActors(NumberOfActorsToSpawn,[]).
spawnMultipleActors(0,ListOfPid)->
  io:format("~p~n",[ListOfPid]),
  ListOfPid;
spawnMultipleActors(NumberOfActorsToSpawn,ListOfPid)->
  spawnMultipleActors(NumberOfActorsToSpawn-1,[spawn(project2,actor,[]) | ListOfPid]).