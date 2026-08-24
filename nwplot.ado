/***
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


{synoptset 35 tabbed}{...}
{p2col:{it:layout_sub}}Description{p_end}
{marker layout_sub}{...}
{p2line}
{p2col:{opt lgc}}only plot largest component{p_end}
{p2col:{opth iterations(int)}}only relevant for layout = mds; maximum number of iterations in the multidimensional scaling procedure, default = 1000{p_end}
{p2col:{opth columns(int)}}only relevant for layout = grid; number of columns to be plotted in grid layout {p_end}
{p2col:{opt norescale}}only relevant for layout = nodexy; do not rescale coordinates{p_end}


{synoptset 35 tabbed}{...}
{marker layoutstyle}{...}
{p2col:{it:layoutstyle}}{p_end}
{p2line}
{p2col:{cmd: mds}}modern multidimensional scaling; default when nodes < 50{p_end}
{p2col:{cmd: mdsclassical}}classical multidimensional scaling; default when nodes > 50{p_end}
{p2col:{cmd: frucht}}Fruchterman-Reingold force-directed layout
		{p_end}
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

***/
capture program drop nwplot
program nwplot, rclass
	version 9.0
	unw_defs
	
	set more off
	local 0_original = `"`0'"'
	local layout = ""
	syntax [anything(name=netname)][if/] [in/], [ ignorelgc lab  labelopt(string) _layoutfunction(string) arrows edgesize(string) ASPECTratio(string) components(string) arcstyle(string) arcbend(string) arcsplines(integer 10) nodexy(varlist numeric min=2 max=2) edgeforeground(string) GENerate(string) colorpalette(string) edgecolorpalette(string) edgepatternpalette(string) symbolpalette(string) lineopt(string) scatteropt(string) legendopt(string) size(string) color(string) symbol(string) edgecolor(string) label(varname) nodefactor(string) sizebin(string) edgefactor(string) arrowfactor(string) arrowgap(string) arrowbarbfactor(string) layout(string) iterations(integer 1000) scheme(string) EXPORT(string) replace EXPORTOPT(string) * ]
	local twowayopt `"`options'"'

	nw_datasync `netname'
	
	// filter out lgc and nodeclash
	local 0 "`layout'"
	syntax [anything(name=something)], [ lgc nodeclash(string) *]
	local nodeproximity : word 2 of `nodeclash'
	capture confirm number `nodeproximity'
	if _rc != 0 {
		local nodeproximity = 0.01
	}
	local nodeclashchange : word 1 of `nodeclash'
	capture confirm number `nodeclashchange'
	if _rc != 0 {
		local nodeclashchange= 1
	}

	tempvar lgc_var

	if "`ignorelgc'" != "" {
		local lgc = ""
	}
	local ignorelgc = ""
	
	if "`lgc'" != "" {
		// was "nwgen `lgc_var' = lgc(`netname')" - same broken-shortcut
		// bug as the mdsclassical block's own "components(")/"lgc("
		// calls further down this file (see that fix's own comment for
		// the full explanation); this is a second, independent call
		// site hitting the identical issue, fixed the same way.
		qui nwcomponents `netname', lgc generate(`lgc_var')
		local if_lgc = " `lgc_var' == 1"
	}
	
	local 0 = `"`0_original'"'
	syntax [anything(name=netname)][if/] [in/], [ lab  labelopt(string) _layoutfunction(string) arrows edgesize(string) ASPECTratio(string) components(string) arcstyle(string) arcbend(string) arcsplines(integer 10) nodexy(varlist numeric min=2 max=2) edgeforeground(string) GENerate(string) colorpalette(string) edgecolorpalette(string) edgepatternpalette(string) symbolpalette(string) lineopt(string) scatteropt(string) legendopt(string) size(string) color(string) symbol(string) edgecolor(string) label(varname) nodefactor(string) sizebin(string) edgefactor(string) arrowfactor(string) arrowgap(string) arrowbarbfactor(string) layout(string) iterations(integer 100) scheme(string) EXPORT(string) replace EXPORTOPT(string) * ]

	// Default node fill color and edge line color are both resolved as
	// "scheme p<n>" / "scheme p<n>line" further down (_getcolorstyle) -
	// left at "" here, `scheme' previously fell through to whatever
	// graph scheme happened to be ambient (c(scheme), Stata's own
	// ordinary default being "stcolor"). Confirmed directly (rendered a
	// tiny two-point scatter+line graph with mfcolor("scheme p1") and
	// lcolor("scheme p1line") under stcolor and inspected the actual
	// pixels) that stcolor defines p1 and p1line as the identical blue -
	// reasonable for an ordinary statistical graph (a single series'
	// marker and connecting line usually SHOULD match), but wrong for a
	// network plot, where nodes and edges need to read as visually
	// distinct by default. Default to one of the package's own
	// network-oriented schemes instead, which deliberately give p1/
	// p1line different colors (see scheme-s1network.scheme) - already
	// packaged in _pkg_ado.txt, just never actually used unless a caller
	// remembered to pass scheme() explicitly.
	if "`scheme'" == "" {
		local scheme "s1network"
	}

	nw_syntax `netname', max(1)
	qui nwsummarize `netname'
	if `r(density)' == 0 {
		di "{txt}Network empty. Plotting does not make sense.{txt}"
		exit
	}
	
	local masternetname "`netname'"
	
	if "`if_lgc'" != "" {
		local if = "`if_lgc'"
	}
	
	gettoken edgecolor_original edgecolor_options : edgecolor, parse(",")
	gettoken edgesize_original edgesize_options : edgesize, parse(",")
	local edgecolor `edgecolor_original'
	local edgesize `edgesize_original'
	
	if "`labelopt'" != "" {
		local scatteropt "`scatteropt' `labelopt'"
	}

    if "`in'" != "" {
		capture nwdrop _temp_in
		nwduplicate `netname', name(__temp_in)
		nwkeep __temp_in in `in'
		if "`edgecolor'" != "" {
			capture nwdrop __temp_edgecolor_in
			nwgen __temp_edgecolor_in = `edgecolor'
			local edgecolor "__temp_edgecolor_in"
			if "`edgecolor'" != "`netname'" {
				nwkeep __temp_edgecolor_in in `in'
			}
		}
		if "`edgesize'" != "" {
			nwgen __temp_edgesize_in = `edgesize'
			local edgesize "__temp_edgesize_in"
			if "`edgesize'" != "`netname'" & "`edgesize'" != "`edgecolor'"{
				nwkeep __temp_edgesize_in in `in'
			}
		}
		local netname "__temp_in"
		nw_syntax `netname', max(1)
	}

     if "`if'"!="" {
		local ifmaster "if `if'"
		capture nwdrop __temp_if
		nwduplicate `netname', name(__temp_if)
		nwdrop __temp_if if (!(`if'))
		if "`edgecolor'" != "" {
			capture nwdrop _temp_edgecolor_if
			nwduplicate `edgecolor', name(__temp_edgecolor_if)
			local edgecolor "__temp_edgecolor_if"
			nwdrop __temp_edgecolor_if if (!(`if'))
		}
		if "`edgesize'" != "" {
			capture nwdrop _temp_edgesize_if
			nwduplicate `edgesize', name(__temp_edgesize_if)
			local edgesize "_temp_edgesize_if"
			nwdrop __temp_edgesize_if if (!(`if'))
		}
		
		local netname "__temp_if"
	}
	nw_syntax `netname', max(1)
	
	qui if "`lab'" != ""{
		local label "`nw_nodename'"
	}
	
	capture which labellist
	if _rc != 0 {
		ssc install labellist
	}

		
	if "`aspectratio'" == "" {
		local aspectratio = 1
	}
	local aspectratio = `aspectratio'*  0.67
	
	if "`sizebin'" == "" {
		local sizebin = 1
	}
	
	if "`arrowbarbfactor'" == "" {
		local arrowbarbfactor = 1
	}
	local arrowbarbfactor = `arrowbarbfactor' * 0.7
	
	if "`nodefactor'" == "" {
		local nodefactor = 1
	}
	local nodefactor = `nodefactor' / 50
	/*if `nodes' > 20 {
		local nodefactor = `nodefactor' / 1.5
	}*/
	
	if "`edgefactor'" == "" {
		local edgefactor = 1
	}
	if "`arrowfactor'" == "" {
		local arrowfactor = 1
	}
	
	if "`arrowgap'" == "" {
		local arrowgap = 0
	}
	local arrowgap = `arrowgap' + 0.5

	if "`arcstyle'" == "" {
		local arcstyle = "automatic"
	}
	_opts_oneof "automatic curved straight" "arcstyle" "`arcstyle'" 6556

	if "`arcbend'" == "" {
		local arcbend = 1
	}
	local arcbend = `arcbend' * 2
	
	nw_syntax `netname'
	
	local gridcols = ceil(sqrt(`nodes'))
	local 0 = "`layout'"
	syntax [anything][, nodeclash(string) lgc norescale iterations(integer 1000) columns(integer `gridcols') ]
	
	if("`anything'"=="") {
		if `nodes' < 50 {
			local anything "mds"
		}
		else {
			local anything "mdsclassical"
		}
	}
	
	local layout_norescale "`rescale'"
	local layout_gridcols = "`columns'"
	local layout_components = "`components'"
	local layout = "`anything'"
	_opts_oneof "mds mdsclassical frucht grid circle nodexy _layoutfunction" "layout" "`layout'" 6556


	// Check matsize (because mds requires STATA matrix)
	if (c(matsize) <`nodes'& "`layout'" == "mds") {
		if "`c(flavor)'" == "Small" {
			di "{err}STATA Small can only use {it:layout(mds)} with networks with max. {bf:100} nodes; {it:layout(circle)} selected instead."
			local layout = "circle"
		}
		else {
			if (c(SE) == 0 & c(MP) == 0 & `nodes' > 800){
				di "{err}STATA/IC can only use {it:layout(mds)} with networks with max. {bf:800} nodes; {it:layout(circle)} selected instead."
				local layout = "circle"
			}
			else{ 
				if (`nodes' > 11000) {
					di "{err}Unfortunately, STATA can only use {it:layout(mds)} with networks with max. {bf:1100} nodes; {it:layout(circle)} selected instead."
					local layout = "circle"
				}
				else {
					set matsize `nodes'
				}
			}
		}
	}
	
	local dolabel  = ("`label'" !="")

	if "`directed'" == "false" & "`arcstyle'" == "automatic" {
		local arcstyle = "straight"
	}

	if "`directed'" == "true" {
		local arrows = "arrows"
	}
	if "`arrows'" != "" {
		local pc "pcarrow"
		local doarrows = 1
	}
	else {
		local pc "pcspike"
		local doarrows = 0
	}
	if "`scheme'" != "" {
		local schemetwoway "scheme(`scheme')"
	}
	
	///////////////////
	//
	// NODE ATTRIBUTES
	//
	///////////////////

	preserve
	if "`ifmaster'" != "" {
		keep `ifmaster'
	}
	
	// Color of nodes
	local colorkeys ""
	local colororder ""
	local colorlabels ""
	
	if ("`color'" != ""){
		local 0 = "`color'"
		syntax [varlist(default=none max=1)] [, foreground(string) norescale forcekeys(string) legendoff colorpalette(string) mlcolor(string) mlwidth(string) *]
		
		local mlcolor_color = "`mlcolor'"
		local mlwidth_color = "`mlwidth'"
		local colorforeground = "`foreground'"
		
		if "`varlist'" == "" {
			tempvar dummy_col
			gen `dummy_col' = 1
			local varlist "`dummy_col'"
			local legendoff "legendoff"
		}
		tempvar color_numeric
		capture encode `varlist' , gen(`color_numeric')
		if _rc == 0 {
			local varlist "`color_numeric'"
		}
		
		local colorkeys = "`forcekeys'"
		local colorkeys_legendoff "`legendoff'"
		local fnum : word count `forcekeys'
				
		// Use forced keys
		local j = 1
		if "`forcekeys'" != "" {
			qui tab `varlist' if _n <= `nodes', matrow(colorkeysmap)
			foreach i in `forcekeys' {
				local colororder "`colororder' `j'"
				local ckey = colorkeysmap[`i', 1]
				_getvaluelabel `varlist', key(`ckey')
				local colorlabels `"`colorlabels' label(`j' "`r(key_label)'")"'
				local j = `j' + 1
			}
		}
			
		// Rescale colors
		if "`rescale'" == "" {	
			tempvar __color
			egen `__color' = group(`varlist')
			mata: ncolor = st_data((1,`nodes'),st_varindex("`__color'"))
			if "`forcekeys'" == "" {
				qui tab `varlist' if _n <= `nodes', matrow(colorkeysmap)
				forvalues i = 1/`r(r)' {
					local ckey = colorkeysmap[`i', 1]
					local colorkeys "`colorkeys' `i'"
					local colororder "`colororder' `i'"
					_getvaluelabel `varlist', key(`ckey')
					local key_label : label (`varlist') `i'
					local colorlabels `"`colorlabels' label(`i' "`r(key_label)'")"'
				}
			}
		}
		else {
			mata: ncolor = st_data((1,`nodes'),st_varindex("`varlist'"))
			if "`forcekeys'" == "" {
				qui tab `varlist' if _n <= `nodes', matrow(colorkeysmap)
				forvalues i = 1/`r(r)' {
				
				
					local ckey = colorkeysmap[`i', 1]
					local colorkeys "`colorkeys' `ckey'"
					local colororder "`colororder' `i'"
					_getvaluelabel `varlist', key(`ckey')
					local colorlabels `"`colorlabels' label(`i' "`r(key_label)'")"'
				}
			}
		}
	}
	else {
		mata: ncolor = J(`nodes',1,1)
		local colorkeys = ""
	}
	if "`colorkeys_legendoff'" == ""{			
		local keysused : word count `colorkeys'
	}
	else {
		local keysused = 0
		local colororder = ""
		local colorlabels = ""
	}
	
	
	// Symbol of nodes
	local symbolkeys ""
	local symbolorder ""
	local symbollabels ""
	if ("`symbol'" != ""){
		// Check for known schemes without symbol support
		if "`scheme'" == "" {
			local scheme = c(scheme)
		}
		
		if ((strpos("s1color s2color economist", "`scheme'") > 0) & "`symbolpalette'" == "") {
			local symbolpalette "circle diamond square triangle smcircle smdiamond smsquare smtriangle"
		}
		
		local 0 = "`symbol'"
		syntax [varlist(default=none max=1)] [, norescale forcekeys(string) legendoff symbolpalette(string) mlcolor(string) mlwidth(string) *]
		local mlcolor_symbol = "`mlcolor'"
		local mlwidth_symbol = "`mlwidth'"
		
		if "`varlist'" == "" {
			tempvar dummy_symb
			gen `dummy_symb' = 1
			local varlist "`dummy_symb'"
			local legendoff "legendoff"
		}
		tempvar symbol_numeric
		capture encode `varlist', gen(`symbol_numeric')
		if _rc == 0 {
			local varlist "`symbol_numeric'"
		}
		
		local symbolkeys = "`forcekeys'"
		local symbolkeys_legendoff "`legendoff'"
		local fnum : word count `forcekeys'
				
		// Use forced keys
		forvalues i = 1/`fnum' {
			local j = `i' + `keysused' + 1
			local symbolorder "`symbolorder' `j'"
			_getvaluelabel `varlist', key(`i')
			local symbollabels `"`symbollabels' label(`j' "`r(key_label)'")"'
		}
			
		// Rescale symbols
		if "`rescale'" == "" {	
			tempvar __symbol
			egen `__symbol' = group(`varlist')
			mata: nsymbol = st_data((1,`nodes'),st_varindex("`__symbol'"))
			if "`forcekeys'" == "" {
				qui tab `varlist' if _n <= `nodes', matrow(symbolkeysmap)
				forvalues i = 1/`r(r)' {
					local j = `i' + `keysused'
					local skey = symbolkeysmap[`i', 1]
					local symbolkeys "`symbolkeys' `i'"
					local symbolorder "`symbolorder' `j'"
					_getvaluelabel `varlist', key(`skey')
					local symbollabels `"`symbollabels' label(`j' "`r(key_label)'")"'
				}
			}
		}
		else {
			mata: nsymbol = st_data((1,`nodes'),st_varindex("`varlist'"))
			if "`forcekeys'" == "" {
				qui tab `varlist' if _n <= `nodes', matrow(symbolkeysmap)
				forvalues i = 1/`r(r)' {
					local j = `i' + `keysused'
					local skey = symbolkeysmap[`i', 1]
					local symbolkeys "`symbolkeys' `skey'"
					local symbolorder "`symbolorder' `j'"
					_getvaluelabel `varlist', key(`skey')
					local symbollabels `"`symbollabels' label(`j' "`r(key_label)'")"'
				}
			}
		}
	}
	else {
		mata: nsymbol = J(`nodes',1,1)
	}
	
	local keysused_symbol : word count `symbolkeys'
	if "`symbolkeys_legendoff'" == "" & "`symbol'" != ""{
		local keysused = `keysused' + `keysused_symbol'
	}
	else{
		local symbolkeys = ""
		local symbolorder = ""
		local symbollabels = ""
	}
	
	local 0 = "`size'"
	syntax [varlist(min=0 max=1 default=none)][, norescale legendoff forcekeys(string) sizebin(integer 1) mlcolor(string) mlwidth(string) *]
	local mlcolor_size = "`mlcolor'"
	local mlwidth_size = "`mlwidth'"
	if "`mlcolor_size'" == "" {
		local mlcolor_size = "`mlcolor_color'"
	}
	
	local size "`varlist'"
	// Size of nodes
	if ("`size'" != ""){
		local nodefactor = `nodefactor' / 2
		qui sum `varlist' if _n <= `nodes'
		local sizekeys_legendoff "`legendoff'"
		local sizekeys "`=round(`r(min)',0.01)' `=round(`r(max)',0.01)'"
		local sizekeys_size "`=round(`r(min)',0.01)' `=round(`r(max)',0.01)'"
		
		if "`forcekeys'" != "" {
			local sizekeys "`forcekeys'"
		}	
		capture drop __size
		gen __size = `varlist'
		if "`rescale'" == "" {
			local sizekeys_size ""
			if (`r(min)' != `r(max)') {
				qui replace __size = 1000 + 3000 * (`varlist') / (`r(max)')
				foreach szkey in `sizekeys' {
					local sizekeys_size_temp `= 1000 + 3000 * (`szkey' / (`r(max)'))'
					local sizekeys_size_temp = `sizekeys_size_temp' * `nodefactor' * 2/20
					local sizekeys_size "`sizekeys_size' `sizekeys_size_temp'"
				}
			}
			else {
				qui replace __size = 1500
				local szkey = 1500
				local sizekeys "`r(min)'"
				local sizekeys_size_temp = 1000
				local sizekeys_size_temp = `sizekeys_size_temp' * `nodefactor' * 2/20
				local sizekeys_size "`sizekeys_size' `sizekeys_size_temp'"
			}
			mata: nsize = st_data((1,`nodes'),st_varindex("__size"))
		}
		else {
			local sizekeys_size ""
			foreach szkey in `sizekeys' {
				local sizekeys_size "`sizekeys_size' `= 0.04 * `szkey''"
			}
			mata: nsize = st_data((1,`nodes'),st_varindex("__size"))
			mata: nsize = nsize :*40
		}
		local nodefactor = `nodefactor' / 20
		capture drop __size
	}
	else {
		mata: nsize = J(`nodes',1,80)
		local sizekeys ""
	}
	
	local sizeorder = ""
	local sizelabels = ""	
	local keysused_size : word count `sizekeys'
	if "`sizekeys_legendoff'" == ""  & "`size'" != ""{
		forvalues i = 1/ `keysused_size' {
			local sizelabel_temp : word `i' of `sizekeys'
			local sizeorder "`sizeorder' `=`keysused' + `i''"
			local sizelabels `"`sizelabels' label(`=`keysused' + `i'' "`varlist' = `sizelabel_temp'")"'
		}
		local keysused = `keysused' + `keysused_size'
	}
	else {
		local sizekeys = ""
	}
	
	restore
	
	// Label of nodes
	qui if ("`label'" != ""){
		capture confirm string variable `label'
		if _rc != 0 {
			tempvar nlabel_string
			tostring `label', generate(`nlabel_string') force
			mata: nlabel = st_sdata((1,`nodes'),st_varindex("`nlabel_string'"))
		}
		else {
			mata: nlabel = st_sdata((1,`nodes'),st_varindex("`label'"))
		}
	}
	else {
		mata: nlabel = J(`nodes',1,"")
	}

	////////////////////
	//
	//   EDGE ATTRIBUTES
	//
	////////////////////
	
	// Get network data
	nwtomata `netname', mat(plotmat)
	mata: M = (plotmat + plotmat') :/ (plotmat + plotmat')
	mata: _editmissing(M,0)
	// Get edgesize network data
	if "`edgesize'" != "" {
		if "`edgesize'" == "," {
			nwrandom `nodes', prob(1) name(__temp_edgesize_dummy)
			local edgesize "__temp_edgesize_dummy,"
			if strpos("`edgesize_options'", "legendoff") == 0 {
				local edgesize_options `"`edgesize_options' legendoff"'
			}
		}
		local 0 "`edgesize'`edgesize_options'"
		capture noi syntax [anything] [, forcekeys(string) legendoff ]
		if _rc != 0 {
			nwdrop __temp_edgesize_dummy
			error 6088
		}
		
		// check and clean networks as edgecolor and edgesize
		local edgesizekeys_legendoff "`legendoff'"
		local edgesize "`anything'"			
		nw_syntax `edgesize', max(1) nocurrent other(other)
		local edgesize_directed = "`otherdirected'"	
		local edgesize = trim("`othernetname'")
		local siznodes `othernodes'
		
		if "`labs'" != "`otherlabs'" & "`force'" == ""{
			di "{err}{it:network} {bf:`edgesize'} has different labels than {it:network} {bf:`netname'}; use option {bf:force}"
			error 6056
		}
		
		if `nodes' != `siznodes' {
			di "{err}{it:network} {bf:`edgesize'} needs to be of the same size as {it:network} {bf:`netname'}"
			error 6056
		}
		local edgesizekeys "`forcekeys'"
		if "`forcekeys'" == "" {
			local edgesizekeys "`r(minval)' `r(maxval)'"
		}
		nwtomata `edgesize', mat(edgesizemat)
		nwname `edgesize', newdirected("`edgesize_directed'")
	}
	else {
		mata: edgesizemat = J(`nodes',`nodes',1)
		local edgesizekeys ""
	}
	
	local edgesizeorder = ""
	local edgesizelabels = ""	
	local keysused_edgesize : word count `edgesizekeys'
	if "`edgesizekeys_legendoff'" == ""  & "`edgesize'" != ""{
		forvalues i = 1/ `keysused_edgesize' {
			local edgesizelabel_temp : word `i' of `edgesizekeys'
			local edgesizeorder "`edgesizeorder' `=`keysused' + `i''"
			local edgesizelabels `"`edgesizelabels' label(`=`keysused' + `i'' "`edgesize_original' = `edgesizelabel_temp'")"'
		}
		local keysused = `keysused' + `keysused_edgesize'
	}
	else {
		local edgesizekeys = ""	
	}
	
	// Get edgecolor network data
	if "`edgecolor'" != ""  {
		if "`edgecolor'" == "," {
			capture nwdrop __temp_edgecol_dummy
			nwrandom `nodes', prob(0) name(__temp_edgecol_dummy)
			//nwreplace __temp_egdecol_dummy = .
			local edgecolor "__temp_edgecol_dummy,"
			if strpos("`edgecolor_options'", "legendoff") == 0 {
				local edgecolor_options `"`edgecolor_options' legendoff"'
			}
		}
		local 0 "`edgecolor'`edgecolor_options'"
		capture noi syntax [anything] [, foreground(string) forcekeys(string) legendoff edgecolorpalette(string) edgepatternpalette(string)]
		local edgeforeground = "`foreground'"
		if _rc != 0 {
			nwdrop __temp_edgecolor_dummy
			error 6088
		}
		// check and clean network 
		local edgecolorkeys_legendoff "`legendoff'"
		local edgecolor "`anything'"
		nw_syntax `edgecolor', max(1) nocurrent other(other)
		local edgecolor_directed = "`otherdirected'"	
		local edgecolor = trim("`othernetname'")
		local siznodes = `othernodes'
		
		if "`labs'" != "`otherlabs'" & "`force'" == ""{
			di "{err}{it:network} {bf:`edgecolor'} has different labels than {it:network} {bf:`netname'}; use option {bf:force}"
			error 6056
		}
		
		if `nodes' != `siznodes' {
			di "{err}{it:network} {bf:`edgecolor'} needs to be of the same size as {it:network} {bf:`netname'}"
			error 6056
		}
		local edgecolorkeys "`forcekeys'"

		qui if "`forcekeys'" == "" {
			nwtabulate `edgecolor', matrow(r)
			matrix edgecolor_mat = r
			
			local edgecolor_matrows = rowsof(edgecolor_mat)
			forvalues i = 1/`edgecolor_matrows'{
				local eckey = edgecolor_mat[`i',1]
				local edgecolorkeys "`edgecolorkeys' `=`eckey'+1'"
			}
		}
		nwtomata `edgecolor', mat(edgecolormat)
		mata: edgecolormat = edgecolormat :+ 1
		nwname `edgecolor', newdirected("`edgecolor_directed'")
	}
	else {
		mata: edgecolormat = J(`nodes',`nodes',0)
	}

	local edgecolororder = ""
	local edgecolorlabels = ""	
	local keysused_edgecolor : word count `edgecolorkeys'
	if "`edgecolorkeys_legendoff'" == ""  & "`edgecolor'" != ""{
		forvalues i = 1/ `keysused_edgecolor' {
			local edgecolorlabel_temp : word `i' of `edgecolorkeys'
			local edgecolororder "`edgecolororder' `=`keysused' + `i''"
			local edgecolorlabels `"`edgecolorlabels' label(`=`keysused' + `i'' "`edgecolor_original' = `=`edgecolorlabel_temp'-1'")"'
		}
		local keysused = `keysused' + `keysused_edgecolor'
	}
	else {
		local edgecolorkeys = ""	
	}

	////////////////////
	//
	//   CALCULATE NODE COORDINATES
	//
	////////////////////
	
	
	if "`nodexy'" != "" {
		local layout = "nodexy"
		local nodex = word("`nodexy'", 1)
		local nodey = word("`nodexy'", 2)
		
		/*
		foreach nvar of varlist `nodex' `nodey' {
			qui sum `nvar'
			if (r(min) < 0 | r(max) >= 2) {
				di "{err}Node coordinates not between 0 and 1.5 Option {it:layout(mds)} selected instead."
				local layout = "mds"		
			}
		}*/
	}
	
	/*
	if "`nodexy'" != "" {
		tempvar xcor ycor
		local layout = "nodexy"
		local nodex = word("`nodexy'", 1)
		local nodey = word("`nodexy'", 2)
		local k = 1
		if "`layout_norescale'" == "" {
			gen `xcor' = `nodex'
			gen `ycor' = `nodey'
			qui sum `xcor'
			replace `xcor' =(1.25 * (`xcor' - r(min)) / (r(max) - r(min))) + 0.25
			qui sum `ycor'
			replace `ycor' = (`ycor' - r(min)) / (r(max) - r(min))
			local nodex "`xcor'"
			local nodey "`ycor'"
		}
		else {
			//qui sum `nodex'
			/*if (r(min) < 0.25 | r(max) >= 1.5) {
				di "{err}Node coordinates outside of valid range; {it:layout(mds)} selected instead."
				local layout = "mds"		
			}
			else {
				qui sum `nodey'
				if (r(min) < 0 | r(max) >= 1) {
					di "{err}Node coordinates outside of valid range; {it:layout(mds)} selected instead."
					local layout = "mds"
				}
			}*/
		}
	}*/
	
	
	local layout_gridcols "`columns'"
	local components = "`layout_components'"
	
	if ("`layout'"!="nodexy"){
		di "{text:Calculating node coordinates...}"
	}
	// BUGFIX: every layout below crashed outright on a single-node
	// network with a different raw error (mds: "dimension exceeds
	// #rows of dissimilarity matrix", r(498); circle/grid: a Mata
	// conformability error; mdsclassical: "_outdegree not found",
	// r(111)) - each layout algorithm needs at least 2 nodes to have
	// anything meaningful to compute (a distance matrix, a circle
	// arrangement, etc.), but none of them special-cased the trivial
	// n=1 case, where the only sensible answer is simply "the one node
	// goes somewhere". Placed at the center of this file's own
	// established [0,~1.5] x [0,1] plotting coordinate range (see the
	// nodexy rescale logic above) and every layout-specific computation
	// below skipped entirely for this case, rather than trying to make
	// each of the 7 different layout algorithms individually tolerate
	// a degenerate 1-node input.
	if (`nodes' == 1) {
		mata: Coord = J(1,2,0.5)
	}
	if ("`layout'"=="_layoutfunction" & `nodes' > 1) {
		gettoken _layoutfcn _layoutfcnopt: _layoutfunction, parse(",")
		mata: Coord = `_layoutfcn'(M`_layoutfcnopt')
	}
	if ("`layout'"== "mds" & `nodes' > 1){
		mata: Coord = netplotmds(M, `iterations')
	}

	if ("`layout'"=="frucht" & `nodes' > 1){
		mata: Coord = fruchtrein(M, `iterations')
	}

    qui if ("`layout'"=="mdsclassical" & `nodes' > 1 ){
		// Coordinates matrix to be populated
		mata: Coord = J(`nodes', 2, 0)
		mata: Coord[.,1] = J(`nodes', 1, 1.5) 
		// Deal with isolates
		//
		// was "nwgen `_isolates' = isolates(`netname')" - "isolates(" is
		// listed in nwgenerate.ado's own recognized-keyword vocabulary
		// (so it parses without error) but has no actual dispatch branch
		// implementing it (nwgenerate.ado only implements the
		// NETWORK-producing shortcuts - large/duplicate/dyadprob/.../
		// transpose; "isolates(" is one of a separate, larger family of
		// VARIABLE-producing shortcuts - degree/outdegree/indegree/
		// isolates/components/lgc/clustering/closeness/farness/nearness/
		// between/evcent/context/addnodes/collapse/subset - that are all
		// recognized but silently no-op instead of erroring). This meant
		// the tempvar was never actually created, and the very next
		// line ("count if `_isolates' == 1") crashed with a "not found"
		// - meaning mdsclassical, the DEFAULT layout for any network
		// with more than 50 nodes, was completely broken for every
		// caller, not a rare edge case - confirmed via a minimal
		// "nwrandom 60, prob(.15)" + "nwplot" repro, traced to this
		// exact line via "set trace on". The general nwgen/nwgenerate
		// variable-shortcut gap is a separate, much larger pre-existing
		// issue (see docs/CERTIFICATION.md's Pending table) - out of
		// scope to fix generally here; this fix routes nwplot's own
		// internal isolates lookup through nwdegree's plain default
		// degree computation instead (its own "isolates" option turned
		// out to have a second, independent, genuine bug - confirmed
		// via "set trace on": with "isolates" given and no explicit
		// generate(), nwdegree.ado reserves only ONE output-variable
		// name ("_isolates"), but its directed-network branch
		// unconditionally needs TWO (outdegree and indegree storage) -
		// crashing with an empty target variable name on any directed
		// network, which "nwrandom" defaults to. Recorded as its own,
		// separate, not-yet-fixed bug in docs/CERTIFICATION.md's
		// Pending table rather than patched here, to keep this fix
		// narrowly scoped to nwplot.ado. nwdegree's plain default
		// behaviour - not the buggy "isolates" option - is exactly the
		// same well-tested, heavily-used code path every other caller
		// of nwdegree already relies on, so the isolate indicator is
		// simply derived from it directly afterward.
		// BUGFIX: a single compound "capture drop A B C D" is NOT
		// equivalent to dropping each variable independently - Stata's
		// drop command is all-or-nothing over its whole varlist, so if
		// even ONE named variable does not exist, the ENTIRE command
		// fails and drops NOTHING, not even the others that do exist
		// (confirmed via a direct, minimal probe: "capture drop a b c d"
		// with only a/b existing left both a and b undropped). Exactly
		// one of _degree (undirected) or _outdegree/_indegree (directed)
		// is ever actually created by nwdegree below - the other name(s)
		// never exist - so this compound drop always silently failed via
		// `capture', on every single call, for every network, leaving
		// _isolates and whichever of _degree/_outdegree/_indegree WAS
		// created stranded in the dataset after nwplot returned. That
		// stranded leftover then collided with nwdegree's own "variable
		// already exists" guard on the very next call that tried to
		// generate the same default variable name - nwplot's own next
		// invocation (this exact line, on ANY network), a later user
		// nwdegree call, or nwplot's internal isolates recomputation for
		// a second network, all indistinguishably, since these are
		// ordinary Stata dataset variables shared across the whole
		// session, not scoped to any one network. This is the actual
		// root cause of the "nwplot/nwdegree fail with a bare r(99)
		// after creating a second network" report - reproduces
		// identically on a single network (no second network needed),
		// confirmed via a direct repro before this fix. Splitting into
		// one drop per variable makes each one independent: a missing
		// variable is silently skipped (via `capture'), not treated as
		// a reason to abandon dropping the others.
		capture drop _isolates
		capture drop _degree
		capture drop _outdegree
		capture drop _indegree
		qui nwdegree `netname', silent
		capture confirm variable _degree
		if _rc == 0 {
			qui gen _isolates = (_degree == 0)
		}
		else {
			qui gen _isolates = (_outdegree == 0) & (_indegree == 0)
		}
		qui count if _isolates == 1
		local isol = `r(N)'
		// same fix as the pre-emptive cleanup above - one drop per
		// variable, not a single compound drop that silently fails
		// entirely (and drops nothing) the moment any one of these four
		// names doesn't exist, which is always true for at least one of
		// _degree vs _outdegree/_indegree.
		capture drop _isolates
		capture drop _degree
		capture drop _outdegree
		capture drop _indegree
		local nonisol = `nodes' - `isol'
		
		// Get number of components
		//
		// was "nwgenerate `_component' = components(`netname')" /
		// "nwgen `_component' = lgc(`netname')" - "components(" and
		// "lgc(" are two more instances of the exact same broken-
		// shortcut family as "isolates(" just above (recognized by
		// nwgenerate.ado's own keyword vocabulary, but with no actual
		// dispatch branch implementing either one) - both calls
		// silently left `_component' never created, which crashed the
		// very next real statement ("tab `_component', ...") with
		// "nothing found where name expected" / a Mata "invalid Stata
		// variable name" error. Routed through nwcomponents instead -
		// already well-tested (this session's own certification
		// history), and it directly provides both the per-node
		// component-id variable AND r(components) in one call, exactly
		// what this code already expected to have. Note "local compnum"/
		// "local compnum_nonisol" just below are otherwise-unused dead
		// locals (confirmed via a direct grep across the whole file -
		// nothing downstream ever references either one; the real
		// downstream driver is "comp_nonisol", computed independently a
		// few lines below from comp_freqid) - left in place rather than
		// removed, since deleting unrelated dead code is out of scope
		// for this fix.
		tempvar _component
		qui nwcomponents `netname', generate(`_component')
		if "`lgc'" != "" {
			qui nwcomponents `netname', lgc generate(`_component') replace
			replace `_component' = 1 - `_component'
			local components = 1
		}

		local compnum = r(components)
		local compnum_nonisol = `compnum' - `isol'
		qui tab `_component', matrow(comp_id) matcell(comp_freq)

		mata: comp_id = st_matrix("comp_id")
		mata: comp_freq = st_matrix("comp_freq")
		mata: comp_freqid = J(rows(comp_id), 2,0)
		mata: comp_freqid[.,1] = comp_freq
		mata: comp_freqid[.,2] = comp_id
		mata: comp_freqid = sort(comp_freqid, - 1)
		mata: comp_nonisol = sum((comp_freqid[.,1] :> 1))
		mata: st_numscalar("r(comp_nonisol)", comp_nonisol)
		local comp_nonisol = `r(comp_nonisol)'
		mata: st_matrix("comp_freqid", comp_freqid)

		// Find overall layout
		// Default = number of (non-isolates) components (undirected)
		if "`components'" == "" {
			local components = `comp_nonisol'
		}
		// Limit number of distinct boxes in graph
		if `components' > `comp_nonisol' {
			local components = `comp_nonisol'
		}
		if `components' > 5 {
			di "{txt}only the {bf:5} largest components are displayed"
			local components = 5
		}
		
		// Go through all (non-isolates) components (that should be plotted in boxes) from large to small
		qui forvalues i = 1/`components' {
			nwduplicate `netname', name(`netname'_comp`i')
			capture drop _id
			gen _id = _n
			
			nwdrop `netname'_comp`i' if `_component' != comp_freqid[`i', 2]
			nwtomata `netname'_comp`i', mat(compmat)
			// Original id's of selected nodes
			mata: original_id = st_data((1::rows(compmat)), "_id")
			
			// Calculate mds coordinates of network i
			mata: compM = (compmat :+ compmat') :/ (compmat :+ compmat')
			mata: _editmissing(compM,0)
			mata: Coord_comp = mmdslayout(compM)
			//noi mata: Coord_comp = correctCoordClash(Coord_comp, compM, (.05 * `nodeclashchange'), `nodeproximity') 
			// Adjust coordinates for position in layout
			// Deal with largest component
			if `i' == 1  & `components' != 1 {
				mata: Coord_comp[.,1] = Coord_comp[.,1] :* 0.9
				if `components' == 1 {
					mata: Coord_comp[.,1] = Coord_comp[.,1] :+ 0.125
				}
			}
			if `i' == 1  & `components' == 1 {
				mata: Coord_comp[.,1] = Coord_comp[.,1] :+ 0.125
			}
			
			// Deal with second largest component
			if `i' == 2 {
				mata: Coord_comp[.,1] = (Coord_comp[.,1] :*0.45):+ 1.1
				mata: Coord_comp[.,2] = (Coord_comp[.,2] :*0.45):+ .5
			}	
			
			// Assign adjusted coordinates to original network
			mata: Coord[original_id,.] = Coord_comp
			mata: mata drop original_id 
			nwdrop `netname'_comp`i'
		}
		capture drop _id 
	}
	capture replace `label' = `_orig_label'
	
	if ("`layout'"=="circle" & `nodes' > 1){
		mata: Coord = circlelayout(rows(M))
	}
	if ("`layout'"=="grid" & `nodes' > 1){
		if "`layout_gridcols'" == "" {
			local layout_gridcols = ceil(sqrt(`nodes'))
		}
		mata: Coord = gridlayout(rows(M), `layout_gridcols')
	}
	if ("`layout'"=="nodexy" & `nodes' > 1){
		mata: Coord = J(rows(M),2,0)
		mata: Coord[.,1] = st_data((1,rows(M)),"`nodex'")
		mata: Coord[.,2] = st_data((1,rows(M)),"`nodey'")
	}
	
	
	// Obtain tie coordinates 
	mata: TC = getTieCoordinates(Coord,nsize,NumElist(plotmat), edgecolormat, edgesizemat, `nodefactor', `doarrows', `arrowgap')
	mata: st_numscalar("r(TC)", rows(TC))
	local minObs = max(`r(TC)', `nodes')
	
	// Prepare temporary Stata dataset for plotting
	preserve
	qui drop _all
	qui set obs `minObs'
	qui gen nx = .
	qui gen ny = .
	qui gen nsize = .
	
	qui gen ncolor = .
	qui gen nsymbol = .
	qui mata: st_addvar("str20", "nlabel")
	qui gen sx = .
	qui gen sy = .
	qui gen ex = .
	qui gen ey = .
	qui gen value = .
	qui gen recip = .
	qui gen edgecolor = .
	qui gen edgesize = .
	
	mata: st_numscalar("r(ties)", rows(TC))
	if `r(ties)' > 0 {
		mata: st_store((1::rows(TC)),("sx","sy","ex","ey","value","recip","edgecolor", "edgesize"),TC[.,.])
	}
	
	qui gen straight =  1 - recip
	qui replace straight = 0 if "`arcstyle'" == "curved"
	qui replace straight = 1 if "`arcstyle'" == "straight"
	qui gen arrow = straight
	
	if ("`arcstyle'" != "straight"){
		di "{txt}Generating splines..."
		//save raw.dta, replace
		qui nwplotsplines, unbend(straight) arrow(arrow) x1(sx) y1(sy) x2(ex) y2(ey) bend(`arcbend') splines(`arcsplines')
	}
	
	mata: st_store((1::rows(Coord)),("nx","ny"), Coord[.,.])
	mata: st_store((1::rows(nsize)),("nsize"), nsize[.,.])
	mata: st_store((1::rows(ncolor)),("ncolor"), ncolor[.,.])
	mata: st_store((1::rows(ncolor)),("nsymbol"), nsymbol[.,.])
	mata: st_sstore((1::rows(nlabel)),("nlabel"), nlabel[.,.])
	
	local binfactor = 1/`sizebin'
	qui replace nsize = (ceil(nsize * `binfactor'))* `sizebin'
	qui tab nsize, matrow(nsizerow)
	qui sum nsize
	local sizemin = r(min)
	local sizemax = r(max)	
	
	// Prepare plots and legend
	qui tab ncolor, matrow(ncolorrow)
	local ncols = rowsof(ncolorrow)
	if `ncols' == 0 { 
		local ncols = 1
	}
	
	qui tab nsymbol, matrow(nsymbolrow)
	local symbs = rowsof(nsymbolrow)
	
	qui tab nsize, matrow(nsizerow)	
	local sizs = rowsof(nsizerow)
	
	// Prepare ghost plots for legend
	tempvar ghost1 ghost2
	local ghostcmd ""
	qui gen `ghost1' = .
	qui gen `ghost2' = .
	local sizekeys_num = 0
	local colorkeys_num = 0
	local symbolkeys_num = 0
	local colorkeys_num : word count `colorkeys'
	local symbolkeys_num : word count `symbolkeys'	
	local sizekeys_num : word count `sizekeys'
	local edgesizekeys_num : word count `edgesizekeys'
	local edgecolorkeys_num : word count `edgecolorkeys'
	local columns = max(`symbolkeys_num', `colorkeys_num', `sizekeys_num', `edgesizekeys_num', `edgecolorkeys_num')
	

	local cols_found =  strpos("`legendopt'", "cols")
	if `cols_found' == 0 {
		local legendopt "`legendopt' cols(`columns')"
	}
	else {
		local 0 `",`legendopt'"'
		syntax [, cols(string) *]
		local columns = `cols'
	}
	
	
	// Get the ident of the legend
	local colorident = ""
	local temp = mod(`=`colorkeys_num'+1', `columns')
	if "`temp'" == "." {	
		local temp = 1 
	}
	forvalues i = `temp' / `columns' {
		if `colorkeys_num' != 0 {
			local colorident = "`colorident' - "
		}
	}
	
	local symbolident = ""
	local temp = mod(`=`symbolkeys_num'+1', `columns')
	if "`temp'" == "." {	
		local temp = 1 
	}
	forvalues i = `temp' / `columns' {
		if `symbolkeys_num' != 0 {
			local symbolident = "`symbolident' - "	
		}
	}

	local sizeident = "" 
	local temp = mod(`=`sizekeys_num'+1', `columns')
	if "`temp'" == "." {	
		local temp = 1 
	}
	forvalues i = `temp' / `columns' {
		if `sizekeys_num' != 0 {
			local sizeident = "`sizeident' - "
		}
	}
	
	local edgesizeident = "" 
	local temp = mod(`=`edgesizekeys_num'+1', `columns')
	if "`temp'" == "." {	
		local temp = 1 
	}
	forvalues i = `temp' / `columns' {
		if `edgesizekeys_num' != 0 {
			local edgesizeident = "`edgesizeident' - "
		}
	}
	
	
	// Ghost plots for node color
	if "`colorkeys_legendoff'" == "" {
		if `colorkeys_num' >= 1 {	
			local ckey = 0
			foreach i in `colorkeys' {
				_getcolorstyle, i(`i') j(0) colorpalette(`colorpalette') symbolpalette(`symbolpalette') scheme(`scheme') mlcolor(`mlcolor_color') mlwidth(`mlwidth_color')
				local tempcolstyle_fill = r(col_fill)
				local tempcolstyle_line = r(col_line)
				local tempwidth_line = r(line_width)
				local ghostcmd `"`ghostcmd' || (scatter `ghost1' `ghost2' if `ghost1' !=.,  msymbol("scheme p0")  mfcolor("`tempcolstyle_fill'") mlwidth("`tempwidth_line'") mlcolor("`tempcolstyle_line'")   msize(2) `scatteropt') "'            		
			}
		}
	}
	else {
		local colorident ""
	}
	
	// Ghost plots for node symbol
	if "`symbolkeys_legendoff'" == "" {
		if `symbolkeys_num' >= 1 {	
			local skey = 0
			foreach j in `symbolkeys' {
				_getcolorstyle, i(0) j(`j') colorpalette(`colorpalette') symbolpalette(`symbolpalette') scheme(`scheme') mlcolor(`mlcolor_symbol') mlwidth(`mlwidth_symbol')
				local tempsymbol = r(symbol)
				local tempcolstyle_line = r(col_line)
				local tempwidth_line = r(line_width)
				local ghostcmd `"`ghostcmd' || (scatter `ghost1' `ghost2' if `ghost1' !=.,  msymbol("`tempsymbol'") mlwidth("`tempwidth_line'") mfcolor("scheme background") mlcolor("`tempcolstyle_line'") msize(2) `scatteropt') "'            		
			}
		}
	}
	else {
		local symbolident ""
	}
	
	// Ghost plots of size of nodes
	if "`size'" != "" & "`sizekeys_legendoff'" == ""{
		local i = 0
		_getcolorstyle, i(0) j(1) colorpalette(`colorpalette') symbolpalette(`symbolpalette') scheme(`scheme') mlcolor(`mlcolor_size') mlwidth(`mlwidth_size')
		foreach szkey in `sizekeys' {
			local i = `i' + 1
			local szkey_size : word `i' of `sizekeys_size'
			local tempcolstyle_line = r(col_line)
			local tempwidth_line = r(line_width)
			local ghostcmd `"`ghostcmd' || (scatter `ghost1' `ghost2' if `ghost1' !=.,  msymbol("scheme p0")  mlcolor("`tempcolstyle_line'") mlwidth("`templine_width'") mfcolor("scheme p0")  msize(`szkey_size') `scatteropt') "'            		
		}
		local sizekeys_num : word count `sizekeys'
	}
	else {
		local sizeident ""
	}
	
	// Ghost plots of size of edges
	if "`edgesizekeys'" != "" & "`edgesizekeys_legendoff'" == ""{
		foreach eszkey in `edgesizekeys' {
			local tempval_line = (`eszkey' / 2) * `edgefactor' / 2
			local tempval_arrow = (`eszkey' + 1) * `arrowfactor' 
			local tempval_barb = `tempval_arrow' * `arrowbarbfactor'
			local ghostcmd `"`ghostcmd' || (`pc' `ghost1' `ghost2' `ghost2' `ghost1' if `ghost1' !=., lpattern(solid) lwidth(`tempval_line') lcolor("scheme p0") mcolor("scheme p0") msize(`tempval_arrow') barbsize(`tempval_barb') `lineopt') ||"'
		}
		local edgesizekeys_num : word count `edgesizekeys'
	}
	else {
		local edgesizeident ""
	}	
	
	// Ghost plots of color of edges
	if "`edgecolorkeys'" != "" & "`edgecolorkeys_legendoff'" == ""{
		foreach eckey in `edgecolorkeys' {
			_getcolorstyle, i(`=`eckey'') edgecolorpalette(`edgecolorpalette') edgepatternpalette(`edgepatternpalette') scheme(`scheme')
			local temppattern = r(edgepattern)
			local tempcolstyle = r(edgecol)
			local tempval_arrow = 3 * `arrowfactor' 
			local tempval_barb = `tempval_arrow' * `arrowbarbfactor'
			local ghostcmd `"`ghostcmd' || (pcspike `ghost1' `ghost2' `ghost2' `ghost1' if `ghost1' !=., lpattern(`"`temppattern'"') lwidth(1) lcolor(`"`tempcolstyle'"') mcolor(`"`tempcolstyle'"')  `lineopt') ||"'
		}
		local edgesizekeys_num : word count `edgesizekeys'
	}
	else {
		local edgesizeident ""
	}	
	
	local arrowgap = `arrowgap' + 1.2
	if "`legendopt'" == "" | `keysused' == 0 {
		local legendcmd = "legend(off)"
		local arrowgap = `arrowgap' - 5.2
	}
	else {
		local legendcmd `"legend(order(`colororder' `colorident' `symbolorder' `symbolident' `sizeorder' `sizeident' `edgesizeorder' `edgesizeident' `edgecolororder' `edgecolorident') `colorlabels' `symbollabels' `sizelabels' `edgesizelabels' `edgecolorlabels' `legendopt')"'
	}

	// Prepare scatter commands to plot nodes
	local scattercmd ""	
	local scattercmdforeground ""
	local tempsize_rows = rowsof(nsizerow)
	
	// Size of nodes
	forvalues tempsiz_mat = 1/`tempsize_rows'{
		local tempsiz = nsizerow[`tempsiz_mat',1] 
		// Color of nodes
		forvalues i = 1/`ncols' {
			// Symbol of nodes
			forvalues j = 1/`symbs'{
				local tempcol = ncolorrow[`i', 1]
				local tempsymb = nsymbolrow[`j',1]
				_getcolorstyle, i(`tempcol') j(`tempsymb') colorpalette(`colorpalette') symbolpalette(`symbolpalette') scheme(`scheme') mlcolor(`mlcolor_color') mlwidth(`mlwidth_color')
				local tempsiz_node = `tempsiz' * `nodefactor' * 2
				local tempcolstyle_fill = r(col_fill)
				local tempcolstyle_line = r(col_line)
				local tempsymbol = r(symbol)
				local tempwidth_line = r(line_width)
				if "`label'" != "" {
					local scatterlabel "mlabel(nlabel)"
				}
				
				local foregroundcheck : list tempcol in colorforeground		
				if `foregroundcheck' == 0 {
					local scattercmd `"`scattercmd' (scatter ny nx if ncolor == `tempcol' & nsymbol == `tempsymb' & nsize == `tempsiz',  mlabcolor("scheme label") msymbol("`tempsymbol'") mlwidth("`tempwidth_line'") mlcolor("`tempcolstyle_line'") mfcolor("`tempcolstyle_fill'") msize(`tempsiz_node') `scatterlabel' `scatteropt') ||"' 
				}
				else {
					local scattercmdforeground `"`scattercmdforeground' (scatter ny nx if ncolor == `tempcol' & nsymbol == `tempsymb' & nsize == `tempsiz',  mlabcolor("scheme label") msymbol("`tempsymbol'") mlwidth("`tempwidth_line'") mlcolor("`tempcolstyle_line'") mfcolor("`tempcolstyle_fill'") msize(`tempsiz_node') `scatterlabel' `scatteropt') ||"' 
				}				
			}
		}
	}
	
	// Prepare pc command to plot arcs/edges
	local pccmd "||"
	local pccmdforeground ""

	// BUGFIX: a network with zero ties at all (e.g. any single-node
	// network - no off-diagonal pair can even exist) leaves `edgesize'/
	// `edgecolor' entirely missing for every observation in this
	// tie-level dataset - `tab' finds no categories to tabulate and
	// does not create `matrow(valuerow)'/`matrow(edgecolorrow)' at all
	// in that case (not merely empty matrices - the locals are left
	// completely undefined), crashing the very next line ("valuerow
	// not found", r(111)). There is nothing to draw on the edge side of
	// the plot when there are no edges, so this whole block is skipped
	// entirely rather than trying to make `tab' tolerate an all-missing
	// input - `pccmd'/`pccmdforeground' simply stay at their own
	// already-initialized "no edges" values ("||"/"").
	qui count if edgesize < .
	if r(N) > 0 {
		qui tab edgesize, matrow(valuerow)
		local tempvalue_rows = rowsof(valuerow)
		qui tab edgecolor, matrow(edgecolorrow)
		local tempecol_rows = rowsof(edgecolorrow)

		forvalues tempecol_mat = 1/`tempecol_rows'{
			local tempecol = edgecolorrow[`tempecol_mat',1]
			_getcolorstyle, i(`tempecol') edgecolorpalette(`edgecolorpalette') edgepatternpalette(`edgepatternpalette') scheme(`scheme')
			local temppattern = r(edgepattern)
			local tempcolstyle = r(edgecol)
			forvalues tempval_mat = 1/`tempvalue_rows'{
				local tempval = valuerow[`tempval_mat',1]
				local tempval_line = (`tempval' / 2) * `edgefactor' / 2
				local tempval_arrow = (`tempval' + 1) * `arrowfactor'
				local tempval_barb = `tempval_arrow' * `arrowbarbfactor'
				local tempecol_orig = `tempecol' - 1
				local foregroundcheck : list tempecol_orig in edgeforeground
				if `foregroundcheck' == 0 {
					local pccmd `"`pccmd' (pcspike sy sx ey ex if value != 0 & edgesize == `tempval' & edgecolor == `tempecol', lpattern(`temppattern') lwidth(`tempval_line') lcolor("`tempcolstyle'") mfcolor("`tempcolstyle'") mcolor("`tempcolstyle'") msize(`tempval_arrow') barbsize(`tempval_barb') `lineopt') || (`pc' sy sx ey ex if value != 0 & edgesize == `tempval'  & edgecolor == `tempecol' & arrow == 1,  lpattern(`temppattern') lwidth(`tempval_line') lcolor("`tempcolstyle'") mfcolor("`tempcolstyle'") mcolor("`tempcolstyle'") msize(`tempval_arrow') barbsize(`tempval_barb') `lineopt') ||"'
				}
				else {
					local pccmdforeground `"`pccmdforeground' (pcspike sy sx ey ex if value != 0 & edgesize == `tempval' & edgecolor == `tempecol', lpattern(`temppattern') lwidth(`tempval_line') lcolor("`tempcolstyle'") mfcolor("`tempcolstyle'") mcolor("`tempcolstyle'") msize(`tempval_arrow') barbsize(`tempval_barb') `lineopt') || (`pc' sy sx ey ex if value != 0 & edgesize == `tempval'  & edgecolor == `tempecol' & arrow == 1,  lpattern(`temppattern') lwidth(`tempval_line') lcolor("`tempcolstyle'") mfcolor("`tempcolstyle'") mcolor("`tempcolstyle'") msize(`tempval_arrow') barbsize(`tempval_barb') `lineopt') ||"'
				}
			}
		}
	}
	
	local pmargin = `nodefactor' * 3
	local graphcmd `"twoway `ghostcmd' `pccmd' `scattercmd' `pccmdforeground' `scattercmdforeground' , ylabel(, nogrid) yscale(off range(0 100)) xscale(off range(0 150)) graphregion(color("scheme plotregion")) plotregion(color("scheme plotregion") margin(`pmargin' `pmargin' `pmargin' `pmargin')) aspectratio(`aspectratio') `legendcmd' `schemetwoway' `twowayopt'"' 

	di "{text:Plotting network...}"
	//di `"`graphcmd'"'
	`graphcmd'

	// export() is a thin wrapper around Stata's own native "graph
	// export" - the just-drawn twoway graph above (`graphcmd') is an
	// ordinary Stata graph object, so exporting it is nothing more than
	// calling the same command a user would type by hand afterward;
	// this does not touch or replace that graph object, so it remains
	// fully available for graph editor/save/re-export use exactly as if
	// export() had never been given. The output format (SVG/PDF/PNG/...)
	// is inferred by "graph export" itself from the filename's own
	// extension, matching Stata's own established convention - no
	// separate format() option is added. exportopt() is a narrow,
	// explicit passthrough for the handful of "graph export" options
	// that are genuinely still useful to reach without leaving nwplot
	// (chiefly raster width()/height() for PNG/TIF quality); anything
	// more exotic is still one manual "graph export" call away.
	if "`export'" != "" {
		// SVG export needs Stata 16 or later - check explicitly rather
		// than let "graph export" itself fail with a generic error (or,
		// on an older Stata that silently accepts the option but
		// produces a broken/incomplete file, worse: fail silently).
		if substr(lower("`export'"), -4, .) == ".svg" & c(stata_version) < 16 {
			di "{err}SVG export requires Stata 16 or later (this is Stata `c(stata_version)'). Export to a different format (png/pdf/eps/...), or upgrade Stata."
			error 9
		}
		di "{text:Exporting graph to `export'...}"
		graph export "`export'", `replace' `exportopt'
		return local export "`export'"
	}

	// the scheme actually used to render this plot - "s1network" unless
	// scheme() was given explicitly (see its own default assignment
	// above)
	return local scheme "`scheme'"

	restore

	if "`generate'" != "" {
		di "{text:Export coordinates...}"
		if (wordcount("`generate'") >= 2){
			local generate_x = word("`generate'", 1)
			local generate_y = word("`generate'", 2)
		}
		else {
			local generate_x = "_x_coord"
			local generate_y = "_y_coord"
		}
		
		capture drop `generate_x'
		capture drop `generate_y'
		if _N < `nodes' {
			set obs `nodes'
		}
		qui gen `generate_x' = .
		qui gen `generate_y' = .
		mata: st_store((1::rows(Coord)),("`generate_x'","`generate_y'"), (Coord[.,.]:/100))
		qui replace `generate_x' = (`generate_x' - 0.05) / 0.9
		qui replace `generate_y' = (`generate_y' - 0.05) / 0.9
	}
	mata: mata drop plotmat nsize ncolor nlabel Coord edgesizemat edgecolormat
	capture mata: mata drop Coord_comp compM comp_freq comp_id comp_freqid compmat comp_share comp_nonisol
	capture mata: mata drop TC M nsymbol
	capture nwdrop __temp* 
	
	capture mat drop edgecolorrow
	capture mat drop valuerow
	capture mat drop nsymbolrow
	capture mat drop ncolorrow
	capture mat drop nsizerow
	capture mat drop nsymblrow
	capture mat drop colorkeysmap
	capture mata drop symbolkeysmap

	//qui nwload `masternetname', labelonly

	// The cleanup captures just above (several of which legitimately
	// "fail" - e.g. the Coord_comp/compM/... Mata cluster only exists
	// when the lgc/component code path actually ran) leave _rc stale
	// at whatever the LAST one happened to return, since nothing
	// between here and the end of the program is a capture-wrapped
	// command that would refresh it (see nwcompressobs.ado's own
	// certified row for the fuller explanation of this Stata
	// behavior - quietly-prefixed commands, mata: blocks, and plain
	// local assignment never update _rc even when they succeed). That
	// stale _rc then survived all the way out to nwplot's own caller,
	// including after a genuinely successful plot/export - confirmed
	// directly while adding export() this unit, and previously worked
	// around rather than fixed in cscripts/test_nwplot.do's own
	// long-standing "assert _rc == 0 | _rc == 3000" pattern. The
	// preceding "mata: st_numscalar("_rc", 0)" line was an earlier,
	// ineffective attempt at this exact fix: st_numscalar("_rc", ...)
	// only creates an ordinary Stata scalar literally named "_rc" in
	// the dataset's own scalar namespace - it has no effect on the
	// interpreter's real _rc state, which only a capture-wrapped
	// command can deterministically set. Reset explicitly and silently.
	capture confirm number 1
end
	
capture program drop _getvaluelabel
program _getvaluelabel
	syntax varlist(min=1 max=1), key(string)
	
	qui labellist `varlist'
	local labkeys "`r(values)'"
	local lablabels `"`r(labels)'"'
	if ("`r(lblname)'"!= ""){
		local lnum = `r(`r(lblname)'_k)'
		local llab "`varlist' = `key'"
		forvalues j = 1 /`lnum' {
			local lkey : word `j' of `labkeys'
			if "`lkey'" == "`key'" {
				local llab : word `j' of `lablabels'
			}
		}
	}
	else{
		local llab "`varlist' = `key'"
	}
	mata: st_global("r(key_label)", "`llab'")
	mata: st_global("r(key)", "`key'")
end

capture program drop nwplotsplines
program nwplotsplines
	syntax, unbend(string) arrow(string) y1(string) x1(string) y2(string) x2(string) bend(string) splines(string) 

	tempvar l llid rad mult1 mult2 mult3 alpha beta x3n y3n x3 x4 y3 y4 xtemp ytemp r gamma delta lid alphaX
	gen `l' = sqrt((`x1' - `x2')^2 + (`y1' - `y2')^2)
	gen `rad' = `bend'* `l'

	gen `mult1' = 1 - 2 * (`x2' > `x1')
	replace `mult1' = 1 - 2 * (`y2' > `y1') if `x1' == `x2'
	gen `mult2' = 1 - 2 * (`y2' > `y1')
	replace `mult2' = 1 - 2 * (`x2' > `x1') if `y1' == `y2'

	gen `alpha' = (acos(abs(`x2' - `x1')/`l'))
	replace `alpha' = acos(1) if `alpha' == .
	gen `beta' = _pi / 2 + `alpha'

	gen `x3n' = (`x1' + 1/2 * (`x2' - `x1')) 
	gen `x3' = `x3n' + `mult1' * cos(`beta') * `rad'
	gen `y3n' = (`y1' + 1/2 * (`y2' - `y1'))  
	gen `y3' = `y3n' + `mult2' * sin(`beta') * `rad'

	gen `r' = sqrt(`rad'^2 + (1/2*`l')^2)	
	gen `mult3' = 2 * (`x3' > `x1') - 1
	gen `gamma' =  `beta' + `mult3' * acos(`rad'/`r') 
	gen `delta' =  `beta' - `mult3' * acos(`rad'/`r') 
	
	gen `lid'  = _n
	expand `splines' if `unbend' !=1
	bys `lid': gen `llid' = _n
	gen `alphaX' = `delta' + (`gamma' - `delta') * (`llid' - 1)/(`splines' -1)
	gen `x4' = `x3' + `mult1'* cos(`alphaX' + _pi) * `r'
	gen `y4' = `y3' + `mult2'*sin(`alphaX' + _pi) * `r' 

	replace `x2' = `x4' if `unbend' != 1
	replace `y2' = `y4' if `unbend' != 1
	replace `x1' = `x4'[_n-1] if `unbend' != 1
	replace `y1' = `y4'[_n-1] if `unbend' != 1
	drop if `llid' == 1 & `unbend'!=1
	replace `arrow' = (`llid' == `splines') if (`arrow' != 1) & (`mult1' == 1)
	replace `arrow' = 1 if (`llid' == 2) & (`mult1' == - 1)
	
	gen `xtemp' = `x1'
	gen `ytemp' = `y1'
	replace `x1' = `x2' if (`llid' == 2) & (`mult1' == - 1)
	replace `y1' = `y2' if (`llid' == 2) & (`mult1' == - 1)
	replace `x2' = `xtemp' if (`llid' == 2) & (`mult1' == - 1)
	replace `y2' = `ytemp' if (`llid' == 2) & (`mult1' == - 1)
end

capture mata: mata drop fruchtrein()
capture mata: mata drop getTieCoordinates()
mata:
real matrix function getTieCoordinates(
	real matrix Coord, real matrix size, real matrix List, real matrix EColMat, real matrix ESizMat, real scalar sizefactor, real scalar doarrows, real scalar arrowgap)
{
	real matrix 	TC
	real scalar 	rad, i, radius, x1, y1, x2, y2, x3, y3, An, Op, Hy, cos_theta, sin_theta
	
	radius = ((size):* sizefactor) :+ arrowgap
	Coord = Coord :*100
	Coord = (Coord :*0.9) :+ 5
	TC = J(rows(List),8,.)

	for(i=1;i<=rows(TC);i++){
		rad = radius[List[i,2],1] 
		if (doarrows==0) {
			rad = 0
		}
		TC[i,1] = Coord[List[i,1],1] //start x of tie i
		TC[i,2] = Coord[List[i,1],2] //start y of tie i
		TC[i,3] = Coord[List[i,2],1] //end x of tie i
		TC[i,4] = Coord[List[i,2],2] //end y of tie i
		TC[i,5] = List[i,3] //value of tie
		TC[i,6] = List[i,4]
		TC[i,7] = EColMat[List[i,1],List[i,2]]
		TC[i,8] = ESizMat[List[i,1],List[i,2]] 
		
		//adjust end point of arrow for node size
		x1 = TC[i,1]
		y1 = TC[i,2]
		x2 = TC[i,3]
		y2 = TC[i,4]
		An = y2 - y1
		Op = x2 - x1
		Hy = sqrt(An*An + Op*Op)
		cos_theta = Op / Hy
		sin_theta = An / Hy
		x3 = x2 - (cos_theta*rad)
		y3 = y2 - (sin_theta*rad)
		TC[i,3] = x3
		TC[i,4] = y3
	}
	return(TC)	
}	
end

/*************************************
*	Obtain color for plotting
*************************************/
capture program drop _getcolorstyle
program def _getcolorstyle
	syntax [, i(string) j(string) mlcolor(string) mlwidth(string) colorpalette(string) symbolpalette(string) edgecolorpalette(string) edgepatternpalette(string) scheme(string)]

	mata: st_rclear()
	local i = `i' - 1
	local j = `j' - 1
	
	// symbol of node
	if ("`symbolpalette'" != ""){
		local symbolpalette_length : word count `symbolpalette'
		local k  = mod(`j', `symbolpalette_length') + 1
		local symbol : word `k' of `symbolpalette' 
	}
	else {
		local symbol `"scheme p`=`j'+1'"'
	}


	if "`scheme'" == "sj" & "`edgepatternpalette'" == "" {
		local edgepatternpalette "dash solid dot dash solid"
	}
	
	// pattern of edge
	if "`edgepatternpalette'" != "" {
		local edgepatternpalette_length : word count `edgepatternpalette'
		local m  = mod(`i', `edgepatternpalette_length') + 1
		local edgepattern : word `m' of `edgepatternpalette'
	}
	else {
		//local edgepattern = "solid"	
		local edgepattern `"scheme p`=`i'+1'linepattern"'
	}
	
	// color of edge
	if "`edgecolorpalette'" != "" {
		local edgecolorpalette_length : word count `edgecolorpalette'
		local j  = mod(`i', `edgecolorpalette_length') + 1
		local edgecol : word `j' of `edgecolorpalette' 
	}
	else {
		local edgecol `"scheme p`=`i'+1'line"'
		/*
		if (strpos("s1mono s2mono sj s1manual s2manual", "") != 0){
			local edgecol `"scheme p`=`i'+2'"'
		}*/
	}
	
	// color of node
	if "`colorpalette'" != "" {
		local colorpalette_length : word count `colorpalette'
		local j  = mod(`i', `colorpalette_length') + 1
		local col_fill : word `j' of `colorpalette' 
	}
	else {
		local col_fill `"scheme p`=`i'+1'"'
	}

	
	if "`mlcolor'" == "" {
		local col_line = "`col_fill'"
	}
	else {
		local col_line "`mlcolor'"
	}
	
	if "`mlwidth'" == "" {
		mata: st_global("r(line_width)", "vthin")
	}
	else {
		mata: st_global("r(line_width)", "`mlwidth'")
	}
	mata: st_global("r(edgepattern)", "`edgepattern'")
	mata: st_global("r(edgecol)", "`edgecol'")
	mata: st_global("r(col_fill)", "`col_fill'")
	mata: st_global("r(col_line)", "`col_line'")
	mata: st_global("r(symbol)", "`symbol'")
