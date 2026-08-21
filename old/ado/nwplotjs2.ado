/***
{smcl}
{* *! version 2.0.0  2april2014}{...}
{marker topic}
{helpb nw_topical##visualization:[NW-2.8] Visualization}

{title:Title}

{p2colset 9 15 22 2}{...}
{p2col :nwplotjs {hline 2} Plot a network with JavaScript}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwplotjs}
[{it:{help netname}}] 
[{cmd:,} {it:{help nwplotjs##node_options:node_options}}
{it:{help nwplotjs##label_options:label_options}}
{it:{help nwplotjs##edge_options:edge_options}}
{it:{help nwplotjs##arrow_options:arrow_options}}
{it:{help nwplotjs##layout_options:layout_options}}
{it:{help nwplotjs##other_options:other_options}}]
	
{synoptset 20}{...}
{p2col:{it:options}}Description{p_end}
{p2line}
{p2col:{it:{help nwplotjs##node_options:node_options}}}change look of
       nodes (size, color, symbol){p_end}
{p2col:{it:{help nwplotjs##label_options:label_options}}}display and change look of
       node labels{p_end}
{p2col:{it:{help nwplotjs##edge_options:edge_options}}}change look of 
       edges (size, color){p_end}
{p2col:{it:{help nwplotjs##arrow_options:arrow_options}}}change look of
       arrows{p_end}
{p2col:{it:{help nwplotjs##layout_options:layout_options}}}change the layout or use existing coordinates{p_end}
{p2col:{it:{help nwplotjs##other_options:other_options}}}other network plot options
		{p_end}
{p2col:{it:{help twoway_options}}}normal twoway options for the whole plot
		{p_end}
	

{synoptset 35 tabbed}{...}
{p2col:{it:node_options}}Description{p_end}
{marker node_options}{...}
{p2line}
{synopt:{opt size}({it:{help varname}} [,{it:{help nwplotjs##node_sub:node_sub}}])}size of the nodes{p_end}
{p2col:{opt color}({it:{help varname}} [,{it:{help nwplotjs##node_sub:node_sub}}])}color of the nodes{p_end}
{p2col:{opt symbol}({it:{help varname}} [,{it:{help nwplotjs##node_sub:node_sub}}])}symbol of the nodes{p_end}
{p2col:{opth nodefactor(float)}}multiply all node sizes by a factor{p_end}


{synoptset 35 tabbed}{...}
{p2col:{it:node_sub}}Description{p_end}
{marker node_sub}{...}
{p2line}
{p2col:{opt colorpalette}({it:{help nwplotjs##colorstyle:colorstyle}}...)}list with colorstyles; change colorpalette{p_end}
{p2col:{opt symbolpalette}({it:{help nwplotjs##symbolstyle:symbolstyle}}...)}list with symbolstyles; change symbolpalette{p_end}
{p2col:{opth mlcolor(colorstyle)}}lcolor of nodes{p_end}
{p2col:{opth minnodesize(real)}}size of smallest node; default = 3{p_end}
{p2col:{opth maxnodesize(real)}}size of largest node; default = 5{p_end}


{synoptset 35 tabbed}{...}
{p2col:{it:label_options}}Description{p_end}
{marker label_options}{...}
{p2line}
{synopt:{opt label}([{it:{help varname}}] [,{it:{help nwplotjs##label_sub:label_sub}}])}display node labels from variable and change label options{p_end}
{p2col:{opt lab}}display node labels saved with network{p_end}


{synoptset 35 tabbed}{...}
{p2col:{it:label_sub}}Description{p_end}
{marker label_sub}{...}
{p2line}
{p2col:{opth labelfactor(real)}}multiply the size of all labels by factor{p_end}
{p2col:{opth labelsize(string)}}"fixed" or "proportional" (size of label proportional to node size){p_end}
{p2col:{opth labelthreshold(real)}}threshold about which labels (size) should be shown; default = 1 (all){p_end}
{p2col:{opt labelcolor}({it:{help nwplotjs##colorstyle:colorstyle}})}HEX color of label{p_end}
{p2col:{opt labelcolormode(string)}}"default" or "node" (use color of node){p_end}
{p2col:{opth font(string)}}font for label; default = "arial"{p_end}
{p2col:{opth labelsizeratio(real)}}ratio of label size to node size; default = 1{p_end}


{synoptset 35 tabbed}{...}
{p2col:{it:edge_options}}Description{p_end}
{marker edge_options}{...}
{p2line}

{p2col:{opt edgecolor}({it:{help netname}} [,{it:{help nwplotjs##edge_sub:edge_sub}}])}change color of edges with data from other network{p_end}
{p2col:{opt edgesize}({it:{help netname}} [,{it:{help nwplotjs##edge_sub:edge_sub}}])}change size of edges with data from other network{p_end}
{p2col:{opt edgepattern}({it:{help netname}} [,{it:{help nwplotjs##edge_sub:edge_sub}}])}change the pattern edges with data from other network{p_end}
{p2col:{opth edgecurve(netname)}}change the curvature for each edge individually based on other network{p_end}
{p2col:{opth edgefactor(float)}}multiply all edge sizes by a factor{p_end}
{p2col:{opth edgecurvefactor(float)}}change the curvature of each each; default = 1{p_end}


{synoptset 35 tabbed}{...}
{p2col:{it:edge_sub}}Description{p_end}
{marker edge_sub}{...}
{p2line}
{p2col:{opth minedgesize(real)}}size of thinest edge; default = 1{p_end}
{p2col:{opth maxedgesize(real)}}size of thickest edge; default = 2{p_end}
{p2col:{opt edgecolorpalette}({it:{help nwplotjs##colorstyle:colorstyle}}...)}list with colorstyles; change edgecolorpalette{p_end}
{p2col:{opt edgepatternpalette}({it:{help nwplotjs##patternstyle:patternstyle}}...)}list with colorstyles; change edgecolorpalette{p_end}
	
	
{synoptset 35 tabbed}{...}
{p2col:{it:arrow_options}}Description{p_end}
{marker arrow_options}{...}
{p2line}
{p2col:{opt arcstyle}({it:{help nwplotjs##arcstyle:arcstyle}})}change the look of arcs (curved, straight){p_end}
{p2col:{opth arrowfactor(float)}}multiply arrowhead by a factor{p_end}


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


{synoptset 40 tabbed}{...}
{p2col:{it:layout_options}}Description{p_end}
{marker layout_options}{...}
{p2line}
{p2col:{cmd: layout}([{it:{help nwplotjs##layoutstyle:layoutstyle}}] [,{it:{help nwplotjs##layout_sub:layout_sub}}])}change the overall layout/arrangement of nodes{p_end}
{p2col:{opt nodexy}({it:{help varname:xvar} {help varname:yvar}})}use variables to force coordinates of nodes{p_end}


{synoptset 35 tabbed}{...}
{p2col:{it:layout_sub}}Description{p_end}
{marker layout_sub}{...}
{p2line}
{p2col:{opt lgc}}only plot largest component{p_end}
{p2col:{opth columns(int)}}only relevant for layout = grid; number of columns to be plotted in grid layout {p_end}


{synoptset 35 tabbed}{...}
{p2col:{it:other_options}}Description{p_end}
{marker other_options}{...}
{p2line}
{p2col:{opt background}({it:{help nwplotjs##colorstyle:colorstyle}})}color of background{p_end}
{p2col:{opth with(int)}}width of exported PNG or SVG{p_end}
{p2col:{opt noexport}}no buttons to export plot as PNG or SVG{p_end}
{p2col:{opt replace}}overwrite plot saved as HTML{p_end}
{p2col:{opt legend}}display legend{p_end}
{p2col:{opt linkurious(path)}}path of local linkurious installaton; by default it uses the web, i.e. an internet connection is required{p_end}

	
{synoptset 35 tabbed}{...}
{marker symbolstyle}{...}
{p2col:{it:symbolstyle}}{p_end}
{p2line}
{p2col:{cmd: circle}}{p_end}
{p2col:{cmd: diamond}}{p_end}
{p2col:{cmd: square}}{p_end}
{p2col:{cmd: star}}{p_end}
{p2col:{cmd: quilateral}}{p_end}
{p2col:{cmd: cross}}{p_end}

		
{synoptset 35 tabbed}{...}
{marker colorstyle}{...}
{p2col:{it:colorstyle}}{p_end}
{p2line}
{pmore}
HEX color codes, e.g. {cmd: #00000} or {cmd: #FFFFF}{p_end}


{synoptset 35 tabbed}{...}
{marker patternstyle}{...}
{p2col:{it:patternstyle}}{p_end}
{p2line}
{p2col:{cmd: line}}{p_end}
{p2col:{cmd: dashed}}{p_end}
{p2col:{cmd: dotted}}{p_end}
{p2col:{cmd: parallel}}{p_end}
{p2col:{cmd: tapered}}{p_end}
{p2col:{cmd: curve}}{p_end}
{p2col:{cmd: arrow}}{p_end}
{p2col:{cmd: curvedArrow}}{p_end}


{synoptset 35 tabbed}{...}
{marker layoutstyle}{...}
{p2col:{it:layoutstyle}}{p_end}
{p2line}
{p2col:{cmd: fruchterman}}Fruchterman-Reingold algorithm; default{p_end}
{p2col:{cmd: random}}random x, y coordinates{p_end}
{p2col:{cmd: circle}}circle layout
		{p_end}
{p2col:{cmd: grid}}grid layout
		{p_end}
{p2col:{cmd: nodexy}}use coordinates given in {opt nodexy()}; only needed to send options.
		{p_end}
		
		
{title:Description}

{pstd}
This command plots a network with JavaScript and displays it in your browser. It generates a HTML file in your working directory, which
uses JavaScript libraries from the nwcommands server, i.e. you need to have a working internet connection to display the plot. Alternatively, you can
specify a path to a local installation of Linkurious, which is required for displaying the HTML. You can download Linkurious for offline use
from here.

{pstd}
Single nodes, but also the whole network, can be moved around. Similarly, one can pinch and zoom. By default, the command adds
"export buttons" to produce PNG or SVG files. The option {bf:noexport} surpresses these buttons.

{pstd}
This example generates a random network and plots it. When no {help netname} is given, the command refers to the
{help nwcurrent:current network}.

	{cmd:. nwclear}
	{cmd:. nwrandom 20, prob(.2)}
	{cmd:. nwplotjs}

{pstd}
Arrowheads are plotted when a network is directed. Furthermore, the command notices if a dyad is mutually or 
asymmetrically connected (see {help nwdyads}). By default, asymmetrically connected dyads are represented as a straight line, whereas
mutually connecetd dyads are represented as two curved lines. However, one can overwrite this and show all ties as 
curved (or straight) lines.

	{cmd:. nwplotjs, arcstyle(automatic)}
	{cmd:. nwplotjs, arcstyle(straight)}
	{cmd:. nwplotjs, arcstyle(curved)}

{pstd}
Almost all elements in a network plot can be easily made bigger or smaller using factors:

	{cmd:. nwplotjs, nodefactor(4)}
	{cmd:. nwplotjs, edgefactor(4)} 
	{cmd:. nwplotjs, arrowfactor(4)}

{phang2}	
	{cmd:. nwplotjs, nodefactor(2) edgefactor(4) arrowfactor(2)}{p_end}

{pstd}
Colors, symbols and size of nodes can be changed accoring to a {help varname}. Furthermore, the palettes used for display
can be changed as well. 

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwplotjs flomarriage, color(seat)}
	{cmd:. nwplotjs flomarriage, color(seat, colorpalette(#6DC20F #FFC200))}
 
	{cmd:. nwplotjs flomarriage, symbol(seat)}
	{cmd:. nwplotjs flomarriage, symbol(seat, symbolpalette(diamond star))}

	{cmd:. nwplotjs flomarriage, size(wealth)}
 
	{cmd:. nwplotjs flomarriage, size(wealth) color(seat) symbol(seat)}
	

{pstd}
This example uses the information stored in the network "flobusiness" to color the edges of the network
"flomarriage". Furthermore, it uses the same information to change the size of the edges. 

	{cmd:. nwplotjs flomarriage, edgecolor(flobusiness) edgesize(flobusiness)}

{pstd}
Here, the nodes are plotted with the node labels saved with the network:
	
	{cmd:. nwplotjs flobusiness, lab}
	
{pstd}
More generally, one can use any {it:varname} as node label.

	{cmd:. nwplotjs flobusiness, label(wealth)}


{pstd}
The next example shows how to only plot the largest component of the network "flomarriage".	

	{cmd:. nwplotjs flomarriage, layout(,lgc)}

	{pstd}
Notice that you could have achieved the same thing by creating a new network that only has the largest component:

	{cmd:. nwgen flolarge = lgc(flomarriage)}
	{cmd:. nwplotjs flolarge }

		{pstd}
There are different layout alogorithms implemented; the default is Fruchterman-Reingold.

	{cmd:. nwplotjs flomarriage, layout(fruchterman)}
	{cmd:. nwplotjs flomarriage, layout(circle)}
	{cmd:. nwplotjs flomarriage, layout(grid, columns(5))}
	{cmd:. nwplotjs flomarriage, layout(random)}

	{pstd}
You can also use pre-existing coordinates. For example, this generates random coordinates xcor and ycor.

	{cmd:. gen xcor = uniform()}
	{cmd:. gen ycor = uniform()}
	{cmd:. nwplotjs flomarriage, layout(nodexy) nodexy(xcor ycor)}
		
	
{title:See also}

	{help nwplot}

***/

