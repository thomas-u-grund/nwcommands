---
title: "Start here"
nav_order: 2
has_children: true
has_toc: false
permalink: /start/
description: "New to nwcommands? Install it, plot your first network, bring in your own data and choose where to go next, in about 15 minutes."
---

# Start here
{: .no_toc }

This page takes you from installation to a plot of your own data in about 15 minutes. Follow it from top to bottom.

1. TOC
{:toc}

## 1. Before you begin

You need Stata 17 or later; Stata BE is enough. nwcommands is tested on macOS with Stata 17, 18 and 19 and on
Windows with Stata 19. Installing and loading the example data need an internet connection.

## 2. Install

Type these two lines in Stata:

```stata
. net install nwcommands, from(https://nwcommands.org/net/) replace
. nwinstall, everything
```

The second line installs the core (every command, help file and dialog box) and the seven packages for statistical
models. It also adds a "Network Analysis" menu to Stata's User menu, with one line in your `profile.do`. If you do not
want the menu, type `nwinstall, everything nogui`.

## 3. Check that it worked

`nwversion` lists the core and the model packages. This is what it showed when this page was written; your version
numbers may be newer.

```stata
. nwversion

nwcommands 3.37.2 (26nov2026), core package; Stata 17, MacOSX
Model packages (separate, GPL-3; install with nwinstall, models):
  nwsaom  1.9.2  (22nov2026)
  nwergm  1.16.1  (24nov2026)
  nwdynam 1.11.1  (22nov2026)
  nwrem   1.7.2  (23nov2026)
  nwalaam 1.4.0  (22nov2026)
  nwsbm   1.1.0  (23nov2026)
  nwlsm   1.0.6  (22nov2026)
```

<details markdown="block">
<summary>Installation problems</summary>

- **Stata answers `option everything not allowed`.** An older `nwinstall` is being used. Type `which nwinstall`: the
  path should point into Stata's `ado/plus` folder. If it says `./nwinstall.ado`, an old copy lies in the folder Stata
  was started from, which is searched first: change to another folder with `cd`. If an older copy is loaded in memory
  (for example by your `profile.do`), type `program drop nwinstall` or restart Stata. Then run
  `nwinstall, everything` again.
- **You want the core only.** Type `nwinstall, all`. The model packages can be added later with `nwinstall, models`.
  Repeating `nwinstall, everything` or `nwinstall, models` also updates them.
- **No internet access, a specific release, or other questions:** see
  [Installation and setup](../tutorials/01-installation-setup/).

</details>

## 4. Your first network

Load the marriage ties among 16 families in Renaissance Florence and describe them:

```stata
. nwwebuse florentine, nwclear

. nwsummarize flomarriage
--------------------------------------------------
   Network name:  flomarriage
   Network id:  2
   Directed: false
   Valued: false
   Two-mode: false
   Nodes: 16
   Selfloop: false
   Edges: 20
   Minimum value:  0
   Maximum value:  1
   Density:  .167
   Mean degree:  2.50
   Temporal: false
```

There are 16 families and 20 marriage ties. The density says that 17% of all possible pairs are tied. Now draw it:

```stata
. nwplot flomarriage, label(_nwnode)
```

![The marriage network of the Florentine families, with the Medici near the center]({{ '/assets/images/start/florentine.png' | relative_url }})

Each dot is a family and each line a marriage tie. One family, the Pucci, has no ties here. Which family lies
between the others most often? That is *betweenness centrality*. The option `generate()` names the new variable
that holds the result:

```stata
. nwbetween flomarriage, generate(between)

. preserve
. gsort -between
. list _nwnode between in 1/5, noobs

  +----------------------+
  |  _nwnode     between |
  |----------------------|
  |   medici        47.5 |
  | guadagni   23.166667 |
  |  albizzi   19.333333 |
  | salviati          13 |
  |  ridolfi   10.333333 |
  +----------------------+

. restore
```

The Medici score about twice as high as any other family. (`preserve` and `restore` put the rows back in their
original order after sorting. Do this whenever you sort while a network is loaded.)

## 5. Use your own data

Network data often come as two files: a list of ties and a table about the people. Here `edges.csv` has one tie per
row:

```
ego,alter
Tom,Mia
Mia,Ben
Ben,Tom
Ben,Zoe
Zoe,Ann
Zoe,Raj
Ann,Raj
```

and `people.csv` has one person per row:

```
name,dept,age
Zoe,tech,38
Ann,tech,29
Ben,sales,45
Mia,sales,31
Raj,tech,52
Tom,sales,41
```

Save both in Stata's working folder (or type your own files' names), then:

```stata
. nwclear
. clear

. import delimited using "people.csv", varnames(1) clear
. save office_people, replace

. import delimited using "edges.csv", varnames(1) stringcols(_all) clear
. nwfromedge ego alter, name(office) undirected

. generate name = _nwnode
. merge 1:1 name using office_people, nogenerate

. nwdegree office, generate(ties) silent
. list name dept age ties, noobs

  +---------------------------+
  | name    dept   age   ties |
  |---------------------------|
  |  Ann    tech    29      2 |
  |  Ben   sales    45      3 |
  |  Mia   sales    31      2 |
  |  Raj    tech    52      2 |
  |  Tom   sales    41      2 |
  |---------------------------|
  |  Zoe    tech    38      3 |
  +---------------------------+

. nwplot office, color(dept) label(name)
```

![Plot of the six people, colored by department]({{ '/assets/images/start/office.png' | relative_url }})

`nwfromedge` builds the network from the list of ties, with one row per person afterwards. `merge` then adds the
information about each person, matched by name. Check that Stata reports every row as matched. The details, and what
to do with other file formats, are in [Reproducible workflow](../tutorials/04-reproducible-workflow/) and
[Importing and exporting](../tutorials/03-importing-exporting/).

## 6. Choose your path

| You want to | Go to |
|---|---|
| learn the basics step by step | [First steps](../tutorials/nwcommands-first-steps/) |
| describe a network: centrality, groups, positions | [Describing networks](../tutorials/nwcommands-describing/) |
| fit a statistical model | [Which package do I need?](../which-package/), then that package's [tutorials](../tutorials/) |
| move over from R | [the R equivalents of each package](../which-package/#if-you-know-the-r-packages) |
| teach a course or a workshop | [Teaching and workshops](../teaching/) |
| look up one command | [Command reference](../reference/) |

## 7. Get help

- In Stata, `help` followed by a command name, for example `help nwplot`.
- Questions and problems: [Help and community](../help/).
- Using the software in your work: [Citing and licenses](../citing/).
