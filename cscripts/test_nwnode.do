cscript

do unw_core.do

nwclear
nwrandom 5, prob(1) name(mynet) labs(p1, p2, p3)
nwnode, ego("p2")






