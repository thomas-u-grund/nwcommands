{smcl}
{* *! version 1.0.0  3sept2014}{...}
{marker topic}
{helpb nw_topical##utilities:[NW-2.7] Utilities}

{title:Title}

{p2colset 9 20 23 2}{...}
{p2col :nwinstall {hline 2}}Install Stata menu/dialogs{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwinstall}
[,
{opt permanently}
{opt remove }
{opt help}
{opt ado}
{opt ext}
{opt dialog}
{opt usermenu}
{opt update}
{opt downloadoff}
{opt menu(string)}
{opt all}
{opth path(string)}]



{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt permanently}}install the menu/dialogs permanently on your Stata{p_end}
{synopt:{opt remove}}remove the "Network Analysis" menu from your Stata{p_end}
{synopt:{opt help}}download the help files{p_end}
{synopt:{opt ado}}download the core command (.ado) files{p_end}
{synopt:{opt ext}}download the extension files{p_end}
{synopt:{opt dialog}}download the dialog boxes{p_end}
{synopt:{opt usermenu}}update menu items for dialog-boxes{p_end}
{synopt:{opt update}}refresh the installed menu (an internal, self-recursive flag: re-invokes {cmd:nwinstall, help usermenu}){p_end}
{synopt:{opt downloadoff}}rebuild the menu from what is already installed, without downloading anything (used internally by {bf:profile.do} integration; equivalent to {opt usermenu} for this purpose){p_end}
{synopt:{opth menu(string)}}install in this menu; default = "stUser"{p_end}
{synopt:{opt all}}download the help files, dialog boxes, extensions and install them permanently{p_end}
{synopt:{opth path(string)}}directory where profile.do is installed; default: sysdir_stata{p_end}


{title:Description}

{pstd}
This command loads Stata dialog boxes for the nwcommands and installs a menu "Network Analysis" inside the "User" menu. Almost
all nwcommands (and their functions) can be executed via dialog boxes. Notice, however, that some more 
advanced functions are only available through Stata syntax (see {help nwcommands}).



{title:Supported network types}

{pstd}
Not applicable - installs/manages this package's own Stata menu, dialogs, and update mechanism; does not read or depend on any network's own content, directed/valued/two-mode status, or tie values.

{title:Example}

{pstd}
New to nwcommands? The full install is two commands:

	{cmd:. net install nwcommands}{p_end}
	{cmd:. nwinstall, all}

{pstd}
The first command installs just {cmd:nwinstall} itself and the landing help topics (see {help nwcommands}); the second downloads
everything else - the core commands, all help files, and the dialog boxes - and installs them permanently.


{pstd}
This installs a menu for the nwcommands:

	{cmd:. nwinstall, permanently}


