{smcl}
{* *! version 2.0.0  4jul2016 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis:[NW-2.7] Utilities}
version 2.0.0

{title:Title}

{p2colset 9 17 22 2}{...}
{p2col :nw_datasync {hline 2} Utility to sync current network with dataset}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nw_datasync} 
[{it:{help netname}}]
[{cmd:,}
{opt generate}({it:{help varname}})
{opt off}
{opt on}
{opt overwrite}

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt generate}({it:{help varname}})}Generate variable that indicates which observations are nodes in current network{p_end}
{synopt:{opt off}}Switch datasync off{p_end}
{synopt:{opt on}}Switch datasync on; default{p_end}
{synopt:{opt overwrite}}Only used for advanced programming {p_end}
{synoptline}
{p2colreset}{...}


{title:Description}

{pstd}
Node attributes are saved in the normal Stata dataset. The observations in the dataset correspond to the nodes in a network. Beginning with version 2.0.0 both are automatically matched by the 
name of the nodes. In the dataset this match is performed on the variable {bf:_nwnode}. In case this variable does not exist, it is automatically created. 

{pstd}
Normally, there is no need to explicitly call {bf:nw_datasync}. All other nwcommands that make use of variables in the Stata dataset (e.g. node attributes) sync automatically.

{pstd}
Syncing is relatively fast, hence, there should be no need to switch it off. Furthermore, a sync is only performed when it is actually needed and the
sorting of the observations on the variable {bf:_nwnode} does not correspond to the sorting of the nodes in the network. For larger networks it can make sense
to switch syncing off. But keep in mind that then it is up to you to make sure that observations correspond to nodes in the network. In this case, the first observation in the
dataset is matched with the first node in the network and so on.

	
{title:See also}

   {help nwattributes: node attributes}
last certified : 21 Aug 2026
