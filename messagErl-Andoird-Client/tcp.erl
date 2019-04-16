%%%-------------------------------------------------------------------
%%% @author max
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 29. Jul 2018 19:02
%%%-------------------------------------------------------------------
-module(tcp).
-author("max").

%% API
-export([start/2, init/1, server/2, mainLoop/3]).


%gen_tcp:listen(5678, [binary, {packet, 0},
%   {active, false}]),


start(Num, LPort) ->
  process_flag(trap_exit, true),
  db:initDB(),
  testwx:start(),
  case gen_tcp:listen(LPort, [binary, {active, false}, {packet, raw}]) of
    {ok, ListenSock} ->
      io:format("Main ID: [~w] ~nNum: ~p ~nPort: ~p ~n", [self(), Num, LPort]),
      % SL = start_servers(Num, ListenSock, []),
      %{ok, Port} = inet:port(ListenSock),
      %Port,
      %spawn(?MODULE, mainLoop, [ListenSock, SL]);
      spawn(?MODULE, mainLoop, [Num, ListenSock, []]);
    {error, Reason} ->
      {error, Reason}
  end.

init([]) ->
  wat.

start_servers(0, _, SpawnList) ->
  SpawnList;
start_servers(Num, LS, SpawnList) ->
  Spawn = spawn(?MODULE, server, [LS, self()]),
  NewSpawnList = SpawnList ++ [Spawn],
  start_servers(Num - 1, LS, NewSpawnList).


mainLoop(Num, ListenSock, SpawnList) ->
  if (Num > 0) ->
    NewSpawnList = start_servers(Num, ListenSock, SpawnList),
    mainLoop(0, ListenSock, NewSpawnList);
    true ->
      ok
  end,

  receive
    {status, Pid, Data} ->
      testwx:start(),
      %io:format("SpawnList: ~p ~n", [SpawnList]),
      %io:format("~w received from ~w ~n", [self(), Pid]),
      Pid ! {refresh, SpawnList, Data};
    {terminate} ->
      gen_tcp:close(ListenSock)
  end,
  mainLoop(0, ListenSock, SpawnList).


server(LS, Father) ->
  io:format("spawn ID: [~w] ~n", [self()]),
  case gen_tcp:accept(LS) of
    {ok, S} ->
      loop(S, Father, 0, 0),
      server(LS, Father);
    Other ->
      io:format("accept returned ~w - goodbye!~n", [Other]),
      ok
  end.