end


/*************************************
*	Network layouts functions (Mata)
*************************************/

capture mata: mata drop NumElist()
mata:
real matrix NumElist(matrix onenet){
	real scalar nodes, i
	real matrix id, full, c1, c2, value, c3, from, to, res
	nodes = rows(onenet)
	id = range(1,nodes,1)
	full = J(nodes, nodes, 1)
	c1=colshape(full:* id,1)
	c2=colshape(full:*(id'),1)
	value=colshape(onenet,1)
	c3 = value:/value
	_editmissing(c3,0)
	
	from = select(c1,c3)
	to = select(c2,c3)
	res = J(rows(from),4,0)
	// BUGFIX: on a network with zero ties anywhere (e.g. a single-node
	// network, where no off-diagonal pair can even exist), `from'/`to'
	// are genuinely 0x0 empty matrices - but `res[.,1]' is a 0x1
	// selection (0 rows still expects 1 column), and assigning a 0x0
	// matrix into a 0x1 target is itself a Mata conformability error,
	// even though both sides have zero elements. `res' is already the
	// correct (empty) result in this case, so the assignment is both
	// unnecessary and unsafe - skipped entirely when there is nothing
	// to assign.
	if (rows(from) > 0) {
		res[.,1] = from
		res[.,2] = to
		res[.,3] = select(value, c3)

		for (i = 1; i <= rows(from); i++) {
			res[i,4] = onenet[res[i,1], res[i,2]] != 0 & onenet[res[i,2], res[i,1]] != 0
		}
	}
	return(res)
}
end

// Attempt to implement spring embedder... but sth does not work yet :-(
capture mata: mata drop fruchtreinlayout()
mata:
real matrix function fruchtreinlayout(real matrix M, real scalar Iter)
{
	real matrix Pos, Pos_up, v_disp
	real scalar F_repulsion, F_attraction, e1,e2, i, u, v, W, L, area, V, temperature, k ,v_pos ,e1_pos, e2_pos, delta
	
	W = 1
	L = 1
	area = W * L
	V = rows(M)
	Pos = runiform(V,2)
	F_repulsion = J(V,2,0)
	F_attraction = J(V,2,0)
	
	temperature = 1/10 * W	
	k = sqrt(area/V)
	
	temperature = 0
	
	for(i=1;i<= Iter;i++){
		// calculate repulsive force
		for(v=1;v<=V;v++){
			v_disp = J(1,2,0)
			for(u=1;u<=V;u++){
				if (v!=u) {
					delta = Pos[v,.] - Pos[u,.]
					v_disp = v_disp + (delta :/ abs(delta)) :* ((J(1,2,1):*(k,k)) :/ abs(delta))  
				}
			}

			F_repulsion[v,.] = v_disp
		}

		Pos_up = F_repulsion
		// calculate attractive force
		for(e1=1;e1<=V;e1++){
			for(e2=1;e2<=V;e2++){
				if (M[e1,e2]!=0){		
					delta = Pos[e1,.] - Pos[e2,.]
					//delta
					e1_pos = Pos_up[e1,.] - (delta :/abs(delta)) :* ( (abs(delta):* abs(delta)):/ k)
					e2_pos = Pos_up[e2,.] + (delta :/abs(delta)) :* ( (abs(delta):* abs(delta)):/ k)		
					Pos_up[e1,.] = e1_pos
					Pos_up[e2,.] = e2_pos
				
				}
			}
		}
		// limit displacement
		for (v=1;v<=V;v++){
			delta = Pos_up[v,.] - Pos[v,.]	
			Pos[v,1] = Pos[v,1] + (delta[1,1] / abs(delta[1,1])) * min((abs(delta[1,1]), temperature))
			Pos[v,2] = Pos[v,2] + (delta[1,2] / abs(delta[1,2])) * min((abs(delta[1,2]), temperature))
			
			
			Pos[v,1] = min(( W, max((- W, Pos[v,1]))))
			Pos[v,2] = min(( L, max(( - L, Pos[v,2]))))
			
		}
		
		// reduce temperature linerarly
		temperature = temperature - (1 / 3)*temperature
	}
	return(Pos)
}
end

capture mata: mata drop mmdslayout()
mata:
real matrix function mmdslayout(real matrix G)
{
	real matrix 	D, sCoord, Coord
	string scalar 	dMat, sMat
	real scalar ScaleFactor, rc, CoordMin1, CoordMin2, CoordMax1, CoordMax2

	Coord  =  circlelayout(rows(G))
	if (rows(G) == 2) {
		Coord[1,1] = 0.5
		Coord[2,1] = 0.5
		Coord[1,2] = 0.75
		Coord[2,2] = 0.25
	}

	D = distance(G) //compute distances
	_diag(D,0)
	
	/*
	// correct for two nodes having the same distance scores to all others
	for (i = 1; i< rows(D); i++) {
		for (j = i;j<=rows(D); j++){
			thisrow = J(1,cols(D),1)
			thisrow[1,i] = 0
			thisrow[1,j] = 0
			diff = select(D[i,.],thisrow) - select(D[j,.],thisrow)
			if ((sum(abs(diff)) == 0) & (i != j)){
				
				//dd_i = (J(1,i,1),J(1, (cols(D) - i),.5)) 
				//dd_j = (J(1,j,0),J(1, (cols(D) - j),.5))
				//D[i,j] = 3
				//D[j,i] = 3
				//D_i =  D[i,.] :* ((uniform(1,cols(D)):*0.5):+0.75)
				/*
				D[i,.] = D[i,.]:+ dd_i
				D[.,i] = D[.,i]:+ (dd_i)'
				D[j,.] = D[j,.]:+ dd_j
				D[.,j] = D[.,j]:+ (dd_j)'*/
				//D[i,j] = 3.2
				//D[j,i] = 3.2
				
				//D[i,.] = D[i,.] :+ J(1,cols(D), .5)
				//D[.,i] = D[.,i] :+ J(cols(D),1, .7)
				//D[j,.] = D[j,.] :+ J(1,cols(D), .8)
				//D[.,j] = D[.,j] :+ J(cols(D),1, .8)
				//D[i,.] = D_i
				//D[.,i] = D_i'
			}
		}
	}
	_diag(D,0)*/
	
	st_matrix("dMat",D) 	    //Distance mat to stata under tempname
	// compute MDS coordinates in stata
	rc = _stata( "  mdsmat dMat,  force noplot method(classical)", 1)
				//" di `test_rc")
	if (rc == 0) {
		Coord = st_matrix("e(Y)") 
		CoordMin1 = min(Coord[.,1])
		CoordMin2 = min(Coord[.,2])
		Coord[.,1] = (Coord[.,1] :- CoordMin1)
		Coord[.,2] = (Coord[.,2] :- CoordMin2)
	
		CoordMax1 = max(Coord[.,1])
		CoordMax2 = max(Coord[.,2])
		Coord[.,1] = (((Coord[.,1] :/ CoordMax1))) 
		Coord[.,2] = (((Coord[.,2] :/ CoordMax2)))
	}
	return(Coord)
}
end

