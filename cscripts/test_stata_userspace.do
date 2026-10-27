* nwcommands never overwrites or deletes the user's own Stata matrices, scalars and variables of the same plain names
* (comp_id, comp_sizeid, components, nsizerow, pvalues ...), and nwplot with components() works when the data set has
* more or fewer rows than the network has nodes (it failed with r(3301) there).
* Companion of test_mata_userspace.do (which covers the Mata namespace).
cscript
set graphics off

local mats comp_id comp_freq comp_freqid comp_sizeid comm_sizeid block_id block_size block_sizeid core_id core_size core_sizeid ///
    colorkeysmap symbolkeysmap edgecolor_mat nsizerow ncolorrow nsymbolrow nsymblrow edgecolorrow valuerow pvalues permvar ///
    reg_results temp_coeff Coord M
local scals components communities modularity commnum maxcore corelevels blocks
foreach m of local mats {
    matrix `m' = (7, 8 \ 9, 10)
}
foreach s of local scals {
    scalar `s' = 4711
}

capture program drop uchk
program define uchk
    args label
    local bad ""
    foreach m of global UMATS {
        capture confirm matrix `m'
        if _rc local bad `bad' `m'
        else if `m'[1,1] != 7 | `m'[2,2] != 10 local bad `bad' `m'
    }
    foreach s of global USCALS {
        capture confirm scalar `s'
        if _rc local bad `bad' `s'
        else if scalar(`s') != 4711 local bad `bad' `s'
    }
    foreach v in _id comp_id nsize ncolor nsymbol edgecolor edgesize {
        capture confirm variable `v'
        if _rc local bad `bad' `v'
        else if `v'[1] != 99 local bad `bad' `v'
    }
    if "`bad'" != "" {
        di as error "after `label': user matrices, scalars or variables damaged: `bad'"
        global UFAIL "$UFAIL [`label': `bad']"
    }
end

capture program drop runc
program define runc
    gettoken label 0 : 0, parse(":")
    gettoken colon 0 : 0, parse(":")
    capture noisily `0'
    if _rc {
        di as error "COMMAND FAILED (r(`=_rc')) in `label': `0'"
        global CFAIL "$CFAIL [`label']"
    }
    uchk "`label'"
end

global UMATS `mats'
global USCALS `scals'
global UFAIL ""
global CFAIL ""

clear
set obs 8
nwclear
local A (0,1,1,0,0,0,0,0\1,0,1,0,0,0,0,0\1,1,0,0,0,0,0,0\0,0,0,0,1,0,0,0\0,0,0,1,0,0,0,0\0,0,0,0,0,0,1,0\0,0,0,0,0,1,0,0\0,0,0,0,0,0,0,0)
nwset, mat(`A') name(h) undirected
nwset, mat((0,1,1,0,0,0,0,0\1,0,1,0,0,0,0,0\1,1,0,1,0,0,0,0\0,0,1,0,1,0,0,0\0,0,0,1,0,1,1,0\0,0,0,0,1,0,1,1\0,0,0,0,1,1,0,1\0,0,0,0,0,1,1,0)) name(g) undirected
nwset, mat((0,1,0,0,0\1,0,0,0,0\0,0,0,1,1\0,0,1,0,1\0,0,1,1,0)) name(two) undirected
foreach v in _id comp_id nsize ncolor nsymbol edgecolor edgesize {
    generate `v' = 99
}
uchk "setup"

nwcomponents h, generate(cc) silent
assert rowsof(r(comp_sizeid)) == 4 & r(comp_sizeid)[1,1] == 3 & r(comp_sizeid)[2,1] == 2 & r(components) == 4
uchk "nwcomponents"
nwkcore h, generate(kc) silent
assert rowsof(r(core_sizeid)) >= 1
uchk "x"
nwconcor g, generate(blk) replace silent
assert rowsof(r(block_sizeid)) >= 1
uchk "x"
nwcommunity g, generate(cm) algorithm(louvain) seed(1) replace silent
assert r(communities) >= 1
uchk "x"
generate grp = 1 + (_n > 4)
nwmodularity g, group(grp)
assert r(communities) >= 1
uchk "x"
generate attr = _n
generate px = _n
generate py = mod(_n * 5, 7)
runc nwplot_attr  : nwplot g, nodexy(px py) size(attr) color(attr) symbol(grp) lab
runc nwplot_edge  : nwplot g, nodexy(px py) edgecolor(g) edgesize(g) edgefactor(3)

* nwplot with components(): a network with a 2-node component, data set of the same size, larger, and smaller than the network
runc plot_comp8   : nwplot h, layout(mdsclassical) components(2)
runc plot_comp8b  : nwplot h, layout(mdsclassical) components(3)
runc plot_two     : nwplot two, layout(mdsclassical) components(2)
runc plot_two1    : nwplot two, layout(mdsclassical) components(1)
runc plot_twodef  : nwplot two, layout(mdsclassical)
quietly keep in 1/3
runc plot_small   : nwplot h, layout(mdsclassical) components(2)
clear
nwplot h, layout(mdsclassical) components(2)

* nwqap
nwset, mat((0,1,0,1,1,0\1,0,1,0,0,1\0,1,0,1,0,0\1,0,1,0,1,1\1,0,0,1,0,0\0,1,0,1,0,0)) name(iv1) undirected labs(A,B,C,D,E,F)
nwset, mat((0,1,1,0,0,1\1,0,0,1,1,0\1,0,0,1,1,0\0,1,1,0,0,1\0,1,1,0,0,0\1,0,0,1,0,0)) name(bindv) undirected labs(A,B,C,D,E,F)
generate comp_id = 99
generate _id = 99
foreach v in nsize ncolor nsymbol edgecolor edgesize {
    generate `v' = 99
}
runc nwqap        : nwqap bindv iv1, permutations(3)

if "$CFAIL" != "" di as error "commands that failed: $CFAIL"
if "$UFAIL" != "" di as error "user objects damaged: $UFAIL"
assert "$CFAIL" == ""
assert "$UFAIL" == ""
di as text "user Stata matrices, scalars and variables are not touched PASS"
