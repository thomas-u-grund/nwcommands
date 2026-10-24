* Tutorial 10: Intro to Longitudinal Network Models
* Requires the core nwcommands and the packages nwsaom, nwrem and nwdynam.

nwsaom version
nwrem version
nwdynam version

* SAOM: three yearly waves of friendship among 50 pupils (RSiena's s50 data)
nwwebuse glasgow, nwclear
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip samex(smoke1) seed(1)

* Does an effect change over time?
estat timetest

* How much does each effect matter for the actors' choices?
estat importance

* REM: a raw, timestamped event stream
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
nwset sender receiver, directed eventtime(t) name(chat)
nwrem chat, nodsnd nidrec

* DyNAM on the same (directed) event log: who initiates the next event?
nwdynam chat, submodel(rate)
