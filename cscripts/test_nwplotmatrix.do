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
