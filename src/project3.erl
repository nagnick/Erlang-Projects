-module(project3).
-author("nicolas").
-import(crypto,[hash/2]).
-export([simulate/2,chordActor/2,actorKiller/1,createCollisionFreeData/1,createActorSearchList/2,fillWithData/2]).

findSuccessor(SortedMapList,MinValue)-> % function searches the list to find the first value grater than or equal to MinValue
  findSuccessor(SortedMapList,MinValue,SortedMapList).% saves original list in case of a wrap around ex min value is larger than largest
  % value in list so return min value of list aka head
findSuccessor([],_,Original)-> % if you get to the end of the list return first item in list
  hd(Original);
findSuccessor(SortedMapList,MinValue,Original)->
  {Key,_} = hd(SortedMapList),
  if
    Key >= MinValue ->
      hd(SortedMapList);
    true ->
      findSuccessor(tl(SortedMapList),MinValue,Original)
  end.

findActorToAsk(FingerTable,Key)-> % function searches the list to find the first value grater than or equal to MinValue
  findActorToAsk(FingerTable,Key,hd(FingerTable)).% saves original list in case of a wrap around ex min value is larger than largest
% value in list so return min value of list aka head
findActorToAsk([],_,LastHighestValue)-> % if you get to the end of the list return first item in list
  LastHighestValue;
findActorToAsk(FingerTable,Key,LastHighestValue)->
  {ActorHash,_} = hd(FingerTable),
  if
    ActorHash < Key -> % find actor with a large hash that is still less than key looking for
      findActorToAsk(tl(FingerTable),Key,hd(FingerTable));
    true -> % this item goes to far return last actor that was less than key
      LastHighestValue
  end.
%%findActorToAsk(FingerTable,Key,LastHighestValue)->
%%  {ActorHash,_} = hd(FingerTable),
%%  if
%%    ActorHash < Key -> % find actor with a large hash that is still less than key looking for
%%      {LastHash,_} = LastHighestValue,
%%      if
%%        LastHash > ActorHash->
%%          findActorToAsk(tl(FingerTable),Key,LastHighestValue);% keep old lastHighestHash as it is higher
%%        true->
%%          findActorToAsk(tl(FingerTable),Key,hd(FingerTable)) % use new value as it is higher
%%      end;
%%    true -> % this item goes to far return last actor that was less than key
%%      LastHighestValue
%%  end.
createFingerTable(_,_,0,FingerTable) ->%List max size is 160
  FingerTable; % table is a list of {hashvalue,PID}
createFingerTable(ActorHash,SortedListOfPids,I,FingerTable)-> % I is size of fingerTable and current index being filled
  %io:format("~w~n",[SortedListOfPids]),
  NextEntryMinHash = (ActorHash + round(math:pow(2,I-1))) rem round(math:pow(2,160)), % formula in doc hash size is 160 so table is 160
  Hash = findSuccessor(SortedListOfPids,NextEntryMinHash), %% get smallest actor hash to fill current spot
  createFingerTable(ActorHash,SortedListOfPids,I-1,[Hash | FingerTable]).

chordActor(SuperVisor,HashId)-> % startingPoint of actor
  receive
    {init, MapOfPids}->
      % make a finger table based of map of hash => PID, first make map a list sorted based on hash
      NewFingerTable = lists:keysort(1,createFingerTable(HashId, lists:keysort(1,maps:to_list(MapOfPids)),160,[])), % initial FingerTable is empty and start filling fingerTable at index 1
      % finger table is sorted so that the search for next in line actors is most efficient
      %io:format("~w~n",[NewFingerTable]),
      chordActor(SuperVisor,NewFingerTable,HashId,MapOfPids) % fingerTable is filled with {hashID,PID} tuples of the actors in network
    % carries map of PIDs to build future fingerTables from
  end.

