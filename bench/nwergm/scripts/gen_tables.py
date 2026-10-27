# Builds tab_compare.tex (estimates, ergm vs nwergm) and tab_bench.tex (timing) from the CSV files written by
# cmp_ergm.R / cmp_nwergm.do and bench_ergm.R / bench_nwergm.do.
import csv, collections, statistics as st, os, sys
os.chdir(os.path.dirname(os.path.abspath(__file__)))

def load(f):
    d = collections.OrderedDict()
    for r in csv.DictReader(open(f)):
        d.setdefault((r['model']), collections.OrderedDict()).setdefault(r['term'], []).append(r)
    return d

def tex(s):
    return s.replace('_', r'\_').replace('~', r'$\sim$')

LABEL = collections.OrderedDict([
    ('toy', ('5-node directed network, MCMLE (10 seeds)', ['edges', 'mutual'])),
    ('flo_mple', ('Florentine marriages, MPLE', ['edges', 'nodematch(seat)', 'nodecov(wealth)'])),
    ('flo_gwesp', ('Florentine marriages, MCMLE (10 seeds)', ['edges', 'nodematch(seat)', 'gwesp(.5)'])),
    ('lazega_dindep', ('Lazega advice, MPLE', ['edges', 'nodematch(office)', 'nodematch(practice)', 'nodeofactor(status=2)', 'nodeifactor(status=2)'])),
    ('lazega_final', ('Lazega advice, MCMLE (5 seeds)', ['edges', 'mutual', 'nodematch(office)', 'nodematch(practice)', 'nodeofactor(status=2)', 'nodeifactor(status=2)', 'gwesp(.5)'])),
    ('lazega_sym', ('Lazega friendship, operator (see text)', ['edges', 'mutual', 'nodematch(practice)', 'Symmetrize(strong)~triangle'])),
    ('davis', ('Southern women, two-mode MCMLE (10 seeds)', ['edges', 'b1factor(title=2)', 'gwb2degree(1)'])),
    ('mesa_gwesp', ('Faux Mesa High, MCMLE (5 seeds)', ['edges', 'nodematch(grade)', 'nodematch(race)', 'gwesp(.25)'])),
    ('mesa_curved', ('Faux Mesa High, curved gwesp (see text)', ['edges', 'nodematch(grade)', 'nodematch(race)', 'gwesp weight', 'gwesp decay'])),
])

def fmt(x, n=3):
    t = f"{x:.{n}f}"
    return t[1:] if t.startswith('-') and float(t) == 0 else t

def compare():
    R = load('cmp_ergm.csv'); S = load('cmp_nwergm.csv')
    out = []
    out.append(r"\begin{table}[htbp]")
    out.append(r"\centering\footnotesize")
    out.append(r"\caption{Coefficients of \texttt{ergm} 4.12.0 and \texttt{nwergm} 1.3.0 on the same networks, default settings. Mean over seeds (standard deviation over seeds in parentheses); $\Delta$ is the difference of the means in units of the standard error that \texttt{ergm} reports.\label{tab:compare}}")
    out.append(r"\begin{tabular}{@{}lrrrrr@{}}")
    out.append(r"\toprule")
    out.append(r" & \multicolumn{2}{c}{\texttt{ergm}} & \multicolumn{2}{c}{\texttt{nwergm}} & \\")
    out.append(r"\cmidrule(lr){2-3}\cmidrule(lr){4-5}")
    out.append(r"Term & mean & (sd) & mean & (sd) & $\Delta$ \\")
    out.append(r"\midrule")
    summary = []
    for m, (title, names) in LABEL.items():
        if m not in R or m not in S: continue
        rterms0 = list(R[m].keys()); sterms = list(S[m].keys())
        if len(rterms0) != len(sterms):
            print("term count mismatch", m, rterms0, sterms); continue
        import re
        norm = lambda x: re.sub(r'[^a-z0-9]', '', x.lower())
        rterms = [None] * len(sterms); left = list(rterms0)
        for j, sr in enumerate(sterms):
            for rt in left:
                if norm(rt) == norm(sr): rterms[j] = rt; left.remove(rt); break
        for j in range(len(rterms)):
            if rterms[j] is None: rterms[j] = left.pop(0)
        print(m, list(zip(sterms, rterms)))
        out.append(r"\multicolumn{6}{@{}l}{\textit{%s}} \\" % tex(title))
        for i, (rt, sr) in enumerate(zip(rterms, sterms)):
            rb = [float(r['b']) for r in R[m][rt]]; rse = [float(r['se']) for r in R[m][rt]]
            sb = [float(r['b']) for r in S[m][sr] if r['conv'] in ('1', '1.0')]
            nR, nS = len(rb), len(sb)
            rm = st.mean(rb); sm = st.mean(sb)
            rsd = st.stdev(rb) if nR > 1 else float('nan'); ssd = st.stdev(sb) if nS > 1 else float('nan')
            d = (sm - rm) / st.mean(rse)
            summary.append((m, names[i] if i < len(names) else sr, d))
            sdr = '' if nR < 2 else '(%s)' % fmt(rsd)
            sds = '' if nS < 2 else '(%s)' % fmt(ssd)
            lab = tex(names[i]) if i < len(names) else tex(sr)
            out.append(r"\quad %s & %s & %s & %s & %s & %s \\" % (lab, fmt(rm), sdr, fmt(sm), sds, fmt(d + 0.0, 2).replace('-0.00', '0.00')))
    out.append(r"\bottomrule")
    out.append(r"\end{tabular}")
    out.append(r"\end{table}")
    open('../tab_compare.tex', 'w').write("\n".join(out) + "\n")
    # numbers for the text
    byk = collections.defaultdict(list)
    for m, t, d in summary: byk[m].append(abs(d))
    for m, v in byk.items(): print(m, "max |Delta| = %.2f" % max(v))
    # seeds that did not converge / n per model
    for m in S:
        n = len(next(iter(S[m].values()))); nc = sum(1 for r in next(iter(S[m].values())) if r['conv'] not in ('1','1.0'))
        print("nwergm", m, "fits", n, "not converged", nc)
    for m in R:
        print("ergm", m, "fits", len(next(iter(R[m].values()))))

