* nwcommands tutorial 17: networks over time
* Requires the core nwcommands.
nwwebuse glasgow, nwclear

* 1. Three waves of the same friendship network
nwsummarize glasgow1
nwsummarize glasgow2
nwsummarize glasgow3

* 2. How much did the ties change between waves?
nwturnover glasgow1 glasgow2, generate(stab12)
return list
nwturnover glasgow2 glasgow3, generate(stab23)
summarize stab12 stab23

* 3. Is the change in the same direction as the correlation?
nwcorrelate glasgow1 glasgow2
nwcorrelate glasgow2 glasgow3

* 4. A temporal edge list: one network, tie times as data
clear
input ego alter wave
1 2 1
2 3 1
1 3 2
2 3 2
3 4 3
end
nwset ego alter, time(wave) name(mynet)
nwattime mynet, at(1) name(t1)
nwattime mynet, at(2) name(t2)
nwsummarize t2
nwattime mynet, at(3) name(t3)
nwturnover t1 t2, generate(stab_t12)
