%%%-------------------------------------------------------------------
%%% @author max
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 29. Jul 2018 19:02
%%% Main module, this module represents the tcp server.
%%%-------------------------------------------------------------------
-module(tcp).
-author("max").

%% API
-export([start/2, init/1, server/2, mainLoop/3]).

start(Num,LPort) ->
  process_flag(trap_exit, true),
  db:initDB(),
  testwx:start(),
  case gen_tcp:listen(LPort, [binary, {active, false},{packet,2}]) of
    {ok, ListenSock} ->
      io:format("Main ID: [~w] ~nNum: ~p ~nPort: ~p ~n", [self(), Num, LPort]),
      % SL = start_servers(Num, ListenSock, []),
      %{ok, Port} = inet:port(ListenSock),
      %spawn(?MODULE, mainLoop, [ListenSock, SL]);
	  % Here we spawn main process which is going to create all client sockets.
	  % Every socket will be accepted by single process.
      spawn(?MODULE, mainLoop, [Num, ListenSock, []]);
    {error,Reason} ->
      {error,Reason}
  end.

init([]) ->
  wat.

start_servers(0, _, SpawnList) ->
  SpawnList;
start_servers(Num, LS, SpawnList) ->
  % Spawn's for each tcp socket.
  Spawn = spawn(?MODULE, server, [LS, self()]),
  % SpawnList is needed for broadcasting messages to all users in relevant chat.
  NewSpawnList = SpawnList ++ [Spawn],
  start_servers(Num-1, LS, NewSpawnList).


mainLoop(Num, ListenSock, SpawnList) ->
  if (Num > 0) ->
    NewSpawnList = start_servers(Num, ListenSock, SpawnList),
    mainLoop(0, ListenSock, NewSpawnList);
    true ->
      ok
  end,

  receive
	% Main process loops here, his job is to receive messages from client process and 
	% passing the message to all other relevant clients within the chat room.
    {status, Pid, Data} ->
      %io:format("SpawnList: ~p ~n", [SpawnList]),
      %io:format("~w received from ~w ~n", [self(), Pid]),
	  % This command initiates the broadcast to all relevant clients.
      Pid ! {refresh, SpawnList, Data};
    {terminate} ->
      gen_tcp:close(ListenSock)
  end,
  mainLoop(0, ListenSock, SpawnList).


server(LS, Father) ->
  io:format("spawn ID: [~w] ~n", [self()]),
  case gen_tcp:accept(LS) of
    {ok,S} ->
	  % After client has connected to port 5678, it is accepted by single process as tcp socket.
	  % The main purpose of loop function, is to serve clients in the most scalable way possible.
      loop(S, Father),
      server(LS, Father);
    Other ->
      io:format("accept returned ~w - goodbye!~n",[Other]),
      ok
  end.

loop(S, Father) ->
  inet:setopts(S,[{active,once}]),
  %io:format("After inet: ~p with ID: ~w ~n", [Test, self()]),
  receive
    {tcp,S,Data} ->
      %Answer = process(Data), % Not implemented in this example
      %gen_tcp:send(S,Answer),
      %io:format("~p ~n", [Data]),
	  % When we receive message from Android client, it is sent as binary code.
	  % However, this version of tcp server is not built for android client use.
	  % Because of the reason above we have to transmit this binary code to erlang term.
      Ldata = binary_to_term(Data),
      %io:format("SERVER: ~p ~n", [Ldata]),
      case Ldata of

        {db} ->
          testwx:start();

        {audio, File} ->
          Status1 = db:registerUser(file, File),
          Status2 = db:joinChat(wat, file),
          db:addMessage(file, wat, File),
          if (Status1 =:= Status2) ->
            DBFile = db:getUserMessages(file, wat),
            BINFile = element(2, hd(DBFile)),
            file:write_file("fromDB.m4a", BINFile);
            true ->
              io:format("SERVER: BAD DB ~n"),
              gen_tcp:send(S, term_to_binary({login}))
          end;
		% Registration of new user made here.
        {register, User, Pass} ->
          Status = db:registerUser(User, Pass),
          if (Status =:= {atomic,ok}) ->
            gen_tcp:send(S, term_to_binary({registered, User}));
            true ->
              io:format("SERVER: Already registered: ~p ~n", [Ldata]),
              gen_tcp:send(S, term_to_binary({login}))
          end;
		% Registered user may join existing chat, or create new chat.
		% If the user is not registered, the server will not allow the user to enter the chat.
        {joinChat, ChatName, User} ->
          Status = db:joinChat(ChatName, User),
          if (Status =:= {atomic,ok}) ->
            gen_tcp:send(S, term_to_binary({joinedChat, User, ChatName}));
            true ->
              io:format("SERVER: ~p please register first.. ~n", [User]),
              gen_tcp:send(S, term_to_binary({register, User}))
          end;
		% After the user joins the wanted chat, he can start sending messages here.
		% Every message is broadcasted to relevant users in the sending user chat.
        {msg, User, ChatName, Message} ->
          Status = db:addMessage(User, ChatName, Message),
          if (Status =:= {atomic,ok}) ->
            %io:format("Father ID: [~w], Brothers: ~p ~n", [Father, Brothers]);
            RefreshData = {ChatName, User, Message},
            Father ! {status, self(), RefreshData},
            %[Brother ! {tcp, S, Data} || Brother <- Brothers];
            gen_tcp:send(S, term_to_binary({msgSent, ChatName, User, Message}));
            true ->
              io:format("SERVER: Please Register or make sure correct chat ~n"),
              gen_tcp:send(S, term_to_binary({registerOrChat}))
          end;
		
        {refresh, ChatName, User, Message} ->
          io:format("PID: [~w], ChatName: ~p, User: ~p, Mesage: ~p ~n", [self(), ChatName, User, Message]);


        A ->
          io:format("SERVER: Bad input format: ~p ~n", [A]),
          gen_tcp:send(S, term_to_binary({wrongFormat}))
      end,

      %io:format("Data from client: ~p ~n", [Ldata]),
      %gen_tcp:send(S, Data),
      loop(S, Father); %% {tcp,S,Data}

    {tcp_closed,S} ->
      io:format("Socket ~w closed [~w]~n",[S,self()]),
      ok;

    {refresh, SpawnList, Data} ->
      %io:format("Entered refresh with: ~p ~n", [SpawnList]),
      Brothers = lists:delete(self(), SpawnList),
      [Brother ! {broadCast, Data} || Brother <- Brothers],
      %io:format("Exited refresh with: ~p ~n", [Brothers]),
      loop(S, Father);
	% The main process sends the command to broadcast from here.
    {broadCast, {ChatName, User, Message}} ->
      %io:format("~w broadcasting!!!! ~n", [self()]),
      gen_tcp:send(S, term_to_binary({msgSent, ChatName, User, Message})),
      loop(S, Father)



  end.