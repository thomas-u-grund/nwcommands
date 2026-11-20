---
title: "Do-files of the book"
parent: "Book companion"
nav_order: 2
description: "One do-file per chapter of the book Network Analysis with Stata, with every command the book prints, in order."
permalink: /book/dofiles/
---

# Do-files of the book
{: .no_toc }

One do-file for each chapter of *Network Analysis with Stata* (forthcoming, Stata Press), with every command that
the chapter prints, in the order in which it prints them. Each do-file runs from top to bottom:

- the data sets are loaded from the internet with `nwwebuse`, so you need nothing else on your computer;
- the few commands that the book shows failing on purpose are run with `capture noisily`;
- a line that a chapter needs but does not print is marked as setup.

Install the software first, as described in *Getting started*:

```stata
net install nwcommands, from(https://nwcommands.org/net/)
nwinstall, everything
```

The do-files were checked against the versions the book was printed with: nwcommands 3.28.0, nwergm 1.10.0,
nwlsm 1.0.0, nwsbm 1.0.0, nwalaam 1.2.0, nwsaom 1.8.1, nwrem 1.5.1 and nwdynam 1.9.1. Results of the model chapters (21 to 28) depend on the
random-number seed and can differ slightly from the printed output with other versions.

**All files at once:** [nwbook_dofiles.zip](nwbook_dofiles.zip)

| Chapter | Do-file |
|---|---|
| Getting started | [`getting_started.do`](getting_started.do) |
| Chapter 2: What is a network? | [`ch02_what_is_a_network.do`](ch02_what_is_a_network.do) |
| Chapter 3: From a research question to a network and a method | [`ch03_research_question_to_network.do`](ch03_research_question_to_network.do) |
| Chapter 4: Working with networks in Stata | [`ch04_working_with_networks_in_stata.do`](ch04_working_with_networks_in_stata.do) |
| Chapter 5: Seeing networks | [`ch05_seeing_networks.do`](ch05_seeing_networks.do) |
| Chapter 6: Describing networks | [`ch06_describing_networks.do`](ch06_describing_networks.do) |
| Chapter 7: Paths, distance, and reachability | [`ch07_paths_distance_reachability.do`](ch07_paths_distance_reachability.do) |
| Chapter 8: Centrality, brokerage, and structural holes | [`ch08_centrality_brokerage_structural_holes.do`](ch08_centrality_brokerage_structural_holes.do) |
| Chapter 9: Cohesion, subgroups, and communities | [`ch09_cohesion_subgroups_communities.do`](ch09_cohesion_subgroups_communities.do) |
| Chapter 10: Positions, roles, and structural equivalence | [`ch10_positions_roles_structural_equivalence.do`](ch10_positions_roles_structural_equivalence.do) |
| Chapter 11: Ego networks | [`ch11_ego_networks.do`](ch11_ego_networks.do) |
| Chapter 12: Two-mode networks | [`ch12_two_mode_networks.do`](ch12_two_mode_networks.do) |
| Chapter 13: Valued, signed, and multiplex networks | [`ch13_valued_signed_multiplex_networks.do`](ch13_valued_signed_multiplex_networks.do) |
| Chapter 14: Networks over time | [`ch14_networks_over_time.do`](ch14_networks_over_time.do) |
| Chapter 15: Random and structured network generators | [`ch15_random_structured_generators.do`](ch15_random_structured_generators.do) |
| Chapter 16: Generating networks from attributes and tie probabilities | [`ch16_attribute_based_generators.do`](ch16_attribute_based_generators.do) |
| Chapter 17: Network structure and diffusion | [`ch17_network_structure_diffusion.do`](ch17_network_structure_diffusion.do) |
| Chapter 18: Random networks and null models | [`ch18_random_networks_null_models.do`](ch18_random_networks_null_models.do) |
| Chapter 19: Permutation inference and comparing networks | [`ch19_permutation_inference_comparing_networks.do`](ch19_permutation_inference_comparing_networks.do) |
| Chapter 20: QAP regression | [`ch20_qap_regression.do`](ch20_qap_regression.do) |
| Chapter 21: Exponential random graph models | [`ch21_exponential_random_graph_models.do`](ch21_exponential_random_graph_models.do) |
| Chapter 22: Advanced exponential random graph models | [`ch22_advanced_exponential_random_graph_models.do`](ch22_advanced_exponential_random_graph_models.do) |
| Chapter 23: Latent space and block models | [`ch23_latent_space_block_models.do`](ch23_latent_space_block_models.do) |
| Chapter 24: Influence and contagion | [`ch24_influence_contagion.do`](ch24_influence_contagion.do) |
| Chapter 25: Stochastic actor-oriented models | [`ch25_stochastic_actor_oriented_models.do`](ch25_stochastic_actor_oriented_models.do) |
| Chapter 26: Advanced stochastic actor-oriented models | [`ch26_advanced_stochastic_actor_oriented_models.do`](ch26_advanced_stochastic_actor_oriented_models.do) |
| Chapter 27: Relational event models | [`ch27_relational_event_models.do`](ch27_relational_event_models.do) |
| Chapter 28: The Dynamic Network Actor Model | [`ch28_dynamic_network_actor_models.do`](ch28_dynamic_network_actor_models.do) |
| Chapter 29: A complete network analysis | [`ch29_complete_network_analysis.do`](ch29_complete_network_analysis.do) |
| Chapter 30: Reproducible and responsible network research | [`ch30_reproducible_responsible_research.do`](ch30_reproducible_responsible_research.do) |
| Appendix A: Performance and network size | [`appendixH_performance.do`](appendixH_performance.do) |
| Appendix B: When things go wrong | [`appendixG_troubleshooting.do`](appendixG_troubleshooting.do) |

Chapter 1 has no code. `nwedit_nodes.csv` and `nwedit_edges.csv` are the node and edge files that the
interactive page of Chapter 5 saves; the Chapter 5 do-file reads them, so that it also runs without the browser
step: [nwedit_nodes.csv](nwedit_nodes.csv), [nwedit_edges.csv](nwedit_edges.csv).
