{smcl}
{* *! version 1.0.6  23aug2014 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##manipulation:[NW-2.5] Manipulation}

{title:Title}

{p2colset 9 20 22 2}{...}
{p2col :nwkeepnodes {hline 2}}Keep nodes of a network{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwkeepnodes}
[{it:{help netname}}],
{opt nodes}({it:{help numlist:nodeid1...}} {help nodeid:{it:or} nodelab1...})
[
{opt attributes}({it:{help varlist}})
{opt generate}({it:{help newnetname}})
{opt netonly}
{opt xvars}]

{p 8 17 2}
{cmdab: nwkeepnodes}
[{it:{help netname}}],
{opt keepmat}({it:matamatrix})
[
{opt attributes}({it:{help varlist}})
{opt generate}({it:{help newnetname}})
{opt netonly}
{opt xvars}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt nodes}({it:{help numlist:nodeid1...}})}{help numlist} of {help nodeid:nodeid's} to be kept{p_end}
{synopt:{opt nodes}({it:{help nodeid:nodelab1...}})}List of {help nodeid:nodelab's} to be kept{p_end}
{synopt:{opt keepmat}({it:matamatrix})}Mata {it:nodes} x 1 matrix; 0 = drop, 1 = keep{p_end}
{synopt:{opth attributes(varlist)}}Attribute variables that are included in the drop{p_end}
{synopt:{opth generate(newnetname)}}Generates a new network and does not overwrite the original network{p_end}
{synopt:{opt netonly}}Only update the network, but keep the Stata variables as they were{p_end}
{synopt:{opt xvars}}Generate Stata variables for the network{p_end}

{pstd}
Exactly one of {opt nodes()} or {opt keepmat()} must be specified - omitting both errors clearly
(unlike {help nwdropnodes}, where omitting both is a silent no-op, since "keep nothing" has no safe
default the way "drop nothing" does).

{synoptline}
{p2colreset}{...}
	
{title:Description}

{pstd}
Keeps nodes of a network. The nodes that are to be kept can be either specifified by their {help nodeid} or by their {help nodeid:nodelab}
in option {bf:nodes()}. Alternatively, one can also keep nodes based on a mata matrix. 

{pstd}
By default, the command overwrites the original network. This cannot be undone. Hence, it is recommended to specify option {bf:generate()},
which generates a new network instead and keeps the original network as it was. 

{pstd}
The command mirrors {help nwdropnodes}.


{pstd}
Keep the first seven nodes of network {it:flomarriage} and save it as network {it:flomarriage_reduced}:

{pmore}
{cmd:. nwwebuse florentine, nwclear}{p_end}
{pmore}
{cmd:. nwkeepnodes flomarriage, nodes(1/7) generate(flomarriage_reduced)}{p_end}


{pstd}
Keep the nodes "medici" and "pucci":

{pmore}
{cmd:. nwwebuse florentine, nwclear}{p_end}
{pmore}
{cmd:. nwkeepnodes flomarriage, nodes(medici pucci)}{p_end}


{pstd}
Alternatively, one can also keep nodes based on a mata matrix. This drops the first node:

{pmore}
{cmd:. nwwebuse florentine, nwclear}{p_end}
{pmore}
{cmd:. mata: k = (0\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1)}{p_end}
{pmore}
{cmd:. nwkeepnodes flomarriage, keepmat(k)}{p_end}

{pstd}
Everything this command does can also be achieved with {help nwkeep} using the {bf:if} condition. For example, the following
command also keeps the first seven nodes:

{pmore}
{cmd:. nwwebuse florentine, nwclear}{p_end}
{pmore}
{cmd:. nwkeep flomarriage if _n <= 7}{p_end}

{pstd}
Note the opposite default polarity between the two interfaces: {help nwkeep} leaves Stata dataset
rows alone unless {bf:clean} is specified, while {cmd:nwkeepnodes} rebuilds the Stata dataset by
default unless {bf:netonly} is specified.



{title:Supported network types}

{pstd}
Binary: yes. Directed: yes. Weighted: yes. Signed: yes - a purely structural operation, existing ties and their values are untouched for surviving nodes. Two-mode: mode assignments are preserved for surviving nodes.

{title:See also}
   
   {help nwdropnodes}, {help nwkeep}, {help nwdrop}, {help nwclear}
