
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
  PIDS = List -- [Actor],% remove itself from neighbors
  if
    Gossip == true->
      Actor ! [Gossip, self()] ++ PIDS; %list[algotype,supervisorPID,NeighborPIDs];
    true -> % push sum give algo info as well which is actor number I
      Actor ! [Gossip, 1] ++ [self()| PIDS]  %list[algotype,algoinfo I,supervisorPID,NeighborPIDs]
  end,
  ok;
fullLink(I,List,Gossip)->%DONE
  Actor = lists:nth(I,List),
  PIDS = List -- [Actor], % remove itself from neighbors
  if
    Gossip == true->
      Actor ! [Gossip, self()] ++ PIDS; %list[algotype,supervisorPID,NeighborPIDs];
    true -> % push sum give algo info as well which is actor number I
      Actor ! [Gossip, I] ++ [self()| PIDS]  %list[algotype,algoinfo I,supervisorPID,NeighborPIDs]
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
    Algo == pushSum ->
      Gossip = false;
    true ->
      Gossip = true,% just for compiler warning doesnt get used
      throw("Not a valid Algo enter gossip or pushSum")
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
  end,
  ok;
superVisor(NumberOfActors,'imp2D', Algo)->%DONE
  %round up to get a square like doc says though square not required by functions below
  if
    Algo == gossip ->
      Gossip = true;
    Algo == pushSum ->
      Gossip = false;
    true ->
      Gossip = true,% just for compiler warning doesnt get used
      throw("Not a valid Algo enter gossip or pushSum")
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
  end,
  ok;
superVisor(NumberOfActors, full, Algo)->%DONE
  if
    Algo == gossip ->
      Gossip = true;
    Algo == pushSum ->
      Gossip = false;
    true ->
      Gossip = true,% just for compiler warning doesnt get used
      throw("Not a valid Algo enter gossip or pushSum")
  end,
  Actors = spawnMultipleActors(NumberOfActors),
  fullLink(NumberOfActors,Actors,Gossip),
  if %start algos
    Gossip == true->
      lists:nth(rand:uniform(NumberOfActors),Actors) ! "rumor";
    true ->
      lists:nth(rand:uniform(NumberOfActors),Actors) ! start
  end,
  ok;
superVisor(NumberOfActors, line, Algo)->%DONE
  if
    Algo == gossip ->
      Gossip = true;
    Algo == pushSum ->
      Gossip = false;
    true ->
      Gossip = true,% just for compiler warning doesnt get used
      throw("Not a valid Algo enter gossip or pushSum")
  end,
  Actors = spawnMultipleActors(NumberOfActors),
  linkInLine(NumberOfActors,Actors,Gossip),
  if %start algos
    Gossip == true->
      lists:nth(rand:uniform(NumberOfActors),Actors) ! "rumor";
    true ->
      lists:nth(rand:uniform(NumberOfActors),Actors) ! start
  end,
  ok.

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

gossipActor(Client, ListOfNeighbors)->%DONE
  io:format("Client~p~n",[Client]),
  io:format("~w~n",[ListOfNeighbors]),
  gossipActor(Client,ListOfNeighbors,10).% stop after sharing rumor 10 times

gossipActor(_,_,0)->
  ok;
gossipActor(Client,ListOfNeighbors,N)->
  receive
    Rumor ->
      lists:nth(rand:uniform(length(ListOfNeighbors)),ListOfNeighbors) ! Rumor
  end,
  gossipActor(Client,ListOfNeighbors,N-1).

pushSumActor(Client,S, ListOfNeighbors) ->%work in progress
  io:format("Client~p~n",[Client]),
  io:format("ActorNum~p~n",[S]),
  io:format("~w~n",[ListOfNeighbors]),
  pushSumActor(Client,S,1,ListOfNeighbors,3,S,math:pow(10,-10)).% 1 = w ; 3 is max number of rounds without change in ratio(last arg S)

pushSumActor(_,_,_,_,_,0,_)->
  ok;
pushSumActor(Client,S,W,ListOfNeighbors,Round,LastRatio,L)->
  receive
    {MS,MW}->
      SS = MS+S,
      SW = MW +W,
      CurrentRatio = (SS/SW),
      lists:nth(rand:uniform(length(ListOfNeighbors)),ListOfNeighbors) ! {SS/2,SW/2}, % send half
      if
        abs(CurrentRatio - LastRatio)  > L ->
          pushSumActor(Client,SS/2,SW/2,ListOfNeighbors,3,CurrentRatio,L); % keep half
        true -> % ratio did not change by at min L so down a round
          pushSumActor(Client,SS/2,SW/2,ListOfNeighbors,Round-1,CurrentRatio,L)
      end;
    start -> % sent by supervisor to start pushsum
      lists:nth(rand:uniform(length(ListOfNeighbors)),ListOfNeighbors) ! {S/2,W/2},
      pushSumActor(Client,S/2,W/2,ListOfNeighbors,3,LastRatio,L)
  end,
  ok.

spawnMultipleActors(NumberOfActorsToSpawn)->%DONE
  spawnMultipleActors(NumberOfActorsToSpawn,[]).
spawnMultipleActors(0,ListOfPid)->
  io:format("~p~n",[ListOfPid]),
  ListOfPid;
spawnMultipleActors(NumberOfActorsToSpawn,ListOfPid)->
  spawnMultipleActors(NumberOfActorsToSpawn-1,[spawn(project2,actor,[]) | ListOfPid]).