%%%-------------------------------------------------------------------
%%% @author max
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 29. Jul 2018 19:12
%%%-------------------------------------------------------------------
-module(client).
-author("max").

%% API
-export([client/1, sendLoop/1, receiveLoop/1, refreshLoop/1]).

client(PortNo) ->
  {ok,Sock} = gen_tcp:connect("localhost",PortNo,[binary, {active,false}, {packet,2}]),
  %{ok,Sock} = gen_tcp:connect("localhost",PortNo,[binary, {packet,2}]),

  %gen_tcp:close(Sock),

  spawn(?MODULE, receiveLoop, [Sock]),
  spawn(?MODULE, sendLoop, [Sock]).

receiveLoop(S) ->
  RawData = gen_tcp:recv(S, 0),
  Data = binary_to_term(element(2,RawData)),
  case Data of

    {register, User} ->
      io:format("messagErl | ~p please register first. ~n", [User]);

    {registered, User} ->
      io:format("messagErl | ~p registered messagErl services. ~n", [User]);

    {joinedChat, User, ChatName} ->
      io:format("~p | ~p entered the room. ~n", [ChatName, User]);

    {msgSent, ChatName, User, LastMessage} ->
      {_, {Hour, Minute, Second}} = calendar:universal_time_to_local_time(erlang:universaltime()),
      io:format("~p[~p:~p:~p] | ~p: ~p ~n", [ChatName, Hour, Minute, Second, User, LastMessage]);

    _ ->
      io:format("CLIENT: Bad input format.. ~n")

  end,

  receiveLoop(S).


sendLoop(S) ->
  receive
    {exit, K} ->
      gen_tcp:close(S),
      io:format("Closed... with message: ~p ~n", [K]);
    {audio, File} ->
      Data = term_to_binary({audio, File}),
      gen_tcp:send(S, Data);
    {send, Message} ->
      %io:format("Before term to binary: ~p ~n", [Message]),
      Data = term_to_binary(Message),
      %io:format("After term to binary: ~p ~n", [Data]),
      gen_tcp:send(S, Data),
      %A = gen_tcp:recv(S, 0),
      %io:format("From Server: ~p ~n", [A]),
      %AfterBinaryData = binary_to_term(element(2,A)),
      %AfterBinaryData = binary_to_term(A),
      %io:format("From Server After: ~p ~n", [AfterBinaryData]),





      sendLoop(S)
  end.

refreshLoop(S) ->
 % Data = term_to_binary({refresh}),
  timer:sleep(1000),
  %gen_tcp:send(S, Data),
  refreshLoop(S).