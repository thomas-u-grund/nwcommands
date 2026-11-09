---
title: "Tutorial 1: Installation & Setup"
parent: "nwcommands (core)"
nav_order: 1
description: "Installing nwcommands 3.0.0 and the model packages from scratch with nwinstall, everything, installing the model packages, choosing a release, and updating."
---

# Tutorial 1: Installation & Setup

This page covers the core `nwcommands` (version 3.0.0) and the four model packages (`nwsaom`,
`nwergm`, `nwdynam`, `nwrem`), which are installed separately.

nwcommands isn't on Stata's built-in SSC-style search path, so installing the core is a two-step
process: first you install a small starter package (`nwinstall` itself) from the address of the project, and
then `nwinstall, everything` downloads everything else for you.

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
help files, then dialog boxes), then the four model packages, then it sets up the "Network Analysis" menu
(see below), and it prints the version of each package at the end. While it runs, Stata prints the package listing of the repository once for each group, so the
same listing scrolls by several times. That is expected.

**If Stata answers `option everything not allowed`:** an older copy of `nwinstall` is being used. Type
`which nwinstall`. The path should point into Stata's `ado/plus` folder. If it says `./nwinstall.ado`, an old
copy lies in the folder Stata was started from (the current folder is searched first before the PLUS folder): change
to another folder with `cd`. If an older copy is loaded in memory (for example because your `profile.do` calls
`nwinstall`), the `net install` line replaced the files on disk but not the program in memory: type
`program drop nwinstall` (or restart Stata). Then run `nwinstall, everything` again.

