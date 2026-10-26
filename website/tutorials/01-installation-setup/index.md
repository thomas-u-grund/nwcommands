---
title: "Tutorial 1: Installation & Setup"
parent: "nwcommands (core)"
nav_order: 2
description: "Installing nwcommands 3.0.0 and the model packages from scratch with nwinstall, everything, installing the model packages, choosing a release, and updating."
---

# Installation & Setup

This page covers the core `nwcommands` (version 3.0.0) and the four model packages (`nwsaom`,
`nwergm`, `nwdynam`, `nwrem`), which are installed separately.

nwcommands isn't on Stata's built-in SSC-style search path, so installing the core is a two-step
process: first you tell Stata *where* to look (`net from`), then you install a small bootstrap
package (`nwinstall` itself), and finally `nwinstall` downloads everything else for you.

## Installing from scratch

```stata
. net install nwcommands, from(https://nwcommands.org/net/) replace
```

(If `nwcommands.org` is not reachable from your network, the same starter package is at
`https://raw.githubusercontent.com/thomas-u-grund/nwcommands/main/`.)
`net install nwcommands` installs only the
`nwinstall` command and a few landing help topics. That is deliberately small, so the next step can do
the real work.

## Installing everything

Requirements: Stata 17 or later. The packages are tested with Stata 17 and 18, and StataBE is enough.
Older versions are untested; on one, `nwinstall` and `nwversion` print a note but go on.

```stata
. nwinstall, everything
```

`nwinstall, everything` installs the core and the four model packages as one consistent set. It first
checks that every model package can be reached and that none needs a newer core, then it downloads every
command, every help file and every dialog box of the core, one group after the other (command files, then
help files, then dialog boxes), then the four model packages, and it prints the version of each package
at the end. While it runs, Stata prints the package listing of the repository once for each group, so the
same listing scrolls by several times. That is expected.

To install the core only, type `nwinstall, all`. It ends with the hint `To also install the model packages
type: nwinstall, models   (or nwinstall, everything)`.

To check that the installation worked, type `which nwdegree`. Stata prints the path of the installed
file, and `help nwcommands` opens the start page of the help. `nwversion` prints the version of the
core and lists the model packages, so you can see what is installed:

```stata
. nwversion

nwcommands 3.0.0 (24oct2026), core package; Stata 18, MacOSX
Model packages (separate, GPL-3; install with nwinstall, models):
  nwsaom  not installed
  nwergm  not installed
  nwdynam not installed
  nwrem   not installed
```

The Stata release and the operating system in the first line are those of the computer the page was
written on; yours will differ.

## The Network Analysis menu

Add `gui` to also install a "Network Analysis" menu in Stata's own User menu, so every command is
reachable through a dialog box, not just the command line:

```stata
. nwinstall, gui
```

`gui` is the current name of the option; the older name `permanently` still works. The option changes
your Stata start-up file (`profile.do`), so that the menu is there each time you start Stata. To take
the menu out again, type `nwinstall, remove`.

This is worth doing even if you are comfortable typing syntax. nwcommands has 120 dialog boxes
covering nearly every command, and they are a fast way to check an option name or its exact syntax
without leaving Stata for `help`.

## Installing the model packages

The model commands are packages of their own and need the core installed first. The core and all four
model packages are free software under the GNU General Public License, version 3.

| Package | Model | Install |
|---|---|---|
| `nwsaom` | stochastic actor-oriented models (SAOM) | `nwinstall, models` installs all four; one only: `net install nwsaom, from(https://raw.githubusercontent.com/thomas-u-grund/nwsaom/main/)` |
| `nwergm` | exponential random graph models (ERGM) | `nwinstall, models` installs all four; one only: `net install nwergm, from(https://raw.githubusercontent.com/thomas-u-grund/nwergm/main/)` |
| `nwdynam` | dynamic network actor models (DyNAM) | `nwinstall, models` installs all four; one only: `net install nwdynam, from(https://raw.githubusercontent.com/thomas-u-grund/nwdynam/main/)` |
| `nwrem` | relational event models (REM) | `nwinstall, models` installs all four; one only: `net install nwrem, from(https://raw.githubusercontent.com/thomas-u-grund/nwrem/main/)` |

If you installed the core alone (`nwinstall, all`), all four at once, from the core:

```stata
. nwinstall, models
```

(`nwinstall, everything` does the core and the four model packages in one step.)

`nwinstall, modelpkg(nwsaom nwergm)` installs only the ones you name, and `release(v1.0.1)` picks a
release. After the installation, `nwversion` lists each model package with its version instead of
"not installed". Each package also has its own `<name> version` subcommand (for example
`nwsaom version`), which stores the release in `r(version)`.

For a computer without internet access, `nwinstall, models` and `nwinstall, everything` can also read the packages from a folder
that contains one subfolder per package (option `modelsfrom()`; see `help nwinstall`).

## Updating vs. pinning a version

Re-running `nwinstall, everything` (or `nwinstall, all` for the core only) at any time re-downloads and replaces everything with whatever is
currently on the `master` branch — there's no separate "update" command, because installing
*is* updating. The model packages update the same way: repeat `nwinstall, models` (or `nwinstall, everything`), or, for a single package, its `net install` line with
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
