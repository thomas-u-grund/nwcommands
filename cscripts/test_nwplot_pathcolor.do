cscript

* nwplot, edgecolor(): a path stored by nwpath, generate() is directed (i->j in the direction of the walk), but on an
* undirected network every tie of the path must be colored. Checked on the interactive page: the shortest Medici-Peruzzi
* path of the Florentine marriage network has three ties, and all three must carry the highlight color. Run from the
* repository root.

set graphics off
nwuse data/florentine, nwclear
quietly nwpath flomarriage, ego(medici) alter(peruzzi) generate(sp)
tempfile html
local f "`html'.html"
quietly nwplot flomarriage, edgecolor(sp_1, legendoff) interactive noopen fname("`f'")
mata: fh = fopen("`f'", "r"); s = ""; while ((l = fget(fh)) != J(0,0,"")) s = s + l; fclose(fh)
mata: pat = `"color":"0 0 255""'; st_local("nblue", strofreal((strlen(s) - strlen(subinstr(s, pat, ""))) / strlen(pat)))
assert `nblue' == 3
display "PASS nwplot_pathcolor: `nblue' blue ties"
