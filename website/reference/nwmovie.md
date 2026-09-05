---
title: "nwmovie"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Interactive, animated network movie (panel waves or a relational-event timeline)"
---

# `nwmovie`

Interactive, animated network movie (panel waves or a relational-event timeline)

## Syntax

```stata
Panel mode - 2 or more already-built networks of the same size, in sequence:
nwmovie
netname netname [netname ...]
[, options]
Event mode - one network built via nwset's eventtime() option (the same event-type temporal network nwrem consumes):
nwmovie
netname
[, options]
Which mode applies is detected automatically from how many network names are given and whether the single name (if only one is given) is an event-type
temporal network - there is no separate option to choose between them.
```

| | |
|---|---|
| `fname(string)` | base filename for the output; writes *fname***.html** in the current directory; default **movie** |
| `noopen` | build the .html file but do not open it in a viewer |
| `layout`(*[layout](nwplot)*) | **panel mode**: layout algorithm - see [nwplot](nwplot)'s own `layout()`; any value other than the **kk** default disables the per-wave transitioning below and falls back to `fixedlayout`'s one-shared-layout behavior, since only **kk** has a "warm start" to relax from |
| `fixedlayout` | **panel mode**: compute one node layout, on the first network only, and reuse it unchanged for every wave, instead of the default per-wave transitioning layout (see Description below) |
| `iterations(int)` | iterations for the layout algorithm; default 500 |
| `color`(*`varname`*) | color nodes by this variable (broadcast to every network/the cumulative event-mode layout network) |
| `symbol`(*`varname`*) | shape nodes by this variable (broadcast to every network) |
| `size`(*`varname`*) | size nodes by this variable (broadcast to every network) |
| `edgecolor`(*[netname](netname)*) | color edges by this other network's own tie values, matching [nwplot](nwplot)'s identical `edgecolor()` (broadcast to every network; panel mode only) |
| `edgesize`(*[netname](netname)*) | width edges by this other network's own tie values (broadcast to every network; panel mode only) |
| `colors`(*`varlist`*) | **panel mode**: one variable PER WAVE (same order as the network list, one per network) instead of `color()`'s single broadcast variable - color genuinely tweens wave to wave, not just position |
| `symbols`(*`varlist`*) | **panel mode**: one variable per wave instead of `symbol()`'s single broadcast variable - shape switches instantly at each wave boundary (not tweened - see Description below) |
| `sizes`(*`varlist`*) | **panel mode**: one variable per wave instead of `size()`'s single broadcast variable - size genuinely tweens wave to wave |
| `edgecolors`(*[netname](netname)* *[netname](netname)* ...) | **panel mode**: one network per wave instead of `edgecolor()`'s single broadcast network - edge color tweens wave to wave for any edge that persists across the transition |
| `edgesizes`(*[netname](netname)* *[netname](netname)* ...) | **panel mode**: one network per wave instead of `edgesize()`'s single broadcast network - edge width tweens wave to wave for any edge that persists across the transition |
| `titles`("*title1*" "*title2*" ...) | **panel mode**: one double-quoted display title per wave, overriding the movie's own displayed wave title/counter (toolbar text and the on-canvas readout box - see Description below); default is each wave's own [`newtitle()`](nwname), if one was ever set, else its bare network name |
| `label`(*`varname`*) | node labels |
| `colorpalette`(*string*) | see [nwplot](nwplot) |
| `edgecolorpalette`(*string*) | see [nwplot](nwplot) |
| `symbolpalette`(*string*) | see [nwplot](nwplot) |
| `scheme`(*string*) | see [nwplot](nwplot) |
| `duration(int)` | **panel mode**: milliseconds per wave-to-wave transition; default 800 |
| `easing`(*string*) | **panel mode**: a Cytoscape.js easing name (e.g. **ease-in-out-cubic**, **linear**, **ease-in-out-bounce**); default **ease-in-out-cubic** |
| `window(real)` | **event mode**: a tie fades out *window* time units (same units as `eventtime()`'s own variable) after its most recent event, and is removed once fully faded; omitted means ties accumulate permanently (a "growth" movie) rather than decaying |
| `speed(real)` | **event mode**: simulated event-time units per real second during playback; default 1 |

## Description

**nwmovie** opens a live, interactive, animated view of a network changing over time, rendered with Cytoscape.js in a chromeless native viewer window (the same one [nwplot](nwplot)'s own `interactive` option uses - falls back to an ordinary browser tab when that native binary isn't available for the current platform). It replaces the previous ImageMagick/`graph export`-based pipeline entirely: there is no external ImageMagick dependency any more, and the result is a real, scrubbable, playable view - not just a fixed-frame-rate GIF - though a GIF can still be exported from within that view (the **Export GIF** button; written via a save dialog, or a browser download, depending on the viewer).

**Panel mode** takes 2 or more already-built networks in sequence, all with the same number of nodes in the same node order (the standard "waves of the same actors" convention this package's other panel-data commands already assume, e.g. [nwsaom](nwsaom)'s own `wave1()`/`wave2()`). By default, each wave gets its own **kk** (Kamada-Kawai) layout, warm-started from the PREVIOUS wave's own final node positions, so consecutive waves relax into nearby layouts - a real, visible transition as ties change - rather than each wave's layout being computed completely independently. Node identity stays visually trackable across the movie (nodes move smoothly, not in unrelated jumps), while still letting the layout itself resettle as the network's structure changes wave to wave. Specify `fixedlayout` to restore the original behavior instead: one node layout, computed once on the first network only and reused unchanged for every wave - the layout itself never moves, at the cost of never reflecting how the network's own structure is changing. An explicit `layout()` other than **kk** also falls back to this one-shared-layout behavior (see `layout()` above), since the per-wave transition relies on **kk**'s own warm-start.

**Event mode** takes exactly one network declared via [nwset](nwset)'s `eventtime()` option - a stream of timestamped (sender, receiver, time) events, not persistent ties (see [nwset](nwset)'s own account of the distinction, and [nwrem](nwrem), which consumes the identical input). Node positions are static (one layout, computed once over the union of every sender/receiver pair that ever occurs); the movie is a scrubbable timeline over real event time, replaying ties as they occur. With `window()`, a tie fades and disappears if no new event on that same pair occurs within the window; without it, ties accumulate and never disappear (useful for showing how a network was built up over time).

