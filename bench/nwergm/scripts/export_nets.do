* Exports the networks and attributes used in the article to CSV so that R's ergm fits identical data.
do "hdr_local.do"
local d "`c(pwd)'"
capture program drop expnet
program expnet
    args name file dir
    _nwsyntax `name', max(1)
    mata: M = *`netobj'->get_matrix_mod(1,`dir')
    mata: _editmissing(M, 0)
    capture erase "`file'"
    mata: fh = fopen("`file'", "w")
    mata: for (i=1; i<=rows(M); i++) fput(fh, invtokens(strofreal(M[i,.]), ","))
    mata: fclose(fh)
    mata: st_local("nt", strofreal(sum(M)))
    di "exported `file': ties (sum of cells) = `nt'"
end
nwwebuse florentine, nwclear
describe, short
outsheet seat wealth using "`d'/flo_attr.csv", comma replace nolabel
expnet flomarriage "`d'/flo_marriage.csv" 0
expnet flobusiness "`d'/flo_business.csv" 0
nwwebuse lazega, nwclear
foreach v in office practice status {
    encode `v', generate(`v'n)
}
describe, short
outsheet officen practicen statusn using "`d'/lazega_attr.csv", comma replace nolabel
expnet lazega_adv "`d'/lazega_adv.csv" 1
expnet lazega_fr "`d'/lazega_fr.csv" 1
nwwebuse mesa, nwclear
encode race, generate(racen)
describe, short
outsheet grade racen using "`d'/mesa_attr.csv", comma replace nolabel
expnet mesa "`d'/mesa.csv" 0
nwwebuse davis, nwclear
encode title, generate(titlen)
outsheet _nwmode titlen using "`d'/davis_attr.csv", comma replace nolabel
expnet davis "`d'/davis_full.csv" 0
* benchmark networks 5 and 6 (regenerated with the seeds of the earlier benchmark suite)
set seed 20260826
nwclear
nwrandom 1000, prob(0.006) name(bench1000)
gen grp = ceil(3*runiform())
outsheet grp using "`d'/attr1000.csv", comma nonames replace nolabel
expnet bench1000 "`d'/net1000.csv" 1
set seed 20260903
nwclear
nwrandom 1000, prob(0.006) undirected name(bench8)
expnet bench8 "`d'/net_sp.csv" 0
display "EXPORT_DONE"
