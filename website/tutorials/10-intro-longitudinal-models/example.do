* Tutorial 10: Intro to Longitudinal Network Models
* Run from a directory with nwcommands net-installed (not a dev checkout).

* SAOM: model network CHANGE between observed waves as a sequence
* of actor-driven "ministeps" - each activated actor may create or
* drop one outgoing tie at a time
* three yearly waves of friendship among 50 pupils (RSiena's s50 data)
nwwebuse glasgow, nwclear
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip samex(smoke1) seed(1)

* REM: model a raw, timestamped event stream directly - no snapshots,
* no aggregation into waves at all
clear
input sender receiver t
1 2 1
1 3 2
2 1 3
1 2 4
3 2 5
2 3 6
1 3 7
3 1 8
2 1 9
1 3 10
end
nwset sender receiver, eventtime(t) name(chat)
nwrem chat, nodsnd nidrec
