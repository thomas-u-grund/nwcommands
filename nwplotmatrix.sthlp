{smcl}
{* *! version 2.0.0  2april2014}{...}
{marker topic}
{helpb nw_topical##visualization:[NW-2.8] Visualization}

{title:Title}

{p2colset 9 15 22 2}{...}
{p2col :nwplotmatrix {hline 2}}Plot a network as sociomatrix{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwplotmatrix}
[{it:{help netname}}] 
[{it:{help if}}]
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
{p2col:{opt group}({it:{help varname}}, [{it:{help connect_options}}])}group nodes by categorical variable{p_end}
{p2col:{it:{help nwplotmatrix##label_options:label_options}}}display and change look of
       axis labels{p_end}
{p2col:{it:{help nwplotmatrix##patch_options:patch_options}}}change look of patches (e.g. color, tievalue){p_end}


{synoptset 35 tabbed}{...}
{p2col:{it:label_options}}Description{p_end}
{marker label_options}{...}
{p2line}
{p2col:{opt lab}display node labels{p_end}
{p2col:{opth label(varname)}}display axis labels from variable{p_end}
{synopt:{opt labelopt}({it:{help scatter##marker_label_options:marker_label_options}})}options for look of axis labels (e.g. size, color){p_end}


{synoptset 35 tabbed}{...}
{p2col:{it:patch_options}}Description{p_end}
{marker patch_options}{...}
{p2line}
{p2col:{opt col:orpalette}({it:{help colstyle:colstyle...}})}list of colors for patches (representing tie values){p_end}
{p2col:{opth lcolor(colorstyle)}}overwrite color of lines between patches{p_end}
{p2col:{opth background(colorstyle)}}overwrite background color{p_end}
{synopt:{opt tievalue}}show tie values as text inside patches{p_end}
{p2col:{opt tievalueopt}({it:{help scatter##marker_label_options:marker_label_options}})}options for look and feel of tie value text{p_end}


		
{title:Description}

{pstd}
This command plots a network as a sociomatrix. It supports subnetworks specified by the {help if} condition. It gives a lot of flexibility to control all elements in a network plot. Furthermore, it 
is compatible with {bf:schemes()} and accepts all {help twoway_options}.

{pstd}
This loads the {help netexample:Florentine data} and makes a simple matrix plot.

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwplotmatrix flomarriage, lab}

{pstd}
The look and feel of the axis labels ca be overwritten with {opt labelopt()}. 
	{cmd:. nwplotmatrix flomarriage, lab labelopt(labsize(tiny))}
	
{pstd}
The following uses the values stored in variable {bf:wealth} as labels.
	{cmd:. nwplotmatrix flomarriage, label(wealth)}


{pstd}
Notice that one can also use normal {help twoway_options} to control the y-axis and the x-axis independently from each other. For example, the
following command produces the same output as the previous command:

 	{cmd:. nwplotmatrix flomarriage, ylabel(,labsize(tiny)) xlabel(,labsize(tiny))}

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
All normal {help connect_options:options for lines} can be applied as well.

	{cmd:. nwplotmatrix flomarriage, group(seat, lcolor(green))}	
	

{title:Supported network types}

{pstd}
Binary: yes. Directed: yes - the matrix display itself makes asymmetry visible directly (unlike {help nwplot}'s node-link layout, which needs {opt arrows} to show direction). Weighted: yes, tie values can drive cell shading/size. Signed: not checked. Two-mode: not checked.

{title:See also}

	{help nwplot}

last certified : 24 Aug 2026
