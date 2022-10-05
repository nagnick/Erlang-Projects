
-module(project2).

-export([gossipActor/0,superVisor/0,spawnMultipleActors/1, fullLink/2,makeGrid/3, gridLink/4]).
makeGrid(N,M,List)-> % assumes N*M = number of elements in List
  makeGrid(N,M,M,N,List,[],[]).

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

getTopNeighbors(Grid,ActorRow,ActorCol,NumCol)->
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

getBottomNeighbors(Grid,ActorRow,ActorCol,NumRow, NumCol)->
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

gridLink(_,_,_,0)->
  ok;
gridLink(Grid,Rows,Columns,I)-> % creates a list of neighbor actors for each actor in grid and sends it to actor
  Temp1 = (I div Columns), %fix this indexing not proper
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
  Actor ! [self()] ++ TopRow ++ Left ++ Right ++ BottomRow,
  gridLink(Grid,Rows,Columns,I-1).

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
  Actors = spawnMultipleActors(4),
  messageStructure(4,Actors,'3DGrid').

messageStructure(NumberOfActors,Actors,'3DGrid')->
  Grid = makeGrid(2,2,Actors),
  io:format("~w",[Grid]),
  gridLink(Grid,2,2,NumberOfActors);
messageStructure(NumberOfActors,Actors, line)->
  linkInLine(NumberOfActors,Actors).

gossipActor()-> %% work in progress
  receive
    ListOfNeighbors->
      gossipActor(hd(ListOfNeighbors),tl(ListOfNeighbors))
  end.
gossipActor(Client, ListOfNeighbors)->
  io:format("Client~p~n",[Client]),
  io:format("~w~n",[ListOfNeighbors]).

spawnMultipleActors(NumberOfActorsToSpawn)->
  spawnMultipleActors(NumberOfActorsToSpawn,[]).
spawnMultipleActors(0,ListOfPid)->
  io:format("~p~n",[ListOfPid]),
  ListOfPid;
spawnMultipleActors(NumberOfActorsToSpawn,ListOfPid)->
  spawnMultipleActors(NumberOfActorsToSpawn-1,[spawn(project2,gossipActor,[]) | ListOfPid]).