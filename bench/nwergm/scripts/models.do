* defines program runmodel: args name seed extra-options ; sets r(cmdline) executes the fit quietly
capture program drop setupmodel
program setupmodel
    args name
    if "`name'"=="B1" {
        loadnet bench_net.csv 1
        c_local cmd "edges mutual"
    }
    if "`name'"=="B2" {
        loadnet net100dir.csv 1
        loadattr attr100dir.csv
        c_local cmd "edges mutual nodematch(grp)"
    }
    if "`name'"=="B3" {
        loadnet net100undir.csv 0
        c_local cmd "edges gwesp(.5)"
    }
    if "`name'"=="B4" {
        loadnet net500.csv 0
        loadattr attr500.csv
        c_local cmd "edges nodematch(grp) gwesp(.5)"
    }
    if "`name'"=="B5" {
        loadnet net1000.csv 1
        loadattr attr1000.csv
        c_local cmd "edges mutual nodematch(grp)"
    }
    if "`name'"=="B6" {
        loadnet net_sp.csv 0
        c_local cmd "edges gwesp(.5) gwnsp(.5)"
    }
    if "`name'"=="F6" {
        loadnet net100dir.csv 1
        loadattr attr100dir.csv
        c_local cmd "edges mutual nodematch(grp) gwesp(.5) gwdsp(.5) gwnsp(.3)"
    }
    if "`name'"=="F9" {
        loadnet net100dir.csv 1
        c_local cmd "edges mutual gwesp(.5) gwdsp(.5) type(ISP)"
    }
    if "`name'"=="F10" {
        loadnet net100dir.csv 1
        c_local cmd "edges mutual gwesp(.5) gwnsp(.5) type(OSP)"
    }
    if "`name'"=="F11" {
        loadnet net100dir.csv 1
        c_local cmd "edges mutual gwesp(.5) gwdsp(.5) type(RTP)"
    }
    if "`name'"=="F7" {
        loadnet net100undir.csv 0
        c_local cmd "edges gwdegree(.5) triangle gwdsp(.3) gwnsp(.4)"
    }
    if "`name'"=="F8" {
        loadnet net100dir.csv 1
        loadattr attr100dir.csv
        c_local cmd "edges mutual gwodegree(.5) gwidegree(.5) nodemix(grp)"
    }
    if "`name'"=="Lazega" {
        nwwebuse lazega, nwclear
        foreach v in office practice status {
            encode `v', generate(`v'n)
        }
        c_local cmd "edges mutual nodematch(officen practicen) nodeofactor(statusn) nodeifactor(statusn) gwesp(.5)"
    }
    if "`name'"=="Mesa" {
        nwwebuse mesa, nwclear
        encode race, generate(racen)
        c_local cmd "edges nodematch(grade racen) gwesp(.25)"
    }
end
capture program drop netname
program netname
    args name
    c_local nn = cond("`name'"=="Lazega","lazega_adv",cond("`name'"=="Mesa","mesa","bnet"))
end
