-module(main).
-import(crypto,[hash/2]).
-export([superVisorActor/3, remoteClient/1, hashActor/0]).
%Input: The input provided (as command line to yourproject1.fsx) will be, the required number of 0’s of the bitcoin.1

%% Output: Print, on independent entry lines, the input string, and the correspondingSHA256 hash separated by a TAB, for
%% each of the bitcoins you find. Obviously, your SHA256 hash must have the required number of leading 0s
%% (k= 3 means3 0’s in the hash notation).  An extra requirement, to ensure every group finds different coins, is to have
%% the input string prefixed by the gator link ID of one of the team members.

%main:superVisorActor("adobra;kjsdfk11", 1, 3). test that input string for 1 zero and with 3 actors

superVisorActor(SizeOfWorkingSet, NumberOfZeros, NumberOfActors)-> % recursion starter spawns a group of actors gives them a working set and waits for responses
  global:register_name(server,self()),% when a new machine joins send its message here
  StartTime = erlang:monotonic_time(),%recommend replacement to now()
  SetSize = SizeOfWorkingSet div NumberOfActors,
  messageActors(0,SetSize, SetSize,NumberOfZeros,NumberOfActors,spawnMultipleHashActors(NumberOfActors)),
  listen(NumberOfActors,StartTime,0,SizeOfWorkingSet, NumberOfZeros, NumberOfActors,1).% last 4 used by remote actor spawner

messageActors(_, _,_, _, 0, _)-> %gives actors in list their working set
  ok;
messageActors(Start,End, SetSize, NumberOfZeros, NumberOfActors, HashActors)->
  hd(HashActors) ! {self(),Start,End, NumberOfZeros},
  messageActors(Start + SetSize, End + SetSize, SetSize ,NumberOfZeros,NumberOfActors-1,tl(HashActors)).% increase each working set by actor fraction of work

listen(0,StartTime,TotalActorCPUTime,_,_,_,_)-> % final call for server
  EndTime = erlang:monotonic_time(),%recommend replacement to now()
  REALTIME = erlang:convert_time_unit(EndTime-StartTime,native,millisecond),
  io:format("REAL TIME OF PROGRAM in milliseconds:~p~n",[REALTIME]),
  CPUTime = erlang:convert_time_unit(TotalActorCPUTime,native,millisecond),
  io:format("RUN TIME OF ALL ACTORS in milliseconds is:~p~n",[CPUTime]);
listen(RunningActors,StartTime,TotalActorCPUTime,SizeOfWorkingSet, NumberOfZeros, NumberOfActors,Clusters)-> %% loop listening to hash actors
  receive
    {"END",ActorCPURuntime,_} ->
      listen(RunningActors -1,StartTime,TotalActorCPUTime+ActorCPURuntime,SizeOfWorkingSet, NumberOfZeros, NumberOfActors,Clusters);
    { ToHash,Hash, _, _} ->
      io:format("~p\t~s~n",[ToHash,Hash]),
      listen(RunningActors,StartTime,TotalActorCPUTime,SizeOfWorkingSet, NumberOfZeros, NumberOfActors,Clusters);
    Node -> % received node from joining remote
      RemotePIDS = spawnMultipleRemoteHashActors(NumberOfActors, Node),
      SetSize = SizeOfWorkingSet div NumberOfActors,
      messageActors(SizeOfWorkingSet*Clusters, (SizeOfWorkingSet*Clusters)+SetSize,SetSize,NumberOfZeros,NumberOfActors,RemotePIDS),
      listen(RunningActors+NumberOfActors,StartTime,TotalActorCPUTime,SizeOfWorkingSet, NumberOfZeros, NumberOfActors,Clusters+1)
  end.

spawnMultipleHashActors(NumberOfActorsToSpawn)->
  spawnMultipleHashActors(NumberOfActorsToSpawn,[]).
spawnMultipleHashActors(0,ListOfPid)->
  ListOfPid;
spawnMultipleHashActors(NumberOfActorsToSpawn,ListOfPid)->
  spawnMultipleHashActors(NumberOfActorsToSpawn-1,[spawn(main,hashActor,[]) | ListOfPid]).

spawnMultipleRemoteHashActors(NumberOfActorsToSpawn,Node)->
  spawnMultipleRemoteHashActors(NumberOfActorsToSpawn,Node,[]).
spawnMultipleRemoteHashActors(0,_,ListOfPid)->
  io:format("~p~n", [ListOfPid]),
  ListOfPid;
spawnMultipleRemoteHashActors(NumberOfActorsToSpawn, Node,ListOfPid)->
  io:format("Spawning ~p remote workers~n", [NumberOfActorsToSpawn]),
  spawnMultipleRemoteHashActors(NumberOfActorsToSpawn-1, Node, [spawn(Node, main,hashActor,[]) | ListOfPid]).

remoteClient(RemoteServerNodeName)-> % remoteClient('Nodename@ipaddress').
  Result = net_adm:ping(RemoteServerNodeName),
  if
    Result == pong->
      global:send(server,node()),% tell server about me! give me work!
      "SUCCESS working with remote";
    Result == pang->
      "FAILURE could not connect to remote"
  end.


hashActor()-> %fix make actor independent of supervisor give them a range of strings to test for supervisor
  StartTime = erlang:monotonic_time(),%recommend replacement to now()
  receive
    {Client, Start, End, NumberOfZeros}->
      ToHash = "nicolasgarcia" ++ numberToString(End),
      Hash = printShaHash(ToHash), %gator id prefix
      Result = countZeros(Hash,NumberOfZeros),
      if
        Result == true->
          Client! {ToHash, Hash,true, self()};
        true -> %% else case or default REMOVE for final result
          ok
      end,
      hashActor(Start, End - 1, Client, NumberOfZeros,StartTime);
    {Client,_}-> % should never enter here or bellow as supervisor sends case above
      Client! "Missing 1 Paramter";
    {Client}->
      Client! "Missing 2 parameters"
  end.
hashActor(Start,End, Client, NumberOfZeros,StartTime) when Start < End->
  ToHash = "nicolasgarcia" ++ numberToString(End),
  Hash = printShaHash(ToHash), %gator id prefix
  Result = countZeros(Hash,NumberOfZeros),
  if
    Result == true->
      Client! {ToHash, Hash, true, self()};
    true -> %% else case or default REMOVE for final result
      ok
  end,
  hashActor(Start, End - 1, Client, NumberOfZeros,StartTime);
hashActor(_,_,Client,_,StartTime)-> % last call of actor
  EndTime = erlang:monotonic_time(),%recommend replacement to now()
  Client ! {"END", EndTime-StartTime, self()}.

printShaHash(N)->
  io_lib:format("~64.16.0b", [binary:decode_unsigned(crypto:hash(sha256,
    N))]).

countZeros(Hash,0)->
  if
    hd(Hash) == hd("0") ->
      false;
    true ->
      true
  end;
countZeros(Hash,NumberOfZeros)->
  if
    hd(Hash) == hd("0") ->
      countZeros(tl(Hash),NumberOfZeros-1);
    true ->
      false
  end.

numberToString(N) when N < 94 -> % 94 possible chars
  [(N+33)]; % 33 = '!' 33 + 93 = 126 = '~' last acceptable char to us
numberToString(N) when N >= 94->
  numberToString(N div 94) ++ numberToString(N rem 94).
