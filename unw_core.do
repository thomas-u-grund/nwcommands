clear mata

*! version 1.0.0  02oct2015

/*
!! low level Mata functions for nwcommands 
*/

/* -------------------------------------------------------------------- */
//!! require a Stata version change before release
version 12



set matastrict on
	
local NWVersion	1

/* -------------------------------------------------------------------- */
					/* Shorthands for types		*/
local RS	real scalar
local RR	real rowvector
local RC	real colvector
local RM	real matrix

local SS	string scalar
local SR	string rowvector
local SC	string colvector
local SM	string matrix
local BOOL	real scalar

/* -------------------------------------------------------------------- */
					/* Derived types 		*/
local 	True	1
local 	False	0

//!! more derived types

/* -------------------------------------------------------------------- */

unw_defs

/*					
local 	vxNWs		nws
local 	vxNWsdef	nws_def
local 	vxNWsder	nws_der		
local 	vxNWdef		nw_def	*/	


local 	NWs			`vxNWs'
local 	NWsdef		`vxNWsdef'
local 	NWsder		`vxNWsder'
local 	NWdef		`vxNWdef'

/* -------------------------------------------------------------------- */
					/* constants			*/
local 	cDftNWpef	"network_"	//default network name pefix
local 	cDftNodepef	"net"		//default node name prefix

/* -------------------------------------------------------------------- */
					/* Error codes			*/
local 	errNWsCreate	480		
local 	errNodeDupName	481	
local 	errNWsNotFound	482		
local 	errNWsExists	483	

/* -------------------------------------------------------------------- */
					/* Utilities			*/
mata:


class priorityQueue {
	real matrix queue
	real matrix positions
	real scalar counter
	
	void insert()
	real matrix removeMin()
	real matrix removeIndex()
	real matrix removePosition()
	void init()
	real scalar isEmpty()
	void changeKey()
	void changeKeyIndex()
	void show()
	void swapPositions()
	void bubbleUp()
	void bubbleDown()
	void new()
}

void priorityQueue::changeKeyIndex(real scalar index, real scalar newKey){
	real scalar pos 

	if (newKey != . ){
		if (positions[index] == .) {
			queue = queue, (newKey\index)
			positions[index] = cols(queue)
			bubbleUp(cols(queue))
		}
		else if (index < cols(positions)) {
			pos = positions[index]
			changeKey(pos, newKey)
			bubbleUp(pos)
		}
	}
}

void priorityQueue::new(){
	this.init()
	counter = 0
}

void priorityQueue::swapPositions(real scalar a, real scalar b){
	
	real scalar indexA, indexB, p
	real matrix temp
	
	if (a <= cols(queue) & b <= cols(queue) & a != b) {

		indexA = queue[2,a]
		indexB = queue[2,b]
		temp = queue[.,a]
		queue[.,a] = queue[.,b]
		queue[.,b] = temp
		p = positions[indexA]
		positions[indexA] = positions[indexB]
		positions[indexB] = p
	}
}

void priorityQueue::bubbleUp(real scalar pos){
	
	real scalar p, parent, parentKey, key, index, parentIndex
	real matrix temp
	
	parent = trunc(pos / 2)
	if (parent == 0) {
		parent = 1
	}
	parentIndex = queue[2,parent]
	parentKey = queue[1,parent]
	
	key = queue[1,pos]
	index = queue[2, pos]

	// Bubble up
	if (key < parentKey & parent != pos ) {
		swapPositions(pos, parent)
		bubbleUp(parent)
	}
}

void priorityQueue::bubbleDown(real scalar pos){
	
	real scalar p, child1, child2, child1Key, child2Key, key, index, child1Index, child2Index, childMinKey, childMin
	real matrix temp
	
	if (pos < cols(queue)) {
	child1 = pos * 2
	child2 = pos * 2 + 1
	child1Key = .
	child2Key = .
	child1Index = .
	child2Index = .

	if (cols(queue) >= child1){
		child1Key = queue[1,child1]
		child1Index = queue[2,child1]
	}
	if (cols(queue) >= child2){
		child2Key = queue[1,child2]
		child2Index = queue[2,child2]
	}
	childMinKey = min((child1Key, child2Key))
	childMin = child1
	if (childMinKey == child2Key) {
		childMin = child2
	}
	
	key = queue[1,pos]
	index = queue[2,pos]

	// Bubble down
	if (key > child1Key & key < child2Key) {
		swapPositions(pos, childMin)
		bubbleDown(childMin)
	}
	else if (key >= child1Key) {
		swapPositions(pos, child1)
		bubbleDown(child1)
	}
	else if (key > child2Key) {
		swapPositions(pos, child2)
		bubbleDown(child2)
	}
	}
}


void priorityQueue::show(){
	"Queue"
	queue
	"Positions"
	positions
}


void priorityQueue::changeKey(real scalar pos, real scalar newKey){
	real matrix temp
	
	temp = queue[1,pos]
	queue[1,pos] = newKey
	if (newKey < temp) {
		bubbleUp(pos)
		bubbleUp(pos)
	}
	else {
		bubbleDown(pos)
		bubbleDown(pos)
	}
}

void priorityQueue::init(){
	queue = J(2,0,.)
	counter = 0
	positions = J(1,0,.)
}

real scalar priorityQueue::isEmpty(){
	return(cols(queue) < 1)
}

void priorityQueue::insert(real scalar newEntry){	
	
	counter = counter + 1

	// Add new entry at the end of the list
	queue = queue, (newEntry\ (counter))
	positions = positions, ((cols(queue) ))
	
	// Check position of newEntry
	real scalar k, parent
	real matrix temp
	k = cols(queue)
	parent = trunc(k / 2 )
	if (parent == 0) {
		parent = 1
	}

	// If necessary bubbleUp the newEntry
	while (queue[1,k] < queue[1,parent] & parent != k){
		bubbleUp(k)
		k = parent
		parent = trunc(k / 2)
		if (parent == 0) {
			parent = 1
		}
	}	
}


real matrix priorityQueue::removeMin(){
	real matrix temp, p, c
	
	temp = J(2,1,.)
	if (isEmpty() == 0) {
		p = queue[2,1]
		temp = queue[.,1]
		c = cols(queue)
		if (c > 1) {
			swapPositions(1, c)
			queue = queue[,(1..(c-1))]
			if (isEmpty() == 0){
				bubbleDown(2)
				bubbleDown(1)
			}
		}
		else {
			queue = J(2,0,.)
		}	
		positions[p] = .
	}
	return(temp)
}

real matrix priorityQueue::removePosition(real scalar pos){
	real matrix temp
	
	temp = J(2,1,.)
	if (isEmpty() == 0  & pos <= cols(queue)) {
		temp = queue[.,pos]
		swapPositions(pos, cols(queue))
		positions[queue[2,cols(queue)]] = .
		queue = queue[,(1..(cols(queue)-1))]
		if (pos < cols(queue)) {
			bubbleDown(pos)
			bubbleUp(pos)
		}
	}
	return(temp)
}

real matrix priorityQueue::removeIndex(real scalar index){
	real matrix temp, pos
	
	temp = J(2,1,.)
	if (isEmpty() == 0  & index <= cols(positions)) {
		pos = positions[index]
		temp = queue[.,pos]
		swapPositions(pos, cols(queue))
		positions[queue[2,cols(queue)]] = .
		queue = queue[,(1..(cols(queue)-1))]
		if (pos < cols(queue)) {
			bubbleDown(pos)
			bubbleUp(pos)
		}
	}
	return(temp)
}


/* 
	Find the first index of matching string 
*/
real scalar first_index_match(string vector src, string scalar t)
{
	real scalar i, dim
	if (cols(src) == 0 | rows(src) == 0){
		return(0)
	}
	dim = rows(src)*cols(src)
	for(i=1; i<=dim; i++){
		if(src[i]==t) {
			return(i)
		}
	}
	return(0)
}

/*
	Build a two-mode "1"/"2" mode vector, one entry per node in
	nodenames' own order, by testing label membership in group1labels -
	NOT by node position. Used by nw2fromedge (see its own comment for
	why position-based assignment is wrong: nodes are numbered by
	sorting the combined label set of both edgelist variables together,
	so a mode-1 and a mode-2 label can land at adjacent node indices).
*/
string colvector modes_from_labels(string rowvector nodenames, string colvector group1labels)
{
	real scalar n, i
	string colvector result
	n = cols(nodenames)
	result = J(n, 1, "2")
	for(i=1; i<=n; i++){
		if (first_index_match(group1labels, nodenames[i]) > 0) {
			result[i] = "1"
		}
	}
	return(result)
}

/*
	Display various error messages 
*/
void error_handle(string scalar r, real scalar code){
	errprintf(r)  
	exit(code)
}

/*
	Match two string vectors
*/
real matrix match_xy(string matrix x, string matrix y){
	real scalar i, j, Mdim
	real matrix M
	string scalar x_i
	
	Mdim = rows(x)
	M = J(Mdim,2,.)
	M[(1::rows(x)),1] = (1::rows(x))

	for (i = 1; i<= rows(x);i++){
		for (j = 1; j<= rows(y);j++){
			if (x[i] == y[j]) {
				M[i,2] = j
			}
		}
	}
	return(M)
}

/* 

Dijkstra's algorithm for finding shortest paths

*/

