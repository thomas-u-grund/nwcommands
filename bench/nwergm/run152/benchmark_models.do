* benchmark_models.do: included (not called) by 03_benchmark_fit.do, 05_sampler_check.do, 06_benchmark_estimates.do and 07_fixed_workload.do.
* Given the local id (B1 ... B6, Lazega, Mesa), it loads the network and sets the locals net and cmd
* (the nwergm terms). The CSV files in data/ are the ones R reads.
local D "data"
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
capture program drop addattr
program addattr
    args f
    preserve
    quietly import delimited using "`f'", clear varnames(nonames)
    mata: G = st_data(., "v1")
    restore
    quietly generate double grp = .
    mata: st_store((1::rows(G)), "grp", G)
end
local net "bnet"
if "`id'"=="B1" {
    loadnet "`D'/bench_net.csv" 1
    local cmd "edges mutual"
}
if "`id'"=="B2" {
    loadnet "`D'/net100dir.csv" 1
    addattr "`D'/attr100dir.csv"
    local cmd "edges mutual nodematch(grp)"
}
if "`id'"=="B3" {
    loadnet "`D'/net100undir.csv" 0
    local cmd "edges gwesp(.5)"
}
if "`id'"=="B4" {
    loadnet "`D'/net500.csv" 0
    addattr "`D'/attr500.csv"
    local cmd "edges nodematch(grp) gwesp(.5)"
}
if "`id'"=="B5" {
    loadnet "`D'/net1000.csv" 1
    addattr "`D'/attr1000.csv"
    local cmd "edges mutual nodematch(grp)"
}
if "`id'"=="B6" {
    loadnet "`D'/net_sp.csv" 0
    local cmd "edges gwesp(.5) gwnsp(.5)"
}
if "`id'"=="Lazega" {
    nwwebuse lazega, nwclear
    foreach v in office practice status {
        encode `v', generate(`v'n)
    }
    local net "lazega_adv"
    local cmd "edges mutual nodematch(officen practicen) nodeofactor(statusn) nodeifactor(statusn) gwesp(.5)"
}
if "`id'"=="Mesa" {
    nwwebuse mesa, nwclear
    encode race, generate(racen)
    local net "mesa"
    local cmd "edges nodematch(grade racen) gwesp(.25)"
}
