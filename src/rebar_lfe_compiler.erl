%% -*- erlang-indent-level: 4;indent-tabs-mode: nil -*-
%% ex: ts=4 sw=4 et
%% -------------------------------------------------------------------
%%
%% rebar: Erlang Build Tools
%%
%% Copyright (c) 2009 Dave Smith (dizzyd@dizzyd.com),
%%                    Tim Dysinger (tim@dysinger.net)
%%
%% Permission is hereby granted, free of charge, to any person obtaining a copy
%% of this software and associated documentation files (the "Software"), to deal
%% in the Software without restriction, including without limitation the rights
%% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
%% copies of the Software, and to permit persons to whom the Software is
%% furnished to do so, subject to the following conditions:
%%
%% The above copyright notice and this permission notice shall be included in
%% all copies or substantial portions of the Software.
%%
%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
%% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
%% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
%% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
%% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
%% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
%% THE SOFTWARE.
%% -------------------------------------------------------------------

-module(rebar_lfe_compiler).

-export([compile/2]).

-export([dotlfe_compile/3]).

-include("rebar.hrl").

%% ===================================================================
%% Public API
%% ===================================================================

compile(Config, _AppFile) ->
    FirstFiles = rebar_config:get_list(Config, lfe_first_files, []),
    rebar_base_compiler:run(Config, FirstFiles, "src", ".lfe", "ebin", ".beam",
                            fun compile_lfe/3).

%% ===================================================================
%% .lfe Compilation API (externally used by only eunit)
%% ===================================================================

dotlfe_compile(Config, OutDir, Sources) ->
    FirstFiles = rebar_config:get_list(Config, lfe_first_files, []),
    LfeOpts = [{outdir, OutDir}] ++ rebar_config:get(Config, lfe_opts, []) ++
        [{i, "include"}, report, return],
    ?DEBUG("lfe_opts ~p~n",[LfeOpts]),
    rebar_base_compiler:run(Config, FirstFiles, Sources,
                            fun(S, _C) ->
                                    compile_lfe(S, LfeOpts)
                            end),
    ok.

%% ===================================================================
%% Internal functions
%% ===================================================================

compile_lfe(Source, _Target, Config) ->
    LfeOpts = rebar_config:get_list(Config, lfe_opts, []) ++
        [{i, "include"}, {outdir, "ebin"}, report, return],
    ?DEBUG("lfe_opts ~p~n",[LfeOpts]),
    compile_lfe(Source, LfeOpts).

compile_lfe(Source, LfeOpts) ->
    case code:which(lfe_comp) of
        non_existing ->
            ?CONSOLE(
               <<"~n===============================================~n"
                 " You need to install LFE to compile LFE source files~n"
                 "Download the latest tarball release from github~n"
                 "   https://github.com/rvirding/lfe/downloads~n"
                 "  and install it into your erlang library dir~n"
                 "===============================================~n~n">>, []),
            ?FAIL;
        _ ->
            case lfe_comp:file(Source, LfeOpts) of
                {ok, _, []} -> ok;
                _ -> ?FAIL
            end
    end.
