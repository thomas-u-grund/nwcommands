---
title: "nwmoviexy"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Animate a sequence of networks (alias for **nwmovie**)"
---

# `nwmoviexy`

Animate a sequence of networks (alias for **nwmovie**)

## Syntax

```stata
nwmoviexy
netlist
[,
nwmovie_options]
```

## Description

`nwmoviexy` is a thin alias for [nwmovie](nwmovie.md): it forwards its entire argument string to `nwmovie` unchanged and behaves identically to it in every way. Historically `nwmoviexy` was a separate, coordinate-specific implementation (accepting an explicit `nodexys(varlist)` option to place nodes at fixed x/y coordinates supplied by the caller). [nwmovie](nwmovie.md) itself was rebuilt on a Cytoscape.js-based rendering pipeline (see that command's own help file) and no longer has an equivalent option - fixed node positions across waves are now produced automatically via its own `fixedlayout` option (one shared layout computed once and reused every frame) instead of requiring the caller to supply coordinates. `nwmoviexy` is kept only as a thin, backward-compatible alias so existing scripts that call it by name continue to work; it accepts exactly [nwmovie](nwmovie.md)'s own current option set, nothing more.

New code should call [nwmovie](nwmovie.md) directly - see its own help file for the complete option reference and worked examples.

## Examples

Animate two waves of a network (accepts exactly the same arguments as [nwmovie](nwmovie.md)):

```stata
. nwclear
. nwrandom 6, prob(.3) name(wave1)
. nwrandom 6, prob(.3) name(wave2)
. nwmoviexy wave1 wave2, duration(400)
```

## Supported network types

Binary: yes. Directed: yes. Weighted: yes. Signed: not checked. Two-mode: not checked - a direct alias for [nwmovie](nwmovie.md); see that command's own identical classification.

## See also

- [nwmovie](nwmovie.md), [nwplot](nwplot.md)