capture program drop nwplotjs
program nwplotjs
	syntax [anything(name = netname)] [, edgecurve(string) edgecurvefactor(real 1) width(int 3000) settings(string) layout(string) nodexy(varlist numeric min=2 max=2) background(string) legend symbol(string) lab labelfactor(real 1)  noexport edgefactor(real 1) nodefactor(real 1) arrowfactor(real 1) arcstyle(string) replace color(string) edgecolor(string) edgesize(string) edgepattern(string) linkurious(string) label(string) size(string) fname(string)]
	
	local replace "replace"
	unw_defs
	
	
	nw_syntax `netname'
	local orig_netobj "`netobj'"
	local orig_netname "`netname'"
	local orig_directed "`directed'"
	
	if "`fname'" == "" {
		local fname = "`orig_netname'"
	}
	local fname "`fname'.html"
	capture erase `fname'
	
	nw_datasync `netname'
	local undirected = "`directed'" == "false"
	
	preserve
	
	qui keep if `nw_included' == 1
	 
	if "`linkurious'" == "" {
		local linkurious = "http://nwcommands.org/linkurious/"
	}
	
	local nodesize_use 0
	local nodecolor_use 0
	local nodesymbol_use 0
	

	if "`background'" == "" {
		local background "#ffffff"
	}
	
	local arrowfactor = `arrowfactor' * 8
	if "`arcstyle'" == "" {
		local arcstyle = "automatic"
	}

	local 0 "`label'"
	local nodelabel_use 0
	syntax [varlist(default=none max=1)], [ labelfactor(real 1) labelsize(string) labelthreshold(real 1) labelcolor(string) labelcolormode(string) font(string) labelsizeratio(real 1)]
	local label "`varlist'"
	local defaultlabelsize = int(`labelfactor' * 14)
	if "`labelsize'" == "" {
		local labelsize = "fixed"
	}
	_opts_oneof "fixed proportional" "labelsize" "`labelsize'" 6556
	
	if "`labelcolormode'" == "" {
		local labelcolormode = "default"
	}
	_opts_oneof "default node" "labelcolormode" "`labelcolormode'" 6556
	
	if "`font'" == "" {
		local font = "arial"
	}
	tempvar labelstr
	qui if "`label'" != "" {
		local nodelabel_use = 1
		tostring `label', generate(`labelstr')
		capture confirm variable `labelstr'
		if _rc == 0 {
			local label "`labelstr'"
		}
	}
	
	local 0 = "`size'"
	syntax [varlist(default=none max=1)] , [ minnodesize(real 3.0) maxnodesize(real 5)]
	local size "`varlist'"
	if "`size'" != "" {
		local maxnodesize = `maxnodesize' * 2.5
		local nodesize_use 1
		local sizelabel :  variable label `size'
		if "`sizelabel'" == "" {
			local sizelabel "`size'"
		}
	}
	local maxnodesize = `maxnodesize' * `nodefactor'
	tempvar s
	gen `s' = 1
	capture replace `s' = `varlist'

	local 0 = "`symbol'"
	tempname symbolcodes symbolpalette_matrix
	mata: `symbolcodes' = "z"
	syntax [varlist(default=none max=1)], [symbolpalette(string)]
	if "`symbolpalette'" == "" {
		local symbolpalette = "circle square diamond star quilateral cross"
	}
	local symbol_first : word 1 of `symbolpalette'
	mata: `symbolpalette_matrix' = J(1,1,"`symbol_first'")
	local symbol "`varlist'"
	if "`symbol'" != "" {
		local nodesymbol_use 1
		local symbollabel :  variable label `symbol'
		if "`symbollabel'" == "" {
			local symbollabel "`symbol'"
		}
		tempvar symbtemp
		tempvar symbstr
		capture tostring `symbol', force generate(`symbstr')
		if _rc == 0 {
			capture confirm string variable `symbol'
			if _rc != 0 {
				local symbol `symbstr'
			}
		}
		
		mata: `symbolcodes' = (uniqrows(st_sdata((1::`nodes'), "`symbol'")))'
		mata: st_numscalar("r(max)", cols(`symbolcodes'))5
		mata: `symbolpalette_matrix' = J(1,`r(max)',"z")
		forvalues i = 1/`r(max)' {
			local l : label `symbol' `i'
			local symbol_i : word `i' of `symbolpalette'
			mata: `symbolpalette_matrix'[`i'] = "`symbol_i'"
		}
	}
	
	local 0 = "`color'"
	tempname colorcodes colorpalette_matrix 
	mata: `colorcodes' = "z"
	syntax [varlist(default=none max=1)] , [ colorhover(string) colorpalette(string) mlcolor(string)]
	if "`colorpalette'" == "" {
		local colorpalette = "#C70039 #0000ff #009933 #ffcc00 #ff00ff #33ccff #996633"
	}
	local color_first : word 1 of `colorpalette'
	mata: `colorpalette_matrix' = J(1,1,"`color_first'")
	local color `varlist'
	if "`color'" != "" {
		local nodecolor_use 1
		local colorlabel :  variable label `color'
		if "`colorlabel'" == "" {
			local colorlabel "`color'"
		}
	
		tempvar colstr
		capture tostring `color', generate(`colstr')
		if _rc == 0 {
			capture confirm string variable `color'
			if _rc != 0 {
				local color `colstr'
			}
		}
		mata: `colorcodes' = (uniqrows(st_sdata((1::`nodes'), "`color'")))'
		mata: st_numscalar("r(max)", cols(`colorcodes'))
		mata: `colorpalette_matrix' = J(1,`r(max)',"z")
		forvalues i = 1/`r(max)' {
			local l : label `color' `i'
			local color_i : word `i' of `colorpalette'
			mata: `colorpalette_matrix'[`i'] = "`color_i'"
		}
	}

	if "`colorhover'" == "" {
		local colorhover "#000"
	}
	if "`mlcolor'" == "" {
		local mlcolor = word("`colorpalette'", 1)
	}


	local netname `netname2'
	qui nw_datasync `netname'
	nw_syntax `netname'
   
    local 0 = "`layout'"
	syntax [anything], [columns(real 0) lgc]
	local layout "`anything'"
	tempname _lgc
	local lgc_use 0
	if "`lgc'" != "" {
		mata: `_lgc' = `orig_netobj'->calculate_lgc()
		local lgc_use 1
	}
	else {
		mata: `_lgc' = J(1,1,0)
	}
	if `columns' == 0 {
		local columns = ceil(sqrt(`nodes'))
	}
	if "`layout'" == "" {
		local layout = "fruchterman"
	}
   	_opts_oneof "grid circle fruchterman nodexy random" "layout" "`layout'" 6556
	
	tempvar xcoord
	tempvar ycoord
	tempvar z
	
	if "`nodexy'" != "" {
		local layout "nodexy"
	}
	
	if "`nodexy'" == "" & "`layout'" == "nodexy" {
		local layout "fruchterman"
		di "{txt}No {res}nodexy(varname varname){txt} specified. Selected layout {res}fruchterman{txt} instead."
	}
	
	if "`layout'" == "nodexy" {
		local x : word 1 of `nodexy'
		local y : word 2 of `nodexy'
		gen `xcoord' = `x'
		gen `ycoord' = `y'
	}
	else if "`layout'" == "circle" {
		gen `z' = _n / `nodes'
		gen `xcoord' = sin(`z' * 2 * _pi)
		gen `ycoord' = cos(`z' * 2 * _pi)
	}
	else if "`layout'" == "grid" {
		gen `z' = _n
		gen `xcoord' = mod(`z'-1, `columns')
		gen `ycoord' = ceil(`z' / `columns')
	}
	else if "`layout'" == "random" | "`layout'" == "fruchterman"{
		gen `xcoord' = uniform()
		gen `ycoord' = uniform()
	}
	
	///////////////////////
	///   NODES
	///////////////////////
	
	///////////////////////
	///   EDGES
	//////////////////////
	
	tempname p
	mata: `p' = &1
	
	local edgesize_use 0
	local edgecolor_use 0
	local edgepattern_use 0
	local edgecurve_use 0
	
	// Edge size
	local 0 "`edgesize'"
	syntax [anything(name=edgesize)], [minedgesize(real 1) maxedgesize(real 2)]
	local maxedgesize = `maxedgesize' * `edgefactor'
	if "`edgesize'" != "" {
		nw_syntax `edgesize'
		local edgesize `netobj'
		local edgesize_use 1
		mata: st_numscalar("r(matchok)", (`edgesize'->get_nodenames() == `orig_netobj'->get_nodenames()))
		if `r(matchok)' == 0 {
			noi di "{pstd}{pstd}{txt}Warning! Networks {bf:`orig_netname'} and {bf:`edgesize'} consist of different nodes or are differently sorted. Option {bf:edgesize()} is ignored." 
			local edgesize_use 0
		}
	}
	else {
		local edgesize `p'
	}
	
	// Edge color
	local 0 "`edgecolor'"
	syntax [anything(name=edgecolor)], [edgecolorhover(string) edgecolorpalette(string)]
	if "`edgecolorhover'" == "" {
		local edgecolorhover "#000"
	}
	if "`edgecolorpalette'" == "" {
		local edgecolorpalette = "#C8C8C8 #0033cc #009933 #ffcc00 #ff00ff #33ccff #996633"
	}
	local edgecolorpalette_num : word count `edgecolorpalette'
	tempname edgecolor_palette
	mata: `edgecolor_palette' = J(1, `edgecolorpalette_num', "")
	forvalues i = 1 / `edgecolorpalette_num' {
		local temp : word `i' of `edgecolorpalette'
		mata: `edgecolor_palette'[`i'] = "`temp'"
	}
	if "`edgecolor'" != "" {
		nw_syntax `edgecolor'
		local edgecolor `netobj'
		local edgecolor_use 1
		mata: st_numscalar("r(matchok)", (`edgecolor'->get_nodenames() == `orig_netobj'->get_nodenames()))
		if `r(matchok)' == 0 {
			noi di "{pstd}{pstd}{txt}Warning! Networks {bf:`orig_netname'} and {bf:`edgecolor'} consist of different nodes or are differently sorted. Option {bf:edgecolor()} is ignored." 
			local edgecolor_use 0
		}
	}
	else {
		local edgecolor `p'
	}
	
	// Edge pattern
	local 0 "`edgepattern'"
	syntax [anything(name=edgepattern)], [ edgepatternpalette(string)]
	if "`edgepatternpalette'" == "" {
		local edgepatternpalette "solid dashed dotted"
	}
	local edgepatternpalette_num : word count `edgepatternpalette'
	tempname edgepattern_palette
	mata: `edgepattern_palette' = J(1, `edgepatternpalette_num', "")
	forvalues i = 1 / `edgepatternpalette_num' {
		local temp : word `i' of `edgepatternpalette'
		mata: `edgepattern_palette'[`i'] = "`temp'"
	}
	if "`edgepattern'" != "" {
		nw_syntax `edgepattern'
		local edgepattern `netobj'
		local edgepattern_use 1
		mata: st_numscalar("r(matchok)", (`edgepattern'->get_nodenames() == `orig_netobj'->get_nodenames()))
		if `r(matchok)' == 0 {
			noi di "{pstd}{pstd}{txt}Warning! Networks {bf:`orig_netname'} and {bf:`edgepattern'} consist of different nodes or are differently sorted. Option {bf:edgepattern()} is ignored." 
			local edgepattern_use 0
		}
	}
	else {
		local edgepattern `p'
	}
	
	if "`edgecurve'" != "" {
		nw_syntax `edgecurve'
		local edgecurve `netobj'
		local edgecurve_use 1
		mata: st_numscalar("r(matchok)", (`edgecurve'->get_nodenames() == `orig_netobj'->get_nodenames()))
		if `r(matchok)' == 0 {
			noi di "{pstd}{pstd}{txt}Warning! Networks {bf:`orig_netname'} and {bf:`edgecurve'} consist of different nodes or are differently sorted. Option {bf:edgecurve()} is ignored." 
			local edgecurve_use 0
		}
	}
	else {
		local edgecurve `p'
	}

	tempname expfile
	file open `expfile' using "`fname'", write `replace'
	
	file write `expfile' `"<script src="`linkurious'/src/sigma.core.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/conrad.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/utils/sigma.utils.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/utils/sigma.polyfills.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/sigma.settings.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/classes/sigma.classes.dispatcher.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/classes/sigma.classes.configurable.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/classes/sigma.classes.graph.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/classes/sigma.classes.camera.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/classes/sigma.classes.quad.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/captors/sigma.captors.mouse.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/captors/sigma.captors.touch.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/sigma.renderers.canvas.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/sigma.renderers.webgl.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/sigma.renderers.svg.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/sigma.renderers.def.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/webgl/sigma.webgl.nodes.def.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/webgl/sigma.webgl.nodes.fast.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/webgl/sigma.webgl.edges.def.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/webgl/sigma.webgl.edges.fast.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/webgl/sigma.webgl.edges.arrow.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/canvas/sigma.canvas.labels.def.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/canvas/sigma.canvas.hovers.def.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/canvas/sigma.canvas.nodes.def.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/canvas/sigma.canvas.edges.def.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/canvas/sigma.canvas.edges.curve.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/canvas/sigma.canvas.edges.arrow.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/canvas/sigma.canvas.edges.curvedArrow.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/sigma.nwcommands.extensions/canvas/sigma.canvas.edges.curvedArrowFlex.js"></script>"' _newline
			
	file write `expfile' `"<script src="`linkurious'/src/renderers/canvas/sigma.canvas.edgehovers.def.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/canvas/sigma.canvas.edgehovers.curve.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/canvas/sigma.canvas.edgehovers.arrow.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/canvas/sigma.canvas.edgehovers.curvedArrow.js"></script>"' _newline
	
	file write `expfile' `"<script src="`linkurious'/sigma.nwcommands.extensions/canvas/sigma.canvas.edgehovers.curvedArrowFlex.js"></script>"' _newline
	
	file write `expfile' `"<script src="`linkurious'/src/renderers/canvas/sigma.canvas.extremities.def.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/svg/sigma.svg.utils.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/svg/sigma.svg.utils.js"></script>"' _newline
	
	file write `expfile' `"<script src="`linkurious'/src/renderers/svg/sigma.svg.nodes.def.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/svg/sigma.svg.edges.def.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/svg/sigma.svg.edges.curve.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/svg/sigma.svg.edges.curvedArrow.js"></script>"' _newline

	file write `expfile' `"<script src="`linkurious'/src/renderers/svg/sigma.svg.labels.def.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/svg/sigma.svg.hovers.def.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/middlewares/sigma.middlewares.rescale.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/middlewares/sigma.middlewares.copy.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/misc/sigma.misc.animation.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/misc/sigma.misc.bindEvents.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/misc/sigma.misc.bindDOMEvents.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/misc/sigma.misc.drawHovers.js"></script>"' _newline
	
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.plugins.colorbrewer/sigma.plugins.colorbrewer.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.plugins.design/sigma.plugins.design.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.plugins.legend/settings.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.plugins.legend/sigma.plugins.legend.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.exporters.image/sigma.exporters.image.js"></script>"' _newline

	file write `expfile' `"<script src="`linkurious'/plugins/sigma.plugins.dragNodes/sigma.plugins.dragNodes.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.helpers.graph/sigma.helpers.graph.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.plugins.activeState/sigma.plugins.activeState.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.plugins.select/sigma.plugins.select.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.plugins.keyboard/sigma.plugins.keyboard.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.renderers.linkurious/settings.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.renderers.linkurious/canvas/sigma.canvas.labels.def.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.renderers.linkurious/canvas/sigma.canvas.hovers.def.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.renderers.linkurious/canvas/sigma.canvas.nodes.def.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.renderers.linkurious/canvas/sigma.canvas.nodes.cross.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.renderers.linkurious/canvas/sigma.canvas.nodes.diamond.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.renderers.linkurious/canvas/sigma.canvas.nodes.equilateral.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.renderers.linkurious/canvas/sigma.canvas.nodes.square.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.renderers.linkurious/canvas/sigma.canvas.nodes.star.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.renderers.linkurious/canvas/sigma.canvas.edges.def.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.renderers.linkurious/canvas/sigma.canvas.edges.curve.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.renderers.linkurious/canvas/sigma.canvas.edges.arrow.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.renderers.linkurious/canvas/sigma.canvas.edges.curvedArrow.js"></script>"' _newline

	file write `expfile' `"<script src="`linkurious'/plugins/sigma.renderers.linkurious/canvas/sigma.canvas.edges.autoCurve.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.plugins.animate/sigma.plugins.animate.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.layouts.fruchtermanReingold/sigma.layout.fruchtermanReingold.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.exporters.image/sigma.exporters.image.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.exporters.svg/sigma.exporters.svg.js"></script>"'
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.renderers.linkurious/canvas/sigma.canvas.edges.dashed.js"></script>"'
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.renderers.linkurious/canvas/sigma.canvas.edges.dotted.js"></script>"'
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.renderers.linkurious/canvas/sigma.canvas.edges.parallel.js"></script>"'
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.renderers.linkurious/canvas/sigma.canvas.edges.tapered.js"></script>"'
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.renderers.linkurious/canvas/sigma.canvas.edgehovers.dashed.js"></script>"'
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.renderers.linkurious/canvas/sigma.canvas.edgehovers.dotted.js"></script>"'
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.renderers.linkurious/canvas/sigma.canvas.edgehovers.parallel.js"></script>"'
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.renderers.linkurious/canvas/sigma.canvas.edgehovers.tapered.js"></script>"'

	file write `expfile'  `"<script src="`linkurious'/plugins/sigma.renderers.customEdgeShapes/sigma.canvas.edges.parallel.js"></script>"'
    file write `expfile'  `"<script src="`linkurious'/plugins/sigma.renderers.customEdgeShapes/sigma.canvas.edgehovers.parallel.js"></script>"'
	file write `expfile'  `"<script src="`linkurious'/plugins/sigma.plugins.edgeSiblings/sigma.plugins.edgeSiblings.js"></script>"'

	file write `expfile' `"<div id="container">"' _newline
	file write `expfile' `"  <style>"' _newline
	file write `expfile' `"    body {"' _newline
    file write `expfile' `"  color: #333;"' _newline
    file write `expfile' `"  font-size: 14px;"' _newline
    file write `expfile' `"  font-family: Lato, sans-serif;"' _newline
    file write `expfile' `"}"' _newline
	file write `expfile' `"    #graph-container {"' _newline
	file write `expfile' `"      top: 0;"' _newline
	file write `expfile' `"      bottom: 0;"' _newline
	file write `expfile' `"      left: 0;"' _newline
	file write `expfile' `"      right: 0;"' _newline
	if "`background'" != "" {
		file write `expfile' `"      background: `background';"' _newline
	}
	file write `expfile' `"      position: absolute;"' _newline
	file write `expfile' `"    }"' _newline
	file write `expfile' `"    #control-pane {"' _newline
    file write `expfile' `"  top: 10px;"' _newline
    file write `expfile' `"  /*bottom: 10px;*/"' _newline
    file write `expfile' `" right: 10px;"' _newline
    file write `expfile' `"  z-index: 1;"' _newline
    file write `expfile' `"  position: absolute;"' _newline
    file write `expfile' `"  width: 230px;"' _newline
    file write `expfile' `"  background-color: rgb(230, 230, 230);"' _newline
    file write `expfile' `"  box-shadow: 0 2px 6px rgba(0,0,0,0);"' _newline
    file write `expfile' `"}"' _newline
    file write `expfile' `"#control-pane > div {"' _newline
    file write `expfile' `"  margin: 10px;"' _newline
    file write `expfile' `"  overflow-x: auto;"' _newline
    file write `expfile' `"}"' _newline
	
	file write `expfile' `"    input[type=range] {"' _newline
    file write `expfile' `"  width: 160px;"' _newline
    file write `expfile' `"}"' _newline

    file write `expfile' `"#image-container {"' _newline
    file write `expfile' `"  top: 0;"' _newline
    file write `expfile' `"  bottom: 0;"' _newline
    file write `expfile' `"  left: 0;"' _newline
    file write `expfile' `"  right: 0;"' _newline
    file write `expfile' `"  position: absolute;"' _newline
    file write `expfile' `"}"' _newline
	
	file write `expfile' `"  </style>"' _newline
	file write `expfile' `"  <div id="graph-container"></div>"' _newline
	file write `expfile' `" "' _newline
	
	if "`export'" == "" { 	
		file write `expfile' `"<div id="control-pane">"' _newline
		file write `expfile' `"<span class="line"></span>"' _newline
		file write `expfile' `"<div>"' _newline
		file write `expfile' `"  <button id="snapClip-btn">Export as PNG</button>"' _newline
		file write `expfile' `"  <button id="export" type="export">Export as SVG</button>"' _newline
		file write `expfile' `"</div>"' _newline
		file write `expfile' `"<div id="dump" class="hidden"></div>"' _newline
		file write `expfile' `"</div>"' _newline
		file write `expfile' `"</div>"' _newline
	}
	file write `expfile' `"<script>"' _newline
	
	// Helpfer functions
	file write `expfile' `"var _ = {"' _newline
	file write `expfile' `"	$: function (id) {"' _newline
    file write `expfile' `"	return document.getElementById(id);"' _newline
	file write `expfile' `"	}"' _newline
	file write `expfile' `"};"' _newline

	file write `expfile' `"function changeWidthValue() {"' _newline
	file write `expfile' `"    var valof = _.$("width").value;"' _newline
	file write `expfile' `"    _.$('width-value').innerHTML = valof;"' _newline
	file write `expfile' `"}"' _newline
	file write `expfile' `""' _newline
	file write `expfile' `"sigma.classes.graph.addMethod('neighbors', function(nodeId) {"' _newline
    file write `expfile' `"	var k,"' _newline
    file write `expfile' `"	neighbors = {},"' _newline
    file write `expfile' `"	index = this.allNeighborsIndex[nodeId] || {};"' _newline
    file write `expfile' `"	for (k in index)"' _newline
    file write `expfile' `"		neighbors[k] = this.nodesIndex[k];"' _newline
    file write `expfile' `"	return neighbors;"' _newline
	file write `expfile' `"});"' _newline
	file write `expfile' `""' _newline
	file close `expfile'

	mata: nwplotjs_writepalette("`fname'", "`color'", `colorcodes', `colorpalette_matrix', "`symbol'", `symbolcodes', `symbolpalette_matrix')

	mata: nwplotjs_writenodes("`fname'", `orig_netobj', "`xcoord'", "`ycoord'", `lgc_use', `_lgc', "`colorlabel'", "`color'", `colorpalette_matrix', `nodecolor_use', "`symbollabel'", "`symbol'", `symbolpalette_matrix', `nodesymbol_use', "`sizelabel'", "`size'", `nodesize_use', "`label'", `nodelabel_use' )

	mata: nwplotjs_writeedges("`fname'", `orig_netobj' , "`orig_directed'" == "false", `lgc_use', `_lgc', "`arcstyle'", `edgecurvefactor', `edgefactor',`edgesize', `edgesize_use', `edgecurve', `edgecurve_use', `edgepattern', `edgepattern_palette', `edgepattern_use', `edgecolor', `edgecolor_palette', `edgecolor_use')
	
	mata: nwplotjs_writestyles("`fname'", "`colorlabel'", "`symbollabel'", "`size'", `minnodesize', `maxnodesize')
   
	tempname expfile
	file open `expfile' using "`fname'", write append
	
	
// Sigma object
	file write `expfile' "" _newline
	file write `expfile' "sigma.renderers.def = sigma.renderers.canvas;" _newline
	file write `expfile' "" _newline
	file write `expfile' "var s = new sigma({graph: g , container: 'graph-container',renderer: {container: document.getElementById('graph-container'), type: 'canvas'}, " _newline
	file write `expfile' "settings: { edgeLabelSize: 'proportional', minEdgeSize: `minedgesize', maxEdgeSize: `maxedgesize', minArrowSize: `arrowfactor'," _newline
	file write `expfile' "minNodeSize: `minnodesize', maxNodeSize: `maxnodesize', dragNodeStickiness: 0.01, nodeBorderSize: 0," _newline
	
	// Label settings
	if "`label'" != "" | "`lab'" != "" {
		file write `expfile' "defaultLabelSize: `defaultlabelsize',"
		if "`labelcolor'" != "" {
			file write `expfile' "defaultLabelColor: '`labelcolor'',"
		}
		file write `expfile' "labelColor: '`labelcolormode'',"
		file write `expfile' "labelSize: '`labelsize'',"
		file write `expfile' "labelThreshold: `labelthreshold',"
		file write `expfile' "labelSizeRatio: `labelsizeratio',"
		file write `expfile' "font: '`font'',"
	}
	else {
		file write `expfile' "labelThreshold: 1000," 
	}
	
	if `edgecurvefactor' == 1 & "`edgecurve'" == "" {
		file write `expfile' "enableEdgeHovering: true, edgeHoverHighlightNodes: 'circle', edgeHovercolor: '#800000', defaultEdgeHoverColor: '#000',edgeHoverExtremities: true"
	}
	else {
		file write `expfile' "enableEdgeHovering: false"
	}
	if "`settings'" != "" {
		file write `expfile' ", `settings'" 
	}
	file write `expfile' "}});" _newline 
	file write `expfile' "" _newline
	file write `expfile' "var frListener = sigma.layouts.fruchtermanReingold.configure(s, {" _newline
	file write `expfile' "	iterations: 500," _newline
	file write `expfile' "	easing: 'quadraticInOut'," _newline
	file write `expfile' "	duration: 800" _newline
	file write `expfile' "});" _newline
	file write `expfile' "" _newline
	file write `expfile' "  var design = sigma.plugins.design(s, {styles: myStyles,palette: myPalette});"_newline
	file write `expfile' "	design.apply();" _newline
  
	file write `expfile' "" _newline
	file write `expfile' "frListener.bind('start stop interpolate', function(e) {" _newline
	file write `expfile' "	console.log(e.type);" _newline
	file write `expfile' "});" _newline
	file write `expfile' "" _newline
	
	
	//file write `expfile' `"sigma.canvas.edges.autoCurve(s);"' _newline
	//file write `expfile' `"s.refresh();"' _newline

	if "`layout'" == "fruchterman" {
		file write `expfile' "sigma.layouts.fruchtermanReingold.start(s);"
		file write `expfile' "" _newline
	}
	file write `expfile' "var activeState = sigma.plugins.activeState(s);" _newline
	file write `expfile' "var dragListener = sigma.plugins.dragNodes(s, s.renderers[0], activeState);" _newline
	//file write `expfile' "var select = sigma.plugins.select(s, activeState);" _newline
	//file write `expfile' "var keyboard = sigma.plugins.keyboard(s, s.renderers[0]);" _newline
	if "`legend'" != "" {
		file write `expfile' "var legend = sigma.plugins.legend(s);" _newline
	}
	//file write `expfile' "legend.setPlacement('left');" _newline
	//file write `expfile' "select.bindKeyboard(keyboard);" _newline
	
	// AutoCurve
	//if "`arcstyle'" == "automatic" & "`directed'" != "false" {
	//	file write `expfile' "sigma.canvas.edges.autoCurve(s);" _newline
	//}
	
	// Drag nodes
	file write `expfile' "s.refresh();" _newline
	file write `expfile' `""' _newline
	file write `expfile' "dragListener.bind('startdrag', function(event) {" _newline
	file write `expfile' "  console.log(event);" _newline
	file write `expfile' "});" _newline
	file write `expfile' "dragListener.bind('drag', function(event) {" _newline
	file write `expfile' "  console.log(event);" _newline
	file write `expfile' "});" _newline
	file write `expfile' "dragListener.bind('drop', function(event) {" _newline
	file write `expfile' "  console.log(event);" _newline
	file write `expfile' "});" _newline
	file write `expfile' "dragListener.bind('dragend', function(event) {" _newline
	file write `expfile' "  console.log(event);" _newline
	file write `expfile' "});" _newline

	/*
	// Highlight selected nodes
	      // We first need to save the original colors of our
      // nodes and edges, like this:
    file write `expfile' `" s.graph.nodes().forEach(function(n) {"' _newline
    file write `expfile' `"    n.originalColor = n.color;"' _newline
    file write `expfile' `" });"' _newline
    file write `expfile' `"s.graph.edges().forEach(function(e) {"' _newline
    file write `expfile' `"    e.originalColor = e.color;"' _newline
    file write `expfile' `"});"' _newline

      // When a node is clicked, we check for each node
      // if it is a neighbor of the clicked one. If not,
      // we set its color as grey, and else, it takes its
      // original color.
      // We do the same for the edges, and we only keep
      // edges that have both extremities colored.
    file write `expfile' `"s.bind('clickNode', function(e) {"' _newline
    file write `expfile' `"	var nodeId = e.data.node.id,"' _newline
    file write `expfile' `"		toKeep = s.graph.neighbors(nodeId);"' _newline
    file write `expfile' `"		toKeep[nodeId] = e.data.node;"' _newline

    file write `expfile' `"		s.graph.nodes().forEach(function(n) {"' _newline
    file write `expfile' `"		if (toKeep[n.id])"' _newline
    file write `expfile' `"			n.color = n.originalColor;"' _newline
    file write `expfile' `"		else"' _newline
    file write `expfile' `"			n.color = '#eee';"' _newline
    file write `expfile' `"	});"' _newline

    file write `expfile' `"	s.graph.edges().forEach(function(e) {"' _newline
    file write `expfile' `"		if (toKeep[e.source])"' _newline
    file write `expfile' `"			e.color = e.originalColor;"' _newline
    file write `expfile' `"		else"' _newline
    file write `expfile' `"			e.color = '#eee';"' _newline
    file write `expfile' `"	});"' _newline

        // Since the data has been modified, we need to
        // call the refresh method to make the colors
        // update effective.
    file write `expfile' `"	s.refresh();"' _newline
    file write `expfile' `"});"' _newline

      // When the stage is clicked, we just color each
      // node and edge with its original color.
    file write `expfile' `"  s.bind('clickStage', function(e) {"' _newline
    file write `expfile' `"    s.graph.nodes().forEach(function(n) {"' _newline
    file write `expfile' `"      n.color = n.originalColor;});"' _newline

    file write `expfile' `"    s.graph.edges().forEach(function(e) {"' _newline
    file write `expfile' `"      e.color = e.originalColor;});"' _newline

        // Same as in the previous event:
    file write `expfile' `"   s.refresh();"' _newline
    file write `expfile' `"  });"' _newline
*/	
	// Save Image
	file write `expfile' `"function generateImage(mouse, clip) {"' _newline
	//file write `expfile' `"	var size = parseInt(_.$("width").value);"' _newline
	//file write `expfile' `"	var color = _.$("color").value;"' _newline

	file write `expfile' `"	sigma.plugins.image(s, s.renderers[0], {"' _newline
    file write `expfile' `"		download: true,"' _newline
    file write `expfile' `"		size: `width',"' _newline
    file write `expfile' `"		margin: 50,"' _newline
    file write `expfile' `"		background: "`background'","' _newline
    file write `expfile' `"		clip: clip,"' _newline
    file write `expfile' `"		zoomRatio: 1,"' _newline
    file write `expfile' `"		labels: false"' _newline
	file write `expfile' `"	});"' _newline
	file write `expfile' `"}"' _newline

	//file write `expfile' `"_.$('width').addEventListener("change", changeWidthValue); "' _newline
	file write `expfile' `"_.$('snapClip-btn').addEventListener("click", function(event) {"' _newline
	file write `expfile' `"generateImage(event, true)"' _newline
	file write `expfile' `"});"' _newline
	
	file write `expfile' `""' _newline
	file write `expfile' `"document.getElementById('export').onclick = function() {"' _newline
	file write `expfile' `"	console.log('exporting...');"' _newline
    file write `expfile' `"	var output = s.toSVG({download: true, filename: '`netname'.svg', size: 1000});"' _newline
	file write `expfile' `"};"' _newline
	file write `expfile' `""' _newline	
	
	file write `expfile' `"s.bind('clickNode doubleClickNode rightClickNode', function(e) {"' _newline	
    file write `expfile' `"console.log(e.type, e.data.node.label, e.data.captor);"' _newline	
	file write `expfile' `"});"' _newline	
	file write `expfile' `"s.bind('clickEdge doubleClickEdge rightClickEdge', function(e) {"' _newline	
	file write `expfile' `"console.log(e.type, e.data.edge, e.data.captor);"' _newline	
	file write `expfile' `"});"' _newline	
	file write `expfile' `"s.bind('clickStage doubleClickStage rightClickStage', function(e) {"' _newline	
	file write `expfile' `"console.log(e.type, e.data.captor);"' _newline	
	file write `expfile' `"});"' _newline	
	file write `expfile' `"s.bind('hovers', function(e) {"' _newline	
	file write `expfile' `"console.log(e.type, e.data.captor, e.data);"' _newline	
	file write `expfile' `"});"' _newline	
	
	file write `expfile' `"</script>"' _newline	
	file close `expfile'
	
	local oscmd "open"
	
	if "`c(return)'" == "Windows" {
		local oscmd "start"
	}

	restore
	shell `oscmd' `fname'
	
end

capture mata: mata drop nwplotjs_writepalette()
capture mata: mata drop nwplotjs_writestyles()
capture mata: mata drop nwplotjs_writeintro()
capture mata: mata drop nwplotjs_writenodes()
capture mata: mata drop nwplotjs_writeedges()

mata:
void nwplotjs_writepalette(string scalar filename, string scalar color, string matrix colorcodes, string matrix colorpalette, string scalar symbol, string matrix symbolcodes, string matrix symbolpalette)
{
	real scalar fh, i 
	
	fh = fopen(filename, "a")
	fput(fh, "")
	fwrite(fh,"	var myPalette = { schemes: { ")
	if (color != ""){
		fwrite(fh," colorScheme: { ")
		for (i = 1; i <= cols(colorcodes); i++){
			fwrite(fh," '")
			fwrite(fh,colorcodes[i])
			fwrite(fh,"':'")
			fwrite(fh,colorpalette[mod((i-1), cols(colorpalette)) + 1])
			fwrite(fh,"',")
		}
		fwrite(fh," }, ")
	}
	if (symbol != ""){
		fwrite(fh," symbolScheme: { ")
		for (i = 1; i <= cols(symbolcodes); i++){
			fwrite(fh," '")
			fwrite(fh,symbolcodes[i])
			fwrite(fh,"':'")
			fwrite(fh,symbolpalette[mod((i-1), cols(symbolpalette)) + 1])
			fwrite(fh,"',")
		}
		fwrite(fh," } ")
	}
	fput(fh," } };")
	fclose(fh)
}

void nwplotjs_writestyles(string scalar filename, string scalar colorlabel, string scalar symbollabel, string scalar size, real scalar size_minnodesize, real scalar size_maxnodesize)
{
	real scalar fh
	
	fh = fopen(filename, "a")
	fput(fh,"")
	fwrite(fh,"	var myStyles = { nodes: {")
	if (colorlabel != "") {
		fwrite(fh, " color: { by: 'data.properties.")
		fwrite(fh, colorlabel)
		fwrite(fh, "', scheme: 'schemes.colorScheme' },")
	}
	
	if (symbollabel != "") {
		fwrite(fh, " type: { by: 'data.properties.")
		fwrite(fh, symbollabel)
		fwrite(fh, "', scheme: 'schemes.symbolScheme' },")
	}
	
	if (size != "") {
		fwrite(fh, " size: { by: 'data.properties.")
		fwrite(fh, size)
		fwrite(fh, "', bins: 5, ")
		fwrite(fh, " min: ")
		fwrite(fh, strofreal(size_minnodesize))
		fwrite(fh, ", max: ")
		fwrite(fh, strofreal(size_maxnodesize))
		fwrite(fh, "}")
	}
	fput(fh, " } };")
	fclose(fh)
}

void nwplotjs_writeintro(string scalar filename, string scalar linkurious)
{


}

void nwplotjs_writenodes(string scalar filename, pointer(class nw_def scalar) scalar network, string scalar xcoordvar, string scalar ycoordvar, real scalar lgc_use, real matrix lgc, string scalar colorlabel, string scalar colorvar, string matrix colorpalette, real scalar color_use,  string scalar symbollabel, string scalar symbolvar, string matrix symbolpalette, real scalar symbol_use, string scalar sizelabel, string scalar sizevar, real scalar size_use, string scalar labelvar, real scalar label_use )
{
	real scalar fh, i, include_node, nodes
	real matrix  size, xcoord, ycoord
	string matrix nodenames, labels, color, symbol
	
	fh = fopen(filename, "a")
	fput(fh,"")
	fput(fh, "	var g = {nodes: [],edges: []};")
	fput(fh,"")
	
	nodenames = network -> get_nodenames()
	nodes = network -> get_nodes()
	xcoord = st_data((1::nodes), xcoordvar)
	ycoord = st_data((1::nodes), ycoordvar)	
	
	if (color_use == 1) {
		color = st_sdata((1::nodes), colorvar)
	}
	if (symbol_use == 1) {
		symbol = st_sdata((1::nodes), symbolvar)
	}
	if (size_use == 1) {
		size = st_data((1::nodes), sizevar)
	}
	if (label_use == 1) {
		labels = st_sdata((1::nodes), labelvar)
	}
	
	for (i = 1; i <= cols(nodenames); i++){
		include_node = 1
		if (lgc_use == 1) {
			include_node = lgc[i]
		}
		
		if (include_node == 1) {
			fwrite(fh, "	 g.nodes.push({id: '")
			fwrite(fh, nodenames[i])
			fwrite(fh, "', x:'")
			fwrite(fh, strofreal(xcoord[i]))
			fwrite(fh, "', y:'")
			fwrite(fh, strofreal(ycoord[i]))		
			fwrite(fh, "',")
		
			if (color_use == 0) {
				fwrite(fh," color: '")
				fwrite(fh, colorpalette[1])
				fwrite(fh,"', ")
			}
			
			if (symbol_use == 0) {
				fwrite(fh," symbol: '")
				fwrite(fh, symbolpalette[1])
				fwrite(fh,"', ")
			}	
		
			fwrite(fh, " label: '")
			if (label_use == 1) {
				fwrite(fh, labels[i])
			}
			else {
				fwrite(fh, nodenames[i])
			}
			fwrite(fh, "', ")	
			
			fwrite(fh, " data: { properties: {")
			if (color_use == 1) {
				fwrite(fh, colorlabel)
				fwrite(fh,": '")
				fwrite(fh, color[i])
				fwrite(fh,"', ")
			}
			if (symbol_use == 1) {
				fwrite(fh, symbollabel)
				fwrite(fh,": '")
				fwrite(fh, symbol[i])
				fwrite(fh,"', ")
			}
			if (size_use == 1) {
				fwrite(fh, sizelabel)
				fwrite(fh,": ")
				fwrite(fh, strofreal(size[i]))
				fwrite(fh," ")
			}
			fwrite(fh, " } } ")
		}
		fput(fh, " } ) ")
	}
	fclose(fh)
}


void nwplotjs_writeedges(string scalar filename, pointer(class nw_def scalar) scalar network, real scalar undirected, real matrix lgc_use, real matrix lgc, string scalar arcstyle, real scalar edgecurvefactor,real scalar edgefactor,  pointer(class nw_def scalar) scalar edgesize, real scalar edgesize_use, pointer(class nw_def scalar) scalar edgecurve, real scalar edgecurve_use,  pointer(class nw_def scalar) scalar edgepattern, string matrix edgepattern_palette, real scalar edgepattern_use, pointer(class nw_def scalar) scalar edgecolor, string matrix edgecolor_palette, real scalar edgecolor_use  )
{
	real scalar fh, _edges, i, include_edge, ego, alter, value, value_opposite
	string matrix _elist
	string scalar temp, epattern, ecolor
	
	fh = fopen(filename, "a")
	fput(fh,"")
	_elist = network->get_edgelist_compressed(undirected)
	_edges = rows(_elist)
	
	for (i = 1; i<= _edges; i++) {
		include_edge = 1
		if (lgc_use == 1) {
			if ( lgc[strtoreal(_elist[i,6])] == 0 | lgc[strtoreal(_elist[i,7])] == 0 ){
				include_edge = 0
			}
		}
			
		if (include_edge == 1) { 
			ego = strtoreal(_elist[i,6])
			alter = strtoreal(_elist[i,7])
			value = strtoreal(_elist[i,3])
			value_opposite = strtoreal(_elist[i,5])
			
			fwrite(fh,"	g.edges.push({id: 'e")		
			fwrite(fh,strofreal(i))
			fwrite(fh,"', source:'")
			fwrite(fh,_elist[i,1])
			fwrite(fh,"', target:'")
			fwrite(fh,_elist[i,2])
			fwrite(fh,"', curv:'")
			
			// Get edge curvature
			if (edgecurve_use == 1){
				fwrite(fh, strofreal((*edgecurve->get_matrix())[ego, alter]))
			}
			else {
				fwrite(fh,strofreal( 5 / edgecurvefactor))
			}
				
			// Get edge width/size
			fwrite(fh,"', size:'")
			if (edgesize_use == 1) {
				fwrite(fh, strofreal((*edgesize->get_matrix())[ego, alter] * edgefactor))
			}
			else {
				fwrite(fh, strofreal(edgefactor)) 
			}
			fwrite(fh,"', type:")
			
			//  Pattern of edge
			epattern = edgepattern_palette[1]
			if (edgepattern_use == 1){
				epattern = ustrtitle(edgepattern_palette[(mod(((*edgepattern->get_matrix())[ego, alter]), cols(edgepattern_palette)) + 1)])
			}
			
			if (epattern == "solid" | epattern == "Solid"){
				epattern = ""
			}
			
			// Arcstyle can be either curved, straight, or automatic
			// Deal with automatic arcstyle
			temp = arcstyle
			if (arcstyle == "automatic"){
				if (value_opposite != 0 & value_opposite != .) {
					arcstyle = "curved"
				}
				else {
					arcstyle = "straight"
				}
			}

			// Undirected and directed network 
			if (undirected == 1) {
				fwrite(fh,"'line")
			}
			else {
				if (arcstyle == "curved"){
					if (edgecurvefactor == 1 & edgecurve_use == 0) {
						fwrite(fh,"'curvedArrow")
					}
					else {
						fwrite(fh,"'curvedArrowFlex")
					}
				}
				else if (arcstyle == "straight"){
					fwrite(fh,"'arrow")
				}
			}
			arcstyle = temp
			
			fwrite(fh, epattern)
			fwrite(fh,"'")
			
			// Color of edge
			ecolor = edgecolor_palette[1]
			if (edgecolor_use == 1){
				ecolor = edgecolor_palette[(mod(((*edgecolor->get_matrix())[ego, alter]), cols(edgecolor_palette)) + 1)]
			}
			fwrite(fh,", color:'")
			fwrite(fh, ecolor)
			fput(fh,"' } )")	
		}
	}
	fclose(fh)
}
end