chordActor(SuperVisor, FingerTable,HashId,MapOfPids)-> % second step of actor
  receive
  %add searchSet receive to start the searching process
    {searchSet,SearchSetList}->
      chordActor(SuperVisor, FingerTable,#{},HashId,SearchSetList,MapOfPids,0)
  end.

chordActor(SuperVisor, FingerTable,DataTable,HashId,SearchSetList, MapOfPids, HopsRunningSum)-> %final main actor
  %io:format("ActorHashID:~w~p~n ~w~n~w~n",[HashId,self(),FingerTable,length(FingerTable)]),
%%  if
%%    SearchSetList == []->
%%      SuperVisor ! {done,self(), HopsRunningSum}; % notify supervisor all searches complete
%%    true ->
%%      %% send message to find hd of searchSetLIst
  %{_,PID}= findSuccessor(FingerTable,hd(SearchSetList)),
 % PID ! {find,decimalShaHash(hd(SearchSetList)),self()}, % fix findGEV expects sorted mapList
%%  end,
  receive
    {addActor,Pid,Id}-> % Don't need / BROKEN
      NewMapOfPids = maps:put(Id,Pid,MapOfPids),
      NewFingerTable = lists:keysort(1,createFingerTable(HashId, lists:keysort(1,maps:to_list(NewMapOfPids)),160,[])), % update finger table by making a new one
      chordActor(SuperVisor, NewFingerTable,DataTable,HashId,SearchSetList,NewMapOfPids,HopsRunningSum);
    {found,Value,Hops}-> % done
      NewSearchSetList = SearchSetList -- [Value],% don't need to search for anymore
      chordActor(SuperVisor, FingerTable,DataTable,HashId,NewSearchSetList,MapOfPids,HopsRunningSum+Hops);

    {find,Key,SearchersPID}-> % done?
      % check finger table
      {ToAskHash,ToAskPID} = findActorToAsk(FingerTable,Key), % returns tuple {HAshKey, PID}
      if
        HashId == ToAskHash -> % found! i must have the data in my dataTable
          io:format("FOund~n"),
          SearchersPID ! maps:get(Key,DataTable); %returns {badKey,Key} if not in map to actor searching
        true -> % not in my data table ask next highest node still less than
          ToAskPID ! {find,Key,SearchersPID}
      end,
      chordActor(SuperVisor,FingerTable,DataTable,HashId,SearchSetList,MapOfPids,HopsRunningSum);

    {addKeyValue,Key,Value}-> % done?
      {ToAskHash,ToAskPID} = findActorToAsk(FingerTable,Key), % returns tuple {HAshKey, PID} %%%%%% BROKEN DOES NOT WORK AT ALLLLLLL
      if
        ToAskHash >= Key  -> % Is next actor in finger table a valid choice? or is it trying to loop around so went higher
          if
            HashId >= ToAskHash -> % looped around to beginning so I am still best choice
              NewMap = maps:put(Key,Value,DataTable),
              SuperVisor ! {dataInserted,Value}; % tell supervisor data is inserted so it knows when to start simulation;
            true -> % next actor is best choice
              ToAskPID ! {addKeyValue,Key,Value},
              NewMap = DataTable
          end;
        true -> % next actor too far up insert in me
          NewMap = maps:put(Key,Value,DataTable),
          SuperVisor ! {dataInserted,Value} % tell supervisor data is inserted so it knows when to start simulation;
      end,
      chordActor(SuperVisor, FingerTable,NewMap,HashId,SearchSetList,MapOfPids,HopsRunningSum)
  end.

decimalShaHash(N)->
binary:decode_unsigned(crypto:hash(sha,N)). % use sha 1 like doc says max size is unsigned 160 bit value = 1461501637330902918203684832716283019655932542976

simulate(NumberOfActors,NumberOfRequests)-> % number of request means each actor must make that many SuperVisor of network will get responses from actors
  io:format("NUM OF REQ:~w~n",[NumberOfRequests]),
  MapOfActors = spawnMultipleActors(NumberOfActors,#{}), % hashed key,PID map returned
  ListOfActors = [X || {_,X} <- maps:to_list(MapOfActors)], % remove hash keys only want pids of actors from now on
  init(ListOfActors,MapOfActors), % init first then start to begin searching(don't want actors to search from actors not done with init)
  Data = createCollisionFreeData(400),
  start(ListOfActors,Data,10),
  fillWithData(ListOfActors,Data),
  hopSum(ListOfActors,0,NumberOfActors),
  actorKiller(ListOfActors).

init([],_)-> % sends actors everything they need to initialize finger table and data map
  io:format("FingerTables built~n"),
  ok;
init(ListOfActors,MapOfActors)->
  PID = hd(ListOfActors),
  PID !  {init,MapOfActors},
  init(tl(ListOfActors),MapOfActors).

start([],_,_)-> % gives actors a search set to start looking up data
  io:format("SearchSets Distributed~n"),
  ok;
start(ListOfActors,CollisionFreeDataSet, SearchSetSize)->
  PID = hd(ListOfActors),
  PID !  {searchSet,createActorSearchList(CollisionFreeDataSet,SearchSetSize)},
  start(tl(ListOfActors),CollisionFreeDataSet,SearchSetSize).

fillWithData(_,[])-> % gives actors a search set to start looking up data
  io:format("Actor data tables filled~n"),
  ok;
fillWithData(ListOfActors,CollisionFreeDataSet)->
  PID = lists:nth(rand:uniform(length(ListOfActors)),ListOfActors), % insert starting at random actors
  PID ! {addKeyValue,decimalShaHash(hd(CollisionFreeDataSet)),hd(CollisionFreeDataSet)},
  receive
    {dataInserted,Value}->
      %io:format("value Entered successfully"),
      fillWithData(ListOfActors,CollisionFreeDataSet -- [Value])
  end.

hopSum([],RunningSum,ActorCount)->
  io:format("AverageNumberOfHops:~p~n",[(RunningSum/ActorCount)]);
hopSum(ListOfActors,RunningSum,ActorCount)->
  receive
    {done,ActorPID,TotalHops} -> % fix if actor already exited don't sum
      Length1 = length(ListOfActors),
      PIDs = ListOfActors -- [ActorPID],
      Length2 = length(PIDs),
      if
        Length1  == Length2 -> % repeat message from actor
          hopSum(PIDs,RunningSum,ActorCount);
        true -> % new message from actor so add to running hops sum
          hopSum(PIDs,RunningSum + TotalHops,ActorCount)
      end
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
  NewMap = maps:put(decimalShaHash([NumberOfActorsToSpawn]),spawn(project3,chordActor,[self(),decimalShaHash([NumberOfActorsToSpawn])]), MapOfPid),
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