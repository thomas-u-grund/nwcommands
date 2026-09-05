---
title: "Installation & Setup"
parent: Tutorials
nav_order: 1
description: "Installing nwcommands from scratch: net install, nwinstall, and the Network Analysis menu."
---

# Installation & Setup

nwcommands isn't on Stata's built-in SSC-style search path, so installing it is a two-step
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

. which nwergm
/Users/tgrund/Library/Application Support/Stata/ado/plus/n/nwergm.ado

. ado dir nwcommands

[9] package nwcommands from https://raw.githubusercontent.com/thomas-u-grund/nwcommands/master
      nwcommands. Start here - installs nwinstall and the landing help topics; run nwinstall, all next
```

## The Network Analysis menu

Add `permanently` to also add a "Network Analysis" menu to Stata's own User menu, so every
command is reachable through a dialog box, not just the command line:

```stata
. nwinstall, permanently
```

This is worth doing even if you're comfortable typing syntax — nwcommands ships around 120
dialog boxes covering nearly every command, and they're a fast way to check an option name or
its exact syntax without leaving Stata for `help`.

{: .note }
A screenshot of the "Network Analysis" menu and a dialog box in action is coming soon.

## Updating vs. pinning a version

Re-running `nwinstall, all` at any time re-downloads and replaces everything with whatever is
currently on the `master` branch — there's no separate "update" command, because installing
*is* updating. If you need to pin to a specific point in time instead of always tracking the
latest release, `net install` accepts a `from()` option pointing at a tagged release URL rather
than the branch URL used above; see `help net` for the general mechanism.

## No internet access or admin rights?

`nwinstall, localcopy` installs by copying files directly from an nwcommands folder you already
have (zip, USB drive, shared network drive) into your own PERSONAL ado directory — no download,
no admin rights needed. See the "Computers without internet access or admin rights" section of
`help nwinstall` for the full option reference.
