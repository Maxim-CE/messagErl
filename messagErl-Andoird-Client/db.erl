%%%-------------------------------------------------------------------
%%% @author max
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 31. Jul 2018 18:17
%%%
%%% A record is a data structure for storing a fixed number of elements.
%%% It has named fields and is similar to a struct in C.
%%% Record expressions are translated to tuple expressions during compilation.
%%% IMPORTANT: To compile all files in directory: cover:compile_directory().
%%% HTTP SERVER: python -m SimpleHTTPServer 5678
%%%-------------------------------------------------------------------
-module(db).
-author("max").
-include_lib("stdlib/include/qlc.hrl").
%% API
-export([initDB/0, registerUser/2, joinChat/2, addMessage/3, getUsers/0, getChats/0, getChatUsers/1, getChats1/1,getUsers/1, getUserMessages/2, getChatMessages/1, storeDB/2, getDB/1, getDBTwo/1, deleteDB/1, stopDB/0, infoDB/0]).
%-record(messagErl, {nodeName, comment, createdOn}).
-record(messagErl, {nodeName, chatName, userName, message, createdOn}).
-record(chatRoom, {chatName, userName}).
-record(user, {userName, password}).
-record(message, {userName, chat, msg, time}).
% nodeName can be node(), but also atom like: max.
% Initialize the mnesia data base.
initDB() ->
  mnesia:create_schema([node()]),
  mnesia:start(),
  % If mnesia table doesn't exist we create one, else we use the existing table.
  try
    mnesia:table_info(type, messagErl),
    mnesia:table_info(type, chatRoom),
    mnesia:table_info(type, user),
    mnesia:table_info(type, message)

  catch
    exit: _ ->
      mnesia:create_table(messagErl, [{attributes, record_info(fields, messagErl)},
        {type, bag},
        {disc_copies, [node()]}]),
      mnesia:create_table(chatRoom, [{attributes, record_info(fields, chatRoom)},
        {type, bag},
        {disc_copies, [node()]}]),
      mnesia:create_table(user, [{attributes, record_info(fields, user)},
        {type, bag},
        {disc_copies, [node()]}]),
      mnesia:create_table(message, [{attributes, record_info(fields, message)},
        {type, bag},
        {disc_copies, [node()]}])
  end.
