---
title: "Installation & Setup"
parent: Tutorials
nav_order: 1
description: "Installing nwcommands 3.0.0 from scratch, installing the model packages, choosing a release, and updating."
---

# Installation & Setup

This page covers the core `nwcommands` (version 3.0.0) and the four model packages (`nwsaom`,
`nwergm`, `nwdynam`, `nwrem`), which are installed separately.

nwcommands isn't on Stata's built-in SSC-style search path, so installing the core is a two-step
process: first you tell Stata *where* to look (`net from`), then you install a small bootstrap
package (`nwinstall` itself), and finally `nwinstall` downloads everything else for you.

## Installing from scratch

```stata
. net from "https://raw.githubusercontent.com/thomas-u-grund/nwcommands/master"
------------------------------------------------------------------------------------------------------------------
https://raw.githubusercontent.com/thomas-u-grund/nwcommands/master/
nwcommands: Network Analysis for Stata
------------------------------------------------------------------------------------------------------------------

nwcommands. Start here - net install this first, then run nwinstall, all
nwcommands-ado. Social Network Analysis Using Stata (part 1 of 3)
nwcommands-ado. Social Network Analysis Using Stata (part 2 of 3)
nwcommands-ado. Social Network Analysis Using Stata (part 3 of 3)
nwcommands-hlp. Social Network Analysis Using Stata - Help Files (part 1 of 2)
nwcommands-hlp. Social Network Analysis Using Stata - Help Files (part 2 of 2)
nwcommands-dlg. Social Network Analysis Using Stata - Dialog Boxes (part 1 of 2)
nwcommands-dlg. Social Network Analysis Using Stata - Dialog Boxes (part 2 of 2)

PACKAGES you could -net describe-:
    nwcommands        
    nwcommands-ado1   
    nwcommands-ado2   
    nwcommands-ado3   
    nwcommands-hlp1   
    nwcommands-hlp2   
    nwcommands-dlg1   
    nwcommands-dlg2   
------------------------------------------------------------------------------------------------------------------

. net install nwcommands
checking nwcommands consistency and verifying not already installed...
installing into /Users/tgrund/Library/Application Support/Stata/ado/plus/...
installation complete.
```

`net install nwcommands` only installs the `nwinstall` command itself, plus a couple of landing
help topics — deliberately small, so the second step can do the real work and show you what's
happening.

(The package listing shown in the transcripts below is from an earlier run and may differ slightly
between releases.)

## Installing everything

`nwinstall, all` downloads and installs every command's `.ado`/`.sthlp` file plus every dialog
box, one group at a time (ado files, then help files, then dialog boxes) — so the same package
listing genuinely scrolls by three times below. That's expected, not a repeated mistake in this
page:

