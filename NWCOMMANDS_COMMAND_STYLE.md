# nwcommands Command Design Standard

Authoritative developer reference for command syntax, network-argument semantics, and network-type
handling across the `nwcommands` package. Written 2026-08-21 as part of the interface/syntax/
network-type/documentation/dialog/repository harmonisation phase, derived primarily from patterns
already established across the package (see `docs/COMMAND_AUDIT.md` for the audit this is built
from), not invented from scratch. Existing, working, documented conventions take precedence over
theoretical elegance.

This document governs new and harmonised commands. It does not require every existing command to be
rewritten to match — see "Backwards compatibility" below.

## Command naming

- `nw` prefix for every public command. Two-mode-specific commands use `nw2` (`nw2project`,
  `nw2clustering`, `nw2set`, `nw2fromedge`, `nw2toedge`) — a deliberate, already-established
  sub-family, not an inconsistency to fix.
- Internal/helper commands not meant for direct end-user use are prefixed `_nw` or `nw_`
  (`_opts_oneof`, `nw_syntax`, `nw_validate`) — both prefixes are already in active use; treat them
  as interchangeable legacy variation, not something to unify, since renaming either would break
  every caller for no user-facing benefit.
- Do not rename an established public command merely because a cleaner name now seems available.
  Where a genuinely better name is warranted, add the better name as the primary command and keep
  the old name as a thin wrapper (see `nw2project`'s own precedent of superseding an
  undocumented gap, not renaming a working command).

## Network arguments: `netname` vs `netlist`