real matrix Dijkstra_dist(real matrix G, real scalar alpha){
	real scalar n, i
	real matrix dist, Ginv
	
	n = rows(G)
	Ginv = (J(n,n,1):/ G)
	dist = Dijkstra(Ginv,1, alpha)[.,1]
	for (i  = 2; i<= n; i++) {
		dist = (dist, Dijkstra(Ginv,i, alpha)[.,1])
	}
	return(dist')
}


real matrix Dijkstra(real matrix G, real scalar source ,real scalar alpha){
	real matrix Q, dist, prev, alt, u, neighbors
	real scalar k,i,n, nneigh, oneneigh
	

	_editvalue(G,.,0)
	n = rows(G)

	Q = (1::n)
	dist = J(n,1,.)
	prev = J(n,1,.)
	
	dist[source] = 0

	while (rows(Q) > 0){

		u = select(Q,(dist[Q] :== min(dist[Q])))
		u = u[1]
		Q = select(Q, (Q:!=u))
		
		alt = ((G[u,.]):^alpha) :+ dist[u]
		neighbors = select((1::n),(G[u,.] :!= 0)')
		nneigh = rows(neighbors)
		for (i = 1; i<= nneigh; i++) {
			oneneigh = neighbors[i]
			if (alt[oneneigh] < dist[oneneigh]){
				dist[oneneigh] = alt[oneneigh]
				prev[oneneigh] = u
			}
		}
	}
	return(dist, prev)
}

// BROKEN function - Does not give correct results !!!

real matrix Dijkstra_fast(real matrix G, real matrix Glist, real scalar source ,real scalar alpha){
	real matrix Q, dist, prev, alt, u, neighbors
	real scalar k,i,n, nneigh, oneneigh, nlist
	

	//_editvalue(G,.,0)
	n = rows(G)
	nlist = cols(Glist)
	
	Q = (1::n)
	dist = J(n,1,.)
	prev = J(n,1,.)
	
	dist[source] = 0

	while (rows(Q) > 0){

		u = select(Q,(dist[Q] :== min(dist[Q])))
		u = u[1]
		Q = select(Q, (Q:!=u))
		
		alt = ((G[u,.]):^alpha) :+ dist[u]
		alt = ((G[u,.]):^alpha) :+ dist[u]
		nneigh = Glist[u,nlist]
		if (nneigh > 0){
			neighbors =  Glist[u,(1::nneigh)]
		}

		for (i = 1; i<= nneigh; i++) {
			oneneigh = neighbors[i]
			
			if (alt[oneneigh] < dist[oneneigh]){
				dist[oneneigh] = alt[oneneigh]
				prev[oneneigh] = u
			}
		}
	}
	return(dist, prev)
}


real matrix Floyd_Warshall(real matrix G, scalar alpha){
	real matrix dist, z
	real scalar n, i, j, k
	

	_editvalue(G,0,.)
	dist = G
	n = rows(G)
	
	for (i = 1; i<=n; i++){
		if (i != j) {
		for (j= 1 ; j<=n; j++) {
			if (j != k & k != i) {
			for (k = 1; k<=n; k++) {
				if ((dist[i,j] > (dist[i,k] + (dist[k,j]))) | dist[i,j] ==.){
					dist[i,j] = (dist[i,k] + (dist[k,j]))
				}
			}
			}
		}
		}
	}
	return(dist)
}

real matrix Brute_dist(real matrix G){
	real matrix dist, found, prev, prev_old
	real scalar i, n
	
	n = rows(G)
	_editmissing(G,0)
	
	dist = G
	prev = G
	_editvalue(prev,0,.)
	prev_old = prev
	found = G
	i = 2
	
	while ((sum(found) < (n * n-1)) & i < n){
		found = found * G
		found = found :/ found
		_editmissing(found, 0)
		_diag(found, 0)
		dist = dist :+ ((found :!= 0) :* (prev:==.) :* (dist:==0) :* i)
		_diag(dist, J(n,1,0)) 
		i = i + 1
		prev = dist :/ dist
		if (prev == prev_old) {
			i = n
		}
		prev_old = prev
	}
	_editvalue(dist,0,.)
	return(dist)
}

real matrix correlate_nets_rep(real scalar reps, real matrix net1, real matrix net2){
	real matrix temp_net1, results, permutationVec, perm_net1, ifcond
	real scalar nsize, i
	
	temp_net1 = net1
	nsize = rows(temp_net1)
	results = J(reps, 1, 0)
	for (i = 1; i <= reps; i ++) {
		permutationVec = unorder(nsize)
		perm_net1 = temp_net1[permutationVec, permutationVec]
		results[i] = correlate_nets(perm_net1, net2)
	}
	return(results)
}

real scalar correlate_nets(real matrix net1, real matrix net2){
	real scalar r, c
	real matrix Z, temp, corr
	
	Z = J(rows(net1), cols(net1), 1)
	r = rows(net1)
	c = cols(net1)
	
	temp = J(sum(Z:!=0),2, 0)
	temp[.,1] = select(vec(net1), vec(Z))
	temp[.,2] = select(vec(net2), vec(Z))
	corr = correlation(temp)
	return(corr[2,1])
}

/*

Community detection: Newman modularity Q and the Louvain method (Blondel et al. 2008)

*/

real scalar Modularity(real matrix W, real matrix membership, real scalar resolution){
	real matrix k, idx
	real scalar m2, ncomm, q, c

	k = rowsum(W)
	m2 = sum(k)

	if (m2 == 0){
		return(0)
	}

	ncomm = max(membership)
	q = 0
	for (c = 1; c <= ncomm; c++){
		idx = selectindex(membership :== c)
		if (cols(idx) > 0){
			q = q + sum(W[idx, idx]) - resolution * (sum(k[idx,1])^2) / m2
		}
	}
	return(q / m2)
}

/*
	Pops and returns the first element of row vector X, shrinking X in
	place (Mata passes matrix arguments by reference by default - verified
	directly before relying on it here). Used as a FIFO dequeue (Queue, new
	elements appended at the back) and, equivalently, a LIFO pop (Stack,
	new elements prepended at the front) by calculate_betweenness()'s
	Brandes' algorithm - both just need "take the front element". Not
	previously defined anywhere in this file; calculate_betweenness() has
	called it since it was written, so nwbetween.ado has never been able to
	run to completion until this was added.
*/
real scalar dequeue(real matrix X){
	real scalar v

	v = X[1,1]
	if (cols(X) > 1){
		X = X[1,(2::cols(X))]
	}
	else {
		X = J(1,0,.)
	}
	return(v)
}

/*
	Sum of edge weights from node i to all nodes currently assigned to community c
*/
real scalar nw_community_kin(real matrix W, real scalar i, real matrix comm, real scalar c){
	real matrix idx

	idx = selectindex(comm :== c)
	if (cols(idx) == 0){
		return(0)
	}
	return(sum(W[i, idx]))
}

/*
	Remap an arbitrary integer-labeled vector to dense labels 1..k
*/
real matrix nw_community_denserelabel(real matrix v){
	real matrix u, out
	real scalar i, n

	n = rows(v)
	u = uniqrows(v)
	out = J(n, 1, 0)
	for (i = 1; i <= n; i++){
		out[i,1] = selectindex(u :== v[i,1])
	}
	return(out)
}

/*
	Louvain community detection (Blondel et al. 2008): greedy local modularity-gain
	moves (phase 1, fixed node visiting order for reproducibility), then aggregate
	communities into a super-node graph and recurse (phase 2), until a full sweep at
	some level produces no further moves.
*/
real matrix Louvain(real matrix W, real scalar resolution){
	real matrix k, comm, Stot, level_comm, W2, M, agg_comm, finalcomm, neighbor_comms, idx
	real scalar n, m2, i, c_old, best_c, best_gain, gain, moved, sweep, k_i, a, c, nc2

	n = rows(W)
	k = rowsum(W)
	m2 = sum(k)

	if (m2 == 0 | n <= 1){
		return((1::n))
	}

	comm = (1::n)
	Stot = k

	moved = 1
	sweep = 0
	while (moved == 1 & sweep < 100){
		moved = 0
		sweep = sweep + 1
		for (i = 1; i <= n; i++){
			c_old = comm[i,1]
			k_i = k[i,1]

			Stot[c_old,1] = Stot[c_old,1] - k_i

			idx = selectindex(W[i,.] :!= 0)
			if (cols(idx) > 0){
				neighbor_comms = uniqrows(comm[idx',1])
			}
			else {
				neighbor_comms = J(0,1,0)
			}
			if (sum(neighbor_comms :== c_old) == 0){
				neighbor_comms = neighbor_comms \ c_old
			}

			best_c = c_old
			best_gain = nw_community_kin(W, i, comm, c_old) / m2 - resolution * Stot[c_old,1] * k_i / (m2^2)

			for (a = 1; a <= rows(neighbor_comms); a++){
				c = neighbor_comms[a,1]
				gain = nw_community_kin(W, i, comm, c) / m2 - resolution * Stot[c,1] * k_i / (m2^2)
				if (gain > best_gain + 1e-12){
					best_gain = gain
					best_c = c
				}
			}

			comm[i,1] = best_c
			Stot[best_c,1] = Stot[best_c,1] + k_i
			if (best_c != c_old){
				moved = 1
			}
		}
	}

	level_comm = nw_community_denserelabel(comm)
	nc2 = max(level_comm)

	if (nc2 == n){
		return(level_comm)
	}

	M = J(n, nc2, 0)
	for (i = 1; i <= n; i++){
		M[i, level_comm[i,1]] = 1
	}
	W2 = M' * W * M

	agg_comm = Louvain(W2, resolution)

	finalcomm = J(n, 1, 0)
	for (i = 1; i <= n; i++){
		finalcomm[i,1] = agg_comm[level_comm[i,1],1]
	}

	return(nw_community_denserelabel(finalcomm))
}

/*
	CONCOR (CONvergence of iterated CORrelations - Breiger, Boorman & Arabie
	1975): builds each node's tie profile (its outgoing ties stacked on its
	incoming ties, self-tie excluded - this captures directed structure
	naturally, unlike an undirected-only method such as Louvain above), takes
	the pairwise correlation matrix of these profiles (Mata's built-in
	correlation(), which treats each column as a variable and each row as an
	observation - exactly this shape), then repeatedly re-correlates that
	matrix with itself. In well-separated block structure this is a
	contraction mapping that converges to a matrix of exactly +1/-1 entries
	(nodes end up perfectly correlated within a block, perfectly anti-
	correlated across the two halves of the split it induces); real data is
	not always this clean, so convergence is capped at maxiter rather than
	asserted. A zero-variance tie profile - every node has this within a
	recursive sub-split once a block's members only tie to nodes *outside*
	the block, since only within-block ties are considered at that point,
	a normal and expected outcome, not a user-input error - produces a
	missing correlation matrix rather than a division-by-zero crash; the
	caller (ConcorSplitIDs below) checks for this and treats it as "this
	branch cannot be split further," the same as any other degenerate
	split. A genuinely isolated node in the *original, full* network (zero
	ties in every direction, so it has no information to split on at any
	depth) is instead checked once, explicitly, before recursion starts -
	see calculate_concor below.
*/
real matrix ConcorConverge(real matrix net, real scalar maxiter){
	real matrix profile, C, Cnew
	real scalar iter

	profile = net \ net'
	C = correlation(profile)
	if (hasmissing(C)){
		return(C)
	}
	for (iter = 1; iter <= maxiter; iter++){
		Cnew = correlation(C)
		if (hasmissing(Cnew)){
			return(Cnew)
		}
		if (max(abs(Cnew :- C)) < 1e-9){
			return(Cnew)
		}
		C = Cnew
	}
	return(C)
}

/*
	Recursively bisect `nodeidx' (a subset of 1..n, indexing into the original
	network `net') `depth' times using CONCOR, returning a rows(nodeidx) x 2
	matrix of [original node index, block id] pairs. Block ids for a depth-d
	call are drawn from 1..2^d, but a branch that cannot be split further
	(all its members end up on the same side of a bisection - a legitimate,
	documented CONCOR outcome, not an error) simply keeps a single id across
	its whole id range rather than every slot necessarily being used.
*/
real matrix ConcorSplitIDs(real matrix net, real scalar depth, real scalar maxiter, real matrix nodeidx){
	real matrix sub, C, split, idxA, idxB, resA, resB, res
	real scalar n

	n = rows(nodeidx)
	if (depth == 0 | n <= 1){
		res = J(n, 2, .)
		res[.,1] = nodeidx
		res[.,2] = J(n,1,1)
		return(res)
	}

	sub = net[nodeidx, nodeidx]
	C = ConcorConverge(sub, maxiter)

	if (hasmissing(C)){
		res = J(n, 2, .)
		res[.,1] = nodeidx
		res[.,2] = J(n,1,1)
		return(res)
	}

	split = (C[.,1] :> 0)

	idxA = select(nodeidx, split)
	idxB = select(nodeidx, 1 :- split)

	if (rows(idxA) == 0 | rows(idxB) == 0){
		res = J(n, 2, .)
		res[.,1] = nodeidx
		res[.,2] = J(n,1,1)
		return(res)
	}

	resA = ConcorSplitIDs(net, depth-1, maxiter, idxA)
	resB = ConcorSplitIDs(net, depth-1, maxiter, idxB)
	resB[.,2] = resB[.,2] :+ 2^(depth-1)

	res = resA \ resB
	res = sort(res, 1)
	return(res)
}

/*
	Fitness of a discrete core/periphery assignment (Borgatti & Everett 1999):
	the Pearson correlation between the observed network `net' and the ideal
	discrete core-periphery pattern it implies - a tie is "expected" between
	any pair where at least one member is core (core-core and core-periphery
	ties both count as structurally expected; only periphery-periphery pairs
	are expected to be tie-free). Self-comparisons are excluded via `idx'
	(precomputed once by the caller - see CorePeriphery below - since it is
	the same off-diagonal mask on every call within one optimization run,
	not worth recomputing per evaluation).
*/
real scalar nw_cp_fitness(real matrix net, real matrix core, real matrix idx){
	real matrix pattern, avec, pvec
	real scalar n

	n = rows(net)
	pattern = ((core * J(1,n,1)) :+ (J(n,1,1) * core')) :> 0
	avec = vec(net)[idx,1]
	pvec = vec(pattern)[idx,1]
	return(correlation((avec,pvec))[1,2])
}

/*
	Discrete core-periphery detection via local search: start from a degree-
	based seed (above-average-degree nodes as an initial core guess), then
	repeatedly try flipping each node's core/periphery status in turn
	(fixed 1..n order, for reproducibility - the same convention Louvain
	above already established), keeping the flip only if it improves the
	fitness score, until a full sweep produces no further improvement or
	`maxiter' sweeps are reached. This is a greedy local optimum, not a
	guaranteed global one - the discrete core-periphery problem is
	combinatorial (2^n possible partitions), the same character of problem
	Louvain's own greedy local search already accepts for modularity.
*/
real matrix CorePeriphery(real matrix net, real scalar maxiter){
	real matrix mask, idx, core, deg
	real scalar n, sweep, moved, i, fit0, fit1

	n = rows(net)
	if (max(net) <= 0){
		errprintf("Core-periphery detection requires at least one tie in the network.\n")
		exit(error(6556))
	}

	mask = J(n,n,1)
	_diag(mask, 0)
	idx = selectindex(vec(mask))

	deg = rowsum(net) :+ colsum(net)'
	core = (deg :> mean(deg))

	sweep = 0
	moved = 1
	while (moved & sweep < maxiter){
		moved = 0
		sweep++
		for (i=1; i<=n; i++){
			fit0 = nw_cp_fitness(net, core, idx)
			core[i,1] = 1 - core[i,1]
			fit1 = nw_cp_fitness(net, core, idx)
			if (fit1 > fit0 + 1e-12){
				moved = 1
			}
			else {
				core[i,1] = 1 - core[i,1]
			}
		}
	}

	return(core \ nw_cp_fitness(net, core, idx))
}

/*
	Bron-Kerbosch (1973) maximal clique enumeration, without pivoting -
	the classic, textbook recursive algorithm: R is the clique built so
	far, P is the set of candidates that could still extend it (every
	remaining candidate is already known to be tied to every member of
	R, an invariant maintained by intersecting with each chosen node's
	own neighbor set on recursion), X is the set of candidates already
	fully explored (excluded so the same maximal clique is never
	reported twice, once found via a different member as the "last one
	added"). A clique is maximal - reported - exactly when both P and X
	are empty: no candidate remains that could extend it, and none was
	skipped that would have. All three sets are represented as 0/1
	indicator row vectors over 1..n (not lists of node indices) - Mata
	has no lightweight dynamic set type, and elementwise :& intersection
	is both simpler and faster than fiddling with `uniqrows()`-style set
	operations on index lists for this. Deliberately the plain, unpivoted
	version rather than the standard pivoting optimization (which
	restricts the outer loop to a subset of P chosen to minimize
	recursive branching) - correctness here is easier to reason about
	and verify by hand than the pivoted variant, and this package's own
	target network scale (moderate SNA datasets, not internet-scale
	graphs) does not need the asymptotic improvement pivoting buys.
	Worst-case exponential in the number of maximal cliques a graph can
	have (a mathematical property of the *problem*, true of any correct
	algorithm, not a defect of this particular implementation) - a dense
	network could in principle take a very long time; not specially
	guarded against here beyond documenting it (see nwclique.ado's own
	"Supported network types" section).
*/
real matrix BronKerbosch(real matrix adj, real rowvector R, real rowvector P, real rowvector X){
	real matrix results, childresults
	real rowvector Pcopy, Nv, newR
	real scalar n, v

	n = cols(P)
	results = J(0, n, 0)

	if (sum(P) == 0 & sum(X) == 0){
		return(R)
	}

	Pcopy = P
	for (v = 1; v <= n; v++){
		if (Pcopy[v] == 0) continue
		Nv = adj[v,.]
		newR = R
		newR[v] = 1
		childresults = BronKerbosch(adj, newR, P :& Nv, X :& Nv)
		results = results \ childresults
		P[v] = 0
		X[v] = 1
	}
	return(results)
}

/*
	is_valid_kplex(S, k): S is the induced adjacency submatrix (diagonal
	zeroed) of some candidate node set; true iff every member's degree
	within S is at least (size of S) - k, the Seidman & Foster (1978)
	definition of a k-plex (a k=1 plex is exactly a clique - every
	member missing 0 ties - so this generalizes BronKerbosch()'s own
	notion directly). A size-0 or size-1 set is trivially always valid
	(nothing to violate).
*/
real scalar is_valid_kplex(real matrix S, real scalar k){
	real scalar s

	s = rows(S)
	if (s <= 1) return(1)
	return(min(rowsum(S)) :>= (s - k))
}

/*
	KPlex(): maximal k-plex enumeration, structurally the same
	Bron-Kerbosch-style R/P/X backtracking as BronKerbosch() above (see
	its own header comment for the full explanation of the R/P/X
	scheme and why plain 0/1 indicator row vectors are used instead of
	index lists) - the only real difference is HOW a candidate is
	determined to still be addable to the set being built. For a
	clique, a candidate must be adjacent to every existing member,
	checked by a cheap neighbor-row intersection; a k-plex candidate
	only needs each member's own missing-tie budget (k-1) to still be
	respected once the candidate joins, which depends on the exact
	membership, not just simple adjacency - so `newR` is a genuine
	*superset* check on the whole induced (m+1)-node submatrix, via
	is_valid_kplex(), for every remaining candidate, at every level.
	This is asymptotically more expensive than BronKerbosch()'s own
	set-intersection update but unambiguously correct, matching this
	session's own established preference (see BronKerbosch()'s own
	comment) for hand-verifiable correctness over asymptotic elegance
	at this package's target (moderate) network scale.

	Correctness of reusing the same R/P/X maximality-tracking scheme
	for k-plexes (not just cliques) rests on k-plexes being downward
	*hereditary*: for any valid k-plex S and any subset S' of S, S' is
	itself a valid k-plex under the same k. Proof sketch: for r in S',
	degree_r(S') >= degree_r(S) - |S \ S'| (removing nodes can remove at
	most that many of r's neighbors) >= (|S| - k) - |S \ S'| = |S'| - k,
	using the given bound degree_r(S) >= |S| - k. This is exactly the
	property BronKerbosch()'s own P/X bookkeeping relies on (a node
	ruled out at one point in the search can never legitimately become
	part of a still-unexplored maximal set built from a superset of the
	current R), so the same non-redundant enumeration argument applies.
*/
real matrix KPlex(real matrix adj, real scalar k, real rowvector R, real rowvector P, real rowvector X){
	real matrix results, childresults, S
	real rowvector Pcopy, newR, newP, newX, Ridx, idx
	real scalar n, v, u

	n = cols(P)
	results = J(0, n, 0)

	if (sum(P) == 0 & sum(X) == 0){
		return(R)
	}

	Pcopy = P
	for (v = 1; v <= n; v++){
		if (Pcopy[v] == 0) continue

		newR = R
		newR[v] = 1
		Ridx = selectindex(newR)

		newP = J(1, n, 0)
		for (u = 1; u <= n; u++){
			if (u == v | P[u] == 0) continue
			idx = (Ridx, u)
			S = adj[idx, idx]
			if (is_valid_kplex(S, k)) newP[u] = 1
		}

		newX = J(1, n, 0)
		for (u = 1; u <= n; u++){
			if (X[u] == 0) continue
			idx = (Ridx, u)
			S = adj[idx, idx]
			if (is_valid_kplex(S, k)) newX[u] = 1
		}

		childresults = KPlex(adj, k, newR, newP, newX)
		results = results \ childresults
		P[v] = 0
		X[v] = 1
	}
	return(results)
}

/*
	bfs_augment(cap, flow, s, t, parent): a single Edmonds-Karp BFS
	augmenting-step over an explicit N x N capacity/flow matrix pair
	(the standard, textbook max-flow algorithm - BFS repeatedly finds
	the shortest remaining-capacity path from s to t, augments along
	it, until none remains). Returns 1 and fills `parent' with the
	predecessor chain (parent[v] = the node BFS reached v from) if a
	path with positive residual capacity (cap[u,v] - flow[u,v] > 0)
	exists from s to t; returns 0 (parent left as J(1,N,0)) once none
	does, at which point the accumulated flow equals the max flow
	(the standard max-flow/min-cut theorem). Used by
	maxflow_vertex_split() below on a "vertex-split" capacity graph,
	not a plain edge-capacity graph - see that function's own header
	comment for what the capacities themselves represent.
*/
real scalar bfs_augment(real matrix cap, real matrix flow, real scalar s, real scalar t, real rowvector parent){
	real scalar N, u, v, qhead, qtail
	real rowvector visited, queue

	N = rows(cap)
	visited = J(1,N,0)
	parent = J(1,N,0)
	queue = J(1,N,0)
	qhead = 1
	qtail = 1
	queue[1] = s
	visited[s] = 1

	while (qhead <= qtail) {
		u = queue[qhead]
		qhead++
		for (v=1; v<=N; v++) {
			if (visited[v] == 0 & (cap[u,v] - flow[u,v]) > 0) {
				visited[v] = 1
				parent[v] = u
				if (v == t) return(1)
				qtail++
				queue[qtail] = v
			}
		}
	}
	return(0)
}

/*
	maxflow_vertex_split(adj, s, t): the *vertex* (node) version of
	max-flow/min-cut, via the standard node-splitting reduction to
	ordinary edge-capacity max-flow (Even 1979): every node v becomes
	two nodes in the flow graph, v_in (index v) and v_out (index n+v),
	joined by a capacity-1 edge - so routing flow through v at all
	"costs" exactly 1 unit of a vertex cut, regardless of how many of
	v's own ties get used - and every original tie (u,w) becomes two
	effectively-uncapped edges u_out->w_in and w_out->u_in (undirected,
	traversable either way; a large-but-finite capacity is used instead
	of a true infinity since Mata has no such value and the true
	maximum possible flow can never exceed n anyway). s and t
	themselves get an uncapped v_in->v_out edge too, since a vertex cut
	separating them is only meaningful for the nodes *between* them,
	never s or t themselves. Requires s and t to not be directly tied
	(adj[s,t]==0) - Menger's theorem's own vertex-connectivity form
	only has a meaningful "separating vertex set" interpretation for
	non-adjacent pairs; vertex_connectivity() below only ever calls
	this on non-adjacent pairs, and separately handles the complete-
	graph case (no non-adjacent pairs exist at all) on its own. By the
	max-flow/min-cut theorem, the resulting max flow value from s_out
	to t_in equals the minimum number of nodes whose removal
	disconnects s from t - i.e. exactly Menger's own vertex-
	connectivity between s and t.
*/
real scalar maxflow_vertex_split(real matrix adj, real scalar s, real scalar t){
	real scalar n, N, bignum, u, v, i, maxf, pathflow, pf
	real matrix cap, flow
	real rowvector parent

	n = rows(adj)
	N = 2 * n
	bignum = n + 10

	cap = J(N, N, 0)
	for (i=1; i<=n; i++) {
		if (i==s | i==t) cap[i, n+i] = bignum
		else cap[i, n+i] = 1
	}
	for (u=1; u<=n; u++) {
		for (v=1; v<=n; v++) {
			if (u != v & adj[u,v] != 0) {
				cap[n+u, v] = bignum
			}
		}
	}

	flow = J(N, N, 0)
	maxf = 0
	while (bfs_augment(cap, flow, n+s, t, parent)) {
		pathflow = bignum
		v = t
		while (v != n+s) {
			u = parent[v]
			pf = cap[u,v] - flow[u,v]
			if (pf < pathflow) pathflow = pf
			v = u
		}
		v = t
		while (v != n+s) {
			u = parent[v]
			flow[u,v] = flow[u,v] + pathflow
			flow[v,u] = flow[v,u] - pathflow
			v = u
		}
		maxf = maxf + pathflow
	}
	return(maxf)
}

/*
	vertex_connectivity(adj): the graph's overall vertex connectivity
	kappa(G) - the minimum number of nodes whose removal disconnects
	the graph or reduces it to a single node. By Menger's theorem,
	kappa(G) equals the minimum, over every non-adjacent pair (s,t), of
	the minimum vertex set separating them (maxflow_vertex_split(adj,
	s, t)); a genuine brute-force over ALL non-adjacent pairs, O(n^2)
	max-flow calls, rather than the smaller reference-vertex subset
	Even's own more efficient algorithm restricts to - a deliberately
	simpler, definitely-correct trade favoring hand-verifiability over
	asymptotic optimality, matching this session's own established
	precedent (see BronKerbosch()'s and is_valid_kplex()'s own header
	comments) and appropriate at this package's target (moderate)
	network scale. A complete graph (every pair adjacent - no
	non-adjacent pair exists at all, so the Menger's-theorem loop above
	would vacuously never run) is handled as its own base case:
	kappa(K_n) = n-1 by definition (removing any n-1 of its n nodes
	always leaves a single, trivially "connected" node; no smaller
	vertex set can disconnect it since every remaining pair stays
	tied). A graph that is already disconnected (a non-adjacent pair
	exists with literally no path between them at all) has kappa(G)=0
	by the same definition - maxflow_vertex_split() naturally returns 0
	for such a pair (no augmenting path exists even before any node is
	removed), so this falls out of the general loop with no special
	case needed.
*/
real scalar vertex_connectivity(real matrix adj){
	real scalar n, s, t, minflow, f
	real scalar any_nonadjacent

	n = rows(adj)
	if (n <= 1) return(0)

	any_nonadjacent = 0
	minflow = n
	for (s=1; s<=n; s++) {
		for (t=s+1; t<=n; t++) {
			if (adj[s,t] == 0) {
				any_nonadjacent = 1
				f = maxflow_vertex_split(adj, s, t)
				if (f < minflow) minflow = f
			}
		}
	}
	if (any_nonadjacent == 0) return(n-1)
	return(minflow)
}

/*
	min_vertex_cutset(adj): a single minimum vertex cutset of the
	graph (there can be several distinct ones of the same minimum
	size; this returns whichever one the underlying max-flow search
	happens to find first, which is all calculate_kcomponents() below
	needs - any minimum cutset works equally well for its own
	recursive splitting). Re-runs the same non-adjacent-pair search
	vertex_connectivity() itself does, but this time keeps the
	winning (s,t) pair's own final flow/capacity state instead of
	discarding it, then extracts the actual cutset from it via the
	standard max-flow/min-cut construction: after the flow is
	maximal, do a BFS from s_out over the *residual* graph (edges
	with cap-flow > 0) - every node reachable this way is on the
	"s side" of the min cut. A node v (v != s,t) whose v_in *is*
	reachable but whose own v_out is *not* is exactly a node whose
	single unit of v_in->v_out capacity is fully used by the flow -
	i.e. a member of the minimum vertex cutset itself. Returns an
	empty (0-column) row vector for a complete graph (no non-adjacent
	pair exists, so there is no meaningful "separating vertex set" at
	all - calculate_kcomponents() itself never calls this in that
	case, since vertex_connectivity() already reports k=n-1 there and
	the recursion stops without needing to cut anything).
*/
real rowvector min_vertex_cutset(real matrix adj){
	real scalar n, N, bignum, s, t, u, v, i, minflow, f, best_s, best_t
	real matrix cap, flow
	real rowvector parent, visited, queue, cutset
	real scalar qhead, qtail, pathflow, pf

	n = rows(adj)
	minflow = n
	best_s = 0
	best_t = 0
	for (s=1; s<=n; s++) {
		for (t=s+1; t<=n; t++) {
			if (adj[s,t] == 0) {
				f = maxflow_vertex_split(adj, s, t)
				if (f < minflow) {
					minflow = f
					best_s = s
					best_t = t
				}
			}
		}
	}
	if (best_s == 0) return(J(1,0,0))

	// re-run max-flow on the winning pair, keeping its final flow
	N = 2*n
	bignum = n + 10
	cap = J(N, N, 0)
	for (i=1; i<=n; i++) {
		if (i==best_s | i==best_t) cap[i, n+i] = bignum
		else cap[i, n+i] = 1
	}
	for (u=1; u<=n; u++) {
		for (v=1; v<=n; v++) {
			if (u != v & adj[u,v] != 0) cap[n+u, v] = bignum
		}
	}
	flow = J(N, N, 0)
	while (bfs_augment(cap, flow, n+best_s, best_t, parent)) {
		pathflow = bignum
		v = best_t
		while (v != n+best_s) {
			u = parent[v]
			pf = cap[u,v] - flow[u,v]
			if (pf < pathflow) pathflow = pf
			v = u
		}
		v = best_t
		while (v != n+best_s) {
			u = parent[v]
			flow[u,v] = flow[u,v] + pathflow
			flow[v,u] = flow[v,u] - pathflow
			v = u
		}
	}

	// BFS the residual graph from best_s's own "out" node
	visited = J(1,N,0)
	queue = J(1,N,0)
	qhead = 1
	qtail = 1
	queue[1] = n+best_s
	visited[n+best_s] = 1
	while (qhead <= qtail) {
		u = queue[qhead]
		qhead++
		for (v=1; v<=N; v++) {
			if (visited[v]==0 & (cap[u,v]-flow[u,v])>0) {
				visited[v] = 1
				qtail++
				queue[qtail] = v
			}
		}
	}

	cutset = J(1,0,0)
	for (i=1; i<=n; i++) {
		if (i==best_s | i==best_t) continue
		if (visited[i]==1 & visited[n+i]==0) cutset = (cutset, i)
	}
	return(cutset)
}

/*
	KComponents(origadj, nodeset, k): the recursive vertex-connectivity
	decomposition underlying both k-components (Kanevsky 1993) and, in
	its full generalized/all-levels form, Moody & White's (2003)
	cohesive blocking - this implements it for one specific target
	level k, not the full recursive-hierarchy-across-all-levels version
	(see nwkcomponents.ado's own doc header for why that scoping choice
	was made). `nodeset' is a 0/1 row vector over the *original* full
	node set (1..cols(nodeset)), not a locally-reindexed subset - kept
	this way throughout the recursion (mirroring BronKerbosch()'s/
	KPlex()'s own R/P/X indicator-vector convention) specifically so
	every result, at any recursion depth, is already a directly
	comparable/stackable row of the same width, with no re-indexing
	needed when building the final results matrix.

	Algorithm: compute the induced subgraph's own vertex connectivity.
	If it already meets the target k, the whole current node set
	qualifies - report it and stop recursing this branch (a k-component
	is, by definition, a MAXIMAL node set with connectivity >= k; once
	a set qualifies, nothing about descending further into subsets of
	it is meaningful for a fixed target k). Otherwise, find a minimum
	vertex cutset (smaller than k, by construction, since a qualifying
	connectivity was just ruled out), remove it, split the remainder
	into its own connected components, and recurse into each
	(component + cutset) node set - re-adding the cutset's own nodes to
	every resulting branch, not just one, matching the standard
	Moody-White convention that cutpoints/cutsets remain shared members
	of whatever cohesive sub-blocks their removal reveals, rather than
	being assigned to just one side. A node set smaller than k+1 nodes
	is pruned immediately without even computing its own connectivity
	(the maximum possible connectivity of an s-node graph is s-1, so no
	set that small could ever reach a target of k).
*/
real matrix KComponents(real matrix origadj, real rowvector nodeset, real scalar k){
	real matrix results, sub, childresults
	real rowvector idx, cutset, cutset_orig, remaining, comp_of, newnodeset
	real rowvector queue
	real scalar n, conn, i, c, ncomp, is_cut, node0, u, w, w_in_remaining
	real scalar qhead, qtail

	n = cols(nodeset)
	idx = selectindex(nodeset)
	results = J(0, n, 0)

	if (length(idx) < k+1) {
		return(results)
	}

	sub = origadj[idx, idx]
	conn = vertex_connectivity(sub)
	if (conn >= k) {
		results = nodeset
		return(results)
	}

	// min_vertex_cutset() is guaranteed to return a genuinely non-empty
	// cutset at this point, never the "no non-adjacent pair exists"
	// empty case its own header comment describes - which matters,
	// since an empty cutset here would make `remaining' below equal
	// `idx' unchanged and recurse right back into this exact same
	// (origadj, nodeset, k) call forever. The size guard just above
	// (length(idx) < k+1) rules this out by a short, exact argument:
	// min_vertex_cutset() only returns empty when its own input is a
	// COMPLETE graph (every pair already adjacent - no non-adjacent
	// pair for it to search over at all), and vertex_connectivity()
	// gives a complete s-node graph connectivity exactly s-1 by
	// definition. Having reached this line at all means conn < k, i.e.
	// (if `sub' were complete) s-1 < k, i.e. s < k+1 - but the size
	// guard already rejected any node set with length(idx) < k+1
	// before ever computing `conn' in the first place. So any `sub'
	// that is both complete AND passes the size guard would have to
	// satisfy both s >= k+1 and s-1 < k (s < k+1) simultaneously -
	// impossible. Reaching this line therefore proves `sub' is not
	// complete, so a non-adjacent pair exists for min_vertex_cutset()
	// to search over, so it cannot return empty.
	cutset = min_vertex_cutset(sub)
	cutset_orig = J(1,0,0)
	for (i=1; i<=cols(cutset); i++) {
		cutset_orig = (cutset_orig, idx[cutset[i]])
	}

	remaining = J(1,0,0)
	for (i=1; i<=cols(idx); i++) {
		is_cut = 0
		for (c=1; c<=cols(cutset_orig); c++) {
			if (idx[i]==cutset_orig[c]) is_cut = 1
		}
		if (is_cut==0) remaining = (remaining, idx[i])
	}

	// connected components of the "remaining" nodes, via BFS restricted
	// to that set (plain BFS on origadj, but only ever stepping into
	// nodes that are themselves members of "remaining")
	comp_of = J(1, n, 0)
	ncomp = 0
	for (i=1; i<=cols(remaining); i++) {
		node0 = remaining[i]
		if (comp_of[node0] != 0) continue
		ncomp++
		queue = J(1, cols(remaining), 0)
		qhead = 1
		qtail = 1
		queue[1] = node0
		comp_of[node0] = ncomp
		while (qhead <= qtail) {
			u = queue[qhead]
			qhead++
			for (w=1; w<=n; w++) {
				if (origadj[u,w] != 0) {
					w_in_remaining = 0
					for (c=1; c<=cols(remaining); c++) {
						if (remaining[c]==w) w_in_remaining = 1
					}
					if (w_in_remaining==1 & comp_of[w]==0) {
						comp_of[w] = ncomp
						qtail++
						queue[qtail] = w
					}
				}
			}
		}
	}

	for (c=1; c<=ncomp; c++) {
		newnodeset = J(1, n, 0)
		for (i=1; i<=n; i++) {
			if (comp_of[i]==c) newnodeset[i] = 1
		}
		for (i=1; i<=cols(cutset_orig); i++) {
			newnodeset[cutset_orig[i]] = 1
		}
		childresults = KComponents(origadj, newnodeset, k)
		results = results \ childresults
	}
	return(results)
}


					/* End utilities		*/
/* -------------------------------------------------------------------- */


mata:
/* -------------------------------------------------------------------- */
/* 
	Version 1 gobal object
		nwsdef is definition of networks
		nwsder is derived from nws
		
		datasync:  allows switching off -nw_datasync- for speed-up
*/

class `NWs' {
	class `NWsdef' scalar nws
	class `NWsder' scalar nwsder
	
}


/* -------------------------------------------------------------------- */
/* -------------------------------------------------------------------- */
/* 
	Version 1 definition of a network
		name:		the name of the network
		label:		the label of the network
		nodenames:	name of nodes
		modes:		mode of nodes
		edge:		edge matrix
		isdirect:	if is direct graph
		is2mode:	if network is two-mode

	`modes' (a per-node "1"/"2" string rowvector, get/set via
	get_modes()/set_modes()) IS handled - populated by nwset's own
	bipartite ingestion paths, queried via get_nodes_mode1()/
	get_nodes_mode2()/is_2mode_boolean(), and (as of the nwsave/nwuse
	persistence fix below) round-tripped through save/reload via
	get_modes_labeled_string()/set_modes_from_labeled_string() - the
	stale "TODO: modes is not handled yet" note this comment used to
	carry here predates that persistence fix and was itself already
	inaccurate before it (modes was already read/written throughout
	the class), left uncorrected until now.

	`nodesmode1'/`nodesmode2' (below) are themselves NOT reliable
	sources of truth despite their names - get_nodes_mode1()/
	get_nodes_mode2() recompute their answer directly from `modes'
	every call and never read these two fields at all; only
	set_nodes_mode1() ever writes them, and grep confirms nothing reads
	them afterward. Left in place as genuinely dead/redundant fields
	rather than removed, consistent with this package's general
	preference for the smallest safe change over a speculative cleanup
	unrelated to whatever fix is actually in progress - noted here so a
	future reader does not mistake them for the authoritative store.
*/
class `NWdef' {
	string scalar 		name
	string scalar 		label
	string scalar		caption
	string rowvector 	nodes
	string scalar 		twomodedescription
	real scalar         nodesmode1
	real scalar         nodesmode2
	string rowvector	nodesvar
	string rowvector 	modes
	real colvector		match // holds information about case numbers to which nodes 1,2,3... match
	string scalar 		description_mode1
	string scalar 		description_mode2
	
	real matrix 		edge
	`BOOL'				isdirect
	`BOOL'				isvalued
	`BOOL'		 		is2mode
	`BOOL'				isselfloop
              
	
//!! how edge matrix is stored
	real scalar 		edgetype

/* -------------------------------------------------------------------- */
	/*
		Sparse index (CSR out-neighbors, CSC-style in-neighbors for directed
		networks). Derived from `edge`; rebuilt lazily on first access after
		any structural change. Additive only as of introduction: `edge`
		remains the authoritative source of truth and every existing method
		is unaffected. See build_sparse_index()/ensure_sparse_built().

		Invalidated by every NWdef method that writes `edge` directly. NOT
		invalidated by external mutation through the pointer returned by
		get_matrix() (e.g. nwreplace.ado writes through it) - callers that
		mix raw get_matrix() writes with the new sparse accessors on the
		same object must not assume the cache reflects such writes.
	*/
	real colvector		rowptr		// length nodes+1; out-CSR row pointers
	real colvector		colidx		// length nnz; target node per entry
	real colvector		cweight		// length nnz; tie weight per entry
	real colvector		rowptr_in	// length nodes+1; in-CSC (directed only)
	real colvector		colidx_in	// length nnz; source node per entry
	real colvector		edgeid_in	// length nnz; index into colidx/cweight
	`BOOL'				sparse_built

	/*
		Whether `edge' currently holds valid dense data. Missing (the
		default for every network built through the traditional dense
		path - create()/create_by_name()/set_edge()/init_edge() never
		touch this field) or `True' both mean "yes, `edge' is valid, use
		it directly" (see ensure_dense_built(): only an explicit `False'
		triggers on-demand materialization). Only set_edge_from_triplets()
		- a genuinely sparse-native construction path that never allocates
		an N x N matrix - sets this to `False'. See ensure_dense_built().
	*/
	`BOOL'				edge_dense_built
/* -------------------------------------------------------------------- */

//!! methods:

	void symmetrize()
	void create()
	void create_by_name()
	void create_by_name_sparse()
	void init_edge()
	void init_edge_sparse()

	string scalar get_name()
	real scalar get_nodes()
	string matrix get_nodenames()
	string scalar get_nodenames_string()
	string matrix get_nodesvar()
	string scalar get_nodesvar_string()
	real scalar get_nodeid_from_nodename()

	string matrix get_edgelist()
	string matrix get_edgelist_compressed()
	real matrix get_outdegree()
	real matrix get_indegree()
	string matrix get_modes()
	
	pointer(real matrix) get_matrix()
	pointer(real matrix) get_matrix_mod()
	pointer(real matrix) get_matrix_unvalued()
	real matrix get_matrix_copy()
	real matrix get_matrix_unvalued_copy()
	real matrix get_adjlist()
	real matrix get_path()

	void build_sparse_index()
	void build_reverse_index()
	void ensure_sparse_built()
	void invalidate_sparse()
	void set_edge_from_triplets()
	void ensure_dense_built()
	real matrix neighbors()
	real matrix neighbors_in()
	real scalar degree()
	real scalar degree_in()
	real scalar has_edge()
	real scalar edge_weight()
	real matrix edgelist()

	string scalar is_selfloop()
	string scalar is_valued()
	string scalar is_directed()
	string scalar is_2mode()
	real scalar is_selfloop_boolean()
	real scalar is_valued_boolean()
	real scalar is_directed_boolean()
	real scalar is_2mode_boolean()
	real scalar has_node()
	string scalar get_label()
	string scalar get_caption()
	string scalar get_vars()
	real scalar get_maximum()
	real scalar get_minimum()
	real scalar get_missing_edges()
	real scalar get_edges_count()
	real scalar get_edges_sum()
	real scalar get_arcs_count()
	real scalar get_arcs_sum()
	real scalar get_density()
	real scalar get_selfloops_number()
    real scalar get_nodes_mode1()
    real scalar get_nodes_mode2() 
	string scalar get_description_mode1()
	string scalar get_description_mode2()
	
    real scalar check_valued()
    real scalar check_symmetry()
	
	real matrix single_source_dijkstra()
	real matrix calculate_shortestpaths_dijkstra()
    real matrix calculate_dyadcensus()
	real matrix calculate_triadcensus()
	real matrix calculate_distances()
	real matrix calculate_distances_without()
	real scalar calculate_distance_pair()
	real matrix calculate_betweenness()
	real matrix calculate_betweenness_weighted()
	real matrix calculate_components()
	real matrix calculate_lgc()
	real matrix calculate_clustering()
	real scalar calculate_modularity()
	real matrix detect_communities_louvain()
	real matrix calculate_concor()
	real matrix calculate_coreperiphery()
	real matrix calculate_brokerage()
	real matrix calculate_2mode_degree()
	real matrix calculate_egostats()
	real matrix calculate_cliques()
	real matrix calculate_cliques_filtered()
	real matrix calculate_kplex()
	real matrix calculate_kplex_filtered()
	real matrix calculate_nclique()
	real matrix calculate_nclique_filtered()
	real matrix calculate_nclan_filtered()
	real matrix calculate_kcomponents()
	real matrix calculate_kcore()
	real matrix calculate_alterstat()
	real matrix calculate_alterstat_hop()
	real matrix calculate_similarity_index()
	real matrix correlate_nodes()
	
	void set()
	void set_name()
	void set_nodenames()
	void set_nodesvar()
	void set_nodes_from_string()
	void set_edge()
	void set_label()
	void set_caption()
	void set_nodes()
	void set_selfloop()
	void set_directed()
	void set_valued()
	void set_2mode()
	void set_modes()
	void set_nodes_mode1()
	void set_nodes_mode2()
	void set_description_mode1()
	void set_description_mode2()
	string scalar get_modes_labeled_string()
	void set_modes_from_labeled_string()

	void connect_edge()
	void add_node()
	void zap()
	void dumper()
	void update_nodesvar()
	void update_match()
	void data_sync()
	void keep_nodes()
	void drop_nodes()
	void permute()
	void clean_matrix_2mode()
	`BOOL' rename_nodename()
	
	//void export_gexf()
}



/*
void `NWdef'::export_gexf(string scalar fname){
	real scalar fh_out, i
	string scalar line
	string matrix elist
	
	if (fileexists(fname)){
		unlink(fname)
	}
	
	fh_out = fopen(fname, "w")
	fput(fh_out,`"<?xml version=”1.0” encoding=”UTF−8”?>"')
	fput(fh_out,`"<gexf xmlns=”http://www.gexf.net/1.2draft""')
	fput(fh_out,`"      xmlns:xsi=”http://www.w3.org/2001/XMLSchema−instance”"')
	fput(fh_out,`"      xsi:schemaLocation=”http://www.gexf.net/1.2draft"')
	fput(fh_out,`"                          http://www.gexf.net/1.2draft/gexf.xsd”"')
	fput(fh_out,`"      version=”1.2”>"')
	fput(fh_out,`"   <meta lastmodifieddate=”2009−03−20”>"')
	fput(fh_out,`"      <creator>nwcommands.org</creator>"')
	fput(fh_out,`"      <description>`r(netname)'</description>"')
	fput(fh_out,`"   </meta>"')
	
	// General network characteristics
	if (is_directed_boolean()){
		fput(fh_out,`"   <graph defaultedgetype="directed">"')
	}
	else {
		fput(fh_out,`"   <graph defaultedgetype="undirected">"')
	}
	
	// Insert nodes
	fput(fh_out,`"      <nodes>"')
	for(i = 1 ; i <= get_nodes(); i++){
		line = `"        <node id=""' + nodes[i] + `"" label = "' + nodes[i] + `"">"'
		// TODO - insert node viz:attributes
		fput(fh_out,line)
	}
	fput(fh_out,`"      </nodes>"')
	
	// Insert edges
	fput(fh_out,`"      <edges>"')
	elist = get_edgelist(is_directed_boolean()==0)
	fput(fh_out,`"      </edges>"')
	for (i = 1 ; i < rows(elist); i++){
		line = `"        <edge id=""' + strofreal(i) + `"" source=""' + elist[i,1] + `"" target=""' + elist[i,2] + `""/>"'
		// TODO - insert edge viz:attributes
		fput(fh_out,line)
	}
	fput(fh_out,`"   </graph>"')
	fput(fh_out,`"</gefx>"')	
}*/

real matrix `NWdef'::calculate_shortestpaths_dijkstra() {
	real scalar i, n, m, k,l
	real matrix D, adjlist
	
	n = get_nodes()
	adjlist = get_adjlist()
	D = J(n,n,.)
	l = 1
	for(i = 1; i <= n; i++) {
		l = m
		m = mod(floor(10 * i/n),10) * 10
		if (m != l & m != 0) {
			printf("{txt}..%2.0f", m)
			displayflush()
		}
		D[i,.] = (single_source_dijkstra(adjlist, i)[.,1])' 
	}
	return(D)
}

real scalar `NWdef'::get_nodeid_from_nodename(string n){
	if (has_node(n)){
		return(select((1::get_nodes())', get_nodenames() :== n))
	}
	else {
		return(-1)
	}
}


real scalar `NWdef'::has_node(string scalar n) {
	return(sum(get_nodenames():==n))
}

real matrix `NWdef'::single_source_dijkstra(real matrix adjlist, real scalar s){
	real matrix d, n, pred, u_tuple
	string matrix color
	real scalar w, i, wx, j, v, u, u_dist, cond1, cond2, stop
	
	w = (*get_matrix())
	
	class priorityQueue Q
	
	
	Q = priorityQueue()
	n = cols(w)
	
	d = J(n,1,.)
	color = J(n,1,"white")
	pred = J(n,(n+1),.)

	d[s] = 0
	pred[s,1] = -1
	
	
	// check for isolates
	if (adjlist[s,1]==.) {
		return(d,pred)
	}

	else {
	for (i = 1; i <= n; i++){
		if (i == s) {
			Q.insert(0)
		}
		else {
			wx = w[s,i]
			if (wx == 0){
				wx = .
			}
			Q.insert(wx)
		}
	}

	while (Q.isEmpty() == 0){
		//"Q first"
		//Q.show()
		u_tuple = Q.removeMin()
		//"Q second"
		//Q.show()
		u_dist = u_tuple[1]
		u = u_tuple[2]
		i = 1
		stop = 0
		while (adjlist[u,i] != . & stop == 0) {
			v = adjlist[u,i]
			cond1 = ((d[u] + w[u,v]) <= d[v])
			cond2 = ((d[u] + w[u,v]) == d[v])
			if (cond1 == 1){
				d[v] = d[u] + w[u,v]
				Q.changeKeyIndex(v,d[v])
				if (cond2 == 1) {
					if (pred[v,(n+1)] == .) {
						pred[v,1] = u
						pred[v,(n+1)] = 2
					}
					else {
						pred[v,pred[v,(n+1)]] = u
						pred[v,(n+1)] = pred[v,(n+1)] + 1
					}
				}
				else {
					pred[v,.] = J(1,(n+1),.)
					pred[v,1] = u
					pred[v,(n+1)] = 2
				}
			}
			i = i + 1
			if (i > cols(adjlist)) {
				i = i - 1
				stop = 1
			}
		}
		color[u] = "black"
	}
	return(d, pred)
	}
} 

/*
	Avoids forcing dense materialization on a sparse-natively-built network
	(edge_dense_built == `False') that hasn't needed one yet: reads min/max
	straight from the sparse weight store instead of *get_matrix(). Falls
	back to the dense read otherwise (unaffected, matches original
	behavior exactly). An all-zero/no-edge sparse network is unvalued.
*/
real scalar `NWdef'::check_valued(){
	real scalar mi, ma

	if (edge_dense_built == `False' & sparse_built == `True'){
		if (rows(cweight) == 0){
			return(0)
		}
		mi = min(cweight)
		ma = max(cweight)
	}
	else {
		mi = min(*get_matrix())
		ma = max(*get_matrix())
	}

	if ((mi >= 0 &  mi <= 1) & (ma>=0 & ma <=1)) {
		return(0)
	}
	else {
		return(1)
	}
}

real matrix `NWdef'::correlate_nodes(scalar outinboth){
	real matrix i_intvec, ctemp, C, selection, i_outvec, i_invec, j_outvec, j_invec,temp
	real scalar i,j, Corr, cmax, cmin, num_cols, num_rows, num
	C = J(rows(*get_matrix()), cols(*get_matrix()), 0)
	for(i = 1; i<= rows(*get_matrix()); i++){
		for(j = 1; j<= cols(*get_matrix()); j++){
				
			selection = J(1, cols(*get_matrix()), 1)
			selection[i] = 0
			selection[j] = 0
			i_outvec = (select((*get_matrix())[i,.], selection))'
			i_invec = (select((*get_matrix())[.,i]', selection))'	
			j_outvec = (select((*get_matrix())[j,.], selection))'
			j_invec = (select((*get_matrix())[.,j]', selection))'
			
			if (outinboth == 1) {
				temp = J(rows(i_outvec), 2, 0)
				temp[.,1] = i_outvec
				temp[.,2] = j_outvec
				Corr = correlation(temp)
				
				if (Corr[2,1]==.){
					ctemp = (sum(i_outvec), sum(j_outvec))
					cmax = max(ctemp)
					cmin = min(ctemp)
					if (cmin > 0) {
						Corr[2,1] = cmin / cmax
					}
					if (cmin == 0 & cmax > 0) {
						Corr[2,1] = -1
					}
					if (cmin == 0 & cmax == 0) {
						Corr[2,1] = 1
					}
				}
				C[i,j] = Corr[2,1]
			}
			if (outinboth == 2) {
				temp = J(rows(i_invec), 2, 0)
				temp[.,1] = i_intvec
				temp[.,2] = j_invec
				Corr = correlation(temp)
				
				if (Corr[2,1]==.){
					ctemp = (sum(i_outvec), sum(j_outvec))
					cmax = max(ctemp)
					cmin = min(ctemp)
					if (cmin > 0) {
						Corr[2,1] = cmin / cmax
					}
					if (cmin == 0 & cmax > 0) {
						Corr[2,1] = -1
					}
					if (cmin == 0 & cmax == 0) {
						Corr[2,1] = 1
					}
				}
				C[i,j] = Corr[2,1]
			}
			if (outinboth == 3) {
				num_cols = cols(i_outvec)
				num_rows = rows(i_invec)
				num =  num_cols + num_rows
				temp = J(num,2,0)
				temp[(1::num_cols),1] = i_outvec
				temp[((num_cols + 1)::num),1] = i_invec
				temp[(1::num_cols),2] = j_outvec
				temp[((num_cols + 1)::num),2] = j_invec			

				Corr = correlation(temp)
				
				if (Corr[2,1]==.){
					ctemp = (sum(i_outvec), sum(j_outvec))
					cmax = max(ctemp)
					cmin = min(ctemp)
					if (cmin > 0) {
						Corr[2,1] = cmin / cmax
					}
					if (cmin == 0 & cmax > 0) {
						Corr[2,1] = -1
					}
					if (cmin == 0 & cmax == 0) {
						Corr[2,1] = 1
					}
				}
				C[i,j] = Corr[2,1]
			}
		}
	}
	return(C)
}

real matrix `NWdef'::calculate_clustering(real scalar mode) {	
	real matrix cluster
	real matrix alters, alters1, alters2
	real matrix id
	real matrix closed_triples
	real matrix potential_triples
	real scalar i, j, k, alter1_id, alter2_id

	closed_triples = J(get_nodes(),1,0)
	potential_triples = J(get_nodes(),1,0)
	id = (1::get_nodes())
	
	// unvalued
	if (mode == 0){
		for ( i = 1 ; i <= get_nodes(); i++) {
			// union of out- and in-neighbors (matches the original dense
			// out-row-plus-in-column derivation exactly; a nonzero pattern
			// is unaffected by valued vs. unvalued, so the sparse index -
			// built from `edge' - gives the identical alter set)
			alters = uniqrows(neighbors(i) \ neighbors_in(i))
			// BUGFIX (intentional, not a silent side effect of the sparse
			// migration): the original dense select(id, mask) here read a
			// mask built from a `!=0' comparison against a matrix that
			// includes the (missing, since self-loops are disabled by
			// default) diagonal entry. Mata's select() treats a missing
			// mask value as "keep", so the original always included node
			// i in its own alters list whenever self-loops were disabled -
			// poisoning that node's potential_triples to missing via `.'
			// arithmetic propagation, silently dropping it from downstream
			// aggregates the same as a legitimately zero-potential node.
			// neighbors()/neighbors_in() correctly exclude i by
			// construction (missing/zero diagonal entries are never
			// stored), so this is fixed as of this session. Verified dead
			// code as of the same session: no shipped .ado file calls
			// calculate_clustering() today (nwclustering.ado has its own
			// independent Stata-side implementation), so this had no
			// effect on any prior shipped output.
			for (j = 1; j <= rows(alters); j++){
				alter1_id = alters[j]
				for (k = (j+1); k <= rows(alters); k++){
					if (k <= rows(alters)) {
						alter2_id = alters[k]	
						potential_triples[i,1] = potential_triples[i,1] + 2
						closed_triples[i,1] = closed_triples[i,1] + (*get_matrix_unvalued())[alter1_id,alter2_id] + (*get_matrix_unvalued())[alter2_id,alter1_id]	
					}
				}	
			}
		}		
	}
	
	// arithmetic mean
	if (mode == 1){
		for ( i = 1 ; i <= get_nodes(); i++) {
			// out-neighbors only (matches the original's asymmetric,
			// out-row-only derivation for the weighted modes exactly -
			// preserved as-is, not "fixed" to match mode 0's union)
			alters = neighbors(i)
			// BUGFIX: same self-inclusion issue as mode 0 above, same fix -
			// neighbors() excludes i by construction. See mode 0's comment.
			for (j = 1; j <= rows(alters); j++){
				alter1_id = alters[j]
				for (k = (j+1); k <= rows(alters); k++){
					if (k <= rows(alters)) {
						alter2_id = alters[k]	
						potential_triples[i,1] = potential_triples[i,1] + (((*get_matrix())[i,alter1_id] :+ (*get_matrix())[i,alter2_id]):/2)
						closed_triples[i,1] = closed_triples[i,1] + (((*get_matrix())[i,alter1_id] :+ (*get_matrix())[i,alter2_id]):/2) :* ((*get_matrix())[alter1_id,alter2_id] != 0)		
					}
				}	
			}
		}
	}
	
	// geometric mean
	if (mode == 2){
		for ( i = 1 ; i <= get_nodes(); i++) {
			// out-neighbors only (matches the original's asymmetric,
			// out-row-only derivation for the weighted modes exactly -
			// preserved as-is, not "fixed" to match mode 0's union)
			alters = neighbors(i)
			// BUGFIX: same self-inclusion issue as mode 0 above, same fix -
			// neighbors() excludes i by construction. See mode 0's comment.
			for (j = 1; j <= rows(alters); j++){
				alter1_id = alters[j]
				for (k = (j+1); k <= rows(alters); k++){
					if (k <= rows(alters)) {
						alter2_id = alters[k]	
						potential_triples[i,1] = potential_triples[i,1] + (sqrt((*get_matrix())[i,alter1_id] :* (*get_matrix())[i,alter2_id]))
						closed_triples[i,1] = closed_triples[i,1] + (sqrt((*get_matrix())[i,alter1_id] :* (*get_matrix())[i,alter2_id])) :* ((*get_matrix())[alter1_id,alter2_id] != 0)		
					}
				}	
			}
		}
	}
	// maximum
	if (mode == 3){
		for ( i = 1 ; i <= get_nodes(); i++) {
			// out-neighbors only (matches the original's asymmetric,
			// out-row-only derivation for the weighted modes exactly -
			// preserved as-is, not "fixed" to match mode 0's union)
			alters = neighbors(i)
			// BUGFIX: same self-inclusion issue as mode 0 above, same fix -
			// neighbors() excludes i by construction. See mode 0's comment.
			for (j = 1; j <= rows(alters); j++){
				alter1_id = alters[j]
				for (k = (j+1); k <= rows(alters); k++){
					if (k <= rows(alters)) {
						alter2_id = alters[k]	
						potential_triples[i,1] = potential_triples[i,1] + (max(((*get_matrix())[i,alter1_id], (*get_matrix())[i,alter2_id])))
						closed_triples[i,1] = closed_triples[i,1] + (max(((*get_matrix())[i,alter1_id], (*get_matrix())[i,alter2_id]))) :* ((*get_matrix())[alter1_id,alter2_id] != 0)		
					}
				}	
			}
		}
	}
	// minimum
	if (mode == 4){
		for ( i = 1 ; i <= get_nodes(); i++) {
			// out-neighbors only (matches the original's asymmetric,
			// out-row-only derivation for the weighted modes exactly -
			// preserved as-is, not "fixed" to match mode 0's union)
			alters = neighbors(i)
			// BUGFIX: same self-inclusion issue as mode 0 above, same fix -
			// neighbors() excludes i by construction. See mode 0's comment.
			for (j = 1; j <= rows(alters); j++){
				alter1_id = alters[j]
				for (k = (j+1); k <= rows(alters); k++){
					if (k <= rows(alters)) {
						alter2_id = alters[k]	
						potential_triples[i,1] = potential_triples[i,1] + (min(((*get_matrix())[i,alter1_id], (*get_matrix())[i,alter2_id])))
						closed_triples[i,1] = closed_triples[i,1] + (min(((*get_matrix())[i,alter1_id], (*get_matrix())[i,alter2_id]))) :* ((*get_matrix())[alter1_id,alter2_id] != 0)		
					}
				}	
			}
		}
	}
	
	potential_triples = editvalue(potential_triples, 0, .)
	cluster = J(get_nodes(),3,0)
	cluster[,1] = (closed_triples:/potential_triples)
	cluster[,2] = closed_triples
	cluster[,3] = potential_triples
	return(cluster)
}

real matrix `NWdef'::calculate_lgc(){
	real matrix lgc, c
	real scalar i, max

	max = 1
	c = calculate_components()
	for (i = 2; i<= max(c); i++){
		if (sum(c[,1] :== i) > sum(c[,1] :== max)){
			max = i
		}
	}
	return(c[,1]:==max)
}

/*
	Newman modularity Q of a given partition (1-indexed community membership vector)
*/
real scalar `NWdef'::calculate_modularity(real matrix membership, | real scalar resolution){
	real matrix w
	real scalar res

	res = (args() == 2 ? resolution : 1)
	w = *get_matrix_mod(1,0)
	_diag(w, 0)
	return(Modularity(w, membership, res))
}

/*
	Detect communities via the Louvain method (Blondel et al. 2008)
*/
real matrix `NWdef'::detect_communities_louvain(| real scalar valued, real scalar resolution){
	real matrix w
	real scalar val, res

	val = (args() >= 1 ? valued : 1)
	res = (args() == 2 ? resolution : 1)
	w = *get_matrix_mod(val, 0)
	_diag(w, 0)
	return(Louvain(w, res))
}

/*
	CONCOR structural-equivalence blockmodel (Breiger, Boorman & Arabie 1975):
	recursively bisects the network `splits' times (2^splits final blocks) via
	iterated profile correlation - see ConcorSplitIDs/ConcorConverge above.
	Unlike Louvain, this is defined for directed networks directly (a node's
	profile already stacks its out-ties and in-ties separately) - no
	symmetrize requirement. A node with literally zero ties in every
	direction in the *original* network has no tie profile to compare
	against anyone else's at any depth, so it is rejected explicitly here,
	once, up front - a within-block "isolate" arising only during recursion
	(a node whose ties all happen to lie outside its current block) is a
	different, legitimate case, handled by ConcorSplitIDs itself.
*/
real matrix `NWdef'::calculate_concor(real scalar splits, | real scalar valued, real scalar maxiter){
	real matrix w, res, out
	real scalar val, iter, n

	val = (args() >= 2 ? valued : 1)
	iter = (args() == 3 ? maxiter : 25)
	w = *get_matrix_mod(val, 1)
	_diag(w, 0)
	n = get_nodes()

	if (min(rowsum(w) :+ colsum(w)') <= 0){
		// _error()'s own message argument silently hits an undocumented
		// ~100-char cap ("argument out of range", r(3300)) - confirmed
		// by bisection; this message is longer, so errprintf()+exit()
		// is used instead (no such limit found there).
		errprintf("CONCOR requires every node to have at least one tie (incoming or outgoing) - remove isolates first (see nwdropnodes/nwkeepnodes) and try again.\n")
		exit(error(6556))
	}

	res = ConcorSplitIDs(w, splits, iter, (1::n))
	out = J(n,1,.)
	out[res[.,1],1] = res[.,2]
	return(out)
}

/*
	Discrete core-periphery detection (Borgatti & Everett 1999) - see
	CorePeriphery()/nw_cp_fitness() above for the algorithm. Undirected
	only (get_matrix_mod(val, 0) symmetrizes), matching the classical
	model's own definition, which does not distinguish in-ties from
	out-ties. Returns an (n+1)-row column vector: rows 1..n are the 0/1
	core assignment, row n+1 is the fitness (correlation with the ideal
	pattern this assignment implies) - the calling .ado splits these
	apart rather than this needing two separate return channels.
*/
real matrix `NWdef'::calculate_coreperiphery(| real scalar valued, real scalar maxiter){
	real matrix w
	real scalar val, iter

	val = (args() >= 1 ? valued : 1)
	iter = (args() == 2 ? maxiter : 100)
	w = *get_matrix_mod(val, 0)
	_diag(w, 0)

	return(CorePeriphery(w, iter))
}

/*
	Gould-Fernandez (1989) brokerage roles: for every directed two-path
	a -> b -> c (a != c) through each node b, classifies the role b plays
	using the group membership of a, b and c:
	  1. coordinator    - g(a)=g(b)=g(c)              (broker within own group)
	  2. gatekeeper      - g(a)!=g(b), g(b)=g(c)        (lets outside info into own group)
	  3. representative  - g(a)=g(b), g(b)!=g(c)        (passes own-group info outward)
	  4. consultant      - g(a)=g(c), g(a)!=g(b)        (outsider linking two members of one other group)
	  5. liaison         - g(a), g(b), g(c) all distinct (bridges two unrelated groups)
	Uses the sparse neighbor accessors directly (neighbors()/neighbors_in(),
	the same primitives calculate_components()/calculate_kcore() already
	use) rather than a dense adjacency matrix, so this scales the same way
	those do. For an undirected network neighbors_in() already falls back
	to neighbors() (see its own definition above), so a and c are drawn
	from the same neighbor set - the definition degrades gracefully rather
	than needing a separate undirected-specific formula. Returns an n x 5
	matrix of per-node role counts, in the column order listed above.
*/
real matrix `NWdef'::calculate_brokerage(real matrix group){
	real matrix result, innb, outnb
	real scalar n, b, i, j, a, c, ga, gb, gc

	n = get_nodes()
	result = J(n, 5, 0)

	for (b=1; b<=n; b++){
		innb = neighbors_in(b)
		outnb = neighbors(b)
		gb = group[b,1]
		for (i=1; i<=rows(innb); i++){
			a = innb[i,1]
			if (a == b) continue
			ga = group[a,1]
			for (j=1; j<=rows(outnb); j++){
				c = outnb[j,1]
				if (c == b | c == a) continue
				gc = group[c,1]
				if (ga==gb & gb==gc){
					result[b,1] = result[b,1] + 1
				}
				else if (ga!=gb & gb==gc){
					result[b,2] = result[b,2] + 1
				}
				else if (ga==gb & gb!=gc){
					result[b,3] = result[b,3] + 1
				}
				else if (ga==gc & ga!=gb){
					result[b,4] = result[b,4] + 1
				}
				else if (ga!=gb & gb!=gc & ga!=gc){
					result[b,5] = result[b,5] + 1
				}
			}
		}
	}
	return(result)
}

/*
	Two-mode (bipartite) degree centrality (Borgatti & Everett 1997): a
	node's raw degree can only ever reach as high as the *other* mode's
	size (a mode-1 node can tie to at most every mode-2 node, never to
	another mode-1 node, in a genuine two-mode network), so ordinary
	degree centrality's usual n-1 normalization is wrong here - each
	node's degree is instead normalized by the size of the *other* mode.
	get_modes() (a string rowvector of "1"/"2" per node, already used by
	nw2project.ado for the same purpose) is queried directly rather than
	assumed from node-index ranges - confirmed empirically that a
	bipartite network's mode-1/mode-2 node index ranges are an internal
	storage detail, not something callers should hardcode.
*/
real matrix `NWdef'::calculate_2mode_degree(){
	string matrix modes
	real matrix result, idx1, idx2
	real scalar n1, n2, i

	modes = get_modes()
	idx1 = selectindex(modes :== "1")
	idx2 = selectindex(modes :== "2")
	n1 = cols(idx1)
	n2 = cols(idx2)

	result = J(get_nodes(), 1, .)
	for (i=1; i<=n1; i++){
		result[idx1[i],1] = degree(idx1[i]) / n2
	}
	for (i=1; i<=n2; i++){
		result[idx2[i],1] = degree(idx2[i]) / n1
	}
	return(result)
}

/*
	Ego-network size and density: an ego's alters are every node it has
	any tie with (union of in- and out-neighbors for a directed network -
	the standard "who is in ego's network at all" membership question,
	distinct from nwaltergen's own directional alter-aggregation
	convention, which deliberately keeps in/out separate for a different
	purpose). Density is the proportion of *possible* ties actually
	present *among the alters themselves* (ego itself excluded - the
	standard convention, matching how ego-network density is normally
	reported: how interconnected are my contacts with each other,
	independent of their (by-definition complete) ties to me). Directed
	networks count ordered alter-alter pairs (size*(size-1) possible
	ties); undirected networks count unordered pairs (size*(size-1)/2).
	An ego with fewer than 2 alters has no pair to assess - density is
	reported missing for it, not spuriously 0 or 1.
*/
real matrix `NWdef'::calculate_egostats(){
	real matrix result, nb
	real scalar n, i, j, k, sz, possible, actual, a, b

	n = get_nodes()
	result = J(n, 2, .)

	for (i=1; i<=n; i++){
		nb = neighbors(i)
		if (isdirect){
			nb = uniqrows(nb \ neighbors_in(i))
		}
		sz = rows(nb)
		result[i,1] = sz

		if (sz < 2) continue

		actual = 0
		for (j=1; j<=sz; j++){
			a = nb[j,1]
			for (k=1; k<=sz; k++){
				if (j == k) continue
				if (!isdirect & k < j) continue
				b = nb[k,1]
				if (has_edge(a,b)) actual = actual + 1
			}
		}
		possible = (isdirect ? sz*(sz-1) : sz*(sz-1)/2)
		result[i,2] = actual / possible
	}
	return(result)
}

/*
	Maximal clique enumeration (see BronKerbosch() above for the
	algorithm itself). Always undirected and binary - a clique is
	fundamentally a symmetric, presence/absence structure (Wasserman &
	Faust 1994's own definition requires every pair of members to be
	mutually adjacent, which has no natural directed or valued
	generalization in the classical sense) - `get_matrix_mod(0,0)`
	symmetrizes and binarizes a directed and/or valued network exactly
	the way `nwclustering`'s own directed-network guard implies is
	needed for a clustering-coefficient-family measure, the closest
	existing analog. Returns a (number of cliques found) x n 0/1
	indicator matrix, one row per maximal clique - cliques genuinely
	overlap (a node can belong to several), so this is not a partition
	the way `calculate_components()`'s single membership-id vector is;
	the calling `.ado` derives whatever per-node summary it wants from
	this full membership matrix.
*/
real matrix `NWdef'::calculate_cliques(){
	real matrix adj, R0, P0, X0
	real scalar n

	n = get_nodes()
	adj = (*get_matrix_mod(0,0)) :!= 0
	_diag(adj, 0)

	R0 = J(1,n,0)
	P0 = J(1,n,1)
	X0 = J(1,n,0)

	return(BronKerbosch(adj, R0, P0, X0))
}

/*
	calculate_cliques(), restricted to cliques of at least `minsize'
	members - a thin, single-purpose wrapper so nwclique.ado only needs
	one-line mata: calls throughout (a bare mata:/end block does not
	nest correctly inside a running program's own execution flow, unlike
	at file level after a program's own "end" - confirmed directly: it
	silently truncates the program's own boundary detection instead of
	behaving as a block-scoped Mata call).
*/
real matrix `NWdef'::calculate_cliques_filtered(real scalar minsize){
	real matrix cliq, sizes

	cliq = calculate_cliques()
	sizes = rowsum(cliq)
	return(select(cliq, sizes :>= minsize))
}

/*
	Maximal k-plex enumeration (see KPlex()/is_valid_kplex() above for
	the algorithm itself and the hereditary-property argument for why
	the same maximality-tracking scheme BronKerbosch() uses for cliques
	still applies). Always undirected and binary, for exactly the same
	reason calculate_cliques() is: a k-plex's own definition (every
	member's within-set degree at least |S|-k) has no natural directed
	or valued generalization. A k=1 k-plex is identical to a clique
	(every member missing 0 ties) - calculate_kplex(1) and
	calculate_cliques() return the same partition of the same maximal
	sets, though via a slower, more general code path; nwkplex.ado
	itself requires k>=2 (a k=1 call is redirected to a hard error
	suggesting nwclique instead, since nwclique already does that exact
	case with the cheaper, purpose-built BronKerbosch() algorithm - see
	nwkplex.ado's own guard).
*/
real matrix `NWdef'::calculate_kplex(real scalar k){
	real matrix adj, R0, P0, X0
	real scalar n

	n = get_nodes()
	adj = (*get_matrix_mod(0,0)) :!= 0
	_diag(adj, 0)

	R0 = J(1,n,0)
	P0 = J(1,n,1)
	X0 = J(1,n,0)

	return(KPlex(adj, k, R0, P0, X0))
}

/*
	calculate_kplex(), restricted to k-plexes of at least `minsize'
	members - mirrors calculate_cliques_filtered()'s own thin-wrapper
	pattern for the same reason (nwkplex.ado only ever needs one-line
	mata: calls).
*/
real matrix `NWdef'::calculate_kplex_filtered(real scalar k, real scalar minsize){
	real matrix kplex, sizes

	kplex = calculate_kplex(k)
	sizes = rowsum(kplex)
	return(select(kplex, sizes :>= minsize))
}

/*
	nclan_diameter_ok(origadj, members, n): true iff the INDUCED
	subgraph on `members' (built from origadj, the network's own
	original, unthresholded adjacency - not the n-step adjacency
	calculate_nclique() itself searches over) has every pair of its own
	members connected by a within-group path of length <= n. This is
	the extra condition that turns an n-clique into an n-clan (Mokken
	1979): an n-clique only guarantees every pair's shortest path in
	the WHOLE original network is <= n - that path may legitimately run
	through nodes outside the n-clique itself, a well-known weakness of
	the plain n-clique definition (Alba 1973) that can make an
	n-clique's own members not even mutually reachable within n steps
	if forced to stay inside the group. Reuses Brute_dist() directly on
	the induced submatrix rather than writing a second distance
	routine - Brute_dist() already returns missing for both the
	diagonal and any genuinely unreachable pair (see its own header
	comment), so both "disconnected within the group" and "too far
	within the group" are captured by a single hasmissing()-after-
	zeroing-the-diagonal check plus a max() bound.
*/
real scalar nclan_diameter_ok(real matrix origadj, real rowvector members, real scalar n){
	real matrix idx, sub, subdist, diagzero
	real scalar s

	idx = selectindex(members)
	s = length(idx)
	if (s <= 1) return(1)

	sub = origadj[idx, idx]
	subdist = Brute_dist(sub)
	diagzero = J(s, 1, 0)
	_diag(subdist, diagzero)

	if (hasmissing(subdist)) return(0)
	return(max(subdist) :<= n)
}

/*
	Maximal n-clique enumeration (Luce 1950): a generalization of an
	ordinary clique where every pair of members need only be within
	geodesic distance `n' of each other in the network as a whole,
	rather than directly tied - a plain clique is the special case
	n=1 (distance-1 "neighbors" are exactly direct ties), so, like
	calculate_kplex()'s own k=1 case, nwnclique.ado requires n>=2 and
	points to nwclique for n=1, which already implements that case more
	cheaply via BronKerbosch() directly on the true adjacency matrix
	rather than a distance matrix. This is exactly what
	calculate_nclique() itself does for n>=2 - build the n-step
	adjacency matrix (`geodesic distance <= n', missing/unreachable
	pairs correctly excluded since a Mata comparison against a missing
	value is always false, needing no separate special-casing) and
	hand it to the *same* BronKerbosch() maximal-clique backtracking
	nwclique.ado's own calculate_cliques() uses - an n-clique is simply
	an ordinary clique of the "distance <= n" graph, not a different
	search algorithm.
*/
real matrix `NWdef'::calculate_nclique(real scalar n){
	real matrix D, adjn, R0, P0, X0
	real scalar nn

	nn = get_nodes()
	D = calculate_distances(0, "brute")
	adjn = (D :<= n)
	_diag(adjn, 0)

	R0 = J(1,nn,0)
	P0 = J(1,nn,1)
	X0 = J(1,nn,0)

	return(BronKerbosch(adjn, R0, P0, X0))
}

/*
	calculate_nclique(), restricted to n-cliques of at least `minsize'
	members - mirrors calculate_cliques_filtered()/calculate_kplex_filtered()'s
	own thin-wrapper pattern.
*/
real matrix `NWdef'::calculate_nclique_filtered(real scalar n, real scalar minsize){
	real matrix ncliq, sizes

	ncliq = calculate_nclique(n)
	sizes = rowsum(ncliq)
	return(select(ncliq, sizes :>= minsize))
}

/*
	n-clans: the maximal n-cliques (calculate_nclique_filtered()) that
	additionally satisfy nclan_diameter_ok() against the network's own
	true adjacency matrix. Deliberately NOT a separate maximal-set
	search of its own - matching the standard, established treatment
	of n-clans in the literature (e.g. Wasserman & Faust 1994) and
	every other SNA package's own convention: n-clans are reported as a
	FILTERED SUBSET of the already-enumerated maximal n-cliques, not as
	independently re-maximized sets of their own. A maximal n-clique
	that fails the diameter check is simply not reported as a clan at
	all (not replaced by some smaller, clan-qualifying subset of
	itself) - a genuine, deliberate limitation of the n-clan concept
	itself, not an implementation shortcut.
*/
real matrix `NWdef'::calculate_nclan_filtered(real scalar n, real scalar minsize){
	real matrix ncliq, adj, keep
	real scalar i

	ncliq = calculate_nclique_filtered(n, minsize)
	if (rows(ncliq) == 0) return(ncliq)

	adj = (*get_matrix_mod(0,0)) :!= 0
	_diag(adj, 0)

	keep = J(rows(ncliq), 1, 0)
	for (i=1; i<=rows(ncliq); i++) {
		keep[i] = nclan_diameter_ok(adj, ncliq[i,.], n)
	}
	return(select(ncliq, keep))
}