capture mata: mata drop correctCoordClash()
mata: 
real matrix function correctCoordClash(real matrix Coord, real matrix net, real scalar b, real scalar prox){ 
	real matrix Coord_new, Ck, Ci
	real scalar i,j,k,x,y, angle
	Coord_new = Coord
	for(i = 1 ; i <= rows(Coord); i++) {
		for(j = (i + 1) ; j <= rows(Coord); j++) {
			//abs(Coord[i,1] - Coord[j,1])
			//abs(Coord[i,2] - Coord[j,2])
			//"next"
			if ((abs(Coord[i,1] - Coord[j,1]) <= prox) & (abs(Coord[i,2] - Coord[j,2]) <= prox)){
				Coord[i,1]
				Coord[j,1]				

			//& (Coord[i,2] == Coord[j,2])) {
				for (k = 1; k <= cols(net); k++) {
					if (net[k,i] != 0) {
						Ck = Coord[k,.]
						Ci = Coord[i,.]
						x = Ck[1,1] - Ci[1,1]
						y = Ck[1,2] - Ci[1,2]
						angle = atan2(y,x)
						Coord_new[i,2] = Coord_new[i,2] - sin(angle) * b
						Coord_new[i,1] = Coord_new[i,1] + cos(angle) * b
						Coord_new[j,2] = Coord_new[j,2] + sin(angle) * b
						Coord_new[j,1] = Coord_new[j,1] - cos(angle) * b
					}
				}
			}
		}
	}
	return(Coord_new)
}
end