Both modes reuse [nwplot](nwplot)'s own color/shape/position resolution - `color()`/`symbol()`/`size()`/`edgecolor()`/`edgesize()`/ `label()` here work exactly like their [nwplot](nwplot) counterparts, applied identically across every panel network (or once, to the event-mode cumulative layout network).

**Panel mode** can also vary node/edge styling BY wave, the way the old ImageMagick-era `colors()`/`sizes()`/etc. plural options did: `colors()`/`symbols()`/`sizes()`/`edgecolors()`/`edgesizes()` each take one value PER WAVE (in the same order as the network list) instead of their singular counterparts' single broadcast value. Color and size (node AND edge) genuinely transition continuously as the movie plays - Cytoscape.js tweens node color/size natively as part of the same `duration()`/`easing()` animation that already moves node position, and edges (which are always fully rebuilt every transition, not kept alive across it - see the crash history noted in **nwmovie_template.html**'s own source) get an equivalent hand-rolled tween for any edge that persists across the transition. Shape stays a hard switch at each wave boundary, not a continuous morph - asking Cytoscape's own animation to interpolate shape (circle into square, say) is not a meaningful blend, and turned out to be a genuine renderer-crash trigger during this feature's own development besides. A brand-new tie that did not exist in the previous wave pops in at its final style directly, with no fade-in - only persisting ties (present in both waves) tween their own width/color change.