%%%------------------------------Chat Initialization------------------------------%%%
registerUser(User, Pass) ->
  AF = fun() ->
    Query = qlc:q([X || X <- mnesia:table(user), (X#user.userName =:= User)]),
    Results = length(qlc:e(Query)),
    if (Results =:= 0) ->
        mnesia:write(#user{userName = User, password = Pass});
      true -> {error, "Already registered.. please login."}
    end
       end,
  mnesia:transaction(AF).

joinChat(ChatName, User) ->
  AF = fun() ->
    Query = qlc:q([X || X <- mnesia:table(user), (X#user.userName =:= User)]),
    Results = length(qlc:e(Query)),
    if (Results =:= 1) ->
        mnesia:write(#chatRoom{chatName = ChatName, userName = User});
      true -> firstRegister
    end
       end,
  mnesia:transaction(AF).

addMessage(User, ChatName, Message) ->
  AF = fun() ->
    %{CreatedOn, _} = calendar:universal_time(),
    {_, {Hour, Minute, Second}} = calendar:universal_time_to_local_time(erlang:universaltime()),
    QueryUser = qlc:q([X || X <- mnesia:table(user), (X#user.userName =:= User)]),
    QueryChat = qlc:q([X || X <- mnesia:table(chatRoom), (X#chatRoom.chatName =:= ChatName) and (X#chatRoom.userName =:= User)]),
    Results = length(qlc:e(QueryUser)) + length(qlc:e(QueryChat)),
    if (Results =:= 2) ->
      mnesia:write(#message{userName = User, chat = ChatName, msg = Message, time = {Hour, Minute, Second}});
      true -> []
    end
       end,
  mnesia:transaction(AF).
%%%-------------------------------------------------------------------------------%%%

%%%-------------------------------------------------------------------------------%%%
getUsers() ->
  AF = fun() ->
    Query = qlc:q([X || X <- mnesia:table(user)]),
    Results = qlc:e(Query),
    lists:map(fun(Item) -> Item#user.userName end, Results)
       end,
  {atomic, Comments} = mnesia:transaction(AF),
  lists:usort(Comments).

getChats() ->
  AF = fun() ->
    Query = qlc:q([X || X <- mnesia:table(chatRoom)]),
    Results = qlc:e(Query),
    lists:map(fun(Item) -> Item#chatRoom.chatName end, Results)
       end,
  {atomic, Comments} = mnesia:transaction(AF),
  lists:usort(Comments).

getChatUsers(ChatName) ->
  AF = fun() ->
    Query = qlc:q([X || X <- mnesia:table(chatRoom), X#chatRoom.chatName =:= ChatName]),
    Results = qlc:e(Query),
    lists:map(fun(Item) -> Item#chatRoom.userName end, Results)
       end,
  {atomic, Comments} = mnesia:transaction(AF),
  lists:sort(Comments).

getUserMessages(User, ChatRoom) ->
  AF = fun() ->
    Query = qlc:q([X || X <- mnesia:table(message), (X#message.userName =:= User) and (X#message.chat =:= ChatRoom)]),
    Results = qlc:e(Query),
    lists:map(fun(Item) -> {Item#message.time, Item#message.msg} end, Results)
       end,
  {atomic, Comments} = mnesia:transaction(AF),
  Comments.
%%%-------------------------------------------------------------------------------%%%






% Way to store values into the table.
storeDB(NodeName, Comment) ->
  AF = fun() ->
    {CreatedOn, _} = calendar:universal_time(),
    mnesia:write(#messagErl{nodeName = NodeName, message = Comment, createdOn = CreatedOn})
       end,
  mnesia:transaction(AF).

getChats1(NodeName) ->
  AF = fun() ->
    Query = qlc:q([X || X <- mnesia:table(messagErl), X#messagErl.nodeName =:= NodeName]),
    Results = qlc:e(Query),
    lists:map(fun(Item) -> Item#messagErl.chatName end, Results)
       end,
  {atomic, Comments} = mnesia:transaction(AF),
  Comments.

getUsers(Chat) ->
  AF = fun() ->
    Query = qlc:q([X || X <- mnesia:table(messagErl), X#messagErl.chatName =:= Chat]),
    Results = qlc:e(Query),
    lists:map(fun(Item) -> Item#messagErl.userName end, Results)
       end,
  {atomic, Comments} = mnesia:transaction(AF),
  Comments.


getChatMessages(Chat) ->
  AF = fun() ->
    Query = qlc:q([X || X <- mnesia:table(chatRoom), X#chatRoom.chatName =:= Chat]),
    Results = qlc:e(Query),
    lists:map(fun(Item) -> {Item#chatRoom.chatName, Item#chatRoom.chatName} end, Results)
       end,
  {atomic, Comments} = mnesia:transaction(AF),
  Comments.

% Get data using the node name.
getDB(NodeName) ->
  AF = fun() ->
    Query = qlc:q([X || X <- mnesia:table(messagErl), X#messagErl.nodeName =:= NodeName]),
    Results = qlc:e(Query),
    lists:map(fun(Item) -> Item#messagErl.message end, Results)
       end,
  {atomic, Comments} = mnesia:transaction(AF),
  Comments.

% Get message and createdOn.
getDBTwo(NodeName) ->
  AF = fun() ->
    Query = qlc:q([X || X <- mnesia:table(messagErl), X#messagErl.nodeName =:= NodeName]),
    Results = qlc:e(Query),
    lists:map(fun(Item) -> {Item#messagErl.message, Item#messagErl.createdOn} end, Results)
       end,
  {atomic, Comments} = mnesia:transaction(AF),
  Comments.

% Delete messages.
deleteDB(NodeName) ->
  AF = fun() ->
    Query = qlc:q([X || X <- mnesia:table(messagErl), X#messagErl.nodeName =:= NodeName]),
    Results = qlc:e(Query),

    Delete = fun() ->
      lists:foreach(fun(Result) -> mnesia:delete_object(Result) end, Results)
             end,
    mnesia:transaction(Delete)
       end,
  mnesia:transaction(AF).

infoDB() ->
  mnesia:info().
stopDB() ->
  mnesia:stop().