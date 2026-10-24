* nwsaom tutorial 4: selection and influence, network-behavior co-evolution
* Requires the core nwcommands and the package nwsaom.

nwwebuse glasgow, nwclear
tabulate alcohol1
tabulate alcohol1 alcohol2
nwsaom describe, waves(glasgow1 glasgow2 glasgow3) behavior(alcohol1 alcohol2 alcohol3)

nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) behsim behavior(alcohol1 alcohol2 alcohol3) linear quadratic avalt seed(1)

* Selection through ego and alter effects as well
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) behsim behegox behaltx behavior(alcohol1 alcohol2 alcohol3) linear quadratic avalt seed(1)

* The alternative influence effect
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) behsim behavior(alcohol1 alcohol2 alcohol3) linear quadratic avsim seed(1)

* Goodness of fit now includes the behavior distribution
estat gof, nsim(100) seed(7)
