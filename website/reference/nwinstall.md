---
title: "nwinstall"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Install the dialogs, menus and the model packages"
---

# `nwinstall`

Install the dialogs, menus and the model packages

## Syntax

```stata
nwinstall
[,
gui
remove 
help
ado
ext
dialog
usermenu
update
downloadoff
menu(string)
all
path(string)
local:copy
from(string)
dest(string)
model:s
every:thing
nogui
dup:check
modelp:kg(namelist)
rel:ease(string)
modelsf:rom(string)
buildp:lugin(namelist)
buildm:ata(namelist)
buildf:rom(string)
buildk:eep]
```

| | |
|---|---|
| `gui` | install the "Network Analysis" menu permanently on your Stata (`permanently` is a synonym); it is set up once, however often you type it - see [The menu is installed once](nwinstall) |
| `remove` | remove the "Network Analysis" menu from your Stata, the line `nwinstall, usermenu` from **profile.do**, and the nwcommands files |
| `help` | download the help files |
| `ado` | download the core command (.ado) files |
| `ext` | accepted, does nothing ([nwdissimilar](nwdissimilar), [nwhierarchy](nwhierarchy) and [nwdendrogram](nwdendrogram) are ordinary commands installed with every other `ado`/`help` install) |
| `dialog` | download the dialog boxes |
| `usermenu` | update menu items for dialog-boxes |
| `update` | refresh the installed menu (an internal, self-recursive flag: re-invokes `nwinstall, help usermenu`) |
| `downloadoff` | rebuild the menu from what is already installed, without downloading anything (used internally by **profile.do** integration; equivalent to `usermenu` for this purpose) |
| `menu(string)` | install in this menu; default = "stUser" |
| `all` | download the core commands, help files, and dialog boxes, and set up the menu (as `gui`); with `nogui` the menu is left out |
| `path(string)` | directory of the **profile.do** to edit; default: the folder where an existing **profile.do** is found (your home folder, PERSONAL or SITE), otherwise the folder Stata recommends: %USERPROFILE% on Windows, ~/Documents/Stata on macOS, PERSONAL on Unix |
| `local:copy` | install by copying files from an existing local nwcommands folder instead of downloading from GitHub - see [Computers without internet access or admin rights](nwinstall) below |
| `from(string)` | with `localcopy`: the local folder to copy nwcommands files from; default: the current directory |
| `dest(string)` | with `localcopy`: the local ado directory to copy files into; default: your PERSONAL ado directory (already on Stata's ado path, so nothing further needs to be configured for the default case) |
| `model:s` | also install the four model packages `nwsaom`, `nwergm`, `nwdynam` and `nwrem` (see below); with `remove` they are uninstalled |
| `every:thing` | install the core (everything `all` installs) and the four model packages (what `models` installs) as one set, set up the menu (as `gui`), and show all five versions at the end |
| `nogui` | with `all` or `everything`: do not set up the menu and do not touch **profile.do** |
| `dup:check` | report dialog files (.dlg) that exist in more than one folder of the ado path; changes nothing |
| `modelp:kg(namelist)` | install only these model packages (any of nwsaom, nwergm, nwdynam, nwrem); can be used alone |
| `buildp:lugin(namelist)` | compile the native plugins of these packages on this computer (any of nwcommands, nwsaom, nwergm, nwdynam; `all` for all four) and install them; macOS and Linux; used alone |
| `buildm:ata(namelist)` | rebuild the Mata libraries of these packages with the Stata that is running (any of nwcommands, nwsaom, nwergm, nwdynam, nwrem; `all` for the core and every installed package); the repair if the shipped library was built by a newer Stata; used alone |
| `buildf:rom(string)` | with `buildplugin()` or `buildmata()`: a folder or URL with one subfolder per package that holds the source (`native/` for the plugins, the `unw_*.do` files for the Mata libraries); default: the GitHub repositories |
| `buildk:eep` | with `buildplugin()` or `buildmata()`: keep the build folder (it holds the build log) |
| `rel:ease(string)` | with `models` or `modelpkg()`: the release to install, for example `v1.0.0`; default: the current release |
| `modelsf:rom(string)` | with `models`: a folder or URL with one subfolder per package, instead of the GitHub repositories (for local clones and offline installs) |

## Description

This command loads Stata dialog boxes for the nwcommands and installs a menu "Network Analysis" inside the "User" menu. Almost all nwcommands (and their functions) can be executed via dialog boxes. Notice, however, that some more advanced functions are only available through Stata syntax (see [nwcommands](nwcommands)).

## The model packages

The commands `nwsaom` (stochastic actor-oriented models), `nwergm` (exponential random graph models), `nwdynam` (dynamic network actor models) and `nwrem` (relational event models) are packages of their own, installed separately from `nwcommands` and distributed under the GNU General Public License, version 3. They need `nwcommands` (install it first, then run `nwinstall, all`). `nwinstall, models` installs all four from their GitHub repositories; `nwinstall, modelpkg(nwsaom nwergm)` installs only some, and `nwinstall, models release(v1.0.0)` installs a particular release. `nwinstall, all` installs the core only (and sets up the menu, unless `nogui`) and ends with a hint about the model packages. `nwinstall, models` and `nwinstall, modelpkg()` install packages only; they do not touch the menu or **profile.do**. `nwinstall, everything` installs the core and the four model packages in one step, sets up the *Network Analysis* menu with the dialog boxes (the same as adding `gui`; add `nogui` to skip that), and prints the version of each package at the end (as [nwversion](nwversion) does). Before anything is installed, `everything` checks that every model repository can be reached and that no model needs a newer core than the one being installed; if not, it stops with a message that names the package and installs nothing. `nwinstall, all models` installs the same packages as `nwinstall, everything`, without the check before the install and the list of versions at the end. With `everything` (and with `models`), `from()` is the source of the core package, `modelsfrom()` the folder with one subfolder per model package, and `release()` the release of the model packages; for an offline install point both at local folders. Each package has a `version` subcommand, for example `nwsaom version`. Updating `nwcommands` never replaces an installed model package.

## The menu is installed once

`gui` (and therefore `all` and `everything`, unless you add `nogui`) puts the single line `nwinstall, usermenu` into your **profile.do**, so that Stata builds the *Network Analysis* menu in the *User* menu each time it starts. The line is never written twice, however often you run `nwinstall`:

- o Other spellings of the line (`nwinstall, downloadoff`, extra spaces, a `quietly` in front) count as the same line; extra copies are dropped, and the rest of your **profile.do** is
- kept as it was.
- o If **profile.do** (or another **profile.do** Stata reads, in your PERSONAL, SITE or home folder or the current folder) already starts a *Network Analysis* menu in some other way, for
- example with a `window menu` line of your own, no second menu is added; `nwinstall` names the line and the file in a message. Lines it cannot identify with certainty are never deleted.
- o Within one session the menu is rebuilt from an empty *User* menu, so typing the command twice shows every entry once. Note that this clears all other menu entries you added to the
- *User* menu in that session.
- o The menu entries of the model packages `nwsaom` and `nwergm` appear only when the package's dialog boxes are installed. There is one entry for each package under
- *Statistical Models*, *Stochastic actor-oriented model (nwsaom)* and *Exponential random graph model (nwergm)*. The other dialogs of a package (Bayesian estimation, several networks,
- postestimation, simulation and so on) open from buttons inside its main dialog.
- o If the menu cannot be built (a Stata without menus, a batch run), you get a note and the installation goes on; nothing fails.
- o `nwinstall, remove` takes the menu, the `nwinstall, usermenu` line and the nwcommands files away again.

`dupcheck` lists dialog files that exist in more than one folder of the ado path (for example an old copy in your PERSONAL folder next to the installed one). Stata uses the first copy it finds; `nwinstall` tells you which one that is and deletes nothing. `nwinstall, all` runs this check at the end.

## Building the plugins on this computer

`nwinstall` installs compiled plugins for macOS, Linux and Windows. If the plugin of your platform is missing, older than the `.ado` files, or does not load on your computer (for example a Linux system with an older C library), you can compile it yourself:

- `. nwinstall, buildplugin(nwsaom)`
- `. nwinstall, buildplugin(all)`

The command copies the C source of the package from its GitHub repository (the same source that `net get` <package> copies), compiles it with the compiler of your computer and puts the plugin where `net install` puts it, in the folder of the PLUS directory; an existing plugin is kept as a file with the extension `.prev`. Restart Stata afterwards, because a plugin that is already loaded is not replaced in a running session. The plugin does not depend on the version or the flavour of Stata (BE, SE, MP; the plugin interface is the same), only on the operating system and the processor, so a plugin built on your computer works in every Stata of that computer.

You need a C compiler, installed once: on macOS the command line tools of Xcode (type `xcode-select --install` in the Terminal), on Linux `gcc` and `make` (for example the package `build-essential`), on Windows Microsoft's free [Build Tools for Visual Studio](https://visualstudio.microsoft.com/visual-cpp-build-tools/) with the workload **Desktop development with C++** (or Visual Studio with that workload). If the compiler is missing, the command says what to install and stops; nothing is changed. On Windows the compiler is found automatically; nothing has to be set up. `buildplugin()` with nothing in the parentheses builds all plugins. `buildfrom()` points to a local copy of the repositories instead of GitHub, and `release()` to a tagged release.

## Rebuilding the Mata libraries on this computer

The Mata libraries (`lnwcommands.mlib`, `lnwsaom1.mlib`, `lnwsaom2.mlib`, `lnwergm.mlib`, `lnwdynam.mlib`, `lnwrem.mlib`) are built with Stata 17. A library built by an *older* Stata loads in every later Stata, but a library built by a *newer* Stata is silently ignored by an older one (the message is "compiled by Stata 18, is too new to be run by this version of Stata and so was ignored"), and every Mata function is then "not found", r(3499). If that happens, or if the shipped libraries do not load for another reason, build them with your own Stata:

- `. nwinstall, buildmata(all)`
- `. nwinstall, buildmata(nwsaom)`

The command copies the Mata source of each package from its GitHub repository, compiles it with the Stata that is running, and puts the libraries where Stata finds the current ones (normally the folder of the PLUS directory); an existing library is kept as a file with the extension `.prev`. `buildmata(all)` builds the core and every installed model package. Restart Stata afterwards.

Three things to know. First, the build **clears the data and the Mata objects in memory**, including loaded networks; the command stops with error 4 if there is data in memory, so save your work first. Second, the libraries of nwsaom and nwergm are compiled against the core library and are only accepted by exactly that core library (error 3021 otherwise). Rebuilding the core therefore always rebuilds the installed nwsaom and nwergm libraries as well, in the right order, and `buildmata(nwsaom)` alone compiles against the core library that is installed. Third, a build takes a few minutes (the core source has more than 13,000 lines), needs the internet unless `buildfrom()` points to a local copy, and uses the source of the current release: update the packages first (`nwinstall, all`, `nwinstall, models`) and then rebuild. `buildfrom()` points to a local copy of the repositories, `release()` to a tagged release, and `dest()` puts the libraries into another folder. The shipped libraries are the better choice when they load: a build with your own Stata is the fallback and the repair.

## Network types

The command works the same for every network type (see [nwnetworktypes](nwnetworktypes)).

## Example

New to nwcommands? The full install is two commands:

```stata
. net install nwcommands, from(https://nwcommands.org/net/) replace
. nwinstall, everything
```
The first command installs just `nwinstall` itself and the landing help topics (see [nwcommands](nwcommands)); if `nwcommands.org` cannot be reached, `from("https://raw.githubusercontent.com/thomas-u-grund/nwcommands/main/")` works as well. The second downloads everything else - the core commands, all help files, and the dialog boxes with the *Network Analysis* menu (set up once, in **profile.do**) - and the four model packages `nwsaom`, `nwergm`, `nwdynam` and `nwrem`. To install the core only, type `nwinstall, all`; to leave the menu out, add `nogui`. nwcommands needs Stata 17 or later (tested on macOS with Stata 17, 18 and 19 and on Windows with Stata 19; StataBE is enough).

This installs a menu for the nwcommands:

```stata
. nwinstall, gui
```

## Stored results

`nwinstall` stores results only with `dupcheck`, `buildmata()` or `buildplugin()`:

- **Scalars**
- **r(ndup)** --- with `dupcheck`: number of dialog files found in more than one folder

- **Macros**
- **r(built)** --- with `buildmata()`: names of the Mata libraries that were built
- **r(plugin_***pkg***)** --- with `buildplugin()`: file name of the plugin installed for package *pkg*

## Computers without internet access or admin rights

The two-command install above needs `net install` to reach nwcommands.org and GitHub, and writes into a Stata-managed ado directory. Some machines - locked-down office computers, air-gapped servers, anywhere outbound internet access is blocked - cannot do either. For these, `localcopy` installs by copying files directly from an nwcommands folder you already have (e.g. handed to you as a zip file, on a USB drive, or over a shared network drive), with no download and no admin rights required.

Step by step:

1. Get the full nwcommands folder onto the computer somehow (email, USB drive, shared drive - anything that is not `net install`) and unzip it if needed. This folder must be the full source folder, not just a couple of files - it needs the `.ado`/`.sthlp`/ `.dlg` files and `lib/lnwcommands.mlib` together.

2. In Stata, `cd` to that folder (or note its full path) and run:

- `. cd "C:\path\to\nwcommands_2016"`
- `. nwinstall, localcopy all`

This copies every `.ado`/`.sthlp`/`.dlg`/`.idlg` file (and the compiled `lnwcommands.mlib`) into your **PERSONAL** ado directory - already on Stata's default ado path, the same one plain `sysdir` lists, and always somewhere in your own user profile, so it needs no admin rights on any platform. Nothing further needs to be set for this default case: `nwset`, `nwdegree`, and the rest are immediately available, and so are the dialog boxes (e.g. `db nwplot`).

3. To also get the "Network Analysis" menu:

- `. nwinstall, gui`

This is the same `gui` step used after a normal install (step 3 does not depend on `localcopy` at all - it only edits your local `profile.do`).

If even your PERSONAL ado directory is not writable (rare, but possible on some managed machines), point `dest()` at any folder you can write to instead, e.g. a folder on a network drive or an external disk:

```stata
. nwinstall, localcopy all dest("D:\my_ado")
```
In that case Stata will not find it automatically, so add it to your ado path every session:

```stata
. adopath ++ "D:\my_ado"
```
or make that permanent by adding the same line to your own `profile.do` (see `profiles`).

`localcopy` accepts the same `ado`/`help`/`dialog`/`all` selectors as the normal network install (`ext` is accepted but does nothing, same as without `localcopy` - see `ext` above), so e.g. `nwinstall, localcopy dialog` copies only the dialog boxes.

---

*nwcommands version 3.24.0, 13 November 2026* ([check your installed version](nwversion))
