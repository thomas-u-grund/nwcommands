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
nwplot glasgow1, color(smoke1) symbol(sport1) scheme(s1network) interactive noopen
display "`r(interactive)'"

* nwmovie builds an interactive, browser-based timeline player directly
* from a sequence of waves - drag the slider, watch nodes and ties change
nwmovie glasgow1 glasgow2 glasgow3, noopen fname(friendship_movie)
