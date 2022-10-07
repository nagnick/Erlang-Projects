
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

gridLink(_,_,_,0,_,_)->%DONE
  ok;
gridLink(Grid,Rows,Columns,I,Imperfect,Gossip)-> % creates a list of neighbor actors for each actor in grid and sends it to actor%DONE
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
  if
    Gossip == true->
      Actor ! [Gossip, self()] ++ TopRow ++ Left ++ Right ++ BottomRow ++ Random; %list[algotype,supervisorPID,NeighborPIDs];
    true -> % push sum give algo info as well which is actor number I
      Actor ! [Gossip, I, self()] ++ TopRow ++ Left ++ Right ++ BottomRow ++ Random %list[algotype,algoinfo I,supervisorPID,NeighborPIDs]
  end,
  gridLink(Grid,Rows,Columns,I-1,Imperfect,Gossip).

fullLink(1,List,Gossip)-> %give every actor a list of all actors first element is the supervisor PID%DONE
  Actor = lists:nth(1,List),
  if
    Gossip == true->
      Actor ! [Gossip, self()] ++ List; %list[algotype,supervisorPID,NeighborPIDs];
    true -> % push sum give algo info as well which is actor number I
      Actor ! [Gossip, 1] ++ [self()| List]  %list[algotype,algoinfo I,supervisorPID,NeighborPIDs]
  end,
  ok;
fullLink(I,List,Gossip)->%DONE
  Actor = lists:nth(I,List),
  if
    Gossip == true->
      Actor ! [Gossip, self()] ++ List; %list[algotype,supervisorPID,NeighborPIDs];
    true -> % push sum give algo info as well which is actor number I
      Actor ! [Gossip, I] ++ [self()| List]  %list[algotype,algoinfo I,supervisorPID,NeighborPIDs]
  end,
  fullLink(I-1,List,Gossip).

linkInLine(1,List,Gossip)->%DONE
  Actor = lists:nth(1,List), % send second item in list to first item in list
  if
    Gossip == true->
      Actor ! [Gossip, self(),lists:nth(2,List)]; %list[algotype,supervisorPID,NeighborPIDs];
    true -> % push sum give algo info as well which is actor number I
      Actor ! [Gossip, 1] ++ [self()| lists:nth(2,List)]  %list[algotype,algoinfo I,supervisorPID,NeighborPIDs]
  end,
  ok;
linkInLine(I,List,Gossip)->%DONE
  if
    I == length(List) -> % end of list give second to last pid
      Actor = lists:nth(I,List),
      if
        Gossip == true->
          Actor ! [Gossip, self(),lists:nth(I -1,List)]; %list[algotype,supervisorPID,NeighborPIDs];
        true -> % push sum give algo info as well which is actor number I
          Actor ! [Gossip, I] ++ [self()| lists:nth(I -1,List)]  %list[algotype,algoinfo I,supervisorPID,NeighborPIDs]
      end;
    true ->
      Actor = lists:nth(I,List),
      Neighbors = [lists:nth(I -1,List), lists:nth(I +1,List)],
      if
        Gossip == true->
          Actor ! [Gossip, self()] ++ Neighbors; %list[algotype,supervisorPID,NeighborPIDs];
        true -> % push sum give algo info as well which is actor number I
          Actor ! [Gossip, I] ++ [self()| Neighbors]  %list[algotype,algoinfo I,supervisorPID,NeighborPIDs]
      end
  end,
  linkInLine(I -1,List,Gossip).

superVisor(NumberOfActors,'2D', Algo)-> %DONE
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
  gridLink(Grid,W,W,W*W,false,Gossip),
  if %start algos
  Gossip == true->
    lists:nth(rand:uniform(W*W),Actors) ! "rumor";
  true ->
    lists:nth(rand:uniform(W*W),Actors) ! start
  end;
superVisor(NumberOfActors,'imp2D', Algo)->%DONE
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
  gridLink(Grid,W,W,W*W,true,Gossip),% true to add random actor to neighbor list
  if %start algos
    Gossip == true->
      lists:nth(rand:uniform(W*W),Actors) ! "rumor";
    true ->
      lists:nth(rand:uniform(W*W),Actors) ! start
  end;
superVisor(NumberOfActors, full, Algo)->%DONE
  if
    Algo == gossip ->
      Gossip = true;
    true ->
      Gossip = false
  end,
  Actors = spawnMultipleActors(NumberOfActors),
  fullLink(NumberOfActors,Actors,Gossip),
  if %start algos
    Gossip == true->
      lists:nth(rand:uniform(NumberOfActors),Actors) ! "rumor";
    true ->
      lists:nth(rand:uniform(NumberOfActors),Actors) ! start
  end;
superVisor(NumberOfActors, line, Algo)->%DONE
  if
    Algo == gossip ->
      Gossip = true;
    true ->
      Gossip = false
  end,
  Actors = spawnMultipleActors(NumberOfActors),
  linkInLine(NumberOfActors,Actors,Gossip),
  if %start algos
    Gossip == true->
      lists:nth(rand:uniform(NumberOfActors),Actors) ! "rumor";
    true ->
      lists:nth(rand:uniform(NumberOfActors),Actors) ! start
  end.

actor()-> %% work in progress
  receive
    List->
      Gossip = hd(List),
      if
      Gossip == true ->
        PIDs = tl(List),
        gossipActor(hd(PIDs),tl(PIDs));
      true -> % pushsum
        Tail = tl(List),
        ActorNum = hd(Tail),
        PIDs = tl(Tail),
        pushSumActor(hd(PIDs),ActorNum,tl(PIDs))
      end
end.

gossipActor(Client, ListOfNeighbors)->%work in progress
  io:format("Client~p~n",[Client]),
  io:format("~w~n",[ListOfNeighbors]).
pushSumActor(Client,ActorNum, ListOfNeighbors)->%work in progress
  io:format("Client~p~n",[Client]),
  io:format("ActorNum~p~n",[ActorNum]),
  io:format("~w~n",[ListOfNeighbors]).

spawnMultipleActors(NumberOfActorsToSpawn)->
  spawnMultipleActors(NumberOfActorsToSpawn,[]).
spawnMultipleActors(0,ListOfPid)->
  io:format("~p~n",[ListOfPid]),
  ListOfPid;
spawnMultipleActors(NumberOfActorsToSpawn,ListOfPid)->
  spawnMultipleActors(NumberOfActorsToSpawn-1,[spawn(project2,actor,[]) | ListOfPid]).