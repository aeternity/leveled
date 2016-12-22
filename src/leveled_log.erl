%% Module to abstract from choice of logger, and allow use of logReferences
%% for fast lookup

-module(leveled_log).

-include("include/leveled.hrl").

-include_lib("eunit/include/eunit.hrl").

-export([log/2,
            log_timer/3,
            put_timings/4,
            head_timings/4]).         

-define(PUT_TIMING_LOGPOINT, 10000).
-define(HEAD_TIMING_LOGPOINT, 100000).
-define(LOG_LEVEL, [info, warn, error, critical]).

-define(LOGBASE, dict:from_list([

    {"G0001",
        {info, "Generic log point"}},
    {"D0001",
        {debug, "Generic debug log"}},
    
    {"B0001",
        {info, "Bookie starting with Ink ~w Pcl ~w"}},
    {"B0002",
        {info, "Snapshot starting with Ink ~w Pcl ~w"}},
    {"B0003",
        {info, "Bookie closing for reason ~w"}},
    {"B0004",
        {info, "Length of increment in snapshot is ~w"}},
    {"B0005",
        {info, "LedgerSQN=~w at startup"}},
    {"B0006",
        {info, "Reached end of load batch with SQN ~w"}},
    {"B0007",
        {info, "Skipping as exceeded MaxSQN ~w with SQN ~w"}},
    {"B0008",
        {info, "Bucket list finds no more results"}},
    {"B0009",
        {info, "Bucket list finds Bucket ~w"}},
    {"B0010",
        {info, "Bucket list finds non-binary Bucket ~w"}},
    {"B0011",
        {warn, "Call to destroy the store and so all files to be removed"}},
    {"B0012",
        {info, "After ~w PUTs total inker time is ~w total ledger time is ~w "
                ++ "and max inker time is ~w and max ledger time is ~w"}},
    {"B0013",
        {warn, "Long running task took ~w microseconds with task of type ~w"}},
    
    {"P0001",
        {info, "Ledger snapshot ~w registered"}},
    {"P0003",
        {info, "Ledger snapshot ~w released"}},
    {"P0004",
        {info, "Remaining ledger snapshots are ~w"}},
    {"P0005",
        {info, "Delete confirmed as file ~s is removed from " ++ 
                "unreferenced files"}},
    {"P0006",
        {info, "Orphaned reply after timeout on L0 file write ~s"}},
    {"P0007",
        {debug, "Sent release message for cloned Penciller following close for "
                ++ "reason ~w"}},
    {"P0008",
        {info, "Penciller closing for reason ~w"}},
    {"P0009",
        {info, "Level 0 cache empty at close of Penciller"}},
    {"P0010",
        {info, "No level zero action on close of Penciller ~w"}},
    {"P0011",
        {info, "Shutdown complete for Penciller"}},
    {"P0012",
        {info, "Store to be started based on manifest sequence number of ~w"}},
    {"P0013",
        {warn, "Seqence number of 0 indicates no valid manifest"}},
    {"P0014",
        {info, "Maximum sequence number of ~w found in nonzero levels"}},
    {"P0015",
        {info, "L0 file found ~s"}},
    {"P0016",
        {info, "L0 file had maximum sequence number of ~w"}},
    {"P0017",
        {info, "No L0 file found"}},
    {"P0018",
        {info, "Response to push_mem of ~w with "
                    ++ "L0 pending ~w and merge backlog ~w"}},
    {"P0019",
        {info, "Rolling level zero to filename ~s"}},
    {"P0020",
        {info, "Work at Level ~w to be scheduled for ~w with ~w "
                ++ "queue items outstanding at all levels"}},
    {"P0021",
        {info, "Allocation of work blocked as L0 pending"}},
    {"P0022",
        {info, "Manifest at Level ~w"}},
    {"P0023",
        {info, "Manifest entry of startkey ~s ~s ~s endkey ~s ~s ~s "
                ++ "filename=~s~n"}},
    {"P0024",
        {info, "Outstanding compaction work items of ~w at level ~w"}},
    {"P0025",
        {info, "Merge to sqn ~w from Level ~w completed"}},
    {"P0026",
        {info, "Merge has been commmitted at sequence number ~w"}},
    {"P0027",
        {info, "Rename of manifest from ~s ~w to ~s ~w"}},
    {"P0028",
        {info, "Adding cleared file ~s to deletion list"}},
    {"P0029",
        {info, "L0 completion confirmed and will transition to not pending"}},
    {"P0030",
        {warn, "We're doomed - intention recorded to destroy all files"}},
    {"P0031",
        {info, "Completion of update to levelzero"}},
    {"P0032",
        {info, "Head timing for result ~w is count ~w total ~w and max ~w"}},
    
    {"PC001",
        {info, "Penciller's clerk ~w started with owner ~w"}},
    {"PC002",
        {info, "Request for manifest change from clerk on closing"}},
    {"PC003",
        {info, "Confirmation of manifest change on closing"}},
    {"PC004",
        {info, "Prompted confirmation of manifest change"}},
    {"PC005",
        {info, "Penciller's Clerk ~w shutdown now complete for reason ~w"}},
    {"PC006",
        {debug, "Work prompted but none needed"}},
    {"PC007",
        {info, "Clerk prompting Penciller regarding manifest change"}},
    {"PC008",
        {info, "Merge from level ~w to merge into ~w files below"}},
    {"PC009",
        {info, "File ~s to simply switch levels to level ~w"}},
    {"PC010",
        {info, "Merge to be commenced for FileToMerge=~s with MSN=~w"}},
    {"PC011",
        {info, "Merge completed with MSN=~w Level=~w and FileCounter=~w"}},
    {"PC012",
        {info, "File to be created as part of MSN=~w Filename=~s"}},
    {"PC013",
        {warn, "Merge resulted in empty file ~s"}},
    {"PC014",
        {info, "Empty file ~s to be cleared"}},
    {"PC015",
        {info, "File created"}},
    {"PC016",
        {info, "Slow fetch from SFT ~w of ~w microseconds with result ~w"}},
    
    {"I0001",
        {info, "Unexpected failure to fetch value for Key=~w SQN=~w "
                ++ "with reason ~w"}},
    {"I0002",
        {info, "Journal snapshot ~w registered at SQN ~w"}},
    {"I0003",
        {info, "Journal snapshot ~w released"}},
    {"I0004",
        {info, "Remaining number of journal snapshots is ~w"}},
    {"I0005",
        {info, "Inker closing journal for reason ~w"}},
    {"I0006",
        {info, "Close triggered with journal_sqn=~w and manifest_sqn=~w"}},
    {"I0007",
        {info, "Inker manifest when closing is:"}},
    {"I0008",
        {info, "Put to new active journal required roll and manifest write"}},
    {"I0009",
        {info, "Updated manifest on startup:"}},
    {"I0010",
        {info, "Unchanged manifest on startup:"}},
    {"I0011",
        {info, "Manifest is empty, starting from manifest SQN 1"}},
    {"I0012",
        {info, "Head manifest entry ~s is complete so new active journal "
                ++ "required"}},
    {"I0013",
        {info, "File ~s to be removed from manifest"}},
    {"I0014",
        {info, "On startup loading from filename ~s from SQN ~w"}},
    {"I0015",
        {info, "Opening manifest file at ~s with SQN ~w"}},
    {"I0016",
        {info, "Writing new version of manifest for manifestSQN=~w"}},
    {"I0017",
        {info, "At SQN=~w journal has filename ~s"}},
    {"I0018",
        {warn, "We're doomed - intention recorded to destroy all files"}},
    {"I0019",
        {info, "After ~w PUTs total prepare time is ~w total cdb time is ~w "
                ++ "and max prepare time is ~w and max cdb time is ~w"}},
    
    {"IC001",
        {info, "Closed for reason ~w so maybe leaving garbage"}},
    {"IC002",
        {info, "Clerk updating Inker as compaction complete of ~w files"}},
    {"IC003",
        {info, "No compaction run as highest score=~w"}},
    {"IC004",
        {info, "Score for filename ~s is ~w"}},
    {"IC005",
        {info, "Compaction to be performed on ~w files with score of ~w"}},
    {"IC006",
        {info, "Filename ~s is part of compaction run"}},
    {"IC007",
        {info, "Clerk has completed compaction process"}},
    {"IC008",
        {info, "Compaction source ~s has yielded ~w positions"}},
    {"IC009",
        {info, "Generate journal for compaction with filename ~s"}},
    {"IC010",
        {info, "Clearing journal with filename ~s"}},
    {"IC011",
        {info, "Not clearing filename ~s as modified delta is only ~w seconds"}},
    {"IC012",
        {warn, "Tag ~w not found in Strategy ~w - maybe corrupted"}},
    {"IC013",
        {warn, "File with name ~s to be ignored in manifest as scanning for "
                ++ "first key returned empty - maybe corrupted"}},
    
    {"PM002",
        {info, "Completed dump of L0 cache to list of size ~w"}},
    
    
    {"SFT01",
        {info, "Opened filename with name ~s"}},
    {"SFT02",
        {info, "File ~s has been set for delete"}},
    {"SFT03",
        {info, "File creation of L0 file ~s"}},
    {"SFT04",
        {debug, "File ~s prompting for delete status check"}},
    {"SFT05",
        {info, "Exit called for reason ~w on filename ~s"}},
    {"SFT06",
        {info, "Exit called and now clearing ~s"}},
    {"SFT07",
        {info, "Creating file with input of size ~w"}},
    {"SFT08",
        {info, "Renaming file from ~s to ~s"}},
    {"SFT09",
        {warn, "Filename ~s already exists"}},
    {"SFT10",
        {warn, "Rename rogue filename ~s to ~s"}},
    {"SFT11",
        {error, "Segment filter failed due to ~s"}},
    {"SFT12",
        {error, "Segment filter failed due to CRC check ~w did not match ~w"}},
    {"SFT13",
        {error, "Segment filter failed due to ~s"}},
    {"SFT14",
        {info, "Range fetch from SFT PID ~w"}},
    
    {"CDB01",
        {info, "Opening file for writing with filename ~s"}},
    {"CDB02",
        {info, "Opening file for reading with filename ~s"}},
    {"CDB03",
        {info, "Re-opening file for reading with filename ~s"}},
    {"CDB04",
        {info, "Deletion confirmed for file ~s at ManifestSQN ~w"}},
    {"CDB05",
        {info, "Closing of filename ~s for Reason ~w"}},
    {"CDB06",
        {info, "File to be truncated at last position of ~w with end of "
                ++ "file at ~w"}},
    {"CDB07",
        {info, "Hashtree computed"}},
    {"CDB08",
        {info, "Renaming file from ~s to ~s for which existence is ~w"}},
    {"CDB09",
        {info, "Failure to read Key/Value at Position ~w in scan"}},
    {"CDB10",
        {info, "CRC check failed due to mismatch"}},
    {"CDB11",
        {info, "CRC check failed due to size"}},
    {"CDB12",
        {info, "HashTree written"}},
    {"CDB13",
        {info, "Write options of ~w"}},
    {"CDB14",
        {info, "Microsecond timings for hashtree build of "
                ++ "to_list ~w sort ~w build ~w"}},
    {"CDB15",
        {info, "Cycle count of ~w in hashtable search higher than expected"
                ++ " in search for hash ~w with result ~w"}},
    {"CDB16",
        {info, "CDB scan from start ~w in file with end ~w and last_key ~w"}},
    {"CDB17",
        {info, "After ~w PUTs total write time is ~w total sync time is ~w "
                ++ "and max write time is ~w and max sync time is ~w"}}
        ])).


