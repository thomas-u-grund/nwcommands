# nwcommands Help-File Style Standard

Authoritative SMCL/`.sthlp` reference, written 2026-08-21 as part of the harmonisation phase.
Derived from the structure already used consistently by every command built or fully re-documented
this session (`nwkcore`, `nwaltergen`, `nwsimindex`, `nwcug`, `nw2project`, `nwburt`, `nwbalance`,
`nwevcent`) — not a new invention, a codification of what already works, extended with the
network-type documentation the harmonisation brief specifically calls for.

## Canonical section order

Not every command needs every section — a data-management command with no meaningful network-type
restrictions doesn't need a "Supported network types" section full of "n/a"s, and a three-line
utility wrapper doesn't need "Remarks." But where a section applies, use this order and these exact
`{title:}` strings so comparable commands look comparable:

```smcl
{smcl}
{* *! version X.Y.Z DDmonYYYY author: <name>}{...}
{marker topic}
{helpb nw_topical##<category>:[NW-x.y] <Category>}

{title:Title}
{p2colset ...}
{p2col :<cmd> {hline 2} <one-line description>}
{p2colreset}

{title:Syntax}
<syntax diagram>
{synoptset ...}
{synopthdr}
{synoptline}
<option descriptions>
{p2colreset}

{title:Description}
<what it does, in prose>

{title:Supported network types}     <- see below; analytical commands only
<binary/directed/weighted/signed/two-mode statement>

{title:Options}                     <- only if options need more explanation than the synoptset gave
{title:Remarks}                     <- only if genuinely needed beyond Description
{title:Stored results}
{title:Examples}
{title:References}                  <- for anything implementing a named statistic/algorithm
{title:See also}
```

## Header

- `{* *! version X.Y.Z DDmonYYYY author: <name>}{...}` — every file should have this; increment the
  version and date whenever the file's *content* materially changes (not for a pure
  "last certified" footer refresh from `nw_helpwriter`).
- `{marker topic}` + `{helpb nw_topical##<category>:...}` — link back into the topical index. Use
  the existing category markers (`generator`, `analysis`, `manipulation`, `utilities`, `concept`) —
  do not invent a new one without also adding it to `nw_topical.sthlp`.

## Syntax block

- Reference `{help netname}` or `{help netlist}` for the network argument — never inline a
  home-grown description of what a network-name argument means. See
  `NWCOMMANDS_COMMAND_STYLE.md` for which one a given command should use.
