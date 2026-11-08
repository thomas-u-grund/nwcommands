* usage: do bstata.do <benchmark id>   (adopath header set by the caller)
args id
capture program drop T
program define T
	* T label : command   -- run and time a command
	gettoken lab 0 : 0
	gettoken colon 0 : 0
	timer clear 99
	timer on 99
	capture noisily `0'
	if _rc noisily di "@@TIME `lab' ERROR " _rc
	timer off 99
	quietly timer list 99
	noisily di "@@TIME `lab' " %9.2f r(t99)
end
if "`id'" == "lazega" {
	nwwebuse lazega, nwclear
	foreach v in office practice status {
		encode `v', generate(`v'n)
	}
	T fit : nwergm lazega_adv, edges mutual nodematch(officen practicen) nodeofactor(statusn) nodeifactor(statusn) gwesp(.5) seed(12345)
	T gof : estat gof, gof(model distance odegree idegree espartners) seed(12345)
	T sim100 : nwergm simulate, nsim(100) seed(1) generate(s)
}
if "`id'" == "mesa" {
	nwwebuse mesa, nwclear
	capture encode race, generate(racen)
	T fit : nwergm mesa, edges nodematch(grade racen) gwesp(.25) seed(12345) mcmleeffectivesize(200)
	T gof : estat gof, seed(12345)
}
if "`id'" == "d1000" {
	nwclear
	set seed 1000
	nwrandom 1000, prob(0.006) name(d1000)
	generate grp = ceil(3*runiform())
	T fit : nwergm d1000, edges mutual nodematch(grp) seed(12345)
}
if "`id'" == "u1000" {
	nwclear
	set seed 1001
	nwrandom 1000, prob(0.006) undirected name(u1000)
	generate grp = ceil(3*runiform())
	generate cov = round(rnormal(0,5), .01)
	T fit : nwergm u1000, edges gwesp(.5) nodefactor(grp) nodecov(cov) seed(12345)
}
if "`id'" == "d5000" {
	nwclear
	set seed 5000
	nwrandom 5000, prob(0.002) name(d5000)
	generate grp = ceil(4*runiform())
	generate cov = round(rnormal(0,5), .01)
	T mple_match : nwergm d5000, edges nodematch(grp) method(mple)
	T mple_cov : nwergm d5000, edges nodematch(grp) nodecov(cov) method(mple)
}
foreach n in 100 200 400 {
	if "`id'" == "sr`n'" {
		nwclear
		set seed `n'
		nwrandom `n', prob(`=10/`n'') name(sr`n')
		generate g = 1
		T mple : nwergm sr`n', edges sender receiver method(mple)
	}
}
if "`id'" == "p1000" {
	nwclear
	set seed 1001
	nwrandom 1000, prob(0.006) undirected name(u1000)
	generate grp = ceil(3*runiform())
	generate cov = round(rnormal(0,5), .01)
	T fit : nwergm u1000, edges gwesp(.5) nodefactor(grp) nodecov(cov) seed(12345)
	T gof : estat gof, seed(12345)
	T sim100 : nwergm simulate, nsim(100) seed(1) generate(s)
	T sa : nwergm u1000, edges gwesp(.5) nodefactor(grp) nodecov(cov) seed(12345) mainmethod(sa)
}
