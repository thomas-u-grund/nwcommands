---
title: "Intro to Longitudinal Network Models"
parent: Tutorials
nav_order: 10
description: "The longitudinal network models have moved to their own packages."
---

# Intro to Longitudinal Network Models

The models for network change are no longer part of the core `nwcommands`. Each is its own
GPL-3 package that requires the core:

```stata
net install nwsaom,  from(https://raw.githubusercontent.com/<account>/nwsaom/main/)   // stochastic actor-oriented models
net install nwrem,   from(https://raw.githubusercontent.com/<account>/nwrem/main/)    // relational event models
net install nwdynam, from(https://raw.githubusercontent.com/<account>/nwdynam/main/)  // dynamic network actor models
```