- List every option in both the syntax diagram and the `{synoptset}` block. A `.sthlp` documenting
  an option the code doesn't parse, or a code option missing from the docs, is a certification
  failure (see "Certification," below) — this audit already found concrete instances (`nwpath`'s
  stored-results claims, `nwdegree`/`nwbetween`'s multi-network claims) of exactly this drift.

## Supported network types

New section, introduced by this harmonisation phase, for every command that does non-trivial
network analysis (i.e. most of the "analysis" category, and generators that produce networks with
type-specific behaviour). Not needed for pure data-management commands with no network-type
restrictions (`nwaddnodes`, `nwrename`, etc.) — don't add boilerplate where it adds nothing.

Template:

```smcl
{title:Supported network types}

{pstd}
Binary: yes. Directed: yes ({opt nosym} to skip auto-symmetrization). Weighted: {opt weighted}
option available (see below); default is dichotomized. Weight meaning: tie strength, used
directly. Signed: not supported — negative tie values are rejected. Two-mode: not supported; see
{help nw2project} to project a two-mode network to one mode first.
```

Adapt freely — the point is that every claim in `NWCOMMANDS_COMMAND_STYLE.md`'s W1-W5/T1-T5
taxonomy for that specific command is stated in plain language, matching what the code actually
does (verified, not assumed — see Certification below). For weighted commands, state explicitly
whether weight means strength, distance/cost, capacity, or a generic value. For two-mode commands,
state whether support is native, mode-specific, or projection-based, and if mode-specific, which
mode is "1" for the network in question (this is data-dependent — state the convention, not a
number).

## Stored results

List every `r()`/`e()` value the command actually returns — cross-checked against the code, not
transcribed from memory or copied from a similar command. Use a consistent two-column layout
(`Scalars` / `Macros` / `Matrices` headers as needed, matching the existing convention in
`nwkcore.sthlp`/`nwcug.sthlp`/etc.).

## Examples

Every example should be runnable. Prefer a small `nwset, mat(...)` literal or `nwwebuse` call over
an unexplained pre-existing dataset assumption. Where the exact numeric output of a live-data
example (e.g. `nwwebuse florentine`) cannot be verified in the current environment (no network
access to fetch the dataset), say so honestly in the example's surrounding prose rather than
inventing a plausible-looking number — this was the standard applied when documenting `nwgeodesic`'s
radius/eccentricity addition this session, and should be the standard going forward.

## References

Required whenever a command implements a named statistic or algorithm from the literature
(Newman's modularity, Seidman's k-core, Liben-Nowell & Kleinberg's similarity indices, etc.) —
matches the pattern already used by every command added this session. Cite the actual source the
implementation follows; if the implementation deviates from the literature definition (as `nwkatz`
was found to, during this audit — it computes a distance-decay sum, not eigenvector-based Katz
centrality), the References/Description section must say so explicitly, not merely cite the name.

## Terminology

Follow `NWCOMMANDS_COMMAND_STYLE.md`'s terminology section (node/tie/weighted-or-valued/
two-mode-or-bipartite/directed). Within a single help file, be internally consistent — don't switch
between "node" and "vertex" mid-document without reason.

## Formatting

- `{pstd}` for body paragraphs, `{p 8 12 2}...{p_end}` (or similar hanging-indent pairs) for
  definition-list-style option/case enumerations — **every `{p N M K}` opener needs a matching
  `{p_end}`** (a real, found-and-fixed bug in `nw_programming.sthlp` during this session: an
  unclosed `{p}` block silently breaks the paragraph's indentation for everything after it).
- Blank line between sections; no more than one blank line in a row.
- Wrap prose near 80 columns to match the existing house style (not strictly enforced, but keep
  lines reasonably short — SMCL does its own re-wrapping at render time, but source readability
  still matters for maintainers).
- **Never use literal backtick-pairs for emphasis in a `.ado` file's comments** if that file has (or
  ever will have) a `nw_helpwriter`-managed doc header — the line-copy loop macro-processes every
  line of the file unconditionally and a double-backtick pair crashes it with "too few quotes" (a
  real bug found and fixed in `nw2project.ado` this session; use plain quotes instead). This is a
  `.ado`-comment rule, not a `.sthlp` rule, but is recorded here since it directly affects whether a
  help file can be regenerated at all.

## Certification

A help file is not certified merely because its SMCL parses cleanly. Certification means:

1. The command referenced actually exists and the syntax shown matches the real `syntax` line.
2. Every documented option is real; every real option is documented.
3. Every documented `netname`/`netlist` designation matches what the code actually does (see
   `docs/COMMAND_AUDIT.md` for confirmed mismatches to fix first).
4. Every claimed network-type support (binary/directed/weighted/signed/two-mode) matches the code.
5. Every stored result claimed is actually returned; nothing returned goes undocumented.
6. Every example runs without error (where feasible to test — `nw_helpwriter`'s own certification
   mechanism runs the command's `cscripts/test_X.do` file and appends a "last certified" footer only
   if it passes; a fixed, session-discovered fragility in that mechanism — a successful `assert`/`di`
   not resetting Stata's ambient `_rc` — is documented in `docs/CERTIFICATION.md`).

Maintain certification status in `docs/CERTIFICATION.md`, not by trusting the presence of a
"last certified" footer alone — that footer only proves the test file passed at that date, not that
every claim above holds; a full audit pass (Part XIX-XXIII of the harmonisation brief) is still
needed per file to confirm 1-5 above, since `nw_helpwriter` only mechanically checks the doc-header
extraction and the test's pass/fail status, not semantic accuracy against the actual code.
