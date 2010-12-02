-module(agent).
-define(timeout, 60000).
-export([start/0,process_requests/3, stop/0]).

start()->
    register(agent, spawn(fun()->process_requests(random:uniform(1000),[],0) end)).
stop()->
    unregister(agent).
process_requests( Bid, Clients, NumBids)->
    receive
      {client_join_req, From } ->
        UpdatedClients = [ From | Clients],
        io:format("[Agent] New client joined auction ~w ~n",[From]),
        process_requests( Bid, UpdatedClients, NumBids);
      {client_leave_req, From } ->
        UpdatedClients = lists:delete(From,Clients),
        process_requests(Bid, UpdatedClients, NumBids);
      {bid, Name, Value}->
         if
                Value > Bid->
                    broadcast(Clients, {message, Value, Name}), %sending all the clients the proposed value by Name, which wins up to now
                    io:format("[Agent] New Bid Value ~s by ~s ~n", [Value, Name]),
                    process_requests( Value, Clients, 1);
                true->
                    process_requests( Bid, Clients , 1)
        end
       after ?timeout->
            if
                NumBids > 0 ->
                    broadcast(Clients, {win, Bid}),
                    io:format("[Agent] Auction over: Won with value ~w ",[Bid]);
                true->
                    NewBid = (Bid /2),
                    io:format("[Agent] A new auction is started with value ~w ~n",[NewBid]),
                    broadcast( Clients, {newbid, NewBid}),
                    process_requests(NewBid, Clients ,0)
            end
    end.
    
broadcast(PeerList, Message)->
  SMTP = fun(Peer) -> Peer ! Message end,
  lists:map(SMTP, PeerList).
