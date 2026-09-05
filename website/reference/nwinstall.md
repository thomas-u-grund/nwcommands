---
title: "nwinstall"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Install Stata menu/dialogs"
---

# `nwinstall`

Install Stata menu/dialogs

## Syntax

```stata
nwinstall
[,
permanently
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
localcopy
from(string)
dest(string)]
```

| | |
|---|---|
| `permanently` | install the menu/dialogs permanently on your Stata |
| `remove` | remove the "Network Analysis" menu from your Stata |
| `help` | download the help files |
| `ado` | download the core command (.ado) files |
| `ext` | accepted for backward compatibility, does nothing (the "extension" commands it used to download separately - [nwdissimilar](nwdissimilar.md), [nwhierarchy](nwhierarchy.md), [nwdendrogram](nwdendrogram.md) - are ordinary commands shipped with every other `ado`/`help` install, and were never genuinely distinct from the rest of the package) |
| `dialog` | download the dialog boxes |
| `usermenu` | update menu items for dialog-boxes |
| `update` | refresh the installed menu (an internal, self-recursive flag: re-invokes `nwinstall, help usermenu`) |
| `downloadoff` | rebuild the menu from what is already installed, without downloading anything (used internally by **profile.do** integration; equivalent to `usermenu` for this purpose) |
| `menu(string)` | install in this menu; default = "stUser" |
| `all` | download the core commands, help files, and dialog boxes, and install them permanently |
| `path(string)` | directory where profile.do is installed; default: sysdir_stata |
| `localcopy` | install by copying files from an existing local nwcommands folder instead of downloading from GitHub - see [Computers without internet access or admin rights](nwinstall.md) below |
| `from(string)` | with `localcopy`: the local folder to copy nwcommands files from; default: the current directory |
| `dest(string)` | with `localcopy`: the local ado directory to copy files into; default: your PERSONAL ado directory (already on Stata's ado path, so nothing further needs to be configured for the default case) |

## Description

This command loads Stata dialog boxes for the nwcommands and installs a menu "Network Analysis" inside the "User" menu. Almost all nwcommands (and their functions) can be executed via dialog boxes. Notice, however, that some more advanced functions are only available through Stata syntax (see [nwcommands](nwcommands.md)).

## Supported network types

Not applicable - installs/manages this package's own Stata menu, dialogs, and update mechanism; does not read or depend on any network's own content, directed/valued/two-mode status, or tie values.
