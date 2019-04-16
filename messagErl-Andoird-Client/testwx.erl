-module(testwx).

-behaviour(wx_object).

%% Client API
-export([start/0, start/1]).

%% wx_object callbacks
-export([init/1, terminate/2,  code_change/3,
  handle_info/2, handle_call/3, handle_cast/2, handle_event/2, loop/1, updateGrid/1]).

-include_lib("wx/include/wx.hrl").

-record(state,
{
  parent,
  config,
  grid
}).

start() ->
  Wx = wx:new(),
  %Test = start([]),
  F = wxFrame:new(Wx, -1, "messagErl Data Base"),
  %wxFrame:show(F).
  start(F),
  wxFrame:show(F).
	%spawn_link(?MODULE, loop, [F]).

loop(F) ->
io:format("[~w]GRID: entering start. ~n", [self()]),
 DBFile = db:getUserMessages(panel, panelChat),
            BINFile = element(2, hd(DBFile)),
updateGrid(BINFile),
%start(F),
%wxGrid:setCellValue(Grid, Row, 1, integer_to_list(length(db:getChats()))),
%wx:batch(fun() -> do_init(F) end),
timer:sleep(2000),
io:format("GRID: entering loop. ~n"),
loop(F).

start(Config) ->
  wx_object:start_link(?MODULE, Config, []).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
init(Config) ->
  wx:batch(fun() -> do_init(Config) end).

