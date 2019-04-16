%%%-------------------------------------------------------------------
%%% @author max
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 01. Aug 2018 17:02
%%%-------------------------------------------------------------------
-module(test).
-author("max").
%-include("db.erl").
%-import(db,).
-export([startTest/1]).

startTest(Port) ->
  Test = {generator},
  ChatName = wat,
  %Port = 7771,
  Milliseconds = 1000,
  U1 = moshe,
  U2 = baruh,
  U3 = babushka,
  U4 = samir,
  U5 = yehuda,

  db:initDB(),

  case Test of
    {server} ->
      %tcp:start(1, Port),
      tcpSup:start_link(3, Port),

      A = client:client(Port),
      B = client:client(Port),
      C = client:client(Port),

      A ! {send, {joinChat, ChatName, manhus}},
      B ! {send, {msg, manhus, ChatName, bdikaaa}},

      A ! {send, {register, U1, 1}},
      B ! {send, {register, U2, 2}},
      C ! {send, {register, U3, 3}},
      timer:sleep(Milliseconds),
      io:format("getUsers(): ~p ~n", [db:getUsers()]),

      A ! {send, {joinChat, ChatName, U1}},
      B ! {send, {joinChat, ChatName, U2}},
      C ! {send, {joinChat, ChatName, U3}},
      timer:sleep(Milliseconds),
      io:format("getChats(): ~p ~n", [db:getChats()]),
      io:format("getChatUsers(ChatName): ~p ~n", [db:getChatUsers(wat)]),

      A ! {send, {msg, U1, ChatName, "LOMNG MESSAGE TO CHECK THE TCP SOCKET LALALALALALALAL"}},
      timer:sleep(Milliseconds),
      A ! {send, {msg, U1, ChatName, test11}},
      B ! {send, {msg, U2, ChatName, test2}},
      timer:sleep(Milliseconds),
      B ! {send, {msg, U2, ChatName, test22}},
      C ! {send, {msg, U3, ChatName, test3}},
      timer:sleep(Milliseconds),
      io:format("getUserMessages(User, ChatRoom) for user ~p: ~p ~n", [U1, db:getUserMessages(U1, ChatName)]),
      io:format("getUserMessages(User, ChatRoom) for user ~p: ~p ~n", [U2, db:getUserMessages(U2, ChatName)]),
      io:format("getUserMessages(User, ChatRoom) for user ~p: ~p ~n", [U3, db:getUserMessages(U3, ChatName)]),

      A ! {wat, closeA},
      B ! {wat, closeB},
      C ! {wat, closeC};

      %db:closeDB();

    {db} ->
%-----------------registerUser-----------------%
      db:registerUser(U1, 1),
      db:registerUser(U2, 2),
      db:registerUser(U3, 3),
      db:registerUser(U4, 4),
      db:registerUser(U5, 5),

      db:registerUser(U1, 1),
      db:registerUser(U2, 2),
      db:registerUser(U3, 3),
      db:registerUser(U4, 4),
      db:registerUser(U5, 5),
% Expected output: no double names.
      io:format("getUsers(): ~p ~n", [db:getUsers()]),
%----------------------------------------------%

      db:joinChat(wat, U1),
      db:joinChat(wat, U2),
      db:joinChat(wat, U3),
      db:joinChat(wat, U4),
      db:joinChat(wat, U5),

      db:addMessage(U1, wat, test1),
      db:addMessage(U1, wat, test11),
      db:addMessage(U1, wat, test12),
      db:addMessage(U1, wat, test13),
      db:addMessage(U2, wat, test2),
      db:addMessage(U3, wat, test3),
      db:addMessage(U4, wat, test4),
      db:addMessage(U5, wat, test5),


      io:format("getChats(): ~p ~n", [db:getChats()]),
      io:format("getChatUsers(ChatName): ~p ~n", [db:getChatUsers(wat)]),
      io:format("getUserMessages(User, ChatRoom) for user ~p: ~p ~n", [U1, db:getUserMessages(U1, wat)]),
      io:format("getUserMessages(User, ChatRoom) for user ~p: ~p ~n", [U2, db:getUserMessages(U2, wat)]),
      io:format("getUserMessages(User, ChatRoom) for user ~p: ~p ~n", [U3, db:getUserMessages(U3, wat)]),
      io:format("getUserMessages(User, ChatRoom) for user ~p: ~p ~n", [U4, db:getUserMessages(U4, wat)]),
      io:format("getUserMessages(User, ChatRoom) for user ~p: ~p ~n", [U5, db:getUserMessages(U5, wat)]);

    {file} ->
      tcpSup:start_link(3, Port),

      A = client:client(Port),
      {ok, File} = file:read_file("test.m4a"),
      A ! {send, {audio, File}};

    {generator} ->
      AI = lists:seq(1, 200),
      Clients = [client:client(Port) || _ <- AI],
      [X ! {send, {register, X, 1}} || X <- Clients],
      [X ! {send, {joinChat, rand:uniform(10), X}} || X <- Clients],
      [X ! {send, {msg, X, rand:uniform(10), rand:uniform(10000)}} || X <- Clients],
      Client = hd(Clients),
      Client ! {send, {db}}
  end.

