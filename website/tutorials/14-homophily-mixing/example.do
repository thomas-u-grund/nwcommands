* nwcommands tutorial 12: homophily, assortativity and mixing
* Requires the core nwcommands.
nwwebuse glasgow, nwclear
nwsummarize glasgow1
summarize sport1 smoke1 alcohol1

* 1. Assortativity: correlate a number across ties
nwassortativity glasgow1
nwassortativity glasgow1, attribute(alcohol1)
nwassortativity glasgow1, attribute(sport1)

* 2. Mixing tables for a categorical attribute
nwmixing glasgow1, attribute(sport1) permutations(500)
nwmixing glasgow1, attribute(smoke1) permutations(500)
nwmixing glasgow1, attribute(smoke1) permutations(1) row

* 3. Is the network the same later? Correlate two waves
nwcorrelate glasgow1 glasgow2

* 4. Plot
nwplot glasgow1, color(smoke1) label(_nwnode) scheme(s1network) export("plot_glasgow_smoke.svg") replace
