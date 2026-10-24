* nwsaom tutorial 3: goodness of fit and fixing a poor model
* Requires the core nwcommands and the package nwsaom.

nwwebuse glasgow, nwclear

* A deliberately thin model
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity seed(1)
estat gof, nsim(100) seed(7)
graph export "gof_thin_geodesic.png", name(gof_geodesic) width(900) replace

* Add transitive triplets and degree effects: better, but not enough
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip indegpopularity outactivity seed(1)
estat gof, nsim(100) seed(7)

* Add a smoother triadic closure effect (gwesp) and out-popularity
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) transtrip indegpopularity outactivity outpopularity seed(1)
estat gof, nsim(100) seed(7)
graph export "gof_final_geodesic.png", name(gof_geodesic) width(900) replace

* The triad census, and one test per period
estat gof, nsim(100) seed(7) stats(triad)
estat gof, nsim(100) seed(7) stats(outdegree) join(off)
