* nwsaom tutorial 9: undirected and two-mode networks
* Requires the core nwcommands and the package nwsaom.

nwwebuse glasgow, nwclear

* ---------------------------------------------------------------
* Part 1: undirected networks. Make the friendship networks
* undirected: a tie exists if either pupil named the other.
* ---------------------------------------------------------------
nwsym glasgow1, generate(u1) mode(max)
nwsym glasgow2, generate(u2) mode(max)
nwsym glasgow3, generate(u3) mode(max)
nwsaom describe, waves(u1 u2 u3)

* No reciprocity effect: every tie is reciprocated by definition.
* The default model: one pupil proposes a change and imposes it (forcing).
nwsaom, waves(u1 u2 u3) outdegree gwesp(.69) samex(smoke1) seed(4)

* Other rules for how an undirected tie changes
nwsaom, waves(u1 u2 u3) outdegree gwesp(.69) samex(smoke1) symtype(confirmation) seed(4)
nwsaom, waves(u1 u2 u3) outdegree gwesp(.69) samex(smoke1) symtype(joint) seed(4)

* Reciprocity is refused for an undirected network
capture noisily nwsaom, waves(u1 u2 u3) outdegree reciprocity
display "return code: " _rc

* ---------------------------------------------------------------
* Part 2: a two-mode network. The Davis "Southern women" data are
* a two-mode network observed once: 18 women, 14 social events.
* ---------------------------------------------------------------
nwwebuse davis, nwclear
nwsummarize

* Cut the 18 x 14 attendance matrix out of the full adjacency matrix
nwtomata davis, mat(D)
mata:
mode = st_sdata(., "_nwmode")
women = selectindex(mode :== "1")
events = selectindex(mode :== "2")
A1 = D[women, events]
rows(A1), cols(A1), sum(A1)
end

* No longitudinal two-mode data ship with the packages, so we create two
* later waves ourselves. A woman is picked at random, looks at every event
* and either keeps things as they are or toggles one attendance. Joining
* an event is more attractive the more women already attend it: the
* effect of indegree popularity is 0.3 and the density effect is -1.5.
mata:
rseed(20261027)
nw = rows(A1)
ne = cols(A1)
A = A1
st_matrix("W1", A1)
printf("wave 1: %g attendances\n", sum(A1))
for (w = 2; w <= 3; w++) {
    for (s = 1; s <= 200; s++) {
        i = ceil(runiform(1, 1) * nw)
        deg = colsum(A)
        u = J(1, ne + 1, 0)
        for (j = 1; j <= ne; j++) {
            sgn = A[i, j] ? -1 : 1
            u[j] = sgn * (-1.5) + 0.3 * ((deg[j] + sgn) ^ 1.5 - deg[j] ^ 1.5)
        }
        p = exp(u) / sum(exp(u))
        r = runiform(1, 1)
        k = 1
        while (k < ne + 1 & r > sum(p[1..k])) k++
        if (k <= ne) A[i, k] = 1 - A[i, k]
    }
    st_matrix("W" + strofreal(w), A)
    printf("wave %g: %g attendances\n", w, sum(A))
}
end
mata: mata clear
clear
nwset, mat(W1) bipartite name(women1)
nwset, mat(W2) bipartite name(women2)
nwset, mat(W3) bipartite name(women3)
* The rows (women) are the actors who choose among the columns (events)
nwsaom, waves(women1 women2 women3) outdegree indegpopularity seed(4)
nwsaom, waves(women1 women2 women3) outdegree indegpopularity outactivity seed(6)

* Let the events be the actors instead (the roles swap)
nwsaom, waves(women1 women2 women3) outdegree indegpopularity actormode(1) seed(7)
