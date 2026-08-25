cscript
do unw_core.do

nwwebuse florentine, nwclear

nwplotmatrix flomarriage, labelopt(labsize(tiny))

nwplotmatrix flomarriage, ylabel(,labsize(tiny)) xlabel(,labsize(tiny))

nwplotmatrix flomarriage, label(wealth) sortby(wealth)

nwplotmatrix flomarriage, scheme(s1mono) title("mynet")

nwplotmatrix flomarriage, scheme(s1mono) colorpalette(black) background(yellow) lcolor(red)

nwplotmatrix flomarriage, tievalue tievalueopt(mlabsize(tiny) mlabcolor(yellow))

nwplotmatrix flomarriage, group(seat)

nwplotmatrix flomarriage, group(seat, lcolor(green))
assert _rc == 0

* moderate-severity pass, visualization group: a single-node network
* used to crash with a generic "invalid syntax" (r198) rather than a
* meaningful message - root-caused to an undefined local (`cbak', only
* ever assigned inside a now-empty `foreach' loop over color levels,
* since there is nothing to tabulate for a single node) that a later
* line referenced unconditionally. Fixed with a clear, purpose-written
* error instead of attempting to make an inherently unrenderable 1x1
* matrix plot succeed (unlike nwplot's own analogous single-node fix,
* which DOES still render - a node-layout plot can trivially place one
* dot, unlike a matrix plot of a 1x1 adjacency matrix).
set graphics off
nwclear
nwset, mat((0)) name(onenode) undirected labs(A)
capture noisily nwplotmatrix onenode
assert _rc == 198
di "=== SINGLE-NODE NETWORK REGRESSION VERIFIED ==="