capture mata: mata drop netplotmds()
mata:
real matrix function netplotmds(real matrix G, real scalar MaxIt)
{
        real matrix     D, sCoord, Coord
        string scalar   dMat, sMat
        real scalar ScaleFactor, rc, maxSX, maxSY, maxX, minX, maxY, minY, num_isol, maxYY, k,i, nonisolates 
        
		G = (G + G') :/ (G + G')
		_editmissing(G, 0)
		_diag(G,0)
		
        Coord  =  J(rows(G),2,.)
        sCoord = jumble(circlelayout(rows(G))) //circle coordinates as starting positions for mds
	    maxSX = max(sCoord[,1])
		maxSY = max(sCoord[,2])
		
        D = distance(G) //compute distances
        _diag(D,0)
		
        st_matrix(dMat=st_tempname(),D)         //Distance mat to stata under tempname
        st_matrix(sMat=st_tempname(),sCoord)    //Distance mat to stata under tempname

        // compute MDS coordinates in stata
        rc = _stata(  "qui mdsmat " + 
                dMat + 
                ", noplot method(modern) initialize(from(" + 
                sMat + 
                ")) iterate("+strofreal(MaxIt)+")" )
        
        if (rc!=0) {
                errprintf("mds computation failed \n")
                exit(rc)
        }

        Coord = st_matrix("e(Y)")       //pull coordinates back into mata
        
        // rescale coordinates to fit inside circle layout
		
		nonisolates = (rowsum(G):!= 0)
		
		maxX = max(select(Coord[.,1], nonisolates))
		minX = min(select(Coord[.,1], nonisolates))
		maxY = max(select(Coord[.,2], nonisolates))
		minY = min(select(Coord[.,2], nonisolates))

		Coord[,1] = (nonisolates :*(Coord[,1]:-minX) :* (1 / (maxX-minX)) :+ 0.25) :+ ((nonisolates:==0) :* Coord[,1])
		Coord[,2] = (nonisolates :*(Coord[,2]:-minY) :* (1 / (maxY-minY))) :+ ((nonisolates:==0):*Coord[,2])
		
		num_isol = sum( nonisolates:==0)
		maxYY = max(Coord[,2])
		
		k = 1
		for ( i = 1; i <= rows(G); i++) {
			if (nonisolates[i] == 0) {
			   Coord[i,1]=1.5
			   Coord[i,2]= (k / num_isol)
			   k = k + 1
			}
		}
		
        return(Coord)
}
end


