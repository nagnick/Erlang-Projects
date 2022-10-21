-module(project3).
-author("nicolas").
-import(crypto,[hash/2]).
-export([simulate/2,chordActor/3,actorKiller/1,createCollisionFreeData/1,createActorSearchList/2]).

findGEValue(SortedMapList,MinValue)-> % function searches the list to find the first value grater than or equal to MinValue
  findGEValue(SortedMapList,MinValue,SortedMapList).% saves original list in case of a wrap around ex min value is larger than largest
  % value in list so return min value of list aka head
findGEValue([],_,Original)->
  hd(Original);
findGEValue(SortedMapList,MinValue,Original)->
  {Key,_} = hd(SortedMapList),
  if
    Key >= MinValue ->
      hd(SortedMapList);
    true ->
      findGEValue(tl(SortedMapList),MinValue,Original)
  end.

createFingerTable(_,_,0,FingerTable) ->%List max size is 160
  FingerTable; % table is a list of {hashvalue,PID}
createFingerTable(ActorHash,SortedListOfPids,I,FingerTable)-> % I is size of fingerTable and current index being filled
  %io:format("~w",[is_integer(round(math:pow(2,I-1)))]),
  NextEntryMinHash = (ActorHash + round(math:pow(2,I-1))) rem round(math:pow(2,160)), % formula in doc hash size is 160 so table is 160
  Hash = findGEValue(SortedListOfPids,NextEntryMinHash), %% get smallest actor hash to fill current spot
  createFingerTable(ActorHash,SortedListOfPids,I-1,[Hash | FingerTable]).

chordActor(FingerTable,DataTable,HashId)-> %starter actor decides which type of actor to run
  io:format("ActorHashID:~w~p~n ~w~n~w~n",[HashId,self(),FingerTable,length(FingerTable)]),
  receive
    {init, MapOfPids}->
      % make a finger table based of map of hash => PID, first make map a list sorted based on hash
      NewFingerTable = createFingerTable(HashId, lists:keysort(1,maps:to_list(MapOfPids)),160,[]), % initial FingerTable is empty and start filling fingerTable at index 1
      chordActor(NewFingerTable,DataTable,HashId);
    {addActor,Pid,Id}->
      NewFingerTable = maps:put(Id,Pid,FingerTable),
      createFingerTable(HashId,lists:keysort(1,maps:to_list(NewFingerTable)),160,[]), % update finger table by making a new one
      chordActor(NewFingerTable,DataTable,HashId);
    %add searchSet receive to start the searching process

    {find,Key,SearchersPID}-> % fix so that it is stored in proper node given key
      %returns {badKey,Key} if not in map
      SearchersPID ! maps:get(Key,FingerTable), % fix need to message those actors(or tell you to keep looking at next actor) unless in me then return my data
      chordActor(FingerTable,DataTable,HashId);
    {addKeyValue,Key,Value}-> % fix
      NewMap = maps:put(Key,Value,DataTable),
      chordActor(FingerTable,NewMap,HashId)
  end.

decimalShaHash(N)->
binary:decode_unsigned(crypto:hash(sha,N)). % use sha 1 like doc says max size is unsigned 160 bit value = 1461501637330902918203684832716283019655932542976

simulate(NumberOfActors,NumberOfRequests)-> % number of request means each actor must make that many SuperVisor of network will get responses from actors
  io:format("NUM OF REQ:~w~n",[NumberOfRequests]),
  MapOfActors = spawnMultipleActors(NumberOfActors,#{}), % hashed key,PID map returned
  ListOfActors = [X || {_,X} <- maps:to_list(MapOfActors)], % remove hash keys only want pids of actors from now on
  init(ListOfActors,MapOfActors), % init first then start to begin searching(don't want actors to search from actors not done with init)
  start(ListOfActors,createCollisionFreeData(40000),150),
  hopSum(ListOfActors,0,NumberOfActors),
  actorKiller(ListOfActors).

init([],_)-> % sends actors everything they need to initialize finger table and data map
  ok;
init(ListOfActors,MapOfActors)->
  PID = hd(ListOfActors),
  PID !  {init,MapOfActors},
  init(tl(ListOfActors),MapOfActors).

start([],_,_)-> % gives actors a search set to start looking up data
  ok;
start(ListOfActors,CollisionFreeDataSet, SearchSetSize)->
  PID = hd(ListOfActors),
  PID !  {searchSet,createActorSearchList(CollisionFreeDataSet,SearchSetSize)},
  start(ListOfActors,CollisionFreeDataSet,SearchSetSize).

hopSum([],RunningSum,ActorCount)->
  io:format("AverageNumberOfHops:~p~n",[(RunningSum/ActorCount)]);
hopSum(ListOfActors,RunningSum,ActorCount)->
  receive
    {done,ActorPID} ->
      PIDs = ListOfActors -- [ActorPID],
      hopSum(PIDs,RunningSum,ActorCount)
  end.

actorKiller([])-> %Tell actors to kill themselves the swarm has converged
  ok;
actorKiller(ListOfActors)->
  {_,PID} = hd(ListOfActors),
  exit(PID,kill),
  actorKiller(tl(ListOfActors)).

spawnMultipleActors(0,MapOfPid)->
  MapOfPid;
spawnMultipleActors(NumberOfActorsToSpawn,MapOfPid)->
  NewMap = maps:put(decimalShaHash([NumberOfActorsToSpawn]),spawn(project3,chordActor,[[],#{},decimalShaHash([NumberOfActorsToSpawn])]), MapOfPid),
  spawnMultipleActors( NumberOfActorsToSpawn-1,NewMap).

createActorSearchList(ListOfData,SizeOfSetReturned)-> % takes in list of collisionFreeData and returns a random set for actors to lookup of given size
  createActorSearchList(ListOfData,length(ListOfData),SizeOfSetReturned,[]).

createActorSearchList(_,_,0,ReturnedList)->
  ReturnedList;
createActorSearchList(ListOfData,SizeOfList,SizeOfSetReturned,ReturnedList)->
  Index = rand:uniform(SizeOfList),
  createActorSearchList(ListOfData,SizeOfList,SizeOfSetReturned-1,[lists:nth(Index,ListOfData) | ReturnedList]).


createCollisionFreeData(NumberOfEntries)-> % anything more than 4000000 is slow
  createCollisionFreeData(NumberOfEntries,3000, #{}).

createCollisionFreeData(0,_, MapOfEntries)-> % creates a set of strings with hashes that do not collide
  TupleList = maps:to_list(MapOfEntries),
  [Value || {_,Value} <- TupleList];
createCollisionFreeData(NumberOfEntries,NextStringNumber, MapOfEntries)->
  Size = maps:size(MapOfEntries),
  String = numberToString(NextStringNumber),
  NewMap = maps:put(decimalShaHash(String),String,MapOfEntries), % if duplicate just rewrites value for key
  NewSize = maps:size(NewMap),
  if
    NewSize == Size -> % new value generated already has it hash in map so overwrite value map has not grown still need to make same amount of data
      createCollisionFreeData(NumberOfEntries,NextStringNumber+1,NewMap);
    true-> % new value increased map size one lees data entry to make
      createCollisionFreeData(NumberOfEntries-1,NextStringNumber+1,NewMap)
  end.

numberToString(N) when N < 94 -> % 94 possible chars
  [(N+33)]; % 33 = '!' 33 + 93 = 126 = '~' last acceptable char to us
numberToString(N) when N >= 94->
  numberToString(N div 94) ++ numberToString(N rem 94).