The package already has a complete, working, documented, Stata-idiomatic standard for this —
`{help netname}` and `{help netlist}` — confirmed correct and functional (including the `*`/`~`/`?`/
`-`/`_all` wildcard syntax, delegated to Stata's own built-in `unab` via `nw_unab.ado`). Use it.
Do not invent local terminology (`network`, `net`, `networkname`, `networks`, `network list`) in new
help files or option names.

**Decision rule** (Part III of the harmonisation brief, restated as policy):

- Use **`netname`** where the command logically operates on exactly one focal network (the large
  majority of analytical/transform commands: centrality, structural measures, single-network
  transforms).
- Use **`netlist`** only where applying the same operation independently to each of several
  networks has clear, useful, *already-implemented* semantics — verify the command actually loops
  over multiple networks (e.g. via `nw_syntax ..., max(9999)` + a `foreach`), not just that its
  local variable happens to be named `netlist`. A command whose `.sthlp` describes multi-network
  behaviour that the code doesn't implement (found twice in this audit — `nwdegree`, `nwbetween`)
  is a documentation bug, not a netlist command; fix the doc, or implement the loop, but do not
  paper over the mismatch.
- Use **multiple distinct role-specific network arguments** (not a generic `netlist`) where a
  command is inherently relational and each input plays a different role — `nwcorrelate` (node vs.
  network-vs-network vs. attribute modes), `nwqap` (DV network + IV networks/variables, in the
  spirit of `regress y x1 x2`). Do not collapse these into `netlist` merely for surface consistency;
  ambiguous output naming and role confusion are real costs, not just aesthetics.
- Use **an option, not the positional argument**, when the network is secondary context for an
  operation whose actual subject is something else — `nwexpand`'s primary argument is a Stata
  variable, with the network supplied via `network()`. This is the canonical pattern for "the
  command's subject isn't a network, but it needs one for context."
- **Current-network fallback**: already-established behaviour — when `netname` is omitted, use the
  current network (as set by `nwcurrent`, or implicitly by the most recent `nwset`/`nwload`/
  generator call). Preserve this; do not silently change it. Commands accepting `netlist` should
  default to the current network only, not automatically to `_all`, unless that is already their
  documented behaviour (a few, like `nwsave`, legitimately default to "everything").

## Output naming for multi-network (`netlist`) commands

Where a `netlist` command generates per-network output, the established convention (seen in
`nwrandom`'s `ntimes()` and referenced, but not implemented, in `nwdegree`/`nwbetween`'s stale docs)
is a **numeric or name suffix appended to the base output name**: `name_1`, `name_2`, ... for
anonymous batches, or `basevar_<netname>` where the network name itself is a meaningful suffix. Do
not invent a different collision-avoidance scheme per command. If a `netlist` command cannot name
its multiple outputs predictably and unambiguously, it is a signal the command should be `netname`
-only instead (see the decision rule above) — do not force multi-network support onto a command
whose output shape doesn't cleanly support it.

## Network types: canonical treatment

### Directed

- `nosym` (boolean option, using Stata's built-in `no`-prefix convention: declaring `nosym` alone
  in the `syntax` line, checked via the base name `sym` in the body — confirmed this is correct
  Stata behaviour, not a bug, during this session's `nwevcent` work) is the established option name
  for "operate on the directed network as-is instead of auto-symmetrizing." Prefer this over
  inventing `directed`/`weak`/`strong` variants unless the command genuinely needs a third state.
- When a statistic requires symmetric input (e.g. `symeigensystem` for eigenvector centrality) and
  the network is directed, either auto-symmetrize by default with `nosym` as the documented opt-out
  (the established pattern), or error clearly if symmetrization would be scientifically
  inappropriate for that specific statistic — never silently produce a number without stating which
  happened.
- Mode selection for "which direction counts as a tie": standardise on **`outgoing` / `incoming` /
  `either`** (`nwneighbor`'s existing terms) over `nwcontext`'s `both` for the identical concept —
  found as a real inconsistency in this audit. New commands should use `either`; existing commands
  using `both` may keep it as a working legacy alias but should document `either` as the canonical
  term.
- For directed-network "neighbor" semantics specifically (not just tie-direction filtering), this
  session established two distinct, deliberate defaults depending on the *kind* of question — see
  `nw_programming.sthlp`'s "[NW-5.2]" section: **union of both directions** for undirected-sense
  structural questions (`nwkcore`, `nwsimindex`); **out-neighbors only** for directional
  influence/exposure questions (`nwaltergen`). Pick per new command based on which kind of question
  it answers, not by copying whichever convention happens to be closest.

### Weighted / valued

- **Never let weight semantics be silently ambiguous.** Every command touching a valued network must
  make one of these explicit, in code and in its `.sthlp`:
  - **W1** — implements a real, correct weighted formulation as its native/default behaviour.
  - **W2** — binary is the canonical/default behaviour, but a documented weighted variant exists
    behind an explicit option (prefer the option name `weighted`, as introduced for `nwevcent` this
    session, over ad hoc alternatives).
  - **W3** — intentionally binary-only; state this in the `.sthlp` in plain language ("weighted
    networks are dichotomized before calculation" or similar), do not just leave weighted behaviour
    unmentioned. `nwreach`'s explicit `set_valued(0)` dichotomization plus its documentation is the
    reference example; `nwqap`'s silent, undocumented dichotomization is the anti-pattern to avoid
    when touching that command.
  - **W4** — not applicable; no defensible weighted formulation exists for this statistic (e.g. a
    dyad/triad census). No action needed beyond not claiming otherwise in the docs.
  - **W5** — a standard weighted formulation exists in the literature but isn't implemented yet;
    record as a roadmap item, don't pretend it's out of scope.
- **Strength vs. distance — never conflate.** Higher weight meaning "stronger/closer tie" and higher
  weight meaning "larger distance/cost" are different interpretations that must never be implicit.
  `nwdegree`'s `alpha` (exponentiates a strength ratio) and `nwkatz`'s `alpha` (exponentiates a
  distance) are the same option name with incompatible semantics — a concrete example of the trap.
  Do not silently apply `distance = 1/weight` unless that transformation is the explicitly selected,
  documented option, or is already an established package convention for that specific command
  family (`nwgeodesic`'s Opsahl et al. formulation is the existing, documented, defensible
  precedent for path-based commands — reuse its `alpha()` convention for new path-based work rather
  than inventing another).
- **Zero and negative weights**: handle deliberately. A row-normalization (`nwconstraint`'s
  `net/rowsum(net)` pattern) silently produces garbage on a negative-sum row; guard or document
  this explicitly per command rather than leaving it unstated, as `nwconstraint` currently does.

### Signed

- Do not treat a signed network as "just a weighted network." A command that has not been
  deliberately audited for signed-tie correctness should be assumed **not** to support them safely
  until checked — this audit found essentially no command that explicitly validates or rejects
  negative weights; this is systemic, not isolated. Where a statistic's mathematics genuinely
  doesn't support negative ties (most do not, without a deliberate signed reformulation), reject
  signed input with a clear error rather than silently computing a number.
- `nwbalance` (Cartwright-Harary strong structural balance, added earlier this session) is the
  package's one genuinely signed-aware command — its convention (triad balanced iff the product of
  its three signed tie values is positive) is the reference point for future signed work.

### Two-mode / bipartite

- **Terminology**: the package already uses "two-mode" as primary terminology (`is2mode`,
  `nw2project`, `nw2clustering`, the `nw2*` command family) with "bipartite" as an accepted synonym
  in prose (`nwset`'s own `bipartite` option). Keep both; prefer "two-mode" in new option/command
  names for consistency with the existing `nw2*` family.
- **Never silently project.** A command that receives two-mode input and needs one-mode data must
  do one of: (a) use a genuine native two-mode formulation if one exists (T1); (b) offer explicit
  mode selection (T2); (c) require an explicit, separate projection step — `nw2project` already
  exists for exactly this and should be the standard reference in error messages
  ("...requires a one-mode network; see {help nw2project} to project first."); or (d) reject
  two-mode input with a clear error (T4/not-yet-T5). `nwclustering`'s auto-redirect to
  `nw2clustering` (with an explicit user-visible message, not silent substitution) is the model
  pattern for commands that have a native two-mode alternative available.
- **Mode selection syntax**: no single canonical term has fully displaced others yet (`mode(1|2)`,
  `context(incoming/outgoing/both)`). Where a new command needs mode selection, prefer numeric
  `mode(1|2)` matching `nw2project`'s existing, tested convention, documenting explicitly which
  mode is "1" for that specific two-mode network (this is data-dependent, not a package-wide
  constant — state it per use, e.g. via `nwset`'s own bipartite row/column convention).

## `if` / `in`

Meaningful on commands operating over the current *dataset* (node- or edge-level Stata variables),
not meaningful as a network *selector* (that's what `netname`/`netlist` are for). Several
data-management commands (`nwdrop`, `nwkeep`, `nwsubset`) already combine a `netname` argument with
an `if`/`in` qualifier on the underlying node/edge data — keep this pattern; do not conflate the two
kinds of filtering.

## Output creation

- `generate(newvar)` for a new **Stata variable** (analytical commands: centrality scores,
  membership indicators, etc.) — this is the dominant, expected meaning package-wide.
- `generate(newnetname)` for a new **network** is a separate, established, and equally legitimate
  convention specific to the data-management command family (`nwaddnodes`, `nwdropnodes`,
  `nwtranspose`, `nwsym`, `nwkeepnodes`) where in-place modification is the default and `generate()`
  opts into producing a copy instead. Do not try to unify these two meanings — document both
  explicitly, distinguished by context, in the style guide (this document) rather than forcing one
  option name to do double duty inconsistently.
- `replace` guards an existing `generate()` target from accidental overwrite — universal, keep as-is.
  When a command's `replace` option needs to also cover *network*-name collisions (not just
  variable-name collisions), it must actually reuse the exact requested name rather than silently
  auto-incrementing to a different one even when `replace` was given — a real bug found and fixed
  twice this session (`nwsimindex`, `nw2project`); check for it whenever touching a command that
  uses the `nw_validate`+`r(validname)` pattern.

## Simulation / permutation / inference options

Standardise, going forward: `reps()` for replication count (not `ntimes()`, `permutations()`, or
other synonyms — `nwrandom`'s `ntimes()` and `nwmixing`/`nwcorrelate`'s `permutations()` are
pre-existing and should be kept as working aliases, not broken, but `reps()` is the term to use in
new commands, matching `nwcug`'s existing usage and Stata's own bootstrap/permutation-command
convention). `seed()` for reproducibility (added to `nwcug` this session as the reference pattern —
optional, calls `set seed` when given, otherwise leaves the ambient seed alone). `tail(both|upper|
lower)` for one/two-sided inference reporting (from `nwcug`).

## Stored results

- New or materially-touched commands should use `program X, rclass` + `return scalar`/`return
  local`/`return matrix`, matching every command built or extended this session (`nwkcore`, `nwcug`,
  `nwsimindex`, `nw2project`, `nwaltergen`, `nwevcent`, `nwgeodesic`). This is the Stata-recommended
  idiom and is what `nw_helpwriter` certification implicitly assumes.
- Do not mechanically rewrite untouched legacy commands (the many still using `mata: st_rclear()` +
  `mata: st_numscalar("r(x)", ...)`) purely to switch idiom — both work identically from the
  caller's perspective; only migrate as part of a change already touching that command for another
  reason.
- **Critical gotcha, discovered twice this session** (`nw2project`, near-miss in `nwcug`): a
  `return scalar x = ...` statement only *publishes* `r(x)` to the calling context once the current
  program actually exits. `r(x)` reads as **missing** from inside the same program body that just
  set it. Any display/logic that needs the value before the program ends must reference the
  underlying local or Stata scalar directly — never `r(x)` — within that same program. See
  `nw_programming.sthlp`'s "[NW-5.2]" pitfalls list, item 5, for the full writeup.

## Errors

- Invalid/nonexistent network: existing `nw_syntax`-driven error handling already covers this
  consistently across modern-architecture commands — preserve it.
- Incompatible network type (wrong directedness, unsupported weights, signed input to a command that
  can't handle it, two-mode input to a one-mode-only command): **must produce an informative,
  specific error**, not silently proceed or produce a number of unclear meaning. Model message
  shape: `"<command> does not support <condition>; <suggested alternative or fix>."` — e.g.
  `nwclustering`'s two-mode redirect message, or the proposed `nw2project`-referencing message above.
- Missing current network when one is required and none was set/loaded: existing `nw_syntax`
  behaviour (errors clearly) — preserve.

## Terminology

Preferred vocabulary, package-wide, in new documentation (existing docs' established synonyms are
not being mass-rewritten as part of this pass, only flagged where actively misleading):

- **node** (primary) — "vertex"/"actor" as recognized synonyms in prose where domain-appropriate
  (e.g. "actor" in a sociological example), not in option/variable names.
- **tie** (primary, matches `nwvalue`/`nwdyads`/the package's own established usage) — "edge"/"link"
  as synonyms in prose.
- **weighted** (primary) — "valued" is the package's own long-established synonym (embedded in
  `is_valued()`/`isvalued`/`get_matrix_mod(valued, ...)` throughout the Mata core) and should be
  kept, not replaced; use "weighted" in new user-facing option names (`weighted`, matching
  `nwevcent`), "valued" is fine in Mata-level code and internal documentation referencing the
  existing API.
- **two-mode** (primary) — "bipartite" as an accepted, established synonym in prose (see above).
- **directed** / **undirected** (primary) — "asymmetric"/"symmetric" appear in some older docs
  referring to the same distinction; keep as synonyms in prose, prefer directed/undirected in new
  option names (matches the existing `directed`/`undirected` boolean options already used
  throughout `nwset`, `nwfromedge`, `nwrandom`, etc.).

## Backwards compatibility

Existing, working user syntax is not broken by this standard. Where harmonisation would change
established syntax:

1. Preserve the old syntax as a working alias wherever practical.
2. Introduce the canonical form alongside it.
3. Document the canonical form as primary in the `.sthlp`; mention the alias for existing users.
4. Test both forms.

Backwards compatibility does **not** extend to silently preserving statistically questionable
treatment of weights, signed ties, or two-mode data discovered during this audit — those get fixed
(with the change documented, per this session's established discipline), not preserved for
compatibility's own sake, per the harmonisation brief's explicit priority ordering: correctness
first, established behaviour second, backwards compatibility third.
