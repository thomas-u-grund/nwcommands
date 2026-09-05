{smcl}
{* *! version 3.4.0  30aug2026}{...}
{marker topic}
{helpb nwtopical##visualization:[NW-2.8] Visualization}

{title:Title}

{p2colset 9 15 22 2}{...}
{p2col :nwmovie {hline 2}}Interactive, animated network movie (panel waves or a relational-event timeline){p_end}
{p2colreset}{...}


{title:Syntax}

{pstd}Panel mode - 2 or more already-built networks of the same size, in sequence:{p_end}

{p 8 17 2}
{cmdab: nwmovie}
{it:{help netname}} {it:{help netname}} [{it:{help netname}} ...]
[{cmd:,} {it:{help nwmovie##options:options}}]

{pstd}Event mode - one network built via {help nwset}'s {opt eventtime()} option (the same event-type temporal network {help nwrem} consumes):{p_end}

{p 8 17 2}
{cmdab: nwmovie}
{it:{help netname}}
[{cmd:,} {it:{help nwmovie##options:options}}]

{pstd}
Which mode applies is detected automatically from how many network names are given and whether the single name (if only one is given) is an event-type
temporal network - there is no separate option to choose between them.

{synoptset 22 tabbed}{...}
{marker options}{...}
{p2col:{it:options}}Description{p_end}
{p2line}
{synopt:{opth fname(string)}}base filename for the output; writes {it:fname}{bf:.html} in the current directory; default {bf:movie}{p_end}
{synopt:{opt noopen}}build the .html file but do not open it in a viewer{p_end}
{synopt:{opt layout}({it:{help nwplot##layout:layout}})}{bf:panel mode}: layout algorithm - see {help nwplot}'s own {opt layout()}; any value other than the {bf:kk} default disables the per-wave transitioning below and falls back to {opt fixedlayout}'s one-shared-layout behavior, since only {bf:kk} has a "warm start" to relax from{p_end}
{synopt:{opt fixedlayout}}{bf:panel mode}: compute one node layout, on the first network only, and reuse it unchanged for every wave, instead of the default per-wave transitioning layout (see Description below){p_end}
{synopt:{opth iterations(int)}}iterations for the layout algorithm; default 500{p_end}
{synopt:{opt color}({it:{help varname}})}color nodes by this variable (broadcast to every network/the cumulative event-mode layout network){p_end}
{synopt:{opt symbol}({it:{help varname}})}shape nodes by this variable (broadcast to every network){p_end}
{synopt:{opt size}({it:{help varname}})}size nodes by this variable (broadcast to every network){p_end}
{synopt:{opt edgecolor}({it:{help netname}})}color edges by this other network's own tie values, matching {help nwplot}'s identical {opt edgecolor()} (broadcast to every network; panel mode only){p_end}
{synopt:{opt edgesize}({it:{help netname}})}width edges by this other network's own tie values (broadcast to every network; panel mode only){p_end}
{synopt:{opt colors}({it:{help varlist}})}{bf:panel mode}: one variable PER WAVE (same order as the network list, one per network) instead of {opt color()}'s single broadcast variable - color genuinely tweens wave to wave, not just position{p_end}
{synopt:{opt symbols}({it:{help varlist}})}{bf:panel mode}: one variable per wave instead of {opt symbol()}'s single broadcast variable - shape switches instantly at each wave boundary (not tweened - see Description below){p_end}
{synopt:{opt sizes}({it:{help varlist}})}{bf:panel mode}: one variable per wave instead of {opt size()}'s single broadcast variable - size genuinely tweens wave to wave{p_end}
{synopt:{opt edgecolors}({it:{help netname}} {it:{help netname}} ...)}{bf:panel mode}: one network per wave instead of {opt edgecolor()}'s single broadcast network - edge color tweens wave to wave for any edge that persists across the transition{p_end}
{synopt:{opt edgesizes}({it:{help netname}} {it:{help netname}} ...)}{bf:panel mode}: one network per wave instead of {opt edgesize()}'s single broadcast network - edge width tweens wave to wave for any edge that persists across the transition{p_end}
{synopt:{opt titles}("{it:title1}" "{it:title2}" ...)}{bf:panel mode}: one double-quoted display title per wave, overriding the movie's own displayed wave title/counter (toolbar text and the on-canvas readout box - see Description below); default is each wave's own {help nwname:{opt newtitle()}}, if one was ever set, else its bare network name{p_end}
{synopt:{opt label}({it:{help varname}})}node labels{p_end}
{synopt:{opt colorpalette}({it:string})}see {help nwplot}{p_end}
{synopt:{opt edgecolorpalette}({it:string})}see {help nwplot}{p_end}
{synopt:{opt symbolpalette}({it:string})}see {help nwplot}{p_end}
{synopt:{opt scheme}({it:string})}see {help nwplot}{p_end}
{synopt:{opth duration(int)}}{bf:panel mode}: milliseconds per wave-to-wave transition; default 800{p_end}
{synopt:{opt easing}({it:string})}{bf:panel mode}: a Cytoscape.js easing name (e.g. {bf:ease-in-out-cubic}, {bf:linear}, {bf:ease-in-out-bounce}); default {bf:ease-in-out-cubic}{p_end}
{synopt:{opth window(real)}}{bf:event mode}: a tie fades out {it:window} time units (same units as {opt eventtime()}'s own variable) after its most recent event, and is removed once fully faded; omitted means ties accumulate permanently (a "growth" movie) rather than decaying{p_end}
{synopt:{opth speed(real)}}{bf:event mode}: simulated event-time units per real second during playback; default 1{p_end}
{p2colreset}{...}


{title:Description}

{pstd}
{bf:nwmovie} opens a live, interactive, animated view of a network changing over time, rendered with Cytoscape.js in a chromeless native
viewer window (the same one {help nwplot}'s own {opt interactive} option uses - falls back to an ordinary browser tab when that native
binary isn't available for the current platform). It replaces the previous ImageMagick/{cmd:graph export}-based pipeline entirely:
there is no external ImageMagick dependency any more, and the result is a real, scrubbable, playable view - not just a fixed-frame-rate GIF -
though a GIF can still be exported from within that view (the {bf:Export GIF} button; written via a save dialog, or a browser download,
depending on the viewer).

{pstd}
{bf:Panel mode} takes 2 or more already-built networks in sequence, all with the same number of nodes in the same node order (the standard
"waves of the same actors" convention this package's other panel-data commands already assume, e.g. {help nwsaom}'s own {opt wave1()}/{opt wave2()}).
By default, each wave gets its own {bf:kk} (Kamada-Kawai) layout, warm-started from the PREVIOUS wave's own final node positions, so
consecutive waves relax into nearby layouts - a real, visible transition as ties change - rather than each wave's layout being computed
completely independently. Node identity stays visually trackable across the movie (nodes move smoothly, not in unrelated jumps), while
still letting the layout itself resettle as the network's structure changes wave to wave. Specify {opt fixedlayout} to restore the
original behavior instead: one node layout, computed once on the first network only and reused unchanged for every wave - the layout
itself never moves, at the cost of never reflecting how the network's own structure is changing. An explicit {opt layout()} other than
{bf:kk} also falls back to this one-shared-layout behavior (see {opt layout()} above), since the per-wave transition relies on {bf:kk}'s
own warm-start.

{pstd}
{bf:Event mode} takes exactly one network declared via {help nwset}'s {opt eventtime()} option - a stream of timestamped
(sender, receiver, time) events, not persistent ties (see {help nwset##temporal:nwset}'s own account of the distinction, and
{help nwrem}, which consumes the identical input). Node positions are static (one layout, computed once over the union of every
sender/receiver pair that ever occurs); the movie is a scrubbable timeline over real event time, replaying ties as they occur. With
{opt window()}, a tie fades and disappears if no new event on that same pair occurs within the window; without it, ties accumulate
and never disappear (useful for showing how a network was built up over time).

{pstd}
Both modes reuse {help nwplot}'s own color/shape/position resolution - {opt color()}/{opt symbol()}/{opt size()}/{opt edgecolor()}/{opt edgesize()}/
{opt label()} here work exactly like their {help nwplot} counterparts, applied identically across every panel network (or once, to the
event-mode cumulative layout network).

{pstd}
{bf:Panel mode} can also vary node/edge styling BY wave, the way the old ImageMagick-era {opt colors()}/{opt sizes()}/etc. plural options
did: {opt colors()}/{opt symbols()}/{opt sizes()}/{opt edgecolors()}/{opt edgesizes()} each take one value PER WAVE (in the same order as
the network list) instead of their singular counterparts' single broadcast value. Color and size (node AND edge) genuinely transition
continuously as the movie plays - Cytoscape.js tweens node color/size natively as part of the same {opt duration()}/{opt easing()}
animation that already moves node position, and edges (which are always fully rebuilt every transition, not kept alive across it - see
the crash history noted in {bf:nwmovie_template.html}'s own source) get an equivalent hand-rolled tween for any edge that persists across
the transition. Shape stays a hard switch at each wave boundary, not a continuous morph - asking Cytoscape's own animation to interpolate
shape (circle into square, say) is not a meaningful blend, and turned out to be a genuine renderer-crash trigger during this feature's own
development besides. A brand-new tie that did not exist in the previous wave pops in at its final style directly, with no fade-in - only
persisting ties (present in both waves) tween their own width/color change.

{pstd}
The toolbar's speed slider (0.1x-5x) scales playback speed for both modes - a single wave-to-wave {opt duration()} or the whole event-time
range {opt speed()} would otherwise take, divided by the live slider value, re-read on every transition/frame so changing it mid-playback
takes effect immediately - and also scales {bf:Export GIF}'s own frame timing to match. The Loop checkbox restarts playback from the
beginning once it reaches the end instead of stopping there (panel mode: back to wave 1; event mode: back to {it:eventtime()}'s own
minimum), for both live playback and {bf:Export GIF}.

{pstd}
The current wave's title/counter (or, in event mode, the active-tie count/time readout) is ALSO shown as its own small box drawn directly
on the canvas, not just in the toolbar - draggable by its own handle and resizable via its own bottom-right resize handle, the same way
{help nwplot}'s own {opt interactive} view lets you reposition/resize its legend. Unlike the toolbar text, this on-canvas box gets baked
into {bf:Export GIF}'s own output, at its own current on-screen position and size, so an exported movie still shows what wave/time each
frame is at once it's outside the interactive viewer. Its own "{bf:x}" button removes it for the rest of that viewing session (and stops
it being baked into any GIF exported after that); there is no way to bring it back short of reopening the movie. Its own font size only
ever changes from manually resizing its box - it never changes on its own between waves, regardless of how long each wave's own title
text happens to be.

{pstd}
Dropped entirely, with no replacement (the ImageMagick pipeline's own options, no longer meaningful once the browser does the
rendering and animation): {opt frames()}, {opt delay()}, {opt explosion()}, {opt imagick()}, {opt keepfiles()}, {opt width()}, {opt height()},
{opt z()}, {opt nodexys()}, {opt switchnetwork()}/{opt switchcolor()}/{opt switchsymbol()}/{opt switchedgecolor()}/{opt switchtitle()}, and
{opt eps} (vector export - {help nwplot}'s own {opt interactive} view made the identical PNG-only tradeoff already, for the same reason:
Cytoscape.js's built-in export is raster-only).

{title:Examples}

{pstd}
{bf:Panel mode}, using the three-wave {help netexample##glasgow:Glasgow} friendship data ({it:glasgow1}/{it:glasgow2}/{it:glasgow3},
one wave per school year) already used elsewhere in this package:{p_end}

	{cmd:. nwwebuse glasgow, nwclear}
	{cmd:. nwmovie glasgow1 glasgow2 glasgow3, duration(600) color(sport1)}

{pstd}
Same data, but coloring each wave by ITS OWN {it:sport} value (one variable per wave, via {opt colors()} instead of {opt color()}) -
node color genuinely tweens as a pupil's own reported sporting activity changes wave to wave:{p_end}

	{cmd:. nwwebuse glasgow, nwclear}
	{cmd:. nwmovie glasgow1 glasgow2 glasgow3, duration(600) colors(sport1 sport2 sport3)}

{pstd}
Same data again, with a custom display title per wave (default, without {opt titles()}, would just be each bare network name -
{it:glasgow1}, {it:glasgow2}, {it:glasgow3}):{p_end}

	{cmd:. nwwebuse glasgow, nwclear}
	{cmd:. nwmovie glasgow1 glasgow2 glasgow3, duration(600) titles("Year 1 (1995)" "Year 2 (1996)" "Year 3 (1997)")}

{pstd}
{bf:Event mode}, on the same small inline event log {help nwrem}'s own example uses:{p_end}

	{cmd:. clear}
	{cmd:. input sender receiver t}
	{cmd:. 1 2 1}
	{cmd:. 1 3 2}
	{cmd:. 2 1 3}
	{cmd:. 1 2 4}
	{cmd:. 3 2 5}
	{cmd:. 2 3 6}
	{cmd:. 1 3 7}
	{cmd:. 3 1 8}
	{cmd:. 2 1 9}
	{cmd:. 1 3 10}
	{cmd:. end}
	{cmd:. nwset sender receiver, eventtime(t) name(chatlog)}
	{cmd:. nwmovie chatlog, window(5) speed(2)}


{title:Supported network types}

{pstd}
Panel mode: binary yes, directed yes, weighted see {help nwplot}, signed not checked, two-mode not checked (animates whichever networks
are given exactly as {help nwplot} would render each one). Event mode: exactly the input {help nwrem} already accepts - a one-mode,
event-type temporal network built via {help nwset}'s {opt eventtime()} option; two-mode is not currently combinable with {opt eventtime()}
at the {help nwset} level (a separate, already-tracked composability gap).

{title:See also}

	{help nwplot}
	{help nwrem}
	{help nwset}