/*
	Maximal k-components (Kanevsky 1993; the single-level case of Moody
	& White's (2003) recursive cohesive blocking - see KComponents()'s
	own header comment in this file for the full algorithm). Always
	undirected and binary, for the same reason every other cohesive-
	subgroup measure in this file is: vertex connectivity has no
	natural directed or valued generalization in the classical sense
	this package's other cohesive-subgroup commands already use.
*/
real matrix `NWdef'::calculate_kcomponents(real scalar k){
	real matrix adj
	real rowvector nodeset
	real scalar n

	n = get_nodes()
	adj = (*get_matrix_mod(0,0)) :!= 0
	_diag(adj, 0)

	nodeset = J(1, n, 1)
	return(KComponents(adj, nodeset, k))
}

/*
	k-core decomposition (Seidman 1983): the coreness of a node is the
	largest k such that the node belongs to a maximal subgraph in which
	every node has degree >= k within that subgraph. Standard iterative
	peeling algorithm: repeatedly remove the remaining node with the
	smallest current degree, assigning it a coreness of
	max(coreness-so-far, its degree at removal) - the max() keeps
	coreness monotone non-decreasing across the peeling order, which is
	what makes the result a genuine core decomposition rather than just a
	degree-removal order.

	Uses the sparse neighbors()/neighbors_in() accessors (never the dense
	matrix), and coreness is computed on the network treated as
	undirected (the standard definition; directed networks use the union
	of out- and in-neighbors as the effective neighbor set, matching how
	calculate_components() already treats directed networks for the same
	kind of undirected-sense structural question).

	Implemented as straightforward peeling with a linear scan for the
	current minimum-degree node each removal: O(n) removals x O(n) scan
	= O(n^2), plus O(n+m) total neighbor-list work. Correct and usable up
	to at least several thousand nodes; the classical Batagelj-Zaversnik
	bucket-queue refinement (O(n+m) total) is a documented future
	optimization, not implemented here - see docs/ROADMAP.md.
*/
real matrix `NWdef'::calculate_kcore(){
	real scalar n, i, j, k, minidx, mindeg, klevel, remaining, maxdeg
	real matrix deg, active, core, nb, adjmat

	n = get_nodes()
	deg = J(n, 1, 0)
	for (i = 1; i <= n; i++){
		if (isdirect){
			deg[i] = rows(uniqrows(neighbors(i) \ neighbors_in(i)))
		}
		else {
			deg[i] = degree(i)
		}
	}

	maxdeg = max(deg)
	if (maxdeg == 0){
		// no ties anywhere: every node is a trivial 0-core, in isolation
		return(J(n,1,0))
	}

	// padded neighbor-list matrix (row i = node i's neighbors, missing-
	// padded to maxdeg columns) - same convention as get_adjlist() in
	// this file, chosen specifically to avoid taking the address of a
	// loop-reused local (which would make every pointer alias the same,
	// final value) rather than a genuine pointer-array-of-neighbor-lists.
	adjmat = J(n, maxdeg, .)
	for (i = 1; i <= n; i++){
		if (isdirect){
			nb = uniqrows(neighbors(i) \ neighbors_in(i))
		}
		else {
			nb = neighbors(i)
		}
		if (rows(nb) > 0){
			adjmat[i, (1::rows(nb))'] = nb'
		}
	}

	active = J(n, 1, 1)
	core = J(n, 1, 0)
	klevel = 0

	for (remaining = n; remaining >= 1; remaining--){
		minidx = 0
		mindeg = .
		for (i = 1; i <= n; i++){
			if (active[i] == 1 & (mindeg == . | deg[i] < mindeg)){
				mindeg = deg[i]
				minidx = i
			}
		}
		if (mindeg > klevel){
			klevel = mindeg
		}
		core[minidx] = klevel
		active[minidx] = 0

		for (k = 1; k <= maxdeg; k++){
			j = adjmat[minidx, k]
			if (j != .){
				if (active[j] == 1){
					deg[j] = deg[j] - 1
				}
			}
		}
	}

	return(core)
}


