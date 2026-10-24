# Generates cscripts/test_nwergm_bip.do from the R reference (Rref.csv from bip_ref.R) and the three test networks.
# usage: python3 make_bip_test.py <refdir> <spec1> <spec2> <out.do>
import csv, sys, math
ref, specs, out = sys.argv[1], sys.argv[2:-1], sys.argv[-1]
rows = list(csv.DictReader(open(ref + "/Rref_all.csv")))
sp = {}
for f in specs:
    for l in open(f):
        l = l.rstrip("\n")
        if l: i, r, s = l.split("|"); sp[i] = (r, s)
nets = {}
for n in "ABC":
    e = list(csv.DictReader(open(f"{ref}/bip{n}_edges.csv"))); v = list(csv.DictReader(open(f"{ref}/bip{n}_nodes.csv")))
    nets[n] = (int(v[0]["n1"]), len(v), [(int(x["person"]), int(x["event"])) for x in e], v)
use = ["A", "B", "C"]
o = []
o.append("cscript\n\ndo unw_core.do\ndo unw_ergm.do\n")
o.append("* Cross-validation of the bipartite (two-mode) terms against R ergm 4.12.0 (tag bip).\n* For every case: the observed statistic (summary() in R) and, where R's pseudolikelihood is well identified, the MPLE coefficients and standard errors.\n* Constants were produced by dev/bip_ref.R (networks from dev/bip_gen.R); the Stata run is dev/bip_run.do.\n")
o.append("""capture program drop _bipcase
program define _bipcase
	args net opts nstat statlist blist selist
	capture noisily nwergm `net', edges `opts' method(mple)
	if _rc {
		di as err "FAIL (error) `net': `opts'"
		exit 9
	}
	mata: st_matrix("__sst", __nwergm_last_M.full_statistic(__nwergm_last_G))
	local ok = 1
	local k = 0
	foreach s of local statlist {
		local ++k
		if abs(__sst[1,`=`k'+1'] - `s') > 1e-4 * max(1, abs(`s')) local ok = 0
	}
	if colsof(__sst) != `nstat' + 1 local ok = 0
	if `ok' == 0 {
		di as err "FAIL (statistic) `net': `opts'"
		matrix list __sst
		exit 9
	}
	if "`blist'" != "" {
		matrix b = e(b)
		matrix V = e(V)
		local k = 0
		foreach x of local blist {
			local ++k
			local se : word `k' of `selist'
			if abs(b[1,`=`k'+1'] - `x') > 1e-4 | abs(sqrt(V[`=`k'+1',`=`k'+1']) - `se') > 1e-3 * max(1, `se') {
				di as err "FAIL (MPLE) `net': `opts'"
				matrix list b
				exit 9
			}
		}
	}
end

""")
for n in use:
    n1, nn, ed, v = nets[n]
    n2 = nn - n1
    o.append(f"* ---- network {n}: {n1} x {n2}\n")
    o.append(f"mata: B{n} = J({n2}, {n1}, 0)\n")  # transposed: nwset takes mode 1 from the matrix columns
    o.append("mata: pe%s = (%s)\n" % (n, "\\".join(str(x[0]) for x in ed)))
    o.append("mata: ev%s = (%s)\n" % (n, "\\".join(str(x[1]) for x in ed)))
    o.append(f"mata: for (k=1;k<={len(ed)};k++) B{n}[ev{n}[k],pe{n}[k]] = 1\n")
    o.append(f"nwset, mat(B{n}) bipartite name(bip{n}) nooutput\n")
    o.append("clear\nset obs %d\n" % nn)
    for c in ("g", "x", "h"):
        o.append("gen %s = .\n" % c)
        vals = [x[c] for x in v]
        o.append("mata: st_store(., \"%s\", (%s))\n" % (c, "\\".join(vals)))
    o.append(f"tempfile nodes{n}\nsave `nodes{n}'\n")
    o.append(f"use `nodes{n}', clear\n")
    cases = {}
    for r in rows:
        if r["net"] != n or r["rname"] == "ERROR" or r["id"] not in sp or r["id"] in ("l_transties", "l_cyclties") or (r["id"] == "coin" and n == "A"): continue
        cases.setdefault(r["id"], []).append(r)
    for cid, rs in cases.items():
        rs = [r for r in rs if r["rname"] != "edges"]
        if not rs: continue
        stats = [float(r["rstat"]) for r in rs]
        bs = [float(r["rb"]) if r["rb"] not in ("NA", "") else float("nan") for r in rs]
        ses = [float(r["rse"]) if r["rse"] not in ("NA", "") else float("nan") for r in rs]
        good = all(math.isfinite(b) and abs(b) < 8 and math.isfinite(s) and 0 < s < 50 for b, s in zip(bs, ses)) and len(rs) <= 12
        # x-based statistics are stored as float in Stata: relax by the statistic tolerance above
        bl = " ".join("%.7g" % b for b in bs) if good else ""
        sl = " ".join("%.7g" % s for s in ses) if good else ""
        o.append("_bipcase bip%s `\"%s\"' %d `\"%s\"' `\"%s\"' `\"%s\"'\n" % (n, sp[cid][1], len(rs), " ".join("%.8g" % s for s in stats), bl, sl))
    o.append("\n")
o.append("di as txt \"PASS test_nwergm_bip\"\n")
open(out, "w").write("".join(o))