To install the core only, type `nwinstall, all` (it also sets up the menu; add `nogui` to both commands to leave the menu out). It ends with the hint `To also install the model packages
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

`nwinstall, everything` (and `nwinstall, all`) also install a "Network Analysis" menu in Stata's own User menu, so every command is
reachable through a dialog box, not just the command line. To add the menu to an installation that has none, or to repair it, type:

```stata
. nwinstall, gui
```

`gui` is the current name of the option; the older name `permanently` still works. The option changes
your Stata start-up file (`profile.do`), so that the menu is there each time you start Stata. To take
the menu out again, type `nwinstall, remove`. The start-up line is written once: running `nwinstall`
again, or having the older `nwinstall, downloadoff` line in `profile.do`, never gives you a second menu. If your
`profile.do` already builds a "Network Analysis" menu in some other way, `nwinstall` tells you and adds nothing.
If the model packages are installed, there is one entry for each of them under "Statistical Models": "Stochastic actor-oriented model (nwsaom)" and "Exponential random graph model (nwergm)". The other dialogs of a package (Bayesian estimation, several networks, postestimation, simulation and so on) open from buttons inside its main dialog. An entry is shown only when that package's dialogs are installed.

To install without the menu, add `nogui`: `nwinstall, everything nogui`. If a dialog file exists in two folders of
the ado path, `nwinstall, dupcheck` shows which copy Stata uses; nothing is deleted.

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

## If a plugin does not work on your computer

The core and the model packages `nwsaom`, `nwergm` and `nwdynam` ship compiled plugins for macOS, Linux and Windows. The full test suites of the core and of all four model packages pass on Windows (347 tests, Stata 19 MP, 9 November 2026); the Linux plugins are built the same way but have not been tested on a Linux machine.
If the plugin of your platform is
missing or does not load (Stata then reports a plugin error, or a command warns that it is falling back to a slower route), compile it on your own computer:

```stata
. nwinstall, buildplugin(nwsaom)
```

`buildplugin()` takes `nwcommands`, `nwsaom`, `nwergm`, `nwdynam` or `all`. The command fetches the C source from GitHub, compiles it with the compiler of
your computer and installs the plugin where `net install` puts it, keeping an existing file as a `.prev` copy. It needs a C compiler,
installed once: on a Mac the command line tools of Xcode (`xcode-select --install`), on Linux `gcc` and `make`, on Windows Microsoft's free
[Build Tools for Visual Studio](https://visualstudio.microsoft.com/visual-cpp-build-tools/) with *Desktop development with C++*, which the command finds by
itself (if it is missing, the command says what to install). Restart Stata afterwards.

A plugin depends on the operating system and the processor, not on the version or the flavour (BE, SE, MP) of Stata, so a plugin built on your computer
works in every Stata installed there. If you would rather look at the source or build it by hand, `net get nwsaom, from(https://nwcommands.org/net/)` copies
the C files, the `Makefile` and a short build note into your current folder.

## Rebuilding the Mata libraries on your own computer

The Mata libraries of the packages are built with Stata 17. A library built by an older Stata loads in every later Stata, but a library built by a *newer* Stata is
ignored by an older one (Stata says "compiled by Stata 18, is too new to be run by this version of Stata and so was ignored", and every Mata function is then "not found",
r(3499)). If that happens, build the libraries with your own Stata:

```stata
. nwinstall, buildmata(all)
```

The command fetches the Mata source from the GitHub repositories, compiles it with the Stata that is running and installs the libraries where Stata finds the current
ones, keeping an existing file as a `.prev` copy. `buildmata()` takes `nwcommands`, `nwsaom`, `nwergm`, `nwdynam`, `nwrem` or `all` (the core and every installed package).
Three things to know: the build **clears the data and the Mata objects in memory** (it stops with error 4 if data is loaded, so save first); the libraries of nwsaom and
nwergm are compiled against the core library, so rebuilding the core rebuilds the installed nwsaom and nwergm libraries as well; and a build takes a few minutes.
Update the packages first (`nwinstall, all` and `nwinstall, models`), because the source of the current release is used. Restart Stata afterwards. The shipped
libraries are the better choice when they load; a build with your own Stata is the fallback and the repair.

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

Download the packages as zip files on a computer that has internet access, carry them over (USB drive, shared drive, email), and install from the unzipped folders. This needs no internet connection and no administrator rights on the target computer; the files go into your personal ado folder.

| Package | Zip file (current release) |
|---|---|
| nwcommands (core, always needed) | [nwcommands.zip](https://github.com/thomas-u-grund/nwcommands/archive/refs/heads/main.zip) |
| nwsaom | [nwsaom.zip](https://github.com/thomas-u-grund/nwsaom/archive/refs/heads/main.zip) |
| nwergm | [nwergm.zip](https://github.com/thomas-u-grund/nwergm/archive/refs/heads/main.zip) |
| nwdynam | [nwdynam.zip](https://github.com/thomas-u-grund/nwdynam/archive/refs/heads/main.zip) |
| nwrem | [nwrem.zip](https://github.com/thomas-u-grund/nwrem/archive/refs/heads/main.zip) |

A particular release has its own zip, for example `https://github.com/thomas-u-grund/nwsaom/archive/refs/tags/v1.5.8.zip`. Take the model packages you need; each needs the core. The core zip is about 10 MB.

1. Unzip the core zip. GitHub names the folder `nwcommands-main`.
2. Make a new folder for the model packages, unzip the model zips into it and rename each unzipped folder to the plain package name: `nwsaom-main` becomes `nwsaom`, `nwergm-main` becomes `nwergm`, and so on. The installer looks for these names.
3. In Stata, go to the core folder, copy the core into your personal ado folder, then install the models from their folder:

```stata
. cd "C:\path\to\nwcommands-main"
. nwinstall, localcopy all
. nwinstall, models modelsfrom("C:\path\to\models")
```

Use `nwinstall, modelpkg(nwsaom nwergm)` in place of `models` to install only some packages. Add `nwinstall, gui` for the *Network Analysis* menu. The compiled plugins for Windows, macOS and Linux are in the zips, so nothing has to be built; if one does not work on your computer, see the section above, *If a plugin does not work on your computer*, and `nwinstall, buildplugin()` can compile it from the same source if a C compiler is installed. `help nwinstall` has the full list of options, including `dest()` for another target folder.
