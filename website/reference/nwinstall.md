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

## Stored results

`nwinstall` stores results only with `dupcheck`, `buildmata()` or `buildplugin()`:

- **Scalars**
- **r(ndup)** --- with `dupcheck`: number of dialog files found in more than one folder

- **Macros**
- **r(built)** --- with `buildmata()`: names of the Mata libraries that were built
- **r(plugin_***pkg***)** --- with `buildplugin()`: file name of the plugin installed for package *pkg*

---

*nwcommands version 3.22.0, 13 November 2026* ([check your installed version](nwversion))
