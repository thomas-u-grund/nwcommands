# Command Language Audit

Living document. Part I-VII deliverable of the interface/syntax/network-type/documentation/dialog/
repository harmonisation phase (started 2026-08-21). Raw material for `NWCOMMANDS_COMMAND_STYLE.md`
and the network-type compatibility matrix. Gathered via four parallel read-only audit passes over
the full public command surface (~127 `nw*` commands) plus the pre-existing `netname.sthlp`/
`netlist.sthlp` conceptual documentation.

## Headline finding: the netname/netlist standard already exists and is sound

Before auditing individual commands, the existing `netname.sthlp`/`netlist.sthlp` pair was read in
full. **The package already has a well-designed, cross-referenced, Stata-idiomatic standard**:

- **`netname`**: exactly one network. Supports the same wildcard abbreviation syntax as `netlist`
  (`*`, `~`, `?`, `-`, `_all` — implemented by delegating to Stata's own built-in `unab` command via
  `nw_unab.ado`, confirmed working by direct test, not just documented) but must resolve to exactly
  one match — the same relationship Stata's own `varname` has to `varlist`.
- **`netlist`**: one or more networks, full wildcard/range/`_all` support.
- **Current-network fallback**: "For most network commands a netname is optional. When no netname
  is explicitly specified the most current network is used" — already the documented, intended
  default.

This is **not a case of inventing a new standard from scratch**. The task is to verify the ~127
commands actually and consistently *implement* this pre-existing standard, and fix the ones that
don't — per the harmonisation brief's own instruction not to assume differences are mistakes
without checking, this matters: several apparent "inconsistencies" below are not bugs, they are
genuinely different, deliberate semantics (see the Type-C role-specific commands).

## Command classification (netname / netlist / role-specific / none)

Derived from four parallel audits covering data-management (40 commands), analysis/statistics (30
commands), generator/IO/visualisation (37 commands), plus this session's own prior work on
newly-added commands (`nwkcore`, `nwaltergen`, `nwsimindex`, `nwcug`, `nw2project`, `nwburt`).

### Type A — `netname` (exactly one network)

The large majority of analytical and single-network-transform commands: `nwbetween`, `nwbridges`,
`nwclustering`, `nwconstraint`, `nwevcent`, `nwgeodesic`, `nwkatz`, `nwmixing`, `nwpath`, `nwreach`,
`nwtriads`, `nwtranspose`, `nwsym`, `nwaddnodes`, `nwdropnodes`, `nwduplicate`, `nwsubset`,
`nwreplacemat`, `nwnoderename`, `nwutility`, `nwvalue`, `nwplot`, `nwplotjs`, `nwplotmatrix`,
`nwmovie`, `nwshared`, `nwsimmelian`, `nwsync`, `nwcurrent`, `nwname`, `nwnode`, `nw2clustering`, and
others.

### Type B — `netlist` (loops over N networks independently)

