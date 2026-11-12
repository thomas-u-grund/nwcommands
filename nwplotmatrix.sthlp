{smcl}
{* *! version 2.0.0  2april2014}{...}
{marker topic}
{helpb nwtopical##visualization:[NW-2.8] Visualization}

{title:Title}

{p2colset 9 15 22 2}{...}
{p2col :nwplotmatrix {hline 2}}Plot a network as sociomatrix{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwplotmatrix}
[{it:{help netname}}] 
[{cmd:,}
{opth sortby(varname)}
{opt group}({it:{help varname}}, [{it:{help connect_options}}])
{it:{help nwplotmatrix##label_options:label_options}}
{it:{help nwplotmatrix##patch_options:patch_options}}
{it:{help twoway_options}}]


	
{synoptset 35}{...}
{p2col:{it:options}}Description{p_end}
{p2line}
{p2col:{opth sortby(varname)}}sort network nodes before plotting{p_end}
{p2col:{opt group}({it:{help varname}}, [{it:{help connect_options}}])}group nodes by categorical variable; the names of the groups are written beside the blocks{p_end}
{p2col:{opt nogroupl:abels}}with {opt group()}: no group names{p_end}
{p2col:{it:{help nwplotmatrix##label_options:label_options}}}display and change look of
       axis labels{p_end}
{p2col:{it:{help nwplotmatrix##patch_options:patch_options}}}change look of patches (e.g. color, tievalue){p_end}


{synoptset 35 tabbed}{...}
{p2col:{it:label_options}}Description{p_end}
{marker label_options}{...}
{p2line}
{p2col:{opt lab}}display node labels{p_end}
{p2col:{opth label(varname)}}display axis labels from variable{p_end}
{p2col:{opt labelopt}({it:{help axis_label_options:suboptions}})}suboptions of both axis labels, for example {cmd:labelopt(labsize(tiny))}; {opt ylabel()} and {opt xlabel()} change one axis{p_end}
{p2col:{opt legendopt}({it:{help legend_options:legend_options}})}options added to the legend, for example {cmd:legendopt(rows(2))}; they replace the default rows(1), position(6) and size(small) of the automatic legend{p_end}


{synoptset 35 tabbed}{...}
{p2col:{it:patch_options}}Description{p_end}
{marker patch_options}{...}
{p2line}
{p2col:{opt co:lorpalette}({it:{help colstyle:colstyle...}})}list of colors for patches (representing tie values){p_end}
{p2col:{opth lc:olor(colorstyle)}}overwrite color of lines between patches{p_end}
{p2col:{opth ba:ckground(colorstyle)}}overwrite background color{p_end}
{synopt:{opt tievalue}}show tie values as text inside patches{p_end}
{p2col:{opt tievalueopt}({it:{help scatter##marker_label_options:marker_label_options}})}options for look and feel of tie value text{p_end}


		
{title:Description}

{pstd}
This command plots a network as a sociomatrix. To plot a part of a network, make it first with {help nwsubset}.
It gives a lot of flexibility to control all elements in a network plot. Furthermore, it 
is compatible with {bf:schemes()} and accepts all {help twoway_options}.

{pstd}
This loads the {help netexample:Florentine data} and makes a simple matrix plot.

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwplotmatrix flomarriage, lab}

{pstd}
The look and feel of the axis labels can be changed with the {help twoway_options} {opt ylabel()} and {opt xlabel()}:

	{cmd:. nwplotmatrix flomarriage, lab ylabel(,labsize(tiny)) xlabel(,labsize(tiny))}
	
{pstd}
The following uses the values stored in variable {bf:wealth} as labels.
	{cmd:. nwplotmatrix flomarriage, label(wealth)}


{pstd}
The y-axis and the x-axis can be controlled independently from each other, for example:

 	{cmd:. nwplotmatrix flomarriage, lab ylabel(,labsize(tiny)) xlabel(,labsize(vsmall))}

{pstd}
It can be useful to sort the nodes of the network before plotting a sociomatrix. This example sorts the nodes according
to the values in variable {it:wealth}.

	{cmd:. nwplotmatrix flomarriage, label(wealth) sortby(wealth)}

{pstd}
The command accepts all normal {help twoway_options}, e.g.

	{cmd:. nwplotmatrix flomarriage, scheme(s1mono) title("mynet")}

{pstd}
One can also overwrite the colors used for the plot:

	{cmd:. nwplotmatrix flomarriage, scheme(s1mono) colorpalette(black) background(yellow) lcolor(red)}

{pstd}
The command also allows to display the tie values inside the patches. The look and feel of these values is controlled with {bf: tievalueopt()}.

	{cmd:. nwplotmatrix flomarriage, tievalue}
	{cmd:. nwplotmatrix flomarriage, tievalue tievalueopt(mlabsize(tiny) mlabcolor(yellow))}


{pstd}
The option {opth group(varname)} sorts the nodes by {help varname} first and then adds lines
to the sociomatrix to separate groups from each other. The example generates the variable seat, 
which is one when a family had some seats in the council.

	{cmd:. nwplotmatrix flomarriage, group(seat)}	

{pstd}
If the group variable has names (a string variable, or a value label), the name of each group is written beside
its block, at the top and at the left, unless node labels are shown ({opt lab} or {opt label()}); {opt nogrouplabels}
leaves the names out. A numeric group variable without a value label gets no names.
The lines between the groups are drawn medium thick.

{pstd}
All normal {help connect_options:options for lines} can be applied as well.

	{cmd:. nwplotmatrix flomarriage, group(seat, lcolor(green))}	
	

{title:Network types}

{pstd}
{bf:Directed:} the matrix shows asymmetry directly. {bf:Valued:} the legend names the value classes of the cells ('no
tie' and 'tie' on a binary network); {opt tievalue} prints the values. {bf:Two-mode:} yes - the nodes of one mode are
placed together (unless {opt sortby()} or {opt group()}) and a line separates the modes. {bf:Signed:} negative values
are not treated specially. See {help nwnetworktypes}.{p_end}

{title:Limits}

{pstd}
One box (five points) is drawn for every pair of nodes, so memory and time grow with the square of the number of nodes:
1,000 nodes 5 seconds and 0.8 GB, 2,000 nodes 19 seconds and 2.6 GB. Networks of more than 2,500 nodes
are refused; plot a part of the network or use {help nwplot}.

{title:See also}

	{help nwplot}

{hline}
{pstd}{it:nwcommands version 3.20.1, 12 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
