-module(agent).
-define(timeout, 60000).
-export([start/0,process_requests/3]).

start()->
    register(agent, spawn(fun()->process_requests(random:uniform(1000),[],0) end)).

process_requests(Bid, Clients,NumBids)->
    io:format("A new bid is started with value ~w ~n",[Bid]),
    receive
      {client_join_req, From } ->
        UpdatedClients = [ From | Clients],
        %broadcast(UpdatedClients,{join,Name}),
        process_requests(Bid, UpdatedClients,0);

      {bid,Name,Value}->
            if
                Value > Bid->
                    broadcast(Clients, {message,Value, Name}), %sending all the clients the proposed value by Name, which wins up to now
                    io:format("[Agent] New Bid Value ~s by ~s ~n", [Value, Name]),
                    process_requests(Clients, Value,1);
                true->
                    %broadcast(Clients, {Value,Name, notwin}), %sending all the clients the proposed value by Name, which didnotwin
                    process_requests(Clients, Bid,1)
            end
       after ?timeout->
            if
                NumBids > 0 ->
                    io:format("Bid won with value ~w",[Bid]);
                true->
                    NewBid = (Bid /2),
                    process_requests(NewBid,Clients,0)
            end
    end.
    
broadcast(PeerList, Message)->
  SMTP = fun(Peer) -> Peer ! Message end,
  lists:map(SMTP, PeerList).
