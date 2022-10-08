
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
      Actor ! [Gossip, self() |PIDS]; %list[algotype,supervisorPID,NeighborPIDs];
    true -> % push sum give algo info as well which is actor number I
      Actor ! [Gossip, 1,self()| PIDS]  %list[algotype,algoinfo I,supervisorPID,NeighborPIDs]
  end,
  ok;
fullLink(I,List,Gossip)->%DONE
  Actor = lists:nth(I,List),
  PIDS = List -- [Actor], % remove itself from neighbors
  if
    Gossip == true->
      Actor ! [Gossip, self() | PIDS]; %list[algotype,supervisorPID,NeighborPIDs];
    true -> % push sum give algo info as well which is actor number I
      Actor ! [Gossip, I, self()| PIDS]  %list[algotype,algoinfo I,supervisorPID,NeighborPIDs]
  end,
  fullLink(I-1,List,Gossip).

linkInLine(1,List,Gossip)->%DONE
  Actor = lists:nth(1,List), % send second item in list to first item in list
  if
    Gossip == true->
      Actor ! [Gossip, self() ,lists:nth(2,List)]; %list[algotype,supervisorPID,NeighborPIDs];
    true -> % push sum give algo info as well which is actor number I
      Actor ! [Gossip, 1 ,self(),lists:nth(2,List)]  %list[algotype,algoinfo I,supervisorPID,NeighborPIDs]
  end,
  ok;
linkInLine(I,List,Gossip)->%DONE
  if
    I == length(List) -> % end of list give second to last pid
      Actor = lists:nth(I,List),
      if
        Gossip == true->
          Actor ! [Gossip,self(),lists:nth(I -1,List)]; %list[algotype,supervisorPID,NeighborPIDs];
        true -> % push sum give algo info as well which is actor number I
          Actor ! [Gossip, I,self(), lists:nth(I -1,List)]  %list[algotype,algoinfo I,supervisorPID,NeighborPIDs]
      end;
    true ->
      Actor = lists:nth(I,List),
      Neighbors = [lists:nth(I -1,List), lists:nth(I +1,List)],
      if
        Gossip == true->
          Actor ! [Gossip, self()| Neighbors]; %list[algotype,supervisorPID,NeighborPIDs];
        true -> % push sum give algo info as well which is actor number I
          Actor ! [Gossip, I,self()| Neighbors]  %list[algotype,algoinfo = I,supervisorPID,NeighborPIDs]
      end
  end,
  linkInLine(I -1,List,Gossip).

superVisor(NumberOfActors, Topology, Algo)->%DONE
  if
    Algo == gossip ->
      Gossip = true;
    Algo == pushSum ->
      Gossip = false;
    true ->
      Gossip = true,% just for compiler warning doesnt get used
      throw("Not a valid Algo enter gossip or pushSum")
  end,
  if % start topology building
    Topology == line->
      ActualNumOfActors = NumberOfActors,
      Actors = spawnMultipleActors(NumberOfActors),
      linkInLine(NumberOfActors,Actors,Gossip);
    Topology == full->
      ActualNumOfActors = NumberOfActors,
      Actors = spawnMultipleActors(NumberOfActors),
      fullLink(NumberOfActors,Actors,Gossip);
    Topology == imp2D->
      W = round(math:ceil(math:sqrt(NumberOfActors))),
      ActualNumOfActors = W*W,
      Actors = spawnMultipleActors(ActualNumOfActors),
      Grid = makeGrid(W,W,Actors),
      gridLink(Grid,W,W,ActualNumOfActors,true,Gossip);% true to add random actor to neighbor list
    Topology == '2D' ->
      W = round(math:ceil(math:sqrt(NumberOfActors))),
      ActualNumOfActors = W*W,
      Actors = spawnMultipleActors(ActualNumOfActors),
      Grid = makeGrid(W,W,Actors),
      gridLink(Grid,W,W,ActualNumOfActors,false,Gossip);
    true ->
      ActualNumOfActors = NumberOfActors, % just for compiler safety
      Actors = [],% just for compiler safety
      throw("Not a valid Topology. Valid options: [line,full,'2D',imp2D")
  end,
  if %start algos
    Gossip == true->
      lists:nth(rand:uniform(ActualNumOfActors),Actors) ! "rumor", % tell random actor rumor to start process
      gossipConvergenceCheck(Actors,erlang:monotonic_time()),
      actorKiller(Actors); % kill any actors not yet dead
    true ->
      lists:nth(rand:uniform(ActualNumOfActors),Actors) ! start,
      pushSumConvergenceCheck(Actors,erlang:monotonic_time()),
      actorKiller(Actors) % kill any actors not yet dead
  end,
  ok.

