{smcl}
{* *! version 1.0.0  3sept2014}{...}
{marker topic}
{helpb nwtopical##utilities:[NW-2.7] Utilities}

{title:Title}

{p2colset 9 20 23 2}{...}
{p2col :nwinstall {hline 2}}Install Stata menu/dialogs and the model packages{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwinstall}
[,
{opt gui}
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
{opth path(string)}
{opt localcopy}
{opth from(string)}
{opth dest(string)}
{opt models}
{opt everything}
{opt nogui}
{opt dupcheck}
{opth modelpkg(namelist)}
{opth release(string)}
{opth modelsfrom(string)}]



{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt gui}}install the "Network Analysis" menu permanently on your Stata (the older name {opt permanently} still works); it is set up once, however often you type it - see {help nwinstall##menu:The menu is installed once}{p_end}
{synopt:{opt remove}}remove the "Network Analysis" menu from your Stata, the line {cmd:nwinstall, usermenu} from {bf:profile.do}, and the nwcommands files{p_end}
{synopt:{opt help}}download the help files{p_end}
{synopt:{opt ado}}download the core command (.ado) files{p_end}
{synopt:{opt ext}}accepted for backward compatibility, does nothing (the "extension" commands it used to download separately - {help nwdissimilar}, {help nwhierarchy}, {help nwdendrogram} - are ordinary commands shipped with every other {opt ado}/{opt help} install, and were never genuinely distinct from the rest of the package){p_end}
{synopt:{opt dialog}}download the dialog boxes{p_end}
{synopt:{opt usermenu}}update menu items for dialog-boxes{p_end}
{synopt:{opt update}}refresh the installed menu (an internal, self-recursive flag: re-invokes {cmd:nwinstall, help usermenu}){p_end}
{synopt:{opt downloadoff}}rebuild the menu from what is already installed, without downloading anything (used internally by {bf:profile.do} integration; equivalent to {opt usermenu} for this purpose){p_end}
{synopt:{opth menu(string)}}install in this menu; default = "stUser"{p_end}
{synopt:{opt all}}download the core commands, help files, and dialog boxes, and set up the menu (as {opt gui}); with {opt nogui} the menu is left out{p_end}
{synopt:{opth path(string)}}directory where profile.do is installed; default: sysdir_stata{p_end}
{synopt:{opt localcopy}}install by copying files from an existing local nwcommands folder instead of downloading from GitHub - see {help nwinstall##offline:Computers without internet access or admin rights} below{p_end}
{synopt:{opth from(string)}}with {opt localcopy}: the local folder to copy nwcommands files from; default: the current directory{p_end}
{synopt:{opth dest(string)}}with {opt localcopy}: the local ado directory to copy files into; default: your PERSONAL ado directory (already on Stata's ado path, so nothing further needs to be configured for the default case){p_end}

{synopt:{opt models}}also install the four model packages {cmd:nwsaom}, {cmd:nwergm}, {cmd:nwdynam} and {cmd:nwrem} (see below); with {opt remove} they are uninstalled{p_end}
{synopt:{opt everything}}install the core (everything {opt all} installs) and the four model packages (what {opt models} installs) as one set, set up the menu (as {opt gui}), and show all five versions at the end{p_end}
{synopt:{opt nogui}}with {opt all} or {opt everything}: do not set up the menu and do not touch {bf:profile.do}{p_end}
{synopt:{opt dupcheck}}report dialog files (.dlg) that exist in more than one folder of the ado path; changes nothing{p_end}
{synopt:{opth modelpkg(namelist)}}install only these model packages (any of nwsaom, nwergm, nwdynam, nwrem); can be used alone{p_end}
{synopt:{opth release(string)}}with {opt models} or {opt modelpkg()}: the release to install, for example {cmd:v1.0.0}; default: the current release{p_end}
{synopt:{opth modelsfrom(string)}}with {opt models}: a folder or URL with one subfolder per package, instead of the GitHub repositories (for local clones and offline installs){p_end}
{synoptline}


{marker models}{...}
{title:The model packages}

{pstd}
The commands {cmd:nwsaom} (stochastic actor-oriented models), {cmd:nwergm} (exponential random graph models), {cmd:nwdynam} (dynamic network actor models) and {cmd:nwrem} (relational event models) are packages of their own, installed separately from {cmd:nwcommands} and distributed under the GNU General Public License, version 3.
They need {cmd:nwcommands} (install it first, then run {cmd:nwinstall, all}).
{cmd:nwinstall, models} installs all four from their GitHub repositories; {cmd:nwinstall, modelpkg(nwsaom nwergm)} installs only some, and {cmd:nwinstall, models release(v1.0.0)} installs a particular release.
{cmd:nwinstall, all} installs the core only (and sets up the menu, unless {opt nogui}) and ends with a hint about the model packages.
{cmd:nwinstall, models} and {cmd:nwinstall, modelpkg()} install packages only; they do not touch the menu or {bf:profile.do}.
{cmd:nwinstall, everything} installs the core and the four model packages in one step, sets up the {it:Network Analysis} menu with the dialog boxes (the same as adding {opt gui}; add {opt nogui} to skip that), and prints the version of each package at the end (as {help nwversion} does).
Before anything is installed, {opt everything} checks that every model repository can be reached and that no model needs a newer core than the one being installed; if not, it stops with a message that names the package and installs nothing.
{cmd:nwinstall, all models} is the same as {cmd:nwinstall, everything}.
With {opt everything} (and with {opt models}), {opt from()} is the source of the core package, {opt modelsfrom()} the folder with one subfolder per model package, and {opt release()} the release of the model packages; for an offline install point both at local folders.
Each package has a {cmd:version} subcommand, for example {cmd:nwsaom version}.
Updating {cmd:nwcommands} never replaces an installed model package.

{title:Description}

{pstd}
This command loads Stata dialog boxes for the nwcommands and installs a menu "Network Analysis" inside the "User" menu. Almost
all nwcommands (and their functions) can be executed via dialog boxes. Notice, however, that some more 
advanced functions are only available through Stata syntax (see {help nwcommands}).



{marker menu}{...}
{title:The menu is installed once}

{pstd}
{opt gui} (and therefore {opt all} and {opt everything}, unless you add {opt nogui}) puts the single line {cmd:nwinstall, usermenu} into your {bf:profile.do}, so that Stata builds the {it:Network Analysis} menu in the {it:User} menu each time it starts.
The line is never written twice, however often you run {cmd:nwinstall}:

{phang2}o  The older spellings of the line ({cmd:nwinstall, downloadoff}, extra spaces, a {cmd:quietly} in front) count as the same line; extra copies are dropped, and the rest of your {bf:profile.do} is kept as it was.{p_end}
{phang2}o  If {bf:profile.do} (or another {bf:profile.do} Stata reads, in your PERSONAL, SITE or home folder or the current folder) already starts a {it:Network Analysis} menu in some other way, for example with a {cmd:window menu} line of your own, no second menu is added; {cmd:nwinstall} names the line and the file in a message. Lines it cannot identify with certainty are never deleted.{p_end}
{phang2}o  Within one session the menu is rebuilt from an empty {it:User} menu, so typing the command twice shows every entry once. Note that this clears all other menu entries you added to the {it:User} menu in that session.{p_end}
{phang2}o  The menu entries of the model packages {cmd:nwsaom} and {cmd:nwergm} appear only when the package's dialog boxes are installed.{p_end}
{phang2}o  If the menu cannot be built (a Stata without menus, a batch run), you get a note and the installation goes on; nothing fails.{p_end}
{phang2}o  {cmd:nwinstall, remove} takes the menu, the {cmd:nwinstall, usermenu} line and the nwcommands files away again.{p_end}

{pstd}
{opt dupcheck} lists dialog files that exist in more than one folder of the ado path (for example an old copy in your PERSONAL folder next to the installed one). Stata uses the first copy it finds; {cmd:nwinstall} tells you which one that is and deletes nothing.
{cmd:nwinstall, all} runs this check at the end.

{title:Supported network types}

{pstd}
Not applicable - installs/manages this package's own Stata menu, dialogs, and update mechanism; does not read or depend on any network's own content, directed/valued/two-mode status, or tie values.

{title:Example}

{pstd}
New to nwcommands? The full install is two commands:

	{cmd:. net install nwcommands, from(https://nwcommands.org/net/) replace}{p_end}
	{cmd:. nwinstall, everything}

{pstd}
The first command installs just {cmd:nwinstall} itself and the landing help topics (see {help nwcommands}); if {cmd:nwcommands.org} cannot be reached, {cmd:from("https://raw.githubusercontent.com/thomas-u-grund/nwcommands/main/")} works as well. The second downloads
everything else - the core commands, all help files, and the dialog boxes with the {it:Network Analysis} menu (set up once, in {bf:profile.do}) - and the four model packages
{cmd:nwsaom}, {cmd:nwergm}, {cmd:nwdynam} and {cmd:nwrem}. To install the core only, type {cmd:nwinstall, all}; to leave the menu out, add {opt nogui}.
nwcommands needs Stata 17 or later (tested with Stata 17 and 18; StataBE is enough).


{pstd}
This installs a menu for the nwcommands:

	{cmd:. nwinstall, gui}


{marker offline}{title:Computers without internet access or admin rights}

{pstd}
The two-command install above needs {cmd:net install} to reach nwcommands.org and GitHub, and writes into a
Stata-managed ado directory. Some machines - locked-down office computers, air-gapped
servers, anywhere outbound internet access is blocked - cannot do either. For these,
{opt localcopy} installs by copying files directly from an nwcommands folder you already
have (e.g. handed to you as a zip file, on a USB drive, or over a shared network drive),
with no download and no admin rights required.

{pstd}
Step by step:

{phang}
1. Get the full nwcommands folder onto the computer somehow (email, USB drive, shared
drive - anything that is not {cmd:net install}) and unzip it if needed. This folder must be
the full source folder, not just a couple of files - it needs the {cmd:.ado}/{cmd:.sthlp}/
{cmd:.dlg} files and {cmd:lib/lnwcommands.mlib} together.{p_end}

{phang}
2. In Stata, {cmd:cd} to that folder (or note its full path) and run:{p_end}

{phang2}{cmd:. cd "C:\path\to\nwcommands_2016"}{p_end}
{phang2}{cmd:. nwinstall, localcopy all}{p_end}

{phang}
This copies every {cmd:.ado}/{cmd:.sthlp}/{cmd:.dlg}/{cmd:.idlg} file (and the compiled
{cmd:lnwcommands.mlib}) into your {bf:PERSONAL} ado directory - already on Stata's default
ado path, the same one plain {cmd:sysdir} lists, and always somewhere in your own user
profile, so it needs no admin rights on any platform. Nothing further needs to be set for
this default case: {cmd:nwset}, {cmd:nwdegree}, and the rest are immediately available, and
so are the dialog boxes (e.g. {cmd:db nwplot}).{p_end}

{phang}
3. To also get the "Network Analysis" menu:{p_end}

{phang2}{cmd:. nwinstall, gui}{p_end}

{phang}
This is the same {opt gui} step used after a normal install (step 3 does not depend
on {opt localcopy} at all - it only edits your local {cmd:profile.do}).{p_end}

{pstd}
If even your PERSONAL ado directory is not writable (rare, but possible on some managed
machines), point {opt dest()} at any folder you can write to instead, e.g. a folder on a
network drive or an external disk:

	{cmd:. nwinstall, localcopy all dest("D:\my_ado")}

{pstd}
In that case Stata will not find it automatically, so add it to your ado path every session:

	{cmd:. adopath ++ "D:\my_ado"}

{pstd}
or make that permanent by adding the same line to your own {cmd:profile.do} (see {help profiles}).

{pstd}
{opt localcopy} accepts the same {opt ado}/{opt help}/{opt dialog}/{opt all}
selectors as the normal network install ({opt ext} is accepted but does nothing, same as
without {opt localcopy} - see {opt ext} above), so e.g. {cmd:nwinstall, localcopy dialog}
copies only the dialog boxes.

{hline}
{pstd}{it:nwcommands version 3.11.1, 28 October 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
