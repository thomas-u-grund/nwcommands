* loads a benchmark network from CSV into nwcommands (name bnet) and optionally attribute grp
capture program drop loadnet
program loadnet
    args file directed
    nwclear
    clear
    mata: loadcsv("`file'", `directed')
    nwset ego alter value, edgelist `=cond(`directed'==1,"directed","undirected")' name(bnet)
end
mata:
void loadcsv(string scalar f, real scalar directed)
{
    real matrix M
    string scalar ln
    real scalar fh, i, n, k, j
    real colvector eg, al, va
    fh = fopen(f, "r")
    M = J(0,0,.)
    i = 0
    while ((ln = fget(fh)) != J(0,0,"")) {
        i++
        if (i==1) {
            n = cols(tokens(subinstr(ln, ",", " ", .)))
            M = J(n,n,0)
        }
        M[i,.] = strtoreal(tokens(subinstr(ln, ",", " ", .)))
    }
    fclose(fh)
    n = rows(M)
    if (directed) k = n*(n-1); else k = n*(n-1)/2
    eg = J(k,1,.); al = J(k,1,.); va = J(k,1,.)
    k = 0
    for (i=1; i<=n; i++) for (j=1; j<=n; j++) {
        if (i==j) continue
        if (!directed & j<i) continue
        k++
        eg[k] = i; al[k] = j; va[k] = (M[i,j]!=0)
    }
    st_addobs(k)
    st_addvar("double", ("ego","alter","value"))
    st_store(., ("ego","alter","value"), (eg,al,va))
}
end
capture program drop loadattr
program loadattr
    args attrfile
    preserve
    quietly import delimited using "`attrfile'", clear varnames(nonames)
    mata: G = st_data(., "v1")
    restore
    quietly generate double grp = .
    mata: st_store((1::rows(G)), "grp", G)
end
