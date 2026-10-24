---
title: "nwinternals"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Help topic: the helper files that start with an underscore."
---

# `nwinternals`

The files whose names start with an underscore (for example `_nwsyntax`) are installed with the
package but are not meant to be called directly. They share code between the documented commands:
resolving network names, parsing network expressions, building dialog boxes and storing error codes.
In Stata: `help nwinternals`.

If you write your own commands against the package, see [`nwprogramming`](nwprogramming). Helper
pages: [`_nwnodeid`](_nwnodeid), [`_nwnodelab`](_nwnodelab), [`_nwtomata`](_nwtomata),
[`_nwdatasync`](_nwdatasync).
