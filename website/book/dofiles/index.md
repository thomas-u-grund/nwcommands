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

The do-files were checked against nwcommands 3.18 and the model packages current in November 2026.
Results of the model chapters (21 to 25) depend on the random-number seed and can differ slightly from the
printed output with other versions.

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
| Chapter 17: Simulating from network models | [`ch17_simulating_from_models.do`](ch17_simulating_from_models.do) |
| Chapter 18: Random networks and null models | [`ch18_random_networks_null_models.do`](ch18_random_networks_null_models.do) |
| Chapter 19: Permutation inference and comparing networks | [`ch19_permutation_inference_comparing_networks.do`](ch19_permutation_inference_comparing_networks.do) |
| Chapter 20: QAP regression | [`ch20_qap_regression.do`](ch20_qap_regression.do) |
| Chapter 21: Exponential random graph models | [`ch21_exponential_random_graph_models.do`](ch21_exponential_random_graph_models.do) |
| Chapter 22: Stochastic actor-oriented models | [`ch22_stochastic_actor_oriented_models.do`](ch22_stochastic_actor_oriented_models.do) |
| Chapter 23: Advanced stochastic actor-oriented models | [`ch23_advanced_stochastic_actor_oriented_models.do`](ch23_advanced_stochastic_actor_oriented_models.do) |
| Chapter 24: Relational event models | [`ch24_relational_event_models.do`](ch24_relational_event_models.do) |
| Chapter 25: The Dynamic Network Actor Model | [`ch25_dynamic_network_actor_models.do`](ch25_dynamic_network_actor_models.do) |
| Chapter 26: A complete network analysis | [`ch26_complete_network_analysis.do`](ch26_complete_network_analysis.do) |
| Chapter 27: Reproducible and responsible network research | [`ch27_reproducible_responsible_research.do`](ch27_reproducible_responsible_research.do) |
| Appendix A: Performance and network size | [`appendixH_performance.do`](appendixH_performance.do) |
| Appendix B: When things go wrong | [`appendixG_troubleshooting.do`](appendixG_troubleshooting.do) |
| Appendix F: Programming with network objects | [`appendixE_programming.do`](appendixE_programming.do) |

Chapter 1 has no code. `nwedit_nodes.csv` and `nwedit_edges.csv` are the node and edge files that the
interactive page of Chapter 5 saves; the Chapter 5 do-file reads them, so that it also runs without the browser
step: [nwedit_nodes.csv](nwedit_nodes.csv), [nwedit_edges.csv](nwedit_edges.csv).