log(LogReference, Subs) ->
    {ok, {LogLevel, LogText}} = dict:find(LogReference, ?LOGBASE),
    case lists:member(LogLevel, ?LOG_LEVEL) of
        true ->
            io:format(LogReference ++ " ~w " ++ LogText ++ "~n",
                        [self()|Subs]);
        false ->
            ok
    end.


log_timer(LogReference, Subs, StartTime) ->
    {ok, {LogLevel, LogText}} = dict:find(LogReference, ?LOGBASE),
    case lists:member(LogLevel, ?LOG_LEVEL) of
        true ->
            MicroS = timer:now_diff(os:timestamp(), StartTime),
            {Unit, Time} = case MicroS of
                                MicroS when MicroS < 1000 ->
                                    {"microsec", MicroS};
                                MicroS ->
                                    {"ms", MicroS div 1000}
                            end,
            io:format(LogReference ++ " ~w " ++ LogText
                            ++ " with time taken ~w " ++ Unit ++ "~n",
                        [self()|Subs] ++ [Time]);
        false ->
            ok
    end.

%% Make a log of put timings split out by actor - one log for every
%% PUT_TIMING_LOGPOINT puts

put_timings(Actor, {?PUT_TIMING_LOGPOINT, {Total0, Total1}, {Max0, Max1}}, T0, T1) ->
    LogRef =
        case Actor of
            bookie -> "B0012";
            inker -> "I0019";
            journal -> "CDB17"
        end,
    log(LogRef, [?PUT_TIMING_LOGPOINT, Total0, Total1, Max0, Max1]),
    {1, {T0, T1}, {T0, T1}};
put_timings(_Actor, {N, {Total0, Total1}, {Max0, Max1}}, T0, T1) ->
    {N + 1, {Total0 + T0, Total1 + T1}, {max(Max0, T0), max(Max1, T1)}}.

%% Make a log of penciller head timings split out by level and result - one
%% log for every HEAD_TIMING_LOGPOINT puts
%% Returns a tuple of {Count, TimingDict} to be stored on the process state

head_timings(HeadTimer, SW, Level, R) ->
    T0 = timer:now_diff(os:timestamp(), SW),
    head_timings_int(HeadTimer, T0, Level, R).

head_timings_int(undefined, T0, Level, R) -> 
    Key = head_key(R, Level),
    NewDFun = fun(K, Acc) ->
                case K of
                    Key ->
                        dict:store(K, [1, T0, T0], Acc);
                    _ ->
                        dict:store(K, [0, 0, 0], Acc)
                end end,
    {1, lists:foldl(NewDFun, dict:new(), head_keylist())};
head_timings_int({?HEAD_TIMING_LOGPOINT, HeadTimingD}, T0, Level, R) ->
    LogFun  = fun(K) -> log("P0032", [K|dict:fetch(K, HeadTimingD)]) end,
    lists:foreach(LogFun, head_keylist()),
    head_timings_int(undefined, T0, Level, R);
