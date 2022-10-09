
-module(project2).
-import(rand,[uniform/1]).
-export([actor/1,main/3,bonusMain/3,superVisor/4]).

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

main(NumberOfActors, Topology, Algo)-> %normal run without bonus implementation
  spawn(project2,superVisor,[NumberOfActors,Topology,Algo,false]),% spwan supervisor to ensure clean slate each run (nothing left in message buffers)
  ok.
bonusMain(NumberOfActors, Topology, Algo)->
  spawn(project2,superVisor,[NumberOfActors,Topology,Algo,true]),%true to run broken nodes
  ok.

superVisor(NumberOfActors, Topology, Algo,Bonus)->%DONE
  if
    Algo == gossip ->
      Gossip = true;
    Algo == pushSum ->
      Gossip = false;
    true ->
      Gossip = true,% just for compiler warning doesnt get used
      throw("Not a valid Algo enter gossip or pushSum")
  end,
  if
    Bonus == true ->
      %Number of actors isn't the true range in the 2d cases but its fine just need a random actor
      BrokenActor = rand:uniform(NumberOfActors); % single actor to kill after a single receive/send action
    true ->
      BrokenActor = -1 % don't break any actors
  end,
  if % start topology building
    Topology == line->
      ActualNumOfActors = NumberOfActors,
      Actors = spawnMultipleActors(NumberOfActors,BrokenActor),
      linkInLine(NumberOfActors,Actors,Gossip);
    Topology == full->
      ActualNumOfActors = NumberOfActors,
      Actors = spawnMultipleActors(NumberOfActors,BrokenActor),
      fullLink(NumberOfActors,Actors,Gossip);
    Topology == imp2D->
      W = round(math:ceil(math:sqrt(NumberOfActors))),
      ActualNumOfActors = W*W,
      Actors = spawnMultipleActors(ActualNumOfActors,BrokenActor),
      Grid = makeGrid(W,W,Actors),
      gridLink(Grid,W,W,ActualNumOfActors,true,Gossip);% true to add random actor to neighbor list
    Topology == '2D' ->
      W = round(math:ceil(math:sqrt(NumberOfActors))),
      ActualNumOfActors = W*W,
      Actors = spawnMultipleActors(ActualNumOfActors,BrokenActor),
      Grid = makeGrid(W,W,Actors),
      gridLink(Grid,W,W,ActualNumOfActors,false,Gossip);
    true ->
      ActualNumOfActors = NumberOfActors, % just for compiler safety
      Actors = [],% just for compiler safety
      throw("Not a valid Topology. Valid options: [line,full,'2D',imp2D")
  end,
  if %start algos
    Gossip == true->
      lists:nth(rand:uniform(ActualNumOfActors),Actors) ! "rumor from nicolas", % tell random actor rumor to start process
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
  REALTIME = erlang:convert_time_unit(EndTime-StartTime,native,microsecond),
  io:format("CONVERGENCE TIME OF PROGRAM in microseconds:~p~n",[REALTIME]),
  ok;
gossipConvergenceCheck(ListOfActors,StartTime)->
  receive
    {done,ActorPID} ->
      PIDs = ListOfActors -- [ActorPID],
      gossipConvergenceCheck(PIDs,StartTime)
  end.

pushSumConvergenceCheck([],StartTime)->
  EndTime = erlang:monotonic_time(),%recommend replacement to now()
  REALTIME = erlang:convert_time_unit(EndTime-StartTime,native,microsecond),
  io:format("CONVERGENCE TIME OF PROGRAM in microseconds:~p~n",[REALTIME]),
  ok;
pushSumConvergenceCheck(ListOfActors,StartTime)->
  receive
    {done, PID,_} ->% replace _ with Sum to see actor results
      %io:format("Actor: ~p returned sum: ~w~n",[PID,Sum]), % used for testing
      pushSumConvergenceCheck(ListOfActors--[PID],StartTime) % push sum only needs one node to converge to get answer
  end.
actorKiller([])-> %Tell actors to kill themselves the swarm has converged
  ok;

actorKiller(ListOfActors)->
  exit(hd(ListOfActors),kill),
  actorKiller(tl(ListOfActors)).

