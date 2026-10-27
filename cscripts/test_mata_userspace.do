* nwcommands never touches the user's own Mata variables and leaves no global Mata variables of its own behind.
* Rule (GOTCHA.md): ado code must not assign plain-named top-level Mata variables (Coord, M, temp, reach, comm_id ...).
* It uses tempname-generated names or the prefix __nw (the registry is __nw) and drops them again.
* The test defines about 100 names that users typically use in a Mata session (real matrices, strings, a struct), runs a broad
* sample of commands, and after every command checks that each user variable still has its value; at the end it lists
* the global Mata variables that appeared during the run: there must be none.
cscript

do unw_core.do
set graphics off

* ---- the user's Mata variables -----------------------------------------------------------------------------------
local names M A B C D X Y Z W p q x y z i j k n m r s t v temp tmp res out Coord coord reach nw nws plotmat edgecolormat ///
    mylab nsize far Coord_comp Mdir Mdir2 TC attr attrview census closeness constraint d dc dr datalong effsize efficiency h ///
    expnet fitted_long fitted_mat mode1 modevec ncolor nearness neighbors newmat nlabel nsymbol onenet original_id perm_net ///
    net_long util compM edgesizemat dsp_res nwqap_fitted_last nwcug_nullvals nwtostataview nw_denom_total subattr keepmatSize ///
    checkedcost checkedvalue corr_reps lb ub sel pvalue
foreach f in comm core block {
    foreach s in size id sizeid share number {
        local names `names' `f'_`s'
    }
}
foreach s in id sizeid freqid freq number nonisol size share {
    local names `names' comp_`s'
}
local names : list uniq names
local iu = 0
local deflist ""
foreach nm of local names {
    local ++iu
    if mod(`iu', 3) == 0 {
        mata: `nm' = "usr_`nm'"
    }
    else {
        mata: `nm' = J(2, 3, `=1000 + `iu'')
    }
}
mata:
struct usrs {
    real scalar a
}
S = usrs()
S.a = 77
end
local nuser = `: word count `names'' + 1

mata:
string scalar __usertest_names(string scalar f)
{
    string colvector L
    string rowvector t
    string scalar out, w
    real scalar i, p
    L = cat(f)
    out = ""
    for (i = 1; i <= rows(L); i++) {
        t = tokens(L[i])
        if (cols(t) >= 3) {
            if (strtoreal(t[1]) < .) {
                w = t[cols(t)]
                p = strpos(w, "[")
                if (p > 0) w = substr(w, 1, p - 1)
                out = out + " " + w
            }
        }
    }
    return(out)
}
end

capture program drop hierdend
program define hierdend
    nwhierarchy `1'
    nwdendrogram _clus_1
end

capture program drop plotcomp
program define plotcomp
    * a data set that holds nothing but the nodes (nwplot with components() keeps the node rows of the data in step with the network)
    clear
    set obs 8
    nwplot `1', layout(mdsclassical) components(2)
end

capture program drop uchk
program define uchk
    args label
    local bad ""
    local iu = 0
    foreach nm of global USERNAMES {
        local ++iu
        if mod(`iu', 3) == 0 {
            capture mata: assert(`nm' == "usr_`nm'")
        }
        else {
            capture mata: assert(rows(`nm') == 2 & cols(`nm') == 3 & all(`nm' :== `=1000 + `iu''))
        }
        if _rc & !`: list nm in global(UDMG)' {
            local bad `bad' `nm'
            global UDMG $UDMG `nm'
        }
    }
    capture mata: assert(S.a == 77)
    if _rc & !`: list posof "S" in global(UDMG)' {
        local bad `bad' S
        global UDMG $UDMG S
    }
    if "`bad'" != "" {
        di as error "after `label': user Mata variables overwritten or removed: `bad'"
        global UFAIL "$UFAIL [`label': `bad']"
    }
end

capture program drop runc
program define runc
    * runc label : command
    gettoken label 0 : 0, parse(":")
    gettoken colon 0 : 0, parse(":")
    preserve
    capture noisily `0'
    local rc = _rc
    restore
    if `rc' {
        di as error "COMMAND FAILED (r(`rc')) in `label': `0'"
        global CFAIL "$CFAIL [`label']"
    }
    uchk "`label'"
    * global Mata objects that this command left behind
    tempfile snapf
    snap `"`snapf'"'
    mata: st_local("after", __usertest_names(st_local("snapf")))
    local fresh : list after - global(KNOWN)
    local fresh : list fresh - global(ALLOWED)
    if "`fresh'" != "" {
        di as error "after `label': global Mata objects left behind: `fresh'"
        global NEWOBJ "$NEWOBJ `fresh'"
        global KNOWN "$KNOWN `fresh'"
    }