/*
	Alter/neighbor attribute aggregation - the Mata half of
	-nwaltergen newvar = stat(alter.srcvar)-, this session's Stata-native-
	integration primitive (nwgen exposure = mean(alter.smoking)-style).
	srcvar is a node-indexed column vector (row i = node i's value, same
	alignment convention as calculate_kcore()'s return). For directed
	networks, "alter" means out-neighbors only (who ego is tied to), not
	the union used by calculate_kcore() - a deliberate, documented
	difference: kcore's union answers an undirected structural question,
	exposure/alter-aggregation is inherently about the direction of the
	tie. Missing srcvar values among a node's alters are dropped before
	aggregating (available-case, matching egen's convention), never
	silently propagated - the Burt bug earlier this session was exactly
	this failure mode via a different mechanism (matrix multiplication),
	worth guarding against explicitly here too.
*/
real matrix `NWdef'::calculate_alterstat(real colvector srcvar, string scalar stat){
	real scalar n, i, m
	real matrix result, nb, vals

	n = get_nodes()
	result = J(n, 1, .)

	for (i = 1; i <= n; i++){
		nb = neighbors(i)
		if (rows(nb) > 0){
			vals = srcvar[nb]
			vals = select(vals, vals :!= .)
		}
		else {
			vals = J(0, 1, .)
		}
		m = rows(vals)

		if (stat == "mean"){
			if (m > 0) result[i] = mean(vals)
		}
		else if (stat == "sum"){
			result[i] = (m > 0 ? sum(vals) : 0)
		}
		else if (stat == "min"){
			if (m > 0) result[i] = min(vals)
		}
		else if (stat == "max"){
			if (m > 0) result[i] = max(vals)
		}
		else if (stat == "sd"){
			if (m > 1) result[i] = sqrt(variance(vals))
		}
		else if (stat == "count"){
			result[i] = m
		}
	}

	return(result)
}

/*
	Multi-hop generalization of calculate_alterstat() above: aggregates
	srcvar over the nodes at exactly `hop' steps away (unweighted
	shortest-path distance - hop count, not tie strength), instead of
	over direct (1-hop) neighbors. `hop'==1 gives the same alter set as
	calculate_alterstat() itself (not delegated to it directly, to avoid
	any risk of the two aggregation code paths drifting apart silently -
	the per-stat logic below is kept in lockstep with it by construction/
	inspection instead). Distances come from calculate_distances(0,
	"brute") - alpha is irrelevant to the "brute" algorithm (it always
	computes unweighted distances on the unvalued matrix), and 0 is
	passed only because the method signature requires some value.
	Directed networks: calculate_distances()'s own distance matrix
	already respects tie direction (distance from i to j via out-going
	ties), matching calculate_alterstat()'s own established convention
	that "alter" means out-neighbors, not the undirected union other
	structural measures (e.g. calculate_kcore()) use. A node with no
	alters at exactly `hop' steps (including an unreachable node, or
	`hop' larger than the network's own diameter from that node) is
	treated identically to a node with zero direct alters in
	calculate_alterstat(): missing for mean/min/max/sd, 0 for sum/count.
*/
real matrix `NWdef'::calculate_alterstat_hop(real colvector srcvar, string scalar stat, real scalar hop){
	real scalar n, i, m
	real matrix result, D, idx, vals

	n = get_nodes()
	result = J(n, 1, .)
	D = calculate_distances(0, "brute")

	for (i = 1; i <= n; i++){
		idx = selectindex(D[i,.] :== hop)'
		if (rows(idx) > 0){
			vals = srcvar[idx]
			vals = select(vals, vals :!= .)
		}
		else {
			vals = J(0, 1, .)
		}
		m = rows(vals)

		if (stat == "mean"){
			if (m > 0) result[i] = mean(vals)
		}
		else if (stat == "sum"){
			result[i] = (m > 0 ? sum(vals) : 0)
		}
		else if (stat == "min"){
			if (m > 0) result[i] = min(vals)
		}
		else if (stat == "max"){
			if (m > 0) result[i] = max(vals)
		}
		else if (stat == "sd"){
			if (m > 1) result[i] = sqrt(variance(vals))
		}
		else if (stat == "count"){
			result[i] = m
		}
	}

	return(result)
}