//Calculates the distance matrix in a discrete graph
//Distances between unconnecte nodes are indicated by "0"
capture mata: mata drop distance()
mata:
real matrix function distance(real matrix Net, | real scalar MaxDist)
{
	real scalar 	maxdist, ready,counter, maxcounter
	real matrix 	N1,Dist,Ntemp
	
	if (args()==2) 
		maxcounter = MaxDist
	else 
		maxcounter = rows(Net)-1
	
	// Undirected network
	Net = (Net + Net') :/ (Net + Net')
	_editmissing(Net, 0)
	
	N1 = Net
	Dist = Net	//Distance 1 matrix
	counter = 1
	ready = 0
	while (ready==0 & counter<maxcounter) {
		counter = counter + 1
		N1=(N1*Net)
		Ntemp = (Dist:==0):*(N1:>0):*counter
		if (sum(Ntemp)==0) ready = 1
		Dist = Dist:+Ntemp
	}
	//Dist = (Dist:==0):* (runiform(rows(Dist), cols(Dist))) :+ Dist 
	maxdist = max(Dist)
	Dist = (Dist:==0):* (maxdist + 1) :+ Dist
	_diag(Dist, 0)
	return(Dist)
}
end

capture mata: mata drop circlelayout()
mata:
real matrix function circlelayout(real scalar N)
{
	real colvector 	V
	real matrix 	Coord
	real scalar 	xmax, ymax, CoordMax1, CoordMax2

	xmax = 100
	ymax = 100
	V= (1::N)
	Coord=J(N,2,.)

	Coord[.,1] = 0.5*xmax :+ 0.5:*xmax:*cos(V[.]:*(2*pi()/N))	
	Coord[.,2] = 0.5*ymax :+ 0.5:*ymax:*sin(V[.]:*(2*pi()/N))

	CoordMax1 = max(Coord[.,1])
	CoordMax2 = max(Coord[.,2])
	Coord[.,1] = (((Coord[.,1] :/ CoordMax1)))
	Coord[.,2] = (((Coord[.,2] :/ CoordMax2)))
	Coord[.,1] = Coord[.,1] :+0.25
	return(Coord)
}
end

