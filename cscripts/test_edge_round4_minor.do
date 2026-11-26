* edge round 4: smaller messages and option checks
clear all
do unw_core.do

capture program drop _rc_is
program _rc_is
	gettoken want cmd : 0
	capture noisily `cmd'
	if _rc != `want' {
		di as err "return code " _rc ", expected `want': `cmd'"
		exit 9
	}
end
capture program drop _says
program _says
	gettoken want cmd : 0
	tempfile lf
	quietly log using "`lf'", text replace name(r4n)
	`cmd'
	quietly log close r4n
	mata: assert(__found(st_local("lf"), st_local("want")) > 0)
end
mata:
real scalar __found(string scalar fn, string scalar want)
{
	string colvector L
	L = cat(fn)
	if (length(L) == 0) return(0)
	return(sum(strpos(L, want) :> 0))
}
end

nwclear
set seed 5
nwrandom 8, prob(.4) name(a) undirected
nwrandom 8, prob(.4) name(b) undirected
_rc_is 3499 nwgenerate q = a + nothere
_rc_is 3499 nwreplace a = nothere
_rc_is 2000 nwgenerate z = a + b if 1==0
_rc_is 198 nwqap a b, permutations(10) type(foo)
_rc_is 198 nwqap a b, permutations(10) mode(foo)
nwqap a b, permutations(10)
_rc_is 198 nwcorrelate a b, permutations(-5)
nwcorrelate a b, permutations(10) noplot
_rc_is 198 nwconstraint a, directed undirected
nwconstraint a, name(con) 
gen attr = mod(_n, 2) in 1/8
_rc_is 198 nwhomophily attr, density(1.3) homophily(4)
_says "negative alpha()" nwkatz a, generate(k) alpha(-3)
replace attr = -1 in 1
_says "negative values" nwplot a, size(attr)

mata: M = (0,1,.\1,0,1\.,1,0)
nwset, mat(M) name(miss) undirected
_rc_is 504 nwhierarchy miss, groups(2) generate(h)
mata: M = J(1,1,0)
nwset, mat(M) name(one) undirected
_rc_is 2001 nwhierarchy one, groups(2) generate(h1)

nwclear
mata: M = (0,1,1,0\1,0,1,0\1,1,0,-1\0,0,-1,0)
nwset, mat(M) name(neg) undirected
_says "negative tie values" nwspectral neg, generate(s) measure(valued)
_says "negative tie values" nwcoreperiphery neg, generate(c) measure(valued)

* export: quotes and a repeated ending
nwclear
nwrandom 5, prob(.5) name(a) undirected
local d "`c(tmpdir)'"
foreach p in "pajek net" "gml gml" "ucinet dl" "edgelist txt" {
	local type : word 1 of `p'
	local end : word 2 of `p'
	local f "`d'/r4 x_`type'"
	nwexport a, type(`type') fname("`f'.`end'") replace
	confirm file "`f'.`end'"
	capture confirm file "`f'.`end'.`end'"
	assert _rc != 0
	nwexport a, type(`type') fname("`f'") replace
}

display "PASS test_edge_round4_minor"