/*
	Common-neighbor similarity indices (Liben-Nowell & Kleinberg 2007's
	terminology): common-neighbor count, Jaccard, Dice/Sorensen, cosine
	(Salton), Adamic-Adar. All computed on the undirected neighbor sense
	(union of out/in for directed networks, same convention as
	calculate_kcore() - a link-prediction/shared-neighborhood question is
	as direction-agnostic as a k-core question, unlike calculate_alterstat's
	exposure semantics, which are deliberately directional).

	NB is the symmetric 0/1 "is a neighbor of" indicator matrix with a
	zeroed diagonal - zeroing it kills two potential correctness bugs at
	once: a self-loop artifically inflating a node's own neighbor count,
	and node i or j themselves being counted as a "shared neighbor" of the
	pair (i,j) via the k=i or k=j term in the matrix-multiply sum below.
	CN = NB*NB' then gives every pairwise shared-neighbor count in one
	matrix multiply: CN[i,j] = sum_k NB[i,k]*NB[j,k] = |N(i) intersect N(j)|.

	Adamic-Adar weights each shared neighbor k by 1/log(degree(k)); k only
	ever contributes to a genuine intersection term if it is tied to two
	distinct nodes i != j, which forces degree(k) >= 2 automatically, so
	the well-known log(1)=0 division blowup can never actually occur for a
	real contributing term - the deg<2 guard below only protects the
	weight *vector's* construction (so it is a well-defined, finite input
	to the matrix product for every node, not just the ones that end up
	mattering), the same defensive missing-value discipline used in
	calculate_alterstat() and the nwburt fix earlier this session.
*/
real matrix `NWdef'::calculate_similarity_index(string scalar measure){
	real scalar n, i, k
	real matrix NB, nb, deg, CN, U, S, invlogdeg, degsum

	n = get_nodes()
	NB = J(n, n, 0)
	for (i = 1; i <= n; i++){
		if (isdirect){
			nb = uniqrows(neighbors(i) \ neighbors_in(i))
		}
		else {
			nb = neighbors(i)
		}
		if (rows(nb) > 0){
			NB[i, nb'] = J(1, rows(nb), 1)
		}
	}
	_diag(NB, J(n,1,0))

	deg = rowsum(NB)
	CN = NB * NB'
	// Mata's elementwise operators do not broadcast a column against a row
	// the way `deg :+ deg''s naive form would suggest (confirmed directly -
	// it is a conformability error, not silently wrong output); degsum[i,j]
	// = deg[i]+deg[j] via two ordinary (non-elementwise) outer-product-
	// shaped matrix multiplications instead.
	degsum = (deg * J(1,n,1)) :+ (J(n,1,1) * deg')

	if (measure == "common"){
		S = CN
	}
	else if (measure == "jaccard"){
		U = degsum :- CN
		S = CN :/ U
	}
	else if (measure == "dice"){
		S = (2 :* CN) :/ degsum
	}
	else if (measure == "cosine"){
		S = CN :/ sqrt(deg * deg')
	}
	else if (measure == "adamicadar"){
		invlogdeg = J(n, 1, 0)
		for (k = 1; k <= n; k++){
			if (deg[k] >= 2){
				invlogdeg[k] = 1 / log(deg[k])
			}
		}
		S = NB * diag(invlogdeg) * NB'
	}

	_diag(S, J(n,1,.))
	return(S)
}


real matrix `NWdef'::calculate_distances_without(){
	real scalar i, j, value1, value2
	real matrix res
	
	res = J(get_nodes(), get_nodes(),0)
	
	for (i = 1; i<=get_nodes(); i++){
		for (j = 1; j<= get_nodes(); j++){
			if	((*get_matrix())[i,j] != 0 & (*get_matrix())[i,j] != .){
				value1 = (*get_matrix())[i,j]
				value2 = (*get_matrix())[j,i]
				(*get_matrix())[i,j] = 0
				(*get_matrix())[j,i] = 0
				res[i,j] = calculate_distance_pair(i,j)
				(*get_matrix())[i,j] = value1
				(*get_matrix())[j,i] = value2
			}
		}
	}
	return(res)
}

real matrix `NWdef'::get_path(real scalar ego, real scalar alter, real scalar length)
{
	real scalar i, j, z, new_paths, id_next, new_temp, reach_num, found, step, temp, temp_new, nodes
	real matrix ids, paths, path_next, reach_next, reach_ids, paths_new, paths_sofar, paths_valid

	found = 0
	nodes = get_nodes()
	ids = (1::nodes)
	paths_sofar = J(1,1,ego)
	step = 0

	// no path from ego to alter
	if (calculate_distances(1, "brute")[ego, alter] == .){
		found = 1
		return(J(0,0,.))
	}
	else {
	 while (found == 0 & step <= nodes) {
		new_paths = 0
		step = step + 1
		for (z = 1; z<= rows(paths_sofar); z ++) {
			id_next = paths_sofar[z, step]
			reach_next = ((*get_matrix())[id_next,])'
			if (reach_next[alter,1] != 0) {
				found = 1
			}
			new_paths = new_paths + sum(reach_next)
		}
		
		paths_new = J(new_paths, (step + 1),0)

		temp = 1
		if (rows(paths_new)> 0) {
		  for (i = 1; i<= rows(paths_sofar); i ++) {
			id_next = paths_sofar[i, step]
			reach_next = ((*get_matrix())[id_next,])'
			_editmissing(reach_next,0)
			reach_ids = select(ids, reach_next)
			reach_num = sum(reach_next)
			if (reach_num > 0){
				path_next = J(reach_num, (step + 1),0)
				path_next[,step] = J(reach_num,1,id_next)
				path_next[,(step+1)] = reach_ids
				for (j = 1; j<step;j++){
					path_next[,j] = J(reach_num,1,paths_sofar[i,j])
				}
				new_temp = temp + (rows(path_next) - 1)
				paths_new[(temp::new_temp),] = path_next
				temp = new_temp + 1
			}
		   }
		  }
		  paths_sofar = paths_new
		
	}
	paths_valid = paths_sofar[,(step + 1)] :== alter
	paths = select(paths_sofar, paths_valid)
	return(paths)
	}
}

/*
	Weak (undirected-sense) connected components, via BFS over the sparse
	neighbor index instead of dense row/column pulls. Component numbering
	preserves the original dense implementation exactly: seeds are chosen
	in ascending node order (1..N), so the k-th component discovered gets
	label k under both implementations, node-for-node identical output -
	verified directly against the prior dense implementation in
	cscripts/test_sparse_index.do's dual-mode BFS before this method was
	changed. For directed networks, neighbors_in() is unioned with
	neighbors() per node, matching the old (*nw)[next,] :+ ((*nw)[,next])'
	out-plus-in behavior exactly.
*/
real matrix `NWdef'::calculate_components(){
	real scalar ncomp, next, i, numnodes, cur, qn
	real matrix visited, comp, queue, nb

	numnodes = get_nodes()
	visited = J(numnodes,1,0)
	comp = J(numnodes,1,0)
	ncomp = 1
	next = 1

	// as long as not everybody has been visited
	while (sum(visited) != numnodes){
		// find next not visited node
		while (visited[next,1]==1) {
			next = next + 1
		}

		// bfs from next, assign component id to everybody reachable
		visited[next,1] = 1
		comp[next,1] = ncomp
		queue = next

		while (rows(queue) > 0){
			cur = queue[1,1]
			qn = rows(queue)
			if (qn > 1){
				queue = queue[(2::qn),1]
			}
			else {
				queue = J(0,1,0)
			}
			nb = neighbors(cur)
			if (isdirect){
				nb = nb \ neighbors_in(cur)
			}
			for (i = 1; i <= rows(nb); i++){
				if (visited[nb[i,1],1]==0){
					visited[nb[i,1],1] = 1
					comp[nb[i,1],1] = ncomp
					queue = queue \ nb[i,1]
				}
			}
		}
		ncomp = ncomp + 1
	}
	return(comp)
}

real matrix `NWdef'::get_adjlist(){
	real scalar n, i, numneighb
	real matrix Glist

	numneighb = rowsum(*get_matrix() :!= 0 :& *get_matrix() :!= . )
	
	Glist  = J(get_nodes(),max(numneighb),.)
	
	for (i = 1; i <= get_nodes(); i++){
		if (numneighb[i] > 0){ 
			Glist[i,(1..(numneighb[i]))] = selectindex((*get_matrix() :!= 0 :& *get_matrix() :!= .)[i,.])
		}
	}
	return((Glist))
}

/*
	Sparse index (CSR out-neighbors + CSC-style in-neighbors for directed
	networks), derived from `edge`. `edge` remains the single source of
	truth; this is a rebuildable cache, invalidated by any method that
	mutates `edge` (see the `sparse_built = `False'' calls in set_edge(),
	init_edge(), add_node(), keep_nodes(), drop_nodes(), symmetrize(), and
	clean_matrix_2mode()) and lazily rebuilt on next access via
	ensure_sparse_built(). Self-loops and missing cells are excluded, same
	as the rest of the class's edge-counting conventions.
*/
void `NWdef'::build_sparse_index(){
	real matrix e, nzmask, rowidx, idx
	real scalar n, nnz, i, k, pos

	n = get_nodes()
	e = edge
	nzmask = (e :!= 0 :& e :!= .)

	nnz = sum(nzmask)
	rowptr = J(n + 1, 1, 0)
	rowidx = J(nnz, 1, 0)
	colidx = J(nnz, 1, 0)
	cweight = J(nnz, 1, 0)

	pos = 1
	for (i = 1; i <= n; i++){
		rowptr[i] = pos
		if (n > 0){
			idx = selectindex(nzmask[i,.])
			k = cols(idx)
			if (k > 0){
				colidx[(pos::(pos+k-1)),1] = idx'
				cweight[(pos::(pos+k-1)),1] = e[i,idx]'
			}
			pos = pos + k
		}
	}
	rowptr[n + 1] = pos

	if (isdirect & nnz > 0){
		for (i = 1; i <= n; i++){
			if (rowptr[i+1] > rowptr[i]){
				rowidx[(rowptr[i]::(rowptr[i+1]-1)),1] = J(rowptr[i+1]-rowptr[i], 1, i)
			}
		}
		build_reverse_index(rowidx, nnz)
	}
	else {
		rowptr_in = J(0, 1, 0)
		colidx_in = J(0, 1, 0)
		edgeid_in = J(0, 1, 0)
	}

	sparse_built = `True'
}

