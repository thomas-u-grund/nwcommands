* network_gen.do - build the benchmark network `bench` for the scaling audit.
*
* Controlled by globals (set by run_audit.py before calling this file):
*   NWA_N     number of nodes (one-mode) or mode-1 nodes (two-mode)
*   NWA_KIND  dir | undir | valued | valuedu | two | edges | none
*               dir     directed, binary, 10 out-ties per node
*               undir   undirected, binary, 10 ties drawn per node (~20 per node after symmetrising)
*               valued  directed, tie values 1..5
*               valuedu undirected, tie values 1..5
*               two     two-mode (nw2fromedge), N mode-1 nodes, N/2 mode-2 nodes, 10 ties per mode-1 node
*               edges2  like edges, with the two-mode id ranges of "two" (mode 2 has N/2 nodes)
*               edges   only the edge list variables from, to, val in memory (for nwfromedge itself)
*               none    nothing (generator commands are measured on their own)
*   NWA_ATTR  1 = add node attributes after loading (grp 1..5, bin 0/1, attr continuous, node_id)
*
* Prints NWAUDIT_GEN_SECS=<seconds> and NWAUDIT_TIES=<number of ties in the edge list>
* or NWAUDIT_GEN_RC=<rc> when the load itself fails.
clear
set seed 20261025
if "$NWA_KIND" != "none" {
    local N = $NWA_N
    local two = ("$NWA_KIND" == "two" | "$NWA_KIND" == "edges2")
    quietly set obs `=`N'*10'
    quietly gen long from = ceil(_n/10)
    if `two' {
        local M = max(2, floor(`N'/2))
        quietly gen long to = ceil(runiform()*`M')
    }
    else {
        quietly gen long to = ceil(runiform()*`N')
        quietly drop if from == to
    }
    quietly duplicates drop from to, force
    quietly gen byte val = ceil(runiform()*5)
    quietly count
    display "NWAUDIT_TIES=" r(N)
    scalar nwa_t_ties = r(N)
    * ground truth for the correctness checks (checks.do): the edge list as Mata externals
    mata: NWA_from = st_data(., "from"); NWA_to = st_data(., "to"); NWA_val = st_data(., "val")
    if "$NWA_KIND" != "edges" & "$NWA_KIND" != "edges2" {
        timer clear 90
        timer on 90
        local opt ""
        if "$NWA_KIND" == "undir" | "$NWA_KIND" == "valuedu" local opt ", undirected name(bench)"
        else local opt ", name(bench)"
        local v ""
        if "$NWA_KIND" == "valued" | "$NWA_KIND" == "valuedu" local v "val"
        if `two' capture noisily quietly nw2fromedge from to, name(bench)
        else capture noisily quietly nwfromedge from to `v' `opt'
        local grc = _rc
        timer off 90
        quietly timer list 90
        display "NWAUDIT_GEN_SECS=" r(t90)
        if `grc' {
            display "NWAUDIT_GEN_RC=`grc'"
            exit `grc'
        }
        if "$NWA_ATTR" == "1" & !`two' {
            quietly {
                local n = _N
                gen long node_id = _n
                gen byte grp = ceil(runiform()*5)
                gen byte bin = (runiform() < .5)
                gen double attr = rnormal()
            }
        }
    }
}
