{smcl}
{* *! version 1.0.0  5sep2026}{...}
{phang}
{help nwcommands:NW-7 internals} {hline 2} Internal helper files

{title:Contents}

{col 14}Section{col 31}Description
{col 14}{hline 46}
{help nwinternals##overview:{col 14}{bf:[NW-7.1]}{...}{col 31}{bf:Overview}}

{help nwinternals##resolution:{col 14}{bf:[NW-7.2]}{...}{col 31}{bf:Network resolution and identification}}

{help nwinternals##expressions:{col 14}{bf:[NW-7.3]}{...}{col 31}{bf:Network-expression parsing}}

{help nwinternals##dialogs:{col 14}{bf:[NW-7.4]}{...}{col 31}{bf:Dialog-box generation}}

{help nwinternals##egen:{col 14}{bf:[NW-7.5]}{...}{col 31}{bf:egen extension functions}}

{help nwinternals##misc:{col 14}{bf:[NW-7.6]}{...}{col 31}{bf:Other small utilities}}

{help nwinternals##defs:{col 14}{bf:[NW-7.7]}{...}{col 31}{bf:Shared error-code definitions}}


{marker overview}{...}
{title:Overview}

{pstd}
Alongside the roughly 130 documented {cmd:nw*} commands, this package ships a number of
leading-underscore files (e.g. {cmd:_nwsyntax.ado}) that are installed but not meant to be
called by name directly. They exist purely to share logic between the real, documented
commands - the same role Stata's own official commands use a leading underscore for
throughout {cmd:ado/base/}.

{pstd}
This page exists so that a curious user finds an explanation somewhere, rather than these
files turning up unexplained in an installed-file listing; it is not a tutorial for using
them. If you are writing your own command against this package's own API (rather than just
using the documented {cmd:nw*} commands), see {help nwprogramming} instead - several of the
files below are exactly the shared helpers that page's own worked example uses.


{marker resolution}{...}
{title:Network resolution and identification}

{pstd}
{cmd:_nwsyntax} is the package's central dispatcher: almost every documented command's
leading argument (an optional {help netname} or {help netlist}, falling back to the
{help nwcurrent:current network} when omitted) is resolved through it. {cmd:_nwname} holds
the real implementation behind {help nwname} (a network's own name and
directed/valued/two-mode metadata). {cmd:_nwnodeid}/{cmd:_nwnodelab} look up a node's
numeric id from its label and vice versa. {cmd:_nwtomata} returns a network's adjacency
matrix as a Mata object or a plain copy - the real implementation behind {help nwtomata}.
{cmd:_nwdatasync} keeps a network's optional Stata-variable representation (see
{help nwload}'s {cmd:xvars}) synchronized with the underlying Mata network object after a
structural change. {cmd:_nwsetobs} sets the working dataset's observation count to match a
network's node count.


{marker expressions}{...}
{title:Network-expression parsing}

{pstd}
{cmd:_nwevalnetexp}/{cmd:_nwexpnetexp} parse and evaluate the {help netexp} mini-language
(matrix-style expressions over networks, e.g. inside {help nwgenerate}/{help nwreplace}).
{cmd:_nwevalnetexp} is also documented on its own (see {help netexp}) as the one file in
this group a programmer may call directly, when writing a command that needs to accept a
{help netexp} argument itself.


{marker dialogs}{...}
{title:Dialog-box generation}

{pstd}
{cmd:_nwdialog}, {cmd:_nwdialog_append}, {cmd:_nwdialog_clusters}, and
{cmd:_nwdialog_lablist} hold the shared logic behind the roughly 120 {cmd:.dlg} dialog
boxes reachable from Stata's "Network Analysis" menu (see {help nwinstall}) - populating a
dialog's network/cluster/label dropdowns with whatever is currently loaded, rather than
each dialog file duplicating that logic.


{marker egen}{...}
{title:egen extension functions}

{pstd}
{cmd:_gnwdegree} and {cmd:_growmedian2} follow Stata's own {help egen} extension-function
naming requirement ({cmd:egen} looks for a file named {cmd:_g}{it:function} automatically)
- they are never called by name directly, only ever reached via
{cmd:egen newvar = nwdegree(...)}-style syntax.


{marker misc}{...}
{title:Other small utilities}

{pstd}
{cmd:_opts_oneof} validates that at most one of a set of mutually exclusive suboptions was
specified, returning a clear error naming all of them if more than one was. {cmd:_extract_valuelabels}
reads a variable's Stata value label into a usable form. {cmd:_nwedgelabs} is a small,
currently-incomplete helper intended to return edge labels for {help nwtabulate}.


{marker defs}{...}
{title:Shared error-code definitions}

{pstd}
{cmd:unw_defs} does not follow the leading-underscore convention above (it predates it), but
belongs on this page for the same reason: it is called by nearly every documented command to
populate a shared table of this package's own error-code local macros (see
{help nwerrorcodes} for the user-facing meaning of each code) and a handful of other
commonly-needed locals, rather than each command redefining the same table itself.