actor(Broken)-> %starter actor decides which type of actor to run
  receive
    List->
      Gossip = hd(List),
      if
      Gossip == true ->
        PIDs = tl(List),
        if
          Broken == true -> % setup broken actor
            brokenGossipActor(hd(PIDs),tl(PIDs));
          true -> % setup regular actor
            gossipActor(hd(PIDs),tl(PIDs))
        end;
      true -> % pushsum
        Tail = tl(List),
        ActorNum = hd(Tail),
        PIDs = tl(Tail),
        if
          Broken == true -> % setup broken actor
            brokenPushSumActor(ActorNum,tl(PIDs));
          true -> % setup regular actor
            pushSumActor(hd(PIDs),ActorNum,tl(PIDs))
        end
      end
  end.

brokenGossipActor(Client,ListOfNeighbors)-> % regular actor but only runs once
  gossipActor(Client,ListOfNeighbors,true).

gossipActor(Client, ListOfNeighbors)->%DONE
  gossipActor(Client,ListOfNeighbors,false).

gossipActor(Client,ListOfNeighbors,Broken)-> % gossipActor started
  receive
    Rumor ->
      gossipActor(Client,ListOfNeighbors,Broken,Rumor)
  end.
gossipActor(converged,ListOfNeighbors,Broken,Rumor)-> % only send actor once converged
  Actor = lists:nth(rand:uniform(length(ListOfNeighbors)),ListOfNeighbors),
  Actor ! Rumor, % keep spreading rumor but node has converged
  gossipActor(converged,ListOfNeighbors,Broken,Rumor), % infinite loop killed buy supervisor with killActor
  ok;
gossipActor(Client,ListOfNeighbors,Broken,Rumor)->
  Actor = lists:nth(rand:uniform(length(ListOfNeighbors)),ListOfNeighbors),
  Actor ! Rumor,
  if
    Broken == true -> % send rumor once then die
      Client ! {done, self()},% tells supervisor it converged though this is not true and real life would not be so kind,
      % this allows me to see the slow down of convergence if a node is lost by having the supervisor terminate normally
      ok;
    true ->
      {_,RumorCount} = erlang:process_info(self(), message_queue_len),% how many messages are in my queue prevents blocking like receive does
      if
         RumorCount >= 9-> % 9  in queue + 1 processed = 10 received
           % tell supervisor I have heard rumor 10 times. do only once
           Client ! {done, self()},
           gossipActor(converged,ListOfNeighbors,Broken,Rumor),
          ok;
        true ->
          gossipActor(Client,ListOfNeighbors,Broken,Rumor)
      end
  end.

brokenPushSumActor(S,ListOfNeighbors)-> % broken so only runs once
  receive
    {MS,MW}->
      SS = MS+S,
      SW = MW +0,
      lists:nth(rand:uniform(length(ListOfNeighbors)),ListOfNeighbors) ! {SS/2,SW/2}; % send half
    start -> % sent by supervisor to start pushsum
      lists:nth(rand:uniform(length(ListOfNeighbors)),ListOfNeighbors) ! {S/2,1/2}
  end,
  ok.
pushSumActor(Client,S, ListOfNeighbors) ->%work in progress
  pushSumActor(Client,S,0,ListOfNeighbors,3,0,math:pow(10,-10)).% 0 = w ; 3 is max number of rounds without change in ratio(last arg S)
pushSumActor(Client,S,W,ListOfNeighbors,0,LastRatio,L)-> % failed to change in 3 rounds done
  Sum = S/W,
  Client ! {done, self(),Sum},% tell supervisor I have converged
  pushSumActor(Client,S,W,ListOfNeighbors,-1,LastRatio,L),% keep sending info but already converged(Continued participation required for total network convergence)
  %above keeps from telling supervisor multiple times
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

spawnMultipleActors(NumberOfActorsToSpawn,BrokenActor)->%DONE
  spawnMultipleActors(NumberOfActorsToSpawn,[],BrokenActor).
spawnMultipleActors(0,ListOfPid,_)->
  ListOfPid;
spawnMultipleActors(NumberOfActorsToSpawn,ListOfPid,0)-> % got to broken actor spawn broken one
  spawnMultipleActors(NumberOfActorsToSpawn-1,[spawn(project2,actor,[true]) | ListOfPid],-1);
spawnMultipleActors(NumberOfActorsToSpawn,ListOfPid,BrokenActor)->
  spawnMultipleActors(NumberOfActorsToSpawn-1,[spawn(project2,actor,[false]) | ListOfPid],BrokenActor-1).