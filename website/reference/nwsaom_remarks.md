---
title: "nwsaom_remarks"
parent: "Command reference"
nav_exclude: true
search_exclude: false
---

# `nwsaom_remarks`

## Description

This file holds the full effect-derivation library, interaction/multiplex/co-evolution mechanics, composition-change/missing-data/structural-zero handling, the full performance benchmark, and the estimation-algorithm background for [nwsaom](nwsaom) - split out into its own file purely to keep [nwsaom](nwsaom)'s own help file within Stata's interactive Viewer's rendering limits (its combined length triggered a real Viewer-side rendering bug on very long SMCL documents once it grew past roughly 1,000 lines). See [nwsaom](nwsaom) itself for the command's syntax, options, and examples.

**A genuine, hard-won methodological lesson from this implementation's own development, worth stating explicitly here**: several of RSiena's own effects (e.g. `gwesp()`) compute their observed/global statistic in a way that is IDENTICAL to the corresponding ERGM statistic, which made it tempting to also reuse an ERGM package's own change-statistic (ministep) formula for the same effect - this is WRONG in general. RSiena's own ministep formula for a given effect is restricted to the ACTIVATED ACTOR'S OWN statistic only (the myopic-actor rule above), which for several effects is a genuinely SMALLER quantity than the effect's own full ERGM change statistic (which legitimately captures the toggle's effect on every actor's own statistic, appropriate for an ERGM's single-actor-free global model but not for an SAOM ministep). Every effect below was independently re-derived and verified against RSiena's own real ministep-contribution source code, not assumed from its global-statistic formula alone; see [Effect library](nwsaom_remarks) below for the account, term by term, including one case (`gwesp()`) where an initial reuse assumption was shipped, caught, and corrected during this package's own development - kept in that section's own account rather than silently erased, matching this whole package's disclosure standard.

## See also

- [nwsaom](nwsaom), [nwsaom_estat](nwsaom_estat), [nwergm](nwergm)
