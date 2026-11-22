---
title: "Literature"
nav_order: 13
description: "Publications about nwcommands, the methods papers behind nwsaom, nwergm, nwdynam, nwrem, nwalaam, nwlsm and nwsbm, and the new commands of the core, and how to add your application."
permalink: /literature/
---

# Literature
{: .no_toc }

A short list, kept small on purpose. It names what to cite for the software and the methods papers each package follows. For the wider literature on each model, the Siena project keeps much longer lists: [articles](https://www.stats.ox.ac.uk/~snijders/siena/siena_articles.htm) and [applications](https://www.stats.ox.ac.uk/~snijders/siena/siena_applications.htm).

## About nwcommands and the models

- Grund, T. U. (2027). *Network Analysis with Stata: Concepts, Methods, and Applications.* Stata Press, College Station, TX. Forthcoming.

## Technical manuals

These manuals document the model packages: syntax, options, stored results and worked examples. They are technical reference documentation, deposited at Zenodo so that each version can be cited and found; they are not peer-reviewed publications. Each DOI leads to the latest manual. The author is T. U. Grund and the year is 2026 for all of them.

| Package | Manual | DOI |
|---|---|---|
| nwsaom | Stochastic actor-oriented models in Stata | [10.5281/zenodo.23623807](https://doi.org/10.5281/zenodo.23623807) |
| nwergm | Exponential random graph models in Stata | [10.5281/zenodo.23661331](https://doi.org/10.5281/zenodo.23661331) |
| nwalaam | Autologistic actor attribute models in Stata | [10.5281/zenodo.24397901](https://doi.org/10.5281/zenodo.24397901) |
| nwdynam | Dynamic network actor models in Stata | [10.5281/zenodo.24398099](https://doi.org/10.5281/zenodo.24398099) |
| nwrem | Relational event models in Stata | [10.5281/zenodo.24398012](https://doi.org/10.5281/zenodo.24398012) |
| nwlsm | Latent space models for networks in Stata | [10.5281/zenodo.24398243](https://doi.org/10.5281/zenodo.24398243) |
| nwsbm | Stochastic block models for networks in Stata | [10.5281/zenodo.24398296](https://doi.org/10.5281/zenodo.24398296) |

How to cite each package is on the [citing page](../citing/).

## Papers about the software

Current versions, as PDF files. All four are under review; the text may change before publication.

- Grund, T. U. *nwcommands: Scalable and extensible network analysis in Stata.* Under review. [PDF](../papers/grund_nwcommands_paper.pdf)
- Grund, T. U. *nwplot: Flexible, publication-quality network visualization in Stata.* Under review. [PDF](../papers/grund_nwplot_paper.pdf)
- Grund, T. U. *nwergm: Exponential-family random graph models in Stata.* Under review. [PDF](../papers/grund_nwergm_paper.pdf)
- Grund, T. U. *nwsaom: Stochastic actor-oriented models in Stata.* Under review. [PDF](../papers/grund_nwsaom_paper.pdf)

## Methods papers behind the packages

### nwsaom (stochastic actor-oriented models)

- Snijders, T. A. B. (2001). The statistical evaluation of social network dynamics. *Sociological Methodology* 31(1), 361-395.
- Steglich, C., Snijders, T. A. B. and Pearson, M. (2010). Dynamic networks and behavior: separating selection from influence. *Sociological Methodology* 40(1), 329-393.
- Koskinen, J. H. and Snijders, T. A. B. (2007). Bayesian inference for dynamic social network data. *Journal of Statistical Planning and Inference* 137(12), 3930-3938.
- Ripley, R. M., Snijders, T. A. B., Boda, Z., Voros, A. and Preciado, P. *Manual for RSiena.* University of Oxford. The reference implementation that nwsaom is compared with.

### nwergm (exponential random graph models)

- Hunter, D. R., Handcock, M. S., Butts, C. T., Goodreau, S. M. and Morris, M. (2008). ergm: a package to fit, simulate and diagnose exponential-family models for networks. *Journal of Statistical Software* 24(3), 1-29. [doi:10.18637/jss.v024.i03](https://doi.org/10.18637/jss.v024.i03)
- Handcock, M. S., Hunter, D. R., Butts, C. T., Goodreau, S. M. and Morris, M. (2008). statnet: software tools for the representation, visualization, analysis and simulation of network data. *Journal of Statistical Software* 24(1), 1-11.
- Krivitsky, P. N. and Handcock, M. S. (2014). A separable model for dynamic networks. *Journal of the Royal Statistical Society: Series B* 76(1), 29-46.
- Caimo, A. and Friel, N. (2011). Bayesian inference for exponential random graph models. *Social Networks* 33(1), 41-55. [doi:10.1016/j.socnet.2010.09.004](https://doi.org/10.1016/j.socnet.2010.09.004) (Bayesian estimation)
- Caimo, A. and Friel, N. (2014). Bergm: Bayesian exponential random graphs in R. *Journal of Statistical Software* 61(2), 1-25. [doi:10.18637/jss.v061.i02](https://doi.org/10.18637/jss.v061.i02)
- Krivitsky, P. N. and Morris, M. (2017). Inference for social network models from egocentrically sampled data, with application to understanding persistent racial disparities in HIV prevalence in the US. *The Annals of Applied Statistics* 11(1), 427-455. [doi:10.1214/16-AOAS1010](https://doi.org/10.1214/16-AOAS1010) (`nwergm ego`)

### nwdynam (dynamic network actor models)

- Stadtfeld, C., Hollway, J. and Block, P. (2017). Dynamic network actor models: investigating coordination ties through time. *Sociological Methodology* 47(1), 1-40. [doi:10.1177/0081175017709295](https://doi.org/10.1177/0081175017709295)
- Stadtfeld, C. and Block, P. (2017). Interactions, actors, and time: dynamic network actor models for relational events. *Sociological Science* 4, 318-352. [doi:10.15195/v4.a14](https://doi.org/10.15195/v4.a14)

### nwrem (relational event models)

- Butts, C. T. (2008). A relational event framework for social action. *Sociological Methodology* 38(1), 155-200.

### nwalaam (autologistic actor attribute models)

- Robins, G., Pattison, P. and Elliott, P. (2001). Network models for social influence processes. *Psychometrika* 66(2), 161-189.
- Daraganova, G. and Robins, G. (2013). Autologistic actor attribute models. In Lusher, D., Koskinen, J. and Robins, G. (eds), *Exponential Random Graph Models for Social Networks*, 102-114. Cambridge University Press.
- Borisenko, A., Byshkin, M. and Lomi, A. (2019). A simple algorithm for scalable Monte Carlo inference. *arXiv:1901.00533*.
- Stivala, A., Wang, P. and Lomi, A. (2024). ALAAMEE: Open-source software for fitting autologistic actor attribute models. *PLOS Complex Systems* 1(4), e0000021.

### nwlsm (latent space models)

- Hoff, P. D., Raftery, A. E. and Handcock, M. S. (2002). Latent space approaches to social network analysis. *Journal of the American Statistical Association* 97(460), 1090-1098. [doi:10.1198/016214502388618906](https://doi.org/10.1198/016214502388618906)
- Handcock, M. S., Raftery, A. E. and Tantrum, J. M. (2007). Model-based clustering for social networks. *Journal of the Royal Statistical Society: Series A* 170(2), 301-354. [doi:10.1111/j.1467-985X.2007.00471.x](https://doi.org/10.1111/j.1467-985X.2007.00471.x)
- Krivitsky, P. N. and Handcock, M. S. (2008). Fitting position latent cluster models for social networks with latentnet. *Journal of Statistical Software* 24(5). [doi:10.18637/jss.v024.i05](https://doi.org/10.18637/jss.v024.i05)
- Sweet, T. M. and Adhikari, S. (2020). A latent space network model for social influence. *Psychometrika* 85(2), 251-274. [doi:10.1007/s11336-020-09700-x](https://doi.org/10.1007/s11336-020-09700-x)

### nwsbm (stochastic block models)

- Nowicki, K. and Snijders, T. A. B. (2001). Estimation and prediction for stochastic blockstructures. *Journal of the American Statistical Association* 96(455), 1077-1087. [doi:10.1198/016214501753208735](https://doi.org/10.1198/016214501753208735)
- Daudin, J.-J., Picard, F. and Robin, S. (2008). A mixture model for random graphs. *Statistics and Computing* 18(2), 173-183. [doi:10.1007/s11222-007-9046-7](https://doi.org/10.1007/s11222-007-9046-7)
- Karrer, B. and Newman, M. E. J. (2011). Stochastic blockmodels and community structure in networks. *Physical Review E* 83(1), 016107. [doi:10.1103/PhysRevE.83.016107](https://doi.org/10.1103/PhysRevE.83.016107)
- Côme, E., Jouvin, N., Latouche, P. and Bouveyron, C. (2021). Hierarchical clustering with discrete latent variable models and the integrated classification likelihood. *Advances in Data Analysis and Classification* 15, 957-986. [doi:10.1007/s11634-021-00440-z](https://doi.org/10.1007/s11634-021-00440-z)
- Leger, J.-B. (2016). Blockmodels: a R-package for estimating in latent block model and stochastic block model, with various probability functions, with or without covariates. *arXiv:1602.07587*. [doi:10.48550/arXiv.1602.07587](https://doi.org/10.48550/arXiv.1602.07587)

### New commands of the core

- Neal, Z. P. (2014). The backbone of bipartite projections: inferring relationships from co-authorship, co-sponsorship, co-attendance and other co-behaviors. *Social Networks* 39, 84-97. [doi:10.1016/j.socnet.2014.06.001](https://doi.org/10.1016/j.socnet.2014.06.001) (`nwbackbone`; the R package is `backbone`, Neal 2026, *PLOS ONE* 21(5), e0349258, [doi:10.1371/journal.pone.0349258](https://doi.org/10.1371/journal.pone.0349258))
- Traag, V. A., Waltman, L. and van Eck, N. J. (2019). From Louvain to Leiden: guaranteeing well-connected communities. *Scientific Reports* 9, 5233. [doi:10.1038/s41598-019-41695-z](https://doi.org/10.1038/s41598-019-41695-z) (`nwcommunity, algorithm(leiden)`)
- Rosvall, M. and Bergstrom, C. T. (2008). Maps of random walks on complex networks reveal community structure. *Proceedings of the National Academy of Sciences* 105(4), 1118-1123. [doi:10.1073/pnas.0706851105](https://doi.org/10.1073/pnas.0706851105) (`nwcommunity, algorithm(infomap)`)
- Valente, T. W. and Vega Yon, G. G. (2020). Diffusion/contagion processes on social networks. *Health Education & Behavior* 47(2), 235-248. [doi:10.1177/1090198120901497](https://doi.org/10.1177/1090198120901497), and the R package `netdiffuseR` (Vega Yon, Olivera Morales and Valente), version 1.25.1 (`nwdiffuse`)

## Using nwcommands in your work

We would like to list work that used nwcommands, nwsaom, nwergm, nwdynam, nwrem, nwalaam, nwlsm or nwsbm. To add yours, open a post in **Show and tell** under Discussions of the package you used, or open an issue if you prefer:

- [nwcommands](https://github.com/thomas-u-grund/nwcommands/discussions), [nwsaom](https://github.com/thomas-u-grund/nwsaom/discussions), [nwergm](https://github.com/thomas-u-grund/nwergm/discussions), [nwdynam](https://github.com/thomas-u-grund/nwdynam/discussions), [nwrem](https://github.com/thomas-u-grund/nwrem/discussions) [nwalaam](https://github.com/thomas-u-grund/nwalaam/issues), [nwlsm](https://github.com/thomas-u-grund/nwlsm/issues) and [nwsbm](https://github.com/thomas-u-grund/nwsbm/issues) (issues).

Please give the full reference, a link (DOI or preprint), the package and version, and one sentence on what you modeled. The list will be added to as submissions arrive; there are no entries yet.
