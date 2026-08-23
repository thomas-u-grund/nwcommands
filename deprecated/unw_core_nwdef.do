mata: 
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
TODO:
	modes is not handled yet 
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
//!! methods:

	void symmetrize()
	void create() 
	void create_by_name()
	void init_edge()

	string scalar get_name()
	real scalar get_nodes()
	string matrix get_nodenames()
	string matrix get_nodesvar()
	string scalar get_nodesvar_string()

	string matrix get_edgelist()
	string matrix get_edgelist_compressed()
	real matrix get_outdegree()
	real matrix get_indegree()
	string matrix get_modes()
	
	pointer(real matrix) get_matrix()
	pointer(real matrix) get_matrix_unvalued()
	real matrix get_matrix_copy()
	real matrix get_matrix_unvalued_copy()
	real matrix get_adjlist()
	
	string scalar is_selfloop()
	string scalar is_valued()
	string scalar is_directed()
	string scalar is_2mode()
	real scalar is_selfloop_boolean()
	real scalar is_valued_boolean()
	real scalar is_directed_boolean()
	real scalar is_2mode_boolean()
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
	real matrix calculate_betweenness()
	//real matrix calculate_betweennessWeighted()
	real matrix calculate_components()
	real matrix calculate_lgc()
	real matrix calculate_clustering()
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

real scalar `NWdef'::check_valued(){
	real scalar mi, ma
	mi = min(*get_matrix())
	ma = max(*get_matrix())
	
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
			alters = select(id, ((*get_matrix_unvalued())[i,] :+ ((*get_matrix_unvalued())[,i])':!=0)')
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
			alters = select(id, ((*get_matrix_unvalued())[i,])')
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
			alters = select(id, ((*get_matrix_unvalued())[i,])')
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
			alters = select(id, ((*get_matrix_unvalued())[i,])')
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
			alters = select(id, ((*get_matrix_unvalued())[i,])')
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

real matrix `NWdef'::calculate_components(){
	real scalar ncomp
	real scalar next
	real scalar i
	real matrix visited
	real matrix comp 	
	real matrix bfs_queue
	real matrix bfs_next
	real scalar numnodes
	pointer(real matrix)  nw
	
	nw = get_matrix()
	numnodes = cols(nodes)
	visited = J(numnodes,1,0)
	comp  = J(numnodes,1,0)
	ncomp = 1
	next = 1 
	
	// as long as not everybody has been visited
	while (sum(visited) != numnodes){
			// find next not visited node
			while (visited[next,1]==1) {
				next = next + 1
			}

			// perform bfs from next and visit everybody reachable
		    // assign component id
			// increment component id	
			visited[next,1]=1
			comp[next,1]=ncomp
			bfs_queue = (*nw)[next,] :+ ((*nw)[,next])'

			bfs_next = J(1, numnodes,0)
			while (sum(bfs_queue)>0) {
				for (i = 1 ; i<=numnodes ; i++) {
					if (bfs_queue[1,i]>= 1) {
				    		bfs_queue[1,i]=0
				    		if (visited[i,1]==0){
				    			visited[i,1]=1		
								comp[i,1]=ncomp
				    			bfs_next = bfs_next + (*nw)[i,] :+ ((*nw)[,i])'
							}
					}
				}
				for (i = 1; i<=numnodes ; i++){
					if (bfs_next[1,i]>0 & visited[i,1]==0) {
						bfs_queue[1,i]=1
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

void `NWdef'::permute(){
	real matrix perm
	perm = unorder(get_nodes())
	set_edge((*get_matrix())[perm, perm])
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
real matrix `NWdef'::calculate_betweenness_weighted(){
	real matrix P 
	real scalar n,i
	
	n = get_nodes()
	for (i = 1, i 
}*/

/*
real matrix calculate_betweenness_weighted_node(real scalar node){
	real matrix P, adjlist, B
	real scalar n, i, nx, k

	n = get_nodes()
	nx = n + 2
	B = J(n,1,.)
	adjlist = get_adjlist()
	P = single_source_dijkstra(adjlist, node)
	k = node
	for (i = 1; i<= n; i++){
		
	}
}*/

real matrix `NWdef'::calculate_betweenness(){
	real matrix adjacencyList, Cb,Stack,P,nP, S, D, Queue, Dd
	real scalar m, k, n, s, v, j, w
	
	adjacencyList=J(get_nodes(),get_nodes()-1,.)
	for (m=1; m<=get_nodes(); m++) {
		k=1
		for (n=1; n<=get_nodes(); n++) {
			if ( m!=n & (*get_matrix())[m,n]>0){
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
				"D"
		D
		"P"
		P
		"S"
		S
		
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
	return(Cb')
}


void `NWdef'::clean_matrix_2mode(){
	real matrix z
	z = ((J(get_nodes(),1, modes):== J(1,get_nodes(), modes')):== 1)
	_editvalue(z, 1, .)
	edge = edge :+ z
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
}

real matrix `NWdef'::get_indegree(real scalar alpha){
	real scalar s, k
	s = colsum(*get_matrix(),0)
	k = colsum(*get_matrix_unvalued(),0)
	return(editmissing((	(k :* ((s :/ k) :^ alpha))'),0))
}

real matrix `NWdef'::get_outdegree(real scalar alpha){
	real scalar s, k
	s = rowsum(*get_matrix(),0)
	k = rowsum(*get_matrix_unvalued(),0)
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
			if (nodesvar[i] == nodesvar[j]){
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
	Set name property
*/
void `NWdef'::set_name(string scalar s) {
	name = s 
}

/* 
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
}

/*
	Get a copy of the edge matrix
*/
real matrix `NWdef'::get_matrix_copy() {
//!! generate edge matrix based on edgetype
	real matrix e
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
	e = (edge:!= 0 :& edge :!= .)
	return(e)
}


/*
	Get pointer to edge matrix
*/
pointer(real matrix) `NWdef'::get_matrix(){
	return(&edge)
}

/*
	Get pointer to unvalued edge matrix
	and replace missings with zeros
*/
pointer(real matrix) `NWdef'::get_matrix_unvalued(){
	if (is_valued()== "false"){
		return (&edge)
	}
	else {
		return(&((edge:!=0 :& edge:!=.) :+ ((edge:==.) :* edge)))
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
    null = (null * (null - 1)) - asym - mutual

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
end



