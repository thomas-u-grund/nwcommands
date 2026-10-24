* nwsaom tutorial 1: a first SAOM on the Glasgow friendship data
* Requires the core nwcommands and the package nwsaom.

nwsaom version
nwwebuse glasgow, nwclear
describe
nwsaom describe, waves(glasgow1 glasgow2 glasgow3)

nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip samex(smoke1) seed(1)
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip samex(smoke1) seed(1) detail