head_timings_int({N, HeadTimingD}, T0, Level, R) ->
    Key = head_key(R, Level),
    [Count0, Total0, Max0] = dict:fetch(Key, HeadTimingD),
    {N + 1,
        dict:store(Key, [Count0 + 1, Total0 + T0, max(Max0, T0)],
        HeadTimingD)}.
                                    
head_key(not_present, _Level) ->
    not_present;
head_key(found, 0) ->
    found_0;
head_key(found, 1) ->
    found_1;
head_key(found, 2) ->
    found_2;
head_key(found, Level) when Level > 2 ->
    found_lower.

head_keylist() ->
    [not_present, found_lower, found_0, found_1, found_2].

%%%============================================================================
%%% Test
%%%============================================================================



-ifdef(TEST).

log_test() ->
    log("D0001", []),
    log_timer("D0001", [], os:timestamp()).

head_timing_test() ->
    SW = os:timestamp(),
    HeadTimer0 = head_timings(undefined, SW, 2, found),
    HeadTimer1 = head_timings(HeadTimer0, SW, 2, found),
    HeadTimer2 = head_timings(HeadTimer1, SW, 3, found),
    {N, D} = HeadTimer2,
    ?assertMatch(3, N),
    ?assertMatch(2, lists:nth(1, dict:fetch(found_2, D))),
    ?assertMatch(1, lists:nth(1, dict:fetch(found_lower, D))).

-endif.