end

* list the global Mata objects (names only)
capture program drop snap
program define snap
    args file
    capture log close snap
    quietly log using `"`file'"', text replace name(snap)
    mata: mata describe
    quietly log close snap
end

global USERNAMES `names'
global UFAIL ""
global UDMG ""
global CFAIL ""

* ---- networks ----------------------------------------------------------------------------------------------------
clear
set obs 8
set seed 12
nwclear
local A (0,1,1,0,0,0,0,0\1,0,1,0,0,0,0,0\1,1,0,1,0,0,0,0\0,0,1,0,1,0,0,0\0,0,0,1,0,1,1,0\0,0,0,0,1,0,1,1\0,0,0,0,1,1,0,1\0,0,0,0,0,1,1,0)
nwset, mat(`A') name(g) undirected labs(a,b,c,d,e,f,gg,h)
nwset, mat(`A') name(d) labs(a,b,c,d,e,f,gg,h)
nwset, mat(`A') name(g2) undirected labs(a,b,c,d,e,f,gg,h)
nwset, mat((`A') :* 0.37) name(gv) undirected labs(a,b,c,d,e,f,gg,h)
nwset, mat((0,1,1\1,0,0\1,0,0)) name(Q) undirected
nwset, mat((0,1,1,0,0,0,0,0\1,0,1,0,0,0,0,0\1,1,0,0,0,0,0,0\0,0,0,0,1,0,0,0\0,0,0,1,0,1,0,0\0,0,0,0,1,0,1,0\0,0,0,0,0,1,0,1\0,0,0,0,0,0,1,0)) name(g3) undirected
generate attr = _n
generate grp = 1 + (_n > 4)
generate px = _n
generate py = mod(_n * 5, 7)
generate efrom = ceil(_n / 2)
generate eto = 1 + mod(_n * 3, 8)
mata: ugm = (0,1,1\1,0,0\1,0,0)
matrix sm4 = (0,1,1,0\1,0,1,0\1,1,0,1\0,0,1,0)
uchk "setup"

* known global Mata objects: everything that exists now, plus the two kept on purpose
*   __nwqapfit      the fitted values of the last nwqap, for  predict newnetname
*   nwg_comb_state  the state of the native plug-in check (an external of the Mata library)
tempfile f0 html savef
global SAVEF `savef'
snap `f0'
mata: st_global("KNOWN", __usertest_names(st_local("f0")))
global ALLOWED "__nwqapfit nwg_comb_state umat"
global NEWOBJ ""

* ---- commands ----------------------------------------------------------------------------------------------------
runc nwcommunity    : nwcommunity g, generate(cm) algorithm(louvain) seed(1) replace silent
runc nwmodularity   : nwmodularity g, group(grp)
runc nwcomponents   : nwcomponents g, generate(cc) silent
runc nwkcore        : nwkcore g, generate(kc) silent
runc nwconcor       : nwconcor g, generate(blk) replace silent
runc nwcloseness    : nwcloseness g, generate(cl_c cl_f cl_n) replace silent
runc nwcloseness2   : nwcloseness g, generate(cl_c cl_f cl_n) replace silent legacy
runc nwbetween      : nwbetween g, generate(b1) replace silent
runc nwbetween2     : nwbetween g, generate(b2) replace silent onemode
runc nwgeodesic     : nwgeodesic g, name(gd) nwreplace force
runc nwneighbor     : nwneighbor g, ego(a)
runc nwneighbor2    : nwneighbor g, ego(a) generate(nb) replace
runc nwlattice      : nwlattice 3 3, name(lat)
runc nwexpand       : nwexpand g, name(gexp)
runc nwdropnodes    : nwdropnodes g, nodes(1 3) generate(gdrop)
runc nwcorrelate    : nwcorrelate g, name(gcorr)
runc nwcug          : nwcug d, stat(nwdyads ##net##) rname(reciprocity) reps(5) seed(1) condition(census)
runc nwdyads        : nwdyads d
runc nwutility      : nwutility Q, benefit(.5) cost(.2)
runc nwturnover     : nwturnover g g2, generate(tov) silent
runc nwcontext      : nwcontext g, attribute(attr) generate(ctx)
runc nwrecode       : nwrecode g2 (1=1)
runc nwdissimilar   : nwdissimilar g, type(hamming) name(gdis)
runc nwsimilar      : nwsimilar g, type(pearson) name(gsim)
runc nwburt         : nwburt g, replace silent
runc nwdyadprob     : nwdyadprob g, density(.2) name(gdp)
runc nwtoedge       : nwtoedge g
runc nwfromedge     : nwfromedge efrom eto, name(gedge) undirected
runc nwtostata      : nwtostata, mat(ugm) stub(w_)
runc nwreplacemat   : nwreplacemat Q, newmat(sm4) labs(a,b,c,d) vars(a b c d)
runc nwtomata       : nwtomata g, mat(umat)
mata: mata drop umat
runc nwcurrent      : nwcurrent
runc nwset          : nwset, mat((0,1,0\1,0,1\0,1,0)) name(path3)
runc nwplot_gen     : nwplot g, generate(qx qy)
runc nwplot_attr    : nwplot g, nodexy(px py) size(attr) color(attr) symbol(grp) lab
runc nwplot_edge    : nwplot g, nodexy(px py) edgecolor(g2) edgesize(g2) edgefactor(3)
runc nwplot_comp    : plotcomp g3
runc nwplot_mds     : nwplot g, layout(mds)
runc nwplot_circle  : nwplot g, layout(circle)
runc nwplot_dir     : nwplot d, nodexy(px py)
runc nwplot_cont    : nwplot g, nodexy(px py) edgecolor(gv)
runc nwplot_html    : nwplot g, nodexy(px py) interactive noopen fname("`html'")
runc nwplot_nxy     : nwplot g, layout(nodexy) nodexy(px py)
runc nwdegree       : nwdegree g, generate(dg) replace silent
runc nwclustering   : nwclustering g, generate(cl) replace silent
runc nwevcent       : nwevcent g, generate(ev) replace
runc nwpagerank     : nwpagerank g, generate(pr) silent replace
runc nwkatz         : nwkatz g, generate(kz) alpha(.1)
runc nwtriads       : nwtriads d
runc nwmotifs       : nwmotifs d, silent
runc nwsummarize    : nwsummarize g
runc nwtranspose    : nwtranspose d, name(dt)
runc nwmixing       : nwmixing g, attribute(grp) permutations(20)
runc nwassortativity: nwassortativity g, silent
runc nwcorrelate_p  : nwcorrelate g g2, permutations(5)
runc nwspectral     : nwspectral g, generate(fied) silent
runc nwclique       : nwclique g, generate(cq) minsize(3) silent replace
runc nwcohesion     : nwcohesion g, generate(coh) replace silent
runc nwbridges      : nwbridges g, nwreplace
runc nwnoderename   : nwnoderename g2, old(a) new(aa)
runc nwaddnodes     : nwaddnodes g2, nodenames(zz)
runc nwsym          : nwsym d
runc nwsave         : nwsave "$SAVEF", replace
runc nwuse          : nwuse "$SAVEF", nwclear
runc nwimport       : nwimport data/gang_pajek.net, type(pajek) name(pj) nwclear
runc nwexport       : nwexport pj, type(pajek) replace
runc nwdrop         : nwdrop pj

* commands that need other data: a 6-node pair for nwqap, a 4-node network for nwhierarchy / nwdendrogram
nwset, mat((0,1,0,1,1,0\1,0,1,0,0,1\0,1,0,1,0,0\1,0,1,0,1,1\1,0,0,1,0,0\0,1,0,1,0,0)) name(iv1) undirected labs(A,B,C,D,E,F)
nwset, mat((0,1,1,0,0,1\1,0,0,1,1,0\1,0,0,1,1,0\0,1,1,0,0,1\0,1,1,0,0,0\1,0,0,1,0,0)) name(bindv) undirected labs(A,B,C,D,E,F)
runc nwqap_a        : nwqap bindv iv1, permutations(3)
runc nwqap_b        : nwqap bindv iv1, permutations(3) type(logit) predict(bindvfitted)
preserve
clear
set obs 4
nwset, mat((0,1,0,1\1,0,1,0\0,1,0,1\1,0,1,0)) name(net1) undirected labs(A,B,C,D)
runc hierdend       : hierdend net1
restore

* ---- summary -------------------------------------------------------------------------------------------------------
if "$NEWOBJ" == "" di as text "no global Mata objects left behind"
else di as error "global Mata objects left behind: $NEWOBJ"
capture erase pj.net
if "$CFAIL" != "" di as error "commands that failed: $CFAIL"
if "$UFAIL" != "" di as error "user variables damaged: $UFAIL"
assert "$CFAIL" == ""
assert "$UFAIL" == ""
assert "$NEWOBJ" == ""
di as text "user Mata variables are not touched, no global Mata variables remain PASS"
