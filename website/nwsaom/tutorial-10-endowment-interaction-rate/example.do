* nwsaom tutorial 10: endowment and creation, interactions, rate effects
* Requires the core nwcommands and the package nwsaom.

nwwebuse glasgow, nwclear

* A model to compare with
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transties seed(4)

* ---------------------------------------------------------------
* Part 1: endowment and creation. Split an effect into a part that
* counts when a tie is created and a part that counts when a tie
* is given up.
* ---------------------------------------------------------------
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity endow(transties) creation(transties) seed(6)

* Reciprocity: are reciprocated ties harder to give up than they are attractive to make?
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree endow(reciprocity) creation(reciprocity) seed(6)

* A covariate effect split in the same way
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transties endow(altx:alcohol1) creation(altx:alcohol1) seed(4)

* On a behavior
nwsaom, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity behavior(alcohol1 alcohol2) linear quadraticendow quadraticcreation seed(4)

* ---------------------------------------------------------------
* Part 2: interactions. Does the pull of reciprocity depend on how much
* the sender drinks?
* ---------------------------------------------------------------
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transties egox(alcohol1) interact(egox#reciprocity) seed(4) detail

* Two covariate effects interacting: do pupils who drink prefer friends who smoke like themselves?
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transties samex(smoke1) egox(alcohol1) interact(samex#egox) seed(4)

* ---------------------------------------------------------------
* Part 3: the rate. By default all pupils have the same rate.
* ---------------------------------------------------------------
* Do heavier drinkers change their friendships more often?
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transties ratecov(alcohol1) seed(4)
matrix list e(ratecoefs)

* Does the rate depend on how many friends a pupil has?
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transties outrate seed(4)
