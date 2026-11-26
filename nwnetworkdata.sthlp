{smcl}
{* *! version 1.2.0  22nov2026 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##import:[NW-2.2] Import/Export}

{title:Title}

{p2colset 9 23 29 2}{...}
{p2col :nwnetworkdata {hline 2}}Import the networks of the networkdata collection (R package by David Schoch) from GitHub{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{phang}
List the available data sets (one row per data set, or one row per network)

{p 8 16 2}
{cmd:nwnetworkdata} {cmd:list} [{it:pattern}] [{cmd:,} {opt net:works} {opt dir:ected} {opt undir:ected} {opt two:mode} {opt one:mode}
{opt weight:ed} {opt mult:iple} {opt loops} {opt temp:oral} {opt k:ind(string)} {opt clear}]


{phang}
Show the properties of the networks of a data set

{p 8 16 2}
{cmd:nwnetworkdata} {cmd:describe} {it:dataname}


{phang}
Load one network, or all networks of a data set, as nwcommands networks

{p 8 16 2}
{cmd:nwnetworkdata} [{cmd:load}] {it:name} [{cmd:,} {opt nwclear} {opt clear} {opt replace} {opt name(newname)}
{opt el:ement(numlist)} {opt valuea:ttr(varname)} {opt bin:ary} {opt noattrs} {opt from(source)} {opt ref:resh} {opt withr}]


{phang}
Load the tie list or the node table, with all attributes, as an ordinary dataset

{p 8 16 2}
{cmd:nwnetworkdata} {cmd:edges} {it:name} [{cmd:,} {opt clear} {opt el:ement(#)} {opt from(source)} {opt withr}]

{p 8 16 2}
{cmd:nwnetworkdata} {cmd:nodes} {it:name} [{cmd:,} {opt clear} {opt el:ement(#)} {opt from(source)} {opt withr}]


{phang}
Load one of the three tables of an ego-centered data set (class {it:egor})

{p 8 16 2}
{cmd:nwnetworkdata} {cmd:tables} {it:dataname} {cmd:,} {opt tab:le(ego|alter|aatie)} [{opt clear} {opt from(source)} {opt withr}]


{phang}
Source and cache

{p 8 16 2}
{cmd:nwnetworkdata} {cmd:source} [{cmd:set} {it:url_or_folder} | {cmd:default}]

{p 8 16 2}
{cmd:nwnetworkdata} {cmd:cache} [{cmd:clear}]


{marker description}{...}
{title:Description}

{pstd}
{cmd:nwnetworkdata} imports the networks of David Schoch's R package {it:networkdata}
(https://github.com/schochastics/networkdata) into nwcommands: 990 R objects, which are 2,274 networks (917 single {it:igraph} objects and
72 lists holding 1,357 further networks, for example the waves of a longitudinal study, the seasons of a series or the groups of an animal study)
plus one ego-centered ({it:egor}) object that is not a network.
Every data set is documented (description, source, references) on
{browse "https://nwcommands.org/datasets/schoch/":nwcommands.org/datasets/schoch}; {cmd:nwnetworkdata describe} {it:name} shows its size and attributes.

{pstd}
{bf:This package contains no network data.} When you ask for a network, {cmd:nwnetworkdata} downloads the original file
({it:dataname}{cmd:.rda}) from the GitHub repository of the R package and keeps it in a cache folder of yours. The file is an R
data file (compressed, in R's serialization format); {cmd:nwnetworkdata} reads it, on your computer, with Stata alone
({bf:no R is needed}): it decompresses the file, decodes the R data, takes the {it:igraph} objects in it and writes csv tables into the cache;
the network is built from these with {helpb nwfromedge}. The result is the same as when R and its package igraph do the conversion.
If the reader meets something it does not handle (which does not happen in the 990 objects of the collection except the {it:egor} object,
see below) it says so and uses R, if you have it ({cmd:Rscript} is looked for in the usual places of a Windows installation and in the path, on
macOS and Linux also in /usr/local/bin, /opt/homebrew/bin and /usr/bin; choose another with {cmd:global nwnd_rscript "path/to/Rscript"}); otherwise it
stops with an error and never guesses. A damaged or truncated file is refused (error 610), as is a file that is larger than
the limits of the reader. The option {opt withr} converts with R and the R package igraph ({cmd:install.packages("igraph")}) instead; the small R script that does it
comes with this command ({cmd:nwnetworkdata_convert.R}) and only reads the downloaded file and writes the csv tables.
The only file shipped in addition to code and help is a catalogue of the names, type and size of the networks, which {cmd:list},
{cmd:describe} and the name checks use. Only names that are in the catalogue are downloaded, and only from the repository of the R package.

{pstd}
{it:name} is either the name of a network or the name of a data set. A data set that is a list of networks ({cmd:sampson},
{cmd:atp}, {cmd:animal_12}, ...) loads all its networks, which are named {it:dataname}{cmd:_1}, {it:dataname}{cmd:_2}, ... in the order
of the list; one of them can be loaded by that name ({cmd:nwnetworkdata sampson_3}) or by {opt element()}. Networks that are not part
of a list have the name of the data set.

{pstd}
Directedness, two-mode status, loops and whether the ties are valued are taken from the original {it:igraph} object; nothing has to be
specified. Node labels are the {cmd:name} vertex attribute of the {it:igraph} object (cleaned to valid names: letters, digits and underscores,
at most 28 characters, unique), or {cmd:n1}, {cmd:n2}, ... if the object has no vertex names. The unchanged vertex names are kept in the
variable {cmd:nd_name}. Every other vertex attribute becomes a variable of the current dataset, in the order of the nodes
(attribute names are made valid Stata names: other characters become {cmd:_}). With a list of networks the dataset holds the attributes of the
last network loaded; use {cmd:nwnetworkdata nodes} {it:name} to get the node table of any network.


{marker options}{...}
{title:Options}

{phang}
{cmd:nwclear} specifies that it is okay to replace all network data in memory, even though the current network data have not been saved to disk.
It removes all networks in memory first (as {help nwwebuse} does).

{phang}
{cmd:clear} specifies that it is okay to replace the data in memory, but the networks in memory are kept.

{phang}
{cmd:replace} replaces a network that exists already under the name that is loaded.

{phang}
{cmd:name(}{it:newname}{cmd:)} names the network {it:newname}. For a data set with several networks, {it:newname} is the prefix:
{it:newname}{cmd:_1}, {it:newname}{cmd:_2}, ...

{phang}
{cmd:element(}{it:numlist}{cmd:)} loads only the listed elements of a list of networks.

{phang}
{cmd:valueattr(}{it:varname}{cmd:)} takes the tie values from this numeric edge attribute (default: {cmd:weight}, if the network has one).

{phang}
{cmd:binary} ignores edge weights and loads a binary network.

{phang}
{cmd:noattrs} does not load the node attributes into the dataset (only the labels).

{phang}
{cmd:from(}{it:source}{cmd:)} is where the original {cmd:.rda} files are fetched from: an address in the repository
{it:https://raw.githubusercontent.com/schochastics/networkdata/} (other addresses are refused) or an existing local folder that
contains the files (for example a clone of the repository). Default: the global {cmd:$nwnd_source} set by {cmd:nwnetworkdata source set};
if empty, {it:https://raw.githubusercontent.com/schochastics/networkdata/main/data}.

{phang}
{cmd:refresh} downloads and converts the data set again, also if it is in the cache.

{phang}
{cmd:withr} converts with R and the R package igraph instead of the reader without R (a data set that is in the cache and was converted
before is converted again). It needs {cmd:Rscript}; error 601 if R or igraph is missing.

{phang}
{cmd:list} options select networks: {cmd:directed}, {cmd:undirected}, {cmd:twomode} (also {cmd:onemode}), {cmd:weighted}, {cmd:multiple}
(networks with multiple edges), {cmd:loops}, {cmd:temporal} (networks whose edges have a time stamp), {cmd:kind(igraph)} or
{cmd:kind(list_of_igraph)}, and a text {it:pattern} that has to be part of the name. {cmd:networks} lists networks instead of data sets;
{cmd:clear} leaves the list in memory as a dataset (variables {cmd:obj} and {cmd:net}).


{marker cache}{...}
{title:Cache and offline use}

{pstd}
The cache is the folder {cmd:nwnd} in your PLUS directory ({cmd:sysdir}; change it with {cmd:global nwnd_cache "folder"}). It holds the
downloaded {cmd:.rda} files ({cmd:rda}), their csv conversions ({cmd:conv}) and Stata versions of these ({cmd:typed}). A data set that is in the cache
is not downloaded or converted again, so it can be used {bf:without internet connection}. If a data set
has to be downloaded and cannot be (no connection, GitHub not reachable), the command stops with error 677 and tells so; if R or igraph is
needed (option {opt withr}, or the {it:egor} object) and missing, it stops with error 601 and shows the message of R. {cmd:nwnetworkdata cache} reports the folder and the number of data sets in it,
{cmd:nwnetworkdata cache clear} deletes them. If the files of the repository change, use {opt refresh}. The catalogue was made from the
repository as of November 2026 (version 0.2.4); a data set added later is not in {cmd:list}.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:What is not a plain network.} Multiple edges and edge attributes cannot be stored in an nwcommands network, which is a matrix:
parallel edges are summed (weights) or counted (no weights), so that an unweighted multigraph becomes a valued network (121 networks;
{cmd:describe} reports it). Edge attributes other than the tie value, and the individual parallel edges, stay available with
{cmd:nwnetworkdata edges}. Edges with a time stamp (7 networks, for example {cmd:dnc_temporalGraph}) are loaded aggregated over time; they are not
loaded as temporal networks, and the times are in {cmd:nwnetworkdata edges}. Ties with the value 0 are no ties. Two-mode networks (23) are loaded
with {cmd:twomode} status, the first mode being the {it:igraph} vertices of type {cmd:FALSE}; they are limited to 20,000 nodes as all two-mode
networks in nwcommands. The object {cmd:gss_egor} (class {it:egor}) holds ego-centered survey data, three tables, no network: it is not loaded by
{cmd:nwnetworkdata gss_egor} (error 459) but with {cmd:nwnetworkdata tables gss_egor, table(ego)}, which is the one use that needs R.
Node labels from accented letters lose the accent (a letter with an accent becomes the plain letter; the unchanged names are in {cmd:nd_name}); R's own conversion
gives other labels on other systems.

{pstd}
{bf:Licence, attribution, citation.} nwnetworkdata only imports; the data are not part of this package and not distributed with it.
The R package networkdata is distributed under the MIT licence (Copyright (c) 2019 David Schoch), which covers the package itself. It documents no licence or permission for the individual
data sets, which come from many original sources and may have their own terms (the page {browse "https://nwcommands.org/datasets/schoch/":nwcommands.org/datasets/schoch} gives an overview and links to the documentation of the R package): please check
the original sources, cite them, and cite the collection: David Schoch (2022), {it:networkdata: Repository of Network Datasets},
https://doi.org/10.5281/zenodo.7189928. The tennis networks ({cmd:atp}, {cmd:wta}) were compiled from data of Jeff Sackmann
(https://github.com/JeffSackmann), whom the author asks users to credit.


{title:Stored results}

{pstd}{cmd:nwnetworkdata load} stores in {cmd:r()}:{p_end}
{synoptset 18 tabbed}{...}
{synopt:{cmd:r(n_loaded)}}number of networks loaded{p_end}
{synopt:{cmd:r(net)}}name of the last network loaded (the current network){p_end}
{synopt:{cmd:r(nets)}}names of all networks loaded{p_end}
{synopt:{cmd:r(obj)}}name of the data set{p_end}

{pstd}{cmd:nwnetworkdata list} stores {cmd:r(n_objects)} and {cmd:r(n_networks)}.{p_end}


{marker examples}{...}
{title:Examples}

{pstd}
What is there?

	{cmd:. nwnetworkdata list}
	{cmd:. nwnetworkdata list, twomode}
	{cmd:. nwnetworkdata list sampson, networks}
	{cmd:. nwnetworkdata describe karate}

{pstd}
Load Zachary's karate club and a two-mode network

	{cmd:. nwnetworkdata karate, nwclear}
	{cmd:. nwnetworkdata southern_women, nwclear}

{pstd}
Load the ten Sampson monastery networks, or just the third

	{cmd:. nwnetworkdata sampson, nwclear}
	{cmd:. nwnetworkdata sampson_3, nwclear}

{pstd}
Tennis 1968, with the player attributes age, hand and country in the dataset

	{cmd:. nwnetworkdata atp, nwclear element(1)}

{pstd}
The tie list of that network, with the surface of each match

	{cmd:. nwnetworkdata edges atp_1, clear}

{pstd}
Use a local clone of the repository (no download)

	{cmd:. nwnetworkdata source set "C:/data/networkdata/data"}

{pstd}
Convert with R instead of the reader without R

	{cmd:. nwnetworkdata karate, nwclear withr}

{pstd}
Name of Rscript, if it is not found

	{cmd:. global nwnd_rscript "C:/Program Files/R/R-4.3.0/bin/Rscript.exe"}


{title:See also}

	{help nwwebuse}, {help netexample}, {help nwfromedge}, {help nwimport}, {help nwset}

{hline}
{pstd}{it:nwcommands version 3.39.0, 26 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
