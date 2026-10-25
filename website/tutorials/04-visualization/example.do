* Tutorial 4: Visualization
* Run from a directory with nwcommands net-installed (not a dev checkout).

* A basic plot of the current network - no styling, just structure
nwwebuse florentine, nwclear
nwplot flomarriage, scheme(s1network) export("plot_basic.svg") replace

* Layout algorithms position the same nodes differently
nwplot flomarriage, layout(circle) scheme(s1network) export("plot_circle.svg") replace
nwplot flomarriage, layout(kk) scheme(s1network) export("plot_kk.svg") replace

* Color, symbol, and size can each be driven by a variable
nwwebuse glasgow, nwclear
nwplot glasgow1, color(smoke1) symbol(sport1) size(alcohol1) scheme(s1network) export("plot_styled.svg") replace

* nwcommands ships three schemes purpose-built for network plots
nwplot glasgow1, color(smoke1) symbol(sport1) size(alcohol1) scheme(s2network) export("plot_scheme2.svg") replace
nwplot glasgow1, color(smoke1) symbol(sport1) size(alcohol1) scheme(s3network) export("plot_scheme3.svg") replace

* Highlight a shortest path between two nodes
nwwebuse florentine, nwclear
nwpath flomarriage, ego(medici) alter(peruzzi) generate(sp)
nwplot flomarriage, edgecolor(sp_1, legendoff) scheme(s1network) export("plot_path.svg") replace

* interactive opens an editable, browser-based version of the same plot:
* drag nodes to reposition them, edit the color/shape legend directly
nwwebuse glasgow, nwclear
nwplot glasgow1, color(smoke1) symbol(sport1) scheme(s1network) interactive noopen fname(interactive_plot)
display "`r(fname)'"

* The interactive workflow in four steps, with the advice network of the
* 71 lawyers of the Lazega law firm (colour = office, shape = practice,
* size = indegree).  1. Build the page; fname() names the file and noopen
* writes it without opening the viewer window.  generate(x y) keeps the layout.
nwwebuse lazega, nwclear
quietly nwdegree lazega_adv, generate(outdeg indeg)
set seed 42
nwplot lazega_adv, color(office, colorpalette(navy dkorange gs12)) symbol(practice) size(indeg) label(_nwnode) edgefactor(0.4) generate(x y) interactive noopen fname(lazega_advice_interactive)
display "`r(fname)'"

* 2. (In the browser: drag, recolour, move the sliders, Save nodes, Save edges.
* The two files below were saved in such a session.)
* 3. Bring the edits back.  No nodefactor() is given: the size slider is
* scaled so that the static plot has the proportions of the view.
nwplot lazega_adv, nodexy(x y) importcoords("lazega_saved_nodes.csv") edgeimport("lazega_saved_edges.csv") color(office, colorpalette(navy dkorange gs12)) symbol(practice) size(indeg) label(_nwnode) scheme(s1mono) labelopt(mlabsize(tiny)) export("plot_lazega_bringback.svg") replace

nwwebuse glasgow, nwclear

* nwmovie builds an interactive, browser-based timeline player directly
* from a sequence of waves - drag the slider, watch nodes and ties change
nwmovie glasgow1 glasgow2 glasgow3, noopen fname(friendship_movie)
