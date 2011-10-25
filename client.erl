-module(client).
%% Exported Functions 
-export([start/2, init_client/1]).

%% API Functions 
start(ServerPid, MyName) ->
  ClientPid = spawn(client, init_client, [ServerPid]), 
  register(client, ClientPid), 
  process_commands(ServerPid, MyName, ClientPid).

init_client(ServerPid) -> 
  ServerPid ! {client_join_req, self()},
  process_requests().

%% Local Functions
%% This is the background process logic 
process_requests() ->
receive 
     {message, Value, Name} ->
        io:format("[~s] bidded with value ~s ~n", [Name, Value]), 
        process_requests();
     {newbid, Value}->
        io:format("New bid was started with inital value ~s ~n",  [Value]), 
        process_requests();
     {win, Value}->
        io:format("Bid won with value ~s ~n",  [Value]), 
        process_requests()
end.

%% This is the main process logic 
process_commands(ServerPid, MyName, ClientPid) ->
  %% Read from standard input and send to server 
  Value = io:get_line("-> "), 
  if
   	Value == "exit\n" -> 
      	ServerPid ! {client_leave_req, MyName, ClientPid}, 
      	unregister(client);
    true ->   
      ServerPid ! {bid, MyName, Value}, 
      io:format("Sent with value ~s ~n", [Value]),
      process_commands(ServerPid, MyName, ClientPid)
  end.