Confirmed via an actual multi-network internal loop (not just a local variable named "netlist"):
`nwcloseness`, `nwdrop`/`nwkeep` (in their `max(9999)` code paths), `nworder` (operates on `_all`),
`nwds`, `nwrecode`, `nwtoedge`/`nw2toedge`, `nwsave` (all networks), `nwrename` (bulk rename via
Stata's own `rename` syntax).

**`nwdegree` and `nwbetween` were both miscategorised in their own documentation**: both `.sthlp`
files described multi-network ("z networks at once") behaviour with an implied output-naming
convention (e.g. `_outdegree_z`), but neither command actually looped over multiple networks — each
processed exactly one network per call, despite `nwdegree`'s code containing clear vestigial
scaffolding for an abandoned loop. This was a genuine doc/code mismatch, not a design choice.
**`nwdegree` fixed** (harmonisation phase, unit 6 — see `docs/CERTIFICATION.md`): implemented real
`netlist` support with `_<netname>`-suffixed output naming, rather than just correcting the docs to
admit the feature didn't exist, since `nwdegree` is this project's own canonical example of a
command where multi-network semantics are genuinely useful. `nwbetween` has the same doc claim and
the same gap, not yet fixed — see Pending below.

### Type C — multiple role-specific `netname`s (not a generic netlist)

Confirmed genuinely different-semantics commands, correctly *not* netlist-shaped:
- `nwcorrelate` — three call shapes (one netname for node-attribute correlation; two netnames for
  network-vs-network correlation; netname+`attribute()`).
- `nwqap` — a "formula" positional argument in the spirit of `regress y x1 x2`: one DV network, one
  or more IV networks/variables, each playing a distinct role.
- `nwappend` — current dataset plus a `using` file, a file-append idiom, not netname/netlist at all.
- `nwexpand` — primary positional argument is a *Stata variable*, with the network supplied via a
  separate `network()` option; a legitimate secondary-role reference, correctly distinct from
  `netname`. This is the canonical pattern for "this command's main subject isn't a network, but it
  needs one for context" and should be documented as such in the style standard, not "fixed."

### Type D — no explicit network argument

Generators that *create* a network rather than operate on an existing one (`nwset`, `nwrandom`,
`nwpref`, `nwring`, `nwsmall`, `nwlattice`, `nwfromedge`, `nw2fromedge`, `nw2set`, `nwhomophily`,
`nwdyadprob`), plus pure utility/state commands (`nwclear`, `nwcompressobs`, `nwpreserve`,
`nwrestore`, `nwtostata`, `nwunab`).

## Cross-cutting inconsistencies found (Part I "same concept, different syntax")

1. **`mode()` terminology collision**: `nwneighbor`'s `mode()` accepts `outgoing|incoming|either`;
   `nwcontext`'s `mode()` accepts `incoming|outgoing|both` — for the literal same semantic concept
   (union of both tie directions). "either" vs "both" is a real, fixable inconsistency, not
   historical drift with distinct meaning. **Action**: standardise on one term (see style standard).
2. **`alpha` means two unrelated things**: in `nwdegree` it exponentiates a *strength ratio*
   (Opsahl et al. generalized degree, `k_i*(s_i/k_i)^alpha`); in `nwkatz` it exponentiates a
   *distance* (`sum(alpha^dist(i,j))`, which — separately — is not actually canonical Katz
   centrality despite the name and citation; true Katz is `(I - alpha*A)^-1`, an eigenvector-family
   measure, not a path-distance sum). Same option name, incompatible semantics *and* a possible
   correctness issue in `nwkatz` independent of the naming collision. **Action**: `nwkatz` needs a
   documentation correction at minimum (flag that it computes a distance-decay measure, not
   canonical Katz centrality) and ideally a real Katz implementation as a separate, correctly-named
   addition later; the `alpha` collision itself should be called out explicitly in the style
   standard as "same name does not imply same meaning here — document per-command."
3. **`generate()` has two legitimately different meanings**: in the data-management group
   (`nwaddnodes`/`nwdropnodes`/`nwtranspose`/`nwsym`/`nwkeepnodes`) it means "save the result as a
   new **network**" (in-place-modify is the default; `generate()` opts into a copy); in analytical
   commands elsewhere it names a new **Stata variable**. These should be documented as two
   deliberately distinct, well-established conventions, not collapsed into one.
4. **Architecture split**: `nwcloseness`, `nwqap`, `nworder`, and (fixed earlier this session)
   `nwdissimilar`/`nwsimilar`/`nwhierarchy`/`nwtomatafast` still use the legacy `_nwsyntax`/
   `nwtomatafast` idiom instead of modern `nw_syntax`. Not purely cosmetic — `nwtomatafast` was
   found to be **actually broken** by this reliance (see `docs/CERTIFICATION.md`), so this list is a
   real risk register, not just a style nit.
5. **Two `r()`-return idioms coexist**: commands added/touched this session (`nwkcore`, `nwcug`,
   `nwsimindex`, `nw2project`, `nwaltergen`) use `program X, rclass` + `return scalar`; the vast
   majority of older commands instead do `mata: st_rclear()` + `mata: st_numscalar("r(x)", ...)`
   manually. Both work; the style standard should state which is canonical going forward
   (recommendation: `rclass`/`return scalar` for new/touched commands — it is what Stata's own
   documentation recommends and what `nw_helpwriter`-certified commands already use — while not
   forcing a mechanical rewrite of every untouched legacy command purely for this reason).
6. **`r()`-return documentation drift**: `nwpath`'s `.sthlp` claims `r(paths)`, `r(path_shortest)`,
   `r(ego)`, `r(alter)`, `r(paths_matrix)` — the actual code only sets `r(num_paths)` and
   `r(path_length)`. A genuine doc/code mismatch, not a design choice.

## Network-type compatibility highlights (full matrix: see below)

The single most-cited "model example" of correct network-type handling found in this audit:
**`nwclustering`** — explicitly errors ("not defined for networks that are both weighted and
directed" without `symmetrize`), explicitly checks `is2mode` and auto-redirects to `nw2clustering`
with a clear message, and exposes an explicit `measure()` option for weighted-vs-binary choice
rather than silently picking one. This should be the template referenced when fixing other commands.

Commands most likely to be silently mishandling weights or two-mode data (highest-value follow-up
targets, per the four audits' own flagged findings):

- **`nwconstraint`** — zero documentation of directed/two-mode behaviour despite being
  weight-driven by construction (row-normalizes the adjacency matrix); a user has no way to know
  what it assumes.
- **`nwqap`** — silently dichotomizes any weighted DV/IV network with no weighted alternative and
  no warning, despite being the flagship network-regression candidate (already a known roadmap
  item, now confirmed at the code level).
- **`nwtriads`** — computes a directed-only 16-type MAN triad census with no guard when given an
  undirected network (several census categories, e.g. 021D/030T, are meaningless for undirected
  data).
- **`nwkatz`** — see #2 above; a correctness issue, not just a naming one.
- **`nwdyadprob`** — auto-installs external packages (`gsample`/`moremata`) from the internet at
  runtime; flagged as a dependency/security concern for the harmonisation's Part XXXVII, separate
  from network-type handling.

Full per-command table available in the three source audit transcripts (data-management,
analysis/statistics, generator/IO/visualisation) referenced in this session's task history; a
consolidated compatibility matrix (Part VII table: Command | Binary | Directed | Weighted class |
Weight meaning | Signed | Two-mode class | Mode selection | Projection required | Notes) is being
built incrementally as each command is actually re-verified against its code, rather than
transcribed wholesale from the audit passes without independent confirmation — see
`docs/NETWORK_TYPE_MATRIX.md`.
