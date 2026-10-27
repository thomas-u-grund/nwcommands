* Timing of nwergm on the benchmark networks (default settings, 5 repeated fits with seeds 1 to 5).
* Same networks as bench_ergm.R (CSV files). The edge list is loaded as directed or undirected exactly as in the R script (the first version of this file omitted "undirected" and fitted B3, B4, B6 as directed models). Writes bench_nwergm.csv (benchmark, rep, seconds, iterations).
do "hdr_local.do"
set linesize 120
local d "`c(pwd)'"
* global BENCHOUT names the output file (default bench_nwergm.csv)
local outf "bench_nwergm.csv"
if "$BENCHOUT" != "" local outf "$BENCHOUT"
capture erase "`outf'"
tempname ph
postfile `ph' str12 bench int rep double(secs iter) using bench_nwergm_tmp.dta, replace

capture program drop loadnet
program loadnet
    args file directed
    nwclear
    clear
    mata: loadcsv("`file'", `directed')
    nwset ego alter value, edgelist `=cond(`directed'==1,"directed","undirected")' name(bnet)
end
mata:
void loadcsv(string scalar f, real scalar directed)
{
    real matrix M
    string scalar ln
    real scalar fh, i, n, k, j
    real colvector eg, al, va
    fh = fopen(f, "r")
    M = J(0,0,.)
    i = 0
    while ((ln = fget(fh)) != J(0,0,"")) {
        i++
        if (i==1) {
            n = cols(tokens(subinstr(ln, ",", " ", .)))
            M = J(n,n,0)
        }
        M[i,.] = strtoreal(tokens(subinstr(ln, ",", " ", .)))
    }
    fclose(fh)
    n = rows(M)
    if (directed) k = n*(n-1); else k = n*(n-1)/2
    eg = J(k,1,.); al = J(k,1,.); va = J(k,1,.)
    k = 0
    for (i=1; i<=n; i++) for (j=1; j<=n; j++) {
        if (i==j) continue
        if (!directed & j<i) continue
        k++
        eg[k] = i; al[k] = j; va[k] = (M[i,j]!=0)
    }
    st_addobs(k)
    st_addvar("double", ("ego","alter","value"))
    st_store(., ("ego","alter","value"), (eg,al,va))
}
end

capture program drop bench
program bench
    args ph name file directed attrfile cmd
    loadnet "`file'" `directed'
    if "`attrfile'" != "" {
        preserve
        quietly import delimited using "`attrfile'", clear varnames(nonames)
        quietly count
        mata: G = st_data(., "v1")
        restore
        quietly generate double grp = .
        mata: st_store((1::rows(G)), "grp", G)
    }
    forvalues r = 1/5 {
        timer clear 8
        timer on 8
        quietly nwergm bnet, `cmd' seed(`r')
        timer off 8
        quietly timer list 8
        post `ph' ("`name'") (`r') (r(t8)) (e(mcmle_iterations))
        di "`name' rep `r': " r(t8) " s, iterations " e(mcmle_iterations)
    }
end

if "$BENCHSEL"=="" | strpos(" $BENCHSEL ", " B1 ") bench `ph' B1 "bench_net.csv" 1 "" "edges mutual"
if "$BENCHSEL"=="" | strpos(" $BENCHSEL ", " B2 ") bench `ph' B2 "net100dir.csv" 1 "attr100dir.csv" "edges mutual nodematch(grp)"
if "$BENCHSEL"=="" | strpos(" $BENCHSEL ", " B3 ") bench `ph' B3 "net100undir.csv" 0 "" "edges gwesp(.5)"
if "$BENCHSEL"=="" | strpos(" $BENCHSEL ", " B4 ") bench `ph' B4 "net500.csv" 0 "attr500.csv" "edges nodematch(grp) gwesp(.5)"
if "$BENCHSEL"=="" | strpos(" $BENCHSEL ", " B5 ") bench `ph' B5 "net1000.csv" 1 "attr1000.csv" "edges mutual nodematch(grp)"
if "$BENCHSEL"=="" | strpos(" $BENCHSEL ", " B6 ") bench `ph' B6 "net_sp.csv" 0 "" "edges gwesp(.5) gwnsp(.5)"
* real networks
if "$BENCHSEL"=="" | strpos(" $BENCHSEL ", " Lazega ") {
nwwebuse lazega, nwclear
foreach v in office practice status {
    encode `v', generate(`v'n)
}
forvalues r = 1/5 {
    timer clear 8
    timer on 8
    quietly nwergm lazega_adv, edges mutual nodematch(officen practicen) nodeofactor(statusn) nodeifactor(statusn) gwesp(.5) seed(`r')
    timer off 8
    quietly timer list 8
    post `ph' ("Lazega") (`r') (r(t8)) (e(mcmle_iterations))
}
}
if "$BENCHSEL"=="" | strpos(" $BENCHSEL ", " Mesa ") {
nwwebuse mesa, nwclear
encode race, generate(racen)
forvalues r = 1/5 {
    timer clear 8
    timer on 8
    quietly nwergm mesa, edges nodematch(grade racen) gwesp(.25) seed(`r')
    timer off 8
    quietly timer list 8
    post `ph' ("Mesa") (`r') (r(t8)) (e(mcmle_iterations))
}
}
postclose `ph'
use bench_nwergm_tmp.dta, clear
export delimited using "`outf'", replace
erase bench_nwergm_tmp.dta
display "BENCH_NWERGM_DONE"
