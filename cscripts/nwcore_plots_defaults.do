* Default calls (no name, saving, export or graph options) of the released core plot commands; each default picture is exported to the
* directory in the global NWP_OUT. Run with the released core and with the changed core: the PNG files must be identical.
* Used by test_nwcore_plots.do (reference directory: environment variable NWCORE_PLOT_REF) and by hand.
set graphics off
capture mkdir "$NWP_OUT"
nwclear
set seed 20261120
nwrandom 12, prob(.3) name(n1)
nwrandom 12, prob(.3) name(n2)
generate byte x = mod(_n, 3) == 0
generate byte toa = 1 + mod(_n, 4)

program define __nwp_exp
	args file
	quietly graph export "$NWP_OUT/`file'.png", replace width(600)
	graph drop _all
end

nwcug n1, stat(nwcomponents ##net##, generate(_ccomp) replace) rname(components) reps(40) seed(1) plot
__nwp_exp cug
set seed 5
nwqap n1 n2, permutations(25) type(regress) plot
__nwp_exp qap
nwdyads n1, plot
__nwp_exp dyads
nwtriads n1, plot
__nwp_exp triads
nwmotifs n1, plot
__nwp_exp motifs
set seed 6
nwmixing n1, attribute(x) plot permutations(25)
__nwp_exp mixing_plot
set seed 6
nwmixing n1, attribute(x) eiplot permutations(25)
__nwp_exp mixing_eiplot
nwtabulate n1 n2, plot
__nwp_exp tabulate2_plot
nwtabulate n1, attribute(x) plot
__nwp_exp tabulate3_plot
set seed 7
nwtabulate n1, attribute(x) eiplot permutations(25)
__nwp_exp tabulate3_eiplot
set seed 8
nwcorrelate n1 n2, permutations(25)
__nwp_exp correlate
nwdiffuse curve n1, toa(toa) graph silent
__nwp_exp diffuse
