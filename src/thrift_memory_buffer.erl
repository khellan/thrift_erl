%%
%% Licensed to the Apache Software Foundation (ASF) under one
%% or more contributor license agreements. See the NOTICE file
%% distributed with this work for additional information
%% regarding copyright ownership. The ASF licenses this file
%% to you under the Apache License, Version 2.0 (the
%% "License"); you may not use this file except in compliance
%% with the License. You may obtain a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied. See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%

-module(thrift_memory_buffer).

-behaviour(thrift_transport).

% Avoiding warning of ambiguous call of overridden auto-imported BIF min/2
% since there is local min in this module.
-compile({no_auto_import,[min/2]}).

%% API
-export([new/0, new/1, new_transport_factory/0]).

%% thrift_transport callbacks
-export([write/2, read/2, flush/1, close/1]).

-record(memory_buffer, {buffer}).
-type state() :: #memory_buffer{}.
-include("thrift_transport_behaviour.hrl").

new() ->
    State = #memory_buffer{buffer = []},
    thrift_transport:new(?MODULE, State).

new (Buf) when is_list (Buf) ->
  State = #memory_buffer{buffer = Buf},
  thrift_transport:new(?MODULE, State);
new (Buf) ->
  State = #memory_buffer{buffer = [Buf]},
  thrift_transport:new(?MODULE, State).

new_transport_factory() ->
    {ok, fun() -> new() end}.

%% Writes data into the buffer
write(State = #memory_buffer{buffer = Buf}, Data) ->
    {State#memory_buffer{buffer = [Buf, Data]}, ok}.

flush(State = #memory_buffer {buffer = Buf}) ->
    {State#memory_buffer{buffer = []}, Buf}.

close(State) ->
    {State, ok}.

read(State = #memory_buffer{buffer = Buf}, Len) when is_integer(Len) ->
    Binary = iolist_to_binary(Buf),
    Give = min(iolist_size(Binary), Len),
    {Result, Remaining} = split_binary(Binary, Give),
    {State#memory_buffer{buffer = Remaining}, {ok, Result}}.

%%--------------------------------------------------------------------
%% Internal functions
%%--------------------------------------------------------------------
min(A,B) when A<B -> A;
min(_,B)          -> B.

