* writes the three Lazega networks (directed, 71 nodes) of data/lazega.nwdta as edge lists i,j for make_fixture.R
* run from the repository root with the nwcommands of this repository on the adopath
clear all
nwclear
nwuse data/lazega
foreach nm in lazega_adv lazega_cow lazega_fr {
	nwtomatafast `nm'
	mata: A = editmissing(`r(mata)', 0)
	mata: k = selectindex(vec(A :!= 0)); n = rows(A)
	mata: E = (mod(k :- 1, n) :+ 1, floor((k :- 1) :/ n) :+ 1)
	mata: fh = fopen("cscripts/nwcommunity_fixture/`nm'.csv", "w"); for (i = 1; i <= rows(E); i++) fput(fh, strofreal(E[i,1]) + "," + strofreal(E[i,2])); fclose(fh)
}
