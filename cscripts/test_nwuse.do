cscript

do unw_core.do

nwclear
nwrandom 7, density(1) name(mynet) 

tempfile f
nwsave `f'
nwclear
nwset
assert         r(networks) == 0

capture nwuse `f'
nwset
assert `"`r(nets)'"' == `" mynet"'
assert         r(networks) == 1

capture nwuse `f'
assert _rc != 0

nwwebuse florentine, nwappend
assert _rc == 0
nwset

assert `"`r(nets)'"' == `" mynet flobusiness flomarriage"'

assert         r(networks) == 3

* --- hpotter/usstates/klas12b: these three example datasets were stuck
* in the legacy pre-.nwdta save format (bare _format/_nets/... Stata
* variables, the same format nwuse_old.ado - archived to old/ado/, never
* reachable from the live adopath - used to read) and silently loaded as
* plain Stata datasets instead of real saved networks (a user-reported
* bug: `nwwebuse hpotter' printed "plain Stata dataset loaded - not a
* saved network file" instead of restoring hpbook1-6). Migrated to
* proper .nwdta files (data/hpotter.nwdta/usstates.nwdta/klas12b.nwdta),
* using the local files directly here (not nwwebuse) so this test needs
* no network access and is unaffected by $nwwebpath.
nwclear
nwuse data/hpotter, nwclear
nwset
assert r(networks) == 6
assert `"`r(nets)'"' == `" hpbook1 hpbook2 hpbook3 hpbook4 hpbook5 hpbook6"'
qui nwsummarize hpbook1
assert r(nodes) == 64
confirm variable schoolyear gender house

nwclear
nwuse data/usstates, nwclear
nwset
assert r(networks) == 1
assert `"`r(nets)'"' == `" usstates"'

nwclear
nwuse data/klas12b, nwclear
nwset
assert r(networks) == 5
assert `"`r(nets)'"' == `" klas12b_primary klas12b_wave1 klas12b_wave2 klas12b_wave3 klas12b_wave4"'
confirm variable delinq1 delinq2 delinq3 delinq4 alcohol2 alcohol3 alcohol4 sex age ethnicity religion advice

