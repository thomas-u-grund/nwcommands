cscript

do unw_core.do

* nwplot, labelopt(mlabvposition(varname)): label position per node from a variable (3.20.1)
nwclear
nwset, mat((0,1,1,0\1,0,1,0\1,1,0,1\0,0,1,0)) name(toy) undirected labs(A,B,C,D)
generate byte lpos = cond(_n <= 2, 9, 3)
nwplot toy, lab labelopt(mlabvposition(lpos))
nwplot toy, lab labelopt(mlabsize(small) mlabvpos(lpos))
nwplot toy if _n != 4, lab labelopt(mlabvposition(lpos))
* a string variable is refused
generate str1 spos = "9"
rcof "nwplot toy, lab labelopt(mlabvposition(spos))" == 198
* without mlabvposition() nothing changes
nwplot toy, lab labelopt(mlabposition(9))
* two-mode: women left, events right
nwwebuse davis, nwclear
generate byte lp = cond(_nwmode == "1", 9, 3)
nwplot davis, label(_nwnode) layout(bipartite, vertical) labelopt(mlabvposition(lp))
