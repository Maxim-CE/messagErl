%%%-------------------------------------------------------------------
%%% @author max
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 06. Aug 2018 15:25
%%%-------------------------------------------------------------------
-module(tcpSup).
-author("max").

-behaviour(supervisor).

%% API
-export([start_link/2, start_link_shell/0]).

%% Supervisor callbacks
-export([init/1]).

start_link_shell() ->
  {ok, Pid} = supervisor:start_link({global, ?MODULE}, ?MODULE, []),
  unlink(Pid).

start_link(Num, Port) ->
  supervisor:start_link({global, ?MODULE}, ?MODULE, [Num, Port]).

init([Num, Port]) ->
  io:format("~p (~p) ~n -----------Supervisor Initializing----------- ~n", [{global, ?MODULE}, self()]),
  RestartStrategy = one_for_one,
  MaxRestarts = 3,
  MaxSecondsBetweenRestarts = 5,
  Flags = {RestartStrategy, MaxRestarts, MaxSecondsBetweenRestarts},
  Restart = permanent,
  Shutdown = infinity,
  Type = worker,
  ChildSpecifications = {tcpSERVER, {gentcp, start_link, [Num, Port]}, Restart, Shutdown, Type, [gentcp]},
  {ok, {Flags, [ChildSpecifications]}}.