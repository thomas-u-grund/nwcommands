* nwsaom tutorial 12: conditional and unconditional estimation, threads and speed
* Requires the core nwcommands and the package nwsaom.

nwwebuse glasgow, nwclear

* The default for a network-only model: conditional estimation
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) seed(4)
display e(conditional)
matrix list e(rates)

* Unconditional estimation: the rates are estimated like the other parameters
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) unconditional seed(4)
display e(conditional)
matrix list e(rates)

* A model with a co-evolving behavior is always unconditional
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) behavior(alcohol1 alcohol2 alcohol3) linear quadratic avalt seed(4)
display e(conditional)

* Restarting an unconditional fit: coefficients (theta0) and rates (rate0)
quietly nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) unconditional seed(4)
matrix b = e(b)
matrix r = e(rates)
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) unconditional theta0(`=b[1,1]' `=b[1,2]' `=b[1,3]') rate0(`=r[1,1]' `=r[1,2]') seed(5)

* ---------------------------------------------------------------
* Speed. The simulations run in a compiled plugin on several threads.
* cores(1) uses one thread, the default uses all physical cores. The
* results for a given seed are identical.
* ---------------------------------------------------------------
display e(engine)
timer clear
timer on 1
quietly nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) indegpopularity outactivity seed(4) cores(1)
timer off 1
matrix b1 = e(b)
timer on 2
quietly nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) indegpopularity outactivity seed(4)
timer off 2
matrix b2 = e(b)
display "largest difference between the two sets of estimates: " mreldif(b1, b2)
timer list

* ---------------------------------------------------------------
* The length of the estimation: k0() simulations in phase 1, k3()
* in phase 3. More simulations give smaller convergence t-ratios
* and a steadier covariance matrix.
* ---------------------------------------------------------------
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) seed(4) k0(100) k3(3000) detail