def bench():
    if not all(os.path.exists(f) for f in ('bench_ergm.csv', 'bench_nwergm.csv', 'bench_nwergm_123.csv')): return
    def ld(f):
        d = collections.OrderedDict()
        for r in csv.DictReader(open(f)): d.setdefault(r['bench'], []).append(r)
        return d
    R = ld('bench_ergm.csv'); S = ld('bench_nwergm.csv'); O = ld('bench_nwergm_123.csv')
    DESC = collections.OrderedDict([
        ('B1', '30 nodes, directed: edges, mutual'),
        ('B2', '100 nodes, directed: + nodematch'),
        ('B3', '100 nodes, undirected: edges, gwesp'),
        ('B4', '500 nodes, sparse, undirected: + nodematch, gwesp'),
        ('B5', '1000 nodes, directed: edges, mutual, nodematch'),
        ('B6', '1000 nodes, sparse, undirected: edges, gwesp, gwnsp'),
        ('Lazega', 'Lazega advice, 71 nodes: seven terms'),
        ('Mesa', 'Faux Mesa High, 205 nodes: gwesp(.25)')])
    out = []
    out.append(r"\begin{table}[htbp]\centering\small")
    out.append(r"\caption{Median time of five fits (seeds 1 to 5) of \texttt{ergm} 4.12.0 and of \texttt{nwergm} 1.2.3 and 1.3.0 on identical networks, default settings; ratio of the medians of \texttt{nwergm} 1.3.0 and \texttt{ergm}; Monte Carlo iterations in the five fits (minimum to maximum).\label{tab:bench}}")
    out.append(r"\begin{tabular}{@{}lrrrrcc@{}}\toprule")
    out.append(r"Benchmark & \texttt{ergm} (s) & 1.2.3 (s) & 1.3.0 (s) & ratio & \texttt{ergm} it. & 1.3.0 it. \\\midrule")
    for k, desc in DESC.items():
        if k not in R or k not in S or k not in O: continue
        rt = [float(r['secs']) for r in R[k]]; sT = [float(r['secs']) for r in S[k]]; oT = [float(r['secs']) for r in O[k]]
        ri = [float(r['iter']) for r in R[k] if r['iter'] not in ('NA', '')]; si = [float(r['iter']) for r in S[k] if r['iter'] not in ('NA', '', '.')]
        def rng(v): return ('%d' % min(v) if min(v) == max(v) else '%d--%d' % (min(v), max(v))) if v else '--'
        def f2(x): return fmt(x, 2) if x < 1 else fmt(x, 1)
        out.append(r"%s & %s & %s & %s & %s & %s & %s \\" % (tex(desc), f2(st.median(rt)), f2(st.median(oT)), f2(st.median(sT)), fmt(st.median(sT) / st.median(rt), 2), rng(ri), rng(si)))
    out.append(r"\bottomrule\end{tabular}\end{table}")
    open('../tab_bench.tex', 'w').write("\n".join(out) + "\n")

if __name__ == '__main__':
    if os.path.exists('cmp_nwergm.csv'): compare()
    bench()