loop(S, Father, MainUser, MainChat) ->
  inet:setopts(S, [{active, once}]),
  %{ok, WAT} = gen_tcp:recv(S, 0),	
  io:format("[~w] Client connected.. ~n", [self()]),
  %self() ! {tcp,S,WAT},
  %RAW = gen_tcp:recv(S, 0),
  %io:format("from anal ~p ~n", [RAW]),
  receive
    {tcp, S, Data} ->
      %Answer = process(Data), % Not implemented in this example
      %gen_tcp:send(S,Answer),
      io:format("DATA: ~p ~n", [Data]),
      %Ldata = binary_to_term(Data),
      if (byte_size(Data) < 100) ->
        RawData = binary_to_list(Data),
        io:format("RawData: ~p ~n", [RawData]),
        {ok, Ts, _} = erl_scan:string(RawData),
        {ok, Ldata} = erl_parse:parse_term(Ts),

        io:format("SERVER: ~p ~n", [Ldata]),
        case Ldata of

          <<"borat">> ->
            io:format("lalalala ~n"),
            loop(S, Father, 0, 0);

          {audio, ChatName, User, FileSize} ->
            %{ok, IoDevice} = file:open("rustm.3gp", [write, binary]),
            %db:registerUser(fileXX, 123),
            %db:joinChat(fileChat, fileXX),
            %db:addUserMessage(fileXX, fileChat, IoDevice),
            Ack = "go" ++ FileSize ++ "\n",
            io:format("SERVER: Sending after audio: ~p ~n", [Ack]),
            gen_tcp:send(S, "send\n"),
            gen_tcp:send(S, Ack),
            BroadFile = {ChatName, User, Ack},
            Father ! {status, self(), BroadFile};


          %db:registerUser(ioDev, IoDevice);

          {close} ->
            gen_tcp:send(S, "-----------------------------\n");
          %DBFile = db:getUserMessages(fileXX, fileChat),
          %BINFile = element(2, hd(DBFile)),
          %file:close(BINFile);


          {audio, File} ->
            Status1 = db:registerUser(file, File),
            Status2 = db:joinChat(wat, file),
            db:addMessage(file, wat, File),
            if (Status1 =:= Status2) ->
              DBFile = db:getUserMessages(file, wat),
              BINFile = element(2, hd(DBFile)),
              file:write_file("rustam.m4a", BINFile);
            % gen_tcp:send(S, "<ok>\n")
              true ->
                io:format("SERVER: BAD DB ~n"),
                gen_tcp:send(S, term_to_binary({login}))
            end;

          {register, User, Pass} ->
            Status = db:registerUser(User, Pass),
            if (Status =:= {atomic, ok}) ->
              %gen_tcp:send(S, term_to_binary({registered, User}));
              gen_tcp:send(S, "<ok>\n");
              true ->
                io:format("SERVER: Already registered: ~p ~n", [Ldata]),
                gen_tcp:send(S, "<ok>\n")
            end;

          {getChat} ->
            Chats = db:getChats(),
            io:format("Chats: ~p ~n", [Chats]),
            Chats1 = [[X] ++ "|" || X <- Chats],
            Chats2 = lists:concat(Chats1),
            Chats3 = lists:concat(Chats2),
            Chats4 = Chats3 ++ "\n",
            gen_tcp:send(S, term_to_binary(Chats4));


          {joinChat, ChatName, User} ->
            Status = db:joinChat(ChatName, User),
            if (Status =:= {atomic, ok}) ->
              gen_tcp:send(S, "<joinedChat>\n"),
              loop(S, Father, User, ChatName);
              true ->
                io:format("SERVER: ~p please register first.. ~n", [User]),
                gen_tcp:send(S, term_to_binary({register, User}))
            end;

          {msg, User, ChatName, Message} ->
            Status = db:addMessage(User, ChatName, Message),
            if (Status =:= {atomic, ok}) ->

              %io:format("Father ID: [~w], Brothers: ~p ~n", [Father, Brothers]);
              MesToSend = atom_to_list(User) ++ ": " ++ Message ++ "\n",
              RefreshData = {ChatName, User, MesToSend},
              Father ! {status, self(), RefreshData},
              %[Brother ! {tcp, S, Data} || Brother <- Brothers];
              io:format("SERVER: Sending to ~p | ~p ~n", [User, MesToSend]),
              gen_tcp:send(S, MesToSend);
              true ->
                io:format("SERVER: Please Register or make sure correct chat ~n"),
                gen_tcp:send(S, term_to_binary({registerOrChat}))
            end;

          {msg1, User, ChatName, Message} ->
            Status = db:addMessage(User, ChatName, Message),
            if (Status =:= {atomic, ok}) ->
              %io:format("Father ID: [~w], Brothers: ~p ~n", [Father, Brothers]);
              RefreshData = {ChatName, User, Message},
              Father ! {status, self(), RefreshData},
              %[Brother ! {tcp, S, Data} || Brother <- Brothers];
              io:format("SERVER: Sending to ~p | ~p ~n", [User, Message]),
              gen_tcp:send(S, Message);
              true ->
                io:format("SERVER: Please Register or make sure correct chat ~n"),
                gen_tcp:send(S, term_to_binary({registerOrChat}))
            end;


          {refresh, ChatName, User, Message} ->
            io:format("PID: [~w], ChatName: ~p, User: ~p, Mesage: ~p ~n", [self(), ChatName, User, Message]);


          _ ->
            io:format("SERVER: Bad input format.. ~n"),
            gen_tcp:send(S, "<ok>\n")
        end;

        true ->
          {ok, IoDevice} = file:open("rustm.3gp", [append, binary]),
          %DBFile = db:getUserMessages(fileXX, fileChat),
          %BINFile = element(2, hd(DBFile)),
          %file:write(BINFile, Data)
          file:write(IoDevice, Data),
          file:close(IoDevice),
          %gen_tcp:send(S, "go\n"),
          gen_tcp:send(S, Data),
          BroadFile = {MainChat, MainUser, Data},
          Father ! {status, self(), BroadFile}

      %BINFile = element(2, hd(DBFile)),
      %file:write_file("rustam.m4a", BINFile);
      % gen_tcp:send(S, "<ok>\n")
      %file:close(IoDevice)
      %gen_tcp:send(S, "go\n"),
      %gen_tcp:send(S, Data),
      %file:write_file("rustam.3gp", Data)
      end,

      %io:format("Data from client: ~p ~n", [Ldata]),
      %gen_tcp:send(S, Data),
      loop(S, Father, MainUser, MainChat); %% {tcp,S,Data}

    {tcp_closed, S} ->
      io:format("Socket ~w closed [~w]~n", [S, self()]),
      ok;

    {refresh, SpawnList, Data} ->
      %io:format("Entered refresh with: ~p ~n", [SpawnList]),
      Brothers = lists:delete(self(), SpawnList),
      [Brother ! {broadCast, Data} || Brother <- Brothers],
      %io:format("Exited refresh with: ~p ~n", [Brothers]),
      loop(S, Father, MainUser, MainChat);

    {broadCast, {ChatName, User, Message}} ->
      %io:format("~w broadcasting!!!! ~n", [self()]),
      if (ChatName =:= MainChat) ->
        gen_tcp:send(S, Message);
        true ->
          1
      end,
      loop(S, Father, MainUser, MainChat);

    _ ->
      io:format("from android ~n"),
      gen_tcp:send(S, "<ok>\n"),
      loop(S, Father, MainUser, MainChat)


  end.

