{smcl}
{* *! version 2.0.0  2april2014}{...}
{marker topic}
{helpb nw_topical##visualization:[NW-2.8] Visualization}

{title:Title}

{p2colset 9 15 22 2}{...}
{p2col :nwplot {hline 2}}Plot a network{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwplot}
[{it:{help netname}}] 
[{it:{help if}}]
[{cmd:,} {it:{help nwplot##node_options:node_options}}
{it:{help nwplot##label_options:label_options}}
{it:{help nwplot##edge_options:edge_options}}
{it:{help nwplot##arrow_options:arrow_options}}
{it:{help nwplot##layout_options:layout_options}}
{it:{help nwplot##other_options:other_options}}
{it:{help nwplot##export_options:export_options}}
{it:{help twoway_options}}]
	
{synoptset 20}{...}
{p2col:{it:options}}Description{p_end}
{p2line}
{p2col:{it:{help nwplot##node_options:node_options}}}change look of
       nodes (color, size, symbol, etc.){p_end}
{p2col:{it:{help nwplot##label_options:label_options}}}display and change look of
       node labels{p_end}
{p2col:{it:{help nwplot##edge_options:edge_options}}}change look of 
       edges (color, size, pattern, etc.){p_end}
{p2col:{it:{help nwplot##arrow_options:arrow_options}}}change look of
       arrows{p_end}
{p2col:{it:{help nwplot##layout_options:layout_options}}}change the layout,
	use existing coordinates, export coordinates{p_end}
{p2col:{it:{help nwplot##other_options:other_options}}}other network plot options
		{p_end}
{p2col:{it:{help nwplot##export_options:export_options}}}export the plot directly
	to a vector (SVG/PDF/EPS) or raster (PNG/TIF/...) file{p_end}
{p2col:{it:{help twoway_options}}}normal twoway options for the whole plot
		{p_end}
	

{synoptset 35 tabbed}{...}
{p2col:{it:node_options}}Description{p_end}
{marker node_options}{...}
{p2line}
{synopt:{opt size}({it:{help varname}} [,{it:{help nwplot##node_sub:node_sub}}])}size of the nodes{p_end}
{p2col:{opt color}({it:{help varname}} [,{it:{help nwplot##node_sub:node_sub}}])}color of the nodes{p_end}
{p2col:{opt symbol}({it:{help varname}} [,{it:{help nwplot##node_sub:node_sub}}])}symbol of the nodes{p_end}
{p2col:{opth nodefactor(float)}}multiply all node sizes by a factor{p_end}


{synoptset 35 tabbed}{...}
{p2col:{it:node_sub}}Description{p_end}
{marker node_sub}{...}
{p2line}
{p2col:{opt norescale}}no automatic rescale{p_end}
{p2col:{opt legendoff}}no legend for this attribute{p_end}
{p2col:{opt forcekeys}({it:{help int}}...)}list of keys to be used in the legend{p_end}
{p2col:{opt colorpalette}({it:{help colorstyle}}...)}list with colorstyles; change colorpalette{p_end}
{p2col:{opt symbolpalette}({it:{help symbolstyle}}...)}list with symbolstyles; change symbolpalette{p_end}
{p2col:{opth foreground(int...)}}values to be plotted in the foreground{p_end}
{p2col:{opth sizebin(int)}}finetune size of nodes{p_end}
{p2col:{opth mlcolor(colorstyle)}}lcolor of nodes{p_end}
{p2col:{opth mlwidth(linewidthstyle)}}lwidth of nodes{p_end}
{p2col:{opth nodeclash(real)}}separate overlaped node in mdsclassical{p_end}

{synoptset 35 tabbed}{...}
{p2col:{it:label_options}}Description{p_end}
{marker label_options}{...}
{p2line}
{p2col:{opt lab}}display node labels saved with network{p_end}
{p2col:{opth label(varname)}}display node labels from variable{p_end}
{synopt:{opt labelopt}({it:{help scatter##marker_label_options:marker_label_options}})}options for look of node labels (e.g. size, color){p_end}


{synoptset 35 tabbed}{...}
{p2col:{it:edge_options}}Description{p_end}
{marker edge_options}{...}
{p2line}
{p2col:{opt edgesize}({it:{help netname}} [,{it:{help nwplot##edge_sub:edge_sub}}])}use edge values of other network to change width of edges; network needs to have the right dimensions{p_end}
{p2col:{opt edgecolor}({it:{help netname}} [,{it:{help nwplot##edge_sub:edge_sub}}])}use edge values of other network to change color of edges; network needs to have the right dimensions{p_end}
{p2col:{opth edgefactor(float)}}multiply all edge sizes by a factor{p_end}
{p2col:{opth edgeforeground(int...)}}top-level counterpart to the {opt foreground()} sub-option of {opt edgecolor()}/{opt edgesize()} - values to be plotted in the foreground{p_end}


{synoptset 35 tabbed}{...}
{p2col:{it:edgesub_sub}}Description{p_end}
{marker edge_sub}{...}
{p2line}
{p2col:{opt legendoff}}no legend for this attribute{p_end}
{p2col:{opt forcekeys}({it:{help int}}...)}list of keys to be used in the legend{p_end}
{p2col:{opt edgecolorpalette}({it:{help colorstyle}}...)}list with colorstyles; change edgecolorpalette{p_end}
{p2col:{opt edgepatternpalette}({it:{help linepatternstyle:pattern}}...)}list with linestyles; the same network as in edgecolor is used to display different line patterns{p_end}
{p2col:{opth foreground(int...)}}values to be plotted in the foreground{p_end}
	
{synoptset 35 tabbed}{...}
{p2col:{it:arrow_options}}Description{p_end}
{marker arrow_options}{...}
{p2line}
{p2col:{opt arcstyle}({it:{help nwplot##arcstyle:arcstyle}})}change the look of arcs (curved, straight){p_end}
{p2col:{opth arcbend(float)}}control the degree of bend for curved arcs; default = 2{p_end}
{p2col:{opth arcsplines(int)}}resolution for curved arcs{p_end}
{p2col:{opt arrows}}force arrowheads on an otherwise-undirected network{p_end}
{p2col:{opth arrowfactor(float)}}multiply arrowhead by a factor{p_end}
{p2col:{opth arrowgap(float)}}control gap between arrowhead and node{p_end}
{p2col:{opth arrowbarbfactor(float)}}control look of arrow{p_end}


{synoptset 35 tabbed}{...}
{marker arcstyle}{...}
{p2col:{it:arcstyle}}{p_end}
{p2line}
{p2col:{cmd: automatic}}plots arcs as curved lines, but only when they are reciprocated; default
		{p_end}
{p2col:{cmd: curved}}plots all arcs as curved lines
		{p_end}
{p2col:{cmd: straight}}plots all arcs as straight lines
		{p_end}

		
{synoptset 35 tabbed}{...}
{p2col:{it:layout_options}}Description{p_end}
{marker layout_options}{...}
{p2line}
{p2col:{cmd: layout}([{it:{help nwplot##layoutstyle:layoutstyle}}] [,{it:{help nwplot##layout_sub:layout_sub}}])}change the overall layout/arrangement of nodes{p_end}
{p2col:{opt nodexy}({it:{help varname:xvar} {help varname:yvar}})}use variables to force coordinates of nodes{p_end}
{p2col:{opt generate}({it:{help newvarname:newxvar} {help newvarname:newyvar}})}export coordinates of nodes{p_end}
{p2col:{opt interactive}}open the plot in an interactive browser view (drag nodes, edit the color/shape
	legend, adjust size/width factors) alongside the usual static plot; requires {opt generate()}
	to also capture the resulting coordinates{p_end}
{p2col:{opt importcoords}({it:filename})}merge node position/color/shape edits saved from an
	{opt interactive} view back in before plotting; requires {opt nodexy()}{p_end}
{p2col:{opt edgeimport}({it:filename})}merge edge color/pattern edits saved from an {opt interactive}
	view back in before plotting; optional companion to {opt importcoords()}{p_end}
{p2col:{opt movieexport}({it:filename})}with {opt interactive}: also write the resolved node/edge
	color/shape/position data as plain JSON to {it:filename}, with no HTML page or viewer window -
	{help nwmovie} uses this internally, once per network in its own sequence, rather than
	re-deriving concrete colors from scratch{p_end}
{p2col:{opt noopen}}with {opt interactive}: build the interactive view but do not open a viewer
	window for it (used together with {opt movieexport()} - {help nwmovie} does not want a viewer
	window popping open for every network in its own sequence){p_end}


{synoptset 35 tabbed}{...}
{p2col:{it:layout_sub}}Description{p_end}
{marker layout_sub}{...}
{p2line}
{p2col:{opt lgc}}only plot largest component{p_end}
{p2col:{opth components(int)}}control the number of components rendered{p_end}
{p2col:{opt ignorelgc}}used internally by {help nwmovie}{p_end}
{p2col:{opth iterations(int)}}only relevant for layout = mds/frucht/kk; maximum number of iterations in the underlying iterative procedure, default = 1000{p_end}
{p2col:{opth columns(int)}}only relevant for layout = grid; number of columns to be plotted in grid layout {p_end}
{p2col:{opt norescale}}only relevant for layout = nodexy; do not rescale coordinates{p_end}
{p2col:{opt vertical}}only relevant for layout = bipartite; arrange the two modes as two columns instead of the default two rows{p_end}


{synoptset 35 tabbed}{...}
{marker layoutstyle}{...}
{p2col:{it:layoutstyle}}{p_end}
{p2line}
{p2col:{cmd: mds}}modern multidimensional scaling{p_end}
{p2col:{cmd: mdsclassical}}classical multidimensional scaling{p_end}
{p2col:{cmd: frucht}}Fruchterman-Reingold force-directed layout
		{p_end}
{p2col:{cmd: kk}}Kamada-Kawai layout (stress majorization using graph-theoretic shortest-path distances as ideal spring lengths - unlike {cmd:frucht}, pairs of nodes far apart in the network end up proportionally far apart in the plot, not just directly-tied pairs pulled together); the default layout. Its own cost grows with both node count and {opt iterations()} - confirmed directly: 1.1 seconds at 50 nodes, 72 seconds at 500 nodes at a plain 1000-iteration count - so whenever {opt iterations()} is left at its own default, the actual iteration count used is scaled down as node count grows (full 1000 iterations up to a few hundred nodes, tapering toward a 10-iteration floor on very large networks) to keep a default {cmd:nwplot} call around 8-10 seconds regardless of network size. Give an explicit {opt iterations()} to override this scaling{p_end}
{p2col:{cmd: hierarchy}}Sugiyama-style layered/hierarchical layout - assigns nodes to top-down layers by longest path from sources and orders each layer to reduce edge crossings; meant for directed, roughly acyclic networks (org charts, dependency/citation graphs, event sequences). An undirected network, or one with cycles, still plots (no error, no crash) but degrades to a less meaningful ordering, since there is no edge direction to layer by{p_end}
{p2col:{cmd: bipartite}}dedicated two-mode layout - the two modes placed in two parallel rows (or two columns with the {opt vertical} sub-option), ordered to reduce crossings between them; requires a two-mode network (see {help nwset##twomode:nwset}'s {opt bipartite}/{opt twomode}){p_end}
{p2col:{cmd: circle}}circle layout
		{p_end}
{p2col:{cmd: grid}}grid layout
		{p_end}
{p2col:{cmd: nodexy}}use coordinates given in {opt nodexy()}; only needed to send options.
		{p_end}
{p2col:{cmd: _layoutfunction}}advanced user-written layout function (see {help nwplot##layoutfunction:here}).
		{p_end}


{synoptset 35 tabbed}{...}
{p2col:{it:other_options}}Description{p_end}
{marker other_options}{...}
{p2line}
{p2col:{opth aspectratio(float)}}height/width ratio{p_end}
{p2col:{opt lineopt}({it:{help line:options}})}send options directly to all line plots used to display arcs{p_end}
{p2col:{opt scatteropt}({it:{help scatter:options}})}send options directly to all scatter plots used to display nodes {p_end}
{p2col:{opt legendopt}({it:{help legend_options:options}})}send options directly to the legend{p_end}


{synoptset 35 tabbed}{...}
{p2col:{it:export_options}}Description{p_end}
{marker export_options}{...}
{p2line}
{p2col:{opt export}({it:filename})}export the plot directly to {it:filename}; the format
	(SVG/PDF/EPS/PNG/TIF/...) is inferred from the file extension, exactly as it would be by a
	manual {help graph export} call afterward{p_end}
{p2col:{opt replace}}overwrite {it:filename} if it already exists{p_end}
{p2col:{opt exportopt}({it:{help graph export:export_options}})}pass additional options
	straight through to the underlying {help graph export} call (e.g. {cmd:width()}/{cmd:height()}
	for raster-format resolution){p_end}


{title:Description}

{pstd}
This command plots a network. It gives a lot of flexibility to control all elements in a network plot. Furthermore, it 
is compatible with {bf:schemes()} and accepts all {help twoway_options}.

{pstd}
This example generates a random network and plots it. Because no {help netname} is given, the command refers to the
{help nwcurrent:current network}.

	{cmd:. nwclear}
	{cmd:. nwrandom 20, prob(.2)}
	{cmd:. nwplot}

{pstd}
One can change the layout where nodes should be plotted:
	
	{cmd:. nwplot, layout(mds)}
	{cmd:. nwplot, layout(circle)}
	{cmd:. nwplot, layout(grid)}
	{cmd:. nwplot, layout(grid, columns(20))}
	{cmd:. nwplot, layout(kk)}
	{cmd:. nwplot, layout(hierarchy)}
	{cmd:. nwplot, layout(bipartite)}
	{cmd:. nwplot, layout(bipartite, vertical)}

{pstd}
Or obtain coordinates from layout and plot with coordinates. The option {bf:nodexy} can be used to write your
own network layout functions, return coordinates and plot a network with these coordinates. Because
{opt generate()} and {opt nodexy()} are a matched pair - one exports the node coordinates a layout produced,
the other forces a later plot to reuse them - this is also how to plot several different networks (e.g. the same
set of people observed at several waves) at identical node positions, so the reader can compare panels directly
instead of re-deriving a fresh, unrelated layout for each one:

	{cmd:. nwplot, gen(xcoord ycoord)}
	{cmd:. replace xcoord = .2 if _n < 5}
	{cmd:. nwplot, nodexy(xcoord ycoord)}

	{cmd:. * fixed coordinates across two waves of the same network}
	{cmd:. nwplot wave1, generate(x1 y1)}
	{cmd:. nwplot wave2, nodexy(x1 y1)}

{pstd}
{opt interactive} opens the plot in a browser alongside the usual static plot: drag nodes to
reposition them, edit the color/shape legend (an edit applies to every node sharing that color/
shape key, not just one node - the same discrete legend model {cmd:color()}/{cmd:symbol()}
already use), edit the edge color/pattern legend the same way, and adjust node-size/edge-width
factors with two sliders. Two buttons in the browser save the edits as CSV files; feed them back
with {opt importcoords()} (paired with {opt nodexy()}, same matched-pair idea as {opt generate()}/
{opt nodexy()} above) and {opt edgeimport()}:

	{cmd:. nwplot flomarriage, generate(x y) color(wealth) interactive}
	{cmd:. * drag nodes / edit the legend in the browser, then save both CSVs, then:}
	{cmd:. nwplot flomarriage, nodexy(x y) importcoords("nodes.csv") edgeimport("edges.csv") color(wealth)}

{pstd}
{opt importcoords()}/{opt edgeimport()} must be run against the same network, same size, as the
{opt interactive} view they came from (row order is how nwplot matches an edit back to a node/tie,
the same way {opt nodexy()}/{opt label()} already do) - re-export from {opt interactive} rather
than reusing an old CSV after the network or an {help if}/{help in} restriction changes. Node size
is not yet individually editable in the interactive view; the size-factor slider maps onto
{opt nodefactor()} instead.

{pstd}
Arrow heads are plotted when a network is directed. Furthermore, the command notices if a dyad is mutually or
asymmetrically connected (see {help nwdyads}). By default, asymmetrically connected dyads are represented as a straight line, whereas
mutually connecetd dyads are represented as two curved lines. However, one can overwrite this and show all ties as 
curved lines.

	{cmd:. nwplot, arcstyle(automatic)}
	{cmd:. nwplot, arcstyle(straight)}
	{cmd:. nwplot, arcstyle(curved)}
	{cmd:. nwplot, arcbend(0.3) arcsplines(20)} 

{pstd}
Almost all elements in a network plot can be easily made bigger or smaller using factors:

	{cmd:. nwplot, nodefactor(2)}
	{cmd:. nwplot, edgefactor(2)} 
	{cmd:. nwplot, arrowfactor(4)}
	{cmd:. nwplot, arrowbarbfactor(.2)}
{phang2}	
	{cmd:. nwplot, nodefactor(2) edgefactor(4) arrowfactor(2) arrowbarbfactor(.2)}{p_end}

{pstd}
Colors, symbols and size of nodes can be changed accoring to a {help varname}. Furthermore, the palettes used for display
can be changed as well. 

	{cmd:. nwwebuse glasgow, nwclear}
	{cmd:. nwplot glasgow1, color(smoke1)}
	{cmd:. nwplot, color(smoke1, colorpalette(red yellow cyan))}
 
	{cmd:. nwplot glasgow1, symbol(sport1)}
	{cmd:. nwplot glasgow1, symbol(sport1, symbolpalette(T S))}

	{cmd:. nwplot glasgow1, size(alcohol1)}
	{cmd:. nwplot, size(alcohol1, forcekeys1(1 5 10 20))}
 
	{cmd:. nwplot glasgow1, size(alcohol1) color(smoke1) symbol(sport1)}

{pstd}
nwcommands ships three schemes purpose-built for network plots - s1network,
s2network, and s3network - each giving node fill and edge line colors that
are visually distinct by default (an ordinary Stata scheme such as the
default {bf:stcolor} typically does not, since a single data series'
marker and connecting line usually should match - reasonable for an
ordinary statistical graph, not for a network plot). {cmd:nwplot} defaults
to {bf:s1network} unless {opt scheme()} is specified explicitly.

	{cmd:. nwplot, scheme(s1network)}
	{cmd:. nwplot, scheme(s2network)}
	{cmd:. nwplot, scheme(s2mono)}
{phang2}
	{cmd:. nwplot, size(alcohol3) color(smoke3) symbol(sport3) scheme(s1network)}{p_end}
{phang2}	
	{cmd:. nwplot, size(alcohol3) color(smoke3) symbol(sport3) scheme(economist)}{p_end}
	{cmd:. set scheme s2network}

{pstd}
This example calculates the shortest path between two nodes (medici and peruzzi) and uses this path
to color the edges of the original network and change the size of the edges on this path. 

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwpath flomarriage, ego(medici) alter(peruzzi) generate(sp)}
{phang2}	
	{cmd:. nwplot flomarriage, edgecolor(sp_1, legendoff) edgesize(sp_1, legendoff) edgefactor(5)}
	
{pstd}
Another example that changes the size and color of edges.

	{cmd:. nwwebuse gang, nwclear}
	{cmd:. nwplot}
	{cmd:. nwplot gang, edgesize(gang)} 
	{cmd:. nwgenerate blood = (gang==4)}
	{cmd:. nwplot blood}
	{cmd:. nwplot gang, edgesize(gang) edgecolor(blood)}

{pstd}
This is how to control the legend of the plot. All options that can be used for twoway legends are valid.{p_end}
	{phang2}
	{cmd:. nwplot gang, size(Arrests, forcekeys(5 10 20)) legendopt(on pos(3) cols(1))}

{pstd}
Because nwplot uses twoway plots one can  use all general twoway options to e.g. control the title of a plot.

{phang2}
{cmd:. nwwebuse florentine, nwclear}{p_end}
{phang2}
{cmd:. nwplot flomarriage, edgecolor(flobusiness) title("Florentine Marriages", color(red) size(huge))}
{p_end}

{pstd}
Here, the nodes are plotted with the node labels saved with the network:
	
	{cmd:. nwplot flobusiness, lab}
	
{pstd}
More generally, one can use any {it:varname} as node labels. The next example, does the same as the previous command, 
but shows how one could use node labels stored elsewhere:

	{cmd:. nwplot flobusiness, label(wealth)}

{pstd}
The look and feel of node labels is changed with labelopt():

	{cmd:. nwplot flobusiness, label(wealth) labelopt(mlabsize(huge) mlabcolor(red))}
	
{pstd}
The command draws on normal scatter plots to plot nodes. Once can send all sorts of options directly to these
underlying scatter plots. Here, the color and symbol of nodes is overwritten.

	{cmd:. nwplot flomarriage, scatteropt(mfcolor(green) msymbol(D))}
	{cmd:. nwplot flomarriage, lineopt(lwidth(10) lcolor(green))}
	

{pstd}
The next example shows how to only plot the largest component of the network.	

	{cmd:. nwwebuse glasgow, nwclear}
	{cmd:. nwcomponents glasgow1, lgc generate(large)}
	{cmd:. nwplot glasgow1 if large == 1}
	
{pstd}
Alternative to display the largest component only:

	{cmd:. nwwebuse glasgow, nwclear}
	{cmd:. nwplot glasgow1, layout(,lgc)}

{pstd}
{bf:Publication-quality vector export.} {opt export()} saves the plot directly to a file, inferring the
format from the extension - exactly what a manual {help graph export} call afterward would do, since
{cmd:nwplot} produces an ordinary Stata graph and never replaces or bypasses it. SVG and PDF are both
scalable vector formats: the plot stays crisp at any zoom level or print size, and both open cleanly in
standard vector-graphics editors (e.g. Adobe Illustrator, Inkscape) for further touch-up - node/edge/label
elements remain separate, editable objects rather than a fixed-resolution image.

	{cmd:. nwplot flomarriage, export("flomarriage.svg")}
	{cmd:. nwplot flomarriage, export("flomarriage.pdf") replace}

{pstd}
Raster formats (PNG, TIF, ...) are also supported the same way; {opt exportopt()} passes options straight
through to the underlying {help graph export} call, most commonly {cmd:width()}/{cmd:height()} to control
resolution:

	{cmd:. nwplot flomarriage, export("flomarriage.png") exportopt(width(2000))}

{pstd}
The graph itself is unaffected by {opt export()} - it remains the normal, currently active Stata graph
afterward, so the Graph Editor, {stata graph save}, and a second {help graph export} in a different format
all continue to work exactly as they would without {opt export()}.

{title:Stored results}

{pstd}
{cmd:nwplot} is {cmd:rclass}.

	Macros:
	  {bf:r(export)}	filename actually passed to {opt export()}, if specified

{title:Supported network types}

{pstd}
Binary: yes. Weighted: yes (via {opt edgesize()}/{opt edgecolor()} - see the shortest-path example above).
Directed: yes - this is the command's native case; arrows are drawn automatically, and reciprocated (mutual)
dyads are curved apart from their asymmetric counterparts by default ({opt arcstyle(automatic)}) so both
directions of a tie remain visible rather than overlapping. Undirected: yes, the default. Two-mode: the
command plots a two-mode network's nodes and ties correctly (it has no bipartite-specific logic, but a
bipartite network's ties are simply a subset of the same one-mode adjacency structure every other network
uses) - the two modes are not visually distinguished automatically, though; pass the network's own
{cmd:get_modes()}-derived mode variable to {opt color()} or {opt symbol()} to tell them apart at a glance
(e.g. {cmd:nw2degree}'s own output, or any variable holding "1"/"2" per node). Self-loops: not rendered -
a self-loop currently has no visible effect on the plot (a zero-length tie), a known limitation recorded
in the package's own visualization roadmap rather than fixed here.

{title:See also}
		{help nwplotmatrix}

