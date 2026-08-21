cscript

do unw_core.do

nwclear


// Check weighted clustering coefficient accoridng to Opsahl & Panzarasa (2009, p. 157)

set obs 6
gen ego = ""
gen alter = ""
gen value = .

replace ego = "A" in 1/2
replace alter = "B" in 1
replace alter = "C" in 2
replace value = 4 in 1
replace value = 2 in 2
replace ego = "C" in 3
replace alter = "B" in 3/5
replace value = 4 in 3
replace ego = "D" in 4
replace value = 1 in 4
replace ego = "E" in 5/6
replace value = 2 in 5
replace alter = "F" in 6
replace value = 1 in 6

nwfromedge _all, undirected


