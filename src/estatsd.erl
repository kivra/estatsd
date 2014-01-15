-module(estatsd).

-export([
         increment/1, increment/2, increment/3,
         decrement/1, decrement/2, decrement/3,
         timing/2, gauge/2
        ]).

-define(SERVER, estatsd_server).

% Convenience: just give it the now() tuple when the work started
timing(Key, StartTime = {_,_,_}) ->
    timing(Key, erlang:round(timer:now_diff(os:timestamp(), StartTime)/1000));

% Log timing information, ms
timing(Key, Duration) when is_integer(Duration) ->
    do_cast(fun() -> gen_server:cast(?SERVER, {timing, Key, Duration}) end);
timing(Key, Duration) ->
    do_cast(fun() ->
                gen_server:cast(?SERVER, {timing, Key, erlang:round(Duration)})
            end).

gauge(Key, Value) when is_integer(Value); is_float(Value) ->
    do_cast(fun() -> gen_server:cast(?SERVER, {gauge, Key, Value}) end).

% Increments one or more stats counters
increment(Key)                 -> increment(Key, 1, 1).
increment(Key, Amount)         -> increment(Key, Amount, 1).
increment(Key, Amount, Sample) ->
    do_cast(fun() ->
                gen_server:cast(?SERVER, {increment, Key, Amount, Sample})
            end).

decrement(Key)                 -> decrement(Key, -1, 1).
decrement(Key, Amount)         -> decrement(Key, Amount, 1).
decrement(Key, Amount, Sample) -> increment(Key, 0 - Amount, Sample).

do_cast(F) ->
    case estatsd_sup:appvar(enabled, true) of
        true  -> F();
        false -> ok
    end.