capture mata: mata drop gridlayout()
mata:
real matrix function gridlayout(real scalar N,  real scalar cols)
{
	real colvector 	V, C
	real matrix 	Coord
	real scalar CoordMax1, CoordMax2, rows

	V= (1::N)
	rows = ceil(N / cols)
	
	Coord=J(N,2,.)
	Coord[.,1] = J(N,1,100) :- floor((V:-1) :/rows) :* (100 / (cols - 1))
	
	Coord[.,2] = mod(V, rows)
	
	Coord[.,2] = editvalue(Coord[.,2],0,rows)
    Coord[.,2] = J(N,1,100) :- ((Coord[.,2] :- 1) :* (100 / (rows - 1)))
	
	if (rows == 1) {
		Coord[.,2] = J(cols, 1, 0.5)
	}
	CoordMax1 = max(Coord[.,1])
	CoordMax2 = max(Coord[.,2])
	Coord[.,1] = (((Coord[.,1] :/ CoordMax1)))
	Coord[.,2] = (((Coord[.,2] :/ CoordMax2)))
	Coord[.,1] = Coord[.,1] * 1.5
	
	return(Coord)
}



real matrix function fruchtrein(real matrix M, real scalar Iter)
{
 real matrix Pos, Disp
 real vector delta
 real scalar radius, i, v,u,e1,e2,W, L, area, V, temperature, k, r
 W = 2
 L = 2
 area =  W*L
 radius= min((W,L))/2 
 V = rows(M)
 Pos = runiform(V,2):-.5  
 Pos[.,1]=floor(W):*runiform(V,1):-W/2 // Initial random position W
 Pos[.,2]=floor(L):*runiform(V,1):-L/2 // Initial random position L
 Disp = J(V,2,0)
 temperature = W/3
 k = sqrt(area/V)


	
 for(i=1;i<= Iter;i++){
 
// calculate repulsive force
	for(v=1;v<=V;v++){
	  for(u=1;u<=V;u++){
		if (v!=u) {
		 delta = Pos[v,.] - Pos[u,.]
		 Disp[v,.] = Disp[v,.] + (delta / norm(delta)) * ((k^2)/norm(delta))
		 }
	  }
	}

// calculate attractive force
	for(e1=1;e1<=V;e1++){
	   for(e2=e1+1;e2<=V;e2++){
		 if (M[e1,e2]!=0){		
		  delta = Pos[e1,.] - Pos[e2,.]
		  Disp[e1,.] = Disp[e1,.] - (delta /norm(delta)) * ( (norm(delta)* norm(delta))/ k)
		  Disp[e2,.] = Disp[e2,.] + (delta /norm(delta)) * ( (norm(delta)* norm(delta))/ k)		
		 }
	   }
	}

// Limit the maximum displacement to the temperature t
		for(v=1;v<=V;v++){
		   Pos[v,.]=Pos[v,.]+(Disp[v,.]/norm(Disp[v,.])*min((norm(Disp[v,.]),temperature)))
		   if (norm(Pos[v,.])>radius) Pos[v,.]=radius*Pos[v,.]/(norm(Pos[v,.]))
		   }
// Reduce temperature
    temperature = temperature - temperature/10
 }
return(Pos)
}

end