```stata
. nwinstall, all
------------------------------------------------------------------------------------------------------------------
https://raw.githubusercontent.com/thomas-u-grund/nwcommands/master/
nwcommands: Network Analysis for Stata
------------------------------------------------------------------------------------------------------------------

nwcommands. Start here - net install this first, then run nwinstall, all
nwcommands-ado. Social Network Analysis Using Stata (part 1 of 3)
nwcommands-ado. Social Network Analysis Using Stata (part 2 of 3)
nwcommands-ado. Social Network Analysis Using Stata (part 3 of 3)
nwcommands-hlp. Social Network Analysis Using Stata - Help Files (part 1 of 2)
nwcommands-hlp. Social Network Analysis Using Stata - Help Files (part 2 of 2)
nwcommands-dlg. Social Network Analysis Using Stata - Dialog Boxes (part 1 of 2)
nwcommands-dlg. Social Network Analysis Using Stata - Dialog Boxes (part 2 of 2)

PACKAGES you could -net describe-:
    nwcommands        
    nwcommands-ado1   
    nwcommands-ado2   
    nwcommands-ado3   
    nwcommands-hlp1   
    nwcommands-hlp2   
    nwcommands-dlg1   
    nwcommands-dlg2   
------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
https://raw.githubusercontent.com/thomas-u-grund/nwcommands/master/
nwcommands: Network Analysis for Stata
------------------------------------------------------------------------------------------------------------------

nwcommands. Start here - net install this first, then run nwinstall, all
nwcommands-ado. Social Network Analysis Using Stata (part 1 of 3)
nwcommands-ado. Social Network Analysis Using Stata (part 2 of 3)
nwcommands-ado. Social Network Analysis Using Stata (part 3 of 3)
nwcommands-hlp. Social Network Analysis Using Stata - Help Files (part 1 of 2)
nwcommands-hlp. Social Network Analysis Using Stata - Help Files (part 2 of 2)
nwcommands-dlg. Social Network Analysis Using Stata - Dialog Boxes (part 1 of 2)
nwcommands-dlg. Social Network Analysis Using Stata - Dialog Boxes (part 2 of 2)

PACKAGES you could -net describe-:
    nwcommands        
    nwcommands-ado1   
    nwcommands-ado2   
    nwcommands-ado3   
    nwcommands-hlp1   
    nwcommands-hlp2   
    nwcommands-dlg1   
    nwcommands-dlg2   
------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
https://raw.githubusercontent.com/thomas-u-grund/nwcommands/master/
nwcommands: Network Analysis for Stata
------------------------------------------------------------------------------------------------------------------

nwcommands. Start here - net install this first, then run nwinstall, all
nwcommands-ado. Social Network Analysis Using Stata (part 1 of 3)
nwcommands-ado. Social Network Analysis Using Stata (part 2 of 3)
nwcommands-ado. Social Network Analysis Using Stata (part 3 of 3)
nwcommands-hlp. Social Network Analysis Using Stata - Help Files (part 1 of 2)
nwcommands-hlp. Social Network Analysis Using Stata - Help Files (part 2 of 2)
nwcommands-dlg. Social Network Analysis Using Stata - Dialog Boxes (part 1 of 2)
nwcommands-dlg. Social Network Analysis Using Stata - Dialog Boxes (part 2 of 2)

PACKAGES you could -net describe-:
    nwcommands        
    nwcommands-ado1   
    nwcommands-ado2   
    nwcommands-ado3   
    nwcommands-hlp1   
    nwcommands-hlp2   
    nwcommands-dlg1   
    nwcommands-dlg2   
------------------------------------------------------------------------------------------------------------------
```

Two commands from the real run above confirm everything landed correctly:

```stata
. which nwinstall
/Users/tgrund/Library/Application Support/Stata/ado/plus/n/nwinstall.ado
*! v1.5.0 __ 17 Sep 2015 __ 13:09:53
*! v1.5.1 __ 17 Sep 2015 __ 14:54:23
*! v2.1.0 __ added LOCALcopy/from()/dest() offline install path

. which nwdegree
/Users/tgrund/Library/Application Support/Stata/ado/plus/n/nwdegree.ado

. ado dir nwcommands

[9] package nwcommands from https://raw.githubusercontent.com/thomas-u-grund/nwcommands/master
      nwcommands. Start here - installs nwinstall and the landing help topics; run nwinstall, all next
```

## The Network Analysis menu

Add `gui` to also add a "Network Analysis" menu to Stata's own User menu, so every
command is reachable through a dialog box, not just the command line:

```stata
. nwinstall, gui
```

This is worth doing even if you're comfortable typing syntax — nwcommands ships around 120
dialog boxes covering nearly every command, and they're a fast way to check an option name or
its exact syntax without leaving Stata for `help`.

{: .note }
A screenshot of the "Network Analysis" menu and a dialog box in action is coming soon.

## Installing the model packages

The model commands are packages of their own, released under the GPL-3, and need the core
installed first (the core itself keeps its own licence):

