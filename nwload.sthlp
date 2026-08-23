{smcl}
{* *! 11jul2016 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##utilities:[NW-2.7] Utilities}

{title:Title}

{p2colset 9 15 22 2}{...}
{p2col :nwload {hline 2}}Load a network as Stata variables{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwload} 
[{it:{help netname}}]
[{cmd:,}
{opth id(int)}
{opt nocurrent}
{opt labelonly}
{opt force}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt nocurrent}}Only load network as Stata variables, but do not make it the {it:current network}{p_end}
{synopt:{opt labelonly}}Only load the node labels as Stata variable{p_end}
{synopt:{opth generate(varname)}}Generate flag for nodes of the loaded network; default = {it:_nwinclude}{p_end}
{synopt:{opt viewoff}}Unconnect view from network to dataset; default{p_end}
{synopt:{opt viewon}}Establish view of network to dataset{p_end}
{synopt:{opt force}}By default, matrix is not loaded for networks with more than 1000 nodes unless {bf:force} is specified{p_end}
		
{title:Description}

{pstd}
Networks exist as objects in Mata. Once a networks have been imported, generated or set, one can interact with
them by referring to their {help netname}, just as if one would interact with variables using their {help varname}. 

{pstd}
Networks have various meta-information, such as node labels (see
{help nwname}). Each network also has information about a set of Stata variables that should be created to represent the network as Stata
variables. {bf:nwset, detail} shows this information for all networks. 

{pstd}
The meta-data of a network (including the variables that should be used to load the network) can be changed with {help nwname}.

{pstd}
The command {bf:nwload} loads a network as Stata variables. By doing so, the command generates a set of Stata variables (the names 
of these variables are stored in the meta-information for a network) and populates these variables with the adjaceny matrix 
of the network.

{pstd}
An adjacency matrix is a simple representation of a network. The adjaceny matrix {it:M} of a network has the dimensions {it:nodes x nodes}. The 
matrix cell {it:M_ij} = 0 when there is no tie between nodes {it:i} and {it:j}. In binary networks, {it:M_ij} = 1 when there is
a network relationship between nodes {it:i} and {it:j}. However, networks can also be valued, i.e. {it:M_ij} > 1. Some 
nwcommands support valued networks.

{pstd}
Loading a network as Stata variables can be useful if one wants to interact with (or look at) the network through the dataset. But notice 
that changing one of the Stata variables does not change the underlying network, unless a view of the network to the dataset is established with
the option {bf:viewon}. But be careful, establishing such a view can also lead to unintended changes of an underlying network. The option {bf:viewoff}
reverts back and unconnects a network from a view on the dataset. To change values of the underlying network directly use {help nwreplace} instead. 

{pstd}
For example, if one were to import/use a network with 16 nodes and drop all Stata variables, {bf:nwload} would create exactly
16 variables and 16 cases.

	{cmd:. webnwuse florentine, nwclear}
	{cmd:. drop _all}
	{cmd:. nwload flomarriage}

{pstd}
All Stata variables can be deleted without deleting the underlying networks (except when a network is established as a view on the dataset with option {bf:viewon}; see above). With {bf:nwload} a network can always be brought back 
as Stata variables. In case the variables already exist, they are overwritten. If one wants to permanently drop a network one needs to
use {help nwdrop} or {help nwclear} (very similar to how one would drop or clear normal variables). 

{pstd}
{bf:nwload} not only loads the adjacency matrix as variables, but also generates (or overwrites) the variable {it:_nwnode}. This variable identifies nodes. When
the network is two-mode (see {help nw2set:introduction to two-mode networks), the command also creates the variable {it:_nwmode}. Lastly, the command
generates (or overwrites) the variable {it:_nwinclude} (unless option {opt:generate()} specifies another variable name. This variable indicates which nodes
are part of the network that has been loaded. 

{pstd}
Nodes and node attributes are represented as observations in the dataset and are matched with the variable {it:_nwnode}. Whenever a nwcommand uses or produces
node-level attributes it matches the nodes with the observations.

{pstd}
One can only load the node labels of a network as a Stata variable with the option {bf:labelsonly} (this does neither load the adjacency matrix
of a network as Stata variables nor other information, but just creates the variable {it:_nwnode}).

{pstd}
For example, one can plot the Florentine marriage network and label the nodes accordingly with:

	{cmd:. webnwuse florentine, nwclear}
	{cmd:. nwplot flomarriage, label(_nwnode)}

{pstd}
Furthermore, {bf:nwload} makes {help netname} the current network, unless option {bf:nocurrent} is specified. Many nwcommands (although
they do something with a network) do not require a network name. In the cases where no {help netname} is specified, a nwcommand 
automatically runs with the {help nwcurrent:current network}. For programming your own network commands with this feature see 
{help nw_syntax}.

{pstd}
By default, commands that generate a network (see {help nw_topical##generator:network generator}) do NOT also load the network as Stata
variables - creating a network never silently spends Stata's own variable budget. Most network generators have the option {bf:xvars}, which
DOES invoke {bf:nwload} after creating the new network, generating its Stata variables immediately. This is convenient for a single network at
a time, but can exhaust Stata's variable limit if used while generating many networks at once.

{pstd}
For example this code generates 1000 random networks with 100 nodes each without ever loading any of them as Stata variables (the default -
{bf:xvars} is NOT specified). Afterwards, {bf:nwload} is used to load just one (the current network, here, the last random network that has
been generated) as Stata variables.

	{cmd:. nwrandom 100, prob(.1) ntimes(1000)}
	{cmd:. nwload}

{pstd}
Notice that {cmd:nwload} does not import or create a network, it simply creates Stata variables to represent a network. Only networks that 
already do exist in Stata, i.e. have been set by {help nwset} or imported by {help nwimport} or {help nwuse} or {help webnwuse} or
created by a {help nw_topical##generator:network generator}, can be loaded as Stata variables. If two different networks use the
same variable names, the Stata variables are overwritten.


{title:See also}
   
   {help nwcurrent}, {help nwsync}, {help nwuse}, {help nwimport}, {help nw_intro##limits:feasible network sizes}

last certified : 23 Aug 2026
