* test_nwstrcat: string variables in categorical options (3.20.1) give the same
* results as their encoded versions and leave the data as they were; options that
* use values as numbers refuse strings with an error
* Run from the repository root.
cscript

do unw_core.do

nwuse data/lazega, nwclear
encode office, generate(officen)
nwduplicate lazega_adv, name(adv_u)
nwsym adv_u

describe, varlist
local vars0 `r(varlist)'
datasignature
local sig0 `r(datasignature)'

* _nwstrcat on its own: the encoded variable has the original name, label and place
label variable office "Office (string)"
datasignature
local sig0 `r(datasignature)'
_nwstrcat office : assert office == officen
_nwstrcat office : assert "`: variable label office'" == "Office (string)"
_nwstrcat office : confirm numeric variable office
confirm string variable office
* the return code of the command is passed on, and the data are restored
capture _nwstrcat office : error 459
assert _rc == 459
confirm string variable office
* numeric variables and repeated names are left alone
_nwstrcat officen officen : summarize officen

* nwbrokerage group()
nwbrokerage lazega_adv, group(officen) generate(bn)
local pn = r(pairs)
nwbrokerage lazega_adv, group(office) generate(bs)
assert r(pairs) == `pn'
foreach r in coordinator gatekeeper representative consultant liaison {
	assert bn_`r' == bs_`r'
}
confirm string variable office
drop bn_* bs_*

* nwmodularity group()
nwmodularity adv_u, group(officen)
local qn = r(modularity)
nwmodularity adv_u, group(office)
assert reldif(r(modularity), `qn') < 1e-12

* nwtabulate attribute()
nwtabulate lazega_adv, attribute(officen)
matrix tn = r(table)
local ein = r(EI_index)
nwtabulate lazega_adv, attribute(office)
assert mreldif(r(table), tn) == 0
assert r(EI_index) == `ein'
assert "`r(attribute)'" == "office"

* nwhomophily: a string attribute is counted and expanded (mode(same))
set seed 1
nwhomophily officen, homophily(2) density(.1) mode(same) name(hn)
set seed 1
nwhomophily office, homophily(2) density(.1) mode(same) name(hs)
nwcorrelate hn hs
assert reldif(r(corr), 1) < 1e-12

* nwcontext uses the values as numbers: a string gives an error, not an empty variable
rcof "nwcontext lazega_adv, attribute(office) generate(ctx)" == 109
capture confirm variable ctx
assert _rc

* the data are as they were (nwhomophily leaves its helper _nwinclude, also with numeric variables)
capture drop _nwinclude
describe, varlist
assert "`r(varlist)'" == "`vars0'"
datasignature
assert "`r(datasignature)'" == "`sig0'"
confirm string variable office

di "test_nwstrcat: all passed"
