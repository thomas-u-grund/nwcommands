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

* --- lazega/s50/sampson/mesa: sourced from real R packages (ergm.multi's
* own Lazega, RSiena's own s501/s502/s503/s50a/s50s, ergm's own
* samplk/sampson and faux.mesa.high), not typed from memory - each
* checked directly against known published/re-derivable statistics
* (Lazega's own 53 men/18 women and 36 partners/35 associates split;
* s50's own wave-1 113-tie count; samplk1's own 55-tie/samplike's own
* 88-tie count; faux.mesa.high's own 205-node/203-edge/57-isolate
* structure) before being trusted, converted to .nwdta the same way
* hpotter/usstates/klas12b were above.
nwclear
nwuse data/lazega, nwclear
nwset
assert r(networks) == 3
assert `"`r(nets)'"' == `" lazega_adv lazega_cow lazega_fr"'
confirm variable age gender office practice school seniority status yrs_frm
qui nwsummarize lazega_adv
assert r(nodes) == 71

nwclear
nwuse data/s50, nwclear
nwset
assert r(networks) == 3
assert `"`r(nets)'"' == `" s50_w1 s50_w2 s50_w3"'
confirm variable alcohol1 alcohol2 alcohol3 smoke1 smoke2 smoke3
qui nwsummarize s50_w1
assert r(nodes) == 50
assert r(edges) == 113 | r(arcs) == 113

nwclear
nwuse data/sampson, nwclear
nwset
assert r(networks) == 4
assert `"`r(nets)'"' == `" samplk1 samplk2 samplk3 samplike"'
confirm variable faction cloisterville
qui nwsummarize samplike
assert r(nodes) == 18
assert r(arcs) == 88

nwclear
nwuse data/mesa, nwclear
nwset
assert r(networks) == 1
assert `"`r(nets)'"' == `" mesa"'
confirm variable grade race sex
qui nwsummarize mesa
assert r(nodes) == 205
assert r(edges) == 203

