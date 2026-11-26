# Changelog

All notable changes to the nwcommands core package. The format follows [Keep a Changelog](https://keepachangelog.com/);
versions follow [Semantic Versioning](https://semver.org/). The model families have their own packages and changelogs
(`nwsaom`, `nwergm`, `nwdynam`, `nwrem`, `nwalaam`, `nwsbm`, `nwlsm`).

## [Unreleased]

### Results that change
- `nwattime`, `nwlambda`, `nwsimindex`, `nw2project` and `nwneighbor ..., subnet() subreplace` with a target network that
  exists could compute the result from another network, without a message, or stop and lose the old target (when the
  target was created before the source). `nwcorrelate, keepexpand` could stop with an error for the same reason.
- `nwimport, type(pajek)`: a file with tab-separated tie lines was read as a network without ties.
- `nwspectral` on a network with missing ties returned missing values and no components; missing ties now count as 0.
- `nwdichotomize ..., generate(name)` with a name in use marked the network of that name as binary.
- `nwset` from an edge list (`edgelist`, `twomode`, `time()`, `interval()`, `eventtime()`) now stops with error 4 when
  the data have unsaved changes and hold variables that are not part of the edge list; they were dropped without a
  message. New option `dropvars` allows it.

### Fixed
- Pajek and UCINET DL files with a byte-order mark, and DL files with blank lines, are imported.
- `nwimport` without `name()`: on Windows, a path with both kinds of separator gave a network name that included
  folder names; the name now comes from the file name.
- `nwfromedge` warns when identifiers that differ only in blanks at the ends become one node.
- `nwrecode`, `nwdichotomize`, `nwsimilar` and `nwdissimilar` say under which name a result is stored when the requested
  name is in use; `nwdichotomize` refuses a name given twice in `generate()`.
- `nwsummarize, detail` on a two-mode network; `nwplot` with a condition that no node meets; `nwegoplot` after a failed
  earlier run.
- Clearer errors: unknown names in `nwgenerate` and `nwreplace` expressions, `nwhierarchy` with missing dissimilarities
  or one node, `nwgenerate` with a condition that selects no node.
- Option values are checked: `nwqap type()` and `mode()`, `nwcorrelate permutations()`, `nwhomophily density()`,
  `nwconstraint` with both `directed` and `undirected`. Notes for a negative `alpha()` of `nwkatz`, negative `size()` in
  `nwplot` and negative tie values in `nwspectral` and `nwcoreperiphery`.
- `nwexport`: no stray quotes in the message; an ending given in `fname()` is not added twice.
- Help: the event data example declares the network as directed; sort order after network commands; encoding of
  imported files.

### Added
- `nwplot, interactive pictograms(names)`: the pictograms of the interactive view can be set in the command, one for all
  nodes or one per group of `symbol()` or `color()`.

## [3.38.0] - 2026-11-26

**Summary.** Fixes for temporal networks with tie values, for dropping nodes of temporal networks, and other fixes in the shared Mata library. Please update.

### Results that change (read before you re-run old analyses)
- Snapshot and interval networks **with tie values**: `nwattime` gave every time the value of the LAST row of a pair.
  It now gives the value of that time or period. Recompute results from such slices. Networks saved to a file with an
  earlier version hold no values per time: declare them again from the data.
- `nwturnover` and `nwkcomponents` counted **missing** tie values as ties.
- `nwdrop`, `nwkeep` and `nwsubset` with a condition on a temporal network left the events, times and intervals at the
  old node numbers: time slices could show ties between the **wrong nodes**, or commands stopped with an error. Check
  results obtained from temporal networks after dropping nodes this way (`nwdropnodes` was not affected).
- `nwrecode` and `nwdichotomize` also end the temporal state of a snapshot or interval network when the rules change the
  value at some time, even if no tie of the network itself changes.

### Fixed
- `nwmovie`: the controls moved when the play button changed between Play and Pause.
- Node names with commas in two-mode networks: the modes were lost when the network was saved and used again.
- The library refuses reserved words as network names in every command.

## [3.37.2] - 2026-11-26

**Summary.** Fixes for commands that deleted or overwrote data and networks, and for wrong results. Please update.

### Results and behaviour that change (read before you re-run old analyses)
- `nwdyadprob`: a **missing** probability produced a tie. It is now no tie.
- `nwmixing, permutations()`: **missing** tie values counted as ties in the p-value. Recompute p-values of networks with missing ties.
- `nwtoedge`/`nw2toedge, full` on a two-mode network listed each tie twice in the same direction; it now lists both directions.
- A temporal network whose ties are changed in place (`nwtranspose`, `nwsym`, `nwpermute`, `nwreplace`, `nwrecode`, `nwdichotomize`, `nwreplacemat`), or a new network made so, is no longer temporal; the command says so. Its old times did not fit the new ties.
- `nwimport`: Pajek arcs and GML `directed 1` stay directed (use `forceundirected` if you want otherwise); self-loops in Pajek, GML, UCINET and edge-list files are kept; commas in node names become blanks.
- `nwimport` without `clear`/`nwclear` leaves existing data unchanged (node attributes of the file are then not loaded; a note says so).
- `nwimport, type(matrix)`: names in the header keep their spelling; a file that is not a square number matrix is refused.
- `nwsync` (also run by `nwsym`, `nwreplace`, `nwreplacemat`) refreshes only the variables that `nwload` made; your own variables with node names are left as they are.
- `nwload` stops when it would overwrite your variable (option `overwrite` replaces it). Commands that load a network
  for you (option `xvars` and generators) print a note instead, keep your variables and carry on.
- `nwutility` needs the new option `replace` to overwrite `_benefit`, `_cost` and `_util`.
- `nwkeep` with a condition that no node meets stops with r(2000); before, it removed the network. `nwkeep` without a
  list or condition (for example with an empty local) is refused; before, it dropped all networks but the current one.
- `nwimport`: option `directed` for matrices and edge lists is followed also when every tie is reciprocated.
- `nwmovie` refuses `duration()`, `speed()` or `window()` of zero or less and unknown `easing()` names, and writes over
  an HTML file that it did not create only with `replace`. `fname()` may end in `.html`.
- `nwuse x, nwappend`: where memory and file differ in a value, the value in memory is kept.

### Fixed: deleted or overwritten data and networks
- `nwdropnodes`, `nwkeepnodes`, `nwreplacemat` with another number of nodes could change the directed or valued flag of **another** network (ties could then be lost on saving).
- `nwhierarchy` dropped observations that belonged to no node (since 3.37.0), also on errors, and overwrote a matrix `mymat`.
- `nwfromedge` removed the data when no row met the condition.
- `nwdropnodes, attributes()` blanked values in unrelated observations and failed on string variables.
- `nw2set` with variables dropped the other variables.
- `nwspmatrix` replaced a variable `_ID` of data that are not `spset`.
- `nwcollapse` left a working network behind after an error.
- `nwsave` and `nwuse`: a variable named like a network could overwrite tie values; user variables could be deleted; after `nwuse`, `save, replace` could overwrite the `.nwdta` file; observations without a node were lost; `nwuse` or `nwwebuse` of a missing or broken file with `nwclear` removed networks and data.
- `nwimport`: a failed or successful import could remove the data in memory.
- `nwsave` failed for network names of 16 or more characters. Files with such names cannot be read by earlier versions.
- A failed `nwcollapse` could leave changed data or a working network behind.
- A failed `nwhierarchy` or `nwcorrelate` could change the current network.
- A failed `nwdegree` could leave some of its variables; a failed `nwcorrelate, attribute()` left `_nwinclude`.
- Help: `nwturnover` counts undirected ties once (not twice); `nw2project, stat(newman)` uses tie values.
- `nwdyadprob` dropped a network of the user called `_tempdyad`.
- `nwplot, layout(mds)` replaced the estimation results `e()`.

### Fixed
- Two-mode UCINET files: node names with blanks gave a **different network** on import, without an error. Names are now
  quoted in the file and read as such. Check two-mode networks imported from such files.
- Pajek files with blank lines: `nwimport` stopped reading at the first one and reported success, so **ties or whole
  sections were missing**. Check networks imported from such files. Comment lines (`%`) are skipped too.
- UCINET files with tabs: ties could be missing without an error.
- `nwimport`: Excel and semicolon matrix files, numeric node names, decimal commas, edge-list headers, string attributes, UCINET files with `labels embedded:`, labels with commas, `;` or apostrophes, Pajek `*Matrix`; file handles are closed after errors.
- `nwmovie` for event networks put all node names into the first label.
- `nwplot, interactive`: missing values in `color()`, `size()` or `symbol()` gave an empty page.

## [3.37.1] - 2026-11-25

**Summary.** Fixes for commands that destroyed networks or gave wrong results. Please update. The core Mata library and the plugins are unchanged; the model packages need no update.

### Results that change (read before you re-run old analyses)
- `nwlambda` and `nwsimindex`: with the input network's name as the name of the result (`name(`*input*`) replace`), they returned **wrong values** without an error. Recompute results obtained this way. The input's name is now refused.
- `nwset, mat(B) bipartite` **changed the Mata matrix `B`** (it became the square matrix of all nodes), so that using `B` again gave a different, larger network. `B` is now left as it is. Networks declared from a matrix that had been used before may be wrong.

### Fixed: lost networks
- `nwbridges` and `nwsimmelian` (option `nwreplace`), `nw2project` and `nwattime` (option `replace`): with the input network's name as the name of the result, the input was destroyed; `name(_all)` with `nwbridges` or `nwsimmelian` dropped **all** networks. These commands now refuse the input's name.

### Fixed
- Rows of the data that belong to no node keep their order when networks are created or the data are synchronized (before: shuffled).
- `nwplot, edgesize()` without `forcekeys()` had no legend entries; they now show the smallest and largest value (none when all ties have one value).
- `nwplot, interactive`: the degree of a clicked node was blank.
- Dialog boxes: long labels shortened.
- `help nwintro`: measured timings removed; the limits stay.

## [3.37.0] - 2026-11-25

**Summary.** Pictograms in the interactive view of `nwplot`, and fixes from a test of the commands at their limits: input checks, error messages, help files and dialog boxes. Some results and behaviour change (below). The core Mata library and the plugins are unchanged; the model packages need no update.

### Results that change
- `nwtabulate network, attribute()`: the **E-I index** counted only the diagonal of the table as internal ties and could have the wrong sign. When every tie joins different groups it is now +1 (before: -1). Recompute E-I values and their p-values obtained with earlier versions.
- `nwtabulate network, attribute()` on an **undirected** network: the table no longer depends on the order of the nodes. Each tie is entered with the lower attribute value as the row, so cells can differ from earlier versions.
- `nwgeodesic`: the distance network is marked as valued when it holds distances above 1.

### New
- `nwplot, interactive`: node groups can be drawn as pictograms (33, chosen in the shape drop-downs of the page), colored and sized like other nodes. Shape groups that do not match the color groups now have rows of their own, with a color picker when there is a single color group. Pictograms are in the page and its PNG export only; Save do-file and the CSV files keep the ordinary shapes.

### Behaviour that changes
- `nwuse` (and `nwwebuse`) no longer discards data with unsaved changes: use the new option `clear`, or `nwclear`; `nwappend` keeps the data.
- `nwreplace` rejects `in` (before: ignored, so every tie was replaced).
- A result may no longer overwrite the input network (`nwcorrelate`, `nwreach`, `nwshared`, `nwgeodesic`); an existing network needs `replace` or `nwreplace` where the command offers it (new for `nwcorrelate`).
- `nwdrop` with a condition that selects every node is refused.
- `nwset` refuses string variables read as a matrix; two columns of names are an edge list (option `edgelist`).
- Stata's reserved words (such as `_all`, `_n`, `if`, `byte`) are refused as network names.
- `nwgenerate` refuses a number alone (`nwgen b = 2`).
- Impossible input is refused with a message: `nwrandom`, `nwlattice`, `nwpref`, `nwqap`.

### Fixed
- Interactive view: the size legend keeps the ratio of the node sizes at any zoom and follows the node size slider; an invalid selector that caused a browser console warning is removed.
- `nwplot`: node-size legend labels no longer show long binary fractions (9.870000000000001).
- `nwset ..., clear` works when no network is loaded.
- `nwimport`: file names with other characters give a valid network name; an edge list with a single line can be read.
- Network expressions with `-` and `!` written without spaces (`nwgen c = 1-a`), and `~=`.
- `nwplot, export(file, replace)` through the shared export helper and in the path read by `nwplot`; `size()` with a string variable gives a message.
- `nwhierarchy` and `nwegoplot` when the data have more observations than the network has nodes.
- Clearer messages: `nwrename`, `nwcorrelate` with a constant network, `nwfromedge` with empty data or a string tie value, commands with no network loaded. `nwdrop` without a name says which network it drops; `nwpref` says when `m()` exceeds `m0()`; `nwconstraint` warns about negative tie values.
- Help files: broken examples and links, raw markup, missing options and required options; text about earlier versions and old timings removed.
- Dialog boxes: missing fields, missing required-input checks, overlapping and cut-off labels, options without effect removed, network boxes that need two networks now add the second.

## [3.36.1] - 2026-11-23

- `nwfromedge` (when a pair is listed more than once and node names are used) and the networkdata reader (`nwwebuse networkdata`, `nwnetworkdata`) no longer run `keep` once per group (`by ...: keep if _n == _N`): in Stata 19 every such `keep` costs more the more networks are stored, so reading a data set with hundreds of networks slowed down as it went. One `keep` now does the same work; the networks are unchanged. Reading `animal_12` (244 networks) in Stata 19.5 MP on a Mac: 96 s to 33 s; on Linux about 80 s before.

## [3.36.0] - 2026-11-22

**Summary.** Creating many networks is much faster, the networkdata collection needs no R any more, and two small corrections to commands and help files. The core Mata library is rebuilt, so the model packages are rebuilt with it (update all packages together, `nwinstall, models`).

### Faster
- **Creating, naming and dropping networks no longer slows down as more networks are stored.** Creating 1,000 random networks of 50 nodes (`nwrandom`) took 112 s and now takes 18 s, and creating a network from a matrix with `nwset, mat()` is faster still (1,000 networks in about 6 s); the time per network no longer grows with the number of networks in memory. Every command that stores a result network benefits (`nwrandom`, `nwload`, `nwreplace`, `nwgenerate`, ...); dropping 100 of 1,000 stored networks takes 0.3 s instead of 4 s. Loading a whole list of 244 networks from Schoch's collection (`nwnetworkdata animal_12`) takes about 16 s instead of about 49 s. Results are unchanged.

### Added
- **The networkdata collection (R package by David Schoch; `nwwebuse networkdata`, `nwnetworkdata`) needs no R any more.** The reader now decompresses and decodes the downloaded `.rda` files with Stata alone (gzip and bzip2, R's serialization format, igraph objects and lists of igraph objects) and gives the same networks as the conversion with R and the package igraph: the same nodes, ties, tie values, directed, valued and two-mode status, node names and node and tie attributes (checked on all 990 data sets of the collection). Nothing is shipped or hosted: the files are still downloaded from Schoch's repository when you ask for a data set. A damaged, truncated or oversized file is refused with a clear message (error 610), nothing is executed, and the reader stops at the limits it checks (size of the file and of the decompressed data, number of elements, nesting). The conversion with R remains available with the new option `withr`, and is used (after a note) if the reader without R meets an object it does not handle; this is the case only for the ego-centered object `gss_egor` (`nwnetworkdata tables`). Node labels made from names with accented letters now lose the accent in every system (R's own conversion gives different labels on different systems); the unchanged names are in `nd_name`. The first use of a very large list of networks (`animal_12`, 244 networks) takes several seconds; every other data set loads in about a second or less.

### Changed
- `nwwebuse networkdata ...` (also `nwwebuse <name>, networkdata`, `nwwebuse networkdata list`, `nwwebuse networkdata describe <name>`) is the new way to load data sets of the networkdata collection; the keyword `schoch` of 3.35 still works with identical behaviour. The collection is described in the help and on the website as the networkdata collection (R package by David Schoch).
- `netexample` and the data sets page list the shipped data sets in one order (longitudinal social networks, one-time social networks, two-mode, signed, event data, networks that are not social), and the networkdata collection last; `baerveldt19` and `usmap` are now in the overview list of `help netexample`.
- `nwdissimilar` spells the distance type `manhattan`; the earlier spelling `manhatten` is still accepted, with the same result. `nwhierarchy`, the dialog boxes, the help files and the website follow.
- Help: `nwsmall` describes the rewiring targets of `prob()` as the command picks them (outside the ring band, no existing tie); `nwsimilar` names `context()` as the main option.

### Rebuilt
- The core Mata library is rebuilt (new compiled registry functions). `nwsaom`, `nwergm` and the other model packages are rebuilt for this version and require core 3.36.0 or later.

## [3.35.1] - 2026-11-22

Documentation only. No command changes.

### Changed
- The page of the Schoch data sets is rewritten as an overview in our own words with links to the documentation of the networkdata package (the descriptions of the collection are not reproduced any more).
- The licence note of the Schoch reader (`nwnetworkdata`, `nwwebuse schoch`) and of `netexample` says that the MIT licence of the package covers the package itself, that no licence is documented for the individual data sets and that users should check and cite the original sources.

## [3.35.0] - 2026-11-22

**Summary.** One rule now holds in every command: a command never changes the type of your network by itself. A directed network is analysed as a directed network, a valued network as a valued one, and where a command needs something else (undirected, binary) you ask for it with an option (`sym`, `weak`, `binary`, ...). Every command also prints one line that says how the network was read, and how many missing ties were treated as 0. The release also adds lists of networks and `save()` to `nwgeodesic` and `nwclustering`, `ntimes()` to `nwhomophily` and `nwdyadprob`, and a reader for the data sets of the R package networkdata (`nwwebuse schoch`).

**Results that change, in short (read before you re-run old analyses on directed networks).** Undirected networks give the same numbers as before everywhere.
- `nwbetween`, `nwcloseness`, `nwevcent`, `nwinduced`, `nwkatz`: a directed network is analysed as it is. Option `sym` restores the old default result (`nwevcent`: option `out` restores the previous out-tie centrality).
- `nwassortativity`: one pair per tie, sender against receiver. `sym` restores the old result.
- `nwcomponents` (and `large()`, `components()`, `lgc()` in `nwgenerate`): a directed network gives its strongly connected components. `weak` restores the old result (`large(net, weak)` in `nwgenerate`).
- `nwrandomwalk`: the walk follows the direction of the ties. `sym` (or `symmetrize`) restores the old result.
- `nwcohesion`, `nwclique`, `nwkplex`, `nwnclique`, `nwnclan`, `nwkcomponents`, `nwlambda`, `nwspectral`, `nwcoreperiphery`, `nwfactions`: a directed network with unreciprocated ties is refused with error 198 instead of being symmetrized silently. Option `sym` analyses the symmetrized network, with the same numbers as before.
- `nwbalance`: a pair of nodes with ties of opposite signs in the two directions is refused with error 198 (the sign of the pair is not defined; use `nwsym` with a mode of your choice first).

**Added, in short.** Lists of networks (wildcards allowed) and `save()` in `nwgeodesic` and `nwclustering`; `ntimes()` in `nwhomophily` and `nwdyadprob`; `nwnetworkdata` and `nwwebuse schoch` (needs R with the package igraph, only for this reader); printed notes that say how every network was read; `(N missing ties treated as 0)` notes. The details follow.

### Results that change
- `nwbetween`, `nwcloseness` and `nwevcent` recognise whether the network is directed or undirected and say so in the output. A directed network is now analysed as it is: shortest paths follow the direction of the ties (betweenness equals `igraph::betweenness(directed = TRUE)` and `sna::betweenness(gmode = "digraph")`, with the directed standardisation `(N-1)(N-2)`; closeness uses the distances from a node to the nodes it can reach, equals `igraph::closeness(mode = "out", normalized = TRUE)`, and is missing for a node that reaches nobody; weights of a valued network as before). Until 3.34.0 the default symmetrized a directed network first (`nwsym`, mode `max`) and `nosym` gave the directed result. Use the new option `sym` for the previous default result; `nosym` is still accepted and is the same as the default. `sym` together with `nosym` is error 198. Undirected networks give exactly the same numbers as before, and need no symmetrized copy any more (nwbetween and nwcloseness take about 30 to 45 percent less time on 2,000 nodes).
- Printed notes: `(directed network: shortest paths follow the direction of the ties)` (`nwbetween`), `(directed network: distances follow the direction of the ties)` (`nwcloseness`), `(directed network: the direction of the ties is used)` (`nwevcent`), `(directed network symmetrized: the larger of the two directions of a tie)` (all three with `sym`), `(undirected network)` (all three).
- The analysed network is the current network after `nwbetween`, `nwcloseness` and `nwevcent` in every mode (3.34.0: `nwcloseness` made the first network of the list current as a by-product when it symmetrized and left the current network unchanged with `nosym`; `nwevcent` and `nwbetween` with `nosym` never changed it). After a call with a list of networks the last network of the list is current.
- Dialogs of the three commands: the `nosym` check box is replaced by a `sym` check box.
- Coercion sweep (standing rule: no command treats a network as another type than it is unless an option asks for it, and every coercion is stated in the output). Helpers `_nwdirnote` (the note line for directed, undirected or symmetrized) and `_nwmissnote` (`(N missing ties treated as 0)`, printed only when the network has missing ties); option `sym` is the same everywhere (the larger of the two directions of a tie).
- `nwassortativity`: a directed network is now analysed as it is, one pair per tie with the value at the sender against the value at the receiver (Newman 2003; equals `igraph::assortativity_degree(directed = TRUE)` for the default degree: out-degree of the sender against in-degree of the receiver, out- and in-strength on a valued network, and `igraph::assortativity(directed = TRUE)` with `attribute()`). Until 3.34.0 a directed network was symmetrized silently. Option `sym` gives the previous result. Notes: `(directed network: out-degree of the sender against in-degree of the receiver, one pair per tie)`, `(directed network: the attribute of the sender against that of the receiver, one pair per tie)`, `(directed network symmetrized: ...)`, `(undirected network)`; `r(ties)` counts the arcs of a directed network; `r(directed)` is stored. Undirected networks: same numbers. Example `lazega_adv`: -0.0802 before, -0.0302 now (`sym`: -0.0802); `glasgow1`: 0.1723 before, 0.1509 now.
- `nwcomponents`: a directed network gives its **strongly connected components** (mutual reachability along the direction of the ties; `igraph::components(mode = "strong")`), as igraph and sna do; until 3.34.0 the weakly connected components were returned silently. Option `weak` gives the previous result. The output says `(directed network: strongly connected components ...)`, `(directed network: weakly connected components, the direction of the ties is ignored)` or `(undirected network)`, and `(N missing ties treated as 0)` when the network has missing ties; `r(connected)` is stored. `nwgenerate ... = nwcomponents(...)` follows the new default; `nwplot` (largest component) keeps the weak components. Example `glasgow1`: 8 components before, 14 now; `lazega_fr`: 1 before, 3 now.
- `nwclustering`: no number changes. The survey claim that the directed coefficient ignores the direction was checked and is wrong: a directed network already uses the direction (a path a -> i -> b is closed by the tie a -> b). The output now says so: `(directed network: a path a -> i -> b is closed by the tie a -> b, the direction of the ties is used)`, `(directed network symmetrized: ...)` with `symmetrize`, `(undirected network)`, `(valued network: tie values ignored, every tie counts as 1)` for `measure(binary)` on a valued network, `(two-mode network read as the one-mode network of the bipartite graph)` with `onemode`, `(N missing ties treated as 0)`, and for a two-mode network `(two-mode network: Opsahl's two-mode clustering of the nodes of mode k (level(k)), 4-paths closed by a 6-cycle; measure ...)`.
- `nwgenerate ... = large()` and `components()`/`lgc()`: follow the new default of `nwcomponents` (strong components for a directed network); `large(net, weak)` gives the previous result.
- `nwrandomwalk`: the random walk on a directed network now follows the direction of the ties (step probability w_ij / out-strength, as `igraph::random_walk(mode = "out")`); the mean hitting time is missing for a node from which the target is not reached with certainty (a dead end, or a part of the network without a way to the target). Until 3.34.0 the network was symmetrized silently. Option `symmetrize` (`sym`) gives the previous result. Needs the dense transition matrix (error 484 above the dense limit; `sym` keeps the stored-ties solver). Notes: `(directed network: the walk follows the direction of the ties; ...)`, `(directed network symmetrized: ...)`, `(undirected network)`; `r(directed)` is stored. Example `lazega_adv`, target n13: mean hitting time 37.66 before, 33.05 now (checked against the linear system solved in R, 1e-9).
- `nwcohesion`, `nwclique`, `nwkplex`, `nwnclique`, `nwnclan`, `nwkcomponents`, `nwlambda` (defined for undirected networks): a directed network whose ties are not all reciprocated is now **refused with error 198** and a message that names the option `sym`; with `sym` the symmetrized network is analysed (the larger of the two directions of a tie) and the output says `(directed network symmetrized: the larger of the two directions of a tie)`. Until 3.34.0 such a network was symmetrized silently, with the same numbers as `sym` gives now. A directed network whose ties are all reciprocated with the same value is identical to an undirected one: it is analysed and the output says `(directed network with every tie reciprocated: analysed as an undirected network)`. Undirected networks: no change. A valued network says that the tie values are ignored (the existing note, now also in `nwlambda`). Shared helper `_nwsymguard`. Dialogs: a `sym` check box (not for `nwcohesion` and `nwlambda`, which have none).
- `nwspectral`, `nwcoreperiphery`, `nwfactions`: same rule as the cohesion family: a directed network with unreciprocated ties is refused with error 198 (naming option `sym`) instead of being symmetrized silently; with `sym` the symmetrized network is analysed (same numbers as before) and the output says so; a directed network with every tie reciprocated runs and says so. `nwspectral, plot` follows the same rule (before, it refused every directed network). Dialogs of `nwspectral` and `nwcoreperiphery` have a `sym` check box. Example `lazega_adv` in the book (`nwcoreperiphery`, ch. 10): add `sym`; the printed core size and fitness are the same as before.
- `nwbalance`: on a directed network a pair of nodes with a tie in each direction and opposite signs used to take the sign of the tie from the node with the lower index (the result depended on the order of the nodes). The sign of such a pair is not defined: the command now stops with error 198 and says how many pairs are affected (use `nwsym` with the mode of your choice first). Networks without such pairs (all undirected networks, directed ones whose mutual pairs agree in sign) give the same numbers as before. The output now says how a directed network is read (a pair is tied when there is a tie in either direction), that only the sign of a tie counts on a valued network, and `(N missing ties treated as 0)`.
- `nwdiffuse` (`exposure`, `threshold`, `long`, `simulate`): no number changes; the output now states how the network was read, one line each: `(directed network: the exposure of a node comes from the nodes it sends ties to; option incoming uses the nodes it receives ties from)` or `... receives ties from)`, `(undirected network)`, `(valued network: tie values ignored, every tie counts as 1; option valued weights by the tie values)` or `(valued network: exposure weighted by the tie values)`, `(self-loops ignored; option self counts them)` (only when the network has self-loop ties) and `(N missing ties treated as 0)`.
- `nwmaxflow`: no number changes; the output now says `(directed network: flow follows the direction of the ties)` or `(undirected network: a tie carries flow in both directions)`, `(valued network: every tie has capacity 1, tie values ignored; option weighted uses the tie values as capacities)` / `(valued network: the tie values are the capacities)` / `(every tie has capacity 1)`, and `(N missing ties treated as 0)`.
- `nwkatz`: a directed network is now analysed as it is also in the default distance-decay form (before, it was symmetrized unless `nosym`, and the text `Network has been symmetrized for calculation.` was printed even for undirected networks and for `walks`, which never symmetrized). `_out` uses the distances from a node to the nodes it reaches, `_in` the distances from the nodes that reach it; option `sym` gives the previous result (`_in` and `_out` equal); `nosym` is accepted and is the default. With `walks`, `_in` equals `igraph::alpha_centrality()` (checked on `lazega_adv`, alpha 0.05, 1e-9); `sym` now also works with `walks` (the larger of the two directions). The output says `(directed network: ...)`, `(directed network symmetrized: ...)` or `(undirected network)`, whether the distance-decay form ignored the tie values of a valued network, and `(N missing ties treated as 0)`. Undirected networks: same numbers. Example `lazega_adv`, alpha 0.2, node 1: `_in` = `_out` = 6.16 before, `_in` 5.68 and `_out` 3.568 now (`sym`: 6.16). Dialog: the `nosym` check box is replaced by `sym`.
- `nwsimindex`, `nwsimmelian`: no number changes; the output says `(directed network: the neighbours of a node are the nodes it sends ties to and the nodes it receives ties from)` (`nwsimindex`), `(directed network: only mutual ties are used)` (`nwsimmelian`), `(undirected network)` and `(N missing ties treated as 0)`. No option was added: the direction rule is the definition of the measure.
- `nwkcore`, `nwego`, `nwconstraint`: no number changes; the output says how a directed network is read (`nwkcore` and `nwego`: the neighbours of a node are the nodes it sends ties to and the nodes it receives ties from; `nwconstraint`: the proportions p_ij come from the out-ties of node i, whereas `nwburt` uses both directions), `(undirected network)` and `(N missing ties treated as 0)`. `nwdegree` and `nwcomponents` also print `(N missing ties treated as 0)` when the network has missing ties. `nwcomponents` test `test_usair_full_data` now uses `weak`.
- `nwevcent`: on a directed network the default is now the **in-tie** eigenvector centrality (the score of a node comes from the nodes that send ties to it), as `igraph::eigen_centrality(directed = TRUE)` (checked on the strongly connected `lazega_adv`, scaled to a maximum of 1, 1e-8; on a network that is not strongly connected igraph and nwcommands both give 0 or tiny scores outside the dominant strongly connected part). Until now the default was the out-tie centrality (the igraph result on the transposed network). New option `out` gives the previous result; `sym` and `out` together are error 198. Note line: `(directed network: the centrality of a node comes from the nodes that send ties to it)`, with `out` `(... from the nodes it sends ties to)`. Undirected networks and `sym`: same numbers. Dialog: check box `out`.
- `nwinduced` (`measure(betweenness|closeness|evcent)`): a directed network is analysed as it is, as `nwbetween`, `nwcloseness` and `nwevcent` now do (the endogenous centrality equals the direct call; `evcent` uses the in-ties), for the full network and for every network without one node, so the induced and exogenous values of a directed network change with them. New option `sym` symmetrizes first (the larger of the two directions of a tie) and gives the result of 3.34.0 and earlier. `measure(degree)` still stops on a directed network. Test: `test_nwinduced` compares the endogenous values on the directed `lazega_adv` with the direct calls, with and without `sym`.

### Added
- `nwnetworkdata` (new): imports the networks of David Schoch's R package networkdata (989 data sets, 2,274 networks) into nwcommands; `nwwebuse schoch`, `nwwebuse schoch list|describe name`, `nwwebuse schoch name` and `nwwebuse name, schoch` call it. No data are shipped: the original `.rda` file is downloaded from Schoch's repository when a data set is asked for, cached in the PLUS folder and converted by R (needs R with the package igraph, only for this reader). Names are checked against the catalogue before anything is downloaded or started, `from()` accepts only the official repository or an existing folder, and every load prints which network was loaded (nodes, ties, directed or undirected, one-mode or two-mode, binary or valued) and where the data came from. Per-data-set documentation (sources, references) is on the website, not in the install.
- `nwgeodesic` and `nwclustering` take a **list of networks**, as `nwsummarize` does (wildcards such as `draw_*` expand the same way). A table with one row per network is printed (`nwgeodesic`: nodes, average path length, diameter, radius, share of connected pairs, average distance over the connected pairs; `nwclustering`: nodes, measure, average and global coefficient) with one line that says how each kind of network was read (the notes of the single-network call). `r()` holds the results of the last network of the list, exactly as the single call for it. New option `save(file [, replace])` writes a Stata data set with one observation per network (also for one network), numbers stored as `double`: `nwgeodesic` writes `name directed valued nodes numpaths unconnected avgpath diameter radius alpha connected avgpath_connected diameter_connected` (`avgpath`, `diameter`, `radius` are missing, not -1, when not every pair is connected; `avgpath_connected` and `diameter_connected` are missing when `unconnected()` replaced the distances of unconnected pairs), `nwclustering` writes `name directed valued twomode nodes measure level cluster_global cluster_avg nmissing` (a two-mode network: Opsahl's global coefficient and the mean over the nodes of `level()`; `level` is missing for a one-mode network). Options that make a variable, a network or a graph for one network (`nwgeodesic`: `generate()`, `name()`, `xvars`, `plot`, `gname()`, `saving()`, `export()`; `nwclustering`: `generate()`, `ra`) are error 198 with a list. A two-mode network in a list of `nwclustering` needs no `generate()`. A call for a single network without `save()` is unchanged (output, `r()`, variables). After `nwgeodesic` with a list the distance network `_geodesic` holds the distances of the last network. Dialogs: a field for `save()`; the `nwclustering` dialog no longer insists on `generate()`. Test `test_core_netlist`: every row against the single call to 1e-12, also for 20 networks from `nwrandom ... ntimes(20)` and `nwsmall ... ntimes(20)`.

- `nwdyadprob` and `nwhomophily`: option `ntimes(#)` draws that many networks, named `name_1`, `name_2`, ... as `nwrandom`, `nwsmall`, `nwring` and `nwpref` do; `r(netlist)` lists them. A call without `ntimes()` is unchanged; `ntimes(0)` is error 198 in `nwdyadprob`. `nwhomophily` builds the dyad weights once and draws all networks from them. Dialogs: a spinner for `ntimes`.
- `nwmixing`: the output says how the table is read, `(directed network: the table counts every tie from ego (row) to alter (column))` or `(undirected network)`, and `(N missing ties treated as 0)` when the network has missing ties. `nwmixing` takes one network (no list), so there is no per-network `save()` for the E-I index.
- Missing-ties note `(N missing ties treated as 0)` (printed only when the network has missing ties; checked for each command that the result with a missing tie equals the result with 0 in its place) in `nwbetween`, `nwcloseness`, `nwevcent`, `nwpagerank`, `nwdyads` and `nwmotifs` (one-mode form). `nwtriads` shows it already through the clustering coefficient it reports; `nwhomophily` reads no network.
- `nwsummarize`: the output says `(valued network: edges and density count every tie with a non-zero value; minimum and maximum are tie values)` for a valued network, and for a network with missing ties `(N missing ties are not counted as ties and not as pairs in the density)` (`; the measures of detail treat them as 0` with `detail`). Missing ties are not treated as 0 by the summary itself: the density is taken over the pairs that have a value.

### Fixed
- The missing-ties note (`_nwmissnote`) counted the within-mode cells of some two-mode networks when the nodes of the two modes are not in two blocks (alphabetical order, e.g. `davis`): the note named 56 missing ties for a network that has none. It reads the cells between the two modes by node mode now.

### Changed
- Help: `nwsummarize` says exactly what `r(missing_edges)` counts (all cells without a value, including the diagonal cells of a network without self-loops, and both cells of a missing tie in an undirected network), how to get the number of missing off-diagonal cells (`r(missing_edges)` - `r(nodes)`) and warns against testing `r(missing_edges)` > 0.

## [3.34.0] - 2026-11-21

### Added
- `nwburt, direction(both|out|in)`: which ties of a directed network count as the ties of ego. `both` (the default) is the convention of 3.33.0, Burt's z_ij + z_ji, and every printed number is unchanged. `out` uses only the ties ego sends (z_ij) and reproduces the results printed by versions before 3.33.0 for a binary directed network; `in` uses only the ties ego receives (z_ji), the result of `out` on the transposed network. The formulas of effective size, efficiency, constraint and hierarchy are the same, also with `dyadredundancy` and `dyadconstraint`, and for a valued network (all-ones values give the binary result). The header says which ties were used; `r(direction)` is stored. On an undirected network the option has no effect. Help file and dialog updated. The Mata library and the plugin are unchanged (no lockstep rebuild of the model packages).

Tested on macOS with Stata 17 and Stata 18 (the new test, the `nwburt` tests, the valued-network test and the dialog tests; on Stata 18 only these four, plus the earlier brokerage-kernel, plot and dialog tests on Stata 17). On Linux (Ubuntu 22.04) and Windows 11 (both StataNow 19.5 MP): the new test, the `nwburt` tests, the brokerage kernels, the dialog tests and the core plot tests.

## [3.33.0] - 2026-11-21

### Results that change
- `nwburt` on a **directed binary network** now uses both directions of every tie, as Burt's measures are defined and as `igraph::constraint()` and the weighted `nwburt` of a valued network do: the tie strength is z_ij + z_ji and the proportions are p_ij = (z_ij + z_ji) / sum_k (z_ik + z_ki). Before, the binary measures used the out-ties only. The printed effective size, efficiency, constraint and hierarchy, and the variables `_effsize`, `_efficiency`, `_constraint`, `_hierarchy`, change for every directed network that is not symmetric; undirected networks and directed networks whose ties are all mutual give the same numbers as before. An all-ones network stored as valued and the same network stored as binary now give identical results. With `dyadredundancy` and `dyadconstraint` the two dyadic networks follow the same definition (their row sums are the node constraint). Small example, 5 actors and 8 directed ties: constraint 0.500, 1.250, 0.500, 1.000, 1.000 before, 0.661, 0.543, 0.482, 0.500, 0.797 now (the values of `igraph::constraint()`).
- `nwcompare`: for a block model (`nwsbm`), the number of parameters *k* is `e(npar)` plus the free membership proportions, Q - 1 (Q1 - 1 plus Q2 - 1 for a two-mode network), the parameters that the ICL penalty of the block model counts as well. On the Lazega friendship network with 3 blocks *k* is now 11 (before 9: `e(npar)` = 9 omitted the 2 free proportions). AIC and BIC are not shown for the block model, so no other number changes.

### Added
- `nwcoreperiphery, restarts(#)`: the number of starts of the local search; default 1 (the degree-based start, output and random numbers unchanged). With more starts, further searches begin from random partitions (each actor in the core with probability one half) and the partition with the highest fitness is kept, never lower than that of the degree-based start. `seed(#)` makes the random starts reproducible. The output adds a line with the number of starts and the number that reached the best fitness; `r(restarts)`, `r(beststart)` and `r(nbest)` are stored. Available up to 2,000 nodes. On the Lazega advice network the default search stops at a core of 18 (fitness 0.281096); with `restarts(200) seed(1)` the best partition has a core of 20 (the same 18 plus two lawyers, fitness 0.281280), reached by 128 of the 200 starts. Help file, dialog and test updated.
- `nwmovie`: the help file and the error messages for a missing `ffmpeg` (or an `ffmpeg` without libx264 or libvpx-vp9) say what to install on Linux (`sudo apt install ffmpeg` on Debian and Ubuntu, `sudo dnf install ffmpeg` with RPM Fusion on Fedora), that Windows and macOS need nothing for `.mp4` and `.webm`, and that `export(.gif)` works everywhere without extra software; the reason (on Linux the viewer's web engine cannot encode video, so a GIF is drawn and `ffmpeg` converts it, with the colours of a 256-colour GIF) is given. The behaviour is unchanged. The install page of the website has a short section on it.

### Help
- `nwcompare`: the help file states what *k* is for each model class.

The Mata library is unchanged (no lockstep rebuild of the model packages).

Tested on macOS with Stata 17 and Stata 18: the new test, the tests of the touched commands, the core plot tests and the dialog tests. On Linux (Ubuntu 22.04) and Windows 11 (both StataNow 19.5 MP): the new test, the tests of the touched commands, the plot and dialog tests; on Linux also the real `nwmovie` export to `.mp4` and `.webm` with `ffmpeg`.

## [3.32.1] - 2026-11-20

### Fixed
- `nwtabulate, attribute()` on an undirected network counted the within-group and between-group ties wrongly: it kept every second row of the list of ties, but the two directions of a tie are not in neighbouring rows, so some ties were counted twice and others not at all. The printed table, the number of ties, the E-I index and `r(table)`, `r(N)` and `r(EI_index)` change for undirected networks (for example a star of three nodes with one node in a group of its own had printed 2 within-group ties and E-I = -1; the correct numbers are 1 within, 1 between, E-I = 0). Each tie is now counted once. Directed networks are unchanged. The permutation p-value and the plot options are unchanged.
- `nwbackbone, method(fixedrow) signed`: a pair of rows with the smallest possible overlap got a missing upper p-value (Stata's `hypergeometric()` returns missing below the lowest possible value), so the pair was never kept and was not counted in the multiple-testing correction. On the Davis data the backbone now keeps 6 ties (before 5), the same as the R package backbone. Unsigned backbones and the other methods are unchanged.
- `nwbackbone, method(fdsm)` prints a note before it starts when the default number of Monte Carlo draws exceeds 1,000,000 (for example 23,462,686 for the Davis data with `signed` and `mtc(BH)`), naming the number and the option `trials()`. The results are unchanged.
- `nwdiffuse curve` stopped with r(3301) when all adoption times fall in one period. It now prints the one row. The Rate column printed 1.000e+15 when `t0()` is earlier than the first adoption; it now prints a missing value (`.`) in a period with new adopters when nobody had adopted before.
- `nwcloseness` prints a one-line note on valued networks that tells how the tie values are used (least-cost distances, or step counts with `binary`), like `nwdegree` and `nwbetween`.

### Help
- `nwdiffuse`: the direction of `simulate` (a node is influenced by the nodes it sends ties to; `incoming` for the other direction) and the meaning of the Rate column (growth of the cumulative number of adopters, not a hazard rate) are stated at the top.
- `nwcommunity`: `symmetrize` keeps a tie when either direction has one (the larger of the two values), not only mutual ties.
- `nwcoreperiphery`: the search is local; a different starting partition can give a better core.

Tested on macOS (Stata 17): the new test and the tests of the touched commands, the core plot tests and the dialog tests. On Linux (Ubuntu 22.04) and Windows 11 (both StataNow 19.5 MP): the new test, the tests of the touched commands, the plot and dialog tests, and the star and Davis checks pass. Stata 18 was not run.

## [3.32.0] - 2026-11-20

### Added
- `nwmovie export()` on Linux: `.mp4` and `.webm` are made with `ffmpeg` (libx264 and libvpx-vp9) from a GIF that the viewer draws at 25 frames per second; `.gif` is written by the viewer itself and needs nothing. Without `ffmpeg` (or without that encoder) the command stops at once with error 498, before anything is launched. On macOS and Windows nothing changes: the viewer encodes the video itself. Where a viewer engine can encode WebM through WebCodecs it does so with the vendored `webm-muxer.js` (MIT; registered in `NOTICE.md`).

### Fixed
- `nwmovie export()`: a failure, a stall (120 s without progress), a viewer that has disappeared without a file, or a Linux session without a display ends the command with error 498, and the viewer is stopped. On macOS the command stops at once (error 498) when the screen is locked; other viewer windows are never touched.
- `nwmovie` erases every temporary file it made (pages, keyframe files, export files, the staged viewer and its profile folder) on success and on failure.
- Two exports started together no longer collide: temporary file and viewer names are unique per Stata process. The random stream is unchanged, so seeded layouts stay the same.
- `export()` without `fname()` no longer writes `movie.html` into the current folder; the page goes to the temp folder.
- `nwinstall, remove path()` no longer stops in console Stata at the window menu.

Tested on macOS (Stata 17): `test_nwmovie`, `test_nwmovie_kill`, `test_nwinstall_ancillary`, `test_nwcoefplot`, `test_nwcore_plots`, `test_nwcore_plots2`, `test_dlg_options` and `test_dlg_plots` pass (in `test_nwinstall_ancillary` only the final real-export step stops, with the expected locked-screen error 498). The real macOS viewer export was not run for this release because the screen was locked; the macOS code path is unchanged, and an earlier build of the same branch produced an `.mp4` on the Mac. The `.mp4`, `.webm` and `.gif` exports, concurrent exports and the cleanup were tested on Linux (Ubuntu 22.04) and on Windows 11 (both StataNow 19.5 MP). Stata 18 was not run for this release.

## [3.31.0] - 2026-11-20

### Added
- `nwcoefplot, msymbol(list)`: one marker symbol per model, in the order of the models (for example `msymbol(O D T)`), so that a black-and-white print tells the models apart. Fewer symbols than models are used again from the start; more symbols than models, or a name that is not a marker symbol, stop with error 198. Without the option the picture is unchanged. Help file, dialog and test updated.

Tested on macOS (Stata 17), on Linux (Ubuntu 22.04) and on Windows 11 (both StataNow 19.5 MP): `test_nwcoefplot`, `test_nwcore_plots`, `test_nwcore_plots2`, `test_dlg_options` and `test_dlg_plots` pass. Stata 18 on the Mac: quick checks of 3.30.0 passed; 3.31.0 was not rerun there.

## [3.30.0] - 2026-11-20

### Added
- `nwdegree, plot`: the degree distribution as a graph (histogram of the generated degree variable; outdegree and indegree side by side for a directed network); `ccdf` draws P(degree >= k) on log-log axes; `standardize` is respected; `name()`, `saving()`, `export()` and graph options as in the plot convention. One one-mode network (two-mode, a list of networks, and a valued network without `binary` stop with error 198). Without `plot` the extra options are still the tabulate options.
- `nwgeodesic, plot`: histogram of the finite geodesic distances (number of pairs at each whole distance, unconnected pairs counted in a note), `average` marks the mean distance of the connected pairs; the graph name option is `gname()` because `name()` is the distance network. Two-mode and valued networks (without `binary`/`alpha(0)`) stop with error 198.
- `nwdiffuse curve, plot(cumulative|new|both)`: `new` draws the new adopters per period as bars, `both` the cumulative proportion and the bars side by side; plain `plot` and `graph` draw the cumulative line as before.
- `nwspectral, plot`: scree plot of the Laplacian eigenvalues with the algebraic connectivity marked; `embedding` adds the second and third eigenvector as a scatter. Two-mode and directed networks stop with error 198.
- `nwtriads, plot expected`: the expected count of every triad type under random dyad types with the dyad census fixed (the uniform distribution on networks with the same dyad census, closed form) is written under the observed count.
- Help files, dialogs and `cscripts/test_nwcore_plots2.do` for these options; examples of the ordered matrix (`nwplotmatrix, sortby() group()`) in the help files of `nwcoreperiphery`, `nwfactions` and `nwconcor`.
- Dialogs: `name`, `saving` and `export` entries in the `nwdendrogram` dialog, `saving` and `export` entries (tab Save/export) in the `nwplotmatrix` dialog, a `name` entry in the `nwmixing` dialog; the `name` field of the `nwcorrelate` dialog says that it also names the graph of the permutations. `cscripts/test_dlg_plots.do` checks that the dialogs of all plot commands carry their plot options and that the command line a dialog emits runs.

Tested on macOS (Stata 17), on Linux (Ubuntu 22.04) and on Windows 11 (both StataNow 19.5 MP): the tests of the new plot options, the dialog tests and the plot tests of every changed command; on Linux and on Windows the export widths of the new plots (`nwdegree`, `nwgeodesic`, `nwspectral`, `nwdiffuse curve, plot(both)`, `nwtriads` with `expected`) were measured exactly, and Windows was also run from a folder with a space in its name. Stata 18 on the Mac was not run for this release.

## [3.29.0] - 2026-11-20

### Added
- `nwcoefplot`: coefficient plot (point estimates with confidence intervals) after `nwsaom`, `nwergm`, `nwdynam`, `nwrem`, `nwalaam`, `nwlsm` and any command that leaves `e(b)` and `e(V)`, so that the user-written `coefplot` is not needed. `level()`, `keep()` and `drop()` (names, `*` and `?` patterns, `eq:name`; the `keep()` order is the plot order), `noconstant`, `eform` (odds ratios for `nwergm`, `nwalaam` and `nwlsm` with Bernoulli or binomial family; rate ratios for `nwdynam`, `nwrem`; refused for `nwsaom` and `nwsbm`), one panel for each equation by default (`byeq`; `mixeq` for one axis), several stored models side by side (`nwcoefplot m0 m1 .`, `common`), `title()`, `name()`, `saving()`, `export()` and all other `twoway` options. The axis of each panel always contains the intervals and the reference line (0, or 1 for `eform`) with a margin, so the dashed line is never clipped in a panel that holds only a constant; on the log axis of `eform` the labels are 1-2-5 values inside the range and the first interval does not start at the edge. Dialog and menu entry (Statistical Models). Test `cscripts/test_nwcoefplot.do` (fake fits and real `nwergm` and `nwlsm` fits when the packages are found).
- `nwcompare, graph coefopts()`: also draws the coefficients of the compared models side by side (through `nwcoefplot, common`).
- The plot convention of the nwcommands family (same option names in every package). New helper `_nw_gfinish` (verbs `version`, `check`, `title`, `blk`, `save`) checks and normalises `name()`, `saving()`, `export()` and the graph options, applies black default titles to new plots, saves and exports the graphs (the graph name goes before the file extension when several graphs are written), and gives one error text for options used without `plot`. The model packages use it from their next releases (they need this core version or later).
- `nwcoefplot`, `nwcompare, graph`: default graph names `coefplot` and `compare`; `name()` and `saving()` replace an existing graph or file without `, replace`; `export()` exports this graph; `title("")` removes the default title; default titles are black; `nwcompare` gets `name()`, `saving()`, `export()` and `plot` (synonym of `graph`).
- `saving()`, `export()` and the pass-through of graph options (appended last to the `twoway`, `graph bar` or `graph combine` call, so they replace defaults) for `nwcug`, `nwtriads`, `nwdyads`, `nwmotifs` and `nwcorrelate` (plot options); for `nwqap` (graph saving is `gsaving()`, because `save()` writes the permutation data); `nwmixing` and `nwtabulate` (the two pictures are named `name_plot` and `name_eiplot`; the pictures stay unnamed when none of `name()`, `saving()`, `export()` is given; `plotoptions()` and `eiplotoptions()` stay); `nwdiffuse curve` (also `plot` as a synonym of `graph`); `nwplotmatrix` and `nwdendrogram` (`name()`, `saving()`, `export()`). `nwcorrelate, noplot` switches off the density plot that is drawn with `permutations()` above 1. `saving()`, `export()` and graph options without the plot option stop with r(198); `name()` without the plot option is still accepted and ignored in the commands that accepted it before. The default pictures of all these commands are unchanged (default calls produce the same PNG files as before).
- Help files and dialogs of these commands list the new options (plot entries added to the `nwdyads`, `nwtabulate` and `nwcorrelate` dialogs; `saving` and `export` entries in the `nwcug`, `nwqap`, `nwtriads`, `nwmixing`, `nwcoefplot` and `nwcompare` dialogs).

### Fixes
- `export(file.png, width(N))` of the plot commands wrote the file but ignored the options after the comma (width, height, ...) when the export string reached `_nw_gfinish save` wrapped in an additional compound-quote layer (`nwcug`, `nwdyads`, `nwtriads`, `nwcoefplot`, `nwcompare` and the other callers). `_nw_gfinish check` and `save` now strip such outer quote layers, so the literal and the double-quoted calling style give the same pictures; tests read the pixel width of each exported PNG.

## [3.28.0] - 2026-11-19

### Added
- `nwspmatrix`: spatial weighting matrix from a network, for `spregress` (agrees with `sna::lnam` to about five digits); `nwdiffuse`: exposure, thresholds and adoption tools for diffusion and contagion (equal to netdiffuseR 1.25.1 to nine digits). Both have dialogs and menu entries.
- `nwbackbone`: backbone extraction after the R package backbone 3.0.4. One-mode valued networks: `global`, `disparity`, `lans`, `mlf`; two-mode projections: `sdsm`, `fdsm`, `fixedrow`, `fixedcol`, `fixedfill`; multiple-testing corrections as `p.adjust`, `signed`, `keepvalues`, `missingaszero`, `project(1|2)`. The p-values and retained ties equal the R values for all deterministic methods (`cscripts/test_nwbackbone.do`, fixture made by R); `fdsm` is Monte Carlo. Not included: SDSM-EC, `backbone_from_unweighted`, valued bipartite networks. Dialog and menu entry (Manipulate Networks).
- `nwcommunity, algorithm(leiden)` (Leiden of Traag, Waltman and van Eck 2019; `beta()`, `iterations()`, `trials()`) and `algorithm(infomap)` (undirected two-level map equation; `r(codelength)`). Mata only, meant for up to a few thousand nodes. The partitions and the modularity agree with igraph (`cscripts/test_nwcommunity_algorithms.do`). Infomap has no directed or multilevel map equation, and its code length differs from igraph's, which teleports on undirected networks. Dialog extended.
- `nwcompare`: table of N, log likelihood, number of parameters, AIC, BIC and ICL of stored (or active) estimation results of nwergm, nwsaom, nwlsm, nwsbm, nwalaam and Stata's own commands, with a note that criteria of different model families are not always comparable. Dialog and menu entry (Statistical Models).
- Menu entries for the nwsbm and nwlsm dialogs (listed when the dialog is installed).
- The model packages `nwsbm` and `nwlsm` are known to the core: `nwinstall, models`, `buildplugin()`, `buildmata()`, `nwversion`, the help index and `tools/release_preflight.py` list them.

## [3.27.0] - 2026-11-18

### Added
- The model package `nwalaam` (autologistic actor attribute models, ALAAMs) is known to the core: `nwinstall, models` and `nwinstall, everything` install it, `modelpkg(nwalaam)`, `buildplugin(nwalaam)` and `buildmata(nwalaam)` work, `nwversion` lists it, `help nwtopical` and `help nwalphabetical` link it, and `nwinstall` sets up a menu entry and a dialog box (Statistical Models) for it once it is installed.

## [3.26.0] - 2026-11-16

### Added
- `nwinstall, buildplugin(nwrem)` compiles the native plugin of nwrem 1.3.0 on this computer, like the plugins of the other model packages; `buildplugin(all)` now covers five packages.

Tested on macOS with Stata 17 BE, Stata 18 BE and StataNow 19.5 MP (full core suite, 258 tests per version: all pass). Windows and Linux: not yet tested for this release.

## [3.25.1] - 2026-11-15

### Removed
- The example data sets `socialevolution` and `socialevolution_nodes` (phone calls among students, from the Social Evolution study of the MIT Media Lab, Madan et al. 2012) are no longer distributed with the package: their redistribution is not permitted by the licence of the original data. `nwwebuse socialevolution` and `nwuse data/socialevolution` therefore no longer work. The email log `manufacturing` (with `manufacturing_nodes`, CC0) is the example event data set; its entry in `netexample` and on the data page of the website explains how to use it.

### Changed
- The tests that used the phone-call data now use `manufacturing`.
- Website menu: the pages of the core package that are not tutorials now come after the 21 tutorials, so Tutorial 21 follows Tutorial 20.

Tested on macOS with Stata 17 BE, Stata 18 BE and StataNow 19.5 MP (full core suite, 258 tests per version: all pass; `test_nwinstall_ancillary` ends at its movie-export check because the screen was locked, and `test_nwinstall_everything` was run with the model repositories next to the core). The change is data, tests and documentation; the Mata library is unchanged (same hash as 3.25.0). Not tested on Windows or Linux for this release.

## [3.25.0] - 2026-11-14

### Results that change (read before you re-run old analyses)
- **Temporal networks (declared with `time()`, `interval()` or `eventtime()` in `nwset`) are no longer flattened silently by the commands that save, export or copy networks.** Networks that are not temporal behave exactly as before; every change below concerns temporal networks only.
  - `nwsave` + `nwuse` / `nwwebuse` / `nwappend`: the network came back as an ordinary network with its ties aggregated over all times (an event network of 439 calls came back as 84 arcs, "Temporal: false"). It now comes back temporal with every event, time and interval. Code that relied on the aggregated network after loading must call `nwattime` or `nwtoedge ..., aggregate`.
  - `nwduplicate` of a temporal network gave a network that was not temporal; the copy is now temporal (so are `nworder` and the copies made by `generate()` of `nwdropnodes` / `nwkeepnodes` and by `nwsubset`). `nwdropnodes`, `nwkeepnodes` and `nwsubset` dropped the temporal data of the network they shortened; they now keep the events, times and intervals among the remaining nodes.
  - `nwexport`: for a temporal network, `type(pajek)`, `type(ucinet)`, `type(gml)` and the edge list of a two-mode network used to write the ties aggregated over all times without a word. They now stop with error 198 and write nothing; the new option `aggregate` gives the old file. `type(edgelist)` of a one-mode temporal network used to write the aggregated ties; it now writes one row per event (observation, interval) with the times (`ego alter [value] time`); `aggregate` gives the old file.
  - `nwtoedge` of a temporal network lists each tie once, aggregated over all times, as before, and now prints a note saying so; the new option `aggregate` gives the same list without the note, and the new option `time` lists the events.
  - `nwload` of a temporal network prints a note that the variables hold the ties aggregated over all times; `nwsync, fromstata` warns that the times stay as they were.

### Added
- **Temporal networks in `nwsave`, `nwuse`, `nwwebuse` and `nwappend`.** A temporal network is saved with its times and comes back exactly: every event of an event network (sender, receiver, time and value, in the order given), every observation of a tie of a snapshot network (a tie can come and go), every interval, the temporal type and the names of the time variables, for one-mode and two-mode networks and for several networks in one file. The file holds the aggregated ties as before, so an earlier version loads the aggregated network; a file without a temporal network has no new columns, and files written by earlier versions load as before.
- **`nwtoedge ..., time`** replaces the data in memory by one row per event (observation of a tie, interval) of a temporal network: `_ego`, `_alter`, `_time` (`_start` and `_end` for intervals) and `_value`; `nwset` turns the rows into the network again. **`nwtoedge ..., aggregate`** states that the list holds the ties aggregated over all times.
- **`nwexport ..., type(edgelist)` writes the times of a temporal network and `nwimport ..., type(edgelist, eventtime)`, `type(edgelist, time)` and `type(edgelist, interval)` (with `directed` or `undirected`) read them back.** `nwexport ..., aggregate` exports the ties aggregated over all times in any format.
- **Data sets `manufacturing` and `manufacturing_nodes`**, for `nwwebuse`: 50,233 emails (sender, receiver, time in days since 1 January 2010) among 144 employees of a manufacturing company between January and 30 September 2010, and the reporting hierarchy of the 154 employees with a known supervisor (supervisor, level, division). Plain data to declare with `nwset sender receiver, eventtime(t)`; `keep if t < 14` gives a small subset (2,738 emails, 129 employees). Subset of Michalski 2020, doi:10.7910/DVN/6Z3CGX, CC0 1.0. Source and changes: `help netexample`, `NOTICE.md` and the website page "Data sets". New test `cscripts/test_manufacturing_data.do`.
- New test `test_temporal_io`.

### Fixed
- **`nwmovie ..., export(file)` no longer leaves the viewer running.** When the viewer never wrote the file (typically on macOS with a locked screen) the command stopped with r(498) after `timeout()` seconds but the viewer process went on running. `nwmovie` now stops the viewer it started (found by the exact name of its staged copy, never by a pattern that could match another process) on a timeout, on an error from the viewer and after a finished export. On macOS it also checks before the viewer is started whether the screen is locked and stops at once with a message (r(498)); if the check cannot be made the command goes on as before. The default `timeout()` is unchanged. New test `test_nwmovie_kill`.
- **A second error line after the command's own message.** 335 error exits in 100 commands showed their message and then called `error N`, which printed Stata's canned text for N ("invalid syntax" for 198) as a second line; they now end with `exit N`. Return codes are unchanged. Where a command shows no message of its own, Stata's text is still printed. New test `test_noextra_errtext`.

Tested on macOS with Stata 17 BE, Stata 18 BE and StataNow 19.5 MP (full core suite, 259 tests per version; two tests need the model repositories next to the core and an unlocked screen and were run separately), on Windows 11 with StataNow 19.5 MP (254 of 259 tests ran clean; the other five end with the known Stata teardown crash after their checks) and on Linux (Ubuntu 22.04) with StataNow 19.5 MP: not yet tested for this release.

## [3.24.0] - 2026-11-13

### Added
- **A public Mata interface, `nwapi_*()` (`help nwapi`).** Twenty-one read-only Mata functions give your own Mata code a small, stable view of the networks in memory: `nwapi_count()`, `nwapi_names()`, `nwapi_exists()`, `nwapi_current()`; the properties `nwapi_nodes()`, `nwapi_ties()`, `nwapi_directed()`, `nwapi_valued()`, `nwapi_twomode()`, `nwapi_selfloops()`, `nwapi_temporal()`, `nwapi_nodelabels()`, `nwapi_modes()`; and the ties as `nwapi_matrix()` (a copy without missing values: the diagonal and the dyads inside a mode of a two-mode network are 0, unlike `nwtomata`), `nwapi_edgelist()` (each tie once in an undirected network), `nwapi_outdegree()`, `nwapi_indegree()`, `nwapi_neighbors()`, `nwapi_inneighbors()` and `nwapi_nodeid()`. A network is given by its exact name (`""` is the current network), nodes by number or label. Errors use the documented return codes (482, 485, 198; 484 for `nwapi_matrix()` above 20,000 nodes). Names, arguments and result shapes stay the same within a major version; `nwapi_version()` is the generation of the interface. The Mata classes behind it stay internal. New help file `nwapi`, a section in `help nwprogramming`, and a test `test_nwapi` that fails when a signature changes. The core Mata library changes, so the model packages are rebuilt with the next lockstep release.
- Linux: when the native viewer cannot start because a WebKit library is missing, `nwplot, interactive` and `nwmovie` say so and show the install command for apt, dnf and pacman (it is shown, never run) instead of failing silently.
- **Console Stata (Linux, macOS):** `_nwopenviewer`, which `nwplot, interactive` and `nwmovie` use, has no `view` window to fall back on there; it prints the path of the file instead of stopping with r(199).

### Fixed
- **A stray `invalid syntax` line after an error message.** Commands that stop with their own message now end with `exit` instead of `err`, which printed a second line, `invalid syntax`, after the real message.
- **`c(tmpdir)` without a trailing slash** (Linux console Stata) no longer gives file names such as `/tmpnwedit_...` for the viewer, the movie and other temporary files.
- **Tests:** the dialog tests are skipped under console Stata; `test_animate` detects ImageMagick; `test_plotfix`, `test__nwopenviewer` and the extended tests handle a `c(tmpdir)` without a trailing slash and a Linux system where the viewer cannot start; the expectations of the extended tests are updated for `nwclustering` without `generate()` and string group variables in `nwbrokerage`.

Tested on macOS with Stata 17 BE, Stata 18 BE and StataNow 19.5 MP (the full test suite), on Windows 11 with StataNow 19.5 MP and on Linux (Ubuntu 22.04) with StataNow 19.5 MP. On Linux, in console Stata, the tests that need the Stata GUI (`nwinstall, usermenu` and `remove`) cannot run and are not counted.

## [3.23.0] - 2026-11-13

### Results that change (read before you re-run old analyses)
- **Return codes.** A Stata variable that already exists (a `generate()` target, for example of `nwdegree`, `nwbetween`, `nwcloseness`, `nwplot`, `nwgen`, `nwaltergen`) now stops with r(110), Stata's own code for "already defined", in every command; about 40 commands used r(99), which is not a Stata code. Other uses of r(99) now give the code of `help nwerrorcodes` for their situation: a network that already exists r(483) (`nwgeodesic`, `nwreach`, `nwbridges`, `nwneighbor, subnet()`), a node that does not exist or a node id out of range r(485) (`nwmaxflow`, `nwrandomwalk`, `nwneighbor`, `nwnode, egoid()`), `nwnode` without `ego()` or `egoid()` r(198). `nwaltergen` with fewer rows of data than nodes gives r(2001) (was r(4)). Do-files that test `_rc == 99` must be updated.
- **Temporal networks: a tie observed at several times keeps all of them** (see Fixed): `nwattime` of a network declared with `time()` or `interval()` now returns ties that came and went, which it dropped before; `nwsummarize` and `nwattime` agree now.
- **`nwplot, importcoords()` / `edgeimport()` node size.** A node-size slider value saved by the interactive view is now used as `nodefactor()` itself (a page saved at slider 1 comes back with the default sizes); before it was multiplied by 0.2 and the nodes came back small. An explicit `nodefactor()` still wins.

### Added
- **`nwregular`** finds the classes of regularly equivalent nodes (maximal regular equivalence, the CATREGE refinement of Borgatti and Everett 1993 for binary data): nodes are in one class when they send ties to, and receive ties from, the same classes. It stores the class of each node in a variable and returns the number of classes and the image matrix (`r(classes)`, `r(image)`). New test `test_nwregular`.
- **`nwegoplot`** draws the ego network of one node: ego in the center, the alters on a circle in an order that keeps their ties short (connected groups together, spectral order inside a group), `sortby()` to group the alters by an attribute, `hop(2)` for the nodes at distance two on an outer ring. The ties of ego are drawn light and the ties among the others dark, and ego is drawn larger, unless `edgecolor()` or `size()` are given; all other options go to `nwplot`. New test `test_nwegoplot`.
- **`nwbalance ..., reps() seed()`** compares the share of balanced triads with random signs on the same ties (each tie positive with the observed share of positive ties as probability): mean and standard deviation over the draws, the closed-form expectation, and the number of draws at least as balanced (`r(null_mean)`, `r(null_sd)`, `r(null_ge)`, `r(null_expected)`, `r(p_positive)`, `r(reps)`). Counts and output without `reps()` are unchanged. New test `test_nwbalance_reps`.
- **`nwturnover ..., formation`** compares the ties formed between the two waves with all pairs without a tie in the first wave: the shares that return a tie of the first wave and that close a two-path of the first wave, in both groups (`r(absent)`, `r(formed_recip)`, `r(absent_recip)`, `r(formed_closure)`, `r(absent_closure)`; for undirected networks only the two-path shares). Counts and output without `formation` are unchanged. New test `test_nwturnover_formation`.
- **`nwcug ..., stat()` short form.** A `stat()` without the `##net##` placeholder is taken as a command that expects the network as its first argument: `stat(nwclustering) rname(cluster_global)` is `stat(nwclustering ##net##) rname(cluster_global)`. The placeholder is still needed for a command or program that takes the network elsewhere; calls with it are unchanged.
- **`nwclustering` without `generate()`** for a one-mode network: the node coefficients then go to a temporary variable, and only the returned results (`r(cluster_global)`, `r(cluster_avg)`) are kept. A two-mode network still needs `generate()` (or `ra`).

### Changed
- **`nwcug` and `nwcorrelate` print their results the way Stata's own tests do**: a header with the network(s), the number of draws (or permutations) and the condition, then a table (`nwcug`: observed value, mean and standard deviation of the null draws, and the p-values; `nwcorrelate`: the correlation, and with `permutations()` the p-value and the middle 95% of the permuted correlations). The returned results are unchanged.
- **String variables in categorical options.** `nwbrokerage, group()`, `nwmodularity, group()` and `nwtabulate, attribute()` take a string variable: only whether two nodes share a value matters, so the command runs with the variable encoded (levels in alphabetical order) and the string variable is put back afterwards. Results are the same as with the encoded variable. Before, `nwbrokerage` refused strings, `nwmodularity` said the variable had missing values, and `nwtabulate` stopped with "option matcol() not allowed". The new internal helper `_nwstrcat varlist : command` does the encoding and restoring, for other commands and the model packages. New test `test_nwstrcat`.
- **`nwplot ..., labelopt(mlabvposition(varname))`** places the label of each node at the clock position held in a variable of the node data, for example the first mode of a two-mode network to the left of its column and the second mode to the right. Before, the variable was not found, because the plot is drawn from nwplot's own data. New test `test_nwplot_labpos`.

### Fixed
- **`nwinstall` reports what it could not download.** The core is installed in numbered parts; a failed download in the middle used to drop that part and all later ones without a message. Each part is tried twice, and `nwinstall` stops with r(677) and names the parts that are missing.
- **Console Stata on macOS** (`c(os)` is Unix there) finds the macOS plugin and the interactive viewer; `animate` removes its files with `rm` on every non-Windows system.
- **Interactive viewer (macOS):** an unattended export stops at once with a clear message when its window is closed too early, instead of waiting for the time limit.
- **Temporal networks: a tie observed at several times keeps all of them.** `nwset ..., time()` kept one time per pair of nodes, the last row's: a tie listed at waves 1 and 3 was missing from `nwattime ..., at(1)`, while `nwsummarize` still counted it, so ties could not come and go. The same held for `interval()`: a pair with two periods kept only the last. The times are now kept as a list with one entry per row, for one-mode and two-mode networks of any size, and `nwattime` returns every tie observed at (or active at) the time asked for. Networks declared by an older version are sliced as before. New test `test_nwattime_multi`.
- **`nwqap` table:** a rounded coefficient, p-value or constant could print with all its binary digits (`.9570000000000001` instead of `.957`), which also shifted the p-value column. The values are now formatted before they are shown; stored results are unchanged.
- **`nwsummarize ..., save(filename, replace)`** wrote a file named "filename, replace.dta" and no filename.dta, without a message. The option now takes a file name with an optional `replace`; the file is replaced in either case, as before.
- **`nwcontext` with a string `attribute()`** now stops with an error (r(109)). The statistics use the values as numbers; a string was read as missing and gave an empty variable without a message.
- **`nwhomophily` with a string variable** counted no observations (`summarize` ignores strings) and stopped with "Not enough observations". It counts the nonmissing values now, and `nwexpand` encodes the string as before.
- **`nwdendrogram` on larger trees.** The wheel has one ring for each merge, and every ring was drawn as one plot per group, so that the graph command for a tree of about 50 nodes or more was longer than Stata/BE allows; the error was swallowed, nothing was drawn and nothing was said. With one color and one symbol (the default) each kind of element is now one plot, which draws the same picture (identical for small trees), and the 71 lawyers of `lazega` draw in Stata/BE. `colorpalette()` and `symbolpalette()` were passed on nested and failed the same silent way; they work now. New test `test_nwdendrogram_large`.
- **`help nwerrorcodes`** lists every code the core commands raise, the package-specific codes and the Stata codes, with the situations in which each is raised. It said it documented every code but listed only the package-specific ones, and it listed r(481), which no command raises (Stata uses 481 for another error).
- **Website command reference:** sections of the help files with other titles than the standard ones were left out of the web pages, among them "Network types" (129 commands), "Limits" (83 commands), the code tables of `nwerrorcodes`, the data set descriptions of `nwwebuse` and most of `nwintro` and `nwprogramming`. All sections are now converted.

Tested on macOS with Stata 17 BE, Stata 18 BE and StataNow 19.5 MP (the full test suite), on Windows 11 with StataNow 19.5 MP and on Linux (Ubuntu 22.04) with StataNow 19.5 MP. On Linux, in console Stata, the tests that need the Stata GUI (dialogs, `nwinstall, usermenu`, `view`) cannot run and are not counted.

## [3.22.0] - 2026-11-13

### Results that change (read before you re-run old analyses)
- `nwcontext, mode(either)` (or `mode(both)`) counted a neighbour tied in both directions twice (every neighbour of an undirected network): the sum and the maximum were doubled and the mean was weighted towards the reciprocated neighbours. Each neighbour now counts once, on a valued network with the larger of the two tie values.
- `nwqap` with an attribute term (`nwqap y x g`) read the attribute by row position, so after the data had been synchronised with a network of another size the attribute could be attached to the wrong nodes (a second identical call gave other coefficients). The data are now synchronised with the dependent network first.
- `nwpath` with `ego()` equal to `alter()` reports the trivial path of length 0 (`r(paths)` 1, `r(path_length)` 0), as igraph; it reported "not connected".
- `nwpath, generate()` on an undirected network stored each tie of the path network in one direction only (an asymmetric matrix flagged undirected); the ties are now stored in both directions.
- `nwbetween` and `nwcloseness` store their results as double (float rounded large betweenness scores: 16,834,504 instead of 16,834,503); `nwgeodesic, generate()`, `nwevcent`, `nwcontext` and the coordinates of `nwplot, generate()` are double as well.
- `nwplot, layout(grid, columns(1))` gave missing x coordinates, and more columns than nodes stopped with a conformability error; both now give a grid.
- `nwexport` writes a binary (unvalued) one-mode network without tie values (Pajek, UCINET DL, GML, edge list: ego and alter only), so that `nwimport` reads it back as binary; valued networks are written with their values as before. Before, every exported binary network came back valued.
- `nwtoedge` (and `nw2toedge`) list each tie of a two-mode network with the mode-1 node in `_ego` and the mode-2 node in `_alter`, so that `nw2fromedge _ego _alter` rebuilds the same network. Before, the node with the higher index was `_ego`, often the mode-2 node.
- `nwset, labs()` and `nwfromedge, labs()` with fewer labels than nodes give the remaining nodes only default names that are not already used: `labs(n2)` for 3 nodes gives n2,n4,n3 (before: refused because n2 was repeated). A label repeated in `labs()` itself is still refused.
- `nwfromedge` with string identifiers keeps the value of the last row when a pair is listed more than once, as with numeric identifiers (before: the largest value).
- `nwtoedge, numeric` numbers ego and alter by the position of the node; before, the numbers were transposed (the row with the value of cell (1,2) had ego 2, alter 1) and did not match the listing of an undirected network.
- `nwsubset netname if a == 1 & b == 2` keeps the nodes that meet the whole condition; the condition lost its parentheses, so `&` and `|` conditions kept the wrong nodes.
- `nwtranspose b, generate(a) replace` transposed another network when `a` stood before `b` in memory; it transposes `b` now.
- `nwreplace` of one cell of an undirected network that leaves the matrix asymmetric marks the network directed (a note says so); before, it stayed undirected with an asymmetric matrix.
- `nwdropnodes` and `nwkeepnodes` keep the direction of the network; a directed network whose remaining matrix was symmetric became undirected.
- `nwdropnodes, nodes(Bob)` on a network with a label containing a blank (e.g. "Anna Maria") dropped another node; labels are looked up exactly now.
- `nwstack` of undirected networks gives an undirected network (before: directed).
- `nwuse` restores the diagonal of a network with self-loops, and every network comes back exactly as saved: a directed network with a symmetric matrix stays directed (before, it was read as undirected). The data set `baerveldt` saved its ethnicity networks (`class<k>_ethn`) as directed; it now saves them as undirected, so they load as before. A two-mode network comes back in the node order it was saved in (before: the labels of both modes sorted together). A one-mode network also keeps its saved node order (before: its labels sorted as text, `n1 n10 n100 ... n2`; for example `nwwebuse mesa`). The ties and the node attributes are the same, but everything that depends on the order of the nodes can change: MCMC chains and estimates of `nwergm` and `nwsaom` for a given seed, random layouts, listings.
- `nwattime` returns the right `r(ties)` when a variable named `ties` exists.
- `nwimport, type(ucinet)` of an edgelist1 file numbers the nodes by their number, not by their text order (node 10 was node 2 before), and reads a file without tie values as binary.
- `nwset sender receiver value, eventtime(time)` with a missing or non-numeric value is refused (r(416), r(109)); before, the value was not used for events.

### Added
- Event networks keep the value of each event: `nwset sender receiver value, eventtime(time)` stores the third variable per event in the event list (column 4 next to sender, receiver and time); without a value variable every event has the value 1. `nwdynam` adds the value of an event to the tie, as goldfish does with the `increment` of an event. The Mata library is rebuilt (`build_eventlist()` takes the values as an optional fifth argument).

### Fixed
- `nwdegree` on an undirected network with two names in `generate()` (and no `isolates`) dropped the variable named second.
- `nwdegree`, `nwcloseness`, `nwgeodesic, generate()`, `nwevcent`, `nwkatz`, `nwneighbor` and `nwcontext` treated a variable that merely starts with the requested name as that variable (`generate(d)` with a variable `dlong`): the command stopped with r(99), or dropped the other variable.
- `nwevcent, replace` into an existing byte or integer variable stored truncated values; the variable is now replaced.
- `nwkatz, walks` without `alpha()` stopped with an error on a network without cycles (spectral radius 0); the default alpha is then 1.
- `nwcloseness` and `nwbetween` with `twomode` on a one-mode network left a helper network (and `nwbetween` the result variable) behind; the check now comes first. Their helper networks (`_tempgeodesic`, `<net>_symmetrized`) have temporary names, so a user network of that name no longer stops the command (`nwcloseness` stopped with r(99) without a message).
- `nwgeodesic, binary alpha()` left the result network behind when it stopped with r(198).
- `nwclustering, symmetrize` without `generate()` (or with an invalid `measure()`) left the symmetrized helper network behind, and the next correct call stopped with r(483).
- `nwclustering`, `nwclique` and `nwbrokerage` overwrote or deleted the user's scalars `clust_global`, `nw_ncliques`, `brk_pairs` and matrix `nw_cliquematrix`; `nwneighbor` and `nwcontext` deleted the user's Mata objects `__nb`, `__attr`, `__context` and others; `nwcorrelate, attribute()` deleted a user network called `same_<attribute>` (it is replaced only with `keepexpand`); `nwqap` stopped with r(483) when a user network `_tempexpand` existed. All use temporary names now.
- `nwneighbor` no longer moves the random-number stream (`r(oneneighbor)` is drawn with the state restored afterwards).
- `nwpath` stops with the error codes of `help nwerrorcodes`: 485 for a node that does not exist or an id out of range, 483 for a path network that exists, 198 for missing or wrong options (all were r(99)). The message for a missing `alter()` named `ego()`.
- `nwplot, generate()` with one name wrote `_x_coord` and `_y_coord`, and overwrote existing variables without `replace` (and changed their type); it now needs two names and `replace` to overwrite. A network without ties is plotted (its nodes) and `generate()` exports the coordinates; before, nothing was plotted or exported.
- `nwsummarize, detail` did not store the documented `r(missing_edges)`; it is stored in every case, and the help says what it counts (cells without a value, including the diagonal of a network without self-loops).
- `nwtabulate` with more than two networks said "Network ... not found" (r(482)); it says "Maximum two networks allowed" and stops with r(198).
- The help of `nwcontext` says how `max`, `min` and `sd` use the tie values of a valued network (they are taken over tie value times attribute).
- `nwset, mat() ... replace` dropped the existing network before checking the new one: a refused request (wrong shape, repeated labels, wrong `vars()`, wrong `nodenames()`) lost it. All checks now come first. `vars()` of the wrong length no longer leaves a half-made network, and `nodenames()` of the wrong length or with repeated names is refused (r(198)).
- `nwset, mat() labsfromvar()` ignored the variable and used n1, n2, ...; it uses the variable now. A numeric variable is no longer turned into a string.
- `nwset ..., edgelist keeporiginal` (and `nwimport ..., keeporiginal`) stopped with "option keeporiginal not allowed"; `nwfromedge` has the option `keeporiginal` (variable `_nodeoriginal` with the original identifier of each node) and the new option `selfloop` (keep the ties of a node with itself).
- `nwfromedge, noclear` overwrote the id variables and dropped rows with a missing identifier; the data are kept as they were.
- `nwfromedge, labs(x y z)` (blank-separated, as the help shows) gave one label "x y z"; blanks and commas both separate labels now.
- `nwtoedge` of a network with one node (with `compress`, and so `nwsave` of such a network or of a two-mode network together with it) stopped with a Mata conformability error and left helper variables in the data. `nwtoedge, numeric` with several networks is refused before the data are changed.
- `nwsave` and `nwuse` failed with `set varabbrev off` ("variable _nw_selfloop not found").
- `nwexport` moved `_nwinclude` behind the user's variables; the variable order is kept, also when the export fails.
- `nwexport, type(ucinet)` / `nwimport, type(ucinet)`: the labels were read back as one label; labels with a blank are written in double quotes and read back.
- `nwimport, type(edgelist) nwappend` replaced the data in memory (and cleared them when the file was missing); the data are kept. `delimiter()` works for edge lists in text files (it stopped with r(6750)).
- `nwrandom, ntimes() nodenamesmata()` gave none of the networks the labels; `nodenamesmata()`, `directed` and `noreplace` are passed on to every network.
- A network name longer than 32 characters (or otherwise not a valid Stata name) was accepted by `nwset`, `nwfromedge`, `nwrename`, `nwgenerate`, `nwtranspose, generate()` and `nwpermute, generate()`, after which no network could be found ("Network _all not found"). Such names are refused with r(198); the name suggested for a taken name of 31 or 32 characters is shortened to stay within 32.
- `nwset ..., eventtime()` stored events with a missing time (sorted last by the event models) and events with a missing sender or receiver (index 0, raw Mata errors later). Such rows are refused with r(416) and a message; nothing is changed.
- A command that takes one network, given two (`nwtomata g h`, and the event and model commands), said "Network g h not found" (r(482)); it says that only one network is allowed (r(198)).
- `nwexport, type(gml)` (and `nwtoedge`) of a network with exactly one tie stopped with a Mata conformability error.
- Error codes follow `help nwerrorcodes`: a node label or number that does not exist (`nwdropnodes`, `nwkeepnodes`, and the helpers behind them) gives r(485) (was r(6012), r(600021), r(600022), or for `nodes(0)` a Mata error; a number above the number of nodes was ignored); `nwsym, mode()` with an invalid value r(6556) (was 6555); `nwpermute, generate()` and `nwstack, name()` onto an existing network r(483) (were 99 and 110); other one-off codes became the standard Stata codes for their meaning (198 invalid syntax, 2001 too few observations, 125 out of range, 480 creation failed, 6082/6705 from the list).
- `nwplot ... if` / `in` deleted every user network whose name began with `__temp` (and one called `_temp_in`); its helper networks have temporary names now. A wrong `edgecolor()`/`edgesize()` sub-option stopped with r(6088) (two-mode unsupported) and could leave a helper network; it stops with r(198).
- `nwdropnodes` and `nwkeepnodes`: a label in a network of 2,000 nodes with long labels stopped with r(1) and no message; node id 0 stopped with a Mata error; `generate()` left the copy behind when the request was refused.
- `nwsubset x if ..., name(x) replace`, `nwduplicate x, name(x) replace`, `nwtranspose x, generate(x) replace`, `nwpermute x, generate(x) nwreplace` and `nwgenerate x = <expression with x>, replace` (also when the expression fails) lost the network `x`; the old network is now replaced only when the new one exists.
- `nwgenerate y = diff` stopped with r(482): the letters "if" inside a network name were taken for an `if` condition.
- `nwnoderename` added a row with the old label and renamed a user variable that had the old label as its name; it renames only the network's own node variable (when the node variables are in the data).
- `nwcollapse` left a network `_temp_<name>` behind.
- `nwstack` stopped with "observation number out of range" when the data had more rows than the stacked network has nodes.
- `nwset ..., twomode` (and `nw2fromedge`) with string identifiers, or a string mode with a numeric one, numbered the nodes in the sort order of both modes together (persons "P1".."P3" and organisations "O1", "O2" gave O1 O2 P1 P2 P3), while the network said that the first three nodes are mode 1: matrices, event lists and the commands built on them mixed the modes up. The mode-1 nodes now come first. A string mode with a numeric one stopped with r(106).
- Numeric node identifiers of 10,000,000 or more were turned into labels such as "n1.00e+07" by `nwset ..., eventtime()`/`time()`/`interval()` and in the mode split of `nwset ..., twomode`, while the network's nodes had the full number: events pointed at no node (index 0), two-mode networks put every node in mode 2. Labels are the full number now (also for a numeric identifier paired with a string one in `nwfromedge`). The offset of mode-2 identifiers in a numeric two-mode list is added in double precision.

Tested on macOS with Stata 17 BE, Stata 18 BE and StataNow 19.5 MP (the full test suite) and on Windows 11 with StataNow 19.5 MP. Linux: plugins built by CI, not tested in Stata.

## [3.21.0] - 2026-11-12

### Results that change (read before you re-run old analyses)
- `nwdyadprob weightnet, density()` draws the ties with probabilities proportional to the tie values of the weight network, as documented. Tie values above 1 were first passed through invlogit, which flattened them (weights of 148, 1 and 0.007 became almost 1, 0.73 and 0.5), so the network of the help example showed hardly any of the intended homophily. Negative weights are refused with `density()`. Without `density()` nothing changes: values outside 0 to 1 are still turned into probabilities with invlogit.

### Added
- `nwgenerate newnet = sym(netname)` makes a symmetrized copy of a network (as `nwsym ..., generate()`); before, the keyword was accepted and did nothing.
- `nwplotmatrix, labelopt()` sets suboptions of both axis labels and `legendopt()` adds options to the legend; both were accepted and ignored.
- `nwtabulate netname1 netname2, unvalued` counts every tie as 1 in the table and in the E-I index; `save()` of `nwtabulate` (two networks, or `attribute()`) saves the E-I indices of the permutations as a data set.
- `nwgeodesic, noreplace` does not overwrite the default network `_geodesic` either.
- `animate, mag()` sets the magnification of the .eps files.

### Fixed
- `nwgenerate newnet = large(netname)` kept the largest component of the right network only by chance.
- `nwring` and `nwsmall` with `ntimes()` gave `labs()` only to the first network; every network now gets the labels. Their help files show that the labels are separated by commas.
- `nwdropnodes, keepmat()` with a matrix of the wrong size overwrote the user's Mata matrix with ones and dropped nothing; it is now an error (r(503)) and the matrix is not changed.
- `nwdegree` on a list of two-mode and one-mode networks stopped with an error (two-mode networks got the plain variable name); a two-mode network of a list now gets its name appended, as the one-mode networks do (`deg_net`).
- `nwplot, iterations()` was ignored (the default of `layout()` replaced it); it is used now, and `layout(..., iterations())` takes precedence.
- `nwnoderename` with a name that was not found or not valid printed an error but did not stop; it now exits with r(198).
- `animate, graphs(_all)` repeated the first graph as the last frame instead of the last graph; the .eps files are erased with Stata's `erase` on every platform (Windows `del` was used on Linux).
- `nwreplacemat` stored `r(directed)` = 1 for a symmetric matrix; `r(directed)` is now 1 when the network is directed.
- `nwclustering, symmetrize` stored `r(symmetrized)` = "false"; it is "true".
- `nwtabulate` printed "tie values are ignored" for the one-way table and the table of two networks, which show the tie values; the note is now printed only for the table by `attribute()`. With `permutations(1)` the tables of two networks or by attribute stopped with an error after the table; they now print no p-value.
- `nwexport` and `nwimport` left r() results of their helper commands behind, and an internal synchronisation step added `r(nodes)` to the results of the calling command; no stray r() results now.
- `nwfactions`, `nwkcomponents`, `nwkplex`, `nwnclan` and `nwnclique` left scalars and matrices (`faction_fitness`, `nw_nkcomp`, `nw_tabnwkplex` and others) in memory and overwrote the user's objects with these names; they use temporary names now.
- `nwnclique`, `nwnclan` and `nwkplex` with `nomatrix` stopped with a conformability error (r(3200)) when exactly one set was found; the per-node variable is now the same as without `nomatrix`. The core Mata library is rebuilt (nwsaom and nwergm are rebuilt against it).
- Commands that synchronise the data with a network no longer change the r() results of the command run before them (for example `r(N)` of `summarize`).
- `nwsummarize` without `detail` no longer stores empty detail results (`r(dg_central)`, `r(transitivity)` and others); they are stored with `detail`, as documented.
- `nwreplacemat, vars()`, `nwtabulate ..., attribute() unvalued` and the `ifcond()` option of `nwcorrelate` are accepted for compatibility and have no effect; their help files say so.
- Help files: the links to `_nwsyntax` in `nwprogramming` and `nwunab` lead to the section of `nwprogramming` that describes it; the "describe" links of `netexample` describe the data sets on the website (`sysdescribe` looked for them on the local computer).
- `nw2fromedge` no longer changes the id variables in the data: the shift of numeric mode-2 ids and the prefixes `m1_`/`m2_` of string ids are applied to the node names only. When the command stopped with an error, the changed variables used to stay in the data; an `if` condition on the mode-2 id was evaluated on the shifted values.
- `nwfromedge ..., name()` with a name already in use stopped with error 483 only after it had dropped the edge list from memory (string ids); it now stops before the data are changed. `replace` is passed on with `twomode`.
- `nwattime` on a temporal two-mode network gives a two-mode slice with the same modes and level labels (it gave a one-mode network).
- `nwdendrogram` reports errors of the graph (for example an unknown `twoway` option) instead of ending silently, and stops with error 459 and a message when the cluster levels are not nested.
- `nwcontext`: `generate()` is no longer required when `mat()` is given; with both options the variable and the Mata matrix are created.
- `nwstack` refuses two-mode networks with error 6088 and a message (it stacked them as one-mode networks).
- `_nwnodelab, nodeid()` with a node id below 1 stops with the message "out of bounds" instead of a Mata error.
- The help file of `nwaddnodes` said that node names are separated by commas or spaces and cannot contain a space; they are separated by commas and may contain spaces.

## [3.20.1] - 2026-11-12

### Fixed
- **Help files checked against the code.** Options, abbreviations, defaults and stored results of every help file were compared with the commands. Corrected, among others: required options shown as optional (`generate()` of `nwspectral`, `nwrandomwalk`, `nwturnover`); missing options (`nwtoedge`, `nwqap`, `nwsym` modes `sum` and `mean`); wrong defaults (`nw2degree`, `nwassortativity` and `nwbetween` use tie values on a valued network; `animate, delay()` is in hundredths of a second; `nwplot, arcbend()`); examples that failed (`nwrecode`, `nwaddnodes`, `nw2set`, `nwcug`, `nwreplacemat`); options that do not exist (`nwplotmatrix, labelopt()`, `nwset, detail`); stored results that were missing (`nwdegree`, `nwtabulate`, `nwtomata`, `nwvalue`, `nwset` and others).
- **Help files have one layout.** The sections "Supported network types", "Valued networks" and "Two-mode networks" are one short section "Network types" (help `nwnetworktypes` explains it), and the sections follow one order: Syntax, Description, Options, remarks, Network types, Limits, Examples, Stored results, References, See also.
- **Help file layout.** In 11 help files (for example `nwburt`, `nwclique`, `nwclustering`, `nwtriads`) the text after one section ran together with the following sections, with markup such as `{pstd}` shown as text; links written as `a/b` showed the second one as markup; stored results, "See also" lines and a few paragraphs did not wrap at the window width; very long source lines lost words in the help Viewer. All help files now pass the new check `tools/check_help_smcl.py`.
- **Help files describe the current behaviour only.** References to earlier versions, old timings and the history of fixes are removed from the help files; options kept for compatibility (`legacy`, `onemode`, aliases) are described by what they do.
- The help files of `nwevcent` and `nwbetween` said that a valued network is made 0/1 by default; both use the tie values unless `binary` is given, as the option lists already said. The help file of `nwgeodesic` said that weighted distances stop at 100 nodes; that limit applies only on a platform without the native plugin.
- The help file of `nwkatz` showed the option `force` inside the text of `geodesic_options`.
- `nwbridges` on an undirected network: the result is symmetrized again (`type(local)` and `type(distance)` could give a tie in one direction only).
- `nwexpand ... if` deleted the observations that do not satisfy the condition from the data in memory; it now only selects the observations that become nodes. `nwhomophily`, which calls it, no longer drops observations either.
- `weights()` of `nwring`, `nwsmall`, `nwpref` and `nwdyadprob` failed when the probabilities did not sum to one; they are normalised, as in `nwrandom`. Tie values are 1, 2, ... as documented.
- `nwcontext, stat(sum)` printed two Mata matrices.
- `nwkeep, clean` without `if` or `in` stopped with an error.

Other results do not change.

## [3.20.0] - 2026-11-12

### Added
- **`nwplot ..., basemap()`** draws outlines, such as the borders of a map, under a network whose nodes are placed with `nodexy()`, for example by longitude and latitude. The argument is a Stata file with the coordinates in `_X` and `_Y` (the `*_shp.dta` file that `spshape2dta` makes from a shapefile), a web address, or the name of a map among the example data; line options follow after a comma, and `if` keeps part of the map (`basemap(usmap if !inlist(state, "AK", "HI"))` for the lower 48 states). The picture then takes the proportions of the map unless `aspectratio()` is given; for longitude and latitude, a degree of longitude is narrowed to its width at the middle latitude of the map (cosine), so that a country keeps its familiar shape. New example file `usmap` (outlines of the US states, US Census Bureau, public domain): `nwplot usair, nodexy(Lon Lat) basemap(usmap)`.
- **Save do-file on the interactive page of `nwplot`.** A new button saves `nwedit_plot.do`, which redraws the picture in Stata as it is on the page: it writes the two files of Save nodes and Save edges into the working directory and calls `nwplot` with the network, `if`/`in` and options of the call that wrote the page, completed with `nodexy()`, `importcoords()` and `edgeimport()`. Run it with `run nwedit_plot.do`.
- **Group names in `nwplotmatrix, group()`.** The name of each group (its value label, or the string; a numeric variable without a value label gets none) is written beside its block, at the top and at the left, and the lines between the groups are drawn medium thick, so that one can see where a group starts and ends. `nogrouplabels` leaves the names out; with node labels (`lab`, `label()`) the names are not written.
- **`nwdyads, plot` and a new `nwtriads, plot`.** Both draw the census as small pictures of the dyad (or triad) types, each with its MAN code and its count underneath, in the order of the printed table; on an undirected network only the types an undirected network can have. The bar chart that `nwtriads, plot` drew before is replaced. New test `test_census_plot`.
- **`nwsummarize` reports the mean degree** (mean outdegree of a directed network) under the density, and stores it in `r(meandegree)`.
- **`nwgeodesic` on a network with unconnected pairs** now also prints, and stores, the share of pairs that are connected and the average and longest distance over the connected pairs (`r(connected)`, `r(avgpath_connected)`, `r(diameter_connected)`). The overall average, diameter and radius are still "(not defined)" and `r(avgpath)` is still -1.

### Changed
- **Data set `lazega`** has three more variables: `officenum` (1 Boston, 2 Hartford, 3 Providence), `practicenum` (1 corporate, 2 litigation) and `partner` (1 partner, 0 associate), the office, practice and status as numbers with value labels, for commands that need numeric groups (`group()`, `nodematch()`, `nwqap`). The string variables and the networks are unchanged.
- `nwgeodesic` overwrites its default output network `_geodesic` without `nwreplace`, as `nwreach` does with `_reach`. A network named with `name()` is still protected.
- The help of `nwplot` says that the PNG export of the interactive page is a raster image, and that `nodexy()` also draws layouts computed elsewhere.

## [3.19.0] - 2026-11-11

### Changed
- **Example data from nwcommands.org.** `nwwebuse` loads the example data sets from https://nwcommands.org/examples (a copy of the `data` folder that the website deploy publishes), so that output such as "Contains data from https://nwcommands.org/examples/lazega.nwdta" stays short. If the website cannot be reached, `nwwebuse` says so and loads the same file from GitHub, which then stays the source for the session (`$nwwebpath`). `nwwebuse set` without arguments resets the source to the new default. Import examples in the help files use the short address. The data themselves do not change.

### Fixed
- **Long messages wrap between words.** Notes, warnings, error messages and the "(plot saved as ...)" notes longer than the line are now printed as paragraphs, so Stata breaks them between words instead of cutting a word at the line width (for example `nwcug, plot`, `nwqap, plot`, the `nwplot` layout note on signed networks, the two-mode refusal, `nwuse` of a plain dataset and the size guards). The wording is unchanged. A long `stat()` in the `nwcug` header continues with a hanging indent. New test `test_msgwrap`.
- **Isolates in an edge list.** A row with one identifier missing (`Fion ""`, `5 .`, or the receiver-only `"" Fion`, `. 5`) in `nwset ..., edgelist` and `nwfromedge` declares the other identifier as a node without a tie from that row, the usual way to keep isolates in an edge list. Up to 3.18.0 the node was kept, but the row was also stored as a tie with a missing end: `nwsummarize` reported one arc too many (5 instead of 4, density .25 instead of .2, correct only after another command rebuilt the network), and with numeric identifiers `nwtomata` failed with r(3200). A missing numeric identifier next to a string one no longer becomes a node called `.`. Rows with both identifiers missing are ignored, as before. The help files of `nwset` and `nwfromedge` say how to keep isolates. New test `test_edgelist_isolates`.
- **`nwimport, type(pajek)` of a file without vertex lines.** A Pajek file whose `*Vertices n` line is followed directly by `*Arcs`, `*Edges`, `*Arcslist` or `*Edgeslist` (valid Pajek, for example `data/pajek_example.net`) failed with r(601), file not found: the import merged a vertex dictionary that only vertex lines create. Such a file now gives n nodes labelled `n1`, `n2`, ... (as `nwfromedge` labels numeric ids), vertices without ties included; a two-mode file (`*Vertices n n1`) without vertex lines no longer fails with "option labs() required". Files with vertex lines are unchanged. Assertions added to `test_nwimport`.

## [3.18.0] - 2026-11-11

### Added
- **Data set `baerveldt19`** (with `baerveldt19_pupils`): all 19 schools of the Dutch Social Behavior study that the Siena project distributes, 990 pupils, as 57 networks `school1_w1`, `school1_w2`, `school1_ethn`, ... `school19_ethn` and a plain data set with `school`, `pupil`, `gender` (1 girls, 2 boys), `delinq1`, `delinq2`, `siena` (the Siena file number) and `nact`. Each group is the whole MAVO year of one school, not a classroom, hence the name school. The data set `baerveldt` (15 of the schools, called classes) is unchanged; its classes are schools 1-7, 9, 11, 12 and 14-18 of `baerveldt19`. Stack all schools with `nwstack school*_w1, name(w1) group(school)`. New test `test_baerveldt19_data`.

## [3.17.6] - 2026-11-09

### Fixed
- **Number fields in the dialogs accept only numbers.** In 31 dialogs, a field that needs a number (the number of nodes of `nwrandom`, `nwpref`, `nwring`, `nwsmall` and `nwvalidvars`, the dimensions of `nwlattice`, probabilities, densities, tie weights, node ids, iterations, tolerances and the other numeric options) is checked when you click OK; text is refused with a message that names the field, before the command runs. Test `test_dlg_options` checks the number of nodes.

## [3.17.5] - 2026-11-09

### Fixed
- **Dialogs, checked systematically against the syntax of every command (67 dialogs changed).** In 30 dialogs the field "name of the new network" was not passed to the command (an empty `option()` since 3.4.0). The generators `nwrandom`, `nwpref`, `nwring`, `nwsmall` and `nwlattice` asked for a network where they need the number of nodes (or the dimensions); the file commands now ask for a file. `nwappend` always failed (it asked for a network, not a file); `nwname` passed the new name as text; `nwburt` and `nwpagerank` ignored some fields; `nwring` and `nwsmall` ran `k(0)` when the field was left alone; `nwplot` always set `iterations(200)` and `columns(5)`, overriding the defaults; the edge colour and size dialogs added an option that does not exist; `nwplotmatrix` offered if/in and an option it does not have. Required inputs (`generate()` and the main argument) are now required by the dialogs, which say so; `nwsubset`, `nwkeep` and `nwdrop` have an if field; labels, typos and the limits of the number fields are corrected. New test: `test_dlg_options`.

### Added
- **`nwinstall, buildplugin()` builds on Windows too**, with Microsoft's free C compiler (Build Tools for Visual Studio), which it finds by itself. If the compiler is missing, it says what to install, with the download address, and changes nothing. `buildplugin()` with nothing in the parentheses builds all plugins (before, it did nothing).

### Tests
- The scratch folders of `test_buildmata`, `test_buildplugin` and `test_localcopy` carry the time in their names (a folder left by a failed run blocked later runs); `test_buildplugin` also runs on Windows.

## [3.17.4] - 2026-11-09

### Fixed
- **`nwsummarize, save()` failed on Windows with a quoted file name** (such as a `tempfile`): the option kept the quotes and the file name came out with a stray quote. Found in the first run of all test suites on Windows.

### Changed
- The package files and the author lines of the `.ado` and help files give the affiliation as RWTH Aachen University.

### Tests
- Eight tests assumed macOS and now also run on Windows: `test_buildmata` (a directory junction instead of `ln -s`), `test__nwopenviewer` (`tasklist` instead of `ps`), `test_animate` (Windows' own `convert.exe` is not ImageMagick), `test_nwgraph_native` (a loaded plugin is renamed, not erased), `test_nwinstall_ancillary` and `test_nwinstall_gui` (both spellings of the repository folder are taken off the ado-path), `test_nwinstall_everything` (the parent folder on Windows; the folder of the model packages can also come from the environment variable `NWMODELS`), and `test_combinatorial_scale` (on Windows the C clock advances in steps of a millisecond or more, so a time limit of a microsecond may not be reached).

## [3.17.3] - 2026-11-09

### Fixed
- **`nwinstall` puts the line `nwinstall, usermenu` into the `profile.do` that Stata reads at every start.** Without `path()`, it used the current folder, so a run from a project folder or a batch run created a `profile.do` that Stata reads only when it starts in that folder, and the menu did not appear at the next start (found in a test on Windows). Now an existing `profile.do` in the home folder, in PERSONAL or in SITE is edited; otherwise one is created in the folder Stata's manuals recommend: `%USERPROFILE%` on Windows, `~/Documents/Stata` on macOS, PERSONAL on Unix. `path()` works as before. New test: `test_nwinstall_profiledir`.
- The check for a menu line in other `profile.do` files split folder names with blanks (such as `C:\Program Files\StataNow19\`) into pieces and could miss a file there.

### Documentation
- The help file describes the default of `path()` correctly (it said the Stata folder).

## [3.17.2] - 2026-11-06

### Changed
- The `nwmovie` dialog has a new group "Export a video or GIF instead of opening the movie" with `export()` (file chooser for .mp4, .webm and .gif), `replace` and `timeout()`, the options added in 3.16.0, and a `nosign` checkbox. The command itself is unchanged.

## [3.17.1] - 2026-11-06

### Changed
- The dialogs of `nwrandom` (new fields `degree()`, `outdegree()`, `indegree()`, `swaps()`), `nwcug` and `nwpermute` offer the degree-preserving options of 3.17.0 for one-mode networks.
- Website: Tutorial 6 (Generating Networks) has a new section on random networks with given degrees, Tutorial 18 (Testing) on the CUG test that holds the degrees fixed, Tutorial 12 points to it; the command tables of "Network types" describe the new options.
- Tests: `test_native370` and `test_twomodesupport` expected `nwpermute, swap` to refuse a one-mode network; they now check that it rewires the network and keeps the degrees.

## [3.17.0] - 2026-11-06

### Added
- **Random networks that keep the degrees of a one-mode network.** Until now only two-mode networks had a degree-preserving null model.
  - `nwcug ..., condition(degrees)` now works for one-mode networks: every draw has exactly the degrees of the network (directed: every out-degree and in-degree), no self-loops and no pair tied twice. It tests whether a statistic goes beyond what the degrees alone produce. The draws are a chain of random tie swaps (two ties a-b and c-d become a-d and c-b), as R's `igraph::rewire(g, keeping_degseq())`; `trades()` sets the number of attempted swaps between two draws (default 10 times the number of ties). The global clustering of the Florentine marriages: 0.165 (sd 0.078) over 2,000 draws, igraph 0.162 (sd 0.077).
  - `nwpermute ..., swap` now works for one-mode networks too: it rewires the network by the same tie swaps (`swaps()`), so that every node keeps its degree and every tie its value.
  - **`nwrandom` draws a network from a list of degrees:** `degree()` (undirected) or `outdegree()` and `indegree()` (directed) take a list of numbers or a variable (for example degrees from `nwdegree`). The network has exactly these degrees, no self-loops and no repeated ties; it is built (Havel-Hakimi; directed: Kleitman-Wang) and then randomized by `swaps()` tie swaps, as `igraph::sample_degseq(method = "edge.switching.simple")`. A list that no network can have (an odd sum, a degree above n - 1, ...) stops with error 198.
- The three use a new kernel of the native plugin (generation 13), built for Windows, macOS and Linux.

## [3.16.1] - 2026-11-06

### Fixed
- **`nwmovie` and `nwplot, interactive` work after an installation from the internet.** Stata's `net install` does not install the page templates, the JavaScript files and the native viewer of these two commands, because of their file types; `nwinstall` copied them into the current working directory instead, where the commands do not look. `nwmovie` therefore stopped with "required file not found: .../nwmovie_template.html", and `nwplot, interactive` with a similar message. `nwinstall` now puts these files into the installation folder, and no longer leaves copies in the working directory; `nwinstall, remove` deletes them again. To repair an existing installation, run `nwinstall, all` once.
- **The help file of `nwaltergen` gave the wrong statistic for "the number of contacts who already adopted".** That number is `sum(alter.adopted)` for a 0/1 variable; `count(alter.adopted)` is the number of contacts with a non-missing value. The help file now says so.

## [3.16.0] - 2026-11-05

### Added
- **`nwmovie, export(filename)` writes the movie as an MP4 or WebM video or an animated GIF**, chosen by the file's extension, without opening the interactive view, so that a do-file can produce the movie file. The native viewer renders and encodes the movie and closes again; `nwmovie` waits for the file (options `replace` and `timeout()`). Nothing beyond the package needs to be installed on Windows, macOS or Linux: the encoding is done by the web engine of the operating system.
- **The movie view has an *Export video* button** next to *Export GIF*: MP4 (H.264) where the web engine can encode it, WebM otherwise. The time readout drawn on the canvas is part of every frame, as in the GIF.

### Fixed
- **Save and export buttons work in the viewer on Windows and Linux.** In the native viewer of these two platforms, *Export PNG*, *Save nodes*, *Save edges* (`nwplot, interactive`) and *Export GIF* (`nwmovie`) did nothing, because a bare web view ignores downloads; only the macOS viewer had a save dialog. The Windows (WebView2) and Linux (WebKitGTK) viewers now show a save dialog as well.
- **The native viewer is started under a name Windows can run.** The viewer was copied to a temporary name without the extension `.exe`, and Windows does not run a program file without it; the copy now keeps the extension.
- **`nwplot, interactive` and `nwmovie` no longer change the random-number stream** when they pick names for their temporary files.

## [3.15.4] - 2026-11-04

### Fixed
- **`nwload` (3.15.2 change) stopped where it should not.** After a node variable of the loaded network had been renamed, loading another network stopped with error 110, because the remaining variables of the network were taken for variables of the user. `nwload` now marks the variables it creates (characteristic `[nwload]`) and drops marked variables by exact name; a renamed variable keeps its new name. Only unmarked variables with a node's name stop `nwload` (option `overwrite`), unless they are all the variables of the network loaded before (a network declared from your own variables with `nwset varlist`).

## [3.15.3] - 2026-11-04

### Fixed
- **`nwplot` no longer drops ties when edge widths vary.** Each tie was matched to its width class by an exact comparison of two decimal numbers, which failed for some values, so that those ties were not drawn at all (in the Chesapeake food web, 6 of the ties with `edgesize()` by flow, 5 on a log scale). The comparison now allows for rounding.

## [3.15.2] - 2026-11-04

### Fixed
- **`nwset` refuses repeated node labels.** `labs(A,A,B)` used to be accepted with rc = 0 and the labels were silently replaced by `n1`, `n2`, `n3` (and repeated values in `labsfromvar()` were kept, so that commands that look nodes up by label could merge nodes). It now stops with error 198 and names the repeated label. A `labs()` list with fewer or more entries than nodes is still accepted, with a note.
- **`nwload` no longer overwrites variables silently.** Loading a second network still replaces the variables of the network loaded before (one network is loaded at a time), but a note now says so. A variable of the user's that has the name of one of the node variables stops `nwload` with error 110 unless `overwrite` is given; before, it was overwritten, and a variable abbreviated by a node name could be dropped. Previous network's variables are dropped by exact name, and only when all of them are present.

## [3.15.1] - 2026-11-04

### Fixed
- **The data set `baerveldt` lists the pupils in the order of their numbers.** In 3.15.0 the nodes of every class network were named `n1`, `n10`, `n11`, ... and therefore stood in text order, so that a network and the pupil attributes merged by the pupil's number did not belong together. The nodes are now named `p01`, `p02`, ... and keep the order of the original files. If you used `baerveldt` from 3.15.0 with `baerveldt_pupils`, fetch the data again with `nwwebuse baerveldt, nwclear`.

## [3.15.0] - 2026-11-04

### Added
- **`nwstack`** stacks several networks into one block-diagonal network, with an optional group variable. It builds the input of `nwsaom, groups()` from separate networks, such as school classes.
- **The data sets `baerveldt` and `baerveldt_pupils`**, for `nwwebuse`: 15 Dutch school classes from the Dutch Social Behavior study of Baerveldt and colleagues, as 45 separate networks of 33 to 91 pupils (friendship at two waves and an ethnicity matrix per class) and a plain data set with the pupils' gender, delinquency at both waves and class size. They are the example of `nwstack` and of the joint model of `nwsaom` (groups). Source and terms: see `NOTICE.md`.

## [3.14.1] - 2026-11-04

Patch release: one fix in `nwuse`. The Mata library and the plugins are unchanged.

### Fixed
- **`nwuse` gave every network of a file the size of the largest one.** A file made by `nwsave` from networks of different sizes (10 and 25 nodes, say) was read back with all networks at 25 nodes: the smaller ones got the extra nodes as isolates, which changed their density and every statistic that depends on the number of nodes. Each network now comes back with its own nodes, isolates included. Files saved before the node list was stored (no `_nw_modes`) load as before. Node names that contain a comma ("Smith, J.") are handled. New test `cscripts/test_nwuse_sizes.do`.

## [3.14.0] - 2026-11-03

Minor release: Monte Carlo p-values that are never 0, and the Mata libraries can be rebuilt on the user's computer. The Mata library and the plugins are unchanged.

### Results that change
- **`nwmixing` reports a Monte Carlo p-value that is never 0.** The permutation p-value is now 2(1 + k)/(R + 1), with k the number of the R permutations in the smaller tail, so that the observed value counts as one more draw. With 100 permutations the smallest p-value is 0.020, where the old formula printed 0. `r(EI_pvalue)` has the same meaning otherwise (two-sided).
- **The permutation and simulation tests report Monte Carlo p-values that are never 0.** `nwcug` (tail p-values (1 + k)/(R + 1); the two-sided value is twice the smaller tail, at most 1), `nwcorrelate` (now two-sided, 2(1 + k)/(R + 1); it was one-sided and could print 0) and `nwqap` (two-tailed, (k + 1)/(R + 1), also with `qapspp`) count the observed value as one more draw of the null, as `nwmixing` does. The smallest p-value of 1,000 draws is 0.001 (tail) or 0.002 (two-sided); of 500 draws, 0.002 and 0.004.

### Added
- **`nwinstall, buildmata(...)` rebuilds the Mata libraries with the Stata that is running (fallback and repair).** A library built by a newer Stata is ignored by an older one (r(3499), every Mata function "not found"); a library built by the Stata that runs always loads. `buildmata(all)` fetches the Mata source of the core and of every installed model package from the GitHub repositories (`buildfrom()` for a local copy, `release()` for a tag), compiles it, and installs the libraries where Stata finds the current ones, keeping the old file as `.prev`. Rebuilding the core always rebuilds the installed nwsaom and nwergm libraries too (they are compiled against it). The build clears the data and the Mata objects in memory and refuses to run when data is loaded (error 4). The same option works for nwsaom, nwergm, nwdynam and nwrem (`buildmata(nwsaom)`). `nwinstall, localcopy` copies the new `nwinstall_buildmata.ado`. Test: `cscripts/test_buildmata.do`.
- The messages of `_nwlibcheck` (library missing, too new, or old) point to `nwinstall, buildmata(all)`.

### Changed
- **`db nwplot` dialog is wider.** The dialog has six tabs, and their titles were cut off at the old width (460 pixels); it now uses the standard wide size (600 pixels). No change to any command or option.

## [3.13.2] - 2026-11-02

Patch release: path highlighting.

### Fixed
- **`nwplot, edgecolor()` on an undirected network colored only one direction of a directed colors network.** `nwpath, generate()` stores a path as a directed network (i to j in the direction of the walk). Used as `edgecolor(sp_1)` on an undirected network, a tie whose stored direction was the other one stayed gray: the Medici-Peruzzi path of the Florentine marriage network (three ties) showed two highlighted ties, in the picture and on the interactive page. A tie of an undirected network is now colored if either direction of the colors network is set. New test `cscripts/test_nwplot_pathcolor.do`.

## [3.13.1] - 2026-11-01

Patch release: the offline install.

### Fixed
- **`nwinstall, localcopy all` now copies the plugins and `nwinstall_buildplugin.ado`.** The offline install copied the Mata library and the `.ado`, help and dialog files, but silently skipped the compiled core plugins (the files under `lib/plugins/<os>/` were copied to a folder that did not exist) and did not copy `nwinstall_buildplugin.ado`, so `nwinstall, buildplugin()` was missing on a computer installed this way. Test `test_localcopy.do`.

## [3.13.0] - 2026-10-31

The native plugins can be compiled on the user's own computer.

### Added
- **`nwinstall, buildplugin(...)` compiles the native plugins on the computer that needs them.** `buildplugin(nwcommands)`, `buildplugin(nwsaom)`, `buildplugin(nwergm)`, `buildplugin(nwdynam)` or `buildplugin(all)` fetches the C source from the repositories (`buildfrom()` reads a local copy, `release()` a tagged release), compiles it with the compiler of the computer (macOS and Linux; a C compiler and `make` are needed) and installs the plugin where `net install` puts it, keeping an existing file as `.prev`. It is the fallback for a platform whose shipped plugin is missing, older than the `.ado` files or does not load. Tested on macOS (Apple silicon, Stata 17); on Windows the command stops with a message. Test `test_buildplugin.do`.
- **The C source of the core plugin and of the viewer launcher ships with the starter package** (`native/*`, listed in `nwcommands.pkg` and `_pkg_boot.txt` as ancillary files): `net get nwcommands, from(https://nwcommands.org/net/)` copies it, together with a build note (`nwgraph_native_readme.txt`). `net install` still installs the compiled plugins only. The model packages ship their source the same way.

## [3.12.2] - 2026-10-31

### Fixed
- **`generate()` no longer deletes a variable whose name starts with the new name.** Stata's `drop` accepts a unique abbreviation, so `nwfactions, generate(fac)` removed the user's variable `faction` before creating `fac`. 37 sites in 29 commands (`nwfactions`, `nwkcore`, `nwcomponents`, `nwcommunity`, `nwcoreperiphery`, `nwclustering`, `nwbetween`, `nwkatz`, `nwplot`, `_nwdatasync` and others) now drop an old result only if the variable exists under exactly that name (`capture confirm new variable`). Test `test_dropabbrev.do`. The `nwcug` help example now includes the `generate()` that `nwcomponents` requires.

## [3.12.1] - 2026-10-28

Menu change that 3.12.0 described but did not contain.

### Changed
- **Menu.** With `nwinstall, gui`, the "Statistical Models" menu keeps its four core entries and has exactly one entry for each model package: "Stochastic actor-oriented model (nwsaom)" and "Exponential random graph model (nwergm)". The other dialogs of these packages (Bayesian estimation, several networks, multiplex, meta-analysis, describe, postestimation, simulation) are opened by buttons in the main dialogs of nwsaom 1.3.2 and nwergm 1.3.3. Before, all of them were listed in the menu one after the other.

## [3.12.0] - 2026-10-28

The dialogs of the model packages are no longer one flat list in the menu.

### Changed
- **Menu layout.** With `nwinstall, gui`, the "Statistical Models" menu keeps its four core entries (correlate, CUG, QAP, utility scores) and adds one submenu per model package: "Stochastic actor-oriented models (nwsaom)" (fit a model, several networks that change together, multiplex networks, Bayesian estimation, meta-analysis, describe the data, postestimation) and "Exponential random graph models (nwergm)" (fit a model, simulate networks, postestimation and goodness of fit). Entries and submenus appear only for dialogs that are installed. The Mata library is unchanged, so the model packages need no release.

## [3.11.1] - 2026-10-27

Fixes for clashes between your own Stata matrices, scalars and variables and those of nwcommands, and one plot error. The Mata library is unchanged, so the four model packages need no release.

### Fixed
- **Commands no longer overwrite or delete your own Stata matrices, scalars and variables.** `nwcomponents`, `nwkcore`, `nwconcor`, `nwcommunity`, `nwmodularity`, `nwplot` and `nwqap` used plain names for their working matrices and scalars (`comp_id`, `comp_sizeid`, `block_id`, `core_id`, `comm_sizeid`, `components`, `communities`, `modularity`, `nsizerow`, `pvalues`, `permvar`, `reg_results` and others). A matrix or scalar of yours with the same name was replaced, and often removed when the command finished (`nwplot` also created and dropped a variable `_id`). They now use private temporary names. The results in `r()` and `e()` are the same. The new test `test_stata_userspace.do` guards this.
- **`nwplot` with `components()` stopped with error 3301 (subscript invalid)** when the data set had more or fewer rows than the network has nodes (for example after you worked with a smaller network on the same data). The nodes of each component are now found from the network itself.

### Known limitation
- When a command stops with an error half way, its private Mata variables (names starting with `__nw`) can stay until the next run or `mata: mata clear`. They never replace your own variables.

## [3.11.0] - 2026-10-27

Fixes for clashes between your own Mata variables and the Mata variables of nwcommands. The Mata library is unchanged (the library hash is the same as in 3.10.0), so the four model packages need no release and work with 3.10.0 and with 3.11.0.

### Changed
- **The registry of networks is now the Mata global `__nw` (it was `nw`).** This is visible only to scripts that address the registry directly: `nw.nws.pdefs[1]` must now be written `__nw.nws.pdefs[1]`, and `r(netobj)` strings that a script stored before upgrading must be created again. Code that uses `r(netobj)`, `_nwsyntax` or the `nwtomata` commands needs no change.

### Fixed
- **Commands no longer overwrite or delete your own Mata variables.** About 30 commands (among them `nwplot`, `nwcommunity`, `nwcomponents`, `nwkcore`, `nwconcor`, `nwcloseness`, `nwburt`, `nwqap`, `nwmixing`, `nwexpand`, `nwlattice`, `nwneighbor`, `nwutility`, `nwset`, `nwcorrelate`, `nwdendrogram`) used short global Mata names such as `Coord`, `M`, `temp`, `reach`, `far` or `comm_id` for their own work. A variable of yours with the same name was replaced, and often deleted when the command finished. They now use private names (`__nwplot_Coord` and so on) and remove them again; several commands (`nwtriads`, `nwmotifs`, `nwmixing`, `nwcug`, `nwdyadprob`, `nwfromedge`, `nwhierarchy`, `nwimport`, `nwload`) also no longer leave temporary Mata variables behind. The new test `test_mata_userspace.do` guards this.
- **A Mata variable called `nw` broke every command.** The registry of all networks was the global Mata variable `nw`, so a user's own `nw` (a common name) replaced it and the next command stopped with "type mismatch: exp.exp: transmorphic found where struct expected" (cured only by `mata: mata clear`). The registry is now `__nw`. Scripts that address the registry directly (`nw.nws.pdefs[1]`, `r(netobj)` strings stored for later) must say `__nw.nws.pdefs[1]`; code that goes through `r(netobj)` or `_nwsyntax` needs no change. The Mata library is unchanged.

## [3.10.0] - 2026-10-26

Layouts that use the tie values, faster and wider similarity and null-model commands (native plug-in generation 12), and tests of the native kernels that run without Stata. The Mata library is unchanged (the four model packages need no release). The macOS plug-in is rebuilt; the Linux and Windows plug-ins come from the CI build after the push.

### Results that change (read before you re-run old scripts)
- **Plots of valued networks get different node positions by default.** `nwplot` (default `layout(kk)` and `layout(frucht)`) and `nwmovie`/`nwmoviexy` (each wave) now use the tie values as strengths, as `igraph::plot()` does for a graph with a `weight` attribute: strongly tied nodes lie closer together. `kk`: the ideal distance of two nodes is the shortest path with edge length 1/value; `frucht`: the attraction along a tie is multiplied by its value (`layout_with_kk(weights=)` takes edge lengths, so one passes 1/value; `layout_with_fr(weights=)` takes strengths). The values are divided by their mean first, so the unit of the values does not matter. Option `binary` restores the layouts of 3.9 and earlier (they are bit-identical for the same seed). Unvalued networks, two-mode networks, networks whose ties all have the same value, and the layouts `mds`, `mdsclassical`, `hierarchy`, `bipartite`, `circle`, `grid` are not affected.
- A **signed network** (a tie value that is not positive) keeps the unweighted layout and prints a note, as `igraph::plot()` does (igraph's `layout_with_fr()`/`layout_with_kk()` refuse non-positive weights; `plot()` warns and ignores the weights).
- `nwmovie`: `binary` is now also passed to the layout of the first network.
- `nwcug` on a two-mode network no longer stops with error 6088: it draws from four null models (see Added). One-mode networks are as before.
- `nwcorrelate` (and with it `nwsimilar, type(pearson)`) formed the n x n matrix four times (`nwset, mat()` evaluated its argument four times): 10.6 seconds at 5,000 nodes. It is formed once now; the numbers are the same.

### Added
- **Kernel 51: node-by-node similarities** of `nwsimilar` (pearson, matches, jaccard, hamming, crossproduct), `nwdissimilar` (euclidean, manhatten, nonmatches, jaccard, hamming) and `nwcorrelate`, all contexts and valued or binary, directed or not: the cells come from the stored ties instead of dense matrix products. 5,000 nodes (10 ties per node): `nwsimilar` pearson 0.45 s (10.6 s before, 24 times faster), the other types 0.36 to 0.38 s (1.0 to 1.2 s before), `nwdissimilar, type(manhatten)` 0.37 s (about 25 minutes in Mata: it had no closed form and ran O(n^3) loops). Differences from the Mata code below 1e-13 (2,688 combinations in the development checks); a network with missing tie values and a platform with an older plug-in keep the Mata code. R: the definition written out in `tools/verify_native390.R`; `igraph::similarity` agrees on the pairs that are not adjacent.
- **Kernel 52: `nwcommunity, algorithm(dirtlpa)`**, the label propagation LPAwb+ of Beckett (2016) in its repeated form DIRT_LPA+ (R: `bipartite::DIRT_LPA_wb_plus`), for two-mode networks; options `reps()` (default 10) and `minmodules()` (default 4) as `reps` and `mini` of the R function; reproducible with `seed()`; plug-in only (without a generation-12 plug-in the command stops with a message that asks for the update). Southern women: Barber's Q 0.3455 (the best known, as with Louvain); `ftdirectors_se`: 0.95110 in 12 seconds against 0.95101 for 100 starts of the Louvain search (0.2 seconds).
- **Kernel 53 and `nwcug` for two-mode networks**: `condition(density|mode1degree|mode2degree|degrees)` (equivalents: `vegan::nullmodel` r00, r0, c0, curveball; `igraph::sample_bipartite(type = "gnm")`), option `trades()`; the draws are made natively on the list of ties and written into one copy of the network. The null means and standard deviations agree with `vegan::nullmodel` (Southern women, NODF).
- **Kernel 54: the sweeps of the weighted Kamada-Kawai layout** of `_nwwlayout` (nwplot and nwmovie `layout(kk)` on valued networks) run natively: 2,000 nodes 0.74 s against 7.0 s in Mata, same start coordinates give the same layout (differences below 1e-14); the Mata code stays as the fallback.
- `_nwwlayout.ado` (internal): the weighted layouts. `kk` with values: shortest weighted paths and Gauss-Seidel stress majorization; the sweeps run in the plug-in (kernel 54, below), the Mata code is the fallback for a missing or older plug-in (about 1.5 s for 1,000 nodes and 18 s for 5,000 nodes in Mata).
- Dialog `nwmovie`: checkbox `binary`.
- Test `cscripts/test_native390.do` (fixtures `cscripts/native390_fixture/`, R script `tools/verify_native390.R`).
- Test: `cscripts/test_wlayout.do`.
- **Tests of the native kernels without Stata** (`native/test/`): `test_kernels.c` compiles the shipped kernels against a stand-in for the plugin interface and checks 170 cases (kernels 1 to 54): every kernel against results recorded from the macOS plugin (`native/test/fixtures/golden.txt`), against the R/igraph/bmotif fixtures of the cscripts, against textbook answers (stars, paths, rings, complete graphs), properties of the null-model draws (margins and counts exact), and large sparse cases of 20,000 to 100,000 nodes with sums or cell numbers above 2^31. `make -C native test` runs it anywhere with a C compiler.
- The workflow `.github/workflows/test-kernels.yml` runs the harness on Linux (gcc, with sanitizers), macOS (clang) and Windows (MSVC `cl`) for every push or pull request that touches `native/`, and uploads the compiler warnings. It builds and commits nothing.

### Changed
- The Windows plugin is compiled with optimisation (`/O2`); it was built without it, so the Windows kernels ran as unoptimised code. Results are unchanged.

### Fixed
- **64-bit counters in the native kernels (Windows).** The C kernels counted nodes, ties, indices, offsets and products of them in `long`, which is 32 bits in the Windows build (MSVC) and 64 bits on macOS and Linux. All 1,245 uses are now a 64-bit type (`nwint`, `native/nwtypes.h`), so a value above 2^31 can no longer wrap on Windows only. No result changes on macOS or Linux (the kernels of generation 11 are bit-identical); within the documented limit of 100,000 nodes no wrong result was found on Windows either, the change closes the latent cases (the diagnostic counters of very long searches, bit-set offsets above about 370,000 nodes, result sizes above 2^31 cells). Also: the Windows build uses the compiler's own bit-scan instruction for the lowest set bit, the headers include what they use (`<time.h>`, `<stdlib.h>`, `<string.h>`), and a malformed argument string no longer dereferences a null pointer.

### Notes
- `nwsimilar, type(pearson)` ignores `context()` (it calls `nwcorrelate` with its default, the outgoing ties); unchanged.
- `nwsimilar, type(hamming)` counts the left-out positions i and j as matches (two per profile); unchanged, documented in the R script.


## [3.9.2] - 2026-10-26

The "Network Analysis" menu is set up once, whatever you run and however often. Only `nwinstall` (ado, help file, dialog) and its tests changed: no command, result, Mata library or plug-in differs from 3.9.1 (the four model packages need no release).

### Results that change (read before you re-run old install scripts)
- **`nwinstall` never writes the menu line twice.** The line `nwinstall, usermenu` is kept at most once in `profile.do`: the older `nwinstall, downloadoff` (and spellings with other spacing or a `quietly`) count as the same line, and extra copies already in the file are dropped when you run `gui`, `all` or `everything` (the rest of the file is kept byte for byte). A menu line of another origin (your own `window menu ... "Network Analysis"` line, `nw_menu`, a menu line in another `profile.do` that Stata reads) stops `nwinstall` from adding a second menu; it names the line and the file. Before, running `nwinstall, gui` after a hand-written menu line gave two menus.
- **The menu is rebuilt from an empty User menu**, so running `nwinstall` twice in one session shows each entry once (before: twice). This clears other entries you added to the User menu in that session.
- `nwinstall, gui`, `all` and `everything` print one line about the menu ("installed", or "already set up in ...").
- **`nwinstall, remove` now also uninstalls the numbered packages** (`nwcommands-ado1`, `-hlp1`, `-dlg1`, ...); before it only tried the unnumbered names of the old layout and left the files behind.

### Added
- `nwinstall, everything` (and `all`) set up the menu and the dialog boxes permanently (this was already so in 3.9.1; the help and the website now say it). New option `nogui` (dialog: checkbox) leaves the menu and the `profile.do` line out. `models` and `modelpkg()` alone never touch the menu.
- `nwinstall, dupcheck` reports dialog files (`.dlg`) that exist in more than one folder of the ado path and says which copy Stata uses; nothing is deleted. `all`, `dialog` and `localcopy` run it at the end. It returns `r(ndup)`.
- A menu that cannot be built (batch run, Stata without menus) is a note, not an error: an install in a do-file or CI run goes on.
- Test: `cscripts/test_nwinstall_gui.do`; `cscripts/test_nwinstall_everything.do` extended (one line after `everything` twice, `nogui`, `remove`).

## [3.9.1] - 2026-10-26

### Added
- The short install address `https://nwcommands.org/net/`: `net install nwcommands, from(https://nwcommands.org/net/) replace`. The deploy workflow copies the starter package (`stata.toc` with the starter entry, `nwcommands.pkg` and the files it lists) into `net/` of the website after the site build (`tools/make_net_dir.sh`; test: `tools/test_net_dir.sh`). The GitHub address keeps working and `nwinstall` still fetches the rest from GitHub. The install lines in the README, help files, error messages and the website show the short address first.
- `tools/release_preflight.py` checks that the deploy workflow copies the starter and, with `--post`, that `https://nwcommands.org/net/stata.toc` is reachable.

No command, result, Mata library or plug-in changes.

## [3.9.0] - 2026-10-26

Plot appearance: `nwplot`, `nwmovie` and `nwplotmatrix` now show what a valued, signed or two-mode network is made of, and `nwturnover` is right on two-mode networks. Only the ado and help files changed: no new plugin generation, no change of the Mata library (the four model packages need no release).

### Results that change (read before you re-run old analyses)
- **`nwplot` draws the tie values of a valued network as edge widths by default** (before: all edges the same width unless `edgesize(<network>)` was given). The widths run from 1 to 4 units (largest absolute value widest, at most 15 width classes; ties of equal value keep the default width). `binary` gives the old picture. Colours never follow the values unless `edgecolor()` is given. `edgesize()` keeps its 1 to 8 range. `nwmovie` inherits the change (and passes `binary` on).
- **`nwplot` draws a signed network (valued, negative ties) with positive ties solid navy and negative ties dashed cranberry, and a legend** (before: all ties the same colour, a negative tie looked like a positive one). The width follows the absolute value. `nosign` gives the old colours; an own `edgecolor()` wins. A negative `edgesize()` value no longer makes the plot fail.
- **`nwplot` of a two-mode network draws the two modes with different symbols and colours and a legend** (circle and diamond; before: one symbol and colour for all nodes) unless `color()` or `symbol()` is given.
- **`nwplotmatrix` has a colour legend (value classes; "no tie" and "tie" on a binary network) by default** (`legend(off)` as before) and, on a two-mode network, puts the nodes of one mode next to each other (unless `sortby()` or `group()` is given) with a line between the modes.
- **`nwturnover` on two-mode networks no longer counts the cells inside a mode** (they are structurally missing, but were read as ties present in both networks, so stable, formed and dissolved ties and the Jaccard index were wrong); only ties between the modes count.

### Added
- `nwplot`: options `binary` and `nosign` (dialog: tab "More options"); stored results `r(edgewidth)`, `r(signcolor)`, `r(modesymbols)`. `nwmovie`: options `binary` and `nosign`, passed to `nwplot`. Test: `cscripts/test_plotfix.do`.
- `nwaltergen`: `wmean` prints one note on a signed network (weights with their signs). `nwdyadprob`: `density()` with neither a weight network nor `mat()` stops with r(198) and a message (was a raw r(3499)).

### Fixed
- `nwplot ... if ..., edgesize(<network>)` failed (a mistyped temporary network name); it works.

### Speed (no change in results)
- `nwgeodesic ..., force` on an unvalued network took 37 s at 600 nodes because option `force` sent it to the Mata Dijkstra routine; it now uses the same hop-count routine as the call without `force` (0.03 s at 600 nodes, 1.2 s at 5,000). The distances are identical (checked on 90 combinations of binary, valued, directed and disconnected networks and options against 3.8.0). The Mata library did not change.

## [3.8.0] - 2026-10-26

Two-mode dispatch, and the bipartite motifs of `bmotif`. Plugin generation 11 (native counting of bipartite motifs). The Mata library did not change, so the four model packages need no new release (they do not call the commands that changed and still require nwcommands 3.6.0 or later). A platform whose plugin has not been rebuilt yet (Linux, Windows before the CI build) has no `nw2motifs`/`nwmotifs` on a two-mode network, the rest works as before.

### Results that change (read before you re-run old analyses)
- **A network declares itself two-mode when it is created, and a command that has a two-mode form of the same concept now uses that form on a two-mode network without being asked.** The option `onemode` forces the one-mode computation on the bipartite graph (what `igraph` does with a bipartite graph). Calls on one-mode networks, and all calls with `onemode`, give exactly what 3.7.0 gave (checked bit for bit in `cscripts/test_dispatch380.do`). The commands:
  - **`nwcloseness` and `nwbetween` on a two-mode network** give the normalisations of Borgatti and Everett (1997) by default: closeness is the smallest possible farness of a node of its mode divided by its farness, betweenness is divided by the largest value a node of its mode can reach (before, the raw closeness (N-1)/farness and raw betweenness of the bipartite graph; those are `onemode`). `twomode`, the earlier way to ask for this, is still accepted as a synonym; `onemode` together with `twomode` is error 198. On a two-mode network `standardize` of `nwbetween` is this standardisation. `r(bw_central)` is computed from the raw scores whatever the option (before, with `twomode`, from the standardised scores).
  - **`nwmotifs` on a two-mode network** counts the bipartite motifs of Simmons et al. (2019, `bmotif`) and the positions of the nodes in them (the table and options of `nw2motifs`) instead of the 4-node census of the bipartite graph read as a one-mode graph, which is `onemode`. The options `plot` and `name()` have no two-mode form (error 198).
  - **`nwdegree` and `nwclustering` on a two-mode network** gave the two-mode result already (they handed the call to `nw2degree` and `nw2clustering` with a note). They now do it without the note and take all options of the two-mode form (`raw` for the count; `level()`, `ra` and `replace` for `nwclustering`); an option that has no two-mode form (`isolates`, `standardize`, `in()`, `out()`, `outputoff`; `silent` and `symmetrize` of `nwclustering`) is named in one note and ignored. `onemode` gives the degree (the number of ties) and the clustering coefficient (0) of the bipartite graph.
- Commands that already followed the rule are unchanged (`nwcommunity` and `nwmodularity`: the bipartite modularity of Barber, `onemode` for Newman; `nwsimilar` and `nwdissimilar`: nodes are compared with nodes of their own mode; `nwspectral` and `nwrandomwalk`: `onemode` reads the graph as a one-mode graph).

### Changed
- `nw2degree`, `nw2clustering` and `nw2motifs` are aliases of `nwdegree`, `nwclustering` and `nwmotifs`: they keep their names, their options and their results (same variables, same `r()`, same messages; `cscripts/test_dispatch380.do` compares them with the 3.7.0 results), and they still stop with error 198 on a one-mode network. `nw2project` and `nw2nested` have no one-mode counterpart and keep their own names.
- The help files say in one wording what a command does with a two-mode network ("Two-mode: two-mode form by default ..."); the dialogs of the five commands have the new options (`onemode`, `raw`, `ra`, `level`). `nwnetworktypes` states the rule once.

### Added
- **`nw2motifs`**, the bipartite motifs of a two-mode network (Simmons et al. 2019, `bmotif`; Baker et al. 2015; Stouffer et al. 2012): the 17 motifs of two to five nodes (44 with the option `sixnode`), their frequencies (`r(motifs)`, with the four normalisations of `bmotif::mcount` through `normalise`) and, for every node, the number of times it holds each of the 46 (148) node positions, stored in variables (`generate()`) or a matrix (`matrix()`), with the twelve normalisations of `bmotif::node_positions` (`posnorm()`). Motif and position numbering are those of `bmotif` (table in the help file). The counting runs in the native plugin without matrices of the size of the network (the 5,092 + 455 directors: the motifs and positions up to five nodes in 0.04 s, up to six nodes in 0.05 s; `bmotif::mcount` and `node_positions` together need 54 s for the five-node set and cannot do six nodes on that network). Results equal `bmotif::mcount` and `bmotif::node_positions` (bmotif 2.0.2) on the toy network, the Southern women, the Swedish directors, a subsample of them and 34 random networks (4 of them larger), for the motif table and for every node (`cscripts/test_nw2motifs.do`, fixture `cscripts/native380_fixture`, made by `tools/verify_native380.R`). A valued network counts the ties above zero (the usual note); the weighted measures of `bmotif` are not offered. A plugin older than the command (or missing for the platform) stops the command with a message that tells how to update; there is no slow Mata fallback.
- `nwmotifs` counts the bipartite motifs on a two-mode network (see Results that change); `nw2motifs` is the same command under its older name.

## [3.7.0] - 2026-10-26

Plugin generation 10 (native kernels for the two-mode and valued commands), valued closeness at any size, level labels of two-mode networks in files, and a few corrections. The Mata library did not change. The four model packages are released with it as patch releases (nwsaom 1.0.10, nwergm 1.2.3, nwdynam 1.1.3, nwrem 1.0.8; they still work with nwcommands 3.6.0). A platform whose plugin has not been rebuilt yet (Linux, Windows before the CI build) keeps the Mata code and gives the same results, slowly.

### Results that change (read before you re-run old analyses)
- **A valued network of more than 100 nodes no longer gets the hop-count closeness or distances silently.** `nwgeodesic` (and through it `nwcloseness`) computed the distances of a valued network of more than 100 nodes on the unvalued network and only said so ("Calculated on unvalued network because network size exceeds 100"); `nwcloseness` never passed `force` on, so the weighted closeness was out of reach. They now compute the least-cost distances (cost 1/w^alpha, `alpha(-1)` = igraph's lengths) at any size with the native plugin; closeness, farness and nearness of such networks therefore differ from before (they used steps). A platform whose plugin is older stops with r(198) unless `force` (slow Mata routine) or `binary` (steps) is given. `force` of `nwcloseness` is passed on to `nwgeodesic`.
- **`nwshared` on a directed network without the option `undirected` now stops with error 198** and a message, as its help file always said. 3.6.0 ran without the option and without a message. Add `undirected` (the network is symmetrized first) to get the earlier result.
- **The native bipartite Louvain search of `nwcommunity` does not give the partition of the Mata search for the same seed** (the two use different random generators and neighbour orders). With the new plugin the result is the same on every platform for a given seed; Barber's Q is the same on the Southern women (0.3455) and statistically the same on larger networks. `nwpermute, swap` draws differently for the same reason (see Added).

### Added
- Native Dijkstra kernels for `nwcloseness` (sums and reachability without the n x n matrix: 1,000 nodes 0.15 s, 10,000 nodes 14 s) and `nwgeodesic` on valued networks; equal to the Mata distances and to `igraph::closeness` with lengths 1/w and w (reachable-nodes form).
- Native kernels in the core plugin: the bipartite (Barber) search of `nwcommunity` on two-mode networks (27 times faster on the 5,092 + 455 directors: 2.4 s to 0.09 s), the weighted walk of `nwpagerank`, the maximum-weight matching of `nwmatching` on valued networks (Hungarian method; the 455 + 5,092 case of the directors takes 0.2 s, the Mata routine cannot do it), the tie swapping of `nwpermute, swap` (works on the list of ties, no n x n matrix) and the weighted betweenness of `nwbetween` on valued networks (1,000 nodes: 0.13 s instead of 111 s; 10,000 nodes 15 s). Results equal the Mata routines (PageRank and betweenness to 1e-9, the matching exactly up to 1,500 nodes in the larger mode and with the same total value above), and R: `igraph::page_rank`, `igraph::betweenness` with lengths 1/w, `igraph::max_bipartite_match` with weights (all in `cscripts/test_native370.do`).
- The random starting orders of the two-mode search of `nwcommunity` and the exchanges of `nwpermute, swap` come from a generator of their own that is seeded from `set seed` (or `seed()`): the same seed gives the same result on every platform with the new plugin. They are therefore not the same draws as in the Mata code; Barber's Q is the same on the Southern women (0.3455) and statistically the same on the directors.

### Fixed
- `nwexport` and `nwimport` keep the level labels of a two-mode network (for example "women" / "events"): Pajek gets a comment line before `*Vertices` (Pajek ignores it), GML the graph attributes `nwmodelabel1` and `nwmodelabel2`, the edge list the labels in the mode columns instead of 1 and 2. UCINET DL has no place for them (a file read back has the labels "rows" and "columns"). Test: `cscripts/test_small370.do`.
- `nwimport, type(ucinet)`: a rectangular matrix with the same number of rows and columns (`nr=` and `nc=` given, for example 3 women by 3 events) was read as a one-mode network and failed; it is now read as a two-mode network.
- `nwshared`: the documented requirement of `undirected` on a directed network is now enforced (see Results that change); help, test and the network-types tables say so.
- `nwinduced` error message for a directed network no longer points to an internal file.
- Website pages and logs show "plugin build" instead of "plugin protocol" in the output of `nwsaom version`.
- `nwmixing` printed stray "invalid name" lines before the table (fixed in 3.6.0, see below); `test_small370.do` repeats the check.

## [3.6.0] - 2026-10-26

This release changes results for valued networks and for two-mode networks. Read the first list before you re-run old analyses. The native plugin has a new generation (9, for the weighted `nwburt`); the Mata library changed, so the four model packages are released in step (nwsaom 1.0.9, nwergm 1.2.2, nwdynam 1.1.2, nwrem 1.0.7).

### Results that change (read before you re-run old analyses)
- **The Valued flag is set when a network is created and is no longer worked out again from the values.** A network is valued if it was created with tie values: `nwfromedge`/`nw2fromedge` with a value variable (also when every value is 1), `nwimport` of a file with tie values (Pajek edge lines with a third field, GML `value`/`weight`, a matrix with values other than 0 and 1), `nwset` from a matrix with a value other than 0 and 1 (the only place where the numbers decide), `nwset, valued`, a saved network that was saved as valued. It is binary if it was created without tie values or with `unvalued`. Transformations (`nwkeepnodes`, `nwdropnodes`, `nwsubset`, `nwtranspose`, `nwsym`, `nwcollapse`, `nwpermute`, `nwduplicate`, `nwrecode`, `nwreplace`, `nwreplacemat`) keep the flag of the source; `nwdichotomize` gives a binary network. Before, only a value below 0 or above 1 made a network valued, so shares, probabilities and normalised weights ran as binary in `nwclustering`, `nwcommunity`, `nwmodularity`, `nwspectral`, `nwconcor`, `nwcoreperiphery` and `nwfactions`; they are valued now. **Networks saved with an earlier release keep the flag they were saved with**: a network of shares that was saved as binary is still binary after `nwuse`; correct it with `nwname netname, newvalued(true)` (or re-create it).
- **On a valued network the commands that have a weighted form in R now use the tie values by default** (before, they counted every tie once unless an option was given). The option `binary` gives the earlier result. Binary networks give the same results as before, bit for bit. Changed defaults on valued networks: `nwdegree` and `nw2degree` (the degree is the strength, the sum of the tie values; `alpha(0)` or `binary` gives the number of ties; new option `ties()` stores the tie counts next to the strength), `nwgeodesic` (a step along a tie of value w costs 1/w, i.e. `alpha(1)`; `alpha(-1)` reads values as lengths as igraph does), `nwcloseness`, `nwbetween` (`weighted` is accepted and redundant), `nwevcent` (`weighted` accepted and redundant), `nwpagerank` (the surfer follows a tie in proportion to its value), `nwrandomwalk` (hitting times of the weighted walk), `nwpath` (path of least cost; new options `alpha()` and `binary`, new result `r(path_cost)`), `nwmatching` (the matching of largest total tie value, new result `r(weight)`; the maximum number of pairs with `binary`), `nwassortativity` (the node attribute is the strength instead of the degree), `nwkatz, walks`, and through them `nwinduced`. Each prints which weighting it used. `nwdegree`, `nwgeodesic` and other commands that call them internally (`nwplot`, `nwsummarize`, `nwreach`, `nwutility`, `nwkatz` without `walks`) keep the binary measure.
- `nwdegree` on a valued network stores the degree in double precision (strengths are not whole numbers); on a binary network it is float as before.
- `nwbetween, weighted` counted tied shortest paths wrongly when path lengths are sums of fractions (alpha 1): equal lengths differed by rounding. Lengths are now compared with a relative tolerance (1e-10). Values change on networks with equal-cost paths (Sampson Berthold 18.08 becomes 14.07; the printed `gang_valued` node g20 73.91 becomes 74.08).
- `nwsimilar, type(crossproduct)` now uses the tie values (sum over k of w_ik w_jk), as documented; before it counted common contacts. Binary networks are unchanged.
- `nwtoedge`, `nwsave` and `nwexport, type(gml)` wrote tie values with 7 digits (3 digits from 1e7 on); they now keep full precision. `nwfromedge` stored the tie value in single precision (16,777,217 became 16,777,216); it now uses double.
- `nwcollapse` returns a network with the directedness of the original (an undirected network came back directed, a directed one was flagged undirected when the collapsed ties happened to be symmetric).
- **Two-mode networks keep their flag.** `nwdropnodes` and `nwkeepnodes` returned a one-mode network (flag false, density from the old modes, `nwdegree` counting ties, `nwclustering` 0, `nwproject` refusing): the flag, the modes of the remaining nodes and the level labels are now kept. `nwduplicate`, `nwsym`, `nwtranspose`, `nwsubset`, `nwdichotomize`, `nwrecode`, `nwaddnodes` and `nwpermute` lost the level labels (shown as `()`); they keep them. The flag is set by declaration only (`nwset, twomode|bipartite`, `nw2fromedge`, `nwfromedge ..., twomode`, `nwimport`, `nwuse`); `nwname ..., new2mode(true)` on a one-mode network, or on a network with a tie inside a mode, now stops with error 459, and `nwreplacemat` refuses a matrix with a tie between two nodes of the same mode of a two-mode network.
- **Commands that cannot say anything about a two-mode network now stop with one message and error 6088** instead of returning all-missing or meaningless numbers: `nwspectral`, `nwrandomwalk` (both give the result for the bipartite graph read as a one-mode graph with the new option `onemode`), `nwcorrelate` (profiles of the nodes of one network), `nwhierarchy`, `nwconcor`, `nwfactions`, `nwcoreperiphery`, `nwqap`, `nwcug`, `nwinduced` and `nwcollapse` (its message is now the common one). The common helper is `_nw2guard`; the help file of every command states in one of four fixed wordings what it does with a two-mode network.
- **`nwcommunity` and `nwmodularity` use Barber's bipartite modularity on a two-mode network** (the null model counts only pairs of nodes from different modes; R: `bipartite::computeModules`). Southern women: 4 communities, Q 0.3455 (the optimum of `computeModules`), before 3 communities and Newman Q 0.3325. `onemode` gives the earlier modularity of the bipartite graph read as a one-mode graph (`igraph::cluster_louvain`). `r(modularity_type)` says which. One-mode networks are unchanged. The search is a Louvain-type search in Mata with `starts()` starting orders (default 30; with 10 about one run in five stopped at a partition slightly below the optimum on the Southern women), not the native kernel.
- **`nwsimilar` and `nwdissimilar` on a two-mode network compare a node with the other nodes of its own mode over the nodes of the other mode** (the groups of a person); pairs of nodes from different modes are missing. Before they filled every pair, including a person against a group, and `pearson` and `euclidean` returned only missing values. `crossproduct` is the number of shared nodes (no longer doubled).
- **`nwpermute` of a two-mode network permutes within the modes.** It used to put ties inside a mode (19 rows in the edge list of a network with 12 ties). New `swap` (and `swaps()`) exchanges the partners of two ties and keeps both degree sequences.
- **An edge list of a two-mode network holds its ties.** `nwtoedge` and `nw2toedge` write the ties between the modes (the option `compress` is the default for two-mode networks; `allpairs` gives the earlier one row for every pair, 55 rows for 10 nodes). Reading `nwtoedge` output with `nwfromedge ..., twomode` gave 18 nodes instead of 10 before. The list also carries the level labels and the modes of isolated nodes, which `nw2fromedge` restores.
- **`nwexport` and `nwimport` keep a two-mode network in all four formats** (before every format came back as a one-mode network; the edge list came back directed). Pajek is written as `*Vertices n n1` with the first mode first, UCINET as a rectangular matrix with row and column labels (a rectangular DL file used to be refused), the edge list gets five columns (ego, alter, value, mode of the ego, mode of the alter), GML the node attribute `nwmode`. A file that declares a two-mode network but has a tie inside a mode is refused (error 459).
- `nwdyads` of a two-mode network shows `Reciprocity: n/a` and stores a missing `r(reciprocity)` (it printed 1). `nwtriads` of a two-mode network no longer announces a delegation and stops with `invalid syntax`; it prints the triad census of the bipartite graph and the transitivity 0.
- `nwimport, type(gml)` put the labels on the wrong nodes from 10 nodes on (the ids were sorted as text, "10" before "2"); fixed.
- `nwdegree, standardize` divided the degree of an undirected network, and the outdegree of a directed network, by (N-1)^2 instead of N-1 (the indegree was right). Standardised degree is now degree / (N-1) in every case. The stored centralisation (`r(dg_central)`, `r(indg_central)`, `r(outdg_central)`) was and is computed from the raw degrees and does not change.
- `r(bw_central)` of `nwbetween` was half of Freeman's betweenness centralisation for undirected networks (and for directed networks analysed with the default symmetrisation). It is now sum(max - b_i) / ((N-1)^2 (N-2) / 2) for undirected and sum(max - b_i) / ((N-1)^2 (N-2)) for directed raw scores (`nosym`), so a star gives 1. The node scores themselves do not change.
- `nwcloseness` on an unconnected network returned closeness above 1 (sum of the finite distances times N-1) and never printed its warning. It now prints a warning and, as R's igraph does, divides the number of nodes a node can reach by its farness, so closeness stays at most 1; a node that reaches nobody gets a missing value. Connected networks, and results with `unconnected()`, are unchanged. Option `legacy` returns the old (N-1) / farness. Farness and nearness are unchanged.
- `nwsimilar` and `nwdissimilar` with `type(jaccard)` and `context(both)` (the default) gave asymmetric and wrong values (the union in the denominator used only the first node). The union now pools the out- and in-neighbours of both nodes, positions i and j left out. The other contexts and types are unchanged.
- `nwutility` with `intrvalue()` or `intrcost()` ignored `benefit()` and `cost()` (benefit was fixed at 1 and the cost per tie at 1). `benefit()` now decays the weighted benefit and `cost()` is the cost of a tie when `intrcost()` is not given, as the help describes. Calls without `intrvalue()` and `intrcost()` are unchanged.
- `nwburt` on a **valued** network now computes Burt's (1992) weighted measures. Before, the tie values were put into the formulas of a binary network without the normalisations that Burt's definitions need, so effective size could be negative and efficiency below 0 (the gang network with values 1 to 4: effective size from -16.6 to 15, 22 of 54 members negative; the Chesapeake network: down to -1.8e10). Now, as in `igraph::constraint(weights=)` of R and `networkx.effective_size` / `networkx.constraint`: the strength of the relation between i and j is the sum of both directions (z_ij + z_ji), p_ij is its share of the sum over all contacts of i, m_jq is a_jq divided by the largest a_jk of j, and effective size, efficiency (effective size divided by the number of contacts), constraint and hierarchy follow Burt. A directed valued network is therefore symmetrized (igraph does the same); a directed network that is not valued is not, and gives the same numbers as before. As for the other commands with a weighted form in R, the Valued flag of the network decides (a network that was created with tie values is weighted by default); the option `binary` ignores the values (every positive value is a tie). Networks that are not valued give exactly the same numbers as before.
- `nwburt` stops with an error for a network with negative or missing tie values. `dyadredundancy` and `dyadconstraint` need the option `binary` for a valued network.
- The weighted measures run in the native plugin only (plugin generation 9, kernel 40; no slow Mata fallback). Without the plugin, or with an older one, a valued network gives the error "Weighted Burt measures need the native plugin of nwcommands >= 3.6.0; use the binary option for the unweighted measures".
- New stored result `r(weighted)`. Regression tests `cscripts/test_burt_valued.do` (60 random valued networks against an independent R implementation that agrees with igraph and networkx to 1e-10; the R script is `tools/verify_burt.R`).
- `nwconstraint` (the dyadic constraint network) is not changed and still uses the tie values as they are.

### Added
- The full US airport network `usair_full` (549 airports, 5,450 directed routes, three connected components; attributes iata, name, city, lat, lon and the degrees) is now documented as bundled example data: `nwwebuse usair_full`. It is derived from the OpenFlights airport and route databases (route data of about 2014) and stays under their Open Database License (ODbL 1.0), with attribution; it is not covered by the GPL-3 of the code. See `NOTICE.md`, `help netexample` and the website page "Data sets". New test `cscripts/test_usair_full_data.do`.
- `nwinstall, everything` installs the core (what `nwinstall, all` installs) and the four model packages (what `models` installs) as one set, checks first that every model repository can be reached and that no model needs a newer core, and prints the version of each package at the end. `from()`, `modelsfrom()` and `release()` work as for `models` (offline installs from local folders). `nwinstall, all models` is the same as `everything`.
- `nwinstall, all` ends with a hint on how to add the model packages.
- `nwinstall` and `nwversion` print a note (and go on) when Stata is older than version 17.
- Mata library (rebuilt with Stata 17; the model packages must be rebuilt against it): `calculate_pagerank` and `calculate_randomwalk_hitting` take an optional weighted argument, new `get_path_weighted` and `calculate_matching_maxweight` (Hungarian method); the defaults of the existing Mata functions are unchanged.
- Help files and dialogs of the changed commands describe the valued-network rule and the option `binary`; a page on valued networks on the website.

- Two-mode measures from R: `nw2nested` (nestedness NODF of Almeida-Neto et al. and the C-score of Stone and Roberts; equal to `vegan::nestednodf(order = TRUE)` and `bipartite::C.score`), `nw2clustering, ra` (global clustering of Robins and Alexander 2004, 4 C4 / L3; Opsahl's coefficient stays the default), `nw2project, stat(newman)` (Newman's collaboration weight, `tnet::projecting_tm`), `nw2degree, raw` (the count, `tnet::degree_tm`), `nwcloseness, twomode` and `nwbetween, twomode` (normalisations of Borgatti and Everett 1997).
- Mata library (rebuilt with Stata 17; the model packages must be rebuilt against it): Barber modularity and Louvain-type search (`nw_modularity_bip`, `nw_louvain_bip`, `calculate_modularity_bipartite`, `detect_communities_bipartite`), `count_samemode_ties`, within-mode `permute` and `permute_swap`, `nw_twomode_profile`, `nw_nodf`, `nw_cscore`, `nw_robins_alexander`, `nw_be_maxbetween`, `nw_isolate_modes_string`, the Pajek, GML and UCINET writers; `NWsdef::duplicate` and the subgraph copies carry the level labels. The existing functions are unchanged.
- Decisions on the open questions of the two-mode plan: (1) `nwrandomwalk` and `nwspectral` refuse, with `onemode` for the bipartite graph read as a one-mode graph; `nwsimilar`/`nwdissimilar` compare within a mode; `nwcorrelate` refuses; (2) `nwcommunity` uses Barber modularity by default, `onemode` for Newman; (3) `nw2clustering` keeps Opsahl's coefficient as the default and offers `ra`; (4) `nw2degree` keeps the division by the other mode and offers `raw`; (5) the default of `nw2project` stays `minmax`, `newman` is new; (6) Pajek files of two-mode networks are always written in the bipartite form; (7) the edge list of a two-mode network is `compress`ed by default, `allpairs` restores the earlier output; (8) `nwcug` refuses a two-mode network and `nwpermute, swap` is the two-mode null model; (9) two-mode ERGM terms stay in nwergm; the core keeps the flag right for them.
- Help files, dialogs, a website page on two-mode networks (and one on the network types of all commands) and the tutorial on two-mode networks describe the rules. Test: `cscripts/test_twomodesupport.do` (R references: igraph 2.3.2, tnet 3.0.16, vegan, bipartite 2.24).
- Not done, for a later release (plugin work): a native kernel for the bipartite Louvain search and for Beckett's DIRT_LPA+ (`computeModules`), faster tie swapping for large networks, bipartite motifs, `nwcug` with a two-mode null model, H2' and other `networklevel` indices.

### Fixed
- `nwkeepnodes` and `nwdropnodes` lost the Valued flag of the network.
- `nwimport, type(gml)` ignored the tie `value`/`weight` and the `directed` key of the file.
- `nwconcor` stopped with a false "every node must have at least one tie" on signed networks (it summed values, so negative ties cancelled positive ones).
- The commands that are binary by definition (R has no weighted form) print one line "(note: tie values are ignored; this measure is binary)" when given a valued network (not with `silent`): `nwbridges`, `nwbrokerage`, `nwclique`, `nwcohesion`, `nwcomponents`, `nwdyads`, `nwego`, `nwkcomponents`, `nwkcore`, `nwkplex`, `nwmixing`, `nwmotifs`, `nwnclan`, `nwnclique`, `nwneighbor`, `nwreach`, `nwshared`, `nwsimindex`, `nwsimmelian`, `nwtabulate`, `nwtriads`, `nwturnover`.
- `nwimport` refused a rectangular UCINET matrix ("Two-mode networks are not supported"); it is read as a two-mode network.
- `nwpermute`, `nwduplicate` and the subgraph commands lost the two-mode level labels.
- `nwkatz` stopped with r(459) when the data set had more observations than the network has nodes; the extra observations are now left missing, as in `nwdegree` and `nwcloseness`.
- `nwmixing` printed stray "0 invalid name" lines before the mixing table.
- `nwcorrelate` stored the permuted correlations as float, so the tie handling in the p-value depended on rounding; they are now stored as double (also in the file written by `save()`).
- `nwreach` help said the network is symmetrised by default; it is not (use `sym`). The help now says so.
- Help for `nwdegree`, `nwbetween`, `nwcloseness` (new option `legacy`, also in its dialog), `nwsimilar` and `nwdissimilar` states the formulas used. Regression test `cscripts/test_auditfix.do`.

### Changed
- Supported Stata versions: 17 or later, tested with Stata 17 and 18 (StataBE is enough); the false "Stata 14 or later" is replaced in the README, `help nwintro`, the help of `nwinstall` and the website. The install pages and the home page lead with `nwinstall, everything`.

## [3.5.1] - 2026-10-25

### Fixed
- **The Mata library could not be used in Stata 17.** The library `lnwcommands.mlib` of 3.5.0 was built with Stata 18; Stata 17 ignores a library built by a newer Stata, so every command that builds or reads a network stopped with `nws_create() not found` (r(3499)). The library is now built with Stata 17, which Stata 17 and Stata 18 both read.
- A command that meets a missing library, one built by a newer Stata, or an old copy of the library (for example left in your PLUS folder by an earlier install) now says so in plain words (and how to reinstall) instead of `<istmt>: 3499 nws_create() not found`.

### Changed
- Requirements stated plainly: Stata 17 or later; tested with Stata 17 and Stata 18; Stata 16 and older are untested. The build script `lib/build.do` refuses to build with a Stata newer than 17 (override for experiments: environment variable `NW_ALLOW_NEWER_STATA=1`).

## [3.5.0] - 2026-10-25

### Results that change (read before you re-run old analyses)
- **Negative ties of undirected networks were lost** when a network was built from a tie list that lists each pair once (`nwfromedge ..., undirected`, `nwset ..., edgelist undirected`, `nwsave` then `nwuse`, `nwimport type(edgelist) forceundirected`): every -1 became 0, so signed undirected networks lost their negative ties and `nwbalance` then called every triad balanced. They are now kept. Re-load signed undirected networks that were saved or built this way.
- Ties are ordered the same way under every seed: equal-sized classes in `r(core_sizeid)` (`nwkcore`), `r(comm_sizeid)` (`nwmodularity`) and `r(block_sizeid)` (`nwconcor`) are listed by ascending id, and a few figures (`nwplot`, `nwplotmatrix`, `nwmovie`) and the vector of a repeated eigenvalue (`nwspectral`) can differ from earlier runs. Details below.
- Error messages that were swallowed inside `quietly` blocks are now visible (see Fixed).

### Fixed
- Error messages printed inside a `quietly` block were swallowed, so the user saw only "invalid syntax". Now shown: `option generate() required.` for `nw2degree`, `nwbrokerage`, `nwclique`, `nwcohesion`, `nwcommunity`, `nwconcor`, `nwcoreperiphery`, `nwdegree`, `nwkcomponents`, `nwkcore`, `nwnclan` and `nwnclique`; the "already exists" messages of `nwbetween` and `nwfromedge`; the size limit of `nwconcor`; and two messages of the bar-plot helper (`all bars zero height?`, `choose between offset() and zoffset()`).
- Ties are broken the same way under every seed. Mata's `sort()` and `order()` order equal keys by the state of the random-number generator, so with equal values these results changed from run to run: the order of equal-sized classes in `r(core_sizeid)` (`nwkcore`), `r(comm_sizeid)` (`nwmodularity`) and `r(block_sizeid)` (`nwconcor`) and which of two equal components `nwplot` draws first; the order of events with the same time in the `nwmovie` file; the vector of a repeated eigenvalue in `nwspectral`; the order of nodes within one group in `nwplotmatrix, group()`; and the positions in the layouts `hierarchy` and `bipartite` of `nwplot`. Equal sizes are now listed by ascending id, and the other ties keep the order of the input.

### Fixed (results change!)
- Saving and reloading an undirected signed network (`nwsave` then `nwuse`, also `nwappend`) turned every negative tie into 0, so `nwbalance` then reported every triad as balanced. The same happened with `nwfromedge`, `nwset` and `nwimport` when an undirected network was built from a list that gives each tie once (`undirected`, `forceundirected`): the symmetrisation compared a value of -1 with the 0 of the absent direction and kept the 0. A tie listed in only one direction is now stored with its own value (if both directions are listed with different values the larger one is kept, as before). Networks with only non-negative values are not affected. Saved files made with 3.4.0 or earlier load as before; if you saved an undirected network with negative ties, rebuild it from the original data. `nwsym` itself is unchanged: on a directed network, `mode(max)` still treats a missing tie as 0. Regression test `cscripts/test_signfix.do`.
- The signed example data sets are now stored with each tie once (smaller files); loading them gives the same networks.

### Added
- Three signed example networks (one valued network with +1 and -1 ties), loaded with `nwwebuse`: `senate114` and `senate93` (US Senate co-sponsorship networks of the 114th and 93rd Congress, Neal 2020, doi:10.6084/m9.figshare.8096429, CC BY 4.0: 100 senators with 1,435 positive and 2,261 negative ties, and 101 senators with 581 positive and 1,858 negative ties; attributes state and party) and `gahuku` (alliances and enmities among the 16 Gahuku-Gama tribes, Read 1954: 29 positive and 29 negative ties). Sources, licences and the changes made to the Senate subset are in `help netexample` and the website page "Data sets"; regression test `cscripts/test_signed_data.do`.

## [3.4.0] - 2026-10-25

### Results that change (read before you re-run old analyses)
- **Node-level results could land on the wrong nodes.** About 20 commands (`nw2degree`, `nwaltergen`, `nwbrokerage`, `nwburt`, `nwclique`, `nwcohesion`, `nwcommunity`, `nwcomponents`, `nwconcor`, `nwcoreperiphery`, `nwego`, `nwgeodesic` (eccentricity), `nwkcomponents`, `nwkcore`, `nwkplex`, `nwnclan`, `nwnclique`, `nwspectral`, `nwturnover`, `nwutility`) wrote their result variable to rows 1 to n of the data set, whatever order the data set was in. If you had sorted or `gsort`ed the data (or used a projection of a two-mode network) before the call, values were attached to the wrong nodes. They are now matched to the nodes by name. Re-run analyses in which a data set was sorted before such a command.
- `nwqap, qapspp` gave p = 0 for every coefficient (it compared a logit coefficient with an OLS-scale null); it now uses the partial OLS slope, so p-values change.
- `nw2project` and `nwproject` report the number of edges (each pair once), no longer twice that.
- `nwsummarize` of a large two-mode network reports the density over the pairs between the two modes.
- `nwpermute, generate()` stops if the network already exists unless `nwreplace` is given (it used to overwrite silently).

### Added
- `nwclique` and `nwkcomponents` have the option `nomatrix` (as `nwnclique`): `r(clique_matrix)` / `r(kcomp_matrix)` are not built or stored; the generated variable and the counts (`r(cliques)`, `r(kcomponents)`) are the same. Stata stores a result matrix in time that grows with the square of the number of columns (about 45 s at 100,000 nodes whatever the number of rows, a transposed matrix costs the same), so the matrix cannot be made cheaper; without it `nwclique` takes 0.26 s at 100,000 nodes instead of 37 s (it gets the clique numbers from the kernel's list of (clique, node) pairs). The default is unchanged.
- Two two-mode example data sets, loaded with `nwwebuse`: `davis` (Southern women of Davis, Gardner and Gardner 1941: 18 women, 14 events, 89 ties; attributes surname, title, event date) and `ftdirectors_se` (a subset of the Financial Times directors-and-companies data of Evtushenko and Gastner, doi:10.5281/zenodo.3553442, CC BY 4.0: 5,092 directors, 455 companies, 5,669 ties; attributes gender, age, sector, industry, employees). Sources, licences and the changes made to the subset are in `help netexample` and the website page "Data sets". Regression test `cscripts/test_twomode_data.do`.

### Changed
- Help files and dialog boxes brought up to date with the changes of this release. Dialogs: `nwplot` has new tabs Interactive (`interactive`, `noopen`, `fname()`, `movieexport()`, `importcoords()`, `edgeimport()`) and More options (`aspectratio()`, `arrows`, `force`, `sizebin()`, `edgeforeground()`, `edgepatternpalette()`, `lineopt()`, `scatteropt()`, `legendopt()`, `exportopt()`), the layouts `kk`, `hierarchy` and `bipartite` (with `vertical`) and the coordinate export `generate()`, which the dialog had not passed on; `nwmovie` has the edge, per-wave, palette and scheme options; `nwnclique`, `nwnclan` and `nwkplex` have `maxcliques()`/`maxplexes()`, `maxtime()`, `countonly` and `nomatrix`; the commands with a size guard (`nwbetween`, `nwcloseness`, `nwkatz`, `nwkcomponents`, `nwspectral`, `nwreach`, `nwconcor`, `nwcontext`, `nwdissimilar`, `nwexpand`, `nwhierarchy`, `nwqap`, `nwsimilar`, `nwsimindex`, `nwutility`) have `force`; `nwcorrelate` has all its options; `nwconstraint` has `name()` and `replace`; `nwexport` offers `gml` and `edgelist`; new dialog `nwpagerank` (menu Network Analysis > Centrality). Help files: stale run times and limits updated in `nwintro`, `nwburt`, `nwconstraint`, `nwsimmelian` and `nwkcomponents`; `nwsimmelian` documents `nwreplace`, `nwexport` the `gml` and `edgelist` types, `nwcorrelate` the default `context(outgoing)` and the content of `save()`, `nwuse` and `nwsave` the two-mode file; the commands with a Limits section point to the web page "How large a network can I analyze?".
- Not changed: the random network generators (`nwrandom`, `nwpref`, `nwsmall`, `nwring`). Their seeded random-number stream is kept (the same seed gives the same network), which a native generator could not do, and what is not drawing time (`nwring`, `nwpref`) is the construction of the network in Stata.
- (The native kernels listed under Faster need no change of the Mata library; the library does change with the Mata speed-ups listed first under Faster: **the model packages nwsaom, nwergm, nwdynam and nwrem must be rebuilt against the new `lnwcommands.mlib` and released in step**.) The Linux and Windows plugins must be rebuilt by the plugin workflow before a release (until then those platforms use the Mata code and are as slow as before).
- `nwtriads`: the count of empty triads (`r(_003)`) is the exact integer; the Mata census could carry a rounding error of one unit in the last place (about 4e-12 at 28,643).

### Fixed
- Interactive viewer: coordinates given with `nodexy()` (or `importcoords()`) that are not on the canvas scale (degrees, metres, ...) were drawn as a tiny cluster with invisible labels (usair with `Lon Lat`). They are now shifted and scaled uniformly (aspect ratio kept) to at most 1,500 pixels, the default node size follows the node density (8 to 34 px) and the label font follows the node size; layouts already on the canvas scale are unchanged.
- Static `nwplot, edgesize()`: the line widths used the raw tie values (clamped at 20); the values are now mapped linearly onto the widths 1 to 8 units like the viewer. New option `edgesizeraw` keeps the old behaviour.
- `nwcorrelate ..., save("name.dta")` with quotes (or with spaces in the path) did not save and printed a wrong path; it saves and prints the full path. `nwsave`/`nwuse` handle quoted names and long absolute paths with spaces.
- Dialog boxes: many labels were stripped fragments ("Dismat", "Generate", "default = "); about 60 dialogs got readable labels from the help files. `nwconstraint` and `nwcorrelate` dialogs have `undirected`/`directed`; `nwcorrelate` (one network) accepts them and forwards them to `nwset`.
- Interactive viewer (`nwplot, interactive`, and the `nwmovie` player): the page drew y downward while Stata draws it upward, so the page and the static figure were mirror images (with `nodexy(Lon Lat)` the US was upside down); the page now uses y up for every layout and the saved node CSV has the same orientation, so `importcoords()` brings the picture back unmirrored. `edgesize()` is shown on the page (tie values map linearly to 1-8 px widths; the slider multiplies on top). `edgecolor()` of a continuous network stopped with "invalid name"; it is now cut into five classes with a sequential palette (integer networks stay categorical). `edgeimport()` accepts the edge file of an undirected network (one row per tie as saved by the page). Arrowheads scale with the edge width (capped) instead of staying at the size of a 3 px line. Test: `cscripts/test_viewerfix2.do`.
- `nwplot, force` stopped with "option force not allowed" (the first option parse did not know `force`); it now draws.
- Node-level variables written by position are now aligned with the network: `nw2degree`, `nwaltergen`, `nwbrokerage`, `nwburt`, `nwclique`, `nwcohesion`, `nwcommunity`, `nwcomponents`, `nwconcor`, `nwcoreperiphery`, `nwego`, `nwgeodesic` (eccentricity), `nwkcomponents`, `nwkcore`, `nwkplex`, `nwnclan`, `nwnclique`, `nwspectral`, `nwturnover` and `nwutility` wrote their results to rows 1 to n of whatever order the data set was in. After `nw2project` (which leaves the data set in another order) the community of the Davis women landed on events, and after `sort`/`gsort` the results of `nwutility` belonged to other nodes. They now call `_nwdatasync` first, as `nwdegree`, `nwcloseness`, `nwbetween`, `nwevcent` and others already did. Test: `cscripts/test_pkgfix.do`.
- `nwsummarize` of a large two-mode network printed `Density: 0` and returned the density over all node pairs (`ftdirectors_se`: .000369); it is now ties over the pairs between the two modes (.00245), and the printed value keeps three significant digits.
- `predict newnetname` works after `nwqap` (it stored nothing and failed with "variable ... not found"); it builds the fitted-value network of the last model. `nwqap, qapspp` compared the observed logit coefficient with a null on the OLS scale and returned p = 0 for every coefficient; the observed statistic is now the partial OLS slope. The header reads `QAP, double semi-partialling` with `qapspp`.
- `nwmixing` with a string attribute printed `__000000_ego | __000000_alter` as the table header; it now shows `attribute_ego | attribute_alter`. The density plot note of `nwmixing` and `nwcorrelate` no longer names an undefined network, and `nwcorrelate, save()` reports the path it wrote.
- `nwdyads` accepts a network list and wildcards (`nwdyads lazega_*`) like `nwsummarize`.
- `nwdyadprob, density()` no longer leaves the helper network `_tempdyad` behind when it fails (the next call stopped with r(483)).
- `nwbrokerage` refuses a string `group()` variable (it classified nothing or everything as one role).
- `nwgeodesic` prints "Network is unvalued; alpha is ignored" only when `alpha()` was typed.
- `nwreplace` set the valued flag of a 0/1 undirected network after its symmetry correction.
- Printed three-decimal numbers (`nwturnover` persistence, Jaccard, `nwcug`, `nwsummarize detail` and others) no longer show floating-point noise such as `.5690000000000001`.
- `nwsave` of a two-mode network writes only the ties between the modes (it listed every pair of nodes inside each mode as well: 2.6 GB for a 5,092 + 455 node network, now 1.2 MB). `nwuse` and `nwappend` restore an identical network (ties, modes, labels, attributes); files written by earlier versions still load, and the new files load in earlier versions. `nwtoedge, compress` (and so `nwexport`) of a two-mode network now lists only the between-mode ties, like `nw2toedge`. Test: `cscripts/test_twomode_save.do`.
- `nwmovie, noopen` opened the viewer anyway (the option was declared in a form Stata reads as `open`); it now opens nothing.
- `nwplot, interactive` has the option `fname()` to write the HTML page to a chosen file; the path is displayed and returned in `r(fname)` (`r(interactive)` unchanged).
- Interactive viewer: the shape drop-down of a colour group shows "mixed" when the group has nodes of several shapes (it showed the first node's shape). The saved CSV is unchanged.
- Bring-back of a saved interactive layout (`importcoords()`/`edgeimport()`): the size slider is a multiplier of the view's pixel size, so the static plot drew symbols about five times too large unless `nodefactor()` was given. The slider value is now scaled (1 corresponds to `nodefactor(0.2)`) so the static plot has the proportions of the view. An explicit `nodefactor()` still wins. The size legend symbols of `nwplot, size()` are grey filled circles with a thin outline (they were black dots with a thick grey ring).
- Stray Stata messages no longer leak into the output of core commands: `(N real changes made)` from `nwtoedge` (and so from `nwmixing`, `nwtabulate`, `nwhomophily`, `nwcollapse`, `nwcorrelate`, `nwqap`), `(N missing values generated)` from `nwpagerank`, `nwfactions`, `nwneighbor`, `nwmaxflow` and `nwcorrelate`, and `variable _nwnode was str5 now str7` from `nwcollapse`. The regression test `cscripts/test_no_leaked_lines.do` scans the output of these commands.
- Output formatting: `nwdegree` and `nwsummarize` print `Degree centralization:` with one colon (was two); `nwevcent` no longer prints a leading `.` before its note on the symmetrized network; rounded results in the display of `nwturnover`, `nwmixing`, `nwclustering`, `nwsummarize`, `nwcug` and other commands no longer show floating point artefacts such as `.5690000000000001` (return values `r()` keep full precision, only the printed text changed).
- `nwattime` prints the number of ties of the static view (an undirected tie was counted twice in the printed line); `r(ties)` is unchanged and still counts triplet rows.
- `nwcorrelate` with `permutations()` and `save()` stored the observed correlation as missing in the saved file; it now holds the observed value.
- `nwbrokerage` help: states the Gould-Fernandez condition that the code applies (paths with a tie from a to c are not counted).

### Faster
- **Core Mata library and shared plumbing** (`lnwcommands.mlib` changes; results are identical, see the checks below). Where the time went at 100,000 nodes / 1 million ties, measured first: sorting the tie list twice (`set_edge_from_triplets()`: 8 s for the 11 million cells of `nwconstraint`), the sort for the in-neighbour index of a directed network, a name hash (0.5 s), the Stata-side dictionary of `nwfromedge` (stack, egen group, collapse, two merges: 0.9 s), and the preserve/merge/gsort of `_nwdatasync` (0.2 s in every command that writes variables). Changes: a tie list that already comes in ascending (ego, alter) order (the kernels, `nwfromedge`, `nwsym`) is not sorted again and its row pointers are made without a loop; the in-neighbour index of a directed network is built when something first asks for it (`degree_in()`, `neighbors_in()`, `get_indegree()`, the components search; a command that does not need it, such as `nwconstraint` or the plugin kernels, no longer pays for it); out- and in-degrees by panel sums (bit-identical to the loops); `check_symmetry()` sorts once; the components search reads the index directly; `nwkcore` fills its padded neighbour matrix in one step; `update_nodesvar()` checks the names of a large network with one sort. `_nwdatasync` now handles directly the two cases that need no merge (the data hold exactly the node names in node order, or the dataset is empty): its early exit had never worked. `nwfromedge` builds the node dictionary in Mata when the identifiers are integers without missing values (the Stata route stays for everything else, `noclear` included). Stata/BE, random network with 5 ties drawn per node (mean degree 10 when undirected), seconds before / after at 1,000 / 5,000 / 20,000 / 100,000 nodes: `nwfromedge` 0.052 / 0.091 / 0.36 / 1.93 and 0.015 / 0.044 / 0.12 / 0.51 (undirected: 0.039 / 0.13 / 0.49 / 2.59 and 0.021 / 0.073 / 0.24 / 1.07); `nwdegree` (undirected) 0.009 / 0.024 / 0.070 / 0.29 and 0.003 / 0.005 / 0.016 / 0.032 (directed 0.010 / 0.023 / 0.072 / 0.30 and 0.004 / 0.013 / 0.045 / 0.19); `nwcomponents` (undirected) 0.005 / 0.015 / 0.050 / 0.20 and 0.005 / 0.014 / 0.045 / 0.17; `nwkcore` 0.006 / 0.019 / 0.072 / 0.34 and 0.005 / 0.017 / 0.065 / 0.29; `nwconstraint` (undirected) 0.032 / 0.34 / 1.58 / 9.7 and 0.023 / 0.13 / 0.43 / 2.2 (directed 0.019 / 0.13 / 0.51 / 2.9 and 0.015 / 0.066 / 0.14 / 0.70). `nwcomponents` and `nwkcore` are bound by their own search (0.2-0.3 s at 100,000 nodes), which was not rewritten.
  - Checked old against new on 72 random one-mode networks (5 to 2,600 nodes; directed, undirected, valued, with duplicates, self-loops, isolates, non-consecutive and string identifiers with spaces) and 60 two-mode and temporal ones: `nwfromedge`, `nwload`, `_nwdatasync` in six dataset states, `nwdegree`, `nwcomponents`, `nwkcore`, `nwsym`, `nwconstraint`, `nwtoedge`, `nwsummarize`, `nwgeodesic`, `nwpagerank`, `nwclustering`, `nw2project`, `nwattime`: all tie lists, index arrays, node names, generated variables, datasets and `r()` results are identical, except the order of rows of equal size in `r(core_sizeid)` of `nwkcore` (Mata's `sort()` breaks ties at random: two runs of the old library differ as well). Test: `cscripts/test_matafast.do`.
  - One thing is deliberately not changed: a row with a missing alter in the edge list is kept by the Stata route of `nwfromedge` as a tie with a missing node number (which later gives `r(3301)` or even stops Stata in plugin kernels). A list with any missing identifier is therefore handed to that route unchanged.
- `nwclustering` (binary measure), `nwtriads` and `nwevcent` run in the compiled graph plugin (native kernels 26, 27 and 28; plugin generation 6), with the Mata code kept as the fallback where the platform's plugin is older or missing and for the weighted clustering measures and for networks with self-loops (`nwtriads`). Results are identical (counts exactly, `nwevcent` to the last digit in all test networks). Stata/BE, random network with 10 ties per node, seconds before / after: `nwclustering` 5,000 nodes 1.15 / 0.06, 100,000 nodes 26.1 / 0.7; `nwtriads` 5,000 nodes 3.4 / 0.08, 100,000 nodes 73 / 1.0; `nwevcent` 5,000 nodes 0.69 / 0.05, 100,000 nodes 13.7 / 0.5.
- `nwpagerank`, `nwclique` and `nwkcomponents` (k = 2) run their searches in the compiled graph plugin (native kernels 34 and 35 and a block-based answer for the k = 2 connectivity queries of algorithm 20; plugin generation 8), with the Mata code kept as the fallback where the platform's plugin is older or missing (`nwclique` also for networks with self-loops). Results are identical: the cliques are the same matrix row by row, the k-components the same rows in the same order, PageRank to the last digits (largest relative difference 7e-17; the mass of the dangling nodes is summed in extended precision). Stata/BE, random network with 10 ties per node, seconds before / after: `nwpagerank` (directed) 5,000 nodes 0.12 / 0.03, 100,000 nodes 1.9 / 0.3; `nwclique` (undirected, minsize 3) 5,000 nodes 0.35 / 0.10, 20,000 nodes 3.3 / 1.0 (the search itself takes 0.6 seconds at 100,000 nodes instead of 45); `nwkcomponents` (k(2)) 5,000 nodes 1.8 / 0.1, 20,000 nodes 67 / 1.0, 100,000 nodes over 120 / about 60. From about 40,000 nodes on the time of `nwclique` and `nwkcomponents` is Stata's `st_matrix()` storing `r(clique_matrix)` / `r(kcomp_matrix)` (time grows with the square of the number of columns, whatever the number of rows). The time guard of `nwkcomponents` (refusal above about 31,000 nodes without `force`) is unchanged, although k(2) now takes about a minute at 100,000 nodes.
- `nwburt`, `nwconstraint` and `nwsimmelian` run in the compiled graph plugin (native kernels 29, 30 and 31; plugin generation 7: `native/nwbrokerage.h`), with the Mata code kept as the fallback where the platform's plugin is older or missing, and for `nwburt, dyadredundancy dyadconstraint`, two-mode networks (`nwconstraint`) and networks with self-loops (`nwsimmelian`). Results agree with the Mata route: `nwsimmelian` exactly, `nwburt` and `nwconstraint` to 1e-15 relative (largest difference measured over 98 test networks 3e-16; `nwburt` adds the same terms in the same order and squares with a product; for `nwconstraint` the Mata routine sorts equal cells with a sort that does not keep the input order, and below 4,001 nodes the dense Mata routine multiplies in a different order, both 1e-16). Stata/BE, random undirected network with mean degree 10, seconds before / after: `nwburt` 5,000 nodes 1.18 / 0.03, 100,000 nodes 25.6 / 0.17; `nwsimmelian` 5,000 nodes 0.51 / 0.08, 100,000 nodes 11.6 / 0.75; `nwconstraint` 5,000 nodes 0.58 / 0.44, 100,000 nodes 13.3 / 10.4 (the kernel needs 0.9 s of that; the rest is storing 11 million cells as a network in the Mata library, which the Mata speed-ups above remove).

### Usability fixes (second round, test `cscripts/test_pkgfix2.do`)
- `nw2project`/`nwproject`: `r(ties)` and the printed `Ties:` line are the number of edges (each pair once), not twice that.
- `nwmixing` prints its table itself so value labels up to 30 characters are no longer cut at 9 (with tabulate options passed through, tabulate's own output is used as before).
- `nwaltergen` without a network name prints which network it used.
- New options: `nopaths` (`nwpath`), `silent` (`nwcloseness`), `directed` as a no-op (`nwrandom`), `nwreplace` (`nwpermute`, generate() now stops if the network exists, like `nwpath`), `listall` (`nwcommunity`, `nwcomponents`; the printed table is capped at 30 rows with a note, results unchanged).
- `nwqap` prints its permutation progress lines only with `detail`.
- `nwcug, condition(census)` prints a note when the null standard deviation is 0; `nwsummarize, detail` shows reciprocity as n/a on undirected networks (stored value unchanged).
- Help: `nwtoedge` (undirected valued networks list only `_ego` > `_alter`), `nwcommunity` (label propagation can collapse on dense networks; Louvain ignores the seed), `nwhierarchy` (default linkage is single), `nwclear` and `nwintro` (Stata's `clear` does not remove networks).

### Fixed (book-code triage, test `cscripts/test_triagefix.do`)
- `nwmixing ..., permutations(1)` (no simulation) printed a stray `invalid syntax` line, also under `quietly`, because the p-value was formatted from a result that does not exist; the line now shows only the E-I index. With `permutations(2)` or more nothing changes.

## [3.3.1] - 2026-10-25

### Fixed
- `nwinstall, all` and `nwinstall, models` index the Mata libraries after installing (`mata mlib index`), so the model packages are found in the same session. (Each model package also indexes its own library when it is first used.)
- `nwinstall, ado|help|dialog|all` accepts `from()` (a local folder or URL) as the source of the core package files; the default is unchanged (GitHub).
- Release check: `tools/check_version.py` warns when the core Mata library differs from the hash recorded at the last release (`tools/record_release_hash.py`), as a reminder to rebuild and re-release nwsaom and nwergm in step. `tools/smoke_fresh_install.sh` tests a fresh install from local folders.

## [3.3.0] - 2026-10-25
Networks of 100,000 nodes: more commands work at that size, and commands that cannot are refused at once with a message and an alternative.

### Important
- The Mata library of the core changed. Install the model packages again after updating the core: nwsaom 1.0.4 or later and nwergm 1.1.2 or later (`nwinstall, models`); older model packages stop with r(3021) "class compiled at different times".

### Added
- A page "How large a network can I analyze?" on the website (and an extended Appendix H in the book) says which commands are reasonable for which network size.

### Fixed
- Scaling audit at 100,000 nodes (stage 4; details in the audit report; Stata/BE, random directed network with 10 ties per node, 1.0 million ties, 12 GB memory cap, 300 s limit). Before: of 143 recipes 83 worked (14 of them took 10 s or more), 26 were refused by a guard, 11 in the setup (a two-mode network is one matrix over both modes), 9 were killed at 12 GB, 5 timed out, 1 stopped with r(920) and 6 with an error; none gave a wrong result. After: 93 work (15 take 10 s or more, the slowest 104 s), 36 are refused at once by a guard, 11 in the setup, 3 are not tried; none killed, none timed out, none with an unexplained error.
  - `nwcompressobs` stopped with "type mismatch" (r(109)) above 65,536 nodes: it tried `encode` on the node labels, which fails above 65,536 distinct strings, and then compared the string variable with a number. `nwdropnodes`, `nwkeepnodes`, `nwdrop`, `nwkeep`, `nwsubset` and `nwreplace` end in `nwcompressobs`, so none of them worked on a network of more than 65,536 nodes.
  - `nwdrop`, `nwkeep` and `nwsubset` (the Mata methods `keep_nodes()` / `drop_nodes()`) built the n x n matrix of a large network and were refused; a network held as stored ties keeps the ties between the remaining nodes, renumbered (1.0 s for 50,000 of 100,000 nodes).
  - `nwset` with `time()` or `interval()` built n x n matrices of times (killed at 20 GB at 100,000 nodes). Above 2,000 nodes the times are kept as a list of the ties that have one; `nwattime` reads the list (1.7 s at 100,000 nodes). Two-mode temporal networks keep the matrices.
  - `nwconstraint` of a large network (killed at 12 GB) builds the constraint network from the list of its non-zero cells (12 s directed and 50 s undirected with 40 million cells, 7 GB, at 100,000 nodes); above 2,000 nodes only `name()` and `replace` are accepted.
  - `nwmaxflow` works arc by arc on a network held as stored ties (refused at 100,000 nodes before; 1.7 s); the matrix route is kept for dense networks and gives the same flow, cut side and cut size.
  - `nwrecode` and `nwdichotomize` no longer stop above 46,341 nodes: the 2,147,483,647 limit belongs to `tabulate [fweight=]`, not to counting the changes. `nwtabulate` writes its table itself above that limit (the options of `tabulate` are ignored then).
  - `nwvalidvars` with more names than a Stata macro holds stopped with r(920) after 2.7 s of work; it stops at once with r(900) and says what to use instead.
- Commands that are dense or many minutes by nature stop at once with r(484), a message and an alternative, and `force` runs them anyway: `nwgeodesic`, `nwreach`, `nwlambda`, `nwexpand` (two n x n matrices, above about 27,000 nodes), `nwcontext` (three; names `nwaltergen`), `nwreplace` (three), and, through the new `_nwtimeguard` (limit `nw_max_seconds` = 120 s, estimated from measured rates), `nwbetween` (15 minutes at 100,000 nodes), `nwcloseness` and `nwkatz` (5 minutes: measured 302 s), `nwkcomponents` (43 minutes), `nwcohesion` (13 minutes). Before, each ran into the 300 s limit or to 12 GB.
- Scaling harness: `--noskip` runs every recipe at every size; `nwdyadprob` is capped at 20,000 (the caller's `J(N,N,.01)` is the 80 GB); refusals by a variable-name list that does not fit into a macro count as guards.
- `cscripts/test_scale100k.do` covers the above (sparse = dense for `nwmaxflow`, `nwconstraint` and `nwdrop` on 150 random networks, list = matrix for the temporal values, `nwattime` at 2,500 nodes, `nwcompressobs` with 70,000 labels, `nwtabulate` / `nwrecode` at 50,000 nodes, the guards and the working commands at 100,000 nodes; 8 s).

## [3.2.0] - 2026-10-25
Large networks (to 100,000 nodes) now work, and a series of wrong results found on the way are fixed. Read "Results that change" before you re-run old analyses.

### Results that change
- `nwcommunity` (Louvain): for networks of more than about 1,500 nodes the method found almost no communities (3,000 nodes: 1,311 communities, modularity 0.07; now 14 communities, modularity 0.18), and it was not optimal on small networks either. Partitions of every network that needed a second aggregation step change, for the better; `r(modularity)` changes with them.
- `nwtabulate, attribute()`: the permutation p-value was biased (the missing diagonal was counted as ties in every permutation). P-values of earlier versions are not reproduced.
- `nwmixing, permutations()` replaced a valued network by its 0/1 pattern; after the call the network held only 0 and 1. The network is now left alone.
- `nwrecode` and `nwdichotomize` returned a permuted matrix whenever the node labels were not in alphabetical order (for example n1 ... n12, which sorts as n1, n10, n11, n12, n2, ...). They also lost the values of self-loops and rounded non-integer values. All three are fixed.
- `nwpref` above 10,000 nodes now works (it stopped with an error); up to 10,000 nodes the networks are the same as before for the same seed. `nwrandom, density()` above 5,000 nodes draws from the same distribution with a different random-number stream; with 5,000 nodes or fewer the networks are the same as before.

### Fixed
- Silent damage of node labels above about 900 nodes: `nwdissimilar`, `nwsimilar`, `nwsimindex`, `nwlambda`, `nwdropnodes`, `nwkeepnodes`, `nwcug`, `nwreplacemat`, `nwrandom` and `nwexpand, network()` could insert a blank into long label lists (`n1067` became `n1 067`), so the new network had nodes the data did not know and rows were appended to the data set. Labels are now passed safely at any size.
- `nwfromedge` (and `nwset ..., edgelist`, `nwimport ..., type(edgelist)`) stopped with `r(920)` from about 40,000 nodes. A directed network with 100,000 nodes and 1,000,000 ties now builds in a few seconds. Node labels with a space or comma are kept as given, and duplicate rows in an edge list give one tie (the last row wins).
- `nwcomponents` and `nwcommunity` stopped with `r(134)` when a network had more than 1,000 components or communities; the size table is replaced by a note above 1,000 groups.
- `nw2set` with a matrix of one single tie value, followed by `nw2toedge`, failed with `r(3200)`; fixed. `nwtoedge, compress`, `nwsave`, `nwuse` and `nwappend` work for 100,000-node networks.
- `nwtostata` stops at once with a clear message when the matrix has more columns than Stata has variables. `nwvalue` returned `.` for a pair without a tie in some sparse networks; `nwaddnodes` stored a 0 on the diagonal of a new node; `nwimport` of a `.dta` edge list ignored `directed`; `nwexport` now writes ties in a fixed order; `nwtabulate` no longer prints a stray "(N real changes made)".
- No hidden installs: nwcommands never installs anything from SSC behind your back. `nwdyadprob` and `nwplot` use their own code (a built-in weighted sampler and value-label lookup), and the table plot of `nwtabulate` is built in, with credit to Nick Cox's `tabplot` on which it is modelled.
- Help: every help file ends with the package version and a link to `nwversion`; `help nwtopical` and `help nwalphabetical` list `animate`, `nwcohesion` and `nwversion`, and a new section on the model packages (nwsaom, nwergm, nwdynam, nwrem).
- (The loss of `profile.do` by `nwinstall` was fixed in 3.1.1; it is not part of this release.)

### Added
- Menu: with `nwinstall, gui`, the "Statistical Models" menu lists the dialogs of nwsaom and nwergm when those packages are installed.
- `nwkplex`, `nwnclique` and `nwnclan` stop with `r(484)` and a message instead of running until memory is exhausted: after `maxplexes()` / `maxcliques()` maximal sets (default 100,000; `nwnclan` 1,000,000 examined), when the result matrix would exceed 50 million numbers, or after `maxtime()` seconds (default 60). New options `countonly` (count and tabulate by size without storing the sets) and `nomatrix` (no sets-by-nodes matrix).
- Memory guards: `nwspectral`, `nwconcor`, `nwhierarchy` and `nwcorrelate` of nodes, and commands whose result is a full n x n matrix by nature (`nwsimilar`, `nwdissimilar`, `nwsimindex`, `nwqap`, `nwutility`, `nwplot`, `nwcollapse`, `nw2fromedge`, `nwhomophily`) refuse at once with `r(484)` when the matrices would not fit, and say why and what to use instead. The option `force` runs them anyway. `nwtoedge` and `nw2toedge` refuse more than 50,000,000 rows and point to `compress`; `nwplotmatrix` is refused above 2,500 nodes.
- Notes above 2,000 nodes for the cubic commands `nwspectral`, `nwconcor` and `nwhierarchy`; the help files give measured times and limits.

### Faster (Stata/BE, about 10 ties per node)
Commands that used an n x n matrix now work on the stored ties. Examples: `nwcomponents` 27 s -> 0.5 s (100,000 nodes); `nwtoedge` 4.7 s -> 0.5 s and `nwexport` 4.7 s -> 0.1 s (1,000 nodes; 20,000 nodes now possible); `nwtabulate` 4.7 s -> 0.01 s; `nwrecode` and `nwdichotomize` 16 s -> 0.03 s; `nwkcomponents` 25 s -> 0.05 s; `nwbalance` 71 s -> 0.03 s and `nwmatching` more than 180 s -> 0.7 s (5,000 nodes); `nwmixing` 56 s -> 0.3 s; `nwevcent` 15 s -> 0.6 s; `nwrandomwalk` 65 s -> 0.15 s (10,000 nodes); `nwcloseness` and `nwkatz` 98 s -> 10 s, `nwgeodesic` and `nwreach` 50 s -> 10 s, `nwcommunity, algorithm(labelprop)` 93 s -> 2 s, `nwcoreperiphery` 19 s -> 0.6 s and `nwclique` (10,000 nodes) 77 s -> 0.9 s; `nwbridges`, `nwdyads`, `nwsummarize`, `nwsimmelian`, `nwtranspose`, `nwpermute`, `nwaddnodes`, `nwdropnodes`, `nwkeepnodes`, `nwattime` and `nwnoderename` from many seconds (or out of memory at 12 GB) to under 2 s at 20,000 nodes; the generators `nwring`, `nwrandom`, `nwsmall`, `nwpref` and `nwcug` draw ties as a list above 2,000 nodes; `nwplot, layout(kk)` 16 s -> 4 s. Two-mode networks up to 20,000 nodes in total work in every two-mode command. Results are identical to earlier versions except where listed under "Results that change". The Linux and Windows plugins must be rebuilt before release; without a rebuilt plugin the older, slower code runs with the same results.

### Details by command (for developers)
#### Fixed

- `nwfromedge` (and everything that builds a network from an edge list: `nwset ..., edgelist`, `nwimport ..., type(edgelist)`) now works at the scale the documentation promises. A directed network with 100,000 nodes and 1,000,000 ties builds in a few seconds in Stata/BE; before, it stopped with `r(920)` (macro substitution results in line that is too long) from about 40,000 nodes on, with the dense-matrix refusal `r(484)` at 25,000 nodes, and took 7 s at 10,000 nodes. Causes: (1) `_nwsyntax` exported every node label in one macro (`labs`) and `nwname` in `r(labs)`, which overflows Stata/BE's 264,408-character macro limit; both are now empty once the string would be longer than 200,000 characters (`_nwnodelab`/`_nwnodeid` read the labels from Mata); (2) `nwfromedge` built the label list with a Stata loop over a macro and checked for duplicate labels with an all-pairs comparison; labels now stay in Mata and the duplicate check sorts; (3) the automatic symmetric/directed detection and `nwsym` allocated the dense N x N matrix; `check_symmetry()` and `symmetrize()` now work on the sparse triplets when the dense matrix was never built; (4) `nwload`, `nwsync`, `nwname` (`get_missing_edges()`, `get_selfloops_number()`) touched the dense matrix or built a macro of all node names; (5) `get_modes_labeled_string()` built its result by repeated string concatenation (quadratic, 1.5 s per `nwname` call at 40,000 nodes).
- `nwcomponents` is no longer quadratic: the breadth-first search copied its queue on every step (27 s at 100,000 nodes / 1,000,000 ties, now 0.5 s).
- Duplicate rows (same ego and alter) in an edge list now give one tie, the last row given winning, in the stored sparse index too; before, the adjacency matrix had one tie but `nwdegree`/`nwclustering` counted the duplicate rows.
- Node labels of string identifiers that contain a space or a comma are kept as given (the old macro route split them into several labels and could drop a node's label).

- `nwtoedge, compress`, `nwsave`, `nwuse` and `nwappend` work for a single big network (tested to 100,000 nodes / 1,000,000 ties). `nwtoedge, compress` lists the stored ties instead of building the N x N list of dyads (new `get_edgelist_sparse()`; the output is identical, including the blanked diagonal). The isolates note it stores in the edge list (a Stata characteristic, 67,784 characters at most) falls back to the isolated nodes only when all node names do not fit. `nwsave` writes the mode list from Mata into a strL variable and `nwuse` reads it back through Mata (a macro of all modes was longer than Stata/BE allows from about 40,000 nodes), and `set_modes_from_labeled_string()` no longer scans the string character by character (28 s at 25,000 nodes, now under 1 s).
- `nwimport` of a `.dta` edge list passed `directed` on under a misspelled name, so it was ignored.
- Commands that took O(N^2) time and memory on the whole network now scale with the number of ties (Stata/BE, 10 ties per node, 1,000 nodes before -> after; larger sizes in the help files): `nwtoedge` (all dyads) 4.7 -> 0.5 s (the list is written straight into variables; refused above 50,000,000 rows with advice to use `compress`); `nwexport` (edge list, Pajek, UCINET, GML) 4.7 -> 0.1 s (from the sparse tie list, files written in blocks; 20,000 nodes 1.4 s, before out of memory); `nwtabulate` of one network 4.7 s -> 0.01 s (dyads counted, not listed); `nw2toedge` 8.3 s and 1.3 GB -> 0.7 s (only the dyads between the modes; `compress` uses the ties); `nwrecode` and `nwdichotomize` 16 s -> 0.03 s (recode of the distinct values, then of the stored ties); `nwkcomponents` 25 s -> 0.05 s (vertex-cut search in the native plugin, edge list built from the sparse index; 20,000 nodes 31 s); `nwplot, layout(kk)` 16 s -> 4 s (distances and stress iterations in the native plugin, bit-identical coordinates; 5,000 nodes 127 s -> 21 s); `nwplotmatrix` 16 s -> 5 s (box data built in Mata; no variable per column, so no 2,048-variable limit; refused above 2,500 nodes). `nwduplicate` copies a sparse-native network without building its matrix.
- `nwrecode` (and `nwdichotomize`, `generate()`/`prefix()`) gave the wrong matrix when the node labels were not in alphabetical order (default labels n1..n12 sort as n1, n10, n11, n12, n2, ...): the result was a permutation of the recoded matrix under the old labels. It also lost the values of self-loops, and rounded non-integer values to single precision. All three are fixed.
- `nwexport` to Pajek, UCINET and GML wrote the ties of one alter in an arbitrary order; they are now ordered by alter label, then ego label. `nwtabulate` no longer prints a stray "(N real changes made)" line.
- Native plugin `nwgraph` has two new kernels (vertex-connectivity search, Kamada-Kawai iterations). The macOS plugin is rebuilt; the Linux and Windows plugins must be rebuilt by CI before a release (the Makefile now compiles with -ffp-contract=off so the coordinates are bit-identical to the Mata code); without a plugin the Mata code runs, only slower.
- Scaling audit at 5,000 nodes (Stata/BE, 10 ties per node): 132 of 140 recipes finish in time, 4 are refused by design (`nwnclique`, `nwkplex`, `nwnclan` result limits, `nwplotmatrix` size, `nwtostata` variable limit), 2 are too slow by their algorithm (`nwspectral`, `nwconcor`: cubic, more than 180 s) and one setup chain (`nwdendrogram`) depends on a 170 s clustering. Fixed on the way:
- `nwdissimilar`, `nwsimilar`, `nwsimindex`, `nwlambda`, `nwdropnodes`, `nwkeepnodes`, `nwcug`, `nwreplacemat` and `nwrandom` damaged the node labels of the network they created once the label list was longer than about 5,000 characters (about 900 nodes): Stata inserts a blank into every 5,292th character of a long option value, so labels such as `n1067` became `n1 067`, the derived network had nodes the data did not know and `nwcommands` appended rows to the active dataset (5,004 observations for a 5,000-node network; `nwhierarchy` then failed with "number of selected observations must match dimension of mymat"). The labels now travel in a Mata variable (`nodenames()` of `nwset`, new hidden options `nodenamesmata()` of `nwrandom` and `labsmata()` of `nwreplacemat`).
- `nwbalance` 71 s -> 0.03 s and `nwmatching` more than 180 s (4 GB) -> 0.7 s at 5,000 nodes: two new kernels in the native plugin (`native/nwcomb2.h`, algorithm codes 22 and 23; plugin kernel version 3). The results are identical to the Mata code (32 random networks per command, directed, undirected, valued, two-mode); a platform whose plugin was not rebuilt keeps the Mata code.
- `nwmixing` 56 s (4.2 GB) -> 0.3 s: lists the ties instead of all N x N dyads. `nwevcent` 15 s -> 0.6 s: the neighbour list is built once.
- `nwtostata` stops at once with r(900) and a message when the matrix has more columns than the flavour of Stata has variables (before: a failure after 2,047 variables had been created, then a misleading "variable already defined" on the next call). `nwdyadprob, density()` (and so `nwhomophily`) refuses more than 50,000,000 dyads before doing the dense work.
- `nwspectral`, `nwconcor` and `nwhierarchy` print a note above 2,000 nodes; the help files give the measured times (`nwspectral` 14 s at 2,000 and 50 s at 3,000 nodes, `nwconcor` 16 s and 57 s, `nwhierarchy` 16 s, 45 s and 170 s at 5,000 nodes).
- `cscripts/test_scale5k.do` covers the above (native versus Mata results, labels above 900 nodes, 5,000-node size check).
- Scaling audit at 10,000 nodes (stage 2; details in the audit report): `nwcommunity` found almost no communities above about 1,500 nodes (3,000 nodes: 1,311 communities, modularity 0.07; 10,000 nodes: 4,800) because from the second aggregation level on every super-node counted its own loop as a tie to its own community and never moved. Fixed in the Mata `Louvain()` and in a new native kernel (algorithm code 24, plugin kernel version 4): 3,000 nodes now give 14 communities with modularity 0.18, and the network is no longer made dense. Partitions of all networks that reached a second level change (they are better); `r(modularity)` of large networks is summed over the stored ties.
- `nwcomponents` and `nwcommunity` failed with r(134) ("too many values") after finding the result once a network had more than 1,000 components or communities (any sparse network of a few thousand nodes); the size table is now counted in Mata, the row names are set through the matrix API, and the printed table is replaced by a note above 1,000 groups. Ties in the size order are broken by the group number.
- `nw2fromedge` and `nw2set` (and so every two-mode network above about 5,000 nodes): blanking the same-mode cells built an n x n string matrix (6.3 GB at 7,500 nodes, more than 12 GB at 15,000); now done in place (1.1 GB at 7,500 nodes, 7 GB at 15,000). `nwmatching`, `nw2degree`, `nw2clustering`, `nwproject`, `nw2project` and `nw2toedge, compress` now run at 15,000 nodes (10,000 + 5,000) in 1 to 10 seconds; before, each of them was killed at 12 GB.
- `nwrandomwalk` 65 s (4 GB) -> 0.15 s (0.2 GB) at 10,000 nodes: the hitting times are found by conjugate gradients on the sparse tie list above 1,500 nodes (relative difference to the dense solution below 1e-13, the dense route is the fallback).
- `nwtabulate, attribute()` listed all N x N dyads (58 s and 4.2 GB at 5,000 nodes, refused above 7,071); it lists the ties only now (identical tables, E-I index and p-value on 36 random networks; 10,000 nodes with 100 permutations 46 s).
- `nwexpand, network()` passed the node names through an option string and damaged them above about 900 nodes (the new network had wrong labels, silently); they travel in a Mata variable now (identical networks on 30 random networks with custom labels).
- `nwspectral`, `nwconcor` and `nwhierarchy` (cubic) and `nwcorrelate` of the nodes (about 25 dense matrices) stop with r(484) and a message above 6,000 / 6,000 / 6,000 / 7,000 nodes instead of running for more than 5 minutes or to 12 GB; `force` runs the first three anyway. `nwcollapse` no longer leaves its temporary network behind when it stops.
- Scaling harness: correctness checks against the generator's edge list (node and tie counts, exact tie set, labels, degrees, components, coreness, distances, clustering, modularity, hitting times; a `correct` column and the outcome class WRONG_RESULT); the `nwset` and `nw2fromedge` recipes now measure what their names say.
- `cscripts/test_scale10k.do`, `test_scale10k_rw.do` and `test_scale10k_louvain.do` cover the above.
- Scaling audit at 20,000 nodes (stage 3; details in the audit report; Stata/BE, 10 ties per node, 12 GB memory cap). Before: of 143 recipes 77 were fast, 12 slow, 14 refused by a guard, 9 refused in the setup (two-mode with 30,000 nodes), 26 killed at 12 GB (7 more only by the memory of their correctness check), 3 timed out, 1 stopped with an error; after: 102 fast, 9 slow, 22 refused, 9 refused in the setup, none killed, none timed out, none wrong. Wrong or damaged results found and fixed:
  - `nwmixing, permutations()` overwrote the network with its 0/1 pattern (a Mata function assigned to its argument): after the call a valued network held only 0 and 1.
  - `nwtabulate, attribute()` counted the missing diagonal as ties in every permutation (`net1 != .` without a colon is one comparison of the whole matrix), which shifted the null distribution and so the permutation p-value; fixed, p-values of earlier versions are not reproduced.
  - `nwpref` stopped above 10,000 nodes ("exceeded maximum table size of 10000": `rdiscrete()` takes at most 10,000 probabilities); above that size the picks come from the list of tie end points, proportional to the degrees (up to 10,000 nodes the networks are the earlier ones for the same seed).
  - `edge_weight(i, j)` failed with a subscript error for a pair without a tie in a row that has other ties (`selectindex()` of a column condition without a match has one column); `nwvalue` on a network held as stored ties returned `.` for every such pair.
  - `nwaddnodes` stored a 0 on the diagonal of the added node while all other diagonal cells are missing.
  - `nwcollapse`, `nw2fromedge` and `nwhomophily` ran for 22 s or to 12 GB before refusing a network that is too large; they now refuse at once (r(484)) with the reason and an alternative.
- Commands that built an n x n matrix (or several) for a result that is sparse now work on the stored ties (20,000 nodes; seconds and memory before -> after; the 143-row table is in the report): `nwtranspose`, `nwpermute` (same permutation for the same seed), `nwaddnodes`, `nwdropnodes` and `nwkeepnodes` (the result stays sparse; killed at 12 GB -> 0.6 to 1.0 s), `nwturnover`, `nwshared`, `nwsimmelian` (12.5 GB -> 1.2 GB), `nwbridges` (9.5 s, 9.4 GB -> 0.4 s, 0.3 GB), `nwdyads` (7 s, 6.3 GB -> 0.08 s), `nwsummarize` (4.9 s, 9.4 GB -> 0.02 s), `nwpath` (and `generate()`), `nwvalue`, `nwreach`, `nwexpand`, `nwattime` (did not finish in 3 minutes -> 0.3 s), `nwset, time()` and `eventtime()`, `nwnoderename` (40 s -> 0.2 s: the duplicate test of the variable names compared all pairs). Results identical to the previous versions on 32 random networks per command and kind (`nwdyads`, `nwsummarize`, `nwtranspose`, ...), except where stated here.
- `nwgeodesic`, `nwreach` (and everything that builds the matrix of distances: `nwutility`, `nwdissimilar`, ...): the plugin answers 128 sources per call instead of one (a call read all 400,000 ties and rebuilt the adjacency lists for a single breadth-first search; plugin kernel version 5, an older plugin keeps one source per call): 49 s -> 10 s and 52 s -> 11 s at 20,000 nodes (6.4 GB for the dense result), identical distances.
- `nwcloseness` and `nwkatz` (distance-decay) take the sums of the distances from one breadth-first search per node in the plugin (new kernel, algorithm code 25, plugin kernel version 5): 97.7 s and 99 s, 6.4 GB -> 9.9 s and 10 s, 0.35 GB at 20,000 nodes. Identical to the distance-matrix route up to 1e-12 on 20 random networks (without a plugin of version 5, or with `geodesic_options`, the matrix route runs as before).
- The new kernel is in `native/nwcomb.h` / `nwcomb2.h` (`comb_distsum()`, `NWCOMB_VERSION` 5, listed in `comb_handles()`); the macOS plugin is rebuilt (`rm`, then `make -C native macos-nwgraph`) and `lib/lnwcommands.mlib` too. **The Linux and Windows plugins must be rebuilt by CI before a release**; until then those platforms keep the distance-matrix route of `nwcloseness` and `nwkatz` (same results, the old time and memory).
- `nwclique` kept every maximal clique, including the thousands of size 1 and 2 of a sparse network, as a row of n numbers, and filtered afterwards: 77 s at 10,000 nodes, killed at 20,000. Only the cliques of the asked size are stored now: 0.9 s and 3.0 s (10,000 and 20,000 nodes); the same cliques in the same order.
- `nwcoreperiphery` on the stored ties above 2,000 nodes (the sums of the correlation come from the ties; same cores, the fitness equal up to rounding): killed at 12 GB (19 s and 9.4 GB at 10,000) -> 0.6 s and 0.2 GB. `nwcommunity, algorithm(labelprop)` on the stored ties (same partitions for the same seed): 93 s and 6.4 GB -> 1.9 s and 0.3 GB at 20,000 nodes (the weight to a community was summed over all n nodes and the relabelling of the communities was quadratic).
- The generators `nwring`, `nwrandom, prob()`, `nwsmall` and `nwpref` draw the ties as a list above 2,000 nodes instead of an n x n matrix (same networks for the same seed as before; killed at 12 GB or 3 GB before -> 0.2 to 2.8 s at 20,000 nodes). `nwrandom, density()` above 5,000 nodes draws the positions of the ties directly instead of shuffling all n^2 cells (a different random-number stream, the same distribution; 56 s at 10,000 nodes and a timeout at 20,000 -> 0.2 s); with 5,000 nodes or fewer the old shuffle runs, so earlier seeds give the same networks. `nwcug` follows: 5 draws at 20,000 nodes 2 s.
- Commands whose result or work is an n x n matrix by nature (`nwsimilar`, `nwdissimilar`, `nwsimindex`, `nwcorrelate` of two networks, `nwqap`, `nwutility`, `nwplot`) stop at once with r(484) when their matrices would not fit in 12 GB (`_nwdenseguard`: the message gives the number of matrices and the memory, and names an alternative); the new option `force` runs them anyway.
- Memory of the dense steps that remain: `nwset, mat()` and `nwlambda` hold two n x n matrices instead of four (6.5 GB at 20,000 nodes; killed before), a dense network is turned into its tie index row by row (four matrices before), `nwname` counts missing cells with `missing()`, `symmetrize()` works pair by pair above 2,000 nodes, and the matrix of a sparse network is built in place. `nwreach` is now one n x n matrix (killed at 12 GB -> 11 s, 6.4 GB), `nwdyadprob, mat()` 3.1 s, `nwconstraint` 8.5 s (both killed before).
- A two-mode network of 20,000 nodes in total (13,333 + 6,667) now works in every two-mode command (1.7 to 12 s each; the setup `nw2fromedge` 11 s and 3.4 GB); above 20,000 nodes `nw2fromedge` stops at once with r(484) instead of after 22 s.
- Scaling harness: peak memory and the kill are attributed to the command or to its check (`NWAUDIT_CMD_RC`; a kill after the command returned is reported OK with `correct = UNCHECKED`), the check of a big dense result counts its ties row by row.
- `cscripts/test_scale20k.do` covers the above (sparse = dense on 20 random networks per command, closeness/Katz plugin = matrix, label propagation and core-periphery on pairs = matrix, the generators against the matrix versions, 20,000-node checks of the generators and of `nwcloseness`).
#### Changed
- `nwkplex`, `nwnclique` and `nwnclan` no longer run until memory is exhausted: they stop with r(484) and a message once more than `maxplexes()` / `maxcliques()` maximal sets (default 100,000; for `nwnclan` the number of maximal n-cliques examined, default 1,000,000) have been found, when the sets-by-nodes result matrix would have more than 50 million numbers, or after `maxtime()` seconds of search (default 60). New options: `countonly` (count the sets and tabulate them by size without storing them: `r(size_table)`, `r(maxsize)`) and `nomatrix` (no sets-by-nodes matrix, only the per-node variable and the counts).
- The kernels are in the existing plugin (`native/nwcomb.h`, `native/nwcomb2.h`, included by `native/nwgraph.c`); the macOS binary is rebuilt, and the Linux and Windows binaries are rebuilt by the plugin workflow (`native/Makefile` now links `-lm` on Linux). Until those are in place, a platform without the new binary keeps using the older Mata code, with the same results and the old speed.
- Help files of the nine commands state the measured limits; `help nwintro` has a section on the combinatorial commands.
- Documentation (`README.md`, `help nwintro`) states the measured end-to-end times for `nwfromedge` and the sparse-native commands, and which commands still need the dense matrix (guard at 20,000 nodes), including `nwtoedge` and `nwsave`.
- Every help file ends with the package version (and a link to `nwversion`) instead of showing it at the top of four landing pages.
- `nwtopical` and `nwalphabetical` list `animate`, `nwcohesion` and `nwversion`, and a new section "Statistical models (separate packages)" (nwsaom, nwergm, nwdynam, nwrem) with web links and the `nwinstall, models` line.

## [3.1.1] - 2026-10-24
### Fixed
- The help text for the `s50` example data now describes it correctly: the 50-girl excerpt of the Teenage Friends and Lifestyle Study that is distributed as `s50` with RSiena (the same networks as the Glasgow data), not a university-freshmen panel.
- `nwinstall, remove` (and `gui`/`permanently` when a `profile.do` already exists) could delete the user's `profile.do` on Mac and Linux. The edit ran `shell ... PATH="...c(adopath)..."; mv ...`; `c(adopath)` contains quote characters once a directory was added with `adopath ++ "dir"`, the shell command became unbalanced, `mv` never ran, and the original had already been erased. The edit no longer uses the shell: the new content is written to a temporary file and verified, a backup is made, the file is replaced with Stata's `copy`, and on any failure the original is left untouched (or restored) with a message. Same code on Mac, Linux and Windows. `remove` also strips the `nwinstall, downloadoff` line, and `gui`/`permanently` append `nwinstall, usermenu` (the line `remove` looks for).
- `cscripts/test_nwinstall.do` covers this case (quoted adopath entry, path with spaces, content of the user's profile.do preserved, failing edit leaves the file untouched, `gui` equals `permanently`).

## [3.1.0] - 2026-10-24
### Added
- `nwinstall, gui` installs the "Network Analysis" menu and the dialog boxes (the older option `permanently` still works).
- `nwcommands` help topic lists the model packages and the license.
### Fixed
- Neighbor lists are returned in sorted order independent of earlier session state. `neighbors(i)`, `neighbors_in(i)` and `edgelist()` of a network built through `set_edge_from_triplets()` (`nwfromedge`, `nwset` from an edge list, `nw2project`, `nwattime`) now always list the nodes in ascending order; before, the order of tied sort keys varied with the session, which changed seeded results of MCMC-based commands.
### Changed
- License: nwcommands is now distributed under the GNU General Public License, version 3 (previously a use-only license). `LICENSE` is the GPL-3 text; `NOTICE.md` states the copyright.

## [3.0.0] - 2026-10-24
### Changed
- The model commands `nwsaom`, `nwergm`, `nwdynam` and `nwrem` are no longer part of this package. They are separate packages
  (GPL-3) in their own repositories. Install them with `nwinstall, models` (or `net install <name>`); updating `nwcommands`
  never overwrites them. **Scripts that call these commands need the model packages installed.** This is a breaking change, hence the new major version.
- The core Mata library `lnwcommands.mlib` contains only the core (717 KB instead of 1.7 MB).
- `lib/build.do`, `native/Makefile` and the CI workflow build only the core (`nwgraph`, `nwedit_viewer`).
### Added
- `nwinstall, models` (also `modelpkg()`, `release()`, `modelsfrom()`): install, update to a given release, or remove the
  four model packages.
- `nwversion`: shows the version of the core and of the installed model packages. Version files: `VERSION`,
  `tools/set_version.py`, `tools/check_version.py`, `CITATION.cff`, `RELEASING.md`.
### Fixed
- `_nwrowalign.ado`, which `nwset` needs, was missing from the package lists.
- Help topic pages mention the moved commands as "moved to its own package".

## [2.0.0] - 2026-08-25
Last release that contained the four model families (git tag `v2.0.0`; the final unsplit state is `pre-split-2026-10-24`).

## [1.x] - 2014-2015
The original releases (`v1.0.2-beta3` to `v1.6.3C`).