The toolbar's speed slider (0.1x-5x) scales playback speed for both modes - a single wave-to-wave `duration()` or the whole event-time range `speed()` would otherwise take, divided by the live slider value, re-read on every transition/frame so changing it mid-playback takes effect immediately - and also scales **Export GIF**'s own frame timing to match. The Loop checkbox restarts playback from the beginning once it reaches the end instead of stopping there (panel mode: back to wave 1; event mode: back to *eventtime()*'s own minimum), for both live playback and **Export GIF**.

The current wave's title/counter (or, in event mode, the active-tie count/time readout) is ALSO shown as its own small box drawn directly on the canvas, not just in the toolbar - draggable by its own handle and resizable via its own bottom-right resize handle, the same way [nwplot](nwplot)'s own `interactive` view lets you reposition/resize its legend. Unlike the toolbar text, this on-canvas box gets baked into **Export GIF**'s own output, at its own current on-screen position and size, so an exported movie still shows what wave/time each frame is at once it's outside the interactive viewer. Its own "**x**" button removes it for the rest of that viewing session (and stops it being baked into any GIF exported after that); there is no way to bring it back short of reopening the movie. Its own font size only ever changes from manually resizing its box - it never changes on its own between waves, regardless of how long each wave's own title text happens to be.

Dropped entirely, with no replacement (the ImageMagick pipeline's own options, no longer meaningful once the browser does the rendering and animation): `frames()`, `delay()`, `explosion()`, `imagick()`, `keepfiles()`, `width()`, `height()`, `z()`, `nodexys()`, `switchnetwork()`/`switchcolor()`/`switchsymbol()`/`switchedgecolor()`/`switchtitle()`, and `eps` (vector export - [nwplot](nwplot)'s own `interactive` view made the identical PNG-only tradeoff already, for the same reason: Cytoscape.js's built-in export is raster-only).

## Examples

**Panel mode**, using the three-wave [Glasgow](netexample) friendship data (*glasgow1*/*glasgow2*/*glasgow3*, one wave per school year) already used elsewhere in this package:

```stata
. nwwebuse glasgow, nwclear
. nwmovie glasgow1 glasgow2 glasgow3, duration(600) color(sport1)
```
Same data, but coloring each wave by ITS OWN *sport* value (one variable per wave, via `colors()` instead of `color()`) - node color genuinely tweens as a pupil's own reported sporting activity changes wave to wave:

```stata
. nwwebuse glasgow, nwclear
. nwmovie glasgow1 glasgow2 glasgow3, duration(600) colors(sport1 sport2 sport3)
```
Same data again, with a custom display title per wave (default, without `titles()`, would just be each bare network name - *glasgow1*, *glasgow2*, *glasgow3*):

```stata
. nwwebuse glasgow, nwclear
. nwmovie glasgow1 glasgow2 glasgow3, duration(600) titles("Year 1 (1995)" "Year 2 (1996)" "Year 3 (1997)")
```
**Event mode**, on the same small inline event log [nwrem](nwrem)'s own example uses:

```stata
. clear
. input sender receiver t
. 1 2 1
. 1 3 2
. 2 1 3
. 1 2 4
. 3 2 5
. 2 3 6
. 1 3 7
. 3 1 8
. 2 1 9
. 1 3 10
. end
. nwset sender receiver, eventtime(t) name(chatlog)
. nwmovie chatlog, window(5) speed(2)
```

## Supported network types

Panel mode: binary yes, directed yes, weighted see [nwplot](nwplot), signed not checked, two-mode not checked (animates whichever networks are given exactly as [nwplot](nwplot) would render each one). Event mode: exactly the input [nwrem](nwrem) already accepts - a one-mode, event-type temporal network built via [nwset](nwset)'s `eventtime()` option; two-mode is not currently combinable with `eventtime()` at the [nwset](nwset) level (a separate, already-tracked composability gap).

## See also

- [nwplot](nwplot)
- [nwrem](nwrem)
- [nwset](nwset)
