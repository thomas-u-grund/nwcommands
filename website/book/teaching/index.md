---
title: "Teaching with the book"
parent: "Teaching and workshops"
nav_order: 5
description: "Material for instructors who teach with the book Network Analysis with Stata: course outlines, notes on every chapter and assignments with other data sets."
permalink: /book/teaching/
---

# Teaching with the book
{: .no_toc }

These pages are for instructors who use *Network Analysis with Stata* (forthcoming, Stata Press) in a course, a
workshop or a reading group. They are also useful to anyone who plans a course of self-study with the book.

The book assumes that readers know Stata and does not assume any knowledge of network analysis. Every example
in it runs in Stata/BE, the smallest edition, and every data set is loaded with `nwwebuse`, so students need
nothing on their computers beyond Stata and the software (installation is described in *Getting started*).

{: .highlight }
> **Slides for all three course outlines.** Every week of the two 12-week courses and every day of the five-day
> workshop has a deck, as PowerPoint and PDF, with speaker notes on every slide, a hands-on slide for each block
> that quotes the book's exercises by number, and the numbers from real runs. Instructors are free to use, adapt
> and share them. Find them in the [course outlines](outlines/) (a *Slides* line under each week and day), and the
> three three-hour sessions of the [six-hour workshop](workshop/) have their own decks.

1. TOC
{:toc}

## What each chapter gives you

Every chapter is built the same way, which makes it easy to turn into a class session:

- a key question and a list of learning outcomes at the start;
- the ideas, developed alongside Stata examples on real data;
- a section *What can go wrong*, with a box of common mistakes;
- key takeaways and further reading;
- exercises labeled *basic*, *applied* or *open*, with the hints printed after all the exercises, so that
  students can try a question before they read them.

The book has one running investigation: the advice, co-work and friendship networks of the lawyers in a
corporate law firm (`lazega`). The Glasgow schoolgirls (`glasgow`) carry the chapters on change over time, the
Florentine families (`florentine`) are small enough to check by hand, and a London gang (`gang`) shows cohesion
and sorting among offenders. Students meet the same actors again and again, so a course can build up one
picture of the law firm week by week.

Every command printed in the book is also in a do-file for its chapter, on the page
[Do-files of the book](../dofiles/). A do-file runs from top to bottom and is a ready-made script for a
demonstration in class.

## Reading paths and courses

*Getting started* describes three paths through the book. Part I (Chapters 1 to 3) and Chapters 4 to 6 are
common ground for all three. The paths then are:

| Path in *Getting started* | Chapters | Course it fits |
|---|---|---|
| Describing a network | 7 to 14, then 15 (the random graph as a baseline), 16 (networks generated from attributes) and 17 (what a structure does to something that spreads) | an introductory course on network analysis |
| Statistical models for one observed network | 7 and 8, the random graph of 15, then 18 to 21 (baselines, permutation tests, QAP regression, the exponential random graph model); 22 when a project needs it; 23 (hidden groups and positions) and 24 (adoption, exposure and contagion) as extensions | a course on inference for network data |
| Change and events | 14 and the first sections of 21 (effect statistics and change statistics); 25 and 26 for panel data; 27 and then 28 for time-stamped event logs | a course on network dynamics |

Each path ends in Part V: Chapter 29 is one complete analysis of the law firm, and Chapter 30 covers
reproducible and responsible reporting. Chapters 9 to 14 can be taken in any order, so a course can choose
among them to suit its students' data.

The [course outlines](outlines/) turn these paths into three formats:

- a 12-week course on descriptive and inferential network analysis, which follows the common ground, the
  describing path and the first half of the path for statistical models;
- a 12-week course on statistical models, which can be taught as a second course and covers the rest of Part IV
  (except Chapters 23 and 24, which are optional reading), for one network, for panels and for event logs;
- a 5-day workshop or summer school, which covers the common ground, the main descriptive tools and the first
  models.

## On the following pages

- [Course outlines](outlines/): week by week (or day by day), the chapters, the core idea, a demonstration with
  the data set and the commands the chapter uses, and the exercises to assign.
- [Six-hour workshop](workshop/): two sessions of three hours for network researchers who are new
  to Stata or to nwcommands, one on the core workflow and one on ERGMs and SAOMs, with a timed agenda, setup
  instructions and R equivalents.
- [Chapter notes](chapter-notes/): for each of the 30 chapters, the rough time it needs, its data sets, the
  chapters it builds on, the commands it teaches, where students typically get stuck, and its exercises by level.
- [Assignments with other data](assignments/): problem sets that apply the book's methods to data sets that
  `nwwebuse` loads but the chapters do not use as their main example.
- [Exercise bank](exercises/): about 85 more exercises with hints, by chapter, that are not printed in the book.

## Exercises and hints

Exercises are cited on these pages as "Ch. 8, Ex. 3": the third exercise of Chapter 8, counted in the order in
which the exercises appear in the chapter, which is the number printed in the book. The book prints a hint for
every exercise. Basic exercises check a definition, a calculation by hand or a single command. Applied exercises
apply the chapter's ideas to the book's data or to a new case, mostly with Stata. Open exercises ask for an
argument or a study design and have no single answer.