/*
	Builds the CSC-style reverse (in-neighbor) index from the forward CSR's
	own row labels (`rowidx`, one source-node label per stored entry).
	`edgeid_in` points back into colidx/cweight rather than duplicating
	weights, so a forward-index rebuild can never desync it from the
	reverse one.
*/
void `NWdef'::build_reverse_index(real matrix rowidx, real scalar nnz){
	real matrix perm, sorted_target
	real scalar n, j, pos

	n = get_nodes()

	if (nnz == 0){
		rowptr_in = J(n + 1, 1, 1)
		colidx_in = J(0, 1, 0)
		edgeid_in = J(0, 1, 0)
		return
	}

	perm = order(colidx, 1)
	colidx_in = rowidx[perm,1]
	edgeid_in = perm
	sorted_target = colidx[perm,1]

	rowptr_in = J(n + 1, 1, 0)
	pos = 1
	for (j = 1; j <= n; j++){
		rowptr_in[j] = pos
		while (pos <= nnz){
			if (sorted_target[pos,1] != j) break
			pos = pos + 1
		}
	}
	rowptr_in[n + 1] = pos
}

void `NWdef'::ensure_sparse_built(){
	if (sparse_built != `True'){
		build_sparse_index()
	}
}

/*
	Marks the sparse cache stale. Public, for the (few) callers outside this
	class that mutate `edge' by writing through the get_matrix() pointer
	directly rather than through an NWdef mutator method - e.g. nwreplace.ado.
*/
void `NWdef'::invalidate_sparse(){
	sparse_built = `False'
}

/*
	Genuinely sparse-native construction: builds the CSR/CSC index directly
	from an edge triplet list (ego, alter, weight - all length-nnz
	colvectors, 1-indexed against the network's existing node count) and
	NEVER allocates the N x N `edge' matrix. Node identity/count/names must
	already be set (via create()/create_by_name(), same precondition as
	set_edge()). `edge' is left as an empty placeholder and
	`edge_dense_built' is set false, so any later call that genuinely needs
	the dense matrix (get_matrix() et al.) materializes it on demand -
	see ensure_dense_built() - rather than never being able to get one.

	This is the actual fix for the O(N^2) creation bottleneck identified in
	this session's architecture report (nwfromedge.ado's make_matrix(),
	which unconditionally allocates J(nodes,nodes,0) regardless of edge
	count): a caller with a triplet list can build a network here in
	O(nnz log nnz) time and O(nnz) memory, full stop.

	Ego/alter are expected pre-mapped to dense 1..n node ids (exactly what
	nwfromedge.ado's existing node-id dictionary stage already produces,
	before it hands off to the dense make_matrix() helper today - that
	mapping stage is unaffected and fully reusable, per the architecture
	report).
*/
void `NWdef'::set_edge_from_triplets(real matrix ego, real matrix alter, real matrix weight, real scalar directed){
	real scalar n, nnz, i, pos
	real matrix ord, sorted_ego, sorted_alter, sorted_weight

	n = get_nodes()
	isdirect = directed
	nnz = rows(ego)

	edge = J(0,0,0)
	edge_dense_built = `False'

	if (nnz == 0){
		rowptr = J(n+1,1,1)
		colidx = J(0,1,0)
		cweight = J(0,1,0)
	}
	else {
		ord = order(ego, 1)
		sorted_ego = ego[ord,1]
		sorted_alter = alter[ord,1]
		sorted_weight = weight[ord,1]

		rowptr = J(n+1,1,0)
		colidx = sorted_alter
		cweight = sorted_weight
		pos = 1
		for (i=1; i<=n; i++){
			rowptr[i] = pos
			while (pos <= nnz){
				if (sorted_ego[pos,1] != i) break
				pos = pos + 1
			}
		}
		rowptr[n+1] = pos
	}

	if (isdirect & nnz > 0){
		build_reverse_index(sorted_ego, nnz)
	}
	else {
		rowptr_in = J(0, 1, 0)
		colidx_in = J(0, 1, 0)
		edgeid_in = J(0, 1, 0)
	}

	if (nnz > 0){
		isvalued = (min(weight) < 0 | max(weight) > 1)
	}
	else {
		isvalued = `False'
	}

	sparse_built = `True'
}

/*
	Materializes `edge' from the sparse triplet store on first demand,
	guarded against accidentally allocating an unreasonably large dense
	matrix (nw_max_dense_nodes, from unw_defs.ado - a network built
	sparse-natively and queried only through sparse-native accessors never
	hits this at all). Called from every get_matrix*() accessor, so every
	existing dense-matrix-consuming command keeps working unchanged on a
	sparse-natively-built network up to that size limit, with a clear error
	instead of silently exhausting memory beyond it - the compatibility
	strategy from this session's architecture report.
*/
void `NWdef'::ensure_dense_built(){
	real matrix e
	real scalar n, i

	if (edge_dense_built != `False'){
		return
	}

	n = get_nodes()
	if (n > `nw_max_dense_nodes'){
		error_handle("Network `" + get_name() + "' has " + strofreal(n) + " nodes; materializing a dense " + strofreal(n) + "x" + strofreal(n) + " matrix would require approximately " + strofreal(round((n*n*8/1024^3)*100)/100) + " GB and has been refused. Use a sparse-native command (neighbors(), degree(), calculate_components(), etc.) instead, which never requires the dense matrix.", `errDenseTooLarge')
	}

	ensure_sparse_built()
	e = J(n, n, 0)
	for (i = 1; i <= n; i++){
		if (rowptr[i+1] > rowptr[i]){
			e[i, colidx[(rowptr[i]::(rowptr[i+1]-1)),1]'] = cweight[(rowptr[i]::(rowptr[i+1]-1)),1]'
		}
	}
	if (isselfloop == 0){
		_diag(e, .)
	}
	edge = e
	edge_dense_built = `True'
}

/*
	Neighbors of node i. For undirected networks `edge` is already stored
	symmetrically, so the out-CSR alone already lists every neighbor -
	directed and undirected networks share this one accessor.
*/
real matrix `NWdef'::neighbors(real scalar i){
	ensure_sparse_built()
	if (rowptr[i+1] > rowptr[i]){
		return(colidx[(rowptr[i]::(rowptr[i+1]-1)),1])
	}
	return(J(0,1,0))
}

real matrix `NWdef'::neighbors_in(real scalar i){
	ensure_sparse_built()
	if (!isdirect){
		return(neighbors(i))
	}
	if (rowptr_in[i+1] > rowptr_in[i]){
		return(colidx_in[(rowptr_in[i]::(rowptr_in[i+1]-1)),1])
	}
	return(J(0,1,0))
}

real scalar `NWdef'::degree(real scalar i){
	ensure_sparse_built()
	return(rowptr[i+1] - rowptr[i])
}

real scalar `NWdef'::degree_in(real scalar i){
	ensure_sparse_built()
	if (!isdirect){
		return(degree(i))
	}
	return(rowptr_in[i+1] - rowptr_in[i])
}

real scalar `NWdef'::has_edge(real scalar i, real scalar j){
	ensure_sparse_built()
	if (rowptr[i+1] > rowptr[i]){
		return(sum(colidx[(rowptr[i]::(rowptr[i+1]-1)),1] :== j) > 0)
	}
	return(0)
}

real scalar `NWdef'::edge_weight(real scalar i, real scalar j){
	real matrix idx

	ensure_sparse_built()
	if (rowptr[i+1] > rowptr[i]){
		idx = selectindex(colidx[(rowptr[i]::(rowptr[i+1]-1)),1] :== j)
		if (cols(idx) > 0){
			return(cweight[rowptr[i] + idx[1] - 1, 1])
		}
	}
	return(0)
}

/*
	Sparse-native edge enumeration: source, target, weight - one row per
	stored entry, O(nnz). Not wired into any command yet (see get_edgelist()
	for the existing O(N^2) dense-scan version consumed by nwtoedge today).
*/
real matrix `NWdef'::edgelist(){
	real matrix out
	real scalar n, i, nnz

	ensure_sparse_built()
	n = get_nodes()
	nnz = rows(colidx)
	out = J(nnz, 3, 0)
	for (i = 1; i <= n; i++){
		if (rowptr[i+1] > rowptr[i]){
			out[(rowptr[i]::(rowptr[i+1]-1)), 1] = J(rowptr[i+1]-rowptr[i], 1, i)
		}
	}
	if (nnz > 0){
		out[.,2] = colidx
		out[.,3] = cweight
	}
	return(out)
}

void `NWdef'::permute(){
	real matrix perm
	perm = unorder(get_nodes())
	set_edge((*get_matrix())[perm, perm])
}

real scalar `NWdef'::calculate_distance_pair(real scalar ego, real scalar alter){
	real scalar found, distance
	real matrix temp, temp2
	
	distance = 1
	found = 0
	temp = (*get_matrix())
	_editmissing(temp,0)
	temp2 = temp

	while (found == 0 & distance < get_nodes()){
		if (temp[ego, alter] != 0 & temp[ego,alter] != .) {
			found = 1
			return(distance)
		}
		else {
			temp = temp * temp2
		}
		distance = distance + 1
	}
	return(-1)
}

real matrix `NWdef'::calculate_distances(real scalar alpha, string scalar alg){
	if (alg == "brute"){
		return(Brute_dist(*get_matrix_unvalued()))
	}
	else {
		return(Dijkstra_dist(*get_matrix(), alpha))
	}
}

/*
	Weighted (Dijkstra-based) generalization of calculate_betweenness()
	above - same Brandes' (2001) two-phase structure (single-source
	shortest-path-DAG discovery, then back-propagation of dependencies),
	generalized from unweighted BFS to weighted Dijkstra: a plain FIFO
	dequeue becomes a linear-scan extract-min over unsettled nodes (Mata
	has no built-in priority queue/decrease-key), and the unweighted
	hop-distance relaxation "D[w]==D[v]+1" becomes a real-valued
	"D[w]==D[v]+cost(v,w)". Edge cost is edge_weight(v,w)^alpha, the
	same alpha-exponent weight-to-distance convention this package
	already uses for calculate_distances()/nwgeodesic (alpha=1: raw
	weight used directly as cost/distance; alpha=0: every positive tie
	costs 1, i.e. unweighted). Only strictly positive ties are edges at
	all (same >0 filter as the unweighted version, so a negative tie in
	a signed network is silently excluded here exactly as it already is
	there - not silently misread as a valid Dijkstra edge cost, which a
	negative weight cannot be).
*/
real matrix `NWdef'::calculate_betweenness_weighted(real scalar alpha){
	real matrix adjacencyList, adjacencyCost, Cb, Stack, P, nP, S, D, Dd
	real matrix nb, settled
	real scalar m, k, n, s, v, j, w, idx, u, mindist, nn, cost

	nn = get_nodes()
	adjacencyList = J(nn, nn-1, .)
	adjacencyCost = J(nn, nn-1, .)
	for (m=1; m<=nn; m++) {
		nb = neighbors(m)
		k=1
		for (idx=1; idx<=rows(nb); idx++) {
			n = nb[idx,1]
			if ( m!=n & edge_weight(m,n)>0){
				adjacencyList[m,k] = n
				adjacencyCost[m,k] = edge_weight(m,n)^alpha
				k++
			}
		}
	}

	Cb=J(1,nn,0)

	for(s=1; s<=nn; s++) {
		Stack=J(1,0,.)
		P=J(nn,nn,.)
		nP=J(nn,1,1)
		S=J(1,nn,0)
		S[s]=1
		D=J(1,nn,.)
		D[s]=0
		settled=J(1,nn,0)

		for (m=1; m<=nn; m++) {
			mindist=.
			u=0
			for (j=1; j<=nn; j++) {
				if (settled[j]==0 & D[j]<. & (u==0 | D[j]<mindist)) {
					mindist=D[j]
					u=j
				}
			}
			if (u==0) break
			settled[u]=1
			v=u

			Stack=cols(Stack)? v,Stack : v
			for(j=1; j<=sum(adjacencyList[v,.]:<.);j++) {
				w=adjacencyList[v,j]
				cost=adjacencyCost[v,j]
				if (settled[w]) continue
				if(D[w]==. | D[w]>D[v]+cost) {
					D[w]=D[v]+cost
					S[w]=0
					nP[w]=1
				}
				if(D[w]==D[v]+cost) {
					S[w]=S[w]+S[v]
					P[w,nP[w]]=v; nP[w]=nP[w]+1
				}
			}
		}

		Dd=J(1,nn,0)

		while (cols(Stack)) {
			w=dequeue(Stack)

			for(j=1; j<nP[w]; j++) {
				v=P[w,j]
				Dd[v]=Dd[v]+(S[v]/S[w])*(1+Dd[w])
			}
			if (w!=s) Cb[w]=Cb[w]+Dd[w]
		}
	}

	if (!isdirect){
		Cb = Cb :/ 2
	}
	return(Cb')
}

real matrix `NWdef'::calculate_betweenness(){
	real matrix adjacencyList, Cb,Stack,P,nP, S, D, Queue, Dd
	real matrix nb
	real scalar m, k, n, s, v, j, w, idx

	// adjacencyList's own N x (N-1) shape is unchanged (still one row per
	// node, sized for the worst case) - only the O(N^2) dense-matrix scan
	// that used to populate it is replaced, with the sparse index instead.
	// The `>0' filter is preserved exactly: neighbors() includes any
	// nonzero, non-missing tie (so a negative tie, e.g. in a signed
	// network, would be included), so it's re-checked here per candidate
	// to match the original's positive-only semantics precisely.
	adjacencyList=J(get_nodes(),get_nodes()-1,.)
	for (m=1; m<=get_nodes(); m++) {
		nb = neighbors(m)
		k=1
		for (idx=1; idx<=rows(nb); idx++) {
			n = nb[idx,1]
			if ( m!=n & edge_weight(m,n)>0){
				adjacencyList[m,k++]=n
			}
		}
    }

	Cb=J(1,get_nodes(),0)
	
	for(s=1; s<=get_nodes(); s++) {
		Stack=J(1,0,.)
		P=J(get_nodes(),get_nodes(),.)
		nP=J(get_nodes(),1,1)
		S=J(1,get_nodes(),0)
		S[s]=1
		D=J(1,get_nodes(),-1)
		D[s]=0
		Queue=J(1,0,.)
		Queue=(cols(Queue)? Queue,s : s)
		while(cols(Queue)) {
			v=dequeue(Queue)
		
			Stack=cols(Stack)? v,Stack : v
			for(j=1; j<=sum(adjacencyList[v,.]:<.);j++) {
				w=adjacencyList[v,j]
				if(D[w]<0) {
					Queue=(cols(Queue)? Queue,w : w)
					D[w]=D[v]+1
				}
				if(D[w]==D[v]+1) {
					S[w]=S[w]+S[v]
					P[w,nP[w]]=v; nP[w]=nP[w]+1
				}     
			}	
		}
		
		Dd=J(1,get_nodes(),0)
		
		while (cols(Stack)) {
			w=dequeue(Stack)
  
			for(j=1; j<nP[w]; j++) {
				v=P[w,j]
				Dd[v]=Dd[v]+(S[v]/S[w])*(1+Dd[w])
			}
			if (w!=s) Cb[w]=Cb[w]+Dd[w]
		}
	}

	// BUGFIX (intentional, per user direction, separate from the sparse
	// migration): summing over every node as source visits each undirected
	// shortest path twice (once from each endpoint), doubling every score.
	// Standard practice - and what nwbetween.ado's own `standardize' formula
	// already assumes - is to halve for undirected networks.
	if (!isdirect){
		Cb = Cb :/ 2
	}
	return(Cb')
}


