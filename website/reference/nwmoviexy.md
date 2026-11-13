---
title: "nwmoviexy"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Animate a sequence of networks (alias for nwmovie)"
---

# `nwmoviexy`

Animate a sequence of networks (alias for nwmovie)

## Syntax

```stata
nwmoviexy
netlist
[,
nwmovie_options]
```

## Description

`nwmoviexy` is a thin alias for [nwmovie](nwmovie): it forwards its entire argument string to `nwmovie` unchanged and behaves identically to it in every way; it accepts exactly [nwmovie](nwmovie)'s option set, nothing more. Fixed node positions across waves are produced by `nwmovie`'s `fixedlayout` option (one shared layout computed once and reused every frame).

New code should call [nwmovie](nwmovie) directly - see its own help file for the complete option reference and worked examples.

## Network types

**Directed:** yes. **Valued:** the layouts use the tie values and the values set the line widths; `binary` switches that off (see [nwplot](nwplot)). **Two-mode:** yes - a symbol and a colour per mode. **Signed:** negative ties are dashed in a second colour (`nosign` is passed on). See [nwnetworktypes](nwnetworktypes).

## Examples

Animate two waves of a network (accepts exactly the same arguments as [nwmovie](nwmovie)):

```stata
. nwclear
. nwrandom 6, prob(.3) name(wave1)
. nwrandom 6, prob(.3) name(wave2)
. nwmoviexy wave1 wave2, duration(400)
```

## See also

- [nwmovie](nwmovie), [nwplot](nwplot)

---

*nwcommands version 3.24.0, 13 November 2026* ([check your installed version](nwversion))