| Package | Model | Install |
|---|---|---|
| `nwsaom` | stochastic actor-oriented models | `net install nwsaom, from(https://raw.githubusercontent.com/thomas-u-grund/nwsaom/main/)` |
| `nwergm` | exponential-family random graph models | `net install nwergm, from(https://raw.githubusercontent.com/thomas-u-grund/nwergm/main/)` |
| `nwdynam` | dynamic network actor models | `net install nwdynam, from(https://raw.githubusercontent.com/thomas-u-grund/nwdynam/main/)` |
| `nwrem` | relational event models | `net install nwrem, from(https://raw.githubusercontent.com/thomas-u-grund/nwrem/main/)` |

All four at once, from the core:

```stata
. nwinstall, models
```

`nwinstall, modelpkg(nwsaom nwergm)` installs only the ones you name, and `release(v1.0.1)`
picks a release. For a computer without internet access, `modelsfrom()` takes a folder with one
subfolder per package. Here is that offline form in a real run (`nwversion` before and after; the folder paths are those of the machine it ran on):

```stata
. nwversion

nwcommands 3.0.0 (24oct2026), core package; Stata 18, MacOSX
Model packages (separate, GPL-3; install with nwinstall, models):
  nwsaom  not installed
  nwergm  not installed
  nwdynam not installed
  nwrem   not installed

. nwinstall, models modelsfrom("/Users/tgrund/FILES_NEW/SOFTWARE")

Installing nwsaom from /Users/tgrund/FILES_NEW/SOFTWARE/nwsaom/ ...
~/.../n/nwsaom.ado
*! version 1.0.1  24oct2026 nwcommands: stochastic actor-oriented model (SAOM) estimation, v1 (+ harmonisation unit 26 co
> -evolution, N-wave, avsim, native backend)

Installing nwergm from /Users/tgrund/FILES_NEW/SOFTWARE/nwergm/ ...
~/.../n/nwergm.ado
*! version 1.0.1  24oct2026 nwergm

Installing nwdynam from /Users/tgrund/FILES_NEW/SOFTWARE/nwdynam/ ...
~/.../n/nwdynam.ado
*! version 1.0.1  24oct2026 nwdynam

Installing nwrem from /Users/tgrund/FILES_NEW/SOFTWARE/nwrem/ ...
~/.../n/nwrem.ado
*! version 1.0.1  24oct2026 nwrem

Model packages installed. Each has a version command, e.g. nwsaom version.
They are free software (GPL-3) and are installed separately from the nwcommands core;
updating nwcommands never overwrites them.

. nwversion

nwcommands 3.0.0 (24oct2026), core package; Stata 18, MacOSX
Model packages (separate, GPL-3; install with nwinstall, models):
  nwsaom  1.0.1  (24oct2026)
  nwergm  1.0.1  (24oct2026)
  nwdynam 1.0.1  (24oct2026)
  nwrem   1.0.1  (24oct2026)
```

`nwversion` shows the core version and which model packages are installed; each package also has its
own `<name> version` subcommand (for example `nwsaom version`), which stores the release in
`r(version)`.

## Updating vs. pinning a version

Re-running `nwinstall, all` at any time re-downloads and replaces everything with whatever is
currently on the `master` branch — there's no separate "update" command, because installing
*is* updating. The model packages update the same way: repeat the `net install` line with
`replace`, for example

```stata
. net install nwsaom, from(https://raw.githubusercontent.com/thomas-u-grund/nwsaom/main/) replace
```

Updating the core never overwrites a model package, and updating a model package never touches
the core, so you decide separately when to move each one.

To pin a specific release instead of tracking the latest, point `from()` at the release tag:

```stata
. net install nwcommands, from(https://raw.githubusercontent.com/thomas-u-grund/nwcommands/v3.0.0/) replace
. net install nwsaom, from(https://raw.githubusercontent.com/thomas-u-grund/nwsaom/v1.0.1/) replace
```

(or `nwinstall, models release(v1.0.1)` for the model packages). See `help net` for the general
mechanism.

## No internet access or admin rights?

`nwinstall, localcopy` installs by copying files directly from an nwcommands folder you already
have (zip, USB drive, shared network drive) into your own PERSONAL ado directory — no download,
no admin rights needed. See the "Computers without internet access or admin rights" section of
`help nwinstall` for the full option reference.