do_init(Config) ->
  %Parent = proplists:get_value(parent, Config),
  %Panel = wxPanel:new(Parent, []),
  Panel = wxPanel:new(Config, []),

  %% Setup sizers
  MainSizer = wxBoxSizer:new(?wxVERTICAL),
  Sizer = wxStaticBoxSizer:new(?wxVERTICAL, Panel,
    [{label, "Statistics"}]),

	%db:registerUser(panel, 123),
	%db:joinChat(panelChat, panel),
	%db:addMessage(msg, panel, panelChat, Panel),

  Grid = create_grid(Panel),

  %% Add to sizers
  Options = [{flag, ?wxEXPAND}, {proportion, 1}],

  wxSizer:add(Sizer, Grid, Options),
  wxSizer:add(MainSizer, Sizer, Options),

  wxPanel:setSizer(Panel, MainSizer),
  {Panel, #state{parent=Panel, config=Config, grid = Grid}}.
	

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Async Events are handled in handle_event as in handle_info
handle_event(#wx{event = #wxGrid{type = grid_cell_change,
  row = Row, col = Col}},
    State = #state{}) ->
  Val = wxGrid:getCellValue(State#state.grid, Row, Col),
  demo:format(State#state.config, "Cell {~p,~p} changed to ~p.\n",
    [Row,Col,Val]),
  {noreply, State}.

%% Callbacks handled as normal gen_server callbacks
handle_info(_Msg, State) ->
  {noreply, State}.

handle_call(shutdown, _From, State=#state{parent=Panel}) ->
  wxPanel:destroy(Panel),
  {stop, normal, ok, State};

handle_call(_Msg, _From, State) ->
  {reply,{error, nyi}, State}.

handle_cast(Msg, State) ->
  io:format("Got cast ~p~n",[Msg]),
  {noreply,State}.

code_change(_, _, State) ->
  {stop, ignore, State}.

terminate(_Reason, _State) ->
  ok.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Local functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

create_grid(Panel) ->
  %% Create the grid with 100 * 5 cells
  Grid = wxGrid:new(Panel, 2, []),
  wxGrid:createGrid(Grid, 4, 5),

  Font = wxFont:new(16, ?wxFONTFAMILY_SWISS,
    ?wxFONTSTYLE_NORMAL,
    ?wxFONTWEIGHT_NORMAL, []),
  %% Fun to set the values and flags of the cells
  Fun =
    fun(Row) ->
      wxGrid:setCellValue(Grid, Row, 0, " "),
      wxGrid:setCellValue(Grid, Row, 1, " "),
      wxGrid:setCellValue(Grid, Row, 2, " "),
      wxGrid:setCellValue(Grid, Row, 3, " "),
      wxGrid:setCellTextColour(Grid, Row, 3, ?wxWHITE),
      wxGrid:setReadOnly(Grid, Row, 3, [{isReadOnly,true}]),
      wxGrid:setCellValue(Grid, Row, 4, " "),
      case Row rem 4 of
        0 -> wxGrid:setCellBackgroundColour(Grid, Row, 2, ?wxWHITE),
          wxGrid:setCellValue(Grid, Row, 0, "Chats"),
          %wxGrid:setCellValue(Grid, Row, 0, length(db:getChats()));
          wxGrid:setCellValue(Grid, Row, 1, integer_to_list(length(db:getChats())));
        1 -> wxGrid:setCellBackgroundColour(Grid, Row, 3, ?wxWHITE),
          wxGrid:setCellTextColour(Grid, Row, 2, {255,215,0,255}),
          wxGrid:setCellValue(Grid, Row, 0, "Users"),
          wxGrid:setCellValue(Grid, Row, 1, integer_to_list(length(db:getUsers())));
        2 -> wxGrid:setCellBackgroundColour(Grid, Row, 3, ?wxWHITE),
          wxGrid:setCellValue(Grid, Row, 0, "Messages"),
          wxGrid:setCellValue(Grid, Row, 1, integer_to_list(length(db:getUsers())));
        _ -> wxGrid:setCellBackgroundColour(Grid, Row, 1, ?wxWHITE),
          wxGrid:setCellValue(Grid, Row, 1,
            " "),
          wxGrid:setCellAlignment(Grid, Row, 4,
            0,?wxALIGN_CENTER),
          wxGrid:setCellValue(Grid, Row, 4,
            " "),
          wxGrid:setCellValue(Grid, Row, 1,
            " "),
          wxGrid:setCellAlignment(Grid, Row, 1,
            ?wxALIGN_CENTER,0),
          wxGrid:setCellTextColour(Grid, Row, 3, ?wxWHITE),
          wxGrid:setCellAlignment(Grid, Row, 2,
            ?wxALIGN_CENTER,
            ?wxALIGN_CENTER),
          wxGrid:setCellFont(Grid, Row, 0, Font),
          wxGrid:setCellValue(Grid, Row, 2,
            " "),
          wxGrid:setRowSize(Grid, Row, 80)
      end
    end,
  %% Apply the fun to each row
  wx:foreach(Fun, lists:seq(0,3)),
  wxGrid:setColSize(Grid, 2, 150),
  wxGrid:connect(Grid, grid_cell_change),
  Grid.





updateGrid(Panel) ->
  %% Create the grid with 100 * 5 cells
  Grid = wxGrid:new(Panel, 2, []),
  wxGrid:createGrid(Grid, 4, 5),

  Font = wxFont:new(16, ?wxFONTFAMILY_SWISS,
    ?wxFONTSTYLE_NORMAL,
    ?wxFONTWEIGHT_NORMAL, []),
  %% Fun to set the values and flags of the cells
  Fun =
    fun(Row) ->
      wxGrid:setCellValue(Grid, Row, 0, " "),
      wxGrid:setCellValue(Grid, Row, 1, " "),
      wxGrid:setCellValue(Grid, Row, 2, " "),
      wxGrid:setCellValue(Grid, Row, 3, " "),
      wxGrid:setCellTextColour(Grid, Row, 3, ?wxWHITE),
      wxGrid:setReadOnly(Grid, Row, 3, [{isReadOnly,true}]),
      wxGrid:setCellValue(Grid, Row, 4, " "),
      case Row rem 4 of
        0 -> wxGrid:setCellBackgroundColour(Grid, Row, 2, ?wxWHITE),
          wxGrid:setCellValue(Grid, Row, 0, "Chats"),
          %wxGrid:setCellValue(Grid, Row, 0, length(db:getChats()));
          wxGrid:setCellValue(Grid, Row, 1, integer_to_list(length(db:getChats())));
        1 -> wxGrid:setCellBackgroundColour(Grid, Row, 3, ?wxWHITE),
          wxGrid:setCellTextColour(Grid, Row, 2, {255,215,0,255}),
          wxGrid:setCellValue(Grid, Row, 0, "Users"),
          wxGrid:setCellValue(Grid, Row, 1, integer_to_list(length(db:getUsers())));
        2 -> wxGrid:setCellBackgroundColour(Grid, Row, 3, ?wxWHITE),
          wxGrid:setCellValue(Grid, Row, 0, "Messages"),
          wxGrid:setCellValue(Grid, Row, 1, integer_to_list(length(db:getUsers())));
        _ -> wxGrid:setCellBackgroundColour(Grid, Row, 1, ?wxWHITE),
          wxGrid:setCellValue(Grid, Row, 1,
            " "),
          wxGrid:setCellAlignment(Grid, Row, 4,
            0,?wxALIGN_CENTER),
          wxGrid:setCellValue(Grid, Row, 4,
            " "),
          wxGrid:setCellValue(Grid, Row, 1,
            " "),
          wxGrid:setCellAlignment(Grid, Row, 1,
            ?wxALIGN_CENTER,0),
          wxGrid:setCellTextColour(Grid, Row, 3, ?wxWHITE),
          wxGrid:setCellAlignment(Grid, Row, 2,
            ?wxALIGN_CENTER,
            ?wxALIGN_CENTER),
          wxGrid:setCellFont(Grid, Row, 0, Font),
          wxGrid:setCellValue(Grid, Row, 2,
            " "),
          wxGrid:setRowSize(Grid, Row, 80)
      end
    end,
  %% Apply the fun to each row
  wx:foreach(Fun, lists:seq(0,3)),
  wxGrid:setColSize(Grid, 2, 150),
  wxGrid:connect(Grid, grid_cell_change),
  Grid.



