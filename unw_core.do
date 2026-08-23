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
	Build an n x n real matrix of per-edge values (time/start/end),
	missing (.) everywhere else, by resolving each row's own node
	LABELS to indices - not position - exactly the same reasoning as
	modes_from_labels() above (see nw2fromedge.ado's own comment): the
	underlying network's node order is not something a caller can
	assume matches the original data's row order. Shared by nwset's
	time()/interval() options - interval calls this twice (once for the
	start values, once for the end values) rather than needing a
	separate implementation.
*/
real matrix build_edge_value_matrix(string rowvector nodenames, string colvector lab1, string colvector lab2, real colvector tval, real scalar symmetric)
{
	real scalar n, k, i, j
	real matrix m
	n = cols(nodenames)
	m = J(n, n, .)
	for (k=1; k<=rows(lab1); k++){
		i = first_index_match(nodenames, lab1[k])
		j = first_index_match(nodenames, lab2[k])
		if (i > 0 & j > 0) {
			m[i,j] = tval[k]
			if (symmetric) m[j,i] = tval[k]
		}
	}
	return(m)
}

/*
	Build an nevents x 3 (sender_id, receiver_id, eventtime) matrix by
	resolving each row's node LABELS to indices - the eventtime
	temporal-type counterpart to build_edge_value_matrix() above, kept
	separate rather than reusing it since events are never folded into
	an n x n edge-shaped matrix at all (see NWdef's own `eventlist'
	field comment).
*/
real matrix build_eventlist(string rowvector nodenames, string colvector lab1, string colvector lab2, real colvector tval)
{
	real scalar nevents, k
	real matrix ev
	nevents = rows(lab1)
	ev = J(nevents, 3, .)
	for (k=1; k<=nevents; k++){
		ev[k,1] = first_index_match(nodenames, lab1[k])
		ev[k,2] = first_index_match(nodenames, lab2[k])
		ev[k,3] = tval[k]
	}
	return(ev)
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
	Label propagation community detection (Raghavan, Albert & Kumar 2007):
	each node starts in its own singleton community; repeatedly, each node
	adopts whichever community its neighbors' total edge weight favors most
	(nw_community_kin(), the same helper Louvain's own greedy search above
	uses) - no modularity optimization at all, just local majority-label
	voting, which is what makes this dramatically cheaper than Louvain for
	very large networks at the cost of less consistent partition quality.

	Both the sweep order AND tie-breaking among equally-favored candidate
	communities are genuinely RANDOMIZED (via unorder() and runiform()),
	matching the textbook algorithm - NOT fixed/deterministic the way
	Louvain's own sweep order above is. This is a deliberate departure
	from this session's usual reproducibility-over-textbook-fidelity
	default, made only after empirically confirming the fixed/
	lowest-index-tiebreak version is not just "less standard" but
	actively WRONG on the simplest possible test case: two triangles
	joined by a single bridge edge collapsed into one giant community
	instead of splitting at the bridge, because a fixed visiting order
	combined with "prefer the lowest-indexed tied community" creates a
	systematic bias - whichever community happens to be checked first in
	a tie keeps absorbing neighbors, cascading into a single dominant
	community. True label propagation's randomization exists specifically
	to prevent this failure mode, not merely to match a textbook - so
	unlike Louvain (whose modularity-GAIN-driven search has no comparable
	directional bias to guard against), reproducibility here is exposed
	via nwcommunity's own seed() option (`set seed` before calling this),
	not attempted via determinism inside the algorithm itself.

	An isolate node (no ties at all) has nothing to vote on and simply
	keeps its own singleton label. Converges when a full sweep makes zero
	moves, capped at 100 sweeps (matching Louvain's own cap) against
	pathological oscillation - label propagation is not proven to always
	converge quickly, unlike Louvain's own modularity-monotonic guarantee.
*/
real matrix LabelPropagation(real matrix W){
	real matrix comm, idx, neighbor_comms, order, weights, winners
	real scalar n, i, ii, c_old, best_w, moved, sweep, a, nwin, pick

	n = rows(W)
	if (n <= 1){
		return((1::n))
	}

	comm = (1::n)
	moved = 1
	sweep = 0
	while (moved == 1 & sweep < 100){
		moved = 0
		sweep = sweep + 1
		order = unorder(n)
		for (ii = 1; ii <= n; ii++){
			i = order[ii]
			idx = selectindex(W[i,.] :!= 0)
			if (cols(idx) == 0){
				continue
			}
			neighbor_comms = uniqrows(comm[idx',1])

			c_old = comm[i,1]
			weights = J(rows(neighbor_comms), 1, .)
			for (a = 1; a <= rows(neighbor_comms); a++){
				weights[a,1] = nw_community_kin(W, i, comm, neighbor_comms[a,1])
			}
			best_w = max(weights)
			winners = select(neighbor_comms, weights :== best_w)
			nwin = rows(winners)
			pick = winners[ceil(runiform(1,1) * nwin), 1]

			comm[i,1] = pick
			if (pick != c_old){
				moved = 1
			}
		}
	}
	return(nw_community_denserelabel(comm))
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
	real matrix mask, idx, core, deg, periph
	real scalar n, sweep, moved, i, m
	real scalar sumA, sumAA, varA, sumP, sumAP, c_old, dirn, nP, wsum
	real scalar sumP1, sumAP1, fit0, fit1, varP0, varP1

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

	// PERFORMANCE FIX (this unit): the search below is a greedy local
	// search over n(*maxiter) candidate single-node flips, and every
	// candidate used to be scored by calling nw_cp_fitness() TWICE
	// (before and after the flip) - each call an O(n^2) full
	// recomputation of the fitness correlation over the *entire*
	// dyad set. That is O(n^2) work per candidate, O(n) candidates per
	// sweep, so O(n^3) per sweep - the confirmed root cause of 255
	// seconds at n=1,000 (docs/PERFORMANCE_BENCHMARKS.md, harmonisation
	// unit 103). Flipping a single node i's core status only changes
	// the "expected pattern" (core[a]+core[b])>0 at the 2(n-1)
	// off-diagonal dyads touching i - and, since a periphery-periphery
	// dyad is the only kind whose expected value depends on BOTH
	// endpoints being periphery, the set of dyads that actually change
	// value on the flip is exactly the dyads between i and every OTHER
	// periphery node - so the whole correlation's sufficient statistics
	// (sums needed for Pearson's r) can be updated in O(n) instead of
	// recomputed in O(n^2). avec (the observed network) never changes
	// during this search, so sumA/sumAA/varA are computed once, up
	// front, outside the loop entirely.
	m = n * (n-1)
	sumA = sum(net)
	sumAA = sum(net:^2)
	varA = m*sumAA - sumA^2

	// One O(n^2) pass to seed sumP/sumAP for the initial core vector -
	// paid once, not per candidate.
	{
		real matrix pattern0
		pattern0 = ((core * J(1,n,1)) :+ (J(n,1,1) * core')) :> 0
		_diag(pattern0, 0)
		sumP = sum(pattern0)
		sumAP = sum(net :* pattern0)
	}

	sweep = 0
	moved = 1
	while (moved & sweep < maxiter){
		moved = 0
		sweep++
		for (i=1; i<=n; i++){
			// pattern is binary (0/1) throughout, so sum(pattern^2) ==
			// sum(pattern) identically - var(P) reduces to sumP*(m-sumP)
			// (a Bernoulli-sum variance), no separate sumPP needed.
			// BUGFIX (caught during this unit's own cross-validation
			// against the pre-fix algorithm, not introduced by it): a
			// zero-variance dyad pattern (e.g. all-periphery or all-
			// core) makes Mata's correlation() return missing (.), and
			// Mata's missing sorts as GREATER than any real number
			// (confirmed directly: ". > 5" is true) - so the pre-fix
			// nw_cp_fitness()-based search actually treats a degenerate
			// fitness as unconditionally "better" than any real one,
			// greedily falling into (and, once there, permanently
			// stuck in, since nothing can then compare greater than
			// missing) a degenerate all-periphery/all-core state
			// whenever the search happens to reach one - not the
			// intended behavior, presumably, but the actual shipped
			// one. An initial version of this rewrite used a "treat
			// zero variance as fitness 0" fallback instead, which is
			// more sensible in isolation but silently changes which
			// local optimum the search converges to - caught by a
			// deterministic 300-network cross-check against the actual
			// pre-fix algorithm (preserved from git history), not by
			// any theoretical review. Fixed by using an explicit
			// missing value in the same zero-variance case, letting
			// Mata's own `>' operator reproduce the exact same quirk.
			varP0 = sumP*(m-sumP)
			fit0 = (varP0 <= 0 | varA <= 0) ? . : (m*sumAP - sumA*sumP) / sqrt(varA*varP0)

			c_old = core[i,1]
			periph = (core :== 0)
			periph[i,1] = 0
			nP = sum(periph)
			wsum = sum(periph :* (net[i,.]' :+ net[.,i]))
			dirn = (c_old == 1 ? -1 : 1)
			sumP1 = sumP + dirn*2*nP
			sumAP1 = sumAP + dirn*wsum
			varP1 = sumP1*(m-sumP1)
			fit1 = (varP1 <= 0 | varA <= 0) ? . : (m*sumAP1 - sumA*sumP1) / sqrt(varA*varP1)

			if (fit1 > fit0 + 1e-12){
				core[i,1] = 1 - c_old
				sumP = sumP1
				sumAP = sumAP1
				moved = 1
			}
		}
	}

	// Final reported fitness computed via one exact, full O(n^2)
	// recomputation (negligible cost paid once) rather than trusting
	// the incrementally-tracked sumP/sumAP - avoids any concern about
	// accumulated floating-point drift over many incremental updates.
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
	real rowvector Nv, newR, PX, Nu, branch
	real scalar n, v, u, best, cnt

	n = cols(P)
	results = J(0, n, 0)

	if (sum(P) == 0 & sum(X) == 0){
		return(R)
	}

	// PERFORMANCE FIX (this unit): added standard Bron-Kerbosch pivoting
	// (Tomita, Tanaka & Takahashi 2006), replacing the plain unpivoted
	// version this function's own header comment previously defended as
	// sufficient for "this package's own target network scale." That
	// assumption no longer holds now the package targets n=10,000:
	// confirmed directly that the unpivoted version's SEARCH TREE, not
	// its actual output, was the problem - a 10,000-node/avg-degree-10
	// random graph has only ~170 maximal cliques (same order of
	// magnitude as at n=1,000-2,000, confirmed empirically), yet the
	// unpivoted search took 28GB+ of RAM and was killed before
	// completing, while n=2,000 alone already took 13 seconds for the
	// same ~170-clique output - a search-tree blow-up, not a
	// combinatorial-output blow-up like nwkplex's genuinely inherent
	// k>=2 case. Pivoting fixes exactly this: pick any u in P union X
	// maximizing |P intersect N(u)|, then only branch on P \ N(u)
	// instead of all of P - every vertex adjacent to u is guaranteed to
	// be covered by some other branch (through u itself or through one
	// of u's own P-neighbors explored elsewhere), so skipping it here
	// cannot drop any maximal clique. This is a well-established,
	// textbook correctness-preserving optimization - it changes how
	// many redundant branches are explored, never which final maximal
	// cliques are found - verified directly regardless, by cross-
	// checking the exact SET of returned cliques (not just the count)
	// against the pre-fix unpivoted algorithm on many small/medium
	// graphs where the unpivoted version still completes quickly.
	PX = P :| X
	best = -1
	u = 0
	for (v = 1; v <= n; v++){
		if (PX[v] == 0) continue
		cnt = sum(P :& adj[v,.])
		if (cnt > best){
			best = cnt
			u = v
		}
	}
	Nu = adj[u,.]
	branch = P :& (1 :- Nu)

	for (v = 1; v <= n; v++){
		if (branch[v] == 0) continue
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
	real scalar N, u, v, qhead, qtail, k, nc
	real rowvector visited, queue, residual, candidates

	N = rows(cap)
	visited = J(1,N,0)
	parent = J(1,N,0)
	queue = J(1,N,0)
	qhead = 1
	qtail = 1
	queue[1] = s
	visited[s] = 1

	// BUGFIX: used to scan every one of the N columns one at a time
	// via an interpreted for(v=1..N) loop for EACH dequeued node - a
	// dense O(N) row scan regardless of how sparse the residual graph
	// actually is, and BFS can dequeue up to N nodes, so O(N^2) per
	// call. Replaced with a single vectorized row-extraction +
	// selectindex() per dequeued node - same result (which candidates
	// qualify doesn't change), computed as one fast vectorized
	// operation instead of N interpreted ones. The early-return-the-
	// instant-t-is-found optimization the old per-cell loop had is
	// replaced by an equivalent check once per dequeued node instead
	// of once per candidate edge - still correct (some already-queued
	// nodes may go unprocessed once t is found, exactly as before;
	// which shortest augmenting path Edmonds-Karp happens to use
	// doesn't affect max-flow correctness, only which path is picked
	// when several of the same shortest length exist).
	while (qhead <= qtail) {
		u = queue[qhead]
		qhead++
		residual = cap[u,.] - flow[u,.]
		candidates = selectindex((residual :> 0) :& (visited :== 0))
		nc = cols(candidates)
		for (k=1; k<=nc; k++) {
			v = candidates[k]
			visited[v] = 1
			parent[v] = u
			qtail++
			queue[qtail] = v
		}
		if (visited[t] == 1) return(1)
	}
	return(0)
}

/*
	Sparse vertex-split max-flow infrastructure (harmonisation unit
	108, docs/CERTIFICATION.md; user directive: "optimize... for 10k
	nodes... feel free to use C plugins or other libraries if needed").
	build_vertexsplit_basecap()/maxflow_vertex_split_shared() above
	already cut fast_min_cut_search()'s CALL COUNT from O(n^2) to
	O(delta^2) (unit 102), but each of those O(delta^2) calls still
	does O(n^2) work internally against a dense (2n)x(2n) matrix -
	confirmed as the remaining reason nwkcomponents/nwcohesion still
	do not complete at n=10,000 (28GB+/9.5GB+ RAM observed directly,
	killed before finishing). This block represents the SAME vertex-
	split graph as an explicit directed edge list instead - the
	standard adjacency-list max-flow representation (parallel arrays
	edgeTo/edgeCap, each edge's own reverse-edge index in edgeRev, and
	a linked-list-style adjacency via headEdge[v]/nextEdge[e] - Mata
	has no native array-of-lists type, so this is the usual
	competitive-programming workaround) - built ONCE per
	fast_min_cut_search()/min_vertex_cutset() call (an unavoidable
	O(n^2) scan of the dense `adj' input itself, done via a single
	vectorized selectindex() over the flattened matrix rather than an
	interpreted double loop, so it is memory-bound, not interpreter-
	loop-bound) and shared across all of that call's own O(delta^2)
	queries via pointers - only the flow array (not the topology) is
	reset between queries, and only the current query's own s/t
	internal-edge capacities are temporarily bumped to `bignum' and
	restored after, mirroring maxflow_vertex_split_shared()'s own
	"mutate 2 cells, restore" discipline exactly. Each individual
	max-flow query then costs O(kappa*(n+m)) instead of O(n^2) (kappa,
	the flow value actually found, is bounded by the minimum degree
	delta for every query fast_min_cut_search() makes - see its own
	header comment - so this is a genuine asymptotic win for sparse
	graphs, not just a constant-factor one).

	Node numbering matches build_vertexsplit_basecap() exactly: 1..n
	are "in" nodes, n+1..2n are "out" nodes. Internal edges (v_in ->
	v_out) are built first, in node order, so internal edge v's own
	forward-arc index is always exactly 2*v-1 (its reverse arc index
	2*v) - used by maxflow_sparse_query() to find and patch the
	current query's own s/t capacities directly, without a search.
*/
void build_vertexsplit_sparse(real matrix adj, real scalar bignum,
		pointer(real colvector) scalar edgeToP,
		pointer(real colvector) scalar edgeCapP,
		pointer(real colvector) scalar edgeRevP,
		pointer(real colvector) scalar headEdgeP,
		pointer(real colvector) scalar nextEdgeP){
	real scalar n, N, m, e, u
	real matrix tempadj
	real colvector nzidx, urow, vcol
	real colvector edgeTo, edgeCap, edgeRev, headEdge, nextEdge

	n = rows(adj)
	N = 2 * n
	tempadj = adj
	_diag(tempadj, 0)

	// Vectorized structural-edge extraction: vec() flattens column-
	// major, so a nonzero at flattened index i corresponds to row
	// r=mod(i-1,n)+1, col c=floor((i-1)/n)+1 - i.e. edge (u=r, w=c).
	nzidx = selectindex(vec(tempadj) :!= 0)
	m = rows(nzidx)
	if (m > 0) {
		urow = mod(nzidx :- 1, n) :+ 1
		vcol = floor((nzidx :- 1) :/ n) :+ 1
	}
	else {
		urow = J(0,1,0)
		vcol = J(0,1,0)
	}

	edgeTo = J(2*(n+m), 1, 0)
	edgeCap = J(2*(n+m), 1, 0)
	edgeRev = J(2*(n+m), 1, 0)
	headEdge = J(N, 1, 0)
	nextEdge = J(2*(n+m), 1, 0)

	e = 0
	for (u=1; u<=n; u++) {
		e++
		edgeTo[e] = n+u
		edgeCap[e] = 1
		edgeRev[e] = e+1
		nextEdge[e] = headEdge[u]
		headEdge[u] = e

		e++
		edgeTo[e] = u
		edgeCap[e] = 0
		edgeRev[e] = e-1
		nextEdge[e] = headEdge[n+u]
		headEdge[n+u] = e
	}

	for (u=1; u<=m; u++) {
		e++
		edgeTo[e] = vcol[u]
		edgeCap[e] = bignum
		edgeRev[e] = e+1
		nextEdge[e] = headEdge[n+urow[u]]
		headEdge[n+urow[u]] = e

		e++
		edgeTo[e] = n+urow[u]
		edgeCap[e] = 0
		edgeRev[e] = e-1
		nextEdge[e] = headEdge[vcol[u]]
		headEdge[vcol[u]] = e
	}

	(*edgeToP) = edgeTo
	(*edgeCapP) = edgeCap
	(*edgeRevP) = edgeRev
	(*headEdgeP) = headEdge
	(*nextEdgeP) = nextEdge
}

/*
	bfs_augment_sparse: the same Edmonds-Karp BFS augmenting step as
	bfs_augment() above, but walking the edge-list/linked-adjacency
	representation build_vertexsplit_sparse() builds instead of a
	dense capacity matrix - so a node's neighbors are enumerated by
	following its own headEdge/nextEdge chain (degree-proportional
	work) rather than scanning an entire length-N row. `parentEdgeP'
	receives, per visited node, the EDGE INDEX BFS reached it through
	(not the predecessor node directly - the edge index is what
	maxflow_sparse_query() needs to read residual capacity and, via
	edgeRev, find the reverse edge to augment).
*/
real scalar bfs_augment_sparse(real colvector edgeTo, real colvector edgeCap, real colvector flow,
		real colvector headEdge, real colvector nextEdge,
		real scalar N, real scalar s, real scalar t,
		pointer(real colvector) scalar parentEdgeP){
	real colvector visited, queue, parentEdge
	real scalar qhead, qtail, u, e, v

	visited = J(N,1,0)
	queue = J(N,1,0)
	parentEdge = J(N,1,0)
	qhead = 1
	qtail = 1
	queue[1] = s
	visited[s] = 1

	while (qhead <= qtail) {
		u = queue[qhead]
		qhead++
		e = headEdge[u]
		while (e != 0) {
			if ((edgeCap[e] - flow[e]) > 0) {
				v = edgeTo[e]
				if (visited[v] == 0) {
					visited[v] = 1
					parentEdge[v] = e
					if (v == t) {
						(*parentEdgeP) = parentEdge
						return(1)
					}
					qtail++
					queue[qtail] = v
				}
			}
			e = nextEdge[e]
		}
	}
	(*parentEdgeP) = parentEdge
	return(0)
}

/*
	maxflow_sparse_query: the sparse-edge-list analogue of
	maxflow_vertex_split_shared() - identical contract (shared base
	topology via pointers, patches exactly the current query's own s/t
	internal-edge capacities to `bignum' and restores them to 1
	afterward, resets only the flow array between queries), computing
	the same vertex-split max-flow value via the same Edmonds-Karp
	augmenting-path loop, just walking edge lists instead of matrix
	rows/columns.
*/
real scalar maxflow_sparse_query(pointer(real colvector) scalar edgeToP,
		pointer(real colvector) scalar edgeCapP,
		pointer(real colvector) scalar edgeRevP,
		pointer(real colvector) scalar headEdgeP,
		pointer(real colvector) scalar nextEdgeP,
		real scalar n, real scalar bignum, real scalar s, real scalar t){
	real scalar N, maxf, pathflow, pf, v, e, erev
	real colvector flow, parentEdge

	N = 2*n
	(*edgeCapP)[2*s-1] = bignum
	(*edgeCapP)[2*t-1] = bignum

	flow = J(rows(*edgeToP), 1, 0)
	maxf = 0
	while (bfs_augment_sparse(*edgeToP, *edgeCapP, flow, *headEdgeP, *nextEdgeP, N, n+s, t, &parentEdge)) {
		pathflow = bignum
		v = t
		while (v != n+s) {
			e = parentEdge[v]
			pf = (*edgeCapP)[e] - flow[e]
			if (pf < pathflow) pathflow = pf
			v = (*edgeToP)[(*edgeRevP)[e]]
		}
		v = t
		while (v != n+s) {
			e = parentEdge[v]
			erev = (*edgeRevP)[e]
			flow[e] = flow[e] + pathflow
			flow[erev] = flow[erev] - pathflow
			v = (*edgeToP)[erev]
		}
		maxf = maxf + pathflow
	}

	(*edgeCapP)[2*s-1] = 1
	(*edgeCapP)[2*t-1] = 1
	return(maxf)
}

/*
	build_vertexsplit_sparse_edges: identical construction to
	build_vertexsplit_sparse() above, but taking an already-sparse
	symmetric edge list (eu, ev - each undirected tie listed once in
	each direction, the same convention edgelist() uses elsewhere in
	this file) directly, instead of scanning a dense adjacency matrix
	to discover one. Exists so KComponentsEdges() below (its own header
	comment explains why) never has to touch a dense n-by-n matrix at
	all, at any recursion level - not even the single vectorized
	vec()/selectindex() scan build_vertexsplit_sparse() still needs.
*/
void build_vertexsplit_sparse_edges(real scalar n, real colvector eu, real colvector ev, real scalar bignum,
		pointer(real colvector) scalar edgeToP,
		pointer(real colvector) scalar edgeCapP,
		pointer(real colvector) scalar edgeRevP,
		pointer(real colvector) scalar headEdgeP,
		pointer(real colvector) scalar nextEdgeP){
	real scalar N, m, e, u
	real colvector edgeTo, edgeCap, edgeRev, headEdge, nextEdge

	N = 2 * n
	m = rows(eu)

	edgeTo = J(2*(n+m), 1, 0)
	edgeCap = J(2*(n+m), 1, 0)
	edgeRev = J(2*(n+m), 1, 0)
	headEdge = J(N, 1, 0)
	nextEdge = J(2*(n+m), 1, 0)

	e = 0
	for (u=1; u<=n; u++) {
		e++
		edgeTo[e] = n+u
		edgeCap[e] = 1
		edgeRev[e] = e+1
		nextEdge[e] = headEdge[u]
		headEdge[u] = e

		e++
		edgeTo[e] = u
		edgeCap[e] = 0
		edgeRev[e] = e-1
		nextEdge[e] = headEdge[n+u]
		headEdge[n+u] = e
	}

	for (u=1; u<=m; u++) {
		e++
		edgeTo[e] = ev[u]
		edgeCap[e] = bignum
		edgeRev[e] = e+1
		nextEdge[e] = headEdge[n+eu[u]]
		headEdge[n+eu[u]] = e

		e++
		edgeTo[e] = n+eu[u]
		edgeCap[e] = 0
		edgeRev[e] = e-1
		nextEdge[e] = headEdge[ev[u]]
		headEdge[ev[u]] = e
	}

	(*edgeToP) = edgeTo
	(*edgeCapP) = edgeCap
	(*edgeRevP) = edgeRev
	(*headEdgeP) = headEdge
	(*nextEdgeP) = nextEdge
}

/*
	fast_min_cut_search_edges: the edge-list-native equivalent of
	fast_min_cut_search() above - identical Esfahanian & Hakimi (1984)
	driver logic (see that function's own header comment for the full
	algorithm explanation), but adjacency checks ("is v0 tied to i?",
	"are two of v0's own neighbors tied to each other?") go through a
	CSR (rowptr/colidx) built once from the edge list, or a boolean
	marker array over v0's own neighbor set, instead of dense matrix
	cell lookups - so this function never touches an n-by-n structure
	anywhere, at any point. Exists for KComponentsEdges() below: a
	subgraph whose vertex connectivity is being checked at recursion
	depth d only needs O(edges in that subgraph) work here, not
	O(n_d^2), which matters because a graph needing many sequential
	small cuts before its "remaining" portion stabilizes pays this
	function's own cost once per cut - confirmed directly (see
	KComponentsEdges()'s own header comment) that this repeated
	near-full-size O(n^2) cost, not the max-flow work itself, was the
	dominant remaining reason a benchmark network took 79.9 seconds at
	n=5,000 even after this same unit's sparse max-flow fix.
*/
real rowvector fast_min_cut_search_edges(real scalar n, real colvector eu, real colvector ev, | real scalar target){
	real scalar m, i, j, v0, delta, f, minflow, best_s, best_t, bignum, e, has_target
	real colvector deg, rowptr, colidx, cursor
	real rowvector neighbors_v0, isNbrJ
	pointer(real colvector) scalar edgeToP, edgeCapP, edgeRevP, headEdgeP, nextEdgeP
	real colvector edgeTo, edgeCap, edgeRev, headEdge, nextEdge

	// BUGFIX (this unit): step (2) below - "v0 to every vertex it is
	// NOT adjacent to" - is genuinely O(n-1-delta) queries, not O(delta)
	// as this function's own header comment (inherited unmodified from
	// harmonisation unit 102) claims. That claim was never actually
	// wrong for the *specific* benchmark graphs unit 102 tested (delta
	// happened to be close to n there), but is wrong in general: a
	// vertex of degree 1 has essentially n-2 non-neighbors, all of
	// which get queried. Confirmed as the real remaining bottleneck
	// behind KComponentsEdges() taking 70+ seconds per recursion level
	// on a benchmark network with a near-isolated minimum-degree node -
	// direct per-call instrumentation showed ~5,000 max-flow queries in
	// a single fast_min_cut_search_edges() call, not the expected O(1)
	// handful. KComponentsEdges() (its only caller that matters for
	// this fix) only ever needs to know whether connectivity is below
	// its OWN fixed target k - not the exact global minimum - and only
	// needs SOME (s,t) pair achieving a cut below k, not the smallest
	// one. `target', when supplied, lets the search stop the instant
	// any query returns a flow strictly less than it: correctness for
	// KComponentsEdges()'s own purposes is unaffected (any cut < k
	// proves conn < k and gives it a valid cutset to remove), while
	// vertex_connectivity()/every other existing caller keeps getting
	// the exact global minimum by simply not passing `target' at all.
	has_target = (args() == 4)
	m = rows(eu)
	deg = J(n,1,0)
	for (e=1; e<=m; e++) deg[eu[e]] = deg[eu[e]] + 1

	delta = min(deg)
	v0 = 1
	for (i=1; i<=n; i++) {
		if (deg[i] == delta) {
			v0 = i
			i = n + 1
		}
	}

	minflow = delta
	best_s = 0
	best_t = 0

	// CSR of the local subgraph, built once, O(n+m) - used only for
	// adjacency checks below, never for the max-flow itself (that
	// still goes through the edge-list vertex-split representation,
	// same as fast_min_cut_search()).
	rowptr = J(n+1,1,0)
	for (i=1; i<=n; i++) rowptr[i+1] = rowptr[i] + deg[i]
	cursor = rowptr[1::n]
	colidx = J(m,1,0)
	for (e=1; e<=m; e++) {
		colidx[cursor[eu[e]]+1] = ev[e]
		cursor[eu[e]] = cursor[eu[e]] + 1
	}

	bignum = n + 10
	edgeToP = &edgeTo
	edgeCapP = &edgeCap
	edgeRevP = &edgeRev
	headEdgeP = &headEdge
	nextEdgeP = &nextEdge
	build_vertexsplit_sparse_edges(n, eu, ev, bignum, edgeToP, edgeCapP, edgeRevP, headEdgeP, nextEdgeP)

	// v0's own neighbor set and a marker array for O(1) "is i tied to
	// v0?" checks. BUGFIX: Mata's a::b range operator produces a
	// DESCENDING sequence when a>b (confirmed directly: "6::5" is
	// (6,5), not empty) rather than an empty range - v0 is the
	// MINIMUM-degree vertex, so deg[v0] can genuinely be 0 (an
	// isolated node), making rowptr[v0]+1 > rowptr[v0+1] and silently
	// pulling two bogus colidx entries into neighbors_v0 instead of
	// correctly finding none, without this guard.
	if (rowptr[v0]+1 <= rowptr[v0+1]) neighbors_v0 = colidx[(rowptr[v0]+1)::rowptr[v0+1]]'
	else neighbors_v0 = J(1,0,0)
	isNbrJ = J(1, n, 0)
	if (cols(neighbors_v0) > 0) isNbrJ[neighbors_v0] = J(1, cols(neighbors_v0), 1)

	// (2) v0 to every vertex it is NOT adjacent to. Early-exit (see
	// this function's own header comment): once minflow is already
	// strictly below `target', nothing this search could still find
	// matters to KComponentsEdges() - it already knows conn < k and
	// already has a valid (s,t) cutting pair.
	for (i=1; i<=n & !(has_target & minflow < target); i++) {
		if (i != v0 & isNbrJ[i] == 0) {
			f = maxflow_sparse_query(edgeToP, edgeCapP, edgeRevP, headEdgeP, nextEdgeP, n, bignum, v0, i)
			if (f < minflow) {
				minflow = f
				best_s = v0
				best_t = i
			}
		}
	}

	// (3) every non-adjacent pair among v0's own neighbors - a fresh
	// marker array per neighbor_i (sized n but only ever populated
	// with that node's own degree-many entries, so the O(n) J()
	// allocation is the only per-i cost beyond the O(degree) fill).
	for (i=1; i<=cols(neighbors_v0) & !(has_target & minflow < target); i++) {
		isNbrJ = J(1, n, 0)
		isNbrJ[colidx[(rowptr[neighbors_v0[i]]+1)::rowptr[neighbors_v0[i]+1]]'] = J(1, deg[neighbors_v0[i]], 1)
		for (j=i+1; j<=cols(neighbors_v0) & !(has_target & minflow < target); j++) {
			if (isNbrJ[neighbors_v0[j]] == 0) {
				f = maxflow_sparse_query(edgeToP, edgeCapP, edgeRevP, headEdgeP, nextEdgeP, n, bignum, neighbors_v0[i], neighbors_v0[j])
				if (f < minflow) {
					minflow = f
					best_s = neighbors_v0[i]
					best_t = neighbors_v0[j]
				}
			}
		}
	}

	return((minflow, best_s, best_t))
}

/*
	min_vertex_cutset_edges_given: the edge-list-native equivalent of
	min_vertex_cutset_given() above - same construction (re-run max-flow
	on the winning pair, keeping its final flow state; BFS the residual
	graph from s_out; a node whose v_in is reachable but v_out is not is
	a cutset member), just sourced from an edge list instead of a dense
	matrix, and using a CSR for the "plain degree bound, no max-flow
	needed" branch's own neighbor-set lookup.
*/
real rowvector min_vertex_cutset_edges_given(real scalar n, real colvector eu, real colvector ev, real rowvector search){
	real scalar N, bignum, v, i, minflow, best_s, best_t, v0, delta, e, m
	real rowvector cutset, degrees
	real colvector visited, queue, cutset_col, deg, rowptr, colidx, cursor
	real scalar qhead, qtail
	pointer(real colvector) scalar edgeToP, edgeCapP, edgeRevP, headEdgeP, nextEdgeP
	real colvector edgeTo, edgeCap, edgeRev, headEdge, nextEdge
	real colvector flow, parentEdge
	real scalar pathflow, pf, erev

	minflow = search[1]
	best_s = search[2]
	best_t = search[3]

	if (best_s == 0) {
		if (minflow == 0) return(J(1,0,0))
		m = rows(eu)
		degrees = J(1, n, 0)
		for (e=1; e<=m; e++) degrees[eu[e]] = degrees[eu[e]] + 1
		delta = min(degrees)
		v0 = 1
		for (i=1; i<=n; i++) {
			if (degrees[i] == delta) {
				v0 = i
				i = n + 1
			}
		}
		return(select(ev', eu' :== v0))
	}

	N = 2*n
	bignum = n + 10
	edgeToP = &edgeTo
	edgeCapP = &edgeCap
	edgeRevP = &edgeRev
	headEdgeP = &headEdge
	nextEdgeP = &nextEdge
	build_vertexsplit_sparse_edges(n, eu, ev, bignum, edgeToP, edgeCapP, edgeRevP, headEdgeP, nextEdgeP)
	edgeCap[2*best_s-1] = bignum
	edgeCap[2*best_t-1] = bignum

	flow = J(rows(edgeTo), 1, 0)
	while (bfs_augment_sparse(edgeTo, edgeCap, flow, headEdge, nextEdge, N, n+best_s, best_t, &parentEdge)) {
		pathflow = bignum
		v = best_t
		while (v != n+best_s) {
			e = parentEdge[v]
			pf = edgeCap[e] - flow[e]
			if (pf < pathflow) pathflow = pf
			v = edgeTo[edgeRev[e]]
		}
		v = best_t
		while (v != n+best_s) {
			e = parentEdge[v]
			erev = edgeRev[e]
			flow[e] = flow[e] + pathflow
			flow[erev] = flow[erev] - pathflow
			v = edgeTo[erev]
		}
	}

	visited = J(N,1,0)
	queue = J(N,1,0)
	qhead = 1
	qtail = 1
	queue[1] = n+best_s
	visited[n+best_s] = 1
	while (qhead <= qtail) {
		v = queue[qhead]
		qhead++
		e = headEdge[v]
		while (e != 0) {
			if ((edgeCap[e]-flow[e])>0 & visited[edgeTo[e]]==0) {
				visited[edgeTo[e]] = 1
				qtail++
				queue[qtail] = edgeTo[e]
			}
			e = nextEdge[e]
		}
	}

	cutset_col = J(0,1,0)
	for (i=1; i<=n; i++) {
		if (i==best_s | i==best_t) continue
		if (visited[i]==1 & visited[n+i]==0) cutset_col = (cutset_col \ i)
	}
	return(cutset_col')
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
	real scalar n, N, bignum
	real matrix basecap
	pointer(real matrix) scalar capptr

	n = rows(adj)
	N = 2 * n
	bignum = n + 10
	basecap = build_vertexsplit_basecap(adj, bignum)
	capptr = &basecap
	return(maxflow_vertex_split_shared(capptr, n, bignum, s, t))
}

/*
	build_vertexsplit_basecap(adj, bignum): builds the vertex-split
	capacity matrix's "default" state - every node's own v_in->v_out
	split edge at capacity 1 (as if no particular (s,t) pair were
	being queried yet) plus the full u_out->v_in block from `adj'.
	maxflow_vertex_split_shared() below temporarily raises exactly two
	cells (the query's own s and t) to `bignum' and restores them
	afterward, so this base matrix can be built ONCE per
	fast_min_cut_search() call and reused across all of its O(delta^2)
	max-flow queries instead of rebuilt from `adj' every single time -
	see maxflow_vertex_split_shared()'s own header comment for why
	this matters.
*/
real matrix build_vertexsplit_basecap(real matrix adj, real scalar bignum){
	real scalar n, N, i
	real matrix cap, tempadj

	n = rows(adj)
	N = 2 * n
	cap = J(N, N, 0)
	for (i=1; i<=n; i++) {
		cap[i, n+i] = 1
	}
	tempadj = adj
	_diag(tempadj, 0)
	cap[(n+1)::N, 1::n] = (tempadj :!= 0) :* bignum
	return(cap)
}

/*
	maxflow_vertex_split_shared(capptr, n, bignum, s, t): the actual
	max-flow computation, factored out of maxflow_vertex_split() so
	fast_min_cut_search() can call it directly against a single shared
	base capacity matrix (built once via build_vertexsplit_basecap())
	instead of paying that matrix's own O(n^2) construction cost again
	on every one of its O(delta^2) queries - this was, after the fix
	one unit ago that replaced the interpreted double-loop construction
	with a single vectorized assignment, still the dominant remaining
	cost: the vectorized assignment is itself still O(n^2) work, and
	was still being redone from scratch on every single call. Mutates
	*capptr's two split-edge cells for this specific (s,t) query to
	`bignum' and restores them to 1 before returning, so the shared
	matrix is back to its default state for the next query regardless
	of which (s,t) pair is queried next.
*/
real scalar maxflow_vertex_split_shared(pointer(real matrix) scalar capptr, real scalar n, real scalar bignum, real scalar s, real scalar t){
	real scalar N, maxf, pathflow, pf, u, v
	real matrix flow
	real rowvector parent

	N = 2 * n
	(*capptr)[s, n+s] = bignum
	(*capptr)[t, n+t] = bignum

	flow = J(N, N, 0)
	maxf = 0
	while (bfs_augment(*capptr, flow, n+s, t, parent)) {
		pathflow = bignum
		v = t
		while (v != n+s) {
			u = parent[v]
			pf = (*capptr)[u,v] - flow[u,v]
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

	// restore the shared base matrix's default state (split capacity
	// 1 for every node) so the next query, on whatever (s,t) it uses,
	// sees the same base matrix build_vertexsplit_basecap() produced -
	// not a stale bignum left over from this query's own s/t.
	(*capptr)[s, n+s] = 1
	(*capptr)[t, n+t] = 1
	return(maxf)
}

/*
	fast_min_cut_search(adj): finds the graph's global vertex
	connectivity kappa(G) and a witness non-adjacent pair achieving it,
	using the Esfahanian & Hakimi (1984) refinement of Even's algorithm
	- O(delta^2) max-flow calls (delta = minimum degree), independent
	of n, instead of the naive O(n^2) all-non-adjacent-pairs search
	this package used until this harmonisation unit (see
	docs/CERTIFICATION.md - found via a direct, measured performance
	regression: nwkcomponents took 66 SECONDS on a mere 100-node/
	avg-degree-10 random graph, ~4,450 max-flow calls for a case that
	needs at most a few hundred). A huge win specifically for sparse
	networks (delta << n), the overwhelmingly common case for this
	package's own commands, and the ones this fix was found benchmarking
	against.

	By Menger's theorem, kappa(G) is the minimum, over every non-adjacent
	pair, of the local vertex connectivity (min vertex set separating
	them, i.e. maxflow_vertex_split()). Checking literally every pair is
	always correct but wasteful; the Esfahanian-Hakimi theorem proves a
	much smaller set of pairs is provably sufficient:
	  (1) kappa(G) <= delta(G) always (removing all of any vertex's own
	      neighbors isolates it) - an upper bound needing no max-flow
	      call at all.
	  (2) Let v0 be a vertex of minimum degree (delta neighbors). Check
	      local connectivity from v0 to every vertex NOT adjacent to it
	      - O(delta) calls (there are at most n-1-delta such vertices,
	      but critically the ALGORITHM's own correctness bound is
	      O(delta), not O(n) - see (3)).
	  (3) Check local connectivity between every PAIR of v0's own
	      delta neighbors that are not themselves adjacent - O(delta^2)
	      calls. This step is NOT optional (Esfahanian & Hakimi's own
	      proof): a minimum cut smaller than delta can exist entirely
	      "around" v0's neighborhood without involving v0's own
	      non-adjacency to anyone, and (2) alone would miss it.
	  kappa(G) = min of (1), every value from (2), every value from (3).
	A complete graph (delta = n-1) falls out correctly with zero max-flow
	calls: v0 is adjacent to everyone (so (2)'s loop is empty) and every
	pair of v0's n-1 neighbors is also adjacent to each other in a
	complete graph (so (3)'s loop is empty too), leaving kappa = delta =
	n-1 exactly as required - no separate base case needed.

	Returns a 3-element row vector (kappa, best_s, best_t): best_s/
	best_t is the non-adjacent pair whose max-flow computation actually
	achieved the reported minimum (0,0 if the minimum was the plain
	degree bound (1) itself, with no max-flow call ever needed to beat
	it - including the complete-graph case above).
*/
real rowvector fast_min_cut_search(real matrix adj){
	real scalar n, i, j, v0, delta, f, minflow, best_s, best_t, bignum
	real rowvector degrees, neighbors_v0
	pointer(real colvector) scalar edgeToP, edgeCapP, edgeRevP, headEdgeP, nextEdgeP
	real colvector edgeTo, edgeCap, edgeRev, headEdge, nextEdge

	n = rows(adj)
	degrees = J(1, n, 0)
	for (i=1; i<=n; i++) {
		degrees[i] = sum(adj[i,.] :!= 0)
	}
	delta = min(degrees)
	v0 = 1
	for (i=1; i<=n; i++) {
		if (degrees[i] == delta) {
			v0 = i
			i = n + 1
		}
	}

	minflow = delta
	best_s = 0
	best_t = 0

	// PERFORMANCE FIX (this unit): was built once as a dense (2n)x(2n)
	// base capacity matrix (build_vertexsplit_basecap()) and shared via
	// a pointer across all of this function's own O(delta^2) queries -
	// a real win over rebuilding it from scratch every query (see
	// maxflow_vertex_split_shared()'s own header comment, one unit
	// ago), but each of those O(delta^2) queries still did O(n^2) work
	// internally against that dense matrix - confirmed as the reason
	// nwkcomponents/nwcohesion still did not complete at n=10,000
	// (28GB+/9.5GB+ RAM observed directly before being killed).
	// build_vertexsplit_sparse()/maxflow_sparse_query() below are the
	// sparse-edge-list equivalent of the exact same "build once, share
	// via pointers, patch 2 cells per query" pattern - see their own
	// header comments. Verified byte-for-byte identical flow values
	// against the dense build_vertexsplit_basecap()/maxflow_vertex_
	// split_shared() pair (still kept, unmodified, as
	// cscripts/test_vertex_connectivity.do's own reference oracle)
	// across hundreds of random graphs before trusting this rewire.
	bignum = n + 10
	edgeToP = &edgeTo
	edgeCapP = &edgeCap
	edgeRevP = &edgeRev
	headEdgeP = &headEdge
	nextEdgeP = &nextEdge
	build_vertexsplit_sparse(adj, bignum, edgeToP, edgeCapP, edgeRevP, headEdgeP, nextEdgeP)

	// (2) v0 to every vertex it is NOT adjacent to
	for (i=1; i<=n; i++) {
		if (i != v0 & adj[v0,i] == 0) {
			f = maxflow_sparse_query(edgeToP, edgeCapP, edgeRevP, headEdgeP, nextEdgeP, n, bignum, v0, i)
			if (f < minflow) {
				minflow = f
				best_s = v0
				best_t = i
			}
		}
	}

	// (3) every non-adjacent pair among v0's own neighbors
	neighbors_v0 = selectindex(adj[v0,.] :!= 0)
	for (i=1; i<=cols(neighbors_v0); i++) {
		for (j=i+1; j<=cols(neighbors_v0); j++) {
			if (adj[neighbors_v0[i], neighbors_v0[j]] == 0) {
				f = maxflow_sparse_query(edgeToP, edgeCapP, edgeRevP, headEdgeP, nextEdgeP, n, bignum, neighbors_v0[i], neighbors_v0[j])
				if (f < minflow) {
					minflow = f
					best_s = neighbors_v0[i]
					best_t = neighbors_v0[j]
				}
			}
		}
	}

	return((minflow, best_s, best_t))
}

/*
	vertex_connectivity(adj): the graph's overall vertex connectivity
	kappa(G) - the minimum number of nodes whose removal disconnects
	the graph or reduces it to a single node. See fast_min_cut_search()
	above for the algorithm and why it replaced this package's earlier
	O(n^2) brute-force search over every non-adjacent pair.
*/
real scalar vertex_connectivity(real matrix adj){
	real rowvector result

	if (rows(adj) <= 1) return(0)
	result = fast_min_cut_search(adj)
	return(result[1])
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
	// BUGFIX: used to re-run its own O(n^2) all-non-adjacent-pairs
	// search identical to vertex_connectivity()'s own former one -
	// same fix, see fast_min_cut_search()'s own header comment.
	return(min_vertex_cutset_given(adj, fast_min_cut_search(adj)))
}

/*
	min_vertex_cutset_given(adj, search): the actual work of
	min_vertex_cutset() above, taking an already-computed
	fast_min_cut_search() result instead of running its own - added
	this unit so KComponents() (below) can call fast_min_cut_search()
	exactly ONCE per recursion level (it already needs the result for
	vertex_connectivity()'s own check) instead of running it a SECOND
	time from scratch just to extract the cutset, whenever a cut turns
	out to be needed. Each fast_min_cut_search() call pays an
	unavoidable O(n^2) scan of the dense `adj' it's given (see that
	function's own header comment) to build its sparse edge
	representation, so skipping the redundant second call roughly
	halves that per-level cost - confirmed as worth doing directly: a
	10,000-node benchmark run was still taking several minutes even
	after this same unit's sparse max-flow fix, well past what the
	max-flow work alone would explain, before this and the
	component-splitting BFS fix (KComponents()'s own comment below)
	were also applied.
*/
real rowvector min_vertex_cutset_given(real matrix adj, real rowvector search){
	real scalar n, N, bignum, v, i, minflow, best_s, best_t, v0, delta, e
	real rowvector cutset, degrees
	real colvector visited, queue, cutset_col
	real scalar qhead, qtail
	pointer(real colvector) scalar edgeToP, edgeCapP, edgeRevP, headEdgeP, nextEdgeP
	real colvector edgeTo, edgeCap, edgeRev, headEdge, nextEdge
	real colvector flow, parentEdge
	real scalar pathflow, pf, erev

	n = rows(adj)
	minflow = search[1]
	best_s = search[2]
	best_t = search[3]

	if (best_s == 0) {
		// The minimum was the plain degree bound itself, with no
		// max-flow call needed to beat it. minflow==0 is the
		// "graph already disconnected" case handled below (not by
		// this branch: kappa==0 with no non-adjacent pair at all is
		// only possible for n<=1, already excluded by every caller).
		// Otherwise, the minimum-degree vertex's own neighbor set is
		// itself always a valid minimum cutset of size delta -
		// removing it isolates that vertex (or reduces the graph to
		// it alone), which is exactly what a vertex cut means here -
		// no max-flow-based extraction needed to find it.
		if (minflow == 0) return(J(1,0,0))
		degrees = J(1, n, 0)
		for (i=1; i<=n; i++) {
			degrees[i] = sum(adj[i,.] :!= 0)
		}
		delta = min(degrees)
		v0 = 1
		for (i=1; i<=n; i++) {
			if (degrees[i] == delta) {
				v0 = i
				i = n + 1
			}
		}
		return(selectindex(adj[v0,.] :!= 0))
	}

	// PERFORMANCE FIX (this unit): re-runs max-flow on the winning pair
	// using the same sparse edge-list representation fast_min_cut_
	// search() now uses, instead of rebuilding a dense (2n)x(2n)
	// capacity matrix - see build_vertexsplit_sparse()/maxflow_sparse_
	// query()'s own header comments. maxflow_sparse_query() itself
	// resets its OWN internal flow array to 0 and restores its two
	// patched capacity cells before returning, so its own flow state
	// cannot be reused for cutset extraction here - the augmenting-
	// path loop is therefore inlined directly against the SAME shared
	// edge arrays instead, keeping this function's own `flow' array
	// alive afterward for the residual-reachability BFS below (the
	// same "keep the final flow state" need the original dense version
	// had for exactly the same reason).
	N = 2*n
	bignum = n + 10
	edgeToP = &edgeTo
	edgeCapP = &edgeCap
	edgeRevP = &edgeRev
	headEdgeP = &headEdge
	nextEdgeP = &nextEdge
	build_vertexsplit_sparse(adj, bignum, edgeToP, edgeCapP, edgeRevP, headEdgeP, nextEdgeP)
	edgeCap[2*best_s-1] = bignum
	edgeCap[2*best_t-1] = bignum

	flow = J(rows(edgeTo), 1, 0)
	while (bfs_augment_sparse(edgeTo, edgeCap, flow, headEdge, nextEdge, N, n+best_s, best_t, &parentEdge)) {
		pathflow = bignum
		v = best_t
		while (v != n+best_s) {
			e = parentEdge[v]
			pf = edgeCap[e] - flow[e]
			if (pf < pathflow) pathflow = pf
			v = edgeTo[edgeRev[e]]
		}
		v = best_t
		while (v != n+best_s) {
			e = parentEdge[v]
			erev = edgeRev[e]
			flow[e] = flow[e] + pathflow
			flow[erev] = flow[erev] - pathflow
			v = edgeTo[erev]
		}
	}

	// BFS the residual graph from best_s's own "out" node, following
	// edge lists instead of scanning a dense row per dequeued node.
	visited = J(N,1,0)
	queue = J(N,1,0)
	qhead = 1
	qtail = 1
	queue[1] = n+best_s
	visited[n+best_s] = 1
	while (qhead <= qtail) {
		v = queue[qhead]
		qhead++
		e = headEdge[v]
		while (e != 0) {
			if ((edgeCap[e]-flow[e])>0 & visited[edgeTo[e]]==0) {
				visited[edgeTo[e]] = 1
				qtail++
				queue[qtail] = edgeTo[e]
			}
			e = nextEdge[e]
		}
	}

	cutset_col = J(0,1,0)
	for (i=1; i<=n; i++) {
		if (i==best_s | i==best_t) continue
		if (visited[i]==1 & visited[n+i]==0) cutset_col = (cutset_col \ i)
	}
	cutset = cutset_col'
	return(cutset)
}

/*
	build_edgelist_csr_dense(adj, euP, evP, rowptrP, colidxP):
	one-time O(n^2) extraction of both representations KComponentsEdges()
	needs from a dense adjacency matrix - a symmetric edge list (eu, ev,
	the same convention build_vertexsplit_sparse() derives internally)
	and a CSR (rowptr, colidx) of the same graph, built directly from
	that edge list rather than re-scanning `adj' a second time.
	Named this short (not build_edgelist_and_csr_from_dense, the first
	choice) after hitting a previously-undocumented Mata constraint the
	hard way: identifiers are capped at 32 characters - a 33-character
	name compiles with "'<name>' found where name expected" at its own
	definition, with no indication length is the problem (confirmed by
	bisecting down to a minimal repro: identical code, only the name
	changed, 32 chars compiles clean and 33 fails identically).
*/
void build_edgelist_csr_dense(real matrix adj,
		pointer(real colvector) scalar euP, pointer(real colvector) scalar evP,
		pointer(real colvector) scalar rowptrP, pointer(real colvector) scalar colidxP){
	real scalar n, m, i, e
	real matrix tempadj
	real colvector nzidx, eu, ev, deg, rowptr, colidx, cursor

	n = rows(adj)
	tempadj = adj
	_diag(tempadj, 0)
	nzidx = selectindex(vec(tempadj) :!= 0)
	m = rows(nzidx)
	if (m > 0) {
		eu = mod(nzidx :- 1, n) :+ 1
		ev = floor((nzidx :- 1) :/ n) :+ 1
	}
	else {
		eu = J(0,1,0)
		ev = J(0,1,0)
	}

	deg = J(n,1,0)
	for (e=1; e<=m; e++) deg[eu[e]] = deg[eu[e]] + 1
	rowptr = J(n+1,1,0)
	for (i=1; i<=n; i++) rowptr[i+1] = rowptr[i] + deg[i]
	cursor = rowptr[1::n]
	colidx = J(m,1,0)
	for (e=1; e<=m; e++) {
		colidx[cursor[eu[e]]+1] = ev[e]
		cursor[eu[e]] = cursor[eu[e]] + 1
	}

	(*euP) = eu
	(*evP) = ev
	(*rowptrP) = rowptr
	(*colidxP) = colidx
}

/*
	csr_neighbors(rowptr, colidx, u): u's neighbor list from a CSR,
	guarding against Mata's a::b range operator returning a DESCENDING
	sequence (not empty) when a>b - see fast_min_cut_search_edges()'s
	own header/inline comment for the direct confirmation ("6::5" is
	(6,5)) and why a degree-0 node makes this guard necessary.
*/
real rowvector csr_neighbors(real colvector rowptr, real colvector colidx, real scalar u){
	if (rowptr[u]+1 <= rowptr[u+1]) return(colidx[(rowptr[u]+1)::rowptr[u+1]]')
	return(J(1,0,0))
}

/*
	KComponentsEdges(nfull, eu, ev, rowptr, colidx, nodeset, k): the
	edge-list/CSR-native equivalent of KComponents() above - identical
	algorithm (see that function's own header comment for the full
	explanation of the recursive cut-and-recurse decomposition), but
	every step here costs time proportional to the CURRENT node set's
	own edges, never O(n_level^2). `eu'/`ev'/`rowptr'/`colidx' describe
	the ORIGINAL full graph (node IDs 1..nfull) and are identical at
	every recursion depth - only `nodeset' changes.
*/
real matrix KComponentsEdges(real scalar nfull, real colvector eu, real colvector ev,
		real colvector rowptr, real colvector colidx,
		real rowvector nodeset, real scalar k){
	real matrix results, childresults
	real rowvector idx, cutset, cutset_orig, remaining, comp_of, newnodeset
	real rowvector queue, remainingInd, candidates, search, inIdx, localMap, nbrs_u
	real scalar n, conn, i, c, ncomp, is_cut, node0, u, w, nc, m
	real scalar qhead, qtail
	real colvector eu_local, ev_local, keep

	n = cols(nodeset)
	idx = selectindex(nodeset)
	results = J(0, n, 0)

	if (length(idx) < k+1) {
		return(results)
	}

	// Filter the ORIGINAL edge list down to just this level's own node
	// set, renumbered to a local 1..|idx| index space -
	// O(m_full) (m_full = the ORIGINAL graph's total edge count, fixed
	// for the whole recursion), not O(n_level^2).
	inIdx = J(1, nfull, 0)
	inIdx[idx] = J(1, cols(idx), 1)
	localMap = J(1, nfull, 0)
	localMap[idx] = (1::cols(idx))'

	m = rows(eu)
	if (m > 0) keep = selectindex(inIdx[eu]' :& inIdx[ev]')
	else keep = J(0,1,0)
	if (rows(keep) > 0) {
		eu_local = localMap[eu[keep]]'
		ev_local = localMap[ev[keep]]'
	}
	else {
		eu_local = J(0,1,0)
		ev_local = J(0,1,0)
	}

	// vertex_connectivity(sub)'s own n<=1 short-circuit is reproduced
	// implicitly: fast_min_cut_search_edges() itself already returns
	// (0,0,0) for a 1-node input with no non-adjacent-pair loop ever
	// executing (same behavior as fast_min_cut_search(), verified
	// directly).
	// PERFORMANCE FIX (this unit): passes `k' as fast_min_cut_search_
	// edges()'s own early-exit target - KComponentsEdges() only needs
	// to know whether conn is below its OWN fixed target k, not the
	// exact global minimum, and only needs SOME sub-k cutting pair, not
	// the smallest one (see that function's own header comment for the
	// full explanation and the measured cause: a near-isolated node's
	// "every non-neighbor" scan is O(n), not O(delta), and was
	// confirmed directly as the actual 70+-second-per-level cost this
	// fixes). The "conn >= k, whole set qualifies" branch just below is
	// completely unaffected - the early exit only ever fires once
	// minflow is already known to be below k, which cannot happen on a
	// branch that reports conn >= k.
	search = fast_min_cut_search_edges(cols(idx), eu_local, ev_local, k)
	conn = search[1]
	if (conn >= k) {
		results = nodeset
		return(results)
	}

	// min_vertex_cutset_edges_given() is guaranteed to return a
	// genuinely non-empty cutset at this point - same short, exact
	// argument as KComponents()'s own (now-removed) inline comment
	// made for the dense version: reaching this line already proves
	// `conn < k' on a node set with `length(idx) >= k+1', which rules
	// out `sub' being complete (a complete s-node graph has
	// connectivity s-1, and s-1<k together with s>=k+1 is impossible),
	// so a non-adjacent pair always exists for it to search over.
	cutset = min_vertex_cutset_edges_given(cols(idx), eu_local, ev_local, search)
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

	// Connected components of "remaining", walking the ORIGINAL
	// graph's own CSR (O(degree(u)) per dequeued node) instead of a
	// dense row - remainingInd/comp_of are indexed by ORIGINAL node ID
	// (0..nfull), matching the CSR's own numbering directly.
	remainingInd = J(1, n, 0)
	if (cols(remaining) > 0) remainingInd[remaining] = J(1, cols(remaining), 1)

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
			nbrs_u = csr_neighbors(rowptr, colidx, u)
			candidates = select(nbrs_u, remainingInd[nbrs_u] :& (comp_of[nbrs_u] :== 0))
			nc = cols(candidates)
			for (c=1; c<=nc; c++) {
				w = candidates[c]
				comp_of[w] = ncomp
				qtail++
				queue[qtail] = w
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
		childresults = KComponentsEdges(nfull, eu, ev, rowptr, colidx, newnodeset, k)
		results = results \ childresults
	}
	return(results)
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
	real scalar nfull
	real colvector eu, ev, rowptr, colidx

	// PERFORMANCE FIX (this unit): KComponents() is now a thin, one-time
	// setup wrapper around KComponentsEdges() below, which does the
	// entire recursion sparsely (never touching a dense matrix at any
	// level). Before this fix, EVERY recursion level re-derived a fresh
	// dense n_level-by-n_level submatrix (origadj indexed by the current
	// node subset twice) and re-scanned it via fast_min_cut_search()'s
	// own O(n^2) vec()/selectindex() extraction - fine for a single top-level call,
	// but confirmed directly (a 10,000-node benchmark network) that a
	// graph needing several SEQUENTIAL small cuts before its "remaining"
	// portion stabilizes pays that near-full-size O(n^2) cost once per
	// cut, compounding badly (79.9 seconds at n=5,000 for ~7 such
	// levels, even after this same unit's earlier sparse max-flow and
	// vectorized component-BFS fixes). Extracting the edge list AND a
	// CSR adjacency ONCE here, up front - both O(n^2)/O(n+m)
	// respectively, paid exactly once regardless of how many recursion
	// levels follow - lets every level's own work scale with that
	// level's own edge count instead.
	nfull = cols(nodeset)
	build_edgelist_csr_dense(origadj, &eu, &ev, &rowptr, &colidx)
	return(KComponentsEdges(nfull, eu, ev, rowptr, colidx, nodeset, k))
}

/*
	CohesionHierarchy(origadj, nodeset): the full, multi-level Moody-White
	(2003) recursive cohesive-blocking decomposition, built directly on top
	of the existing single-level KComponents()/vertex_connectivity()
	primitives (nwkcomponents.ado's own doc header explicitly frames this
	as "a natural, separate follow-on built on the same k(int)-level
	primitive" - this is that follow-on). Returns one row per cohesive
	block found anywhere in the hierarchy (at any depth): column 1 is that
	block's own ACTUAL vertex connectivity (not merely the level it was
	searched for - see below), columns 2..cols(origadj)+1 are its 0/1
	membership indicator over the full original node set.

	Algorithm: compute `nodeset''s own actual connectivity kappa via
	vertex_connectivity() and record (kappa, nodeset) as one block of the
	hierarchy unconditionally - this differs from KComponents() itself,
	which only ever reports sets meeting a REQUESTED target k; here every
	visited node set is reported, at whatever its own true kappa turns out
	to be, since the whole point of the hierarchy is to expose the nesting
	structure across ALL levels, not just one. If `nodeset' is too small to
	possibly contain a (kappa+1)-connected subset (fewer than kappa+2
	nodes - the minimum size a (kappa+1)-connected subgraph could have),
	recursion stops here. Otherwise, KComponents(origadj, nodeset, kappa+1)
	finds every maximal (kappa+1)-or-better-connected child block within
	`nodeset', and each becomes its own recursive call - note a child's
	own reported kappa can turn out to be strictly greater than kappa+1
	(KComponents only guarantees >= the requested target, not equality),
	which is expected and matches a well-documented real property of
	structural cohesion: the hierarchy can skip levels.

	Termination: guaranteed, and needs no defensive equality check against
	`nodeset' itself (contrast KComponents()'s own recursion, which does
	need such reasoning - see its header comment) because every child
	returned by KComponents(origadj, nodeset, kappa+1) is, by that
	function's own contract, a set with connectivity >= kappa+1 - strictly
	greater than `nodeset''s own just-computed connectivity kappa - so a
	child can never be identical to `nodeset' (same node set would mean
	same connectivity). Each recursive call therefore strictly increases
	the target connectivity level, which is bounded above by n-1, so the
	recursion depth is finite regardless of graph structure. A `nodeset'
	with zero qualifying children (KComponents returns 0 rows - no subset
	reaches kappa+1) simply contributes no further rows, via the ordinary
	empty-loop behaviour below; no special case needed.
*/
real matrix CohesionHierarchy(real matrix origadj, real rowvector nodeset){
	real matrix results, childresults, sub, kcomps
	real rowvector idx
	real scalar kappa, i

	idx = selectindex(nodeset)
	sub = origadj[idx, idx]
	kappa = vertex_connectivity(sub)
	results = (kappa, nodeset)

	if (length(idx) < kappa + 2) {
		return(results)
	}

	kcomps = KComponents(origadj, nodeset, kappa + 1)
	for (i=1; i<=rows(kcomps); i++) {
		childresults = CohesionHierarchy(origadj, kcomps[i,.])
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
	string scalar 		provenance // human-readable origin note, e.g. how a projected network was derived - see set_provenance()/get_provenance()

	// Temporal metadata (two-mode/temporal architecture initiative, Part
	// II) - groundwork only, per the user's own explicit scope limit: no
	// full temporal-network modelling subsystem. Three semantics
	// distinguished by `temporaltype': "snapshot" (one timepoint per
	// tie, `edgetime' parallels `edge'), "interval" (start<=t<end per
	// tie, `edgestart'/`edgeend' parallel `edge'), "event" (timestamped
	// relational events, NOT persistent ties - stored separately in
	// `eventlist' as sender/receiver/eventtime triplets, never folded
	// into `edge' at all, so no static command can accidentally treat
	// an event stream as an ordinary graph without an explicit,
	// separate aggregation step). `timevar'/`startvar'/`endvar'/
	// `eventtimevar' are purely descriptive (the original Stata
	// variable name(s) time was declared from), mirroring how
	// `description_mode1'/`description_mode2' work for two-mode.
	real scalar			istemporal
	string scalar		temporaltype
	string scalar		timevar
	string scalar		startvar
	string scalar		endvar
	string scalar		eventtimevar
	real matrix			edgetime
	real matrix			edgestart
	real matrix			edgeend
	real matrix			eventlist

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
	real scalar check_issymmetric()
	real matrix calculate_burt()
	real rowvector edge_weight_row()

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
	string scalar get_provenance()
	real scalar is_temporal_boolean()
	string scalar is_temporal()
	string scalar get_temporal_type()
	string scalar get_timevar()
	string scalar get_startvar()
	string scalar get_endvar()
	string scalar get_eventtimevar()
	pointer(real matrix) get_edge_time()
	pointer(real matrix) get_edge_start()
	pointer(real matrix) get_edge_end()
	pointer(real matrix) get_eventlist()

    real scalar check_valued()
    real scalar check_symmetry()
	
	real matrix single_source_dijkstra()
	real matrix calculate_shortestpaths_dijkstra()
    real matrix calculate_dyadcensus()
	real matrix calculate_triadcensus()
	real matrix calculate_distances()
	real matrix calculate_distances_bfs()
	real matrix calculate_distances_dijkstra()
	real matrix calculate_distances_without()
	real scalar calculate_distance_pair()
	real scalar bfs_dist_excluding()
	real matrix bfs_hopdist_from()
	real matrix calculate_betweenness()
	real matrix calculate_betweenness_native()
	real matrix calculate_betweenness_weighted()
	real matrix calculate_components()
	real matrix calculate_lgc()
	real matrix calculate_clustering()
	real scalar calculate_modularity()
	real matrix detect_communities_louvain()
	real matrix detect_communities_labelprop()
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
	real matrix calculate_cohesion_hierarchy()
	real matrix calculate_laplacian()
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
	void set_provenance()
	void set_temporal()
	void set_temporal_type()
	void set_timevar()
	void set_startvar()
	void set_endvar()
	void set_eventtimevar()
	void set_edge_time()
	void set_edge_interval()
	void set_eventlist()
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
	pointer(class `NWdef' scalar) scalar extract_subgraph()
	void permute()
	void clean_matrix_2mode()
	`BOOL' rename_nodename()
	
	//void export_gexf()
}

/*
	Basic temporal graph-view slicing (two-mode/temporal architecture
	initiative, Part II): given a temporal network and a timepoint,
	return the (i,j,weight) triplets of ties active at that instant -
	the conceptual model requested is "temporal network -> select edges
	active at t -> static graph view -> ordinary nw algorithm", so
	these deliberately return the SAME triplet shape
	set_edge_from_triplets() already consumes elsewhere (nw2project),
	not a new representation. Documented interval convention:
	start <= t < end; a missing end (edgeend == .) is treated as
	open-ended (Mata's missing-as-+infinity comparison semantics
	already make `ee[i,j] > at' true whenever ee[i,j] is missing, so no
	special-casing is needed) - a missing START is NOT specially
	handled (would need the opposite convention, missing-as-negative-
	infinity, which Mata does not give for free) and is simply excluded,
	a documented simplification, not silently wrong.
*/
real matrix nwattime_slice_snapshot(pointer(class nw_def scalar) scalar p, real scalar at){
	real matrix et, ed, out
	real scalar n, i, j, nout
	et = *(p->get_edge_time())
	ed = *(p->get_matrix())
	n = p->get_nodes()
	out = J(n*n, 3, 0)
	nout = 0
	for (i=1; i<=n; i++){
		for (j=1; j<=n; j++){
			if (i != j & et[i,j] != . & et[i,j] == at & ed[i,j] != . & ed[i,j] != 0){
				nout = nout + 1
				out[nout,1] = i
				out[nout,2] = j
				out[nout,3] = ed[i,j]
			}
		}
	}
	if (nout == 0) return(J(0,3,0))
	return(out[(1::nout),.])
}

real matrix nwattime_slice_interval(pointer(class nw_def scalar) scalar p, real scalar at){
	real matrix es, ee, ed, out
	real scalar n, i, j, nout
	es = *(p->get_edge_start())
	ee = *(p->get_edge_end())
	ed = *(p->get_matrix())
	n = p->get_nodes()
	out = J(n*n, 3, 0)
	nout = 0
	for (i=1; i<=n; i++){
		for (j=1; j<=n; j++){
			if (i != j & es[i,j] != . & es[i,j] <= at & ee[i,j] > at & ed[i,j] != . & ed[i,j] != 0){
				nout = nout + 1
				out[nout,1] = i
				out[nout,2] = j
				out[nout,3] = ed[i,j]
			}
		}
	}
	if (nout == 0) return(J(0,3,0))
	return(out[(1::nout),.])
}

/*
	Event slicing is a plain exact-timestamp match (no windowing/
	aggregation - explicitly out of scope for this pass, see
	docs/ROADMAP.md), producing a binary tie per matching event. This
	is the ONE place an event network is allowed to become a persistent
	graph, and only because the user explicitly requested exactly this
	instant via at() - matching the specification's own "acceptable for
	static commands to reject event networks without explicit window"
	language: this command IS the explicit request.
*/
real matrix nwattime_slice_event(pointer(class nw_def scalar) scalar p, real scalar at){
	real matrix ev, acc, out
	real scalar nev, k, n, i, j, nout
	ev = *(p->get_eventlist())
	nev = rows(ev)
	n = p->get_nodes()
	// accumulate through a dense n x n indicator rather than emitting
	// one triplet row per matching event directly - two+ events
	// between the same pair at the exact same t would otherwise emit
	// duplicate triplet rows, which set_edge_from_triplets() (the
	// consumer) does not dedupe itself
	acc = J(n, n, 0)
	for (k=1; k<=nev; k++){
		if (ev[k,3] != . & ev[k,3] == at){
			i = ev[k,1]
			j = ev[k,2]
			if (i > 0 & j > 0 & i != j) acc[i,j] = 1
		}
	}
	out = J(n*n, 3, 0)
	nout = 0
	for (i=1; i<=n; i++){
		for (j=1; j<=n; j++){
			if (acc[i,j] == 1){
				nout = nout + 1
				out[nout,1] = i
				out[nout,2] = j
				out[nout,3] = 1
			}
		}
	}
	if (nout == 0) return(J(0,3,0))
	return(out[(1::nout),.])
}

/*
	Node-naming utilities shared by nwset.ado's own mat()/varlist
	ingestion and nwfromedge.ado's sparse-native construction (moved
	here from nwset.ado during the sparse-backend migration's
	nwfromedge rewiring, so both callers share one implementation
	instead of nwfromedge depending on nwset.ado's own Mata block
	having already been loaded first - a real, if latent, cross-file
	availability risk avoided by centralizing shared utilities in this
	always-loaded core file, matching first_index_match()'s own
	existing precedent).
*/
string matrix get_node_suffix(real scalar nodes){
	real matrix M
	string matrix S

	M = (1::nodes)
	S = strofreal(M)
	return(S)
}

string matrix get_nodenames_from_string(string scalar s, real scalar z, string scalar def){
	string matrix nodenames, nodenamesrest
	real scalar invalid, i, j

	nodenames = (tokens(s,","))'
	nodenames = select(nodenames, (J(rows(nodenames),1, ","):!= nodenames))
	invalid = 0

	// check for duplicates
	for (i = 1; i<= (rows(nodenames)-1); i++){
		for (j = i + 1; j <= rows(nodenames); j++){
			if (nodenames[i] == nodenames[j]){
				invalid = 1
				i = rows(nodenames) + 1
				j = rows(nodenames) + 1
			}
		}
	}

	if (invalid == 1){
		nodenames =(J(z,1,def) + get_node_suffix(z))
		return(nodenames)
	}

	if (rows(nodenames)< z){
		nodenamesrest = (J(z,1,def) + get_node_suffix(z))
		nodenamesrest[(1::rows(nodenames))] = nodenames
		return(nodenamesrest)
	}
	if (rows(nodenames)> z){
		return(nodenames[(1::z)])
	}
	return(nodenames)
}

string matrix get_nodenames_from_var(string scalar v, real scalar z, string scalar def){
	string scalar s

	s = invtokens(st_sdata((1,z), v))
	return(get_nodenames_from_string(s, z, def))
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
	real matrix alters, innb, outnb
	real matrix closed_triples
	real matrix potential_triples
	real scalar i, j, k, alter1_id, alter2_id, w1, w2, ptrip

	closed_triples = J(get_nodes(),1,0)
	potential_triples = J(get_nodes(),1,0)

	// PERFORMANCE FIX (this unit): every mode below used to look up tie
	// presence/weight via the DENSE (*get_matrix())/(*get_matrix_
	// unvalued()) accessors inside its own innermost loop - forcing
	// ensure_dense_built() to materialize the full N-by-N matrix even
	// though neighbor ENUMERATION (alters = neighbors(i)) was already
	// sparse. Not merely a one-time cost either: nwclustering.ado
	// wasn't even calling this function at all until this same unit
	// (see below) - it had its own, entirely separate, Stata-level
	// reshape/merge pipeline instead, measured directly at 459
	// SECONDS on a 10,000-node network (docs/PERFORMANCE_BENCHMARKS.md).
	// Replaced every dense lookup with has_edge()/edge_weight() (the
	// same safe "check has_edge() before reading edge_weight()"
	// pattern nwevcent's own sparse migration already established),
	// so this function no longer touches the dense matrix at all.
	for ( i = 1 ; i <= get_nodes(); i++) {
		if (mode == 0) {
			// BUGFIX (caught by cscripts/test_nwtriads.do's directed-
			// network case during this same unit's validation, not a
			// pre-existing bug this unit introduced no change in
			// output for undirected networks): an earlier draft of this
			// sparse migration paired every two elements of union(out-
			// neighbors(i), in-neighbors(i)) against each other,
			// checking has_edge() in both directions. That over-counts
			// for a DIRECTED network - e.g. two nodes that are both
			// pure in-neighbors of i get paired even though neither one
			// is reachable FROM i, which is not a valid directed wedge.
			// nwclustering.ado's actual shipped (pre-existing, reshape/
			// merge-based) implementation instead only ever pairs one
			// IN-neighbor with one OUT-neighbor of i - the directed
			// two-path a -> i -> b - and checks whether the direct
			// shortcut a -> b closes it (the same in x out cross-
			// product idiom calculate_brokerage() already uses above
			// for its own directed two-path enumeration). For an
			// undirected network neighbors_in()==neighbors() by
			// construction, so this reduces to exactly the same count
			// as the old union-based draft (every unordered alter pair
			// {a,b} is visited as both (in=a,out=b) and (in=b,out=a),
			// matching that draft's potential_triples+=2 and
			// has_edge(a,b)+has_edge(b,a) exactly) - confirmed via
			// direct hand and empirical cross-checks against the
			// pre-existing reshape pipeline on both directed and
			// undirected networks before trusting this.
			innb = neighbors_in(i)
			outnb = neighbors(i)
			for (j = 1; j <= rows(innb); j++){
				alter1_id = innb[j]
				for (k = 1; k <= rows(outnb); k++){
					alter2_id = outnb[k]
					if (alter2_id == alter1_id) continue
					potential_triples[i,1] = potential_triples[i,1] + 1
					closed_triples[i,1] = closed_triples[i,1] + has_edge(alter1_id,alter2_id)
				}
			}
			continue
		}

		// valued modes: out-neighbors only (matches the original's
		// asymmetric, out-row-only derivation for the weighted modes
		// exactly) - only ever reached for undirected networks in
		// practice, since nwclustering.ado itself refuses any
		// weighted measure on a directed network.
		alters = neighbors(i)
		for (j = 1; j <= rows(alters); j++){
			alter1_id = alters[j]
			for (k = (j+1); k <= rows(alters); k++){
				alter2_id = alters[k]
				w1 = has_edge(i,alter1_id) ? edge_weight(i,alter1_id) : 0
				w2 = has_edge(i,alter2_id) ? edge_weight(i,alter2_id) : 0
				if (mode == 1) ptrip = (w1 + w2) / 2          // arithmetic mean
				else if (mode == 2) ptrip = sqrt(w1 * w2)     // geometric mean
				else if (mode == 3) ptrip = max((w1, w2))     // maximum
				else ptrip = min((w1, w2))                    // minimum
				closed_triples[i,1] = closed_triples[i,1] + ptrip :* has_edge(alter1_id,alter2_id)
				potential_triples[i,1] = potential_triples[i,1] + ptrip
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
	Detect communities via label propagation (Raghavan, Albert & Kumar 2007)
	- see LabelPropagation()'s own header comment for the algorithm.
*/
real matrix `NWdef'::detect_communities_labelprop(| real scalar valued){
	real matrix w
	real scalar val

	val = (args() >= 1 ? valued : 1)
	w = *get_matrix_mod(val, 0)
	_diag(w, 0)
	return(LabelPropagation(w))
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
	Full Moody & White (2003) cohesive-blocking hierarchy - see
	CohesionHierarchy()'s own header comment for the algorithm. Always
	undirected and binary, for the same reason calculate_kcomponents()
	above is (vertex connectivity has no directed/valued generalization
	this package uses). Column 1 of the result is each block's own actual
	connectivity level; columns 2.. are its 0/1 node membership.
*/
real matrix `NWdef'::calculate_cohesion_hierarchy(){
	real matrix adj
	real rowvector nodeset
	real scalar n

	n = get_nodes()
	adj = (*get_matrix_mod(0,0)) :!= 0
	_diag(adj, 0)

	nodeset = J(1, n, 1)
	return(CohesionHierarchy(adj, nodeset))
}

/*
	Graph Laplacian L = D - W (D the diagonal weighted-degree matrix), the
	standard starting point for spectral graph analysis - Stage 6's
	explicitly-flagged next roadmap item. Always undirected/symmetrized
	(get_matrix_mod(valued, 0)) - the classical Laplacian spectrum results
	(multiplicity of eigenvalue 0 equals the number of connected
	components; the second-smallest eigenvalue, "algebraic connectivity"
	or the Fiedler value, is a genuine measure of overall connectivity;
	its eigenvector's sign gives a classical two-way spectral partition)
	all assume a symmetric, undirected Laplacian - the same reasoning
	every other connectivity-flavored measure in this file (k-components,
	the cohesion hierarchy, Louvain) already applies. Self-loops are
	excluded from the degree/weight construction the same way every other
	such measure here already does (_diag(w,0) first).
*/
real matrix `NWdef'::calculate_laplacian(| real scalar valued){
	real matrix w
	real scalar val

	val = (args() >= 1 ? valued : 1)
	w = *get_matrix_mod(val, 0)
	_diag(w, 0)
	return(diag(rowsum(w)) - w)
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
/*
	Blau's (1977) index of heterogeneity for a categorical variable:
	1 - sum(p_k^2), where p_k is the proportion of `vals' falling in
	category k - 0 when every value is identical (no diversity), and
	approaching 1 as values spread evenly across many categories. Shared
	by calculate_alterstat()'s and calculate_alterstat_hop()'s own
	"diversity" stat branches (a small, pure math helper, unlike those two
	functions' own per-node aggregation loops, which are deliberately kept
	as independent copies - see calculate_alterstat_hop()'s own header
	comment for why). Undefined for zero values - callers only invoke this
	when `vals' is non-empty (m > 0), matching mean/min/max's own
	established missing-for-empty convention.
*/
real scalar BlauIndex(real colvector vals){
	real matrix distinct
	real scalar m, j
	real colvector p

	m = rows(vals)
	distinct = uniqrows(vals)
	p = J(rows(distinct), 1, 0)
	for (j=1; j<=rows(distinct); j++){
		p[j] = sum(vals :== distinct[j]) / m
	}
	return(1 - sum(p:^2))
}

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
		else if (stat == "diversity"){
			if (m > 0) result[i] = BlauIndex(vals)
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
		else if (stat == "diversity"){
			if (m > 0) result[i] = BlauIndex(vals)
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


/*
	Sparse-native forward-BFS distance from `source' to `target', with the
	single direct hop `source'->`target' excluded from the very first
	expansion (used by calculate_distances_without() below to answer "how
	would ego reach alter if this one tie didn't exist"). The old dense
	implementation zeroed both edge[source,target] AND edge[target,source]
	before recomputing - confirmed via direct probe (a hand-built directed
	network with a genuine, distinct reverse arc plus an alternate path)
	that the reverse-arc zeroing never actually changes the result: a
	forward BFS from `source' has no reason to ever traverse back through
	`target'->`source' to reach `target' itself, so excluding only the
	forward hop replicates the dense behaviour exactly while never
	touching the dense `edge' matrix at all.
*/
real scalar `NWdef'::bfs_dist_excluding(real scalar source, real scalar target){
	real matrix dist, queue, newqueue, nb
	real scalar n, d, i, cur

	n = get_nodes()
	dist = J(n,1,.)
	// `source' is pre-marked visited at distance 0 in the general
	// (source != target) case - this is what actually blocks the
	// removed edge from being used, since any OTHER node's neighbor
	// list can still legitimately contain `source' (undirected ties are
	// symmetric, so e.g. removing edge (2,1) doesn't remove 1 from
	// node 2's own neighbor list - only marking `source' permanently
	// "already visited" prevents a path from using that same edge to
	// get back to it). Confirmed the hard way: seeding from neighbors()
	// without this mark (to handle the source==target self-loop case
	// below) silently let a removed edge on a simple path graph be
	// "reached again" through an intermediate node's own, still-intact,
	// neighbor list - a real regression caught by re-running the very
	// probes that had already verified this function, not assumed
	// fixed. The source==target case (a genuine self-loop edge,
	// reachable via edgelist() -> calculate_distances_without()) is
	// handled separately below without this pre-mark, since it needs
	// exactly the opposite: a genuine return path IS what's being
	// asked for, matching calculate_distance_pair()'s own self-pair
	// handling above.
	if (source != target){
		dist[source,1] = 0
	}
	nb = neighbors(source)
	queue = select(nb, nb :!= target)
	d = 1

	while (rows(queue) > 0 & d <= n){
		newqueue = J(0,1,0)
		for (i = 1; i <= rows(queue); i++){
			cur = queue[i,1]
			if (dist[cur,1] == .){
				dist[cur,1] = d
				nb = neighbors(cur)
				newqueue = newqueue \ nb
			}
		}
		if (dist[target,1] != .) break
		queue = newqueue
		d = d + 1
	}
	if (dist[target,1] != .) return(dist[target,1])
	return(-1)
}

/*
	Sparse-native replacement for the old dense implementation, which
	zeroed edge[i,j]/edge[j,i] through the get_matrix() pointer, called
	calculate_distance_pair() (itself dense, matrix-power based), then
	restored the two cells - an O(m * n^3)-shaped computation (m = edge
	count) that also mutated `edge' directly mid-computation. Iterates
	edgelist() (O(nnz), one row per stored sparse entry - both directions
	for an undirected tie, matching the old dense loop's own i,j-pair
	iteration over a symmetric matrix) and calls bfs_dist_excluding() per
	edge instead - O(m * (V+E)), and `edge'/the sparse index are never
	mutated. Verified byte-identical against the prior dense
	implementation on hand-built undirected/directed/bridge/cycle
	networks, including the asymmetric reverse-arc case above.
*/
real matrix `NWdef'::calculate_distances_without(){
	real matrix res, el
	real scalar n, m, ego, alter

	n = get_nodes()
	res = J(n, n, 0)
	el = edgelist()

	for (m = 1; m <= rows(el); m++){
		ego = el[m,1]
		alter = el[m,2]
		res[ego,alter] = bfs_dist_excluding(ego, alter)
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

	if (isdirect){
		// BUGFIX: this used to additionally require nnz > 0, skipping
		// build_reverse_index() entirely for a directed network with
		// zero ties - falling into the `else' branch below instead,
		// which sets rowptr_in to J(0,1,0) (an EMPTY, 0-row matrix),
		// not the correctly n+1-sized "no in-neighbors for any node"
		// array build_reverse_index()'s own nnz==0 branch already knows
		// how to produce (J(n+1,1,1)). Any subsequent neighbors_in()/
		// degree_in() call on such a network then indexed rowptr_in[i+1]
		// out of bounds on a 0-row matrix and crashed with "subscript
		// invalid" - found directly via nw_evcentrality()'s own new
		// sparse power iteration, which (unlike the prior dense
		// symeigensystem()-based implementation) genuinely calls
		// neighbors_in() and hit this on an all-isolates directed
		// network. The fix is simply to always call
		// build_reverse_index() for a directed network - it already
		// handles nnz==0 correctly on its own, so no separate case is
		// needed here at all.
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
	real matrix ord, sorted_ego, sorted_alter, sorted_weight, keep

	n = get_nodes()
	isdirect = directed

	// A stored weight of exactly 0 means "no tie" everywhere else in
	// this class (every dense `edge' matrix is J(n,n,0)-initialized, so
	// an unset cell already reads as 0, and get_arcs_count()/
	// get_edges_count() both explicitly exclude *e==0 cells). The old
	// dense make_matrix() path (removed with nwfromedge.ado's sparse-
	// native rewiring) got this convention for free, since writing a 0
	// into an already-zero cell is a no-op; a sparse index has no such
	// implicit background value, so a zero-weight triplet must be
	// dropped explicitly here or it becomes a real stored tie instead
	// of the "no tie" every other accessor assumes (confirmed via
	// nwcomponents' own regression test: a value-0 edgelist row was
	// silently keeping an otherwise-isolated node connected until this
	// filter was added).
	if (rows(ego) > 0){
		keep = selectindex(weight :!= 0)
		ego = ego[keep,1]
		alter = alter[keep,1]
		weight = weight[keep,1]
	}
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

/*
	Sparse-native replacement for nwissymmetric.ado's own dense
	issymmetric(*get_matrix()) check (via nwtomata's full O(n^2)
	materialization) - a network is symmetric iff, for every stored
	directed edge (i,j,w), the reverse edge (j,i) also exists with the
	identical weight. O(m) edges checked, each an O(degree) sparse
	lookup (has_edge()/edge_weight() scan just j's own row), instead of
	materializing and scanning a full dense n-by-n matrix - confirmed
	as one of the `nwtomata'-dependent family flagged in
	docs/PERFORMANCE_BENCHMARKS.md (harmonisation unit 103) as excluded
	from the n=10,000 benchmark tier entirely. Short-circuits on the
	first asymmetric edge found, so an obviously-asymmetric large
	network returns almost immediately rather than paying for a full
	scan.
*/
real scalar `NWdef'::check_issymmetric(){
	real matrix el
	real scalar k, m

	el = edgelist()
	m = rows(el)
	for (k=1; k<=m; k++){
		if (!has_edge(el[k,2], el[k,1])) return(0)
		if (edge_weight(el[k,2], el[k,1]) != el[k,3]) return(0)
	}
	return(1)
}

/*
	edge_weight_row(i): i's own out-edge weights as a plain row vector
	(same values edge_weight(i,Ni[k]) would give for each of i's own
	neighbors) - a small helper so calculate_burt() above can compute
	outdeg[i] via a single sum() instead of its own loop.
*/
real rowvector `NWdef'::edge_weight_row(real scalar i){
	real matrix Ni
	real rowvector w
	real scalar k

	Ni = neighbors(i)
	w = J(1, rows(Ni), 0)
	for (k=1; k<=rows(Ni); k++) w[k] = edge_weight(i, Ni[k])
	return(w)
}

/*
	Sparse-native replacement for nwburt.ado's own dyadicredundancy()/
	dyadicconstraint()/hierarchy() (file-scope Mata in nwburt.ado),
	which compute Burt's (1992) effective size/efficiency/constraint/
	hierarchy via two FULL n-by-n matrix products (net*net, p*p) after
	materializing the whole network via nwtomata - O(n^3) regardless of
	sparsity, confirmed as one of the `nwtomata'-dependent family
	flagged in docs/PERFORMANCE_BENCHMARKS.md as excluded from the
	n=10,000 benchmark tier. Both matrix products get immediately
	element-wise multiplied by the (sparse) tie matrix itself right
	afterward (dyadred/dyadcon are only ever nonzero where an actual
	tie (i,j) exists - Burt's own constraint is defined per EXISTING
	relationship, not for arbitrary pairs), so only the (i,j) entries
	where a real tie exists are ever used - computed here directly via
	a nested loop over each node's own OUT-neighborhood (the same
	"local induced subgraph" idiom already established for
	calculate_clustering()/calculate_brokerage() above), O(sum of
	out-degree^2) instead of O(n^3): for a bounded-degree sparse graph
	this is close to linear in node count, not cubic.

	Returns an n x 4 matrix (effsize, efficiency, constraint,
	hierarchy), matching nwburt.ado's own generate() column order
	exactly. Does not compute the dyadic-level redundancy/constraint
	NETWORKS nwburt's own dyadredundancy()/dyadconstraint() options can
	optionally save - those remain on the original dense path (a
	disclosed, deliberate scope limit: they are an opt-in, far less
	commonly used feature, and building a new dyadic NETWORK output is
	a different problem from summarizing it per node).
*/
real matrix `NWdef'::calculate_burt(){
	real scalar n, i, j, k, q, outdeg_i, wij, wiq, wqj, net2ij, p2ij, pij, cij
	real matrix Ni, outdeg, effsize, efficiency, constraint, hierarchy_out
	real matrix dyadred_sum, dyadcon_sum, avgc, z, hh, mm

	n = get_nodes()
	outdeg = J(n,1,0)
	for (i=1; i<=n; i++) outdeg[i,1] = sum(edge_weight_row(i))

	dyadred_sum = J(n,1,0)
	dyadcon_sum = J(n,1,0)
	for (i=1; i<=n; i++){
		Ni = neighbors(i)
		outdeg_i = outdeg[i,1]
		if (outdeg_i == 0 | rows(Ni) == 0) continue
		for (j=1; j<=rows(Ni); j++){
			wij = edge_weight(i, Ni[j])
			net2ij = 0
			p2ij = 0
			for (q=1; q<=rows(Ni); q++){
				if (Ni[q] == Ni[j]) continue
				wiq = edge_weight(i, Ni[q])
				if (has_edge(Ni[q], Ni[j])){
					wqj = edge_weight(Ni[q], Ni[j])
					net2ij = net2ij + wiq*wqj
					if (outdeg[Ni[q],1] > 0) p2ij = p2ij + (wiq/outdeg_i)*(wqj/outdeg[Ni[q],1])
				}
			}
			pij = wij/outdeg_i
			cij = pij + p2ij
			dyadred_sum[i,1] = dyadred_sum[i,1] + wij*(net2ij/outdeg_i)
			dyadcon_sum[i,1] = dyadcon_sum[i,1] + wij*(cij^2)
		}
	}

	effsize = outdeg - dyadred_sum
	efficiency = effsize :/ outdeg
	_editmissing(efficiency, 0)
	constraint = dyadcon_sum

	// hierarchy: identical vector-level formula to nwburt.ado's own
	// file-scope hierarchy() function, operating on outdeg/constraint
	// directly instead of rowsum()s of dense dc/net matrices - the
	// two are the same quantities, just derived sparsely above.
	avgc = constraint :/ outdeg
	z = J(n,1,0)
	for (i=1; i<=n; i++){
		Ni = neighbors(i)
		if (outdeg[i,1] == 0 | rows(Ni) == 0) continue
		for (j=1; j<=rows(Ni); j++){
			wij = edge_weight(i, Ni[j])
			// recompute this (i,j)'s own dyadic constraint value (cij)
			// the same way as above - kept as a second, independent
			// pass for clarity matching the original's own separate
			// dc-then-hierarchy(net,dc) two-step structure, at the
			// (small, sparse) cost of repeating the inner O(degree)
			// loop once more.
			net2ij = 0
			p2ij = 0
			for (q=1; q<=rows(Ni); q++){
				if (Ni[q] == Ni[j]) continue
				wiq = edge_weight(i, Ni[q])
				if (has_edge(Ni[q], Ni[j])){
					wqj = edge_weight(Ni[q], Ni[j])
					if (outdeg[Ni[q],1] > 0) p2ij = p2ij + (wiq/outdeg[i,1])*(wqj/outdeg[Ni[q],1])
				}
			}
			pij = wij/outdeg[i,1]
			cij = wij*((pij+p2ij)^2)
			// matches the original's own "z = rowsum(net :* (dc:/avgc)
			// :* log(dc:/avgc))" EXACTLY, including its own extra `net'
			// factor beyond the one already inside dc itself (dc_ij =
			// net_ij*(p_ij+p2_ij)^2) - for a binary network net_ij is
			// idempotent under multiplication so this is invisible
			// there, but a VALUED network's own net_ij^2 term is a real
			// property of the already-shipped formula, not something to
			// silently "fix" as part of a pure performance rewrite.
			if (cij > 0 & avgc[i,1] > 0) z[i,1] = z[i,1] + wij*cij*(ln(cij/avgc[i,1]))/avgc[i,1]
		}
	}
	hierarchy_out = z :/ (outdeg :* ln(outdeg))
	_editmissing(hierarchy_out, 1)
	mm = (outdeg :== 0)
	_editvalue(mm, 1, .)
	hierarchy_out = hierarchy_out :+ mm

	return((effsize, efficiency, constraint, hierarchy_out))
}

void `NWdef'::permute(){
	real matrix perm
	perm = unorder(get_nodes())
	set_edge((*get_matrix())[perm, perm])
}

/*
	Sparse-native replacement for the old dense matrix-power loop
	(temp = temp * temp2, up to n times, O(n^3) per iteration). Seeds the
	BFS frontier from `ego''s own out-neighbors at distance 1, WITHOUT
	pre-marking `ego' itself as visited - this is deliberate, not an
	oversight: the old matrix-power version returns the length of the
	shortest CYCLE back to `ego' when ego==alter (confirmed via direct
	probe: calculate_distance_pair(i,i) on a network with a genuine
	2-cycle through i returns 2, not 0), and seeding from `ego''s
	neighbors rather than `ego' itself reproduces that exactly for both
	ego==alter and ego!=alter without a special case. Respects
	directedness natively via neighbors() (forward/out only - undirected
	ties are already stored symmetrically, see neighbors()'s own
	comment). O(V+E) with early exit once `alter' is found, instead of
	the old O(n^4) worst case.
*/
real scalar `NWdef'::calculate_distance_pair(real scalar ego, real scalar alter){
	real matrix dist, queue, newqueue, nb
	real scalar n, d, i, cur

	n = get_nodes()
	dist = J(n,1,.)
	queue = neighbors(ego)
	d = 1

	while (rows(queue) > 0 & d <= n){
		newqueue = J(0,1,0)
		for (i = 1; i <= rows(queue); i++){
			cur = queue[i,1]
			if (dist[cur,1] == .){
				dist[cur,1] = d
				if (cur != alter){
					nb = neighbors(cur)
					newqueue = newqueue \ nb
				}
			}
		}
		if (dist[alter,1] != .) break
		queue = newqueue
		d = d + 1
	}
	if (dist[alter,1] != .) return(dist[alter,1])
	return(-1)
}

/*
	Sparse-native, unweighted (hop-count) single-source distances from
	`source' via forward BFS over neighbors() - replaces Brute_dist()'s
	O(n^4)-worst-case matrix-power-and-compare loop with O(V+E) per
	source. `source' itself is left missing on return (matching
	Brute_dist()'s own final "_editvalue(dist,0,.)" step, which turns
	every untouched/self cell to missing) - calculate_distances_bfs()
	below fixes that up per row.
*/
real matrix `NWdef'::bfs_hopdist_from(real scalar source){
	real matrix dist, nb, q
	real scalar n, head, tail, cur, k, nbn, nid

	// PERFORMANCE FIX (this unit): rebuilt the frontier on every BFS
	// level via "newqueue = newqueue \ nb" - repeated vertical matrix
	// concatenation, which reallocates and copies the whole growing
	// vector on every append. A level with a large frontier (routine
	// for a random sparse graph, where most nodes are discovered within
	// 2-3 hops) made this effectively quadratic in that level's own
	// size, not the O(n+m) the surrounding algorithm was designed for -
	// confirmed as the actual cause of nwgeodesic/nwcloseness not
	// completing at n=10,000 in a reasonable time (docs/PERFORMANCE_
	// BENCHMARKS.md), not a memory blow-up (RSS stayed flat while CPU
	// stayed pegged during direct observation). Replaced with the
	// standard array-based-queue BFS: a single preallocated length-n
	// vector (a node is enqueued at most once, so n is always enough
	// room) with a read pointer and a write pointer, no reallocation at
	// any point. Produces identical distances to the original
	// level-by-level formulation - verified directly against it (kept,
	// unmodified, as a git-history reference oracle) across many random
	// graphs before trusting this.
	n = get_nodes()
	dist = J(n,1,.)
	dist[source,1] = 0
	q = J(n,1,0)
	head = 1
	tail = 1
	q[tail,1] = source
	tail++

	while (head < tail){
		cur = q[head,1]
		head++
		nb = neighbors(cur)
		nbn = rows(nb)
		for (k=1; k<=nbn; k++){
			nid = nb[k,1]
			if (dist[nid,1] == .){
				dist[nid,1] = dist[cur,1] + 1
				q[tail,1] = nid
				tail++
			}
		}
	}
	dist[source,1] = .
	return(dist)
}

/*
	Sparse-native all-pairs unweighted distance matrix - replaces
	Brute_dist(*get_matrix_unvalued()) in calculate_distances()'s
	"brute" branch. Diagonal missing, matching Brute_dist()'s own
	convention (verified via direct probe against the prior dense
	implementation on hand-built undirected/directed/disconnected
	networks).
*/
real matrix `NWdef'::calculate_distances_bfs(){
	real matrix D
	real scalar n, i

	n = get_nodes()
	D = J(n, n, .)
	for (i = 1; i <= n; i++){
		D[i,.] = bfs_hopdist_from(i)'
	}
	return(D)
}

/*
	Sparse-native all-pairs weighted distance matrix via Dijkstra -
	replaces Dijkstra_dist(*get_matrix(), alpha) in calculate_distances()'s
	non-"brute" branch. Same linear-scan extract-min structure already
	established and certified for calculate_betweenness_weighted() above
	(Mata has no built-in priority queue/decrease-key) - precomputes a
	sparse adjacency/cost cache once via neighbors()/edge_weight() rather
	than rescanning a dense row per relaxation. Edge cost is
	edge_weight(u,v)^(-alpha), i.e. (1/weight)^alpha - the same
	weight-to-distance convention the old Dijkstra_dist() used (it
	inverted the whole matrix once up front, "Ginv = 1/G", then raised to
	alpha inside Dijkstra() itself; edge_weight(u,v)^(-alpha) is the
	identical quantity computed per edge instead of per whole matrix).
	Diagonal 0 (self-distance), matching Dijkstra_dist()'s own convention
	(it never revisits/blanks the source the way Brute_dist() does) -
	verified via direct probe against the prior dense implementation,
	including alpha=0 (every positive tie costs 1, i.e. unweighted) and
	alpha=1 (raw 1/weight per tie) on a directed valued network.
*/
real matrix `NWdef'::calculate_distances_dijkstra(real scalar alpha){
	real matrix adjacencyList, adjacencyCost, D, Dsrc, settled, nb
	real scalar n, m, k, idx, v, s, u, w, i, j, mindist

	n = get_nodes()
	adjacencyList = J(n, max((1, n-1)), .)
	adjacencyCost = J(n, max((1, n-1)), .)
	for (m = 1; m <= n; m++){
		nb = neighbors(m)
		k = 1
		for (idx = 1; idx <= rows(nb); idx++){
			v = nb[idx,1]
			if (v != m){
				adjacencyList[m,k] = v
				adjacencyCost[m,k] = edge_weight(m,v)^(-alpha)
				k++
			}
		}
	}

	D = J(n, n, .)
	for (s = 1; s <= n; s++){
		Dsrc = J(1, n, .)
		Dsrc[s] = 0
		settled = J(1, n, 0)
		for (i = 1; i <= n; i++){
			mindist = .
			u = 0
			for (j = 1; j <= n; j++){
				if (settled[j] == 0 & Dsrc[j] < . & (u == 0 | Dsrc[j] < mindist)){
					mindist = Dsrc[j]
					u = j
				}
			}
			if (u == 0) break
			settled[u] = 1
			for (j = 1; j <= sum(adjacencyList[u,.] :< .); j++){
				w = adjacencyList[u,j]
				if (settled[w]) continue
				if (Dsrc[w] == . | Dsrc[w] > Dsrc[u] + adjacencyCost[u,j]){
					Dsrc[w] = Dsrc[u] + adjacencyCost[u,j]
				}
			}
		}
		D[s,.] = Dsrc
	}
	return(D)
}

real matrix `NWdef'::calculate_distances(real scalar alpha, string scalar alg){
	if (alg == "brute"){
		return(calculate_distances_bfs())
	}
	else {
		return(calculate_distances_dijkstra(alpha))
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
	"D[w]==D[v]+cost(v,w)". Edge cost is edge_weight(v,w)^(-alpha), i.e.
	(1/weight)^alpha - Opsahl, Agneessens and Skvoretz (2010, Social
	Networks 32(3), 245-251), the same tie-STRENGTH-to-distance
	convention calculate_distances_dijkstra()/nwgeodesic already use for
	exactly this reason (a stronger tie is a SHORTER effective distance,
	the opposite of treating the raw weight as a cost) - alpha=1: cost
	is 1/weight; alpha=0: every positive tie costs 1, i.e. unweighted.
	BUGFIX: this used to be edge_weight(v,w)^alpha (no negation) - the
	mathematical INVERSE of Opsahl's own definition and of this exact
	function's own header comment, which already (wrongly) claimed "the
	same alpha-exponent weight-to-distance convention this package
	already uses for calculate_distances()/nwgeodesic" while actually
	computing its opposite. Confirmed via direct hand-calculation on
	nwbetween.ado's own doc-header/cscripts test network (A-B=1, A-C=4,
	B-C=2, C-D=1, undirected): under the corrected 1/weight cost,
	cost(A,B) direct = 1/1 = 1, but cost(A,B) via C = 1/4 + 1/2 = 0.75 -
	CHEAPER, so the true shortest A-B path runs through C, putting C (a
	strongly-tied hub) correctly on the betweenness path it should be
	on. The old, wrong formula priced every direct tie as literally its
	own raw weight regardless of any stronger intermediary, silently
	favoring direct ties over cheaper indirect ones - exactly backwards
	from "a stronger tie means a shorter effective distance."
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
				adjacencyCost[m,k] = edge_weight(m,n)^(-alpha)
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

/*
	Native (C) graph-algorithm plugin dispatcher (harmonisation unit 95,
	docs/CERTIFICATION.md; feasibility background in
	docs/NATIVE_GRAPH_LIBRARIES.md - the evidence-based conclusion there
	is a bespoke C kernel for specific interpreter-overhead-bound
	algorithms, not adoption of a third-party graph library; see
	native/nwgraph.c's own header for the full account). Deliberately
	mirrors unw_ergm.do's own ErgmNativeInstallDir()/
	ErgmNativePluginSubdir()/ErgmNativePluginPath()/ErgmNativeAvailable()
	pattern exactly (same platform-detection logic, same graceful-
	fallback contract - never errors, only ever returns 0/"" when a
	platform's own plugin binary is absent), generalized here to live in
	unw_core.do (rather than duplicated per calling command) since more
	than one future native graph kernel can share this single dispatcher
	and the one shared `nwgraph.plugin`/`nwgraph_unix.plugin` binary -
	unlike nwergm's own ErgmNative* functions, which only ever needed to
	locate exactly one plugin name and were never generalized.
*/
string scalar NativeGraphInstallDir(){
	string scalar full, dir, fn

	full = findfile("nwset.ado")
	if (full == "") return("")
	pathsplit(full, dir, fn)
	return(dir)
}

string scalar NativeGraphPluginSubdir(){
	string scalar os

	os = st_global("c(os)")
	if (os == "Windows") return("windows")
	if (os == "Unix") return("unix")
	return("macos")
}

string scalar NativeGraphPluginFilename(){
	if (st_global("c(os)") == "Unix") return("nwgraph_unix.plugin")
	return("nwgraph.plugin")
}

string scalar NativeGraphPluginPath(){
	string scalar dir

	dir = NativeGraphInstallDir()
	if (dir == "") return("")
	return(pathjoin(pathjoin(dir, "lib"),
		pathjoin("plugins", pathjoin(NativeGraphPluginSubdir(), NativeGraphPluginFilename()))))
}

real scalar NativeGraphAvailable(){
	string scalar p

	p = NativeGraphPluginPath()
	if (p == "") return(0)
	return(fileexists(p))
}

/*
	Native betweenness centrality (Brandes 2001, unweighted/dichotomized -
	the same scope as calculate_betweenness() above; the weighted
	Dijkstra-based mode remains Mata-only, a documented follow-on).
	Marshals the tie list to native/nwgraph.c's own ALG_BETWEENNESS
	kernel via a single `plugin call' (one call per invocation, not per
	node/edge - the same boundary-crossing discipline nwergm's own native
	backend uses) and reads back one betweenness score per node.
	CALLER'S RESPONSIBILITY: check NativeGraphAvailable() first - this
	function does not itself fall back to Mata, matching
	calculate_betweenness_weighted()'s own "one function, one job"
	convention; nwbetween.ado's own dispatch decides which to call.
*/
real matrix `NWdef'::calculate_betweenness_native(){
	real matrix ties
	real scalar n, nties, nobs_needed, __junk
	string scalar origframe, argstr, cmd

	real colvector Cb

	n = get_nodes()
	// edgelist() stores an undirected tie SYMMETRICALLY (both (i,j) and
	// (j,i) rows already present - see its own header comment and
	// docs/SPARSE_BACKEND.md) - native/nwgraph.c's own adjacency
	// construction therefore never auto-adds a reverse edge itself (that
	// would double it for undirected networks); `isdirect' below is
	// passed through purely for the FINAL undirected-halving step,
	// matching calculate_betweenness()'s own identical halving. Ties
	// with weight <= 0 are excluded, matching calculate_betweenness()'s
	// own `edge_weight(m,n)>0' filter on signed networks.
	ties = edgelist()
	if (rows(ties) > 0) ties = select(ties, ties[.,3] :> 0)
	nties = rows(ties)

	origframe = st_framecurrent()
	stata("capture frame drop __nwgraph_native")
	stata("frame create __nwgraph_native")
	st_framecurrent("__nwgraph_native")

	nobs_needed = max((n, nties, 1))
	st_addobs(nobs_needed)
	// BUGFIX: st_addvar() returns the new variable's column index - a
	// bare (uncaptured) call makes Mata auto-display that return value
	// as an unrequested integer, exactly like any other uncaptured
	// top-level Mata expression. Masked here in ordinary use only
	// because nwbetween.ado's own call site is inside a `qui foreach'
	// block (confirmed directly: calling this method outside any qui
	// context prints "1 2 3" before doing anything else) - the
	// identical bug in unw_ergm.do's ErgmNativeSampleCore() was NOT
	// masked (no qui wraps nwergm.ado's own MCMLE call site), which is
	// what actually surfaced this for a user. Fixed here too, not just
	// where it happened to be visible.
	__junk = st_addvar("double", "v1")
	__junk = st_addvar("double", "v2")
	__junk = st_addvar("double", "v3")

	if (nties > 0) st_store((1::nties), ("v1","v2"), ties[.,(1,2)])

	argstr = strofreal(1) + " " + strofreal(n) + " " + strofreal(isdirect) + " " + strofreal(nties)

	// see ErgmNativeSampleCore()'s own identical comment (unw_ergm.do) on
	// why redefining an already-loaded plugin-type program is left in
	// place rather than dropped first.
	stata("capture program nwgraph_native, plugin using(" + char(34) + NativeGraphPluginPath() + char(34) + ")")
	cmd = "plugin call nwgraph_native v1 v2 v3, " + char(34) + argstr + char(34)
	stata(cmd)

	Cb = st_data((1::n), "v3")

	st_framecurrent(origframe)
	stata("capture frame drop __nwgraph_native")

	return(Cb)
}


void `NWdef'::clean_matrix_2mode(){
	real matrix z
	// General validation-stage finding (see docs/CERTIFICATION.md): this
	// method reads/writes `edge' directly with no dense guard, unlike
	// every other such method in this class. Its one live caller
	// (nw2fromedge.ado) happens to always call symmetrize() first (via
	// its own hardcoded `undirected' nwsym step), which itself already
	// calls ensure_dense_built() - so this was "accidentally safe" by
	// caller convention, not by design. Guarded explicitly here so it is
	// actually safe for any future caller, not just the current one.
	ensure_dense_built()
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

void `NWdef'::set_provenance(string scalar note){
	provenance = note
}

string scalar `NWdef'::get_provenance(){
	return(provenance)
}

void `NWdef'::set_temporal(real scalar d){
	istemporal = d
}

real scalar `NWdef'::is_temporal_boolean(){
	// BUGFIX: an uninitialized `real scalar' class field defaults to
	// Mata missing (.), not 0 - confirmed via a direct probe
	// (`class{real scalar flag}; t=cls(); if(t.flag) printf("truthy")'
	// prints "truthy" for a never-set field) - so a bare `if(istemporal)'
	// would report EVERY ordinary, never-declared-temporal network as
	// temporal, since `.' is truthy in Mata. Matches the existing,
	// already-correct is_2mode()'s own `is2mode == 1' convention -
	// mirrored here rather than inventing a second pattern.
	return(istemporal == 1)
}

string scalar `NWdef'::is_temporal(){
	if (istemporal == 1) return("true")
	return("false")
}

void `NWdef'::set_temporal_type(string scalar t){
	temporaltype = t
}

string scalar `NWdef'::get_temporal_type(){
	return(temporaltype)
}

void `NWdef'::set_timevar(string scalar s){
	timevar = s
}

string scalar `NWdef'::get_timevar(){
	return(timevar)
}

void `NWdef'::set_startvar(string scalar s){
	startvar = s
}

string scalar `NWdef'::get_startvar(){
	return(startvar)
}

void `NWdef'::set_endvar(string scalar s){
	endvar = s
}

string scalar `NWdef'::get_endvar(){
	return(endvar)
}

void `NWdef'::set_eventtimevar(string scalar s){
	eventtimevar = s
}

string scalar `NWdef'::get_eventtimevar(){
	return(eventtimevar)
}

void `NWdef'::set_edge_time(real matrix m){
	edgetime = m
}

pointer(real matrix) `NWdef'::get_edge_time(){
	return(&edgetime)
}

void `NWdef'::set_edge_interval(real matrix s, real matrix e){
	edgestart = s
	edgeend = e
}

pointer(real matrix) `NWdef'::get_edge_start(){
	return(&edgestart)
}

pointer(real matrix) `NWdef'::get_edge_end(){
	return(&edgeend)
}

void `NWdef'::set_eventlist(real matrix m){
	eventlist = m
}

pointer(real matrix) `NWdef'::get_eventlist(){
	return(&eventlist)
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

	// sparse-native networks (edge_dense_built==`False') never populate
	// `edge' - without this, keep_nodes()/drop_nodes() silently operated
	// on an empty/stale dense matrix for such networks. Found while
	// building the induced-subgraph primitive for nwcohesion (harmonisation
	// unit 59) - every other dense-touching method already guards with
	// this same call (see e.g. check_symmetry() above).
	ensure_dense_built()

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

/*
	Return a fresh, unregistered NWdef instance holding the induced
	subgraph on the nodes selected by `k' (a 0/1 rowvector, one entry per
	node of the CALLING network, same convention as keep_nodes()) -
	unlike keep_nodes()/drop_nodes(), which mutate the instance they are
	called on, this leaves the calling network completely untouched and
	hands back a standalone copy suitable for recursive algorithms (e.g.
	nwcohesion's Moody-White hierarchy, nwego's induced ego-network
	extraction) that need to keep re-deriving further subgraphs from the
	ORIGINAL network at each step. The returned instance is never added
	to the network store (`nw.nws' names/pdefs) - it exists only as long
	as the caller holds the pointer, so purely-internal recursive use
	never pollutes the user-visible named-network namespace. set_selfloop()
	is called before set_edge() (the reverse of `NWsdef'::duplicate()'s
	order) because set_edge()'s own diagonal-handling reads
	is_selfloop_boolean() at the time it runs.
*/
pointer(class `NWdef' scalar) scalar `NWdef'::extract_subgraph(rowvector k){
	pointer(class `NWdef' scalar) scalar sub

	ensure_dense_built()
	sub = &(`NWdef'())
	sub->set_name(get_name() + "_sub")
	sub->set_selfloop(is_selfloop_boolean())
	sub->set_directed(is_directed_boolean())
	sub->set_valued(is_valued_boolean())
	sub->set_2mode(is_2mode_boolean())
	sub->set_edge(get_matrix_copy())
	sub->set_nodenames(get_nodenames())
	if (is_2mode_boolean() == 1){
		sub->set_modes(get_modes())
	}
	sub->set_nodesvar(get_nodesvar())
	sub->set_label(get_label())
	sub->set_caption(get_caption())

	sub->keep_nodes(k)

	return(sub)
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
	ensure_dense_built()
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
	ensure_dense_built()
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
	// General validation-stage finding (see docs/CERTIFICATION.md): no
	// live caller currently exists (confirmed via grep), but this method
	// read/wrote `edge' directly with no dense guard, unlike every other
	// dense-touching method in this class - would silently index into an
	// empty/wrong-sized matrix for a sparse-natively-built network.
	ensure_dense_built()
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
	// General validation-stage finding (see docs/CERTIFICATION.md): this
	// method's only live caller is nwaddnodes.ado, already documented as
	// broken for an unrelated reason (see CERTIFICATION.md's own Pending
	// row) - but it read/wrote `edge' directly with no dense guard,
	// unlike every other dense-touching method in this class, and would
	// have silently concatenated onto an empty/wrong-sized matrix for a
	// sparse-natively-built network regardless of that unrelated bug.
	ensure_dense_built()
	size = cols(nodes)
	nodes = (nodes, s)
	nodesvar = (nodesvar, strtoname(s))
	edge = (edge, J(size, 1, 0)\J(1, size+1, 0))
	sparse_built = `False'
	// `modes' was never extended here - genuinely harmless while `modes'
	// itself is still empty (get_modes()'s own lazy-init sizes it fresh
	// off get_nodes() on first read, whenever that happens), but once
	// modes had ALREADY been populated (e.g. by an earlier nwset() call)
	// this left it permanently undersized relative to `nodes' - any
	// later get_modes_labeled_string() call (nwsummarize, nwsync, ...)
	// then indexes past its end and errors "subscript invalid" (3301).
	// Found via a real, previously-masked bug: nwaddnodes.ado used to
	// always auto-call nwload() right after add_node(), and nwload's own
	// chain happened to rebuild `modes' from scratch as a side effect,
	// silently papering over the undersized array - once nwaddnodes
	// stopped auto-loading by default (the xvars-consistency unit), the
	// latent bug in add_node() itself finally surfaced. New nodes default
	// to mode "1", the same single-mode default get_modes() itself uses.
	if (cols(modes) > 0) {
		modes = (modes, "1")
	}
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
	// General validation-stage finding (see docs/CERTIFICATION.md): this
	// debug-only dump (invoked manually, e.g. `nw.nws.dumper()`, no .ado
	// command calls it) read `edge' directly with no dense guard - would
	// have silently printed "no edges" for every node on a sparse-
	// natively-built network instead of erroring or reflecting reality.
	ensure_dense_built()
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
	pointer(class nw_def scalar) scalar pcurrent
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
