* generate(fac) must not delete an existing variable "faction": Stata's drop accepts unique
* abbreviations, so every generate-style "capture drop" is guarded by "capture confirm new variable".
cscript
set graphics off
clear
set obs 8
nwclear
nwset, mat((0,1,1,0,0,0,0,0\1,0,1,0,0,0,0,0\1,1,0,1,0,0,0,0\0,0,1,0,1,0,0,0\0,0,0,1,0,1,1,0\0,0,0,0,1,0,1,1\0,0,0,0,1,1,0,1\0,0,0,0,0,1,1,0)) name(g) undirected
local bad ""
foreach cmd in "nwfactions g, groups(2)" "nwkcore g" "nwcomponents g" "nwcommunity g" "nwcoreperiphery g" "nwclustering g" "nwbetween g" {
    capture drop faction
    quietly generate faction = 42
    capture quietly `cmd' generate(fac)
    if _rc capture quietly `cmd', generate(fac)
    capture confirm variable faction
    if _rc local bad `bad' [`cmd']
    else {
        quietly count if faction != 42
        if r(N) > 0 local bad `bad' [`cmd']
    }
}
if "`bad'" != "" {
    display as error "FAIL: abbreviation drop removed or changed 'faction' in: `bad'"
    exit 9
}
display "PASS test_dropabbrev"