void `NWdef'::clean_matrix_2mode(){
	real matrix z
	z = ((J(get_nodes(),1, modes):== J(1,get_nodes(), modes')):== 1)
	_editvalue(z, 1, .)
	edge = edge :+ z
	sparse_built = `False'
}

void `NWdef'::set_description_mode1(string scalar description){
	description_mode1 = description
}

void `NWdef'::set_description_mode2(string scalar description){
	description_mode2 = description
}

string scalar `NWdef'::get_description_mode1(){
	return(description_mode1)
}

string scalar `NWdef'::get_description_mode2(){
	return(description_mode2)
}

void `NWdef'::set_nodes_mode1(real scalar m1){
	nodesmode1 = m1
	nodesmode2 = get_nodes() - m1
}

void `NWdef'::set_nodes_mode2(real scalar m2){
	nodesmode2 = m2
}

void `NWdef'::set_modes(string rowvector m){
	modes = m
}

string matrix `NWdef'::get_modes(){
    if (cols(modes) == 0) {
		set_modes(J(1,get_nodes(),"1"))
	}
	return(modes)
}

/*
	Serializes the per-node mode assignment as "label=mode,label=mode,..."
	pairs - keyed by each node's own label rather than by bare position,
	so it survives round-tripping through nwsave/nwuse even though the
	reload path (nwfromedge, rebuilding the network from a saved
	edgelist) is not guaranteed to reproduce the exact original node
	ordering. Used by nwsave.ado (via a new nw_name.ado r(modes) return)
	to persist mode membership - previously NOT saved at all despite
	is2mode itself being saved correctly, a genuine, previously-
	undiscovered bug: nwsave's own edgelist-export step
	(nwtoedge ... ignore2mode) discards mode information by design (it
	is only meant to capture edges), and nothing else ever wrote the
	`modes' array out as data, so every saved-and-reloaded two-mode
	network silently lost its actual mode partition (only the boolean
	"is this a two-mode network" flag survived) - confirmed directly via
	a save/reload round-trip before this fix. See
	set_modes_from_labeled_string() below for the matching reload side.
*/
string scalar `NWdef'::get_modes_labeled_string(){
	string rowvector m
	string scalar result
	real scalar i

	m = get_modes()
	result = ""
	for (i=1; i<=cols(nodes); i++) {
		if (i > 1) result = result + ","
		result = result + nodes[i] + "=" + m[i]
	}
	return(result)
}

/*
	Reload side of get_modes_labeled_string() above - parses
	"label=mode,label=mode,..." pairs and places each mode value at
	whatever index that label currently occupies in `nodes' (via
	first_index_match(), not a positional assumption), so it is robust
	to the reloaded network's own node order potentially differing from
	the order in effect when the string was originally saved. A label
	from the string that is no longer found in the current `nodes'
	array (should not normally happen - node identity is exactly what
	the edgelist-based save/reload mechanism is meant to preserve - but
	handled defensively rather than assumed) is silently skipped rather
	than erroring. A blank string (e.g. reloading a legacy .nwdta file
	saved before this fix existed, which never wrote this data out at
	all) is a deliberate no-op: get_modes()'s own existing lazy default
	(all nodes "1") applies exactly as it always has, with no attempt
	to retroactively guess mode membership that was never actually
	saved - the same "do not silently reinterpret old data" principle
	nwuse.ado's own new2mode() handling already follows for is2mode.
*/
void `NWdef'::set_modes_from_labeled_string(string scalar s){
	string scalar remaining, onepair, lab, md
	real scalar idx, eqpos, commapos

	if (s == "") return
	get_modes()
	remaining = s
	while (strlen(remaining) > 0) {
		commapos = strpos(remaining, ",")
		if (commapos == 0) {
			onepair = remaining
			remaining = ""
		}
		else {
			onepair = substr(remaining, 1, commapos-1)
			remaining = substr(remaining, commapos+1, .)
		}
		eqpos = strpos(onepair, "=")
		if (eqpos > 0) {
			lab = substr(onepair, 1, eqpos-1)
			md = substr(onepair, eqpos+1, .)
			idx = first_index_match(nodes, lab)
			if (idx > 0) modes[idx] = md
		}
	}
}

real scalar `NWdef'::get_nodes_mode1(){
    return(sum(modes:=="1"))
}

real scalar `NWdef'::get_nodes_mode2(){
    return(sum(modes:=="2"))
}

string scalar `NWdef'::get_nodesvar_string(){
	return(invtokens(nodesvar," "))
}

string matrix `NWdef'::get_nodesvar(){
	return(nodesvar)
}

string scalar `NWdef'::get_nodenames_string(){
	return(invtokens(nodes,";"))
}

void `NWdef'::set_nodesvar(string matrix v){
	nodesvar = v
}

string matrix `NWdef'::get_edgelist_compressed(real scalar undirected){
	string matrix _edge
	_edge = get_edgelist(undirected)
	return(select(_edge, ((_edge[,3]:!= ".") :& (_edge[,3]:!= "0"))))
}

string matrix `NWdef'::get_edgelist(real scalar undirected){
	string matrix sender, receiver, sender_num, receiver_num
	real scalar i, size
	real matrix e, z
	
	receiver = J(get_nodes(), 1, nodes)	
	sender = J(1,get_nodes(), nodes')
	
	receiver_num = J(get_nodes(), 1, (1::get_nodes())')
	sender_num = J(1, get_nodes(), (1::get_nodes()))
	

	// -- TODO -- change to pointer matrix

	e = get_matrix_copy()
	if (undirected == 1) {
		z = lowertriangle(J(get_nodes(), get_nodes(), 1),1)  
	}
	else {
		z = J(get_nodes(), get_nodes(), 1)
	}
	return(select((vec(sender), vec(receiver), strofreal(vec(e)), strofreal(vec(z)), strofreal(vec(e')),strofreal(vec(sender_num)), strofreal(vec(receiver_num))), vec(z)))
}


void `NWdef'::drop_nodes(rowvector d){
	keep_nodes(d:==0)
}

void `NWdef'::keep_nodes(rowvector k){
	real matrix edge_new
	string matrix modes_new, nodesvar_new, nodes_new

	if (cols(k) == cols(nodes)){
		nodes_new = select(nodes,k)
		nodesvar_new = select(nodesvar,k)
		if (is2mode == 1){
			modes_new = select(modes,k)
		}
		edge_new = select(edge,k)
		edge_new = select(edge_new,k')
		nodes = nodes_new
		nodesvar = nodesvar_new
		modes = modes_new
		edge = edge_new
		sparse_built = `False'
	}
}

real scalar `NWdef'::is_selfloop_boolean(){
	return(isselfloop)
}

real scalar `NWdef'::is_valued_boolean(){
	return(isvalued)
}

real scalar `NWdef'::is_directed_boolean(){
	return(isdirect)
}

real scalar `NWdef'::is_2mode_boolean(){
	return(is2mode)
}
	
void `NWdef'::set_valued(real scalar d){
	isvalued = d
}

void `NWdef'::set_2mode(real scalar d){
	is2mode = d
}

real scalar `NWdef'::check_symmetry(){
//!! TODO - change when network not saved as matrix edge
	if (edge == edge'){
		return(1)
	}
	return(0)
}

/*
pointer (real matrix) scalar `NWdef'::get_symmetrize(string scalar mode){
//!! TODO - change when network not saved as matrix edge	
	real matrix d, res1, res2
	d = diagonal(edge)
	
	if (mode == "sum") {
		return(&(edge  + edge'))
	}
	if (mode == "mean") {
		return(&((edge  + edge'):/2))
	}
	if (mode == "max") {
		res2 = (edge')
		res2 = ((edge') :> edge):* res2
		res1 = edge
		res1 = (edge :>= (edge')):* res1
		return(&res1 + res2
	}
	if (mode == "min") {
		res2 = (edge')
		res2 = ((edge') :< edge):* res2
		res1 = edge
		res1 = (edge :<= (edge')):* res1
		edge = res1 + res2
	}
	_diag(edge,d)
	set_directed(0)
}*/

void `NWdef'::symmetrize(string scalar mode){
//!! TODO - change when network not saved as matrix edge	
	real matrix d, res1, res2
	d = diagonal(edge)
	
	if (mode == "sum") {
		edge = edge  + edge'
	}
	if (mode == "mean") {
		edge = (edge  + edge'):/2
	}
	if (mode == "max") {
		res2 = (edge')
		res2 = ((edge') :> edge):* res2
		res1 = edge
		res1 = (edge :>= (edge')):* res1
		edge = res1 + res2
	}
	if (mode == "min") {
		res2 = (edge')
		res2 = ((edge') :< edge):* res2
		res1 = edge
		res1 = (edge :<= (edge')):* res1
		edge = res1 + res2
	}
	_diag(edge,d)
	set_directed(0)
	sparse_built = `False'
}

/*
	Generalized (Opsahl et al. 2010) degree centrality: k_i * (s_i/k_i)^alpha,
	where k_i is unweighted degree (tie count) and s_i is weighted degree
	(tie-value sum). Both use the sparse index instead of a full-matrix
	rowsum/colsum. get_indegree() falls back to the forward (out) index for
	undirected networks, matching how neighbors_in() does the same - `edge'
	already stores undirected ties symmetrically, so out-ties are the
	complete tie set and no reverse index is built for them in the first
	place (build_sparse_index() only builds rowptr_in/colidx_in/edgeid_in
	when isdirect).
*/
real matrix `NWdef'::get_indegree(real scalar alpha){
	real matrix s, k
	real scalar i, n

	ensure_sparse_built()
	n = get_nodes()
	s = J(n,1,0)
	k = J(n,1,0)
	if (!isdirect){
		for (i=1; i<=n; i++){
			if (rowptr[i+1] > rowptr[i]){
				k[i,1] = rowptr[i+1] - rowptr[i]
				s[i,1] = sum(cweight[(rowptr[i]::(rowptr[i+1]-1)),1])
			}
		}
	}
	else {
		for (i=1; i<=n; i++){
			if (rowptr_in[i+1] > rowptr_in[i]){
				k[i,1] = rowptr_in[i+1] - rowptr_in[i]
				s[i,1] = sum(cweight[edgeid_in[(rowptr_in[i]::(rowptr_in[i+1]-1)),1],1])
			}
		}
	}
	return(editmissing((k :* ((s :/ k) :^ alpha)),0))
}

real matrix `NWdef'::get_outdegree(real scalar alpha){
	real matrix s, k
	real scalar i, n

	ensure_sparse_built()
	n = get_nodes()
	s = J(n,1,0)
	k = J(n,1,0)
	for (i=1; i<=n; i++){
		if (rowptr[i+1] > rowptr[i]){
			k[i,1] = rowptr[i+1] - rowptr[i]
			s[i,1] = sum(cweight[(rowptr[i]::(rowptr[i+1]-1)),1])
		}
	}
	return(editmissing((k :* ((s :/ k) :^ alpha)),0))
}

string matrix `NWdef'::get_nodenames(){
	return(nodes)
}

/*
	Sync network with dataset
*/
void `NWdef'::data_sync(){
	real scalar newobs
	real scalar N, z, v
	string colvector newnodename

	z = 0
	if (_st_varindex("`nw_nodename'") == .) {
		v= st_addvar("str40","`nw_nodename'")
		z = st_nobs()
	}
	
	update_match()
	newobs = sum(match[,2]:==.) - z
	
	N = st_nobs()
	if (newobs > 0){
		st_addobs(newobs)
		newnodename = select(nodes,(match[.,2]:==.)')'
		st_sstore(((N+1)::(N+newobs)),"`nw_nodename'", newnodename)	
		update_match()
	}
}

/*
	Update matching between nodes 1,2,3... and cases in the dataset.
*/
void `NWdef'::update_match(){
	match = match_xy(nodes',st_sdata(.,"`nw_nodename'"))	
}

/*
	Update variable names that should be used when loading data to Stata
*/
void `NWdef'::update_nodesvar(){
	real scalar i, j, k
	
	k = cols(nodesvar)
	
	nodesvar = strtoname(nodes)
	for(i = 1; i<=k;i++){
		for(j = 1; j<=k;j++){
			if (nodesvar[i] == nodesvar[j] & i != j ){
				j = k + 1
				i = j
				nodesvar = J(1,k,"`nwvars_def_pref'") + (strofreal(1::k))'
			}
		}	
	}
}

/*
	Get number of self-loops
*/
real scalar `NWdef'::get_selfloops_number(){
	real matrix  d
	
	if (isselfloop == 1) { 
		d = diagonal(*get_matrix())
		return(sum(d :/ d))	
	}
	else {
		return(0)
	}
}

/*
	Get network density
*/
real scalar `NWdef'::get_density(){
	pointer(real matrix) scalar e

	e = get_matrix_unvalued()
	return(sum(*e)/ sum(*e:!= .))
}


/*
	Get edges counts
*/
real scalar `NWdef'::get_edges_count(){
	pointer(real matrix) scalar e
	
	e = get_matrix()
	return(sum(*e:!=. :& *e:!=0)/2)
}

/*
	Get sum of edge values
*/
real scalar `NWdef'::get_edges_sum(){
	pointer(real matrix) scalar e
	
	e = get_matrix()
	return(sum(*e)/2)
}

/*
	Get arcs counts
*/
real scalar `NWdef'::get_arcs_count(){
	pointer(real matrix) scalar e

	e = get_matrix()
	return(sum(*e:!=. :& *e:!=0))
}

/*
	Get sum of arc values
*/
real scalar `NWdef'::get_arcs_sum(){
	pointer(real matrix) scalar e
	
	e = get_matrix()
	return(sum(*e))
}

/*
	Get missing edge values
*/
real scalar `NWdef'::get_missing_edges(){
	pointer(real matrix) scalar e
	
	e = get_matrix()
	return(sum(*e:==.))
}

/*
	Get minimum edge value
*/
real scalar `NWdef'::get_minimum(){
	pointer(real matrix) scalar e
	
	e = get_matrix()
	return(min(*e))
}

/*
	Get maximum edge value
*/
real scalar `NWdef'::get_maximum(){
	pointer(real matrix) scalar e
	
	e = get_matrix()
	return(max(*e))
}

/*
	Set network label
*/
void `NWdef'::set_label(string scalar s){
	label = s
}

/*
	Set network caption
*/
void `NWdef'::set_caption(string scalar s){
	caption = s
}

/*
	Set new nodes
*/
void `NWdef'::set_nodes(rowvector n){
	nodes = n
}

void `NWdef'::set_nodenames(rowvector n){
	nodes = n
}

`BOOL' `NWdef'::rename_nodename(string scalar oldname, string scalar newname){
	real scalar i
	if (cols(selectindex(nodes:== newname)) != 0) {
		return(0)
	}
	else {
		i = selectindex(nodes:== oldname)
		if (cols(i) == 0) {
			return(0)
		}
		else {
			nodes[i[1]] = newname
			update_nodesvar()
			return(1)
		}
	}
}


void `NWdef'::set_nodes_from_string(string scalar s){
	nodes = tokens(s,";")
}

/*
	Return network label
*/
string scalar `NWdef'::get_label(){
	return(label)
}

/*
	Return network caption
*/
string scalar `NWdef'::get_caption(){
	return(caption)
}

/*
	Return true/false string if network is valued
*/
string scalar `NWdef'::is_valued(){
	if (isvalued == 1) {
		return("true")
	}
	else {
		return("false")
	}
}

/*
	Return true/false string if network has self-loops
*/
string scalar `NWdef'::is_selfloop(){
	if (isselfloop == 1) {
		return("true")
	}
	else {
		return("false")
	}
}

/*
	Return true/false string if network is two-mode
*/
string scalar `NWdef'::is_2mode(){
	if (is2mode == 1) {
		return("true")
	}
	else {
		return("false")
	}
}

/*
	Return true/false string if network is directed
*/
string scalar `NWdef'::is_directed(){
	if (isdirect == 1) {
		return("true")
	}
	else {
		return("false")
	}
}

/* 
	Return list of variables for network representation in dataset
*/
string scalar `NWdef'::get_vars(){
	 string scalar s
	 real scalar i
	 
	 for(i = 1 ; i<= get_nodes(); i++) {
			s = s + " " + ustrtoname(nodes[i])
	 }
	 return(s)
}
	
/*
	Return number of nodes
*/
real scalar `NWdef'::get_nodes(){
	return(cols(nodes))
}

/*
	Return name of a network
*/
string scalar `NWdef'::get_name(){
	return(name)
}

/*
	Create a network with n nodes
*/
void `NWdef'::create(real scalar n, | string scalar prefix) {
	real scalar v
	zap()
	if(args() == 1) {
		nodes = "`nwvars_def_pref'" :+ strofreal((1..n))
	}
	else {
		nodes = prefix :+ strofreal((1..n))	
	}
	update_nodesvar()
	init_edge()
	
	if (_st_varindex("`nw_nodename'") == .) {
		v = st_addvar("str40","`nw_nodename'")
	}
}

/*
	Set a network
*/
void `NWdef'::set(string scalar networkname, string colvector nodenames, real matrix edge, `BOOL' isdirect){
	this.name = networkname
	this.nodes = nodenames
	this.edge = edge
	this.isdirect = isdirect
	
	if (max(edge) > 1 | min(edge) < 0) {
		this.isvalued = `True'
	}
	else {
		this.isvalued = `False'
	}
} 

/*
	Create a network with n nodes by name
*/
void `NWdef'::create_by_name(string rowvector name) {
	real scalar v

	zap()
	nodes = name
	update_nodesvar()
	init_edge()
	if (_st_varindex("`nw_nodename'") == .) {
		v =	st_addvar("str40","`nw_nodename'")
	}

}

/*
	Genuinely sparse-native counterpart to create_by_name(): identical
	except it calls init_edge_sparse() instead of init_edge(), so node
	identity/count can be established WITHOUT allocating an N x N `edge'
	matrix - create_by_name() itself does (via init_edge()'s
	J(size,size,0)), which would defeat set_edge_from_triplets()'s purpose
	for any caller that needs both. Added as a separate method rather than
	changing create_by_name() itself: every existing command relies on
	create_by_name() leaving `edge' immediately dense-valid, and changing
	that default for everyone is a much larger, riskier change than this
	narrowly-scoped addition needs.
*/
void `NWdef'::create_by_name_sparse(string rowvector name) {
	real scalar v

	zap()
	nodes = name
	update_nodesvar()
	init_edge_sparse()
	if (_st_varindex("`nw_nodename'") == .) {
		v =	st_addvar("str40","`nw_nodename'")
	}
}

/* 
	Set name property
*/
void `NWdef'::set_name(string scalar s) {
	name = s 
}

/* 
	REMOVE SELFLOOPS!!!! This sucks
	
	Set isselfloop property
*/
void `NWdef'::set_selfloop(real scalar d) {
	isselfloop = d
	if (isselfloop == 0) {
		_diag(edge,.)
	}
}


/* 
	Set isdirect property
*/
void `NWdef'::set_directed(real scalar d) {
	isdirect = d
}

/*
	Initialize edge matrix
*/
void `NWdef'::init_edge() {
	real scalar size
//!! create edge matrix based on edgetype
	size = cols(nodes)
	edge = J(size, size, 0)
	sparse_built = `False'
	edge_dense_built = `True'
}

/*
	Sparse-native counterpart to init_edge(): establishes an empty (no
	edges yet) sparse index for `size' nodes WITHOUT allocating the N x N
	`edge' matrix. Pairs with create_by_name_sparse() / a later
	set_edge_from_triplets() call.
*/
void `NWdef'::init_edge_sparse() {
	real scalar size

	size = cols(nodes)
	edge = J(0, 0, 0)
	edge_dense_built = `False'
	rowptr = J(size+1, 1, 1)
	colidx = J(0, 1, 0)
	cweight = J(0, 1, 0)
	rowptr_in = J(0, 1, 0)
	colidx_in = J(0, 1, 0)
	edgeid_in = J(0, 1, 0)
	sparse_built = `True'
}

/*
	Set edge matrix
*/
void `NWdef'::set_edge(real matrix edge1) {
	if (is_selfloop_boolean() == 0){
		edge = edge1
		_diag(edge, .)
	}
	else {
		edge = edge1
	}
	sparse_built = `False'
	edge_dense_built = `True'
}

/*
	Get a copy of the edge matrix
*/
real matrix `NWdef'::get_matrix_copy() {
//!! generate edge matrix based on edgetype
	real matrix e
	ensure_dense_built()
	e = edge

	if (isselfloop == 0){
		_diag(e,.)
		return(e)
	}
	else {
		return(edge)
	}
	return(edge)
}

/*
	Get a copy of the unvalued edge matrix
	and replace missings with zeros
*/
real matrix `NWdef'::get_matrix_unvalued_copy() {
//!! generate edge matrix based on edgetype
	real matrix e
	ensure_dense_built()
	e = (edge:!= 0 :& edge :!= .)
	return(e)
}


/*
	Get pointer to edge matrix
*/
pointer(real matrix) `NWdef'::get_matrix(){
	ensure_dense_built()
	return(&edge)
}

/*
	Get pointer to unvalued edge matrix
	and replace missings with zeros
*/
pointer(real matrix) `NWdef'::get_matrix_unvalued(){
	ensure_dense_built()
	if (is_valued()== "false"){
		return (&edge)
	}
	else {
		return(&((edge:!=0 :& edge:!=.) :+ ((edge:==.) :* edge)))
	}
}

/*
	Get pointer to modified edge matrix.

	For example:
		get_matrix(0,0) - returns unvalued and undirected matrix
		get_matrix(1,0) - returns valued and undirected matrix
		get_matrix(0,1) - returns unvalued and directed matrix
		get_matrix(1,1) - returns valued and directed matrix
	
	Note: Symmetrization uses option "max"
	
*/
pointer(real matrix) `NWdef'::get_matrix_mod(real scalar getvalued, real scalar getdirected){
	real matrix res1, res2, d

	ensure_dense_built()
	if (isvalued == getvalued & isdirect == getdirected){
		return (&edge)
	}
	else {
		if (getvalued == 0 & getdirected == 1){ 
			if (isvalued == 0) {
				return (&(edge))
			}
			else {
				return(&((edge:>0 :& edge:!=.) :+ ((edge:==.) :* edge)))
			}
		}
		if (getvalued == 1 & getdirected == 1){ 
			return(&(edge))
		}
		if (getvalued == 1 & getdirected == 0){ 
			if (isdirect == 0) {
				return (&(edge))
			}
			else {
				res2 = (edge')
				res2 = ((edge') :> edge):* res2
				res1 = edge
				res1 = (edge :>= (edge')):* res1
				return(&((res1 + res2) :+ ((edge:==.) :* edge)))
			}
		}
		if (getvalued == 0 & getdirected == 0 ) {
			if (isdirect == 0 & isvalued == 0) {
				return (&(edge))
			}
			else {
				res2 = (edge')
				res2 = ((edge') :> edge):* res2
				res1 = edge
				res1 = (edge :>= (edge')):* res1
				return(&(((res1 + res2):>0 :& (res1 + res2):!=.) :+ ((edge:==.) :* edge)))
			}
		}
	}
}




real matrix `NWdef'::calculate_dyadcensus(){
    real scalar asym
    real scalar mutual
    real scalar null

    asym = sum((*get_matrix_unvalued() - *get_matrix_unvalued()'):==1) + sum((*get_matrix_unvalued() - *get_matrix_unvalued()'):==-1)
    asym = asym / 2
    mutual = sum(*get_matrix_unvalued():* (*get_matrix_unvalued()')) / 2
    null = rows(*get_matrix_unvalued())
    // was "(null * (null - 1)) - asym - mutual" - n*(n-1) is the count
    // of ORDERED pairs, but a dyad is an UNORDERED pair (i,j)==(j,i)),
    // so the total dyad count is n*(n-1)/2, not n*(n-1) - the missing
    // /2 silently doubled every reported null-dyad count (confirmed via
    // 3 hand-computable networks: a fully-connected undirected triangle
    // reported null=3 instead of the correct 0; a 3-node directed
    // network with one mutual/one asym/one null dyad reported null=4
    // instead of 1; an empty 3-node network reported null=6 instead of
    // 3 - in every case exactly double the correct value, landing
    // entirely in null since mutual/asym are computed independently and
    // were already correct). reciprocity (mutual/(mutual+asym)) does not
    // depend on null, so this bug was invisible in that stored result -
    // only r(_001)/the displayed "Null" column were wrong.
    null = (null * (null - 1) / 2) - asym - mutual

    if (is_2mode_boolean() == 1) {
        null = get_nodes_mode1() * get_nodes_mode2() - asym - mutual
    }
    return((mutual, asym, null))
}

real matrix `NWdef'::calculate_triadcensus(){
	real matrix outdeg, indeg, deg, delta1, delta2, delta
	real scalar pot, transTrip, transitivity
	real scalar x_003,x_012,x_021D, x_021U, x_021C, x_030T, x_030C, x_102, x_120D, x_120U, x_120C, x_111D, x_111U, x_210, x_201, x_300
	real scalar t201, t021D, t021U, t111D, t111U
	real matrix M, C, E, Ecompl, diagonal
	
	E = abs(*get_matrix_unvalued()) + abs((*get_matrix_unvalued())')
	E = E :/ E
	_editmissing(E, 0)
	
	M = *get_matrix_unvalued() + *get_matrix_unvalued()'
	_editvalue(M, 1, 0)
	_editvalue(M, 2, 1)
	_editmissing(M, 0)
	
	C = *get_matrix_unvalued() - M
	_editmissing(C, 0)
	
	Ecompl = E
	_editvalue(Ecompl, 0, 10)
	_editvalue(Ecompl, 1, 0)
	_editvalue(Ecompl, 10, 1)
	diagonal = J(rows(Ecompl), 1, 0)
	
	_diag(Ecompl, diagonal)
	x_003 = sum(diagonal((Ecompl * Ecompl * Ecompl))) / 6
	x_012 = sum((Ecompl * Ecompl) :* (C + C')) / 2
	x_102 = sum((Ecompl * Ecompl) :* M) / 2
	x_021D = sum((C' * C) :* ( Ecompl :/ 2))
	x_021U = sum((C * C') :* ( Ecompl :/ 2))
	x_021C = sum((C * C) :* Ecompl)
	x_030T = sum((C * C) :* C)
	x_030C = sum(diagonal(C * C * C)) / 3
	x_201 = sum((M * M) :* (Ecompl :/ 2))
	x_120D = sum((C' * C) :* (M :/ 2))
	x_120U = sum((C * C') :* (M :/ 2))
	x_120C = sum((C * C) :* M)
	x_210 = sum((M * M) :* ((C + C') :/ 2))
	x_300 = sum(diagonal(M * M *M)) / 6
	t201 = (M * M) :* Ecompl
	t021D = (C' * C) :* Ecompl
	t021U = (C * C') :* Ecompl
	t111D = ((*get_matrix_unvalued() * *get_matrix_unvalued()') :* Ecompl) - t201 - t021U
	x_111D = sum(t111D) / 2
	t111U = ((*get_matrix_unvalued()' * *get_matrix_unvalued()) :* Ecompl) - t201 - t021D
	x_111U = sum(t111U) / 2
	
	return((x_003,x_012, x_021D, x_021U, x_021C, x_030T, x_030C, x_102, x_111D, x_111U, x_120D, x_120U, x_120C, x_210, x_201, x_300))

}

/*
	Update edge matrix given a list of nodes connecting to node i
*/
void `NWdef'::connect_edge(real scalar i, real rowvector rj) {
	edge[i, rj] = J(1, cols(rj), 1)
	if(!isdirect) {
		edge[rj', i] = J(cols(rj), 1, 1)
	}
	sparse_built = `False'
}

/*
	Add a node
*/
void `NWdef'::add_node(string scalar s) {
	real scalar idx, size
	idx = first_index_match(nodes, s)
	if(idx > 0) {
		error_handle("`vlNWdef': node name already exists.", 
			`errNodeDupName') 
	}
	size = cols(nodes)
	nodes = (nodes, s)
	nodesvar = (nodesvar, strtoname(s))
	edge = (edge, J(size, 1, 0)\J(1, size+1, 0))
	sparse_built = `False'
}

/*
	Cleanup of the network
*/
void `NWdef'::zap() {
	name = ""
	label = ""
	caption = ""
	nodes = J(0, 0, "")
	modes = J(0, 0, "")
	edge  = J(0, 0, 0)
	isdirect = `False'
	is2mode   = `False'
	sparse_built = `False'
}

/*
	Print out network information
*/
void `NWdef'::dumper(string scalar prefix) {
	real scalar i, j, size 
	string scalar s
	
	// name
	printf(prefix)
	printf("name: %s\n", name)
	
	// label
	printf(prefix)
	printf("label: %s\n", label)

	// isdirect
	if(isdirect) {
		s = "true"
	}
	else {
		s = "false"
	}
	printf(prefix)
	printf("direct: %s\n", s)

	size = cols(nodes)
	printf(prefix)
	printf("size: %g\n", size)
	
	// is2mode
	if(is2mode) {
		s = "true"
	}
	else {
		s = "false"
	}
	printf(prefix)
	printf("mode: %s\n", s)

	if(is2mode) {
		printf(prefix)
		printf("mode:")
		for(i=1; i<cols(modes); i++) {
			printf("%s; ", modes[i])  
		}
		if(cols(modes) != 0) {
			printf("%s", modes[cols(modes)])  		
		}
		printf("\n")
	}

	// nodes
	printf(prefix)
	printf("nodes:")
	for(i=1; i<size; i++) {
		printf("%g.%s; ", i, nodes[i])  
	}
	if(size != 0) {
		printf("%g.%s", size, nodes[size])  		
	}
	printf("\n")

	// edges
	printf(prefix)
	printf("edges:\n")
	
	for(i=1; i<=size; i++) {
		printf(prefix)
		printf("  %g.%s: ", i, nodes[i])
		for(j=1; j<=size; j++) {
			if(edge[i, j] != 0 & edge[i,j] != .) { 
				printf("%g.%s;", j, nodes[j])
			}
		}
		printf("\n")
	}
	printf("\n")
}
/* -------------------------------------------------------------------- */

/* -------------------------------------------------------------------- */
/* 
	Version 1 definition of networks
		names[i] is the name of the networks
		pdefs[i] points to network definition
*/
class `NWsdef' {
	string rowvector 				names
	pointer(class `NWdef' scalar) rowvector 	pdefs
	real scalar number  // number of networks in memory
	pointer(class `NWdef' scalar) scalar pcurrent
    `BOOL' datasync // flag for -nw_datasync- on/off
    
	
//!! methods:
	void zap()
	void create()	
	void create_by_name()
	void add()
	void add_existing()
	real append()
	void dumper()
	void update_number()
	void delete_index()
	void delete_name()
	void rename()
	real scalar get_number()
	real scalar get_index_of() 	// return the index of a network with a name
	string scalar get_names()
	void make_current()
	void make_current_from_name()
	
	real scalar get_index_of_current()
	string scalar get_current_name()
	real scalar get_max_nodes()
	string scalar get_valid_name()
	void drop_current_nodesvar()
	void generate_current_nodesvar()
	void duplicate()
	void drop()
	
	void set_datasync()
	real get_datasync()
	
	//void preserve()
}


void `NWsdef'::set_datasync(real onoff){
	datasync = onoff
}

real `NWsdef'::get_datasync(){
    if (datasync == .){
        set_datasync(1)
    }
    return(datasync)
}

void `NWsdef'::drop_current_nodesvar(){
	real scalar i
	for (i = 1; i<= cols(pcurrent->nodesvar); i++){
		stata("capture drop " + pcurrent->nodesvar[i])
	}
}

void `NWsdef'::generate_current_nodesvar(){
	real scalar i

	for (i = 1; i<= cols(pcurrent->nodesvar); i++){
		stata("capture gen " + pcurrent->nodesvar[i] + " = .")
	}
}

void `NWsdef'::zap(){
	real scalar n
	n = cols(names)
	names = J(0, 0, "")
	pdefs = NULL
	number = 0
}

string scalar `NWsdef'::get_valid_name(string scalar s){
	real scalar i, suffix
	string scalar snew

	if (rows(names) == 0) {
		return(s)
	}
	
	snew = s
	suffix = 1
	i = first_index_match(names, s)
	
	if (i != 0) {
		snew = s + "_" + strofreal(suffix)
		while (first_index_match(names, snew)!= 0) {
			suffix = suffix + 1
			snew = s + "_" + strofreal(suffix)
		}
	}
	return(snew)
}

/*
	Get number of largest network
*/
real scalar `NWsdef'::get_max_nodes(){
	real scalar n, m, i
	
	n = 0
	for (i = 1; i<= 1; i++){
		n = max((n,pdefs[i]->get_nodes()))
	}
	return(n)
}

/*
	Get index of current network
*/
real scalar `NWsdef'::get_index_of_current(){
	string scalar s

	s = pcurrent->get_name()
	return(first_index_match(names, s))
}

/*
	Get name of current network
*/
string scalar `NWsdef'::get_current_name(){

	if (strpos(get_names(),pcurrent->get_name()) == 0) {
		make_current_from_name(tokens(get_names())[1])
		//make_current_from_name(ustrword(get_names(),1))
	}
	return(pcurrent->get_name())
}

/*
	Make current network from index i
*/
void `NWsdef'::make_current(real scalar i){
	pcurrent = pdefs[i]
}

/*
	Make current network from name s
*/
void `NWsdef'::make_current_from_name(string scalar s){
	real scalar i 
	
	i = first_index_match(names, s)
	make_current(i)
}

/*
	Get string with list of all networks
*/
string scalar `NWsdef'::get_names(){
	real scalar i
	string scalar s

	for(i = 1; i<=get_number(); i++){
		s = s + " " + names[i]
	}
	return(s)
}

/* 
	Rename network oldname and call it newname
*/
void `NWsdef'::rename(string scalar oldname, string scalar newname){
	real scalar i

	i = first_index_match(names, oldname)

	if(i==0) {
		error_handle("Network name " + oldname + " does not exist. " , `errNWsNotFound')
	}
	names[i] = newname
	pdefs[i]->set_name(newname)
}

/*
	Delete network with index i
*/
void `NWsdef'::delete_index(real scalar i){
	real scalar size
	real matrix k
	
	size = cols(names)
	if(i == 0 | i > size) {	
		error_handle("`NWsdef':network not found", `errNWsNotFound')
	}
	
	k = J(1,size,1)
	k[i] = 0
	pdefs = select(pdefs, k)
	names = select(names, k)
	number = number - 1
}

/*
	Delete network with name s
*/
void `NWsdef'::delete_name(real scalar s){
	delete_index(first_index_match(names,s))
}


/* 
	Get index of a network with a particular name s
*/
real scalar `NWsdef'::get_index_of(string scalar s){
	return(first_index_match(names, s))
}

/*
	Update number of networks
*/
void `NWsdef'::update_number() {
	number = cols(pdefs)
}

/*
	Get number of networks
*/
real scalar `NWsdef'::get_number() {
	return(cols(names))
}

/*
	Create n networks 
*/
void `NWsdef'::create(real scalar n) {
	real scalar i 
	
//!! do we want an upper limit ??
	if(n <= 0) {	
		error_handle("`NWsdef':the number of networks must be positive", `errNWsCrete')
	}
	
	names =  "`cDftNWpef'" :+ strofreal((1..n))
	pdefs = J(1, n, NULL)
	for(i=1; i<=n; i++) {
		pdefs[i] = &(`NWdef'())
		pdefs[i]->set_name(names[i])
	}
	if (_st_varindex("`nw_nodename'") == .) {
		st_addvar("str40","`nw_nodename'")
	}
}

/*
	Create networks by name
*/
void `NWsdef'::create_by_name(string rowvector s) {
	real scalar n, i, v

	n = cols(s)
//!! do we need an upper limit ??
	if(n <= 0) {	
		error_handle("`NWsdef':the number of networks must be positive", `errNWsCreate')
	}	

	names = s	
	pdefs = J(1, n, NULL)
	for(i=1; i<=n; i++) {
		pdefs[i] = &(`NWdef'())
		pdefs[i]->set_name(names[i])
	}
	if (_st_varindex("`nw_nodename'") == .) {
		v= st_addvar("str40","`nw_nodename'")
	}
}

/*
	Add one network
*/


real `NWsdef'::append(pointer(class `NWs') scalar newnws){
	string matrix s
	real scalar c1, c2

	s = (this.names'\ ((*newnws).nws.names)')
	c1 = cols(this.pdefs)
	c2 = cols((*newnws).nws.number)
	
	if (rows(uniqrows(s)) == c1 + c2){
		pdefs = (pdefs, (*newnws).nws.pdefs)
		names = (names, (*newnws).nws.names)
		number = cols(pdefs)
		return(1)
	}
	else {
		return(0)
	}
}

void `NWsdef'::add_existing(pointer(class `NWdef' scalar) scalar nw){
	real scalar size
	
	add((*nw).get_name())
	size = cols(pdefs)
	pdefs[size] = nw
}


void `NWsdef'::add(string scalar s) {

	real scalar i, size
	if (rows(names) > 0){
		i = first_index_match(names, s)
	}
	else {
		i = 0
		names = s
	}
	if(i>0) {
		error_handle("Network name already exists" , `errNWsExists')
	}

	if (rows(names) > 0){
		names = (names, s)
	}
	else {
		names = s
	}

	pdefs = (pdefs, NULL)
	size = cols(pdefs)
	pdefs[size] = &(`NWdef'())
	pdefs[size]->set_name(names[size])
	pcurrent = pdefs[size]
}

/*
	Drop a network
*/
void `NWsdef'::drop(string scalar netname){
	real scalar i, size
	real matrix k
	
	i = first_index_match(names, netname)
	size = cols(names)
	
	if (i <= size) {
		k = J(1, size, 1)
		k[1,i] = 0
		names = select(names, k)
		pdefs = select(pdefs, k)
	}
}
	
/* 
	Add a duplicate of a network
*/

void `NWsdef'::duplicate(string scalar netname, string scalar new_netname){
	real scalar i, size
	
	names = (names, new_netname)
	i = first_index_match(names, netname)
	pdefs = (pdefs, NULL)
	size = cols(pdefs)
	pdefs[size] = &(`NWdef'())
	pdefs[size]->set_name(new_netname)
	pdefs[size]->set_edge(pdefs[i]->get_matrix_copy())
	pdefs[size]->set_nodenames(pdefs[i]->get_nodenames())
	
	if (pdefs[i]->is_2mode_boolean()){
		pdefs[size]->set_modes(pdefs[i]->get_modes())
	}
	
	pdefs[size]->set_nodesvar(pdefs[i]->get_nodesvar())
	pdefs[size]->set_selfloop(pdefs[i]->is_selfloop_boolean())
	pdefs[size]->set_directed(pdefs[i]->is_directed_boolean())
	pdefs[size]->set_valued(pdefs[i]->is_valued_boolean())
	pdefs[size]->set_2mode(pdefs[i]->is_2mode_boolean())

	pdefs[size]->set_label(pdefs[i]->get_label())
	pdefs[size]->set_caption(pdefs[i]->get_caption())
	make_current(size)

}

/*
	Print out network information 
*/
void `NWsdef'::dumper() {
	real scalar i 
	for(i=1; i<=cols(names); i++) {
		printf("Network %s:\n", names[i])
		pdefs[i]->dumper("	")
	}
}

/* -------------------------------------------------------------------- */
/* 
	Version 1 definition of derived-across-network datasig
*/
class `NWsder' {
	string scalar datasig		// used by -nw_datasync-
//!! methods:
}

/* -------------------------------------------------------------------- */
/* 
	Version 1 interface routines for interactive session
*/
class `NWs' scalar nws_create()
{
	class `NWs'  scalar a 
	
	return(a)
}
end