gossipConvergenceCheck([],StartTime)->
  EndTime = erlang:monotonic_time(),%recommend replacement to now()
  REALTIME = erlang:convert_time_unit(EndTime-StartTime,native,millisecond),
  io:format("REAL TIME OF PROGRAM in milliseconds:~p~n",[REALTIME]),
  ok;
gossipConvergenceCheck(ListOfActors,StartTime)->
  receive
    {done,ActorPID} ->
      PIDs = ListOfActors -- [ActorPID],
      gossipConvergenceCheck(PIDs,StartTime)
  end.

pushSumConvergenceCheck([],StartTime)->
  EndTime = erlang:monotonic_time(),%recommend replacement to now()
  REALTIME = erlang:convert_time_unit(EndTime-StartTime,native,millisecond),
  io:format("REAL TIME OF PROGRAM in milliseconds:~p~n",[REALTIME]),
  ok;
pushSumConvergenceCheck(_,StartTime)->
  receive
    {done, PID,Sum} ->
      io:format("Actor: ~p returned sum: ~w~n",[PID,Sum]),
      pushSumConvergenceCheck([],StartTime) % push sum only needs one node to converge to get answer
  end.
actorKiller([])-> %Tell actors to kill themselves the swarm has converged
  ok;

actorKiller(ListOfActors)->
  hd(ListOfActors) ! die,
  actorKiller(tl(ListOfActors)).

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
%%  io:format("Client~p~n",[Client]),
%%  io:format("~w~n",[ListOfNeighbors]),
  gossipActor(Client,ListOfNeighbors,10,false).% stop after sharing rumor 10 times

gossipActor(_,_,0,_)->
  ok;
gossipActor(Client,ListOfNeighbors,N,true)->
  receive
    Rumor ->
      lists:nth(rand:uniform(length(ListOfNeighbors)),ListOfNeighbors) ! Rumor
  end,
  gossipActor(Client,ListOfNeighbors,N-1,true);
gossipActor(Client,ListOfNeighbors,N,false)->
  receive
    Rumor ->
      lists:nth(rand:uniform(length(ListOfNeighbors)),ListOfNeighbors) ! Rumor,
      % tell supervisor I have heard rumor once. do only on first listen
      Client ! {done, self()},
      io:format("Got rumor ~p~n",[self()])
  end,
  gossipActor(Client,ListOfNeighbors,N-1,true). % Done = true as has to have heard rumor to have gotten here

pushSumActor(Client,S, ListOfNeighbors) ->%work in progress
%%  io:format("Client~p~n",[Client]),
%%  io:format("ActorNum~p~n",[S]),
%%  io:format("~w~n",[ListOfNeighbors]),
  pushSumActor(Client,S,0,ListOfNeighbors,3,0,math:pow(10,-10)).% 0 = w ; 3 is max number of rounds without change in ratio(last arg S)

pushSumActor(Client,S,W,_,0,_,_)-> % failed to change in 3 rounds done
  Sum = S/W,
  Client ! {done, self(),Sum},% tell supervisor I have converged
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
      lists:nth(rand:uniform(length(ListOfNeighbors)),ListOfNeighbors) ! {S/2,1/2},
      pushSumActor(Client,S/2,1/2,ListOfNeighbors,3,(S/2)/(1/2),L) % all nodes w = 0 but starter node gets a weight of 1 so 1/2 after here
  end,
  ok.

spawnMultipleActors(NumberOfActorsToSpawn)->%DONE
  spawnMultipleActors(NumberOfActorsToSpawn,[]).
spawnMultipleActors(0,ListOfPid)->
  %io:format("~p~n",[ListOfPid]),
  ListOfPid;
spawnMultipleActors(NumberOfActorsToSpawn,ListOfPid)->
  spawnMultipleActors(NumberOfActorsToSpawn-1,[spawn(project2,actor,[]) | ListOfPid]).