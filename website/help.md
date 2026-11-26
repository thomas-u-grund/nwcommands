---
title: "Help and about"
nav_order: 9
description: "Where to ask questions, report problems and follow announcements for nwcommands, nwsaom, nwergm, nwdynam, nwrem, nwalaam, nwlsm and nwsbm."
permalink: /help/
has_children: true
has_toc: false
---

# Get help and community
{: .no_toc }

Also here: [citing and licenses](/citing/), [literature](/literature/), [links](/links/) and [about](/about/).

Each package has its own place for questions and problems. Everything is public, so an answer to one person helps the next.

## Ask a question

Use **GitHub Discussions** of the package your question is about. You need a free GitHub account.

| Package | Questions | Problems and feature requests |
|---|---|---|
| nwcommands (core) | [Discussions](https://github.com/thomas-u-grund/nwcommands/discussions) | [Issues](https://github.com/thomas-u-grund/nwcommands/issues) |
| nwsaom | [Discussions](https://github.com/thomas-u-grund/nwsaom/discussions) | [Issues](https://github.com/thomas-u-grund/nwsaom/issues) |
| nwergm | [Discussions](https://github.com/thomas-u-grund/nwergm/discussions) | [Issues](https://github.com/thomas-u-grund/nwergm/issues) |
| nwdynam | [Discussions](https://github.com/thomas-u-grund/nwdynam/discussions) | [Issues](https://github.com/thomas-u-grund/nwdynam/issues) |
| nwrem | [Discussions](https://github.com/thomas-u-grund/nwrem/discussions) | [Issues](https://github.com/thomas-u-grund/nwrem/issues) |
| nwalaam | [Discussions](https://github.com/thomas-u-grund/nwalaam/discussions) | [Issues](https://github.com/thomas-u-grund/nwalaam/issues) |
| nwlsm | [Issues](https://github.com/thomas-u-grund/nwlsm/issues) | [Issues](https://github.com/thomas-u-grund/nwlsm/issues) |
| nwsbm | [Issues](https://github.com/thomas-u-grund/nwsbm/issues) | [Issues](https://github.com/thomas-u-grund/nwsbm/issues) |

Use a *question* (Discussions) for "how do I...?" and "how should I read this output?". Use an *issue* when something gives an error or a wrong result, or when you want a feature. If you are not sure which package you need, see [Which package do I need?](../which-package/).

## Announcements

New releases and workshops are announced on the **nwcommands mailing list** (a Google Group): [groups.google.com/g/nwcommands](https://groups.google.com/g/nwcommands), address nwcommands@googlegroups.com. The list is for announcements; please ask questions in GitHub Discussions, where the answers stay findable.

## Before you ask

1. Look in the [tutorials](../nwcommands/install/) and the help file (`help <command>` in Stata).
2. If you are coming from R, see the pages that compare the packages with RSiena ([nwsaom](../nwsaom/rsiena/)), ergm ([nwergm](../nwergm/rergm/)), goldfish ([nwdynam](../nwdynam/r-goldfish/)) and relevent ([nwrem](../nwrem/r-relevent/)).
3. Update to the latest release (see [Install](../nwcommands/install/)); the problem may be fixed.

## How to ask so that we can help

Please include:

- the output of `nwversion` and of `<package> version` (for example `nwsaom version`), and your Stata version and operating system;
- the commands that produce the problem, as short as possible, and the output including any error message;
- if your data are confidential, a small made-up or simulated network that shows the same problem.

## Contributing

Pull requests are welcome in each repository on GitHub. For changes to the models, please include a comparison with the R package that the model follows, since that comparison is how the packages are validated.
