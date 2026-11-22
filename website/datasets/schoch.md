---
title: "Schoch networkdata"
parent: "Data sets"
permalink: /datasets/schoch/
description: "The 2,274 networks of David Schoch's R package networkdata, loadable with nwwebuse schoch: what they are, where they come from, how to cite them."
---

# The networkdata collection (Schoch)
{: .no_toc }

nwcommands ships none of these networks. `nwwebuse schoch <name>` (or `nwnetworkdata <name>`) downloads the original file from David Schoch's repository <https://github.com/schochastics/networkdata>, keeps it in a cache in your PLUS directory, converts it on your computer (R with the package igraph is needed, only for the first use of a data set) and builds the network. The R package is distributed under the MIT licence (Copyright (c) 2019 David Schoch); it states no licence for the individual data sets. **Please cite the original source of every data set you use, and the collection:**

> Schoch, D. (2022). *networkdata: Repository of Network Datasets*. <https://doi.org/10.5281/zenodo.7189928>

The tennis networks `atp` and `wta` were constructed from data gathered and compiled by Jeff Sackmann (<https://github.com/JeffSackmann>); the package asks to give credit to him. Titles, descriptions, sources and references below are reproduced from the documentation of the package (version 0.2.4 of the repository); they were not checked by the nwcommands authors. The package says that many data sets were assembled automatically and may contain errors.

```stata
. nwwebuse schoch list
. nwwebuse schoch describe karate
. nwwebuse schoch karate, nwclear
. nwwebuse schoch sampson, nwclear element(3)
```

A data set that is a *list of networks* (waves, seasons, groups) is loaded with all its networks, called `name_1`, `name_2`, ...; `element()` loads some of them. Size is nodes/edges as stored in R (parallel edges counted separately).

## Summary

990 R objects: 917 single igraph networks, 72 lists of networks (together 1357 networks) and 1 ego-centered egor object (not a network). 2274 networks in total: 1962 undirected, 289 directed, 23 two-mode; 1823 with edge weights, 121 with multiple edges, 44 with loops, 7 with edge time stamps.

- Animal social networks (Animal Social Network Repository): 36 data sets
- Covert networks: 46 data sets
- Freeman's data sets (UCINET / Moreno collection): 60 data sets
- KONECT networks: 22 data sets
- Miscellaneous networks: 17 data sets
- Movie networks (Harvard Dataverse): 773 data sets
- Shakespeare's plays: 36 data sets

## Animal social networks (Animal Social Network Repository)

### animal_1: Fishstickleback Proximity (weighted)
{: #animal_1 }
- **Networks:** list of 7 networks `animal_1_1` ... `animal_1_7`: undirected, valued; 10-10 nodes, 45-45 edges.
- **Sizes (element:nodes/edges):** 1:10/45 2:10/45 3:10/45 4:10/45 5:10/45 6:10/45 7:10/45
- **Description:** Species: \*Gasterosteus aculeatus\* Taxonomic class: Actinopterygii Population type: captive Geographical location: St. Andrews, UK Data collection technique: video Interaction type: group membership Definition of interaction: A pair of individuals were classed as shoaling if they were within four body lengths of one another from head to head. Gambit of the group approach was then used to assume that a string of fish connected by less than two body lengths were all assumed to be associating with one another. Edge weight type: frequency Total duration of data collection: 120 min Time resolution of data collection (within a day): 6 min Time span of data collection (within a day): 120 min Note: Networks represent social data collected from seven replicate groups of fish
- **Source:** https: //bansallab.github.io/asnr/
- **References:** Atton, N., et al. "Familiarity affects social network structure and discovery of prey patch locations in foraging stickleback shoals." Proceedings of the Royal Society of London B: Biological Sciences 281.1789 (2014): 20140579.
- **Load:** `nwwebuse schoch animal_1`

### animal_10: Philetairus socius
{: #animal_10 }
- **Networks:** list of 23 networks `animal_10_1` ... `animal_10_23`: undirected; 5-64 nodes, 9-177 edges.
- **Sizes (element:nodes/edges):** 1:18/28 2:7/12 3:5/10 4:42/152 5:18/27 6:13/19 7:19/64 8:9/10 9:34/147 10:12/36 11:16/21 12:42/113 13:39/124 14:31/117 15:11/38 16:23/43 17:64/177 18:6/9 19:6/11 20:18/80 21:14/62 22:15/64 23:24/62
- **Description:** Species: \*Philetairus socius\* Taxonomic class: Aves Population type: free-ranging Geographical location: Kimberley, South Africa Data collection technique: mark recapture Interaction type: social projection bipartite Definition of interaction: A network edge was drawn between individuals that used the same nest chambers either for roosting or nest-building at any given time within a series of observations at the same colony in the same year, either together in the nest chamber at the same time or at different times. Edge weight type: unweighted Total duration of data collection: 10 months Time resolution of data collection (within a day): Time span of data collection (within a day): focal follow/ad libitum Note: Networks represent social data collected from 23 colonies of sociable weavers
- **Source:** https: //bansallab.github.io/asnr/
- **References:** Dijk, René E., et al. "Cooperative investment in public goods is kin directed in communal nests of social birds." Ecology letters 17.9 (2014): 1141-1148.
- **Load:** `nwwebuse schoch animal_10`

### animal_11: Wild birds
{: #animal_11 }
- **Networks:** list of 6 networks `animal_11_1` ... `animal_11_6`: undirected, valued; 126-149 nodes, 1444-2837 edges.
- **Sizes (element:nodes/edges):** 1:131/1444 2:135/1483 3:126/1615 4:135/2009 5:145/2512 6:149/2837
- **Description:** Species: \*Wild birds\* Taxonomic class: Aves Population type: free-ranging Geographical location: Oxford, UK Data collection technique: RFID Interaction type: social projection bipartite Definition of interaction: Groups were defined as individuals detected on the same nest-box during the same day, and co-memberships represented individuals that overlapped in nest-box exploration patterns during the same day. Networks were calculated from these group-by-individual matrices using the halfweight index. Edge weight type: half\_weight\_index Total duration of data collection: 6 days Time resolution of data collection (within a day): 1 sec Time span of data collection (within a day): 12 hours Note: Each network represents social data collected for consecutive 6-day time window.
- **Source:** https: //bansallab.github.io/asnr/
- **References:** Firth, Josh A., and Ben C. Sheldon. "Experimental manipulation of avian social structure reveals segregation is carried over across contexts." Proceedings of the Royal Society of London B: Biological Sciences 282.1802 (2015): 20142350.
- **Load:** `nwwebuse schoch animal_11`

### animal_12: Ants Proximity (weighted)
{: #animal_12 }
- **Networks:** list of 244 networks `animal_12_1` ... `animal_12_244`: undirected, valued; 35-164 nodes, 480-11139 edges.
- **Sizes (element:nodes/edges):** 1:113/4550 2:113/4573 3:113/4483 4:113/4094 5:113/4149 6:113/4259 7:113/4077 8:113/4076 9:113/4128 10:113/3943 11:113/3454 12:99/3248 13:99/3252 14:99/3399 15:99/3301 16:99/3397 17:99/3342 18:99/3423 19:99/3196 20:99/3147 21:99/3266 22:80/2269 23:80/2246 24:80/2372 25:80/2117 26:80/2137 27:80/2010 28:80/2143 29:80/2221 30:80/2220 31:80/1882 32:56/1090 33:56/1082 34:56/1118 35:56/1210 36:56/1083 37:55/1158 38:56/1134 39:55/1106 40:55/1094 41:55/1129 42:131/6591 43:131/6464 44:131/6497 45:131/6198 46:131/5926 47:131/5960 48:131/6293 49:131/6078 50:131/6375 51:131/5679 52:131/5704 53:111/3808 54:111/3929 55:111/3930 56:111/3972 57:111/4041 58:111/3921 59:111/3825 60:111/3743 61:111/3902 62:111/3843 63:90/2507 64:90/2605 65:90/2313 66:90/2336 67:89/2351 68:89/2394 69:88/2195 70:89/2373 71:88/2401 72:87/2008 73:58/1015 74:58/1086 75:58/1061 76:58/991 77:58/1015 78:58/928 79:58/963 80:58/879 81:58/895 82:58/930 83:160/11139 84:160/9844 85:160/9191 86:160/9092 87:160/8863 88:160/8823 89:160/8690 90:159/8482 91:160/8883 92:159/9046 93:160/8451 94:141/6404 95:141/6477 96:141/6607 97:141/6403 98:141/7025 99:141/6731 100:141/6609 101:141/6417 102:141/6368 103:140/6480 104:115/4684 105:115/4647 106:115/4477 107:115/4440 108:115/4535 109:115/4545 110:115/4634 111:115/4695 112:115/4321 113:115/4161 114:95/2990 115:95/2977 116:95/3348 117:95/2915 118:94/3028 119:94/2969 120:94/2985 121:93/3059 122:93/2853 123:94/2992 124:102/4269 125:102/4149 126:102/4055 127:102/3754 128:102/3929 129:102/3903 130:102/3797 131:102/3857 132:102/3988 133:102/4036 134:102/3592 135:73/2067 136:73/2119 137:73/2107 138:73/2144 139:73/2095 140:73/2089 141:73/2022 142:73/2041 143:73/2184 144:73/2120 145:55/1234 146:55/1228 147:55/1167 148:55/1204 149:55/1240 150:55/1266 151:55/1276 152:55/1272 153:55/1252 154:55/1221 155:35/497 156:35/490 157:35/505 158:35/501 159:35/488 160:35/484 161:35/480 162:35/492 163:35/485 164:35/500 165:152/9053 166:152/9141 167:152/8634 168:152/8566 169:152/8410 170:152/8379 171:152/8093 172:152/8032 173:152/7835 174:152/7779 175:152/6716 176:133/6057 177:133/5995 178:133/6235 179:133/5990 180:133/5926 181:133/6082 182:133/6180 183:133/5795 184:133/5907 185:132/5923 186:89/2937 187:89/2945 188:89/3029 189:89/2916 190:89/2568 191:89/2856 192:89/2956 193:89/2866 194:89/2861 195:89/2556 196:66/1546 197:66/1485 198:66/1425 199:66/1506 200:66/1554 201:66/1492 202:66/1570 203:66/1501 204:66/1512 205:66/1508 206:164/10731 207:164/10272 208:164/10090 209:164/10313 210:164/10005 211:164/9726 212:164/9860 213:164/9664 214:164/10774 215:164/9354 216:164/8042 217:143/6625 218:143/7068 219:143/7037 220:143/7098 221:143/6611 222:143/7178 223:143/7061 224:143/7209 225:143/6760 226:143/7121 227:118/4885 228:118/4888 229:118/4536 230:118/4658 231:118/4842 232:118/4788 233:118/4784 234:118/5112 235:118/4709 236:118/4383 237:91/2817 238:91/2718 239:91/2616 240:91/2670 241:91/2717 242:91/2570 243:91/2475 244:91/2447
- **Description:** Species: \*Camponotus fellah\* Taxonomic class: Insecta Population type: captive Geographical location: University of Lausanne, Laussane, Switzerland Data collection technique: video Interaction type: physical contact Definition of interaction: A pair of ants was considered to interact when the front end of one ant was located within the trapezoidal shape representing the other ant. Edge weight type: frequency Total duration of data collection: 1day Time resolution of data collection (within a day): 0.5 sec Time span of data collection (within a day): 24 hours Note: Networks represent six separate colonies of the ant. The authors recorded the position and orientation of all individuals twice per second to reconstruct spatial movement and infer all social interactions occurring over the 41 days of the experiment.
- **Source:** https: //bansallab.github.io/asnr/
- **References:** Mersch, Danielle P., Alessandro Crespi, and Laurent Keller. "Tracking individuals shows spatial fidelity is a key regulator of ant social organization."Science 340.6136 (2013): 1090-1093.
- **Load:** `nwwebuse schoch animal_12`

### animal_13: Ants Trophallaxis (weighted)
{: #animal_13 }
- **Networks:** list of 16 networks `animal_13_1` ... `animal_13_16`: undirected, valued; 24-37 nodes, 23-68 edges.
- **Sizes (element:nodes/edges):** 1:30/37 2:24/32 3:29/28 4:35/51 5:27/26 6:30/23 7:29/43 8:37/68 9:26/36 10:24/30 11:28/45 12:31/41 13:30/32 14:33/46 15:31/52 16:27/48
- **Description:** Species: \*Camponotus pennsylvanicus\* Taxonomic class: Insecta Population type: captive Geographical location: Old Main, State College, Pennsylvania Data collection technique: video Interaction type: trophallaxis Definition of interaction: " A trophallaxis event was recorded when ants engaged in mandible-to-mandible contact for greater than 1 s" Edge weight type: duration Total duration of data collection: 1 day Time resolution of data collection (within a day): 1sec Time span of data collection (within a day): 20min Note: Networks represent two C. pennsylvanicus colonies. Each colony was filmed for approximately 30 minutes for 8 consecutive nights.
- **Source:** https: //bansallab.github.io/asnr/
- **References:** Quevillon, Lauren E., et al. "Social, spatial, and temporal organization in a complex insect society." Scientific reports 5 (2015).
- **Load:** `nwwebuse schoch animal_13`

### animal_14: Beetle Proximity (weighted)
{: #animal_14 }
- **Networks:** list of 12 networks `animal_14_1` ... `animal_14_12`: undirected, valued (types differ between the networks); 27-30 nodes, 117-210 edges.
- **Sizes (element:nodes/edges):** 1:30/185 2:30/210 3:27/117 4:30/195 5:28/131 6:29/174 7:30/138 8:30/176 9:30/161 10:30/178 11:29/180 12:30/155
- **Description:** Species: \*Bolitotherus cornutus\* Taxonomic class: Insecta Population type: captive Geographical location: Virginia, USA Data collection technique: survey scan Interaction type: spatial proximity Definition of interaction: Social partners were defined as any beetle within 3 cm (i.e., approximately 2 body lengths) of the focal beetle. Edge weight type: simple\_ratio\_index Total duration of data collection: 12 days Time resolution of data collection (within a day): 3.5 hours Time span of data collection (within a day): few minutes Note: Networks represent four control (C) and four treatment (T) groups recorded during �undisturbed� phase where individuals were allowed to interact with each other freely.
- **Source:** https: //bansallab.github.io/asnr/
- **References:** Formica, Vincent, et al. "Consistency of animal social networks after disturbance." Behavioral Ecology (2016): arw128.
- **Load:** `nwwebuse schoch animal_14`

### animal_15: Asianelephants Dominance (unweighted)
{: #animal_15 }
- **Network:** `animal_15`: undirected, valued; 73 nodes, 60 edges.
- **Description:** Species: \*Elephas maximus\* Taxonomic class: Mammalia Population type: free-ranging Geographical location: Uda Walawe National Park, Sri Lanka Data collection technique: focal sampling Interaction type: dominance Definition of interaction: Indicators of dominance as well as subordination was included. If a series of interactions occurred during a particular event, the winners/losers were determined only on conclusion of the event, when individuals or groups moved apart. Edge weight type: unweighted Total duration of data collection: 206days Time resolution of data collection (within a day): 1sec Time span of data collection (within a day): 5.5 hours Note:
- **Source:** https: //bansallab.github.io/asnr/
- **References:** de Silva, Shermin, Volker Schmid, and George Wittemyer. "Fission–fusion processes weaken dominance networks of female Asian elephants in a productive habitat." Behavioral Ecology (2016): arw153.
- **Load:** `nwwebuse schoch animal_15`

### animal_16: Baboon Association (weighted)
{: #animal_16 }
- **Networks:** list of 58 networks `animal_16_1` ... `animal_16_58`: undirected, valued (types differ between the networks); 4-26 nodes, 0-41 edges.
- **Sizes (element:nodes/edges):** 1:4/6 2:5/8 3:26/31 4:4/4 5:4/4 6:8/9 7:16/28 8:20/33 9:25/22 10:13/32 11:14/25 12:8/5 13:9/4 14:7/17 15:6/12 16:6/11 17:9/15 18:10/27 19:13/16 20:13/30 21:8/15 22:8/9 23:23/30 24:21/7 25:19/9 26:19/7 27:18/27 28:18/21 29:13/19 30:4/4 31:5/6 32:26/35 33:4/4 34:4/5 35:8/11 36:16/41 37:20/14 38:25/21 39:13/30 40:14/17 41:8/2 42:9/3 43:7/10 44:6/9 45:6/5 46:9/7 47:10/8 48:13/14 49:13/21 50:8/18 51:8/10 52:23/23 53:21/0 54:19/14 55:19/25 56:18/32 57:18/23 58:13/28
- **Description:** Species: \*Papio cynocephalus\* Taxonomic class: Mammalia Population type: free-ranging Geographical location: Amboseli National Park, Kenya Data collection technique: focal sampling Interaction type: spatial proximity Definition of interaction: These networks were constructed based on nearest neighbour data collected during focal sampling. Edge weight type: frequency Total duration of data collection: 30days Time resolution of data collection (within a day): Time span of data collection (within a day): focal follow/ad libitum Note: Networks represent grooming interaction or association between five social groups of baboons. Each network summarizes data collected within 30 days before and 90 days after each knockout. A natural knockout was considered to have occurred when a given alpha or beta male was present in the group for at least three months prior to his disappearance, and then he disappeared permanently from the group.
- **Source:** https: //bansallab.github.io/asnr/
- **References:** Franz, Mathias, Jeanne Altmann, and Susan C. Alberts. "Knockouts of high-ranking males have limited impact on baboon social networks." Current zoology 61.1 (2015): 107-113.
- **Load:** `nwwebuse schoch animal_16`

### animal_17: Bats Foodsharing (weighted)
{: #animal_17 }
- **Network:** `animal_17`: undirected, valued; 21 nodes, 72 edges.
- **Description:** Species: \*Desmodus rotundus\* Taxonomic class: Mammalia Population type: captive Geographical location: Bloomfield Hills, Michigan, USA Data collection technique: video Interaction type: trophallaxis Definition of interaction: Food sharing event were defined as periods where food could be passed that lasted at least 5 s and were separated by more than 5s. Edge weight type: duration Total duration of data collection: 2 hours Time resolution of data collection (within a day): 1 sec Time span of data collection (within a day): 2 hours Note:
- **Source:** https: //bansallab.github.io/asnr/
- **References:** Carter, Gerald G., and Gerald S. Wilkinson. "Food sharing in vampire bats: reciprocal help predicts donations more than relatedness or harassment."Proceedings of the Royal Society of London B: Biological Sciences 280.1753 (2013): 20122573.
- **Load:** `nwwebuse schoch animal_17`

### animal_18: Bats Roostuse (weighted)
{: #animal_18 }
- **Network:** `animal_18`: undirected, valued; 43 nodes, 546 edges.
- **Description:** Species: \*Myotis sodalis\* Taxonomic class: Mammalia Population type: free-ranging Geographical location: Pickaway County, Ohio, USA Data collection technique: radio tags Interaction type: social projection bipartite Definition of interaction: Roost network was first contructed as a two-mode network that consisted of bats and roosts. Single-mode projection of the bat nodes was used to assess colony social structure. Edge weight type: unweighted Total duration of data collection: 1 year Time resolution of data collection (within a day): Time span of data collection (within a day): 8 hours Note:
- **Source:** https: //bansallab.github.io/asnr/
- **References:** Silvis, Alexander, et al. "Roosting and foraging social structure of the endangered Indiana bat (Myotis sodalis)." PloS one 9.5 (2014): e96937.
- **Load:** `nwwebuse schoch animal_18`

### animal_19: Bison Dominance (weighted)
{: #animal_19 }
- **Network:** `animal_19`: undirected, valued; 26 nodes, 222 edges.
- **Description:** Species: \*Bison bison\* Taxonomic class: Mammalia Population type: semi-ranging Geographical location: Moiese, Montana, USA Data collection technique: survey scan Interaction type: dominance Definition of interaction: Only those aggressive interactions were analyzed that led to an outcome in which the lost and the winner could be categorized unambiguosly Edge weight type: frequency Total duration of data collection: 2 months Time resolution of data collection (within a day): 1sec Time span of data collection (within a day): focal follow/ad libitum Note:
- **Source:** https: //bansallab.github.io/asnr/
- **References:** Dale F Lott. Dominance relations and breeding rate in mature male American bison. Zeitschrift für Tierpsychologie, 49(4): 418-432, 1979.
- **Load:** `nwwebuse schoch animal_19`

### animal_2: Guppy Proximity Frequency (weighted)
{: #animal_2 }
- **Networks:** list of 9 networks `animal_2_1` ... `animal_2_9`: undirected, valued; 6-6 nodes, 15-15 edges.
- **Sizes (element:nodes/edges):** 1:6/15 2:6/15 3:6/15 4:6/15 5:6/15 6:6/15 7:6/15 8:6/15 9:6/15
- **Description:** Species: \*Poecilia reticulata\* Taxonomic class: Actinopterygii Population type: captive Geographical location: Louisville, Kentucky Data collection technique: video Interaction type: spatial proximity Definition of interaction: A contact phase between two individuals was one or more consecutive observations in which they were recorded as being within four body length to one another. Edge weight type: frequency Total duration of data collection: 90min Time resolution of data collection (within a day): 10 seconds Time span of data collection (within a day): 90min Note: Networks represent 10 independed replicates of grourp of 5 guppies that were familiar with each other
- **Source:** https: //bansallab.github.io/asnr/
- **References:** Hasenjager, Matthew J., and Lee Alan Dugatkin. "Familiarity affects network structure and information flow in guppy (Poecilia reticulata) shoals." Behavioral Ecology (2016): arw152.
- **Load:** `nwwebuse schoch animal_2`

### animal_20: Cattle Dominance (weighted)
{: #animal_20 }
- **Network:** `animal_20`: undirected, valued; 28 nodes, 205 edges.
- **Description:** Species: \*Cattle N/A\* Taxonomic class: Mammalia Population type: semi-ranging Geographical location: Jeanerette, Louisiana, USA Data collection technique: survey scan Interaction type: dominance Definition of interaction: The dominance relationship was ascertained from direct physical contests. Edge weight type: frequency Total duration of data collection: Not specified Time resolution of data collection (within a day): 1 sec Time span of data collection (within a day): 1 hour Note:
- **Source:** https: //bansallab.github.io/asnr/
- **References:** Martin W. Schein and Milton H. Fohrman. Social dominance relationships in a herd of dairy cattle. The British J. of Animal Behaviour, 3(2): 45-55, 1955.
- **Load:** `nwwebuse schoch animal_20`

### animal_21: Dolphin Association (weighted)
{: #animal_21 }
- **Networks:** list of 4 networks `animal_21_1` ... `animal_21_4`: undirected, valued; 151-291 nodes, 1032-3182 edges.
- **Sizes (element:nodes/edges):** 1:190/1134 2:291/3182 3:151/1554 4:188/1032
- **Description:** Species: \*Tursiops truncatus\* Taxonomic class: Mammalia Population type: free-ranging Geographical location: Cedar Key, Florida, USA Data collection technique: survey scan Interaction type: spatial proximity Definition of interaction: Interactions characterized by prey capture or persistent incidents of prey searching as indicated by long dives or specialized feeding behaviours with direction shifts between surfacings. Edge weight type: frequency Total duration of data collection: 124 days Time resolution of data collection (within a day): Time span of data collection (within a day): 5min Note: Four networks: an overall network that does not take behaviour into account, and the socialize network, the travel network and the forage network that correspond to their respective behaviours.
- **Source:** https: //bansallab.github.io/asnr/
- **References:** Gazda, Stefanie, et al. "The importance of delineating networks by activity type in bottlenose dolphins (Tursiops truncatus) in Cedar Key, Florida." Royal Society open science 2.3 (2015): 140263.
- **Load:** `nwwebuse schoch animal_21`

### animal_22: Dolphin Proximity (unweighted)
{: #animal_22 }
- **Network:** `animal_22`: undirected; 62 nodes, 159 edges.
- **Description:** Species: \*Tursiops truncatus\* Taxonomic class: Mammalia Population type: free-ranging Geographical location: Fiordland, New Zealand Data collection technique: survey scan Interaction type: spatial proximity Definition of interaction: All members of a school were assumed associated. Half-weight index (HWI) was used to quantify the frequency of association among individuals. Edge weight type: frequency Total duration of data collection: 594 days Time resolution of data collection (within a day): Time span of data collection (within a day): Not specified Note:
- **Source:** https: //bansallab.github.io/asnr/
- **References:** Lusseau, David, et al. "The bottlenose dolphin community of Doubtful Sound features a large proportion of long-lasting associations." Behavioral Ecology and Sociobiology 54.4 (2003): 396-405.
- **Load:** `nwwebuse schoch animal_22`

### animal_23: Elephantseal Dominance (weighted)
{: #animal_23 }
- **Networks:** list of 4 networks `animal_23_1` ... `animal_23_4`: undirected, valued; 18-50 nodes, 15-58 edges.
- **Sizes (element:nodes/edges):** 1:50/58 2:18/15 3:30/33 4:35/23
- **Description:** Species: \*Mirounga angustirostris\* Taxonomic class: Mammalia Population type: free-ranging Geographical location: California, USA Data collection technique: survey scan Interaction type: dominance Definition of interaction: Dominance status determined by Elo rating based on winner of an competitive interaction and intensity of interaction Edge weight type: frequency Total duration of data collection: 69 days Time resolution of data collection (within a day): Time span of data collection (within a day): focal follow/ad libitum Note: Network represent interactions collected over different years and/or in different colonies
- **Source:** https: //bansallab.github.io/asnr/
- **References:** Casey, Caroline, et al. "Rival assessment among northern elephant seals: evidence of associative learning during male–male contests." Royal Society open science 2.8 (2015): 150228.
- **Load:** `nwwebuse schoch animal_23`

### animal_24: Hyenas Groupmembership (weighted)
{: #animal_24 }
- **Networks:** list of 3 networks `animal_24_1` ... `animal_24_3`: undirected, valued; 35-36 nodes, 509-585 edges.
- **Sizes (element:nodes/edges):** 1:35/521 2:36/585 3:35/509
- **Description:** Species: \*Crocuta crocuta\* Taxonomic class: Mammalia Population type: free-ranging Geographical location: Masai Mara National Reserve, Kenya Data collection technique: survey scan Interaction type: group membership Definition of interaction: Association patterns were recorded based on the co-occurrence of each pair of individuals, during the period for which they were concurrently present in the clan. Edge weight type: twice\_weight\_index Total duration of data collection: 4 months (approx 16 days each month) Time resolution of data collection (within a day): 15min Time span of data collection (within a day): few hours Note: The three social networks were collected during periods of low (networks A and C) and high (network B) prey abundance.
- **Source:** https: //bansallab.github.io/asnr/
- **References:** Holekamp, Kay E., et al. "Society, demography and genetic structure in the spotted hyena." Molecular Ecology 21.3 (2012): 613-632.
- **Load:** `nwwebuse schoch animal_24`

### animal_25: Kangeroos Proximity (weighted)
{: #animal_25 }
- **Network:** `animal_25`: undirected, valued; 17 nodes, 91 edges.
- **Description:** Species: \*Macropus giganteus\* Taxonomic class: Mammalia Population type: free-ranging Geographical location: New South Wales, Australia Data collection technique: survey scan Interaction type: spatial proximity Definition of interaction: Two individuals were assumed to be associating if they occured within 120 cm of another at set 15-min intervals in the enclosure. Edge weight type: frequency Total duration of data collection: Not specified Time resolution of data collection (within a day): Time span of data collection (within a day): focal follow/ad libitum Note:
- **Source:** https: //bansallab.github.io/asnr/
- **References:** TR Grant. Dominance and association among members of a captive and a free-ranging group of grey kangaroos (Macropus giganteus). Animal Behaviour, 21(3): 449-456, 1973.
- **Load:** `nwwebuse schoch animal_25`

### animal_26: Possum Burrowsharing (weighted)
{: #animal_26 }
- **Network:** `animal_26`: undirected, valued; 15 nodes, 13 edges.
- **Description:** Species: \*Trichosurus cunninghami\* Taxonomic class: Mammalia Population type: free-ranging Geographical location: Cambarville, Victoria, Australia Data collection technique: logger Interaction type: social projection bipartite Definition of interaction: The proximity loggers recorded the identity of interacting individuals (based on a threshold proximity set to detect den-sharing events) and the time and length of those interactions. From these data, den-sharing was recorded as a binary variable with �1� representing an instance of day-time den-sharing and �0� representing the use of separate dens for every pairwise combination of individuals on each of the 223 days of data collection. Edge weight type: frequency Total duration of data collection: 3 months Time resolution of data collection (within a day): 1 sec Time span of data collection (within a day): 24 hours Note:
- **Source:** https: //bansallab.github.io/asnr/
- **References:** Banks, Sam C., et al. "Adaptive responses and disruptive effects: how major wildfire influences kinship‐based social interactions in a forest marsupial." Molecular ecology 21.3 (2012): 673-684.
- **Load:** `nwwebuse schoch animal_26`

### animal_27: Primates Association (weighted)
{: #animal_27 }
- **Networks:** list of 19 networks `animal_27_1` ... `animal_27_19`: undirected, valued; 5-25 nodes, 10-181 edges.
- **Sizes (element:nodes/edges):** 1:15/45 2:21/60 3:16/73 4:16/89 5:25/181 6:19/55 7:24/103 8:25/97 9:7/20 10:6/15 11:10/13 12:5/10 13:22/167 14:12/43 15:15/59 16:8/18 17:19/49 18:19/114 19:19/129
- **Description:** Species: \*Macaca fuscata\* Taxonomic class: Mammalia Population type: free-ranging Geographical location: Yakushima, Japan Data collection technique: focal sampling Interaction type: grooming Definition of interaction: Based on observation of grooming interaction Edge weight type: frequency Total duration of data collection: 3 months Time resolution of data collection (within a day): Time span of data collection (within a day): focal follow/ad libitum Note: Networks represent four control (C) and four treatment (T) groups recorded during �undisturbed� phase where individuals were allowed to interact with each other freely.
- **Source:** https: //bansallab.github.io/asnr/
- **References:** Griffin, Randi H., and Charles L. Nunn. "Community structure and the spread of infectious disease in primate social networks." Evolutionary Ecology 26.4 (2012): 779-800.
- **Load:** `nwwebuse schoch animal_27`

### animal_28: Raccoon Proximity (weighted)
{: #animal_28 }
- **Networks:** list of 52 networks `animal_28_1` ... `animal_28_52`: undirected, valued; 8-24 nodes, 17-100 edges.
- **Sizes (element:nodes/edges):** 1:23/63 2:19/50 3:19/46 4:19/48 5:19/57 6:18/59 7:18/49 8:17/42 9:16/30 10:15/26 11:17/35 12:22/50 13:17/35 14:18/22 15:16/33 16:14/32 17:14/41 18:15/36 19:16/42 20:14/27 21:15/27 22:13/21 23:23/50 24:8/19 25:10/23 26:13/27 27:13/39 28:13/26 29:14/23 30:14/25 31:14/18 32:12/17 33:15/21 34:24/100 35:16/35 36:18/47 37:17/35 38:16/29 39:12/31 40:13/25 41:12/23 42:13/24 43:14/23 44:11/22 45:22/67 46:16/33 47:15/34 48:16/32 49:22/75 50:22/82 51:22/61 52:21/60
- **Description:** Species: \*Procyon lotor\* Taxonomic class: Mammalia Population type: free-ranging Geographical location: Illinois, USA Data collection technique: logger Interaction type: spatial proximity Definition of interaction: Close proximity (within 1�1.5m). Any contacts \<1 s in duration were excluded. Edge weight type: duration Total duration of data collection: 7days Time resolution of data collection (within a day): 1 sec Time span of data collection (within a day): 24 hours Note: Networks represents adjacency matrices constructed for each week of the year
- **Source:** https: //bansallab.github.io/asnr/
- **References:** Reynolds, Jennifer JH, et al. "Raccoon contact networks predict seasonal susceptibility to rabies outbreaks and limitations of vaccination." Journal of Animal Ecology 84.6 (2015): 1720-1731.
- **Load:** `nwwebuse schoch animal_28`

### animal_29: Rhesusmacaque Association (weighted)
{: #animal_29 }
- **Networks:** list of 2 networks `animal_29_1` ... `animal_29_2`: undirected, valued; 28-28 nodes, 228-378 edges.
- **Sizes (element:nodes/edges):** 1:28/378 2:28/228
- **Description:** Species: \*Macaca mulatta\* Taxonomic class: Mammalia Population type: captive Geographical location: Rijswijk, the Netherlands Data collection technique: survey scan Interaction type: physical contact Definition of interaction: Edge defined based on individuals sitting in contact with eah other. Edge weight type: frequency Total duration of data collection: 3years Time resolution of data collection (within a day): 1 hour Time span of data collection (within a day): few minutes Note: Two networks represent proximity (contact sits) and grooming patterns - who was sitting in contact with whom and who was grooming whom.
- **Source:** https: //bansallab.github.io/asnr/
- **References:** Massen, Jorg JM, and Elisabeth HM Sterck. "Stability and durability of intra-and intersex social bonds of captive rhesus macaques (Macaca mulatta)." International Journal of Primatology 34.4 (2013): 770-791.
- **Load:** `nwwebuse schoch animal_29`

### animal_3: Hirundo rustica
{: #animal_3 }
- **Networks:** list of 2 networks `animal_3_1` ... `animal_3_2`: undirected, valued; 17-17 nodes, 53-122 edges.
- **Sizes (element:nodes/edges):** 1:17/53 2:17/122
- **Description:** Species: \*Hirundo rustica\* Taxonomic class: Aves Population type: free-ranging Geographical location: Boulder County, Colorado, USA Data collection technique: logger Interaction type: physical contact Definition of interaction: Interaction 0.1 m and closer Edge weight type: frequency Total duration of data collection: 11 days Time resolution of data collection (within a day): 1 sec Time span of data collection (within a day): 6 hours Note: Two networks were constructed with edges weighted by the number of interactions at two spatial proximities: body contact interactions and all other spatially proximate interactions
- **Source:** https: //bansallab.github.io/asnr/
- **References:** Levin, Iris I., et al. "Stress response, gut microbial diversity and sexual signals correlate with social interactions." Biology Letters 12.6 (2016): 20160352.
- **Load:** `nwwebuse schoch animal_3`

### animal_30: Rhesusmacaque Dominance (weighted)
{: #animal_30 }
- **Network:** `animal_30`: undirected, valued; 62 nodes, 1167 edges.
- **Description:** Species: \*Macaca fuscata\* Taxonomic class: Mammalia Population type: semi-ranging Geographical location: Arashiyama, Japan Data collection technique: survey scan Interaction type: dominance Definition of interaction: The dominance relations between females were determined based on approach-retreat episodes around the food. The dominance range order was arranged based on these dyadic relations. Edge weight type: frequency Total duration of data collection: 6 months Time resolution of data collection (within a day): 2 hours Time span of data collection (within a day): focal follow/ad libitum Note:
- **Source:** https: //bansallab.github.io/asnr/
- **References:** Takahata, Yukio. "Diachronic changes in the dominance relations of adult female Japanese monkeys of the Arashiyama B group." The monkeys of Arashiyama. State University of New York Press, Albany (1991): 123-139.
- **Load:** `nwwebuse schoch animal_30`

### animal_31: Sheep Dominance (weighted)
{: #animal_31 }
- **Network:** `animal_31`: undirected, valued; 28 nodes, 235 edges.
- **Description:** Species: \*Ovis canadensis\* Taxonomic class: Mammalia Population type: semi-ranging Geographical location: Montana, USA Data collection technique: focal sampling Interaction type: dominance Definition of interaction: Social status was determined by assembling a win-loss matrix based on the outcome of agonistic interactions. The winner of a dominance fight, involving a series of butts and clashes, was recorded as winning one interaction. Edge weight type: frequency Total duration of data collection: 15 months Time resolution of data collection (within a day): Time span of data collection (within a day): focal follow/ad libitum Note:
- **Source:** https: //bansallab.github.io/asnr/
- **References:** Christine C Hass. Social status in female bighorn sheep (Ovis canadensis): Expression, development and reproductive correlates. J. of Zoology, 225(3): 509-523, 1991.
- **Load:** `nwwebuse schoch animal_31`

### animal_32: Spidermonkeys Contact (weighted)
{: #animal_32 }
- **Network:** `animal_32`: undirected, valued, loops; 17 nodes, 72 edges.
- **Description:** Species: \*Ateles hybridus\* Taxonomic class: Mammalia Population type: free-ranging Geographical location: Colombia Data collection technique: focal sampling Interaction type: physical contact Definition of interaction: Physical contact event between the two individuals (e.g. grooming, mating and embracing) Edge weight type: duration Total duration of data collection: 2 years Time resolution of data collection (within a day): 15min Time span of data collection (within a day): focal follow/ad libitum Note:
- **Source:** https: //bansallab.github.io/asnr/
- **References:** Rimbach, Rebecca, et al. "Brown spider monkeys (Ateles hybridus): a model for differentiating the role of social networks and physical contact on parasite transmission dynamics." Phil. Trans. R. Soc. B 370.1669 (2015): 20140110.
- **Load:** `nwwebuse schoch animal_32`

### animal_33: Voles Social Projection Bipartite (weighted)
{: #animal_33 }
- **Networks:** list of 254 networks `animal_33_1` ... `animal_33_254`: undirected, valued (types differ between the networks); 4-183 nodes, 0-515 edges.
- **Sizes (element:nodes/edges):** 1:29/33 2:29/18 3:42/35 4:47/65 5:60/86 6:51/52 7:33/22 8:35/45 9:24/28 10:44/67 11:69/115 12:100/166 13:104/148 14:51/32 15:96/106 16:104/113 17:93/94 18:91/49 19:82/103 20:93/138 21:116/239 22:134/253 23:178/363 24:147/213 25:145/173 26:171/253 27:161/189 28:115/105 29:84/82 30:40/44 31:23/25 32:14/2 33:23/24 34:39/25 35:42/39 36:26/14 37:20/4 38:16/7 39:10/1 40:7/1 41:13/2 42:9/0 43:18/11 44:53/77 45:85/140 46:86/116 47:102/193 48:87/119 49:74/77 50:72/58 51:55/35 52:38/24 53:35/23 54:53/105 55:56/85 56:65/85 57:73/84 58:93/131 59:98/139 60:89/104 61:69/58 62:50/31 63:48/56 64:33/19 65:36/44 66:28/17 67:37/30 68:53/62 69:39/45 70:57/61 71:45/41 72:31/27 73:20/18 74:19/13 75:19/18 76:46/59 77:76/156 78:69/82 79:88/137 80:90/132 81:81/97 82:44/18 83:67/82 84:61/76 85:106/196 86:68/90 87:92/193 88:117/244 89:141/271 90:135/331 91:113/195 92:92/103 93:79/89 94:32/20 95:37/33 96:29/18 97:23/9 98:20/13 99:30/24 100:54/56 101:41/18 102:33/7 103:25/9 104:12/2 105:17/3 106:15/4 107:21/20 108:25/12 109:44/51 110:67/111 111:79/160 112:84/124 113:59/72 114:56/42 115:34/13 116:37/22 117:21/13 118:45/84 119:28/27 120:35/25 121:33/27 122:44/54 123:62/79 124:70/80 125:34/25 126:37/22 127:31/33 128:23/9 129:32/21 130:39/30 131:58/68 132:54/82 133:44/45 134:40/35 135:33/21 136:31/32 137:29/31 138:30/22 139:11/6 140:21/17 141:32/29 142:52/60 143:40/34 144:41/42 145:52/66 146:38/17 147:38/43 148:43/54 149:82/155 150:92/165 151:118/238 152:172/503 153:183/515 154:130/229 155:82/119 156:65/54 157:48/28 158:32/39 159:20/14 160:12/4 161:13/7 162:13/4 163:15/7 164:19/9 165:21/11 166:33/10 167:13/2 168:12/2 169:8/2 170:17/2 171:24/12 172:49/63 173:66/69 174:36/30 175:54/61 176:70/95 177:80/63 178:47/27 179:39/22 180:27/13 181:31/31 182:10/2 183:30/10 184:36/13 185:38/7 186:84/107 187:97/143 188:95/138 189:62/46 190:43/25 191:13/3 192:65/91 193:59/79 194:92/119 195:73/85 196:76/93 197:67/63 198:56/37 199:47/35 200:47/54 201:78/174 202:68/76 203:105/197 204:77/103 205:50/29 206:124/186 207:114/104 208:91/74 209:78/57 210:65/58 211:84/130 212:112/151 213:112/157 214:108/156 215:92/128 216:75/55 217:85/84 218:84/92 219:80/70 220:51/48 221:27/24 222:20/13 223:9/3 224:12/5 225:12/3 226:9/2 227:12/4 228:7/2 229:15/2 230:15/1 231:4/0 232:8/0 233:11/2 234:35/21 235:67/89 236:73/122 237:99/184 238:54/40 239:90/138 240:110/152 241:116/104 242:90/93 243:58/26 244:71/59 245:63/77 246:20/17 247:45/36 248:59/55 249:95/106 250:94/107 251:88/113 252:82/96 253:57/65 254:28/23
- **Description:** Species: \*Microtus agrestis\* Taxonomic class: Mammalia Population type: free-ranging Geographical location: Northumberland, England Data collection technique: mark recapture Interaction type: social projection bipartite Definition of interaction: An edge was inserted into the network whenever two voles were caught in at least one common trap over the primary trapping sessions being considered Edge weight type: frequency Total duration of data collection: 6 days Time resolution of data collection (within a day): 12 hours Time span of data collection (within a day): 24 hours Note: Networks represent social data combined over two consecutive trapping sessions at four sites (BHP, KCS, PLJ and ROB). Populations were trapped in �primary� sessions every 28 days from March to November, and every 56 days from November to March.
- **Source:** https: //bansallab.github.io/asnr/
- **References:** Davis, Stephen, et al. "Spatial analyses of wildlife contact networks." Journal of the Royal Society Interface 12.102 (2015): 20141004.
- **Load:** `nwwebuse schoch animal_33`

### animal_34: Zebra Groupmembership (weighted)
{: #animal_34 }
- **Network:** `animal_34`: undirected; 27 nodes, 111 edges.
- **Description:** Species: \*Equus grevyi\* Taxonomic class: Mammalia Population type: free-ranging Geographical location: Kenya Data collection technique: survey scan Interaction type: group membership Definition of interaction: A group was defined as a set of one or more individuals that is spatially cohesive and distinct from other groups at the time of observation. Edges were constructed based on half-weight index (HWI). Edge weight type: unweighted Total duration of data collection: 3 months Time resolution of data collection (within a day): Time span of data collection (within a day): focal follow/ad libitum Note:
- **Source:** https: //bansallab.github.io/asnr/
- **References:** Siva R Sundaresan, Ilya R Fischhoff, Jonathan Dushoff, and Daniel I Rubenstein. Network metrics reveal differences in social organization between two fission-fusion species, Grevy's zebra and onager. Oecologia, 151(1): 140-149, 2007.
- **Load:** `nwwebuse schoch animal_34`

### animal_35: Desert Tortoise Asynchronous Burrow Sharing (unweighted)
{: #animal_35 }
- **Networks:** list of 53 networks `animal_35_1` ... `animal_35_53`: undirected; 12-1100 nodes, 5-479 edges.
- **Sizes (element:nodes/edges):** 1:75/7 2:158/188 3:158/17 4:121/184 5:121/53 6:107/105 7:16/7 8:26/35 9:25/35 10:25/27 11:28/38 12:32/14 13:32/8 14:42/20 15:40/16 16:40/6 17:105/30 18:105/12 19:73/10 20:252/67 21:252/13 22:391/64 23:749/12 24:1100/418 25:1100/34 26:897/237 27:897/22 28:750/123 29:750/31 30:908/479 31:908/19 32:640/106 33:640/5 34:144/83 35:22/9 36:20/6 37:17/7 38:51/89 39:51/11 40:44/34 41:24/25 42:22/20 43:21/13 44:40/11 45:18/5 46:20/21 47:24/12 48:23/26 49:23/16 50:32/23 51:27/6 52:12/5 53:15/13
- **Description:** Species: \*Gopherus agassizii\* Taxonomic class: Reptilia Population type: free-ranging Geographical location: Nevada, USA Data collection technique: radio tags Interaction type: social projection bipartite Definition of interaction: A bipartite network was first constructed based on burrow use - an edge connecting a tortoise node to a burrow node indicated burrow use by the individual. Social networks of desert tortoises were then constructed by the bipartite network into a single-mode projection of tortoise nodes. Edge weight type: unweighted Total duration of data collection: 8 months Time resolution of data collection (within a day): Time span of data collection (within a day): focal follow/ad libitum Note: Networks represent social data collected over different years and inactive (November�February)/active (March�October) season.
- **Source:** https: //bansallab.github.io/asnr/
- **References:** Sah, Pratha, et al. "Inferring social structure and its drivers from refuge use in the desert tortoise, a relatively solitary species." Behavioral Ecology and Sociobiology 70.8 (2016): 1277-1289.
- **Load:** `nwwebuse schoch animal_35`

### animal_36: Lizard Proximity (weighted)
{: #animal_36 }
- **Network:** `animal_36`: undirected, valued; 60 nodes, 318 edges.
- **Description:** Species: \*Tiliqua rugosa\* Taxonomic class: Reptilia Population type: free-ranging Geographical location: Kungara, South Australia Data collection technique: logger Interaction type: spatial proximity Definition of interaction: Two lizards were assumed to had made a social contact if they were within 2 m of each other at any of the synchronized 10 min GPS locations. Edge weight type: simple\_ratio\_index Total duration of data collection: 120 days Time resolution of data collection (within a day): 10 minutes Time span of data collection (within a day): 24 hours Note:
- **Source:** https: //bansallab.github.io/asnr/
- **References:** Bull, C. M., S. S. Godfrey, and D. M. Gordon. "Social networks and the spread of Salmonella in a sleepy lizard population." Molecular Ecology 21.17 (2012): 4386-4392.
- **Load:** `nwwebuse schoch animal_36`

### animal_4: Branta leucopsis
{: #animal_4 }
- **Networks:** list of 2 networks `animal_4_1` ... `animal_4_2`: undirected, valued; 20-23 nodes, 190-253 edges.
- **Sizes (element:nodes/edges):** 1:20/190 2:23/253
- **Description:** Species: \*Branta leucopsis\* Taxonomic class: Aves Population type: captive Geographical location: Heteren, Netherlands Data collection technique: survey scan Interaction type: foraging Definition of interaction: Animals grazing on the same patch during a sampling period were assumed to be associating (gambit of the group) Edge weight type: frequency Total duration of data collection: 15 days Time resolution of data collection (within a day): 4min Time span of data collection (within a day): 4 hours Note: Networks represent male and female only network
- **Source:** https: //bansallab.github.io/asnr/
- **References:** Kurvers, Ralf HJM, et al. "Contrasting context dependence of familiarity and kinship in animal social networks." Animal Behaviour 86.5 (2013): 993-1001.
- **Load:** `nwwebuse schoch animal_4`

### animal_5: White Leghorn
{: #animal_5 }
- **Network:** `animal_5`: undirected; 32 nodes, 496 edges.
- **Description:** Species: \*White leghorn\* Taxonomic class: Aves Population type: captive Geographical location: Manhattan, Kansas Data collection technique: mn/unspecified Interaction type: dominance Definition of interaction: Dominance interaction recoded based on agonistic behavior until each bird has established its dominance and/or subordination. Edge weight type: frequency Total duration of data collection: Time resolution of data collection (within a day): Time span of data collection (within a day): Note:
- **Source:** https: //bansallab.github.io/asnr/
- **References:** Guhl, A. M. "Social behavior of the domestic fowl." Transactions of the Kansas Academy of Science (1903-) 71.3 (1968): 379-384.
- **Load:** `nwwebuse schoch animal_5`

### animal_6: Haemorhous mexicanus
{: #animal_6 }
- **Network:** `animal_6`: undirected, valued; 117 nodes, 1027 edges.
- **Description:** Species: \*Haemorhous mexicanus\* Taxonomic class: Aves Population type: free-ranging Geographical location: Virginia Tech, Virginia, USA Data collection technique: RFID Interaction type: social projection bipartite Definition of interaction: A machine learning algorithm was applied to identify clusters of detections on feeders. Next, the network was generated based on patterns of co-occurrence by individuals in the same feeding events. Asociations between birds were defined using the simple ratio index. Edge weight type: simple\_ratio\_index Total duration of data collection: 137 days Time resolution of data collection (within a day): 1 sec Time span of data collection (within a day): 24 hours Note:
- **Source:** https: //bansallab.github.io/asnr/
- **References:** Adelman, James S., et al. "Feeder use predicts both acquisition and transmission of a contagious pathogen in a North American songbird." Proc. R. Soc. B. Vol. 282. No. 1815. The Royal Society, 2015.
- **Load:** `nwwebuse schoch animal_6`

### animal_7: Zonotrichia Atricapilla
{: #animal_7 }
- **Networks:** list of 2 networks `animal_7_1` ... `animal_7_2`: undirected, valued; 31-40 nodes, 211-305 edges.
- **Sizes (element:nodes/edges):** 1:31/211 2:40/305
- **Description:** Species: \*Zonotrichia atricapilla\* Taxonomic class: Aves Population type: free-ranging Geographical location: California, USA Data collection technique: survey scan Interaction type: group membership Definition of interaction: A flock was defined as a group of birds within an approximately 5-metre radius. Social networks of flock comembership was constructed where nodes represent individual birds and edges represent the simple ratio association index Edge weight type: simple\_ratio\_index Total duration of data collection: 3 months Time resolution of data collection (within a day): Time span of data collection (within a day): focal follow/ad libitum Note: Two networks collected over two consecutive years
- **Source:** https: //bansallab.github.io/asnr/
- **References:** Arnberg, Nina N., et al. "Social network structure in wintering golden‐crowned sparrows is not correlated with kinship." Molecular ecology 24.19 (2015): 5034-5044.
- **Load:** `nwwebuse schoch animal_7`

### animal_8: Zonotrichia atricapilla
{: #animal_8 }
- **Networks:** list of 2 networks `animal_8_1` ... `animal_8_2`: undirected, valued (types differ between the networks); 27-46 nodes, 164-348 edges.
- **Sizes (element:nodes/edges):** 1:46/348 2:27/164
- **Description:** Species: \*Zonotrichia atricapilla\* Taxonomic class: Aves Population type: free-ranging Geographical location: California, USA Data collection technique: survey scan Interaction type: group membership Definition of interaction: Flocks were defined as a group of individuals found within a single 5 m radius. For each season, Simple Ratio association index was calculated for each pair of individuals, which ranged from 0 for pairs never seen in the same flock and 1 for pairs always seen in the same flock. Edge weight type: frequency Total duration of data collection: 4 months Time resolution of data collection (within a day): Time span of data collection (within a day): focal follow/ad libitum Note: Networks represent social data collected during two non-breeding seasons: October 2010�February 2011 (Season 2) and October2011�April 2012 (Season 3).
- **Source:** https: //bansallab.github.io/asnr/
- **References:** Shizuka, Daizaburo, et al. "Across‐year social stability shapes network structure in wintering migrant sparrows." Ecology letters 17.8 (2014): 998-1007.
- **Load:** `nwwebuse schoch animal_8`

### animal_9: Acanthiza
{: #animal_9 }
- **Network:** `animal_9`: undirected, valued; 62 nodes, 1151 edges.
- **Description:** Species: \*Acanthiza\* Taxonomic class: Aves Population type: free-ranging Geographical location: Canberra, Australia Data collection technique: survey scan Interaction type: group membership Definition of interaction: Flock membership was identified based on frequent interactions between (such as �beating� for insects) flocks and large gaps between flocks. Association strength of each dyad was calculated using the simple ratio index. Edge weight type: frequency Total duration of data collection: 2 months Time resolution of data collection (within a day): Time span of data collection (within a day): focal follow/ad libitum Note:
- **Source:** https: //bansallab.github.io/asnr/
- **References:** Farine, Damien R., and Peter J. Milburn. "Social organisation of thornbill-dominated mixed-species flocks using social network analysis." Behavioral Ecology and Sociobiology 67.2 (2013): 321-330.
- **Load:** `nwwebuse schoch animal_9`

## Covert networks

### covert_1: 17 November Greece Bombing
{: #covert_1 }
- **Networks:** list of 5 networks `covert_1_1` ... `covert_1_5`: undirected (types differ between the networks); 18-30 nodes, 9-52 edges.
- **Sizes (element:nodes/edges):** 1:18/18 2:18/40 3:18/46 4:30/52 5:18/9
- **Description:** The dataset refers to the 17 November Revolutionary Organisation, a Marxist urban guerrilla organization operating in Greece. The data refers to the specific temporal window which runs from 1975 to 2002. During these years the group has been responsible for several violent acts such as assassinations, kidnappings and symbolic attacks on government offices. The following has been reconstructed: 1) 2-mode matrix, binary, 15x12 persons by events. Ties are participation in terrorist events 2) 1-mode stacked matrices 18x18 persons by persons, binary Kinship 1975-1984 1985-1994 1995-2002 The original file presents a distinction among several types of relationships: 1. Acquaintances/Distant family ties (interactions limited to radical organisation activities), 2. Friends/Moderately close family ties (interactions extend beyond radical organisations to include such categories as co-workers and roommates). Operational/Organisational leadership (i.e. JI leadership, formally or informally ranking members of burgeoning cells).Operational Ties (i.e. worked closely on a bombing together). 3. Close Friends/Family, Tight-knit operational cliques (would die for each other) If one of these three types of relationships was present, it has been coded with 1. }
- **Source:** Reconstructed at Manchester (https://sites.google.com/site/ucinetsoftware/datasets/covert-networks). Freely available from http://doitapps.jjay.cuny.edu/jjatt/data.php
- **Load:** `nwwebuse schoch covert_1`

### covert_10: Caviar
{: #covert_10 }
- **Networks:** list of 12 networks `covert_10_1` ... `covert_10_12`: undirected, valued; 15-110 nodes, 18-205 edges.
- **Sizes (element:nodes/edges):** 1:110/205 2:15/18 3:42/50 4:41/50 5:24/28 6:33/56 7:33/48 8:32/39 9:27/47 10:34/44 11:42/58 12:34/44
- **Description:** Project Caviar was a unique investigation that targeted a network of hashish and cocaine importers operating out of Montreal. The network was targeted between 1994 and 1996 by a tandem investigation uniting the Montreal Police, the Royal Canadian Mounted Police, and other national and regional law-enforcement agencies from various countries (i.e., England, Spain, Italy, Brazil, Paraguay, and Colombia). The case is unique because it involved a specific investigative approach that will be referred to as a “seize and wait” strategy. Unlike most law-enforcement strategies, the mandate set forward in the Project Caviar case was to seize identified drug consignments, but not to arrest any of the identified participants. This took place over a 2-year period. Thus, although 11 importation consignments were seized at different moments throughout this period, arrests only took place at the end of the investigation. What this case offers is a rare opportunity to study the evolution of a criminal network phenomenon as it was being disrupted by law-enforcement agents. The inherent investigative strategy permits an assessment of change in the network structure and an inside look into how network participants react and adapt to the growing constraints set upon them. The principal data source was comprised of information submitted as evidence during the trials of 22 participants in the Caviar network. It included 4,279 paragraphs of information (over 1,000 pages) revealing electronically intercepted telephone conversations between network participants. These transcripts were used to create the overall matrix of the drug-trafficking operation’s communication system throughout the course of the investigation. Individuals falling in the surveillance net were not all participants in the trafficking operation. An initial extraction of all names appearing in the surveillance data led to the identification of 318 individuals. From this pool, 208 individuals were not implicated in the trafficking operations. Most were simply named during the many transcripts of conversations, but never detected. Others who were detected had no clear participatory role within the network (e.g., family members or legitimate entrepreneurs). The final network was thus composed of 110 participants. NETWORK 11 1-mode matrices person by person, representing the 11 phases of the investigation. Ties are directed and valued. Number of nodes = 1) 15x15, 2) 24x24, 3) 33x33, 4) 33x33, 5) 32x32, 6) 27x27, 7) 34x34, 8) 42x42, 9) 34x34, 10) 42x42, 11) 41x41 1-mode matrix 110 x 110 person by person of the complete network. Ties are communication exchanges between criminals. Values represent level of communication activity. Data comes from police wiretapping.
- **Source:** Available from Manchester (https://sites.google.com/site/ucinetsoftware/datasets/covert-networks), reconstructed from Morselli’s book, Inside Criminal Networks http://www.springer.com/social+sciences/criminology/book/978-0-387-09525-7 Book pages from 173 to 186, Appendix
- **References:** Morselli, C., 2009. Inside criminal networks. New York: Springer.
- **Load:** `nwwebuse schoch covert_10`

### covert_11: Christmas Eve Bombings Indonesia 2000
{: #covert_11 }
- **Networks:** list of 14 networks `covert_11_1` ... `covert_11_14`: undirected, valued (types differ between the networks); 45-45 nodes, 2-233 edges.
- **Sizes (element:nodes/edges):** 1:45/23 2:45/98 3:45/146 4:45/233 5:45/187 6:45/102 7:45/46 8:45/7 9:45/7 10:45/8 11:45/2 12:45/229 13:45/3 14:45/3
- **Description:** This is a time series that treat specific attacks as endpoints and depict the evolution of relations between individuals indirectly and directly associated with the 2000 Christmas Eve bombing.  http://en.wikipedia.org/wiki/Christmas\_Eve\_2000\_Indonesia\_bombings 1-mode stacked matrices 27 x 27 person by person. Data for 11 time periods plus kinship data. Undirected, valued ties. Tie value codes for kinship matrix: 0 = No Kinship // 1 = In-laws // 2 = Cousins // 3 = Sibling // 4 = Parent/Child // 5 = Married // 6 = Grandparent/Child // 7 = Significant Other Tie value codes for time series matrices: 0 = No relation // 1 = Acquaintances/distant family ties (interaction limited to radical organisation activities) // 2 = Friends/Moderately close family (inc co-workers/ roommates) Operational/Org leadership/Operational lies (e.g. worked closely on a bombing together) // 3 = Close friends/family, tight-knit operational cliques
- **Source:** Available from Manchester (https://sites.google.com/site/ucinetsoftware/datasets/covert-networks) or here http://doitapps.jjay.cuny.edu/jjatt/data.php
- **Load:** `nwwebuse schoch covert_11`

### covert_12: CielNet
{: #covert_12 }
- **Network:** `covert_12`: undirected, valued; 25 nodes, 35 edges.
- **Description:** Project Ciel is based on a small drug-importation network that was importing liquid hashish from Jamaica to Montreal. This network was targeted by the Royal Canadian Mounted Police and the Montreal Police from May 1996 to June 1997. Typical of many Canadian investigations of drug smuggling and trafficking, the operations in Project Ciel were described as taking place within a tightly governed organizational framework—a hierarchy, in short. Reports from the investigation maintained that the main target of the investigation was the “organizational leader.” Other key targets included the leader’s “lieutenant” and a series of other subordinates. The investigation produced three separate seizures, with two taking place at Mirabel airport near Montreal and another occurring at Sangster airport in Jamaica. Overall, 75 people fell into the surveillance net. A selection process that was aimed at identifying only those individuals who were active in the drug-importation operations resulted in a final network of 25 participants. NETWORK 1-mode matrix 25 x 25 person by person. Ties are communication exchanges between criminals. Ties are directed and valued. Higher values represent more active communication channels. Data comes from police wiretapping.
- **Source:** Available from Manchester (https://sites.google.com/site/ucinetsoftware/datasets/covert-networks). Reconstructed from Morselli’s book, Inside Criminal Networks http://www.springer.com/social+sciences/criminology/book/978-0-387-09525-7 book page 172, Appendix.
- **References:** Morselli, C., 2009. Inside criminal networks. New York: Springer.
- **Load:** `nwwebuse schoch covert_12`

### covert_13: Cocaine Dealing Natarajan
{: #covert_13 }
- **Network:** `covert_13`: undirected, valued; 28 nodes, 40 edges.
- **Description:** This dataset comes from an investigation into to a large cocaine trafficking organization in New York City. 1-mode matrix 28 x 28 persons by persons. Directed valued relations are communications exchanges / flows of information. Data come from police wiretappings (transcripts of 151 telephone conversations).
- **Source:** Available from Manchester (https://sites.google.com/site/ucinetsoftware/datasets/covert-networks). Reconstructed from Natarajan, M. "Understanding the structure of a drug trafficking organization: a conversational analysis." Crime Prevention Studies 11 (2000): 273-298.
- **References:** Natarajan, M. "Understanding the structure of a drug trafficking organization: a conversational analysis." Crime Prevention Studies 11 (2000): 273-298.
- **Load:** `nwwebuse schoch covert_13`

### covert_14: Cocaine Smuggling
{: #covert_14 }
- **Network:** `covert_14`: undirected, valued; 28 nodes, 40 edges.
- **Description:** Data refers to four groups involved in cocaine trafficking in Spain. Information comes from police wiretapping and meetings registered by police investigations of these criminal organisations between 2007 and 2009. Operation MAMBO (N=22). The investigation started in 2006 and involved Colombian citizens that were introducing 50 kg of cocaine to be adulterated and distributed in Madrid (Spain). Ultimately, the group was involved in smuggling cocaine from Colombia through Brazil and Uruguay to be distributed in Spain. This is a typical Spanish middle cocaine group acting as wholesale supplier between a South American importer group and retailers in Madrid. Operation JUANES (N=51). In 2009, the police investigation detected a group involved in the smuggling of cocaine from Mexico to be distributed in Madrid (Spain). In this case, the group operated in close cooperation with another organization that was laundering the illegal income from drug distribution from this and other groups. The cocaine traffickers earned an estimated EUR 60 million. Operation JAKE (N=62). In 2008, the group investigated was operating as a wholesale supplier and retail distributor of cocaine and heroin in a large distribution zone located in Madrid (Spain), where gypsy clans traditionally carry out similar activities. The group was in charge of acquiring, manipulating and selling the drugs in the gypsy quarter. Operation ACERO (N=11). This investigation started in 2007 and involved a smaller family-based group. The group was composed mainly of members of a same family and was led by a female. They distributed cocaine in Madrid (Spain) that was provided to them by other groups based in a northwest region of the country, one of the most active areas in the provision of cocaine from the countries of origin. The group also had their own procedures to launder money. 4 1-mode matrices person by person from each of the operations described above. Undirected, valued ties. Mambo: 31x31 Juanes:51x51 Jake: 38x38 Acero: 25x25 Relations are communications between individuals. Meaning of tie values is unclear - may represent level of communications activity.
- **Source:** Available at Manchester (https://sites.google.com/site/ucinetsoftware/datasets/covert-networks). Reconstructed from Jimenez-Salinas Framis, A. "Illegal networks or criminal organizations: Power, roles and facilitators in four cocaine trafficking structures." In Third Annual Illicit Networks Workshop, Montreal. 2011
- **References:** Jimenez-Salinas Framis, A. "Illegal networks or criminal organizations: Power, roles and facilitators in four cocaine trafficking structures." In \*Third Annual Illicit Networks Workshop\*, Montreal. 2011.
- **Load:** `nwwebuse schoch covert_14`

### covert_15: Czech Corruption
{: #covert_15 }
- **Network:** `covert_15`: undirected, valued; 16 nodes, 50 edges.
- **Description:** The data comes from a Czech media database called Newton Media Search and involves all major Czech newspapers for the period from 4th June 2013 to 4th June 2014. Actors are: Jana Nagyová, Petr Nečas – former prime minister and his office chief and love affair. Ivan Fuksa, Petr Tluchoř, Marek Šnajdr – deputies of ODS (conservative governing party at that time) Ondrej Páleník, Roman Boček, Jan Pohůnek, Milan Kovanda, Lubomír Poul, Libor Grygárek – high government officials and espionage agents Ivo Rittig, Roman Janoušek, Václav Ryba, Tomáš Hrdlička, Jiří Toman – eminences gris, "godfathers" DATA FORMATS: UCINET, .csv 1-mode matrix 16 x 16 person by person. The ties are co-appearances – every time an actor was mentioned in one article together with any other actor, it is considered to be a tie. Ties are valued on am 11 point scale, where 10 is the strongest tie (Nagyova – Necas). All other ties were transformed by dividing the total number of co-appearances between the two actors by the value of the strongest tie, which gave the percent of the maximal tie. This percentage was then assigned an integer value from range 0 - 9 according to which tenth of percents this particular value falls into. Example: The Fuksa - Nagyova tie reaching 50% of the strongest tie value was assigned a value of 5. The Nagyova - Ryba tie reaching 3% of the max value was assigned zero etc.
- **Source:** Data from Tomas Diviák, Available from Manchester (https://sites.google.com/site/ucinetsoftware/datasets/covert-networks).
- **Load:** `nwwebuse schoch covert_15`

### covert_16: Domestic Terrorist Web Links
{: #covert_16 }
- **Network:** `covert_16`: undirected, loops; 32 nodes, 50 edges.
- **Description:** Network of hyperlinks between domestic terrorist group websites in the United States. DATA FORMATS: UCINET, .csv 1-mode matrix 32 x 32 website by website Directed binary ties are based on analysis of hyperlinks between sites.
- **Source:** Available from Manchester (https://sites.google.com/site/ucinetsoftware/datasets/covert-networks)
- **References:** Zhou et al. (2005), ‘US domestic extremist groups on the web: link and content analysis’, available at http://ieeexplore.ieee.org/xpl/login.jsp?tp=&arnumber=1511999&url=http%3A%2F%2Fieeexplore.ieee.org%2Fxpls%2Fabs\_all.jsp%3Farnumber%3D1511999
- **Load:** `nwwebuse schoch covert_16`

### covert_17: Drugnet
{: #covert_17 }
- **Network:** `covert_17`: undirected; 293 nodes, 284 edges.
- **Description:** This is a dichotomous adjacency matrix of drug users in Hartford. Ties are directed and represent acquaintanceship. The network is a result of two years of ethnographic observations of people's drug habits. NETWORK 1-mode matrix 293x293 person by person, directed ties. Relations are acquaintanceship. Attribute dataset includes ethnicity, gender. Ethnicity codes: 2 = African American; 3 = Puerto Rican/Latino; 1, 5, 6, 7 = white or other Gender codes: 1 = male; 2 = female; 0 = unknown
- **Source:** https://sites.google.com/site/sfeverton18/research/cohesion-and-clustering
- **References:** WEEKS, M. R., CLAIR, S., BORGATTI, S. P., RADDA, K. & SCHENSUL, J. J. 2002. Social networks of drug users in high-risk sites: Finding the connections. AIDS and Behaviour, 6, 193-206.
- **Load:** `nwwebuse schoch covert_17`

### covert_18: FIFA
{: #covert_18 }
- **Networks:** list of 2 networks `covert_18_1` ... `covert_18_2`: undirected, valued; 340-450 nodes, 3328-5022 edges.
- **Sizes (element:nodes/edges):** 1:340/3328 2:450/5022
- **Description:** Two Networks of Standing Committee membership. These are overt networks with covert elements. 2-Mode persons to Standing Committees (converted to 1-Mode) 340 x 340 persons by persons undirected binary 450 x 450 persons by persons undirected binary
- **Source:** Available from Manchester (https://sites.google.com/site/ucinetsoftware/datasets/covert-networks). Reconstructed by Gemma Edwards from Select Committee 2006 activity report.
- **Load:** `nwwebuse schoch covert_18`

### covert_19: Global Suicide Attacks
{: #covert_19 }
- **Networks:** list of 17 networks `covert_19_1` ... `covert_19_17`: undirected, loops (types differ between the networks); 4-31 nodes, 3-44 edges.
- **Sizes (element:nodes/edges):** 1:10/17 2:4/6 3:4/4 4:4/3 5:4/4 6:9/7 7:6/5 8:4/3 9:10/9 10:7/6 11:10/10 12:15/19 13:11/13 14:21/25 15:25/41 16:27/42 17:31/44
- **Description:** Data is on militant organizations between 1985 and 2006. Each node signifies a militant organization or other type of entity that conducts suicide attacks. 1-mode matrix for each year, organization by organization. Undirected, binary ties represent a known physical relationship between agents from different but “connected” organizations. 1985 10 x 10 1986 4 x 4 1990 4 x 4 1993 4 x 4 1994 4 x 4 1995 9 x 9 1996 6 x6 1997 4 x 4 1998 10 x 10 1999 7 x 7 2000 10 x 10 2001 15 x 15 2002 11 x 11 2003 21 x 21 2004 25 x 25 2005 27 x 27 2006 31 x 31 }
- **Source:** Available from Manchester (https://sites.google.com/site/ucinetsoftware/datasets/covert-networks). Reconstructed from Benjamin Acosta & Steven J. Childs (2013) ‘Illuminating the Global Suicide-Attack Network’, Studies in Conflict & Terrorism, 36:1, 49-76
- **References:** Benjamin Acosta & Steven J. Childs (2013) ‘Illuminating the Global Suicide-Attack Network’, \*Studies in Conflict & Terrorism\*, 36:1, 49-76
- **Load:** `nwwebuse schoch covert_19`

### covert_2: 9/11 Hijackers
{: #covert_2 }
- **Networks:** list of 2 networks `covert_2_1` ... `covert_2_2`: undirected, loops (types differ between the networks); 19-60 nodes, 27-126 edges.
- **Sizes (element:nodes/edges):** 1:60/126 2:19/27
- **Description:** Famous dataset of the terrorists involved in the 9/11 bombing of the World Trade Centres in 2011. Data was extracted from news reports and ties range from ‘at school with’ to ‘on same plane’. 1-mode matrix 19 x 19 person by person of trusted prior contacts and 1-mode matrix 61 x 61 of other associates. Ties are undirected and binary. Relations are a mix of prior-contacts like trained together, lived together, financial transactions, at school with, on same flight.
- **Source:** Reconstructed at Manchester (https://sites.google.com/site/ucinetsoftware/datasets/covert-networks). http://orgnet.com/tnet.html http://firstmonday.org/ojs/index.php/fm/article/view/941/863#fig4
- **References:** Krebs, Valdis E. "Mapping networks of terrorist cells." \*Connections\* 24.3 (2002): 43-52.
- **Load:** `nwwebuse schoch covert_2`

### covert_20: Hamburg Cell 9/11 2001
{: #covert_20 }
- **Networks:** list of 23 networks `covert_20_1` ... `covert_20_23`: undirected, valued; 34-34 nodes, 4-122 edges.
- **Sizes (element:nodes/edges):** 1:34/7 2:34/14 3:34/24 4:34/42 5:34/66 6:34/89 7:34/79 8:34/65 9:34/57 10:34/57 11:34/54 12:34/11 13:34/11 14:34/5 15:34/5 16:34/5 17:34/5 18:34/4 19:34/5 20:34/5 21:34/5 22:34/122 23:34/122
- **Description:** This is a time series that treat specific attacks as endpoints and depict the evolution of relations between individuals indirectly and directly associated with the sleeper Al Qaeda cell in Hamburg around the time of the 9/11 bombings. http://en.wikipedia.org/wiki/Hamburg\_cell 1-mode stacked matrices 35 x 35 person by person, data for 11 time points. Ties are undirected and valued. Tie codes: 0 = No relation // 1 = Acquaintances/distant family ties (interaction limited to radical organisation activities) // 2 = Friends/Moderately close family (inc co-workers/ roommates) Operational/Org leadership/Operational lies (e.g. worked closely on a bombing together) // 3 = Close friends/family, tight-knit operational cliques.
- **Source:** Available from Manchester (https://sites.google.com/site/ucinetsoftware/datasets/covert-networks) or here http://doitapps.jjay.cuny.edu/jjatt/data.php
- **Load:** `nwwebuse schoch covert_20`

### covert_21: Heroin Dealing Natarajan
{: #covert_21 }
- **Network:** `covert_21`: undirected; 38 nodes, 87 edges.
- **Description:** This dataset comes from an investigation into a large heroin trafficking organization in New York City in the 1990s. 1-mode matrix 38x38 person by person. Directed binary relations are communications exchanges / flows of information. Data come from police wiretappings (transcripts of 151 telephone conversations).
- **Source:** Available from Manchester (https://sites.google.com/site/ucinetsoftware/datasets/covert-networks). Reconstructed from Natarajan, M. (2006). Understanding the Structure of a Large Heroin Distribution Network: A Quantitative Analysis of Qualitative Data. Quantitative Journal of Criminology, 22(2), 171-192.
- **References:** Available from Manchester (https://sites.google.com/site/ucinetsoftware/datasets/covert-networks). Reconstructed from Natarajan, M. (2006). Understanding the Structure of a Large Heroin Distribution Network: A Quantitative Analysis of Qualitative Data. Quantitative Journal of Criminology, 22(2), 171-192.
- **Load:** `nwwebuse schoch covert_21`

### covert_22: Islamic State Allegiances
{: #covert_22 }
- **Network:** `covert_22`: two-mode; 67 nodes, 47 edges (modes: 47 + 20).
- **Description:** 2-mode dataset describing groups allied to Islamic State and the countries in which they are operating 2-mode matrix 47 x 20 organizations by state, undirected binary ties.
- **Source:** Available from Manchester (https://sites.google.com/site/ucinetsoftware/datasets/covert-networks)
- **Load:** `nwwebuse schoch covert_22`

### covert_23: Islamic State Group
{: #covert_23 }
- **Networks:** list of 3 networks `covert_23_1` ... `covert_23_3`: undirected; 56-56 nodes, 6-15 edges.
- **Sizes (element:nodes/edges):** 1:56/12 2:56/6 3:56/15
- **Description:** The data describes relationships between members of the Islamic State supplied to the BBC by IS investigation team. 1-mode matrices 56 x 56 persons by persons undirected binary ties. The data includes three matrices with three types of relationships: Links (relationship definition unknown) Components & friends (former companion, close, friends, close coordination, most important companion, close relationship) Kinship (brothers, brothers working together, young brother, brother, married to sister, son)
- **Source:** Available from Manchester (https://sites.google.com/site/ucinetsoftware/datasets/covert-networks). Reconstructed from http://www.bbc.co.uk/news/world-middle-east-29052475
- **Load:** `nwwebuse schoch covert_23`

### covert_24: Italian Gangs
{: #covert_24 }
- **Network:** `covert_24`: undirected; 67 nodes, 114 edges.
- **Description:** Describes Italian gang members and their nationalities. No further contextual data available. 1-Mode matrix 67x67 person by person, relations are co-membership of gangs. Attribute data is gang member’s country of origin, coded numerically. No codebook available.
- **Source:** Available from Manchester (https://sites.google.com/site/ucinetsoftware/datasets/covert-networks)
- **Load:** `nwwebuse schoch covert_24`

### covert_25: Jakarta Bombing 2009 / Noordin Top
{: #covert_25 }
- **Networks:** list of 4 networks `covert_25_1` ... `covert_25_4`: undirected, valued; 28-28 nodes, 13-38 edges.
- **Sizes (element:nodes/edges):** 1:28/34 2:28/38 3:28/13 4:28/38
- **Description:** This is a time series that treat specific attacks as endpoints and depict the evolution of relations between individuals indirectly and directly associated with the 2009 Jakarta bombing. http://en.wikipedia.org/wiki/2009\_Jakarta\_bombings This network draws on the same terrorist activities as the Noordin Top network. 1-mode stacked matrices, 28 x 28 person by person, data for kinship, pre-attack and post-attack. Ties undirected and valued. Codebook available here http://doitapps.jjay.cuny.edu/jjatt/files/Relations\_Codebook\_Public\_Version2.pdf
- **Source:** Available from Manchester (https://sites.google.com/site/ucinetsoftware/datasets/covert-networks) or here http://doitapps.jjay.cuny.edu/jjatt/data.php
- **Load:** `nwwebuse schoch covert_25`

### covert_26: Jemaah Islamiyah Koschade
{: #covert_26 }
- **Network:** `covert_26`: undirected, valued; 17 nodes, 63 edges.
- **Description:** Jemaah Islamiyah cell that was responsible for the Bali bombings in 2002 – i.e. should tally with the other Bali bombing dataset from JJATT. The recording of the interaction of the cell began following the  meeting in the Hotel Harem in Denpasar on October 6, when the group was considered to go ‘operationally covert’, and concluded when the majority of the group had left Bali before the implementation of the operation on October 11, 2002. 1-mode matrix 17 x 17 person by person, undirected and valued. Relationships between terrorists concern who exchanged information with whom (communications exchanges). The valued relations represent the strength of the relations between the individuals, with a score of one signifying the weakest relationship such as a single text message or a financial transaction, and five signifying the strongest relationship such as individuals who resided together, or individuals who had numerous weak contacts over the period in question.
- **Source:** Dataset comes from the publication Koschade, Stuart (2006) A Social Network Analysis of Jemaah Islamiyah: The Applications to Counter-Terrorism and Intelligence. Studies in Conflict and Terrorism Vol. 29(6):pp. 559-575 This data has been reconstructed by Koschade by using the report provided by the international crisis group which collected depositions of JI suspects, court documents, and others Indonesian press reports. (INTERNATIONAL CRISIS GROUP. 2003 ‘Jemaah Islamiyah in South East Asia: Damaged but Still Dangerous’).
- **Load:** `nwwebuse schoch covert_26`

### covert_27: Linux Terrorists
{: #covert_27 }
- **Networks:** list of 2 networks `covert_27_1` ... `covert_27_2`: undirected; 260-645 nodes, 571-3172 edges.
- **Sizes (element:nodes/edges):** 1:260/571 2:645/3172
- **Description:** These are two datasets about a set of terrorists and the attacks they carry out collected by the MIND Lab at University of Maryland (UMD) (http://www.mindswap.org/). NETWORK 1-mode matrix 645 x 645 organization by organization, directed ties. Ties are co-location of terrorist attacks. 1-mode matrix 260 x 260 organization by organization, directed ties. Ties are co-located terrorist attacks by same organisation.
- **Source:** Available from Manchester (https://sites.google.com/site/ucinetsoftware/datasets/covert-networks).
- **Load:** `nwwebuse schoch covert_27`

### covert_28: London Gang
{: #covert_28 }
- **Network:** `covert_28`: undirected, valued; 54 nodes, 315 edges.
- **Description:** Data is on co-offending in a London-based inner-city street gang, 2005-2009, operating from a social housing estate. Data comes from anonymised police arrest and conviction data for ‘all confirmed’ members of the gang. 1-Mode matrix 54 x 54 persons by persons, undirected, valued. Network tie values: = 1 (hang out together) = 2 (co-offend together) = 3 (co-offend together, serious crime) = 4 (co-offend together, serious crime, kin) } Attributes: Age, Birthplace (1 = West Africa, 2= Caribbean, 3= UK, 4= East Africa), Residence, Arrests, Convictions, Prison, Music.
- **Source:** Available from Manchester (https://sites.google.com/site/ucinetsoftware/datasets/covert-networks).
- **References:** Grund, T. and Densley, J. (2015) Ethnic Homophily and Triad Closure: Mapping Internal Gang Structure Using Exponential Random Graph Models. Journal of Contemporary Criminal Justice, Vol. 31, Issue 3, pp. 354-370 Grund, T. and Densley, J. (2012) Ethnic Heterogeneity in the Activity and Structure of a Black Street Gang. European Journal of Criminology, Vol. 9, Issue 3, pp. 388-406.
- **Load:** `nwwebuse schoch covert_28`

### covert_29: Madoff Fraud
{: #covert_29 }
- **Network:** `covert_29`: undirected, loops; 61 nodes, 61 edges.
- **Description:** Bernie Madoff was involved in a massive financial fraud in the USA and was sentenced to 150 years in prison (http://en.wikipedia.org/wiki/Bernard\_Madoff). The network is finance flows between financial institutions and Madoff’s firm. All data for this network was gathered from news stories and court documents found on major media web sites. Read more about the social network underpinnings of this scheme in The Network Thinkers blog post (http://www.thenetworkthinkers.com/2009/02/madoff-feeder-funds.html) 1-mode directed network 61 x 61 firm by firm, showing money flows between banks and other organizations, leading ultimately to Madoff’s firm. Relations are money flows. Arrows show direction of money flow.
- **Source:** Freely available, to be reconstructed by Manchester http://orgnet.com/Madoff9.png
- **Load:** `nwwebuse schoch covert_29`

### covert_3: Al Qaeda 1993-2003
{: #covert_3 }
- **Networks:** list of 33 networks `covert_3_1` ... `covert_3_33`: undirected; 271-271 nodes, 1-109 edges.
- **Sizes (element:nodes/edges):** 1:271/4 2:271/2 3:271/3 4:271/4 5:271/1 6:271/2 7:271/1 8:271/19 9:271/17 10:271/1 11:271/66 12:271/14 13:271/47 14:271/38 15:271/1 16:271/26 17:271/26 18:271/16 19:271/2 20:271/32 21:271/14 22:271/27 23:271/13 24:271/1 25:271/109 26:271/77 27:271/99 28:271/10 29:271/6 30:271/38 31:271/1 32:271/44 33:271/16
- **Description:** The Al Qaeda Operations Attack Series is data that pools the relations of individuals associated with over 10 attacks and individually depicts them for each event. It is not a time series but instead an aggregate attack series best perceived as the variously composed attack teams deployed by Al Qaeda over a decade. 1-mode stacked matrices 272 x 272 person by person, each matrix represents an attack. Undirected ties. Relations are co-participation in an attack. 1-mode stacked matrices 272 x 272 person by person. Undirected ties. Relations are kinship relations. Matrices coded as follows: 0 = No Kinship // 1 = In-laws // 2 = Cousins // 3 = Sibling // 4 = Parent/Child // 5 = Married
- **Source:** Available from Manchester (https://sites.google.com/site/ucinetsoftware/datasets/covert-networks) or http://doitapps.jjay.cuny.edu/jjatt/data.php
- **Load:** `nwwebuse schoch covert_3`

### covert_30: Madrid Train Bombing 2004
{: #covert_30 }
- **Networks:** list of 25 networks `covert_30_1` ... `covert_30_25`: undirected, valued (types differ between the networks); 54-54 nodes, 0-226 edges.
- **Sizes (element:nodes/edges):** 1:54/4 2:54/4 3:54/6 4:54/9 5:54/9 6:54/9 7:54/14 8:54/16 9:54/17 10:54/19 11:54/23 12:54/23 13:54/51 14:54/55 15:54/120 16:54/183 17:54/8 18:54/3 19:54/0 20:54/0 21:54/0 22:54/124 23:54/226 24:54/226 25:54/226
- **Description:** This is a time series that treat specific attacks as endpoints and depict the evolution of relations between individuals indirectly and directly associated with the Madrid train bombing. http://en.wikipedia.org/wiki/2004\_Madrid\_train\_bombings 1-mode stacked matrices 55 x 55 person by person, data on 20 time periods plus kinship data and tie extinguished data. Codebook available here http://doitapps.jjay.cuny.edu/jjatt/files/Relations\_Codebook\_Public\_Version2.pdf
- **Source:** Available from Manchester (https://sites.google.com/site/ucinetsoftware/datasets/covert-networks) or here http://doitapps.jjay.cuny.edu/jjatt/data.php
- **Load:** `nwwebuse schoch covert_30`

### covert_31: Mali Terrorist Network
{: #covert_31 }
- **Network:** `covert_31`: undirected; 36 nodes, 67 edges.
- **Description:** Data refers to a terrorist network operating in the Sahel Sahel-Sahara region and describes relationships between Islamists and Tuareg rebels during the Malian conflict. Data comes from a selection of newspaper articles published between 2010 and 2012. “Using social network analysis, our first aim is to illuminate the relationships between the Islamists and the rebels involved in the current Malian conflict. We use a selection of newspaper articles to demonstrate that the connection between Islamists and rebels depends on brokers who passed from the Tuareg rebellion to radical groups. Our second objective is to detail the internal relationships within each of the subgroups. Our findings show how Islamists were affected by the accidental disappearance of one the AQMI regional emirs and how the death of one of the architects of the Tuareg rebellion affected rebel cohesion.” Walther et al., INSNA Sunbelt Conference 2013 1-mode matrix 36x36 person by person Relations derived from interactions, including participation in political or military event, political meetings; trainings in Afghanistan, Iraq, or Libya; combats; negotiations for hostage releases; or involvements with a killing, an abduction, or a bombing.
- **Source:** The dataset has been reconstructed from the following publication: Walther, Olivier J., and Dimitris Christopoulos (2015), "Islamic terrorism and the Malian rebellion." Terrorism and Political Violence, 27 (3), 497-519.
- **References:** Walther, Olivier J., and Dimitris Christopoulos (2015), "Islamic terrorism and the Malian rebellion." \*Terrorism and Political Violence\*, 27 (3), 497-519.
- **Load:** `nwwebuse schoch covert_31`

### covert_32: Montreal Street Gangs
{: #covert_32 }
- **Network:** `covert_32`: undirected; 35 nodes, 78 edges.
- **Description:** Data obtained from the Montreal Police’s central intelligence base, the Automated Criminal Intelligence Information System (ACIIS), was used to reconstruct the organization of drug-distribution operations in Montreal North. These operations were targeted during three separate investigations between 2004 and 2007 by the Montreal Police, who believed that the criminal activities were under the control of one of the more reputed gangs in Montreal—the Bo-Gars (or Handsome Boys, in English). Because the trials extending from two of the investigations were still ongoing at the time of analysis, their names remain confidential and I simply refer to Investigations A, B, and C. Investigation A began in February 2004 and ended in April 2005, with the arrests of 27 individuals who were accused primarily of importing and distributing crack and cocaine in a Montreal North neighborhood. Investigation A was the largest of the three investigations under study and it was the only case to offer electronic surveillance information amongst the available data sources. Investigations B and C, which were direct extensions of observations made during Investigation A, both began during the fall of 2006 and ended in June 2007, with the arrests of 24 individuals who were targeted in Investigation B and 11 individuals targeted in Investigation C. Investigation B concentrated on street dealers of marijuana and crack, while Investigation C focused specifically on the activities of a group of wholesalers who were supplying some of the dealers targeted in Investigation B. Overall, 101 individuals were monitored during the investigations—45 in Investigation A, 30 in Investigation B, and 26 in Investigation C. This list of 101 individuals was used as a starting point to reconstruct the final network. This final network was comprised of 70 participants and was based on information obtained from three data sources. NETWORK 1-mode matrix 35 x 35 organization by organization (Gangs in Montreal). Undirected ties, binary (original network is directed). Ties are relationships between gangs (as reported in focus groups/interviews with gang members). Attribute data: -- Gang affiliation: 1) Bloods, 2) Crips, or 3) Other -- Gang Ethnicity: 1) Hispanic, 2) Afro-Canadian, 3) Caucasian, 4) Asian, 5) No main association/mixed. -- Territory data: 1) Downtown 2) East 3) West -- Missing data coded as 99 }
- **Source:** The data has been reconstructed from the following article: Karine Descormiers and Carlo Morselli (2011) 'Alliances, Conflicts, and Contradictions in Montreal's Street Gang Landscape' International Criminal Justice Review, Vol. 1 No. 3, pp. 297-314
- **References:** Karine Descormiers and Carlo Morselli (2011) 'Alliances, Conflicts, and Contradictions in Montreal's Street Gang Landscape' International Criminal Justice Review, Vol. 1 No. 3, pp. 297-314
- **Load:** `nwwebuse schoch covert_32`

### covert_33: Ndrangheta Mafia 2
{: #covert_33 }
- **Network:** `covert_33`: two-mode; 203 nodes, 455 edges (modes: 156 + 47).
- **Description:** Data is on attendance of suspected members of the Ndrangheta criminal organization at summits (meetings whose purpose is to make important decisions and/or affiliations, but also to solve internal problems and to establish roles and powers) taking place between 2007 and 2009. 2-mode matrix 156 x 47 persons by events (summits), undirected binary ties. Attendance at events have been registered by police authorities through wiretapping and observations during the large investigation called "Operazione Infinito".
- **Source:** The data has been reconstructed by the document "ORDINANZA DI APPLICAZIONE DI MISURA COERCITIVA con mandato di cattura - art. 292 c.p.p. -" which is available online at the following address http://www.stampoantimafioso.it/documentazione-antimafia/ordinanze/. Stampo Antimafioso is a project which aims to share information about the Mafia operating in Northem Italy. The dataset has been reconstructed by mostly referring to pp.87-110 of the document named "Operazione Infinito". This report is a judicial document concerning the pre-trial detention order triggered by the the preliminary investigation judge (Giudice per le indagini preliminari) of Milan. With this judicial act, measures of custody and pretrial detention have been ordered for the reported suspected of 'Ndrangheta affiliation.
- **Load:** `nwwebuse schoch covert_33`

### covert_34: Noordin Top
{: #covert_34 }
- **Networks:** list of 10 networks `covert_34_1` ... `covert_34_10`: undirected; 79-79 nodes, 11-267 edges.
- **Sizes (element:nodes/edges):** 1:79/15 2:79/175 3:79/200 4:79/91 5:79/16 6:79/29 7:79/63 8:79/267 9:79/11 10:79/147
- **Description:** These data were drawn primarily from "Terrorism in Indonesia: Noordin's Networks," a publication of the International Crisis Group (2006) and include relational data on the 79 individuals listed in Appendix C of that publication. The data were initially coded by Naval Postgraduate School students as part of the course “Tracking and Disrupting Dark Networks” under the direction of Professor Sean Everton, Co-Director of the CORE Lab, and Professor Nancy Roberts. CORE Lab Research Assistant Daniel Cunningham reviewed and cleaned all coding made by students. NETWORK 1-mode stacked matrix 79 x 79 person by person. Ties are undirected. Ties include classmates; friendship; soulmates; co-location of logistical activity; co-attendance at meetings; co-participation in operations; co-attendance at training events; communications; business & financial ties. Codebook available here http://www.thearda.com/archive/files/codebooks/origCB/Noordin%20Subset%20Codebook.pdf
- **Source:** Data is available in its original format from Manchester (https://sites.google.com/site/ucinetsoftware/datasets/covert-networks).
- **References:** Roberts, Nancy and Sean F. Everton. 2011. Roberts and Everton Terrorist Data: Noordin Top Terrorist Network (Subset). For a detailed analysis of Noordin top network see: Everton, S. F. (2012) Disrupting dark networks: Cambridge University Press. For a detailed explanation of matrices and the kind of relationship considered see the appendix of the book.
- **Load:** `nwwebuse schoch covert_34`

### covert_35: Paul Revere
{: #covert_35 }
- **Networks:** list of 2 networks `covert_35_1` ... `covert_35_2`: undirected, valued (types differ between the networks); 254-261 nodes, 334-10221 edges.
- **Sizes (element:nodes/edges):** 1:254/10221 2:261/334
- **Description:** The Paul Revere conspiracy dataset concerns relationships between 254 people and their affiliations with seven different organizations in Boston. The dataset refers to Paul Revere, who was responsible for organizing a local militia of Boston's revolutionary movement (see http://en.wikipedia.org/wiki/Sons\_of\_Liberty). The dataset was analysed by Kieran Healy of Duke University. This dataset has been reconstructed by looking at the information presented in the appendix of the book ‘Paul Revere's Ride’ published by David Fischer (1994). 2-mode affiliation matrix 254x7 people by organizations, relations refer to membership of organizations; 1-mode matrix 254 x 254 people by people, relations are shared membership of organizations, relations are valued with values indicating number of memberships in common.
- **Source:** Freely available: http://kieranhealy.org/blog/archives/2013/06/09/using-metadata-to-find-paul-revere/
- **References:** Fischer, D. 1994. Paul Revere's ride. Oxford University Press.
- **Load:** `nwwebuse schoch covert_35`

### covert_36: Philippine Kidnappings
{: #covert_36 }
- **Network:** `covert_36`: two-mode; 351 nodes, 402 edges (modes: 246 + 105).
- **Description:** Data refers to the Abu Sayyaf Group (ASG), a violent non-state actor operating in the Southern Philippines. In particular, this data is related to the Salast movement that has been founded by Aburajak Janjalani, a native terrorist of the Southern Philippines in 1991. ASG is active in kidnapping and other kinds of terrorist attacks (Gerdes et al. 2014). The reconstructed 2-mode matrix combines terrorist kidnappers and the terrorist events they have attended. 2-model matrix 246x105 persons by terrorist events, undirected binary relations are participation in events
- **Source:** Available from Manchester (https://sites.google.com/site/ucinetsoftware/datasets/covert-networks). http://www.tandfonline.com/eprint/cCV3RJihmG3miPFECpV7/full
- **References:** Gerdes, Luke M., Kristine Ringler, and Barbara Autin. "Assessing the Abu Sayyaf Group's Strategic and Learning Capacities." \*Studies in Conflict & Terrorism\* 37, no. 3 (2014): 267-293.
- **Load:** `nwwebuse schoch covert_36`

### covert_37: Philippines Bombing
{: #covert_37 }
- **Networks:** list of 15 networks `covert_37_1` ... `covert_37_15`: undirected, valued; 16-16 nodes, 1-69 edges.
- **Sizes (element:nodes/edges):** 1:16/19 2:16/36 3:16/49 4:16/69 5:16/69 6:16/50 7:16/13 8:16/1 9:16/1 10:16/4 11:16/3 12:16/6 13:16/69 14:16/69 15:16/69
- **Description:** This is a time series that treat specific attacks as endpoints and depict the evolution of relations between individuals indirectly and directly associated with the Philippines bombing http://en.wikipedia.org/wiki/Rizal\_Day\_bombings 1-mode stacked matrices 16 x 16 person by person nodes, data on 11 time periods plus kinship data and tie extinguished data. Codebook available here http://doitapps.jjay.cuny.edu/jjatt/files/Relations\_Codebook\_Public\_Version2.pdf
- **Source:** Available from Manchester (https://sites.google.com/site/ucinetsoftware/datasets/covert-networks) or here http://doitapps.jjay.cuny.edu/jjatt/data.php
- **Load:** `nwwebuse schoch covert_37`

### covert_38: Provisional Irish Republican Army
{: #covert_38 }
- **Networks:** list of 5 networks `covert_38_1` ... `covert_38_5`: undirected; 83-526 nodes, 92-1025 edges.
- **Sizes (element:nodes/edges):** 1:334/405 2:260/340 3:526/1025 4:367/514 5:83/92
- **Description:** Data is on active Provisional IRA (hereafter PIRA) members between 1970 and 1998. Data collected at the International Center for the Study of Terrorism, Pennsylvania State University. From this data are derived network structures and the nature of dependence within them. The PIRA network comprises the following four types of relationships: (1) involvement in a PIRA activity together, (2) friends before joining PIRA movement, (3) blood relatives, and (4) related through marriage. We treated each relation as a tie and coded whether a tie exists between two members or not. Thus, the networks have, conceptually and technically, binary and symmetric relations between members. Data also includes sociological information of members, such as gender, age, marital status, recruiting age, education (that is, attending university), brigade memberships, non-/violent characteristics, role-related characteristics—senior leader, IED constructor, IED planter, and gunman—and task-related characteristics (that is, foreign operation tasks, and involvement n bank robbery, kidnapping, hijacking, and drugs).
- **Source:** Available from Manchester (https://sites.google.com/site/ucinetsoftware/datasets/covert-networks).
- **References:** Paul Gill , Jeongyoon Lee , Karl R. Rethemeyer , John Horgan & Victor Asal (2014) Lethal Connections: The Determinants of Network Connections in the Provisional Irish Republican Army, 1970–1998, International Interactions: Empirical and Theoretical Research in International Relations, 40:1, 52-78
- **Load:** `nwwebuse schoch covert_38`

### covert_39: Rhodes Bombing
{: #covert_39 }
- **Network:** `covert_39`: undirected; 22 nodes, 66 edges.
- **Description:** Data is a social network of the (believed defunct) Greek terrorist group November17 (N17) that was derived from open source reporting (Irwin et al, 2002; Abram and Smith, 2004). 1-mode matrix 22x22 persons by persons. Relations indicate that open source reporting has demonstrated some connection between the two individuals at some point in the past. Attribute data includes… Role 1= Leader (gives orders), 2 = operational (receives orders) Faction 1 = 1st Generation Leadership Faction, 2 = Koufontinas Faction, 3 = Sardanopoulos Faction Resources 1= controls one resource, 2= controls two resources, 3= controls three resources (resources are money, weapons, safe houses) Some attribute data is missing
- **Source:** Available from Manchester (https://sites.google.com/site/ucinetsoftware/datasets/covert-networks). Reconstructed from Rhodes, C.J. and P. Jones, “Inferring Missing Links in Partially Observed Social Networks”, Journal of the Operational Research Society (2009) 60, 1373-1383 For more details of attribute data see Rhodes CJ, Keefe EMJ (2007). Social network topology: A Bayesian approach. J Opl Res Soc 58(12): 1605–1611.
- **References:** Rhodes, C.J. and P. Jones, “Inferring Missing Links in Partially Observed Social Networks”, \*Journal of the Operational Research Society\* (2009) 60, 1373-1383
- **Load:** `nwwebuse schoch covert_39`

### covert_4: Australian Embassy Bombing, Indonesia 2004
{: #covert_4 }
- **Networks:** list of 15 networks `covert_4_1` ... `covert_4_15`: undirected, valued; 27-27 nodes, 1-112 edges.
- **Sizes (element:nodes/edges):** 1:27/3 2:27/7 3:27/14 4:27/22 5:27/25 6:27/27 7:27/37 8:27/112 9:27/23 10:27/6 11:27/1 12:27/3 13:27/112 14:27/112 15:27/112
- **Description:** This is a time series that treat specific attacks as endpoints and depict the evolution of relations between individuals indirectly and directly associated with the Australian Embassy bombing. http://en.wikipedia.org/wiki/2004\_Australian\_Embassy\_bombing\_in\_Jakarta 1-mode stacked matrices 27 x 27 person by person. Data for 11 time periods plus kinship data. Undirected, valued ties. Tie value codes for kinship matrix: 0 = No Kinship // 1 = In-laws // 2 = Cousins // 3 = Sibling // 4 = Parent/Child // 5 = Married // 6 = Grandparent/Child // 7 = Significant Other Tie value codes for time series matrices: 0 = No relation // 1 = Acquaintances/distant family ties (interaction limited to radical organisation activities) // 2 = Friends/Moderately close family (inc co-workers/ roommates) Operational/Org leadership/Operational lies (e.g. worked closely on a bombing together) // 3 = Close friends/family, tight-knit operational cliques }
- **Source:** Available from Manchester (https://sites.google.com/site/ucinetsoftware/datasets/covert-networks) or http://doitapps.jjay.cuny.edu/jjatt/data.php
- **Load:** `nwwebuse schoch covert_4`

### covert_40: Saxena Terror India
{: #covert_40 }
- **Networks:** list of 4 networks `covert_40_1` ... `covert_40_4`: undirected (types differ between the networks); 5-25 nodes, 6-64 edges.
- **Sizes (element:nodes/edges):** 1:5/6 2:25/64 3:23/44 4:18/21
- **Description:** Data is organisation-to-organisation links of terrorist organisations operating in the Indian State of Jammu & Kashmir. Four 1-mode matrices persons by persons for years 2000 (5 x 5), 2001 (25 x25), 2002 (23 x 23), 2003 (18 x 18). Undirected, binary ties are "co-occurrence" mentions of terrorist organisations together in various sources e.g. on-line
- **Source:** Available from Manchester (https://sites.google.com/site/ucinetsoftware/datasets/covert-networks)
- **References:** Sudhir Saxena, K. Santhanam, Aparna Basu (2004), 'Application of social network analysis (SNA) to terrorist networks in Jammu & Kashmir’, \*Strategic Analysis\* 28(1)
- **Load:** `nwwebuse schoch covert_40`

### covert_41: Siren
{: #covert_41 }
- **Network:** `covert_41`: undirected; 44 nodes, 103 edges.
- **Description:** Project Siren began in February 1998 when a port worker informed members of the CERVO group that a container of stolen vehicles had been recently shipped to Ghana. This shipment was subsequently seized at its transit point in Anvers, Belgium. This initial tip and action led to a close monitoring of the suspects involved in the shipment. The investigation continued for 4 months (to June 1998), during which time CERVO members monitored stolen-vehicle shipments intended for Russia, Egypt, Iraq, Italy, and Switzerland. Some vehicles were also resold in Toronto. Overall, 35 cars were retrieved according to the files that were consulted. NETWORK 1-mode matrix 44 x 44 person by person. Ties are undirected. Relations represent communication exchanges between criminals. Data comes from police wiretapping.
- **Source:** Available from Manchester (https://sites.google.com/site/ucinetsoftware/datasets/covert-networks), reconstructed from Morselli’s book, Inside Criminal Networks http://www.springer.com/social+sciences/criminology/book/978-0-387-09525-7 book page 187, Appendix
- **References:** Morselli, C., 2009. Inside criminal networks. New York: Springer.
- **Load:** `nwwebuse schoch covert_41`

### covert_42: Slumlords
{: #covert_42 }
- **Networks:** list of 7 networks `covert_42_1` ... `covert_42_7`: undirected (types differ between the networks); 5-22 nodes, 4-23 edges.
- **Sizes (element:nodes/edges):** 1:9/15 2:22/15 3:11/16 4:13/23 5:16/11 6:11/18 7:5/4
- **Description:** “A client of orgnet -- a small, not-for-profit, economic justice organization (EJO) -- used social network analysis to assist their city attorney in convicting a group of "slumlords" of various housing violations that the real estate investors had been side-stepping for years. The housing violations, in multiple buildings, included raw sewage leaks, multiple tenant children with high lead levels, eviction of complaining tenants, utility liens of six figures. Set of matrices of ties between real estate agents, businesses, persons, and properties, corresponding to the step-by-step analysis described here http://www.orgnet.com/slumlords.html 1-mode network 5x5 real estate transactions 2-mode network 11x5 owners by properties 1-mode network 11x11 person by person, relations are common ownership of properties 1-mode network 11x11 person by person, relations are family ties 1-mode network 13x13 person by person, relations are family ties 2-mode network 13x9 person by business and properties, relations are business affiliations/ownership 1 mode network 9x9 business/property by business/property, relations are having affiliated persons/owners in common }
- **Source:** Available at http://www.orgnet.com/slumlords.html and reconstructed at Manchester (https://sites.google.com/site/ucinetsoftware/datasets/covert-networks).
- **Load:** `nwwebuse schoch covert_42`

### covert_43: Southeast Asian Aggregated Attacks 2005
{: #covert_43 }
- **Networks:** list of 48 networks `covert_43_1` ... `covert_43_48`: undirected, valued (types differ between the networks); 108-108 nodes, 1-160 edges.
- **Sizes (element:nodes/edges):** 1:108/11 2:108/29 3:108/4 4:108/160 5:108/93 6:108/25 7:108/107 8:108/97 9:108/29 10:108/4 11:108/5 12:108/47 13:108/1 14:108/5 15:108/63 16:108/90 17:108/108 18:108/4 19:108/1 20:108/1 21:108/1 22:108/5 23:108/1 24:108/1 25:108/1 26:108/17 27:108/2 28:108/4 29:108/4 30:108/16 31:108/1 32:108/60 33:108/7 34:108/10 35:108/5 36:108/25 37:108/24 38:108/7 39:108/3 40:108/8 41:108/9 42:108/112 43:108/7 44:108/82 45:108/16 46:108/78 47:108/38 48:108/5
- **Description:** The Southeast Asian Aggregate Attack Series collapses all of the individual, Indonesian cases into a single series of relations useful for inspecting a series of behavioural and compositional changes in one terrorist network. 1-mode stacked matrices 109x109 person by person. Kinship, friendship, acquaintanceship, time series, tie formed, tie ended. Codebook available here http://doitapps.jjay.cuny.edu/jjatt/files/Relations\_Codebook\_Public\_Version2.pdf
- **Source:** Available from Manchester (https://sites.google.com/site/ucinetsoftware/datasets/covert-networks) or here http://doitapps.jjay.cuny.edu/jjatt/data.php
- **Load:** `nwwebuse schoch covert_43`

### covert_44: Suffragettes
{: #covert_44 }
- **Networks:** list of 12 networks `covert_44_1` ... `covert_44_12`: undirected, valued (types differ between the networks); 13-1614 nodes, 2-1996 edges.
- **Sizes (element:nodes/edges):** 1:85/166 2:85/89 3:85/73 4:85/54 5:85/10 6:85/2 7:1614/1996 8:85/334 9:13/17 10:31/18 11:49/285 12:112/1352
- **Description:** Dataset collected by Gemma Edwards on the Suffragette movement in the UK. “…Relational data were constructed from historical archives, including suffragette letters and speeches, and secondary sources like published auto-biographies and newspaper accounts. This historical material provided not only relational data for quantitative network analysis about the structure of these networks, but rich, narrative accounts about the meaning of ties over time and the perception of the network from those within it. Using historical letters as a source of data on suffragette networks was seen as particularly useful for example, as letters contained relational data in terms of ‘who was writing to whom’, and writers would further ‘talk their ties’ within the course of letter writing. Also, letters tend to be dated, allowing for an analysis of the evolution of ties over time (Edwards and Crossley 2009). 1-mode network 85x85 persons by persons, relations are co-location (1908 visits) 1-mode network 85x85 persons by persons, relations are co-location (1909 visits) 1-mode network 85x85 persons by persons, relations are co-location (1910 visits) 1-mode network 85x85 persons by persons, relations are co-location (1911 visits) 1-mode network 85x85 persons by persons, relations are co-location (1912 visits) 1-mode network 85x85 persons by persons, relations are co-location (1913 visits) 1-mode network 85x85 persons by persons, relations are co-location (Blathwayt visits) 1-mode network 112x112 persons by persons, relations are pre-existing ties (Pankhurst Inner Circle) 2-mode network 13x18 persons by militant acts (Bristol Bath militant acts) 1-mode network 49x49 persons by persons, relations are co-attendence at events (Bristol Bath events) 2-mode network 1216x398 person by arrest date and location (50 all 2M) }
- **Source:** Available from Manchester (https://sites.google.com/site/ucinetsoftware/datasets/covert-networks). http://eprints.ncrm.ac.uk/842/1/Social\_Network\_analysis\_Edwards.pdf
- **References:** Edwards, Gemma, and Nick Crossley. "Measures and meanings: exploring the ego-net of Helen Kirkpatrick Watts, militant suffragette." \*Methodological Innovations Online\* 4.1 (2009): 37-61. Edwards, Gemma. "Infectious innovations? The diffusion of tactical innovation in social movement networks, the case of suffragette militancy." \*Social Movement Studies\* 13.1 (2014): 48-69. Edwards, Gemma. Social Movements and Protest. Cambridge University Press, 2014. Crossley, Nick, et al. "Covert social movement networks and the secrecy-efficiency trade off: The case of the UK suffragettes (1906–1914)." \*Social Networks\* 34.4 (2012): 634-644.
- **Load:** `nwwebuse schoch covert_44`

### covert_45: Swingers
{: #covert_45 }
- **Network:** `covert_45`: two-mode; 96 nodes, 232 edges (modes: 57 + 39).
- **Description:** Data on couples attending swinging parties. 2-mode matrix 57 x 39 couples by events (parties) "Swing units" are a couple attending events with other "swing units".
- **Source:** Data from Anne-Marie Niekamp. Available from Manchester (https://sites.google.com/site/ucinetsoftware/datasets/covert-networks).
- **Load:** `nwwebuse schoch covert_45`

### covert_46: Kenya Tanzania Gerdes
{: #covert_46 }
- **Network:** `covert_46`: two-mode; 43 nodes, 65 edges (modes: 18 + 25).
- **Description:** Data collected by the Center for Computational Analysis of Social and Organizational Systems, a research group at Carnegie Mellon University, on the participation of 18 Al Qaeda members in 25 functional tasks underlying the 1998 bombings of the U.S. Embassies in Nairobi, Kenya, and Dar es Salaam, Tanzania 2-Mode persons to Standing Committees. 2-mode matrix 18 x 25 persons to tasks, binary undirected. Relations are participation in tasks.
- **Source:** Available from Center for Computational Analysis of Social and Organizational Systems (CASOS). (2008). Tanzania-Kenya-imoon.xml. Data available online: http://www.casos.cs.cmu.edu/ computational\_tools/datasets/internal/tanzania\_ kenya/index11.php. Also Available from Manchester (https://sites.google.com/site/ucinetsoftware/datasets/covert-networks).
- **References:** Gerdes, Luke M. (2014), ‘Dependency Centrality from Bipartite Social Networks’, \*Connections\*, 34, 1&2
- **Load:** `nwwebuse schoch covert_46`

### covert_47: Togo
{: #covert_47 }
- **Network:** `covert_47`: undirected; 33 nodes, 47 edges.
- **Description:** Project Togo began in February 1998 when a Toronto-based ringing operation was dismantled and one of its participants informed the police that he was previously employed by a Montreal businessman who was also active in the resale of stolen vehicles. This initial tip was corroborated soon after by a thief who had been arrested while driving a stolen vehicle. By December 1998, the Togo investigation was under way. It spanned into February 1999 and 20 cars that were destined for France, Ghana, and local buyers in southern Quebec were retrieved. NETWORK 1-mode matrix 33 x 33 person by person. Undirected ties. Ties are communication exchanges between criminals. Data comes from police wiretapping.
- **Source:** Available from Manchester (https://sites.google.com/site/ucinetsoftware/datasets/covert-networks), reconstructed from Morselli’s book, Inside Criminal Networks http://www.springer.com/social+sciences/criminology/book/978-0-387-09525-7 book page 187, Appendix
- **References:** Morselli, C., 2009. Inside criminal networks. New York: Springer.
- **Load:** `nwwebuse schoch covert_47`

### covert_6: Bali Bombing 2002/Jemaah Islamiyah
{: #covert_6 }
- **Networks:** list of 11 networks `covert_6_1` ... `covert_6_11`: undirected, valued; 27-27 nodes, 4-156 edges.
- **Sizes (element:nodes/edges):** 1:27/14 2:27/43 3:27/83 4:27/97 5:27/99 6:27/156 7:27/52 8:27/11 9:27/11 10:27/10 11:27/4
- **Description:** This is a time series that treat specific attacks as endpoints and depict the evolution of relations between individuals indirectly and directly associated with the 2002 Bali bombing by Jemaah Islamayah. http://en.wikipedia.org/wiki/2002\_Bali\_bombings 1-mode stacked matrices 27 x 27 person by person, data for 11 time periods. Ties are undirected and valued. Tie codes: 0 = No relation // 1 = Acquaintances/distant family ties (interaction limited to radical organisation activities) // 2 = Friends/Moderately close family (inc co-workers/ roommates) Operational/Org leadership/Operational lies (e.g. worked closely on a bombing together) // 3 = Close friends/family, tight-knit operational cliques
- **Source:** Available from Manchester (https://sites.google.com/site/ucinetsoftware/datasets/covert-networks) or here http://doitapps.jjay.cuny.edu/jjatt/data.php
- **Load:** `nwwebuse schoch covert_6`

### covert_7: Bali Bombing 2005
{: #covert_7 }
- **Networks:** list of 21 networks `covert_7_1` ... `covert_7_21`: undirected (types differ between the networks); 27-27 nodes, 0-90 edges.
- **Sizes (element:nodes/edges):** 1:27/0 2:27/4 3:27/6 4:27/11 5:27/11 6:27/13 7:27/15 8:27/16 9:27/16 10:27/17 11:27/17 12:27/37 13:27/38 14:27/43 15:27/44 16:27/50 17:27/50 18:27/82 19:27/90 20:27/1 21:27/0
- **Description:** This is a time series that treat specific attacks as endpoints and depict the evolution of relations between individuals indirectly and directly associated with the 2005 Bali bombing by Jemaah Islamayah. http://en.wikipedia.org/wiki/2005\_Bali\_bombings 1-mode matrix 27 x 27 person by person, data for 11 time periods. Ties are undirected and valued. Tie codes: 0 = No relation // 1 = Acquaintances/distant family ties (interaction limited to radical organisation activities) // 2 = Friends/Moderately close family (inc co-workers/ roommates) Operational/Org leadership/Operational lies (e.g. worked closely on a bombing together) // 3 = Close friends/family, tight-knit operational cliques.
- **Source:** Available from Manchester (https://sites.google.com/site/ucinetsoftware/datasets/covert-networks) or here http://doitapps.jjay.cuny.edu/jjatt/data.php
- **Load:** `nwwebuse schoch covert_7`

### covert_8: Baseball Steroid Use
{: #covert_8 }
- **Networks:** list of 2 networks `covert_8_1` ... `covert_8_2`: undirected, valued (types differ between the networks); 72-84 nodes, 84-1017 edges.
- **Sizes (element:nodes/edges):** 1:72/1017 2:84/84
- **Description:** “When the Mitchell Report on steroid use in Major League Baseball (MLB), was published people were surprised at both the number and names of those who were mentioned. The diagram below shows a network map created from data found in the Mitchell Report. Baseball players are shown as green nodes. Those who were found to be providers of steroids and other illegal performance enhancing substances appear as red nodes. The links reveal the flow of chemicals -- from providers to players.” http://orgnet.com/steroids.html 2-mode matrix 72 x 12 of users by providers, relations are the supply of illegal performance enhancing substances. 1-mode matrix 72x72 of player by player, relations are having suppliers in common.
- **Source:** Freely available http://orgnet.com/steroids.html and reconstructed by Manchester (https://sites.google.com/site/ucinetsoftware/datasets/covert-networks)
- **Load:** `nwwebuse schoch covert_8`

### covert_9: Big Allied and Dangerous (BAAD)
{: #covert_9 }
- **Networks:** list of 2 networks `covert_9_1` ... `covert_9_2`: undirected, loops (types differ between the networks); 394-459 nodes, 394-4939 edges.
- **Sizes (element:nodes/edges):** 1:394/4939 2:459/394
- **Description:** The Big Allied And Dangerous (BAAD) project focuses on creation and maintenance of a comprehensive database of terrorist organizational characteristics. This project has created two datasets. The first, BAAD Version 1.0 (BAAD1) contains a single snapshot of 395 terrorist organizations active (meaning they perpetrated at least one attack) between 1998-2005. This dataset grew from the information originally hosted by the Memorial Institute for the Prevention of Terrorism’s (MIPT) in their Terrorism Knowledge Base (TKB). BAAD1 improved and extended the data available from MIPT through independent verification and coding efforts. The dataset includes both case-by-variables information on each organization and network data. The case-by-variables dataset is available for download currently. The network data will be available for download during the second quarter of 2010. Big Allied and Dangerous, Version 2.0 (BAAD2) seeks to improve upon BAAD1 in multiple ways by (1) providing time series data in yearly slices, (2) expanding the time period forward through 2007, and (3) increasing the number and depth of variables collected and coded. BAAD2 is made up of two major components. The first is the data on organizational variables. These variables include: group name, aliases, homebase, ideology, size, age, structure, financial support, electoral involvement, leadership loss, territorial control, CBRN pursuit or use, and number of incidents, injuries, and fatalities. The second component is the social network data, which characterizes relations between terrorist organizations as well as between countries and terrorist organizations. Relationships are coded for categories such as: suspected ally, ally, faction, splinter group, rival, enemy, target, and state sponsor. This data can then be used to create dynamic network visualizations to show the networks evolving over the 10 years included in the dataset. Data construction for BAAD2 is currently ongoing. NETWORK 2-mode matrix 394 x 65 organization by territory, undirected ties. Ties are location of attacks. 1-mode matrix 394 x 394 organization by organization (co-location of attacks), undirected ties. Attribute data for each organization. Attribute codebook available at: http://www.albany.edu/pvc/lethality\_paper\_\_CodeBook.pdf
- **Source:** Freely available from http://www.albany.edu/pvc/data.shtml and from Manchester (https://sites.google.com/site/ucinetsoftware/datasets/covert-networks)
- **References:** Asal, Victor H. and R. Karl Rethemeyer. (2008). “The Nature of the Beast: Terrorist Organizational Characteristics and Organizational Lethality.” \*Journal of Politics\*, 70(2): 437-449.
- **Load:** `nwwebuse schoch covert_9`

## Freeman's data sets (UCINET / Moreno collection)

### ants_1: Ant Colony (I)
{: #ants_1 }
- **Network:** `ants_1`: directed, multiple edges; 16 nodes, 200 edges.
- **Description:** These are observations of ritual dominance activities in an ant community (a collection of 16 female Leptothorax allardycei ants over 18.2 hours in a queenright colony)
- **Source:** http://moreno.ss.uci.edu/data.html#ants
- **References:** B. J. Cole, 1981, "Dominance hierarchies in Leptothorax ants" \*Science\*, 212: 83-84.
- **Load:** `nwwebuse schoch ants_1`

### ants_2: Ant Colony (II)
{: #ants_2 }
- **Network:** `ants_2`: directed, multiple edges; 13 nodes, 361 edges.
- **Description:** These are observations of ritual dominance activities in an ant community (a collection of 13 female Leptothorax allardycei ants in a queenless colony)
- **Source:** http://moreno.ss.uci.edu/data.html#ants
- **References:** B. J. Cole, 1981, "Dominance hierarchies in Leptothorax ants" \*Science\*, 212: 83-84.
- **Load:** `nwwebuse schoch ants_2`

### bible: Nouns in the King's James Bible
{: #bible }
- **Network:** `bible`: undirected, valued; 1773 nodes, 9131 edges.
- **Description:** Christoph Romhild recorded 1773 proper nouns--people and places--in the King James Bible. He tallied 63,779 occasions in which pairs of these proper nouns appeared in the same verse in the bible. Many of these, of course, appeared more than once. So the data presented here are tallies, for each pair of proper nouns, of the number of verses in which they appeared together. Romhild worked with Chris Harrison, and together, they produced some elegant visual images of the data. They are displayed in the source listed below.
- **Source:** http://moreno.ss.uci.edu/data#bible
- **References:** http://chrisharrison.net/projects/bibleviz/index.html
- **Load:** `nwwebuse schoch bible`

### bkfrab: Bernard/Killworth - Fraternity (interaction)
{: #bkfrab }
- **Network:** `bkfrab`: undirected, valued; 58 nodes, 967 edges.
- **Description:** These data concern interactions among students living in a fraternity at a West Virginia college. All subjects had been residents in the fraternity from three months to three years. BKFRAB records the number of times a pair of subjects were seen in conversation by an "unobtrusive" observer (who walked through the public areas of the building every fifteen minutes, 21 hours a day, for five days). BKFRAC contains rankings made by the subjects of how frequently they interacted with other subjects in the observation week.
- **Source:** http://moreno.ss.uci.edu/data.html#bkfrat
- **References:** Bernard H. R., Killworth P. and Sailer L. (1980). Informant accuracy in social network data IV. \*Social Networks\*, 2, 191-218. Bernard H. R., Killworth P. and Sailer L. (1982). Informant accuracy in social network data V. \*Social Science Research\*, 11, 30-66. Romney A. K. and Weller S. (1984). Predicting informant accuracy from patterns of recall among individuals. \*Social Networks\*, 6, 59-78.
- **Load:** `nwwebuse schoch bkfrab`

### bkfrac: Bernard/Killworth - Fraternity (rankings)
{: #bkfrac }
- **Network:** `bkfrac`: directed, valued; 58 nodes, 3306 edges.
- **Description:** These data concern interactions among students living in a fraternity at a West Virginia college. All subjects had been residents in the fraternity from three months to three years. BKFRAB records the number of times a pair of subjects were seen in conversation by an "unobtrusive" observer (who walked through the public areas of the building every fifteen minutes, 21 hours a day, for five days). BKFRAC contains rankings made by the subjects of how frequently they interacted with other subjects in the observation week.
- **Source:** http://moreno.ss.uci.edu/data.html#bkfrat
- **References:** #' Bernard H. R., Killworth P. and Sailer L. (1980). Informant accuracy in social network data IV. \*Social Networks\*, 2, 191-218. Bernard H. R., Killworth P. and Sailer L. (1982). Informant accuracy in social network data V. \*Social Science Research\*, 11, 30-66. Romney A. K. and Weller S. (1984). Predicting informant accuracy from patterns of recall among individuals. \*Social Networks\*, 6, 59-78.
- **Load:** `nwwebuse schoch bkfrac`

### bkoffb: Bernard/Killworth - Office (interaction)
{: #bkoffb }
- **Network:** `bkoffb`: undirected, valued; 40 nodes, 238 edges.
- **Description:** These data concern interactions in a small business office, recorded by an "unobtrusive" observer. Observations were made as the observer patrolled a fixed route through the office every fifteen minutes during two four-day periods. BKOFFB contains the observed frequency of interactions; BKOFFC contains rankings of interaction frequency as recalled by the employees over the two-week period.
- **Source:** http://moreno.ss.uci.edu/data.html#bkoff
- **References:** Bernard H. R., Killworth P. and Sailer L. (1980). Informant accuracy in social network data IV. \*Social Networks\*, 2, 191-218. Bernard H. R., Killworth P. and Sailer L. (1982). Informant accuracy in social network data V. \*Social Science Research\*, 11, 30-66. Romney A. K. and Weller S. (1984). Predicting informant accuracy from patterns of recall among individuals. \*Social Networks\*, 6, 59-78.
- **Load:** `nwwebuse schoch bkoffb`

### bkoffc: Bernard/Killworth - Office (rankings)
{: #bkoffc }
- **Network:** `bkoffc`: directed, valued; 40 nodes, 1558 edges.
- **Description:** These data concern interactions in a small business office, recorded by an "unobtrusive" observer. Observations were made as the observer patrolled a fixed route through the office every fifteen minutes during two four-day periods. BKOFFB contains the observed frequency of interactions; BKOFFC contains rankings of interaction frequency as recalled by the employees over the two-week period.
- **Source:** http://moreno.ss.uci.edu/data.html#bkoff
- **References:** #' Bernard H. R., Killworth P. and Sailer L. (1980). Informant accuracy in social network data IV. \*Social Networks\*, 2, 191-218. Bernard H. R., Killworth P. and Sailer L. (1982). Informant accuracy in social network data V. \*Social Science Research\*, 11, 30-66. Romney A. K. and Weller S. (1984). Predicting informant accuracy from patterns of recall among individuals. \*Social Networks\*, 6, 59-78.
- **Load:** `nwwebuse schoch bkoffc`

### bktecb: Bernard/Killworth - Tech company (interaction)
{: #bktecb }
- **Network:** `bktecb`: undirected, valued; 34 nodes, 175 edges.
- **Description:** These data concern interactions in a technical research group at a West Virginia university. BKTECB contains a frequency record of interactions, made by an observer every half-hour during one five-day work week. BKTECC contains the personal rankings of the remembered frequency of interactions in the same period.
- **Source:** http://moreno.ss.uci.edu/data.html#bktec
- **References:** Bernard H. R., Killworth P. and Sailer L. (1980). Informant accuracy in social network data IV. \*Social Networks\*, 2, 191-218. Bernard H. R., Killworth P. and Sailer L. (1982). Informant accuracy in social network data V. \*Social Science Research\*, 11, 30-66. Romney A. K. and Weller S. (1984). Predicting informant accuracy from patterns of recall among individuals. \*Social Networks\*, 6, 59-78.
- **Load:** `nwwebuse schoch bktecb`

### bktecc: Bernard/Killworth - Tech company (rankings)
{: #bktecc }
- **Network:** `bktecc`: directed, valued; 34 nodes, 1122 edges.
- **Description:** These data concern interactions in a technical research group at a West Virginia university. BKTECB contains a frequency record of interactions, made by an observer every half-hour during one five-day work week. BKTECC contains the personal rankings of the remembered frequency of interactions in the same period.
- **Source:** http://moreno.ss.uci.edu/data.html#bktec
- **References:** #' Bernard H. R., Killworth P. and Sailer L. (1980). Informant accuracy in social network data IV. \*Social Networks\*, 2, 191-218. Bernard H. R., Killworth P. and Sailer L. (1982). Informant accuracy in social network data V. \*Social Science Research\*, 11, 30-66. Romney A. K. and Weller S. (1984). Predicting informant accuracy from patterns of recall among individuals. \*Social Networks\*, 6, 59-78.
- **Load:** `nwwebuse schoch bktecc`

### bott: Preschool
{: #bott }
- **Network:** `bott`: directed, valued, multiple edges; 11 nodes, 256 edges.
- **Description:** The data were collected in 1926 in a preschool in Toronto. Observations were made on each child in turn who was defined as a "focal" individual. Instances in which the focal child (1) talked to another, (2) interfered with another, (3) watched another, (4) imitated another or (5) cooperated with another were tabulated along with the name of the other to whom the social behavior was directed. The result was tabulated in five matrices.
- **Source:** http://moreno.ss.uci.edu/data.html#bott
- **References:** Bott, H. "Observations of play activities in a nursery school," \*Genetic Psychology Monographs\*, 1928, 4: 44-88.
- **Load:** `nwwebuse schoch bott`

### ceos_clubs: Ceo's and Clubs
{: #ceos_clubs }
- **Network:** `ceos_clubs`: two-mode; 41 nodes, 98 edges (modes: 26 + 15).
- **Description:** These data give the affiliation network of 26 CEO's of major corporations and banks and their spouses to 15 clubs, corporate and cultural boards.. Data were collected in the Minneapolis area. Membership was during the period 1978-1981.
- **Source:** http://moreno.ss.uci.edu/data.html#galas
- **References:** Galaskiewicz J (1985). Social Organization of an Urban Grants Economy. New York. Academic Press.
- **Load:** `nwwebuse schoch ceos_clubs`

### crime: St. Louis Crimes
{: #crime }
- **Network:** `crime`: two-mode, valued; 1427 nodes, 1487 edges (modes: 870 + 557).
- **Description:** In the 1990s Rick Rosenfeld and Norm White used police records to collect data on crime in St. Louis. They began with five homicides and recorded the names of all the individuals who had been involved as victims, suspects or witnesses. They then explored the files and recorded all the other crimes in which those same individuals appeared. This snowball process was continued until they had data on 557 crime events. Those events involved 870 participants of which: 569 appeared as victims 682 appeared as suspects 195 appeared as witnesses, and 41 were dual (they were recorded both as victims and suspects in the same crime. Their data appear, then, as an 870 by 557, individual by crime event matrix. Victims are coded as 1, suspects as 2, witnesses as 3 and duals as 4.
- **Source:** http://moreno.ss.uci.edu/data#crime
- **Load:** `nwwebuse schoch crime`

### dolphins_1: Dolphins (I)
{: #dolphins_1 }
- **Network:** `dolphins_1`: undirected, valued, loops; 13 nodes, 45 edges.
- **Description:** Thirteen male dolphins were observed as they swam in a shallow lagoon. Tabulations were made of who was swimming with whom. The table shows the observed frequencies.
- **Source:** http://moreno.ss.uci.edu/data.html#dolphin
- **References:** R. C. Connor, R. A. Smolker and A. F. Richards, 1992, "Dolphin alliances and coalitions," in \*Coalitions and Alliances in Humans and Other Animals\* (Eds: A. H. Harcourt and F. B. M. deWaal). Oxford: Oxford University Press, 415-444.
- **Load:** `nwwebuse schoch dolphins_1`

### dolphins_2: Dolphins (II)
{: #dolphins_2 }
- **Network:** `dolphins_2`: undirected; 62 nodes, 159 edges.
- **Description:** undirected social network recording frequent associations between pairs in a community of 62 dolphins living off Doubtful Sound, New Zealand.
- **Source:** http://moreno.ss.uci.edu/data.html#dolphins
- **References:** D. Lusseau, K. Schneider, O. J. Boisseau, P. Haase, E. Slooten, and S. M. Dawson, The bottlenose dolphin community of Doubtful Sound features a large proportion of long-lasting associations, \*Behavioral Ecology and Sociobiology\* 54, 396-405 (2003). D. Lusseau, The emergent properties of a dolphin social network, \*Proc. R. Soc.\* London B (suppl.) 270, S186-S188 (2003). D. Lusseau, Evidence for social role in a dolphin social network, Preprint q-bio/0607048 (http://arxiv.org/abs/q-bio.PE/0607048)
- **Load:** `nwwebuse schoch dolphins_2`

### eies_messages: EIES (Messages)
{: #eies_messages }
- **Network:** `eies_messages`: directed, valued, loops; 32 nodes, 460 edges.
- **Description:** These data arose from an early experiment on computer mediated communication. Fifty academics interested in social network research were allowed to contact each other via an Electronic Information Exchange System (EIES). The data collected consisted of all messages sent plus acquaintance relationships at two time periods (collected via a questionnaire).The data include the 32 actors who completed the study. In addition attribute data on primary discipline and number of citations was recorded. NUMBER\_OF MESSAGES is the total number of messages person i sent to j over the entire period of the study. The attribute data give the number of citations of the actors work in the social science citation index at the beginning of the study together with a discipline code: 1 = Sociology, 2 = Anthropology, 3 = Mathematics/Statistics, 4 = other. These data are used by Wasserman and Faust in their network analysis book.
- **Source:** http://moreno.ss.uci.edu/data.html#eies
- **References:** Freeman, S. C. and L. C. Freeman (1979). The networkers network: A study of the impact of a new communications medium on sociometric structure. \*Social Science Research Reports\* No 46. Irvine CA, University of California. Wasserman S. and K. Faust (1994). Social Network Analysis: Methods and Applications.Cambridge University Press, Cambridge.
- **Load:** `nwwebuse schoch eies_messages`

### eies_relations: EIES (relations)
{: #eies_relations }
- **Network:** `eies_relations`: directed, edge time stamps; 32 nodes, 768 edges.
- **Description:** These data arose from an early experiment on computer mediated communication. Fifty academics interested in social network research were allowed to contact each other via an Electronic Information Exchange System (EIES). The data collected consisted of all messages sent plus acquaintance relationships at two time periods (collected via a questionnaire).The data include the 32 actors who completed the study. In addition attribute data on primary discipline and number of citations was recorded. TIME\_1 and TIME\_2 give the reported acquaintance information at the beginning of the study and eight months later. These are coded as follows: 4 = close personal fiend, 3= friend, 2= person I've met, 1 = person I've heard of but not met, and 0 = person unknown to me (or no reply). The attribute data give the number of citations of the actors work in the social science citation index at the beginning of the study together with a discipline code: 1 = Sociology, 2 = Anthropology, 3 = Mathematics/Statistics, 4 = other. These data are used by Wasserman and Faust in their network analysis book.
- **Source:** http://moreno.ss.uci.edu/data.html#eies
- **References:** Freeman, S. C. and L. C. Freeman (1979). The networkers network: A study of the impact of a new communications medium on sociometric structure. \*Social Science Research Reports\* No 46. Irvine CA, University of California. Wasserman S. and K. Faust (1994). Social Network Analysis: Methods and Applications.Cambridge University Press, Cambridge.
- **Load:** `nwwebuse schoch eies_relations`

### ffe_elite: French Financial Elite (elite)
{: #ffe_elite }
- **Network:** `ffe_elite`: directed; 28 nodes, 330 edges.
- **Description:** In 1990 Kadushin collected data from 127 members of the French financial elite. He used various criteria to determine the top 28 and recorded their who-to-whom responses to questions about who was influencential, who were members of the elite and who were friends. He also recorded a large amount of information on their individual backgrounds and characteristics.
- **Source:** http://moreno.ss.uci.edu/data#ffe
- **References:** Kadushin, C. 1995. "Friendship among the French financial elite." \*American Sociological Review\* 60:202-221.
- **Load:** `nwwebuse schoch ffe_elite`

### ffe_friends: French Financial Elite (friendships)
{: #ffe_friends }
- **Network:** `ffe_friends`: undirected; 28 nodes, 66 edges.
- **Description:** In 1990 Kadushin collected data from 127 members of the French financial elite. He used various criteria to determine the top 28 and recorded their who-to-whom responses to questions about who was influencential, who were members of the elite and who were friends. He also recorded a large amount of information on their individual backgrounds and characteristics.
- **Source:** http://moreno.ss.uci.edu/data#ffe
- **References:** Kadushin, C. 1995. "Friendship among the French financial elite." \*American Sociological Review\* 60:202-221.
- **Load:** `nwwebuse schoch ffe_friends`

### ffe_influence: French Financial Elite (influence)
{: #ffe_influence }
- **Network:** `ffe_influence`: directed; 28 nodes, 100 edges.
- **Description:** In 1990 Kadushin collected data from 127 members of the French financial elite. He used various criteria to determine the top 28 and recorded their who-to-whom responses to questions about who was influencential, who were members of the elite and who were friends. He also recorded a large amount of information on their individual backgrounds and characteristics.
- **Source:** http://moreno.ss.uci.edu/data#ffe
- **References:** Kadushin, C. 1995. "Friendship among the French financial elite." \*American Sociological Review\* 60:202-221.
- **Load:** `nwwebuse schoch ffe_influence`

### flo_business: Florentine Families (Business)
{: #flo_business }
- **Network:** `flo_business`: undirected; 16 nodes, 15 edges.
- **Description:** Breiger & Pattison (1986), in their discussion of local role analysis, use a subset of data on the social relations among Renaissance Florentine families (person aggregates) collected by John Padgett from historical documents. The two relations are business ties (specifically, recorded financial ties such as loans, credits and joint partnerships) and marriage alliances. As Breiger & Pattison point out, the original data are symmetrically coded. This is acceptable perhaps for marital ties, but is unfortunate for the financial ties (which are almost certainly directed). To remedy this, the financial ties can be recoded as directed relations using some external measure of power - for instance, a measure of wealth. PADGW provides information on (1) each family's net wealth in 1427 (in thousands of lira); (2) the number of priorates (seats on the civic council) held between 1282- 1344; and (3) the total number of business or marriage ties in the total dataset of 116 families (see Breiger & Pattison (1986), p 239). Substantively, the data include families who were locked in a struggle for political control of the city of Florence in around 1430. Two factions were dominant in this struggle: one revolved around the infamous Medicis (9), the other around the powerful Strozzis (15).
- **Source:** http://moreno.ss.uci.edu/data#padgett
- **References:** Breiger R. and Pattison P. (1986). Cumulated social roles: The duality of persons and their algebras. \*Social Networks\*, 8, 215-256. Kent D. (1978). The rise of the Medici: Faction in Florence, 1426-1434. Oxford: Oxford University Press.
- **Load:** `nwwebuse schoch flo_business`

### flo_marriage: Florentine Families (Marriage)
{: #flo_marriage }
- **Network:** `flo_marriage`: undirected; 16 nodes, 20 edges.
- **Description:** Breiger & Pattison (1986), in their discussion of local role analysis, use a subset of data on the social relations among Renaissance Florentine families (person aggregates) collected by John Padgett from historical documents. The two relations are business ties (specifically, recorded financial ties such as loans, credits and joint partnerships) and marriage alliances. As Breiger & Pattison point out, the original data are symmetrically coded. This is acceptable perhaps for marital ties, but is unfortunate for the financial ties (which are almost certainly directed). To remedy this, the financial ties can be recoded as directed relations using some external measure of power - for instance, a measure of wealth. PADGW provides information on (1) each family's net wealth in 1427 (in thousands of lira); (2) the number of priorates (seats on the civic council) held between 1282- 1344; and (3) the total number of business or marriage ties in the total dataset of 116 families (see Breiger & Pattison (1986), p 239). Substantively, the data include families who were locked in a struggle for political control of the city of Florence in around 1430. Two factions were dominant in this struggle: one revolved around the infamous Medicis (9), the other around the powerful Strozzis (15).
- **Source:** http://moreno.ss.uci.edu/data#padgett
- **References:** Breiger R. and Pattison P. (1986). Cumulated social roles: The duality of persons and their algebras. \*Social Networks\*, 8, 215-256. Kent D. (1978). The rise of the Medici: Faction in Florence, 1426-1434. Oxford: Oxford University Press.
- **Load:** `nwwebuse schoch flo_marriage`

### fraternity: Newcomb Fraternity
{: #fraternity }
- **Networks:** list of 15 networks `fraternity_1` ... `fraternity_15`: directed; 17-17 nodes, 272-272 edges.
- **Sizes (element:nodes/edges):** 1:17/272 2:17/272 3:17/272 4:17/272 5:17/272 6:17/272 7:17/272 8:17/272 9:17/272 10:17/272 11:17/272 12:17/272 13:17/272 14:17/272 15:17/272
- **Description:** The networksrecord weekly sociometric preference rankings from 17 men attending the University of Michigan in the fall of 1956; data from week 9 are missing. A "1" indicates first preference, and no ties were allowed. The men were recruited to live in off-campus (fraternity) housing, rented for them as part of the Michigan Group Study Project supervised by Theodore Newcomb from 1953 to 1956. All were incoming transfer students with no prior acquaintance of one another. After the meeting, Lin Freeman cleaned the data set and made it available on his website. It takes the form of a matrix that records coauthorship among 475 authors who were involved in the production of 295 articles. Cell entries report the number of coaurherships displayed by pairs of authors.
- **Source:** http://moreno.ss.uci.edu/data#newfrat
- **References:** Newcomb T. (1961). The acquaintance process. New York: Holt, Reinhard & Winston. Nordlie P. (1958). A longitudinal study of interpersonal attraction in a natural group setting. Unpublished doctoral dissertation, University of Michigan. White H., Boorman S. and Breiger R. (1977). Social structure from multiple networks, I. Blockmodels of roles and positions. \*American Journal of Sociology\*, 81, 730-780.
- **Load:** `nwwebuse schoch fraternity`

### giraffe: Giraffe Affiliation
{: #giraffe }
- **Network:** `giraffe`: directed, valued, multiple edges; 6 nodes, 90 edges.
- **Description:** The authors studied a herd of six female captive giraffe (Giraffa camelopardalis) for two years. They were concerned with the question of whether giraffe associated randomly or patterned their behavior and proximity in a manner indicative of social relationships. Affiliative interaction, proximity, and nearest neighbors for female giraffe living in a large outdoor enclosure were analyzed, and all three measures were nonrandomly distributed, indicating female giraffe had social preferences. Furthermore, preferences were consistent across measures and time, suggesting that adult female giraffe maintain relationships.
- **Source:** http://moreno.ss.uci.edu/data.html#giraffe
- **References:** Brashaw, M. J., M. A. Bloomsmith, T. L. Maple and F. B. Bercovitch. 2007. "The Structure of Social Relationships Among Captive Female Giraffe (Giraffa camelopardalis)." \*Journal of Comparative Psychology\* 121:46-53.
- **Load:** `nwwebuse schoch giraffe`

### hall: Residence Hall Friendship
{: #hall }
- **Network:** `hall`: directed, valued; 217 nodes, 2672 edges.
- **Description:** Cynthia Webster collected friendship data among the 217 residents living at a residence hall located on the Australian National University campus. Residents were interviewed individually at the start of the second semester. First, they were asked to recall all of their friends who currently lived in the residence hall. They then were provided with a list of all residents and were asked to add anyone whom they also considered a friend, but had forgotten to include. From the complete list of friends, they were asked to indicate the strength of each friendship tie. Most specified three levels of friendship, "best friend," "close friend," and "friend." The data were combined to form a valued, actor-by-actor matrix of reported friendship relations.
- **Source:** http://moreno.ss.uci.edu/data#oz
- **References:** L. C. Freeman, C. M. Webster and D. M. Kirke (1998) "Exploring social structure using dynamic three-dimensional color images." \*Social Networks\* 20, 109-118
- **Load:** `nwwebuse schoch hall`

### hens: Hens Pecking order
{: #hens }
- **Network:** `hens`: directed; 32 nodes, 496 edges.
- **Description:** Records the "peck order" of a flock of 32 White Leghorn hens studied in 1946. A tie from hen a to b means that hen a can peck hen b. The author claims that temporal changes are rare; once a hen dominates another, that pattern persists.
- **Source:** http://moreno.ss.uci.edu/data.html#hens
- **References:** Guhl, A. M., 1953. Social Behavior of the Domestic Fowl. Manhattan, Kansas: Kansas State College, Agricultural Experiment Station, Technical Bulletin 73.
- **Load:** `nwwebuse schoch hens`

### highschool_boys: Friendships among High School Boys
{: #highschool_boys }
- **Network:** `highschool_boys`: directed, multiple edges, edge time stamps; 70 nodes, 506 edges.
- **Description:** In the fall of 1957. and the spring of 1958. boys in a small high school in Illinois were asked. "What fellows here in school do you go around with most often?" The data are from research reported by Coleman. The data report the direct choices of each of 73 boys at two times. HS1 was recorded in 1957 and HS2 in 1958.
- **Source:** http://moreno.ss.uci.edu/data.html#high
- **References:** Coleman, J. S. Introduction to Mathermatical Sociology. New York: Free Press, pp.450-451.
- **Load:** `nwwebuse schoch highschool_boys`

### ht_advice: High-tech Managers (Advice)
{: #ht_advice }
- **Network:** `ht_advice`: directed; 21 nodes, 190 edges.
- **Description:** These data were collected from the managers of a high-tec company. The company manufactured high-tech equipment on the west coast of the United States and had just over 100 employees with 21 managers. Each manager was asked "To whom do you go to for advice?" and "Who is your friend?" Data for the item "To whom do you report?" was taken from company documents. In addition attribute information was collected. This consisted of the managers age (in years), length of service or tenure (in years), level in the corporate hierarchy (coded 1,2 and 3; 1=CEO, 2 = Vice President, 3 = manager) and department (coded 1,2,3,4 with the CEO in department 0 ie not in a department).
- **Source:** http://moreno.ss.uci.edu/data#krackht
- **References:** Krackhardt D. (1987). Cognitive social structures. \*Social Networks\*, 9, 104-134.
- **Load:** `nwwebuse schoch ht_advice`

### ht_friends: High-tech Managers (Friendships)
{: #ht_friends }
- **Network:** `ht_friends`: directed; 21 nodes, 102 edges.
- **Description:** These data were collected from the managers of a high-tec company. The company manufactured high-tech equipment on the west coast of the United States and had just over 100 employees with 21 managers. Each manager was asked "To whom do you go to for advice?" and "Who is your friend?" Data for the item "To whom do you report?" was taken from company documents. In addition attribute information was collected. This consisted of the managers age (in years), length of service or tenure (in years), level in the corporate hierarchy (coded 1,2 and 3; 1=CEO, 2 = Vice President, 3 = manager) and department (coded 1,2,3,4 with the CEO in department 0 ie not in a department).
- **Source:** http://moreno.ss.uci.edu/data#krackht
- **References:** Krackhardt D. (1987). Cognitive social structures. \*Social Networks\*, 9, 104-134.
- **Load:** `nwwebuse schoch ht_friends`

### ht_reports: High-tech Managers (Reports to)
{: #ht_reports }
- **Network:** `ht_reports`: directed; 21 nodes, 20 edges.
- **Description:** These data were collected from the managers of a high-tec company. The company manufactured high-tech equipment on the west coast of the United States and had just over 100 employees with 21 managers. Each manager was asked "To whom do you go to for advice?" and "Who is your friend?" Data for the item "To whom do you report?" was taken from company documents. In addition attribute information was collected. This consisted of the managers age (in years), length of service or tenure (in years), level in the corporate hierarchy (coded 1,2 and 3; 1=CEO, 2 = Vice President, 3 = manager) and department (coded 1,2,3,4 with the CEO in department 0 ie not in a department).
- **Source:** http://moreno.ss.uci.edu/data#krackht
- **References:** Krackhardt D. (1987). Cognitive social structures. \*Social Networks\*, 9, 104-134.
- **Load:** `nwwebuse schoch ht_reports`

### insna: INSNA Teacher Student
{: #insna }
- **Network:** `insna`: directed; 60 nodes, 94 edges.
- **Description:** When Barry Wellman founded the International Network for Social Network Analysis (INSNA) in 1977, he sent a questionnaire to all the founding members. Included were questions on who taught each founder and who each founder taught. This data set is based on their responses.
- **Source:** http://moreno.ss.uci.edu/data#ts
- **References:** K. Reitz and D. R. White, 1989 "Rethinking the Role Concept: Homomorphisms on Social Networks" pp. 429-488 in L.C.Freeman, D.R. White, A.K.Romney, eds., Research Methods in Social Network Analysis. George Mason Press. Reprinted 1992 Transaction Publishers: New Brunswick, NJ.
- **Load:** `nwwebuse schoch insna`

### jazz: Collaboration in Jazz
{: #jazz }
- **Network:** `jazz`: undirected; 198 nodes, 2742 edges.
- **Description:** The data here record a network of jazz bands. The data were obtained from The Red Hot Jazz Archive digital database. The data include 198 bands that performed between 1912 and 1940, with most of the bands performing in the 1920's. In this case each vertex corresponds to a band, and a link between two bands is established if they had at least one musician in common.
- **Source:** http://moreno.ss.uci.edu/data.html#jazz
- **References:** PABLO M. GLEISER and LEON DANON "Community structure in jazz." Advances in Complex Systems (ACS) 2003 Vol: 6 Issue: 4 (December 2003) Page: 565 - 573.
- **Load:** `nwwebuse schoch jazz`

### jpr: Joint Senate Press Releases
{: #jpr }
- **Network:** `jpr`: undirected; 92 nodes, 477 edges.
- **Description:** These data are from Justin Grimmer's doctoral dissertation in political science at Harvard. They record instances of joint press releases issued by U. S. Senators.
- **Source:** http://moreno.ss.uci.edu/data.html#jpr
- **References:** http://people.fas.harvard.edu/~jgrimmer/
- **Load:** `nwwebuse schoch jpr`

### kangaroo: Kangaroo
{: #kangaroo }
- **Network:** `kangaroo`: undirected, valued, loops; 17 nodes, 105 edges.
- **Description:** Frequencies of observed physical proximities among a collection of 17 free-ranging grey kangaroos. Observations were made in the Nadgee Nature Reserve in New South Wales. There were 18 kangaroos in the original report, but one (number M11) was never observed and is therefore dropped from this network. Two kinds of dominance ranks are included. One, ss, is the ratio of an animal's number of "successes" to its number of "involvements." The other, ps, is calculated by assigning an animal 2 points for each other animal it bests on more than 50/% of their contacts. One point is given for a tie and none for less than 50/% successes. Since, except for a juvenile male (M2), there were no cross-sex contests, males and females are ranked seperately, but M2 is ranked with the females.
- **Source:** http://moreno.ss.uci.edu/data.html#kangaroo
- **References:** T. R. Grant, "Dominance and association among members of a captive and a free-ranging group of grey kangaroos (Macropus giganthus)," \*Animal Behaviour\*, 1973, 21: 449-456.
- **Load:** `nwwebuse schoch kangaroo`

### karate: Karate Club (binary)
{: #karate }
- **Network:** `karate`: undirected; 34 nodes, 78 edges.
- **Description:** These are data collected from the members of a university karate club by Wayne Zachary (presence or absence of ties among the members of the club) Zachary (1977) used these data and an information flow model of network conflict resolution to explain the split-up of this group following disputes among the members.
- **Source:** http://moreno.ss.uci.edu/data#zachary
- **References:** Zachary W. (1977). An information flow model for conflict and fission in small groups. \*Journal of Anthropological Research\*, 33, 452-473.
- **Load:** `nwwebuse schoch karate`

### karate_weight: Karate Club (weighted)
{: #karate_weight }
- **Network:** `karate_weight`: undirected, multiple edges; 34 nodes, 231 edges.
- **Description:** These are data collected from the members of a university karate club by Wayne Zachary (relative strength of the associations, i.e. number of situations in and outside the club in which interactions occurred). Zachary (1977) used these data and an information flow model of network conflict resolution to explain the split-up of this group following disputes among the members.
- **Source:** http://moreno.ss.uci.edu/data#zachary
- **References:** Zachary W. (1977). An information flow model for conflict and fission in small groups. \*Journal of Anthropological Research\*, 33, 452-473.
- **Load:** `nwwebuse schoch karate_weight`

### law_advice: Law Firm (Advice)
{: #law_advice }
- **Network:** `law_advice`: directed; 71 nodes, 892 edges.
- **Description:** This data set comes from a network study of corporate law partnership that was carried out in a Northeastern US corporate law firm, referred to as SG&R, 1988-1991 in New England. It includes (among others) measurements of networks among the 71 attorneys (partners and associates) of this firm, i.e. their strong-coworker network, advice network, friendship network, and indirect control networks. Various members' attributes are also part of the dataset, including seniority, formal status, office in which they work, gender, lawschool attended. The ethnography, organizational and network analyses of this case are available in Lazega (2001). \*\*Basic advice network\*\*: "Think back over the past year, consider all the lawyers in your Firm. To whom did you go for basic professional advice? For instance, you want to make sure that you are handling a case right, making a proper decision, and you want to consult someone whose professional opinions are in general of great value to you. By advice I do not mean simply technical advice." Coding: The first 36 respondents are the partners in the firm. The attribute variables are: 1. status (1=partner; 2=associate) 2. gender (1=man; 2=woman) 3. office (1=Boston; 2=Hartford; 3=Providence) 4. years with the firm 5. age 6. practice (1=litigation; 2=corporate) 7. law school (1: harvard, yale; 2: ucon; 3: other) }
- **Source:** http://moreno.ss.uci.edu/data#lazega
- **References:** Emmanuel Lazega, The Collegial Phenomenon: The Social Mechanisms of Cooperation Among Peers in a Corporate Law Partnership, Oxford University Press (2001). Tom A.B. Snijders, Philippa E. Pattison, Garry L. Robins, and Mark S. Handcock. New specifications for exponential random graph models. \*Sociological Methodology\* (2006), 99-153.
- **Load:** `nwwebuse schoch law_advice`

### law_cowork: Law Firm (Co-work)
{: #law_cowork }
- **Network:** `law_cowork`: directed; 71 nodes, 1104 edges.
- **Description:** This data set comes from a network study of corporate law partnership that was carried out in a Northeastern US corporate law firm, referred to as SG&R, 1988-1991 in New England. It includes (among others) measurements of networks among the 71 attorneys (partners and associates) of this firm, i.e. their strong-coworker network, advice network, friendship network, and indirect control networks. Various members' attributes are also part of the dataset, including seniority, formal status, office in which they work, gender, lawschool attended. The ethnography, organizational and network analyses of this case are available in Lazega (2001). \*\*Strong coworkers network:\*\* "Because most firms like yours are also organized very informally, it is difficult to get a clear idea of how the members really work together. Think back over the past year, consider all the lawyers in your Firm. Would you go through this list and check the names of those with whom you have worked with. (By "worked with" I mean that you have spent time together on at least one case, that you have been assigned to the same case, that they read or used your work product or that you have read or used their work product; this includes professional work done within the Firm like Bar association work, administration, etc.)" Coding: The first 36 respondents are the partners in the firm. The attribute variables are: 1. status (1=partner; 2=associate) 2. gender (1=man; 2=woman) 3. office (1=Boston; 2=Hartford; 3=Providence) 4. years with the firm 5. age 6. practice (1=litigation; 2=corporate) 7. law school (1: harvard, yale; 2: ucon; 3: other) }
- **Source:** http://moreno.ss.uci.edu/data#lazega
- **References:** Emmanuel Lazega, The Collegial Phenomenon: The Social Mechanisms of Cooperation Among Peers in a Corporate Law Partnership, Oxford University Press (2001). Tom A.B. Snijders, Philippa E. Pattison, Garry L. Robins, and Mark S. Handcock. New specifications for exponential random graph models. \*Sociological Methodology\* (2006), 99-153.
- **Load:** `nwwebuse schoch law_cowork`

### law_friends: Law Firm (Friendship)
{: #law_friends }
- **Network:** `law_friends`: directed; 71 nodes, 575 edges.
- **Description:** This data set comes from a network study of corporate law partnership that was carried out in a Northeastern US corporate law firm, referred to as SG&R, 1988-1991 in New England. It includes (among others) measurements of networks among the 71 attorneys (partners and associates) of this firm, i.e. their strong-coworker network, advice network, friendship network, and indirect control networks. Various members' attributes are also part of the dataset, including seniority, formal status, office in which they work, gender, lawschool attended. The ethnography, organizational and network analyses of this case are available in Lazega (2001). \*\*Friendship network:\*\* "Would you go through this list, and check the names of those you socialize with outside work. You know their family, they know yours, for instance. I do not mean all the people you are simply on a friendly level with, or people you happen to meet at Firm functions." Coding: The first 36 respondents are the partners in the firm. The attribute variables are: 1. status (1=partner; 2=associate) 2. gender (1=man; 2=woman) 3. office (1=Boston; 2=Hartford; 3=Providence) 4. years with the firm 5. age 6. practice (1=litigation; 2=corporate) 7. law school (1: harvard, yale; 2: ucon; 3: other) }
- **Source:** http://moreno.ss.uci.edu/data#lazega
- **References:** Emmanuel Lazega, The Collegial Phenomenon: The Social Mechanisms of Cooperation Among Peers in a Corporate Law Partnership, Oxford University Press (2001). Tom A.B. Snijders, Philippa E. Pattison, Garry L. Robins, and Mark S. Handcock. New specifications for exponential random graph models. \*Sociological Methodology\* (2006), 99-153.
- **Load:** `nwwebuse schoch law_friends`

### literary: Swedish Literary Criticism
{: #literary }
- **Network:** `literary`: undirected; 15 nodes, 17 edges.
- **Description:** Rosengren collected data on Swedish literary critics writing during the stylistic revolution in Swedish literature in 1881 to 1883. He recorded sets of authors, other than the author being reviewed, who were mentioned together in any published literary review in the Swedish press during those years. Then he dropped any pairs that were mentioned together less than five times and he included only those pairs of authors whose proportion of co-mentions was more than three standard errors above its expectation.
- **Source:** http://moreno.ss.uci.edu/data#swedish
- **References:** Rosengren, K. E. (1968). Sociological Aspects of the Literary System. Stockholm: Natur och Culture. Rosengren, K. E. (1983). The Climate of Literature: Sweden's Literary Frume of Reference, 1953-1976. Lund: Studentlitteratur. Freeman, Linton C. "Boxicity and the Social Context of Swedish Literary Criticism, 1881-1883." \*Journal of Social and Biological Structures\*, 9, 1986, 141-149.
- **Load:** `nwwebuse schoch literary`

### macaque: Macaque Dominance
{: #macaque }
- **Network:** `macaque`: directed, valued; 62 nodes, 1187 edges.
- **Description:** records dominance relations (a directed tie from a to b means a dominates b) in a colony of 62 adult female Japanese macaques (Macaca fuscata fuscata). They are known as the "Arashiyama B group." Records were made during the non-mating season, April to early October, 1976. Approach-retreat episodes involving food were recorded. In addition, the presence of six lineages was reported. The first 4 animals belong to a lineage, and the next 14 belong to another. The following 31 are in a third lineage, and the next 6 are in the fourth. The following 6 are the fifth lineage, and the remaining animal is unrelated to the others.
- **Source:** http://moreno.ss.uci.edu/data#mac
- **References:** Y. Takahata, "Diachronic changes in the dominance relations of adult female Japanese monkeys of the Arashiyama B group," in Linda Marie Fedigan and Pamela J. Asquith, eds., The Monkeys of Arashiyama. Albany: State University of New York Press, 1991, pp. 124-139.
- **Load:** `nwwebuse schoch macaque`

### mine: Kapferer - Mine
{: #mine }
- **Network:** `mine`: undirected; 15 nodes, 25 edges.
- **Description:** Bruce Kapferer (1969) collected data on men working on the surface in a mining operation in Zambia (then Northern Rhodesia). He wanted to account for the development and resolution of a conflict among the workers. The conflict centered on two men, Abraham and Donald; most workers ended up supporting Abraham. Kapferer observed and recorded several types of interactions among the workers, including conversation, joking, job assistance, cash assistance and personal assistance. Two miners are connected if they are connected by any of these relations.
- **Source:** http://moreno.ss.uci.edu/data#kapmine
- **References:** Kapferer B. (1969). Norms and the manipulation of relationships in a work context. In J Mitchell (ed), Social networks in urban situations. Manchester: Manchester University Press. Doreian P. (1974). On the connectivity of social networks. \*Journal of Mathematical Sociology\*, 3, 245-258.
- **Load:** `nwwebuse schoch mine`

### miserables: Les Miserables co-appearances
{: #miserables }
- **Network:** `miserables`: undirected, valued; 77 nodes, 254 edges.
- **Description:** Weighted network of co-appearances of characters in Victor Hugo's novel "Les Miserables". Nodes represent characters as indicated by the labels and edges connect any pair of characters that appear in the same chapter of the book. The values on the edges are the number of such coappearances.
- **Source:** http://moreno.ss.uci.edu/data#lesmis
- **References:** D. E. Knuth. (1993). The Stanford GraphBase: A Platform for Combinatorial Computing, Addison-Wesley, Reading, MA
- **Load:** `nwwebuse schoch miserables`

### netsci: Netscience Coauthorship
{: #netsci }
- **Network:** `netsci`: undirected, valued; 1589 nodes, 2742 edges.
- **Description:** coauthorship network of scientists working on network theory and experiment, as compiled by Mark Newman in May 2006. The network was compiled from the bibliographies of two review articles on networks, M. E. J. Newman, SIAM Review 45, 167-256 (2003) and S. Boccaletti et al., Physics Reports 424, 175-308 (2006), with a few additional references added by hand. The version given here contains all components of the network, for a total of 1589 scientists, and not just the largest component of 379 scientists previously published. The network is weighted, with weights assigned directly in terms of the number of collaborations between authors and inversely in terms of the number of other authors involved. This weighting is described in M. E. J. Newman, Phys. Rev. E 64, 016132 (2001).
- **Source:** http://moreno.ss.uci.edu/data#netsci
- **References:** M. E. J. Newman, Finding community structure in networks using the eigenvectors of matrices, Preprint physics/0605087 (2006).
- **Load:** `nwwebuse schoch netsci`

### physicians: Innovations among Physicians
{: #physicians }
- **Network:** `physicians`: directed; 246 nodes, 1099 edges.
- **Description:** This data set was prepared by Ron Burt. He dug out the 1966 data collected by Coleman, Katz and Menzel on medical innovation. They had collected data from physicians in four towns in Illinois, Peoria, Bloomington, Quincy and Galesburg. They were concerned with the impact of network ties on the physicians' adoprion of a new drug, tetracycline. Three sociometric matrices were generated. One was based on the replies to a question, "When you need information or advice about questions of therapy where do you usually turn?" A second stemmed from the question "And who are the three or four physicians with whom you most often find yourself discussing cases or therapy in the course of an ordinary week -- last week for instance?" And the third was simply "Would you tell me the first names of your three friends whom you see most often socially?" In addition, records of prescriptions were reviewed and a great many other questions were asked. In the ATTRIBUTES data I have included 13 items: city of practice, recorded date of tetracycline adoption date, years in practice, meetings attended, journal subscriptions, free time activities, discussions, club memberships, friends, time in the community, patient load, physical proximity to other physicians and medical specialty.
- **Source:** http://moreno.ss.uci.edu/data.html#ckm
- **References:** Coleman, J. S. Introduction to Mathermatical Sociology. New York: Free Press, pp.450-451.
- **Load:** `nwwebuse schoch physicians`

### polblogs: Political Blogs
{: #polblogs }
- **Network:** `polblogs`: directed, loops; 1490 nodes, 19025 edges.
- **Description:** The data were compiled by Lada Adamic and Natalie Glance. Links between blogs were automatically extracted from a crawl of the front page of the blog. In addition the authors drew on various sources (blog directories, and incoming and outgoing links and posts around the time of the 2004 presidential election) and classified the first 758 blogs as left-leaning and the remaining 732 as right-leaning.
- **Source:** http://moreno.ss.uci.edu/data.html#blogs
- **References:** Lada A. Adamic and Natalie Glance, "The political blogosphere and the 2004 US election", \*Proceedings of the WWW-2005 Workshop on the Weblogging Ecosystem\* (2005)
- **Load:** `nwwebuse schoch polblogs`

### polbooks: Political Books
{: #polbooks }
- **Network:** `polbooks`: directed; 105 nodes, 441 edges.
- **Description:** Nodes represent books about US politics sold by the online bookseller Amazon.com. Edges represent frequent co-purchasing of books by the same buyers, as indicated by the "customers who bought this book also bought these other books" feature on Amazon.
- **Source:** http://moreno.ss.uci.edu/data#books
- **References:** Valdis Krebs, unpublished, http://www.orgnet.com/
- **Load:** `nwwebuse schoch polbooks`

### pony: Pony
{: #pony }
- **Network:** `pony`: directed, multiple edges; 17 nodes, 761 edges.
- **Description:** weights are the number of occasions in which the row pony threatened the column pony.
- **Source:** http://moreno.ss.uci.edu/data.html#pony
- **References:** T.H.Cluton-Brock, J.P.Greenwood and R.P.Powell, 1976, "Ranks and Relationships in Highland Ponies and Highland Cows," \*Zeitschrift Tierpsychologie\*, 41, 202-216. M.W.Schein and M.W.Frohman, 1955, "Social Dominance Relationships in a Herd of Dairy-Cattle," \*British Journal of Animal Behaviour\*, 3, 45-55 (1955).
- **Load:** `nwwebuse schoch pony`

### protein: Protein-Protein Interactions (probably yeast)
{: #protein }
- **Network:** `protein`: undirected, multiple edges, loops; 2114 nodes, 4480 edges.
- **Description:** One research area in biology in which centralities have been applied is protein-protein interaction. Interactions between proteins are common. They play an important part in every process involving living cells. Knowledge about how they interact can lead to better understanding of a great many diseases and it can help in the design of appropriate therapies. Often studies of protein-protein interaction generate huge data sets. In the letter in Nature that was mentioned above, Jeong, Mason, Barabasi and Oltvai (2001) examined a data matrix that contained interactions linking 2114 proteins contained in yeast. Earlier experimental work had demonstrated that some of the protein molecules in yeast were lethal; if they were removed the yeast would die. Removing others, however, had no such dramatic effect. So Jeong et al. examined the question of whether the structural properties of those proteins, in particular their degree centralities, could predict which proteins were lethal and which ones were not. Their results showed that proteins of high degree were far more likely to be lethal than those of lower degree. Subsequent articles (cited below) questioned these results. The argument was that gaps in the data called the whole analysis into question.
- **Source:** http://moreno.ss.uci.edu/data.html#pro-pro
- **References:** Jeong, H., S. P. Mason, A.-L. Barabasi and Z. N. Oltvai. (2001). "Lethality and centrality in protein networks." \*Nature\* 411(6833): 41-42. S. Coulomb, M. Bauer, D. Bernard, and M.-C. Marsolier-Kergoat. (2005). "Gene essentiality and the topology of protein interaction networks", \*Proceedings of the Royal Society B: Biological Sciences\*, Volume 272, Number 1573:1721-1725. J-D. Han, D. Dupuy, N. Bertin, M. E. Cusick, and M. Vidal. (2005). "Effect of sampling on topology predictions of protein-protein interaction networks", \*Nature Biotechnology\* 23 (7):839-844. M. Stumpf, C. Wiuf, and R. May. (2005). "Subnets of scale-free networks are not scale-free: Sampling properties of networks", \*PNAS\* 102 (12):4221-4224.
- **Load:** `nwwebuse schoch protein`

### rhesus: Rhesus Monkey Grooming
{: #rhesus }
- **Network:** `rhesus`: directed, valued; 16 nodes, 111 edges.
- **Description:** observed grooming episodes in a community of free ranging rhesus monkeys in Cayo Santiago observed in June and July of 1963. Seven are males (066, ER, R006, EZ, EC, CY and CN) and the other nine are females.
- **Source:** http://moreno.ss.uci.edu/data#rhesus
- **References:** D. S. Sade, "Sociometrics of Macaca mulatta: Linkages and cliques in grooming matrices," \*Folia Primatologica\*, 1972, 18: 196-223.
- **Load:** `nwwebuse schoch rhesus`

### sampson: Monastery
{: #sampson }
- **Networks:** list of 10 networks `sampson_1` ... `sampson_10`: directed; 18-18 nodes, 39-58 edges.
- **Sizes (element:nodes/edges):** 1:18/55 2:18/57 3:18/56 4:18/47 5:18/54 6:18/58 7:18/53 8:18/50 9:18/39 10:18/41
- **Description:** Sampson recorded the social interactions among a group of monks while resident as an experimenter on vision, and collected numerous sociometric rankings. During his stay, a political "crisis in the cloister" resulted in the expulsion of four monks (Nos. 2, 3, 17, and 18) and the voluntary departure of several others - most immediately, Nos. 1, 7, 14, 15, and 16. (In the end, only 5, 6, 9, and 11 remained). Most of the present data are retrospective, collected after the breakup occurred. They concern a period during which a new cohort entered the monastery near the end of the study but before the major conflict began. The exceptions are "liking" data gathered at three times: SAMPLK1 to SAMPLK3 - that reflect changes in group sentiment over time (SAMPLK3 was collected in the same wave as the data described below). Information about the senior monks was not included. Four relations are coded, with separate matrices for positive and negative ties on the relation. Each member ranked only his top three choices on that tie. The relations are esteem (SAMPES) and disesteem (SAMPDES), liking (SAMPLK) and disliking (SAMPDLK), positive influence (SAMPIN) and negative influence (SAMPNIN), praise (SAMPPR) and blame (SAMPNPR). In all rankings 3 indicates the highest or first choice and 1 the last choice. (Some subjects offered tied ranks for their top four choices).
- **Source:** http://moreno.ss.uci.edu/data#sampson
- **References:** Breiger R., Boorman S. and Arabie P. (1975). An algorithm for clustering relational data with applications to social network analysis and comparison with multidimensional scaling. \*Journal of Mathematical Psychology\*, 12, 328-383. Sampson, S. (1969). Crisis in a cloister. Unpublished doctoral dissertation, Cornell University.
- **Load:** `nwwebuse schoch sampson`

### sheep: Bighorn Sheep Dominance
{: #sheep }
- **Network:** `sheep`: directed, valued; 28 nodes, 250 edges.
- **Description:** Data record wins and losses for 28 female bighorn sheep observed on the National Bison Range in 1984. the weight of a tie from a to b is the number of occasions on which a was observed dominating b. Ages are listed, but those assigned an age of 9 are at least 9 years old; they may be older.
- **Source:** http://moreno.ss.uci.edu/data.html#sheep
- **References:** Christine Hass, "Social status in female bighorn sheep (Ovis canadensis): expression, development and reproductive correlates." \*Journal of the Zoological Society of London\*, 1991, 225: 509-523.Station, Technical Bulletin 73.
- **Load:** `nwwebuse schoch sheep`

### sn_auth: Social Networks Coauthors
{: #sn_auth }
- **Network:** `sn_auth`: undirected, valued; 475 nodes, 625 edges.
- **Description:** Chris McCarty prepared a data set for the 2008 INSNA meeting in St. Pete. He recorded all the coauthorships in the Social Networks journal from the beginning to provide a network of networkers. The result was a t-shirt with a graphic design that was sold at the meeting. After the meeting, Lin Freeman cleaned the data set and made it available on his website. It takes the form of a matrix that records coauthorship among 475 authors who were involved in the production of 295 articles. Cell entries report the number of coaurherships displayed by pairs of authors.
- **Source:** http://moreno.ss.uci.edu/data#auth
- **Load:** `nwwebuse schoch sn_auth`

### southern_women: Davis - Southern Women
{: #southern_women }
- **Network:** `southern_women`: two-mode; 32 nodes, 89 edges (modes: 18 + 14).
- **Description:** These data were collected by Davis et al. in the 1930s. They represent observed attendance at 14 small social events by 18 Southern women.
- **Source:** http://moreno.ss.uci.edu/data.html#davis
- **References:** Breiger R. (1974). The duality of persons and groups. \*Social Forces\*, 53, 181-190. Davis, A. et al. (1941). Deep South. Chicago: University of Chicago Press.
- **Load:** `nwwebuse schoch southern_women`

### surfersb: Windsurfers (Interactions)
{: #surfersb }
- **Network:** `surfersb`: undirected, valued, loops; 43 nodes, 378 edges.
- **Description:** This was a study of windsurfers on a beach in southern California during the fall of 1986. The windsurfing community was fairly clearly divided into at least two sub-communities. Members of each community seemed, to some degree, to limit their interaction to fellow group members. Contacts between members of the two groups occurred, but these were less frequent. Observations of 43 individuals were made for 31 days. All interpersonal contacts among collections of these individuals were recorded.
- **Source:** http://moreno.ss.uci.edu/data.html#beach
- **References:** L. C. Freeman, S. C. Freeman and A. G. Michaelson "On Human Social Intelligence." \*Journal of Social and Biological Structures\*, 11, 1988, 415-425. L. C. Freeman, S. C. Freeman and A. G. Michaelson "How Humans See Social Groups: A Test of the Sailer-Gaulin Models." \*Journal of Quantitative Anthropology\*, 1, 1989, 229-238.
- **Load:** `nwwebuse schoch surfersb`

### surfersc: Windsurfers (Closeness)
{: #surfersc }
- **Network:** `surfersc`: undirected, valued; 43 nodes, 897 edges.
- **Description:** This was a study of windsurfers on a beach in southern California during the fall of 1986. The windsurfing community was fairly clearly divided into at least two sub-communities. Members of each community seemed, to some degree, to limit their interaction to fellow group members. Contacts between members of the two groups occurred, but these were less frequent. Observations of 43 individuals were made for 31 days. All interpersonal contacts among collections of these individuals were recorded (see \[surfersb\]). Then all 43 individuals were interviewed following the end of observation. Data on each individual's perception of social affiliations were collected. The perceptual data were generated by asking each subject to perform a sequence of card sorting tasks that assigned an index of the perceived closeness of every individual on the beach to each of the other individuals.
- **Source:** http://moreno.ss.uci.edu/data.html#beach
- **References:** L. C. Freeman, S. C. Freeman and A. G. Michaelson "On Human Social Intelligence." \*Journal of Social and Biological Structures\*, 11, 1988, 415-425. L. C. Freeman, S. C. Freeman and A. G. Michaelson "How Humans See Social Groups: A Test of the Sailer-Gaulin Models." \*Journal of Quantitative Anthropology\*, 1, 1989, 229-238.
- **Load:** `nwwebuse schoch surfersc`

### tailor_social: Kapferer - Tailor-Shop (social)
{: #tailor_social }
- **Network:** `tailor_social`: undirected, edge time stamps; 39 nodes, 278 edges.
- **Description:** Bruce Kapferer (1972) observed interactions in a tailor shop in Zambia (then Northern Rhodesia) over a period of ten months. His focus was the changing patterns of alliance among workers during extended negotiations for higher wages. Kapferer recorded two two different types of interaction, recorded at two different times (seven months apart) over a period of one month. This network includes the"sociational" (friendship, socioemotional) interactions. The data are particularly interesting since an abortive strike occurred after the first set of observations, and a successful strike took place after the second.
- **Source:** http://moreno.ss.uci.edu/data#kaptail
- **References:** Kapferer B. (1972). Strategy and transaction in an African factory. Manchester: Manchester University Press.
- **Load:** `nwwebuse schoch tailor_social`

### tailor_work: Kapferer - Tailor-Shop (work)
{: #tailor_work }
- **Network:** `tailor_work`: directed, edge time stamps; 39 nodes, 211 edges.
- **Description:** Bruce Kapferer (1972) observed interactions in a tailor shop in Zambia (then Northern Rhodesia) over a period of ten months. His focus was the changing patterns of alliance among workers during extended negotiations for higher wages. Kapferer recorded two two different types of interaction, recorded at two different times (seven months apart) over a period of one month. This network includes the"instrumental" (work- and assistance-related) interactions at the two times The data are particularly interesting since an abortive strike occurred after the first set of observations, and a successful strike took place after the second.
- **Source:** http://moreno.ss.uci.edu/data#kaptail
- **References:** Kapferer B. (1972). Strategy and transaction in an African factory. Manchester: Manchester University Press.
- **Load:** `nwwebuse schoch tailor_work`

### taro: Taro Exchange
{: #taro }
- **Network:** `taro`: undirected; 22 nodes, 39 edges.
- **Description:** These data represent the relation of gift-giving (taro exchange) among 22 households in a Papuan village. Hage & Harary (1983) used them to illustrate a graph hamiltonian cycle. Schwimmer points out how these ties function to define the appropriate persons to mediate the act of asking for or receiving assistance among group members.
- **Source:** http://moreno.ss.uci.edu/data#taro
- **References:** Hage P. and Harary F. (1983). Structural models in anthropology. Cambridge: Cambridge University Press. Schwimmer E. (1973). Exchange in the social structure of the Orokaiva. New York: St Martins.
- **Load:** `nwwebuse schoch taro`

### train: Madrid Train Bombing
{: #train }
- **Network:** `train`: undirected, valued, multiple edges; 70 nodes, 486 edges.
- **Description:** Jose A. Rodriguez of the University of Barcelona created a network of the individuals involved in the bombing of commuter trains in Madrid on March 11, 2004. Rodriguez used press accounts in the two major Spanish daily newspapers (El Pais and El Mundo) to reconstruct the terrorist network. The names included were of those people suspected of having participated and their relatves. Four relations were recorded: Rodriguez specified 4 kinds of ties linking theindividuals involved: 1. Trust--friendship (contact, kinship, links in the telephone center). 2. Ties to Al Qaeda and to Osama Bin Laden. 3. Co-participation in training camps and/or wars. 4. Co-participation in previous terrorist Attacks (Sept 11, Casablanca). These four were added together providing a "strength of connection" index that ranges from 1 to 4. }
- **Source:** http://moreno.ss.uci.edu/data#train
- **References:** Hayes, Brian. 2006. "Connecting the dots." \*American Scientist\* 94 (5):400-404.
- **Load:** `nwwebuse schoch train`

### wiring: Bank Wiring Room
{: #wiring }
- **Network:** `wiring`: undirected; 14 nodes, 32 edges.
- **Description:** These are the observational data on 14 Western Electric (Hawthorne Plant) employees from the bank wiring room first presented in Roethlisberger & Dickson (1939). The data are better known through a scrutiny made of the interactions in Homans (1950), and the CONCOR analyses presented in Breiger et al (1975). The employees worked in a single room and include two inspectors (I1 and I3), three solderers (S1, S2 and S3), and nine wiremen or assemblers (W1 to W9). The interaction categories include: RDGAM, participation in horseplay; RDCON, participation in arguments about open windows; RDPOS, friendship; RDNEG, antagonistic (negative) behavior; RDHLP, helping others with work; and RDJOB, the number of times workers traded job assignments. \*\*The dataset only includes the positive and negative ties, making it a signed network\*\*
- **Source:** http://moreno.ss.uci.edu/data#wiring
- **References:** Breiger R., Boorman S. and Arabie P. (1975). An algorithm for clustering relational data with applications to social network analysis and comparison with multidimensional scaling. \*Journal of Mathematical Psychology\*, 12, 328-383. Homans G. (1950). The human group. New York: Harcourt-Brace. Roethlisberger F. and Dickson W. (1939). Management and the worker. Cambridge: Cambridge University Press.
- **Load:** `nwwebuse schoch wiring`

## KONECT networks

### arenas_email: Arenas Email
{: #arenas_email }
- **Network:** `arenas_email`: undirected; 1133 nodes, 5451 edges.
- **Description:** This is the email communication network at the University Rovira i Virgili in Tarragona in the south of Catalonia in Spain. Nodes are users and each edge represents that at least one email was sent. The direction of emails or the number of emails are not stored.
- **Source:** Data downloaded from http://konect.uni-koblenz.de/ orginaly from http://deim.urv.cat/~aarenas/data/welcome.htm
- **References:** Jerome Kunegis. KONECT - The Koblenz Network Collection. In Proc. Int. Web Observatory Workshop, pages 1343-1350, 2013. Roger Guimerà, Leon Danon, Albert Díaz-Guilera, Francesc Giralt, and Alex Arenas. Self-similar community structure in a network of human interactions. Phys. Rev. E, 68(6):065103, 2003.
- **Load:** `nwwebuse schoch arenas_email`

### arenas_meta: Arenas Metabolic
{: #arenas_meta }
- **Network:** `arenas_meta`: undirected, multiple edges, loops; 453 nodes, 4596 edges.
- **Description:** This is the metabolic network of the roundworm Caenorhabditis elegans. Nodes are metabolites (e.g., proteins), and edges are interactions between them. Since a metabolite can iteract with itself, the network contains loops. The interactions are undirected. There may be multiple interactions between any two metabolites.
- **Source:** Data downloaded from http://konect.uni-koblenz.de/ orginaly from http://deim.urv.cat/~aarenas/data/welcome.htm
- **References:** Jerome Kunegis. KONECT - The Koblenz Network Collection. In Proc. Int. Web Observatory Workshop, pages 1343-1350, 2013. Jordi Duch and Alex Arenas. Community detection in complex networks using extremal optimization. Phys. Rev. E, 72(2):027104, 2005.
- **Load:** `nwwebuse schoch arenas_meta`

### brunson_club_membership: Brunson Club Membership
{: #brunson_club_membership }
- **Network:** `brunson_club_membership`: two-mode; 40 nodes, 95 edges (modes: 25 + 15).
- **Description:** This bipartite network contains membership information of corporate executive officers in social organisations such as clubs and boards. Left nodes represent persons and right nodes represent social organisations. An edge between a person and a social organization shows that the person has a memberstatus.
- **Source:** Data downloaded from http://konect.uni-koblenz.de/ orginaly from https://github.com/corybrunson/triadic
- **References:** Jerome Kunegis. KONECT - The Koblenz Network Collection. In Proc. Int. Web Observatory Workshop, pages 1343-1350, 2013. Katherine Faust. Centrality in affiliation networks. Social Networks, 19(2):157--191, 1997.
- **Load:** `nwwebuse schoch brunson_club_membership`

### brunson_corporate_leadership: Brunson Corporate Leadership
{: #brunson_corporate_leadership }
- **Network:** `brunson_corporate_leadership`: two-mode; 44 nodes, 99 edges (modes: 20 + 24).
- **Description:** This bipartite network contains person–company leadership information between companies and 20 corporate directors. The data was collected in 1962. Left nodes represent persons and right nodes represent companies. An edge between a person and a company shows that the person had a leadership position in that company.
- **Source:** Data downloaded from http://konect.uni-koblenz.de/ orginaly from https://github.com/corybrunson/triadic
- **References:** Jerome Kunegis. KONECT - The Koblenz Network Collection. In Proc. Int. Web Observatory Workshop, pages 1343-1350, 2013. Roy Barnes and Tracy Burkett. Structural redundancy and multiplicity in corporate networks. International Network for Social Network Analysis, 30(2), 2010.
- **Load:** `nwwebuse schoch brunson_corporate_leadership`

### brunson_revolution: Brunson Revolution
{: #brunson_revolution }
- **Network:** `brunson_revolution`: two-mode; 141 nodes, 160 edges (modes: 136 + 5).
- **Description:** This bipartite network contains membership information of 136 people in 5 organisations dating back to the time before the American Revolution. The list includes well-known people such as the American activist Paul Revere. Left nodes represent persons and right nodes represent organisations. An edge between a person and an organization shows that the person was a member of the organisation.
- **Source:** Data downloaded from http://konect.uni-koblenz.de/ orginaly from https://github.com/corybrunson/triadic
- **References:** Jerome Kunegis. KONECT - The Koblenz Network Collection. In Proc. Int. Web Observatory Workshop, pages 1343-1350, 2013. NA
- **Load:** `nwwebuse schoch brunson_revolution`

### brunson_south_africa: Brunson South Africa
{: #brunson_south_africa }
- **Network:** `brunson_south_africa`: two-mode; 11 nodes, 13 edges (modes: 6 + 5).
- **Description:** This bipartite network contains person–company shared leadership relations of "the five most representative companies" that are claimed to represent "the small inner ring of South African Finance". Left nodes represent persons and right nodes represent companies. An edge between a person and a company shows that the person had a leadership position in that company.
- **Source:** Data downloaded from http://konect.uni-koblenz.de/ orginaly from https://github.com/corybrunson/triadic
- **References:** Jerome Kunegis. KONECT - The Koblenz Network Collection. In Proc. Int. Web Observatory Workshop, pages 1343-1350, 2013. John Atkinson Hobson. The Evolution of Modern Capitalism: A Study of Machine Production. The Walter Scott publishing co., ltd., 1919.
- **Load:** `nwwebuse schoch brunson_south_africa`

### chicagoroad: Road Transportation Network Chicago
{: #chicagoroad }
- **Network:** `chicagoroad`: undirected; 1467 nodes, 1298 edges.
- **Description:** This is the road transportation network of the Chicago region (USA). Nodes are transport nodes, and edges are connections.
- **Source:** Data downloaded from http://konect.uni-koblenz.de/ orginaly from http://www.bgu.ac.il/~bargera/tntp/
- **References:** Jerome Kunegis. KONECT - The Koblenz Network Collection. In Proc. Int. Web Observatory Workshop, pages 1343-1350, 2013. R. W. Eash, K. S. Chon, Y. J. Lee, and D. E. Boyce. Equilibrium traffic assignment on an aggregated highway network for sketch planning. Transportation Research Record, 994:30--37, 1983.
- **Load:** `nwwebuse schoch chicagoroad`

### dnc_corecipient: DNC Email (Corecipients)
{: #dnc_corecipient }
- **Network:** `dnc_corecipient`: undirected, valued, multiple edges; 906 nodes, 12085 edges.
- **Description:** This is the undirected network of people having received the same email in the 2016 Democratic National Committee email leak. The Democratic National Committee (DNC) is the formal governing body for the United States Democratic Party. A dump of emails of the DNC was leaked in 2016, and this dataset contains persons from that dump as nodes, and an edge when two persons received the same email, i.e., when two persons were on the recipient list of the same email. Multiple edges indicate multiple emails.
- **Source:** Data downloaded from http://konect.uni-koblenz.de/ orginaly from http://www.rene-pickhardt.de/extracting-2-social-network-graphs-from-the-democratic-national-committee-email-corpus-on-wikileaks/
- **References:** Jerome Kunegis. KONECT - The Koblenz Network Collection. In Proc. Int. Web Observatory Workshop, pages 1343-1350, 2013.
- **Load:** `nwwebuse schoch dnc_corecipient`

### dnc_temporalGraph: DNC Email (Temporal)
{: #dnc_temporalGraph }
- **Network:** `dnc_temporalGraph`: directed, multiple edges, edge time stamps; 1891 nodes, 37421 edges.
- **Description:** This is the directed network of emails in the 2016 Democratic National Committee email leak. The Democratic National Committee (DNC) is the formal governing body for the United States Democratic Party. A dump of emails of the DNC was leaked in 2016. Nodes in the network correspond to persons in the dataset. A directed edge in the dataset denotes that a person has sent an email to another person. Since an email can have any number of recipients, a single email is mapped to multiple edges in this dataset, resulting in the number of edges in this network being about twice the number of emails in the dump.
- **Source:** Data downloaded from http://konect.uni-koblenz.de/ orginaly from http://www.rene-pickhardt.de/extracting-2-social-network-graphs-from-the-democratic-national-committee-email-corpus-on-wikileaks/
- **References:** Jerome Kunegis. KONECT - The Koblenz Network Collection. In Proc. Int. Web Observatory Workshop, pages 1343-1350, 2013.
- **Load:** `nwwebuse schoch dnc_temporalGraph`

### euroroad: Road network Europe
{: #euroroad }
- **Network:** `euroroad`: undirected; 1174 nodes, 1417 edges.
- **Description:** This is the international E-road network, a road network located mostly in Europe. The network is undirected; nodes represent cities and an edge between two nodes denotes that they are connected by an E-road.
- **Source:** Data downloaded from http://konect.uni-koblenz.de/ orginaly from http://lovro.lpt.fri.uni-lj.si/support.jsp
- **References:** Jerome Kunegis. KONECT - The Koblenz Network Collection. In Proc. Int. Web Observatory Workshop, pages 1343-1350, 2013. Lovro Subelj and Marko Bajec. Robust network community detection using balanced propagation. Eur. Phys. J. B, 81(3):353--362, 2011.
- **Load:** `nwwebuse schoch euroroad`

### f2f_hypertext: Face-2-face contacts at Hypertext
{: #f2f_hypertext }
- **Network:** `f2f_hypertext`: undirected, multiple edges, edge time stamps; 113 nodes, 20818 edges.
- **Description:** This is the network of face-to-face contacts of the attendees of the ACM Hypertext 2009 conference. The ACM Conference on Hypertext and Hypermedia 2009 (HT 2009, http://www.ht2009.org/) was held in Turin, Italy over three days from June 29 to July 1, 2009. In the network, a node represents a conference visitor, and an edge represents a face-to-face contact that was active for at least 20 seconds. Multiple edges denote multiple contacts. Each edge is annotated with the time at which the contact took place.
- **Source:** Data downloaded from http://konect.uni-koblenz.de/ orginaly from http://www.sociopatterns.org/
- **References:** Jerome Kunegis. KONECT - The Koblenz Network Collection. In Proc. Int. Web Observatory Workshop, pages 1343-1350, 2013. Lorenzo Isella, Juliette Stehlé, Alain Barrat, Ciro Cattuto, Jean-François Pinton, and Wouter Van den Broeck. What's in a crowd? analysis of face-to-face behavioral networks. J. of Theoretical Biology, 271(1):166--180, 2011.
- **Load:** `nwwebuse schoch f2f_hypertext`

### f2f_infectious: Face-2-face contacts at Infectious
{: #f2f_infectious }
- **Network:** `f2f_infectious`: undirected, multiple edges, edge time stamps; 410 nodes, 17298 edges.
- **Description:** This network describes the face-to-face behavior of people during the exhibition INFECTIOUS: STAY AWAY in 2009 at the Science Gallery in Dublin. Nodes represent exhibition visitors; edges represent face-to-face contacts that were active for at least 20 seconds. Multiple edges between two nodes are possible and denote multiple contacts. The network contains the data from the day with the most interactions.
- **Source:** Data downloaded from http://konect.uni-koblenz.de/ orginaly from http://www.sociopatterns.org/
- **References:** Jerome Kunegis. KONECT - The Koblenz Network Collection. In Proc. Int. Web Observatory Workshop, pages 1343-1350, 2013. Lorenzo Isella, Juliette Stehlé, Alain Barrat, Ciro Cattuto, Jean-François Pinton, and Wouter Van den Broeck. What's in a crowd? analysis of face-to-face behavioral networks. J. of Theoretical Biology, 271(1):166--180, 2011.
- **Load:** `nwwebuse schoch f2f_infectious`

### maayan_faa: FAA Preferred Routes
{: #maayan_faa }
- **Network:** `maayan_faa`: directed; 1226 nodes, 2613 edges.
- **Description:** This network was constructed from the USA's FAA (Federal Aviation Administration) National Flight Data Center (NFDC), Preferred Routes Database. Nodes in this network represent airports or service centers and links are created from strings of preferred routes recommended by the NFDC.
- **Source:** Data downloaded from http://konect.uni-koblenz.de/ orginaly from http://research.mssm.edu/maayan/datasets/qualitative\_networks.shtml
- **References:** Jerome Kunegis. KONECT - The Koblenz Network Collection. In Proc. Int. Web Observatory Workshop, pages 1343-1350, 2013. Federal Aviation Administration. Air traffic control system command center. http://www.fly.faa.gov/.
- **Load:** `nwwebuse schoch maayan_faa`

### maayan_pdzbase: Maayan Pdzbase
{: #maayan_pdzbase }
- **Network:** `maayan_pdzbase`: undirected, loops; 212 nodes, 244 edges.
- **Description:** This is a network of protein–protein interactions from PDZBase.
- **Source:** Data downloaded from http://konect.uni-koblenz.de/ orginaly from http://research.mssm.edu/maayan/datasets/qualitative\_networks.shtml
- **References:** Jerome Kunegis. KONECT - The Koblenz Network Collection. In Proc. Int. Web Observatory Workshop, pages 1343-1350, 2013. Thijs Beuming, Lucy Skrabanek, Masha Y. Niv, Piali Mukherjee, and Harel Weinstein. PDZBase: A protein--protein interaction database for PDZ-domains. Bioinformatics, 21(6):827--828, 2005.
- **Load:** `nwwebuse schoch maayan_pdzbase`

### petster: Petster Friendships
{: #petster }
- **Network:** `petster`: undirected; 1858 nodes, 12534 edges.
- **Description:** This Network contains friendships between users of the website hamsterster.com. The network contains many vertex attributes about the pet.
- **Source:** Data downloaded from http://konect.uni-koblenz.de/
- **References:** Jerome Kunegis. KONECT - The Koblenz Network Collection. In Proc. Int. Web Observatory Workshop, pages 1343-1350, 2013.
- **Load:** `nwwebuse schoch petster`

### powergrid: Powergrid
{: #powergrid }
- **Network:** `powergrid`: undirected; 4941 nodes, 6594 edges.
- **Description:** This undirected network contains information about the power grid of the Western States of the United States of America. An edge represents a power supply line. A node is either a generator, a transformator or a substation.
- **Source:** Data downloaded from http://konect.uni-koblenz.de/ orginaly from http://toreopsahl.com/datasets/#uspowergrid
- **References:** Jerome Kunegis. KONECT - The Koblenz Network Collection. In Proc. Int. Web Observatory Workshop, pages 1343-1350, 2013. Duncan J. Watts and Steven H. Strogatz. Collective dynamics of \`small-world' networks. Nature, 393(1):440--442, 1998.
- **Load:** `nwwebuse schoch powergrid`

### radoslaw_email: Radoslaw - Email Network
{: #radoslaw_email }
- **Network:** `radoslaw_email`: directed, valued, loops; 167 nodes, 5784 edges.
- **Description:** This is the internal email communication network between employees of a mid-sized manufacturing company. The network is directed and nodes represent employees. The left node represents the sender and the right node represents the recipient. Edges between two nodes are individual emails.
- **Source:** Data downloaded from http://konect.uni-koblenz.de/ orginaly from http://www.ii.pwr.wroc.pl/~michalski/index.php?content=datasets#manufacturing
- **References:** Jerome Kunegis. KONECT - The Koblenz Network Collection. In Proc. Int. Web Observatory Workshop, pages 1343-1350, 2013. Radoslaw Michalski, Sebastian Palus, and Przemyslaw Kazienko. Matching organizational structure and social network extracted from email communication. In Lecture Notes in Business Information Processing, volume 87, pages 197--206. Springer Berlin Heidelberg, 2011.
- **Load:** `nwwebuse schoch radoslaw_email`

### ucforum: UC forum (2-mode)
{: #ucforum }
- **Network:** `ucforum`: two-mode, valued; 1421 nodes, 7089 edges (modes: 899 + 522).
- **Description:** This bipartite network contains user posts to forums. The users are students at the University of California, Irvine. An edge represents the number of times a (P)erson posted in a (F)orum.
- **Source:** Data downloaded from http://konect.uni-koblenz.de/ orginaly from http://toreopsahl.com/datasets/#online\_forum\_network
- **References:** Jerome Kunegis. KONECT - The Koblenz Network Collection. In Proc. Int. Web Observatory Workshop, pages 1343-1350, 2013. Tore Opsahl and Pietro Panzarasa. Triadic closure in two-mode networks: Redefining the global and local clustering coefficients. Social Networks, 34, 2011.
- **Load:** `nwwebuse schoch ucforum`

### ucsocial: UC forum (messages sent)
{: #ucsocial }
- **Network:** `ucsocial`: directed, valued; 1899 nodes, 20296 edges.
- **Description:** This directed network contains sent messages between the users of an online community of students from the University of California, Irvine. A node represents a user. A directed edge represents a sent message. Multiple edges denote multiple messages.
- **Source:** Data downloaded from http://konect.uni-koblenz.de/ orginaly from http://toreopsahl.com/datasets/#online\_social\_network
- **References:** Jerome Kunegis. KONECT - The Koblenz Network Collection. In Proc. Int. Web Observatory Workshop, pages 1343-1350, 2013. Tore Opsahl and Pietro Panzarasa. Clustering in weighted networks. Social Networks, 31(2):155--163, 2009.
- **Load:** `nwwebuse schoch ucsocial`

### unicodelang: Unicodelang
{: #unicodelang }
- **Network:** `unicodelang`: two-mode, valued; 868 nodes, 38 edges (modes: 254 + 614).
- **Description:** This bipartite network denotes which languages are spoken in which countries. Nodes are countries and languages; edge weights denote the proportion (between zero and one) of the population of a given country speaking a given language. To quote the Unicode data description: "The main goal is to provide approximate figures for the literate, functional population for each language in each territory: that is, the population that is able to read and write each language, and is comfortable enough to use it with computers."
- **Source:** Data downloaded from http://konect.uni-koblenz.de/ orginaly from http://www.unicode.org/cldr/charts/25/supplemental/territory\_language\_information.html
- **References:** Jerome Kunegis. KONECT - The Koblenz Network Collection. In Proc. Int. Web Observatory Workshop, pages 1343-1350, 2013.
- **Load:** `nwwebuse schoch unicodelang`

### usa_borders: USA Bordering States
{: #usa_borders }
- **Network:** `usa_borders`: undirected; 49 nodes, 107 edges.
- **Description:** These are the 48 contiguous states and the District of Columbia of the United States of America (the USA). They include all states except the states of Alaska and Hawaii, which are not connected by land with the other states, and include the District of Columbia (DC). An edge denotes that two states share a border. The US states in the configuration given by this dataset exist since February 14, 1912, when Arizona was admitted as the 48th state, and is current as of 2014. The states of Alaska and Hawaii were admitted as the 49th and 50th states in 1959, but are not contiguous with the other states, and are not reflected in this dataset.
- **Source:** Data downloaded from http://konect.uni-koblenz.de/ orginaly from http://www-cs-faculty.stanford.edu/~uno/sgb.html
- **References:** Jerome Kunegis. KONECT - The Koblenz Network Collection. In Proc. Int. Web Observatory Workshop, pages 1343-1350, 2013. Donald E. Knuth. The Art of Computer Programming, Volume 4, Fascicle 0: Introduction to Combinatorial and Boolean Functions. Addison-Wesley, 2008.
- **Load:** `nwwebuse schoch usa_borders`

### usflights: US Flights 2010
{: #usflights }
- **Network:** `usflights`: directed, valued; 1574 nodes, 28236 edges.
- **Description:** This is the directed network of flights between US airports in 2010. Each edge represents a connection from one airport to another, and the weight of an edge shows the number of flights on that connection in the given direction, in 2010.
- **Source:** Data downloaded from http://konect.uni-koblenz.de/ orginaly from http://toreopsahl.com/datasets/#usairports
- **References:** Jerome Kunegis. KONECT - The Koblenz Network Collection. In Proc. Int. Web Observatory Workshop, pages 1343-1350, 2013. Tore Opsahl. Why anchorage is not (that) important: Binary ties and sample selection, 2011.
- **Load:** `nwwebuse schoch usflights`

## Miscellaneous networks

### adjnoun: Words in David Copperfield
{: #adjnoun }
- **Network:** `adjnoun`: undirected; 112 nodes, 425 edges.
- **Description:** A network of common adjective and noun adjacencies for the novel "David Copperfield" by Charles Dickens, as described by M. Newman. Nodes represent the most commonly occurring adjectives and nouns in the book. Edges connect any pair of words that occur in adjacent position in the text of the book.
- **Source:** http://www-personal.umich.edu/~mejn/netdata/
- **References:** Newman, Mark EJ. "Finding community structure in networks using the eigenvectors of matrices." \*Physical Review E\* 74.3 (2006): 036104.
- **Load:** `nwwebuse schoch adjnoun`

### atp: ATP Tennis (1968-2021)
{: #atp }
- **Networks:** list of 54 networks `atp_1` ... `atp_54`: directed, valued, multiple edges, loops (types differ between the networks); 345-597 nodes, 1213-3892 edges.
- **Sizes (element:nodes/edges):** 1:497/1213 2:446/1418 3:451/1650 4:459/2580 5:504/2767 6:592/3653 7:595/3735 8:535/3804 9:553/3690 10:524/3842 11:509/3655 12:572/3805 13:582/3778 14:573/3691 15:554/3892 16:532/3440 17:495/3093 18:513/3269 19:510/3124 20:523/3372 21:596/3608 22:597/3477 23:405/3195 24:542/3588 25:509/3633 26:498/3726 27:520/3744 28:496/3616 29:502/3604 30:499/3463 31:497/3442 32:480/3189 33:486/3221 34:479/3164 35:497/3094 36:517/3087 37:505/3138 38:492/3122 39:524/3125 40:488/3013 41:493/2973 42:464/2903 43:482/2908 44:459/2872 45:457/2873 46:453/2801 47:428/2751 48:430/2781 49:431/2795 50:438/2746 51:419/2761 52:364/2665 53:345/1411 54:393/2609
- **Description:** The dataset includes all ATP tennis matches from 1968-2021 The networks are directed pointing from the loser to the winner. Each network contains the following attributes: Edge attributes: - surface: on which surface the match(es) took place (e.g. "Hard", "Grass", "Clay") - weight: number of times Player A lost to Player B on surface X Vertex attributes: - hand: if player is (L)eft or (R)ight handed (or (U)nknown) - age: age of player during the season - country: home country of player } Check out https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0017249 for a potential use case.
- **Source:** Networks constructed from data that was gathered and compiled by Jeff Sackmann (https://github.com/JeffSackmann). Please give credit to him if you use this data.
- **Load:** `nwwebuse schoch atp`

### cent_lit: Centrality literature network
{: #cent_lit }
- **Network:** `cent_lit`: directed; 129 nodes, 613 edges.
- **Description:** In 1979, Linton Freeman published a paper which defined several kinds of centrality. His typology has become the standard for network analysis. Freeman, however, was not the first to publish on centrality in networks. His paper is part of a discussion which dates back to the 1940s. The network shows the papers that discuss network centrality and their cross- references until 1979. Arcs represent citations; they point from the cited paper to the citing paper. In principle, papers can only cite papers which appeared earlier, so the network is acyclic. Arcs never point back to older papers just like parents cannot be younger than their children. However, there are usually some exceptions in a citation network: papers which cite one another, e.g., papers appearing at about the same time and written by one author. We eliminated these exceptions by shrinking the papers by an author which are connected by cyclic citations. In the centrality literature network, we used the latter approach (e.g., two publications by Gilch in 1954 are shrunk to one paper #GilchSW-54).
- **Source:** https://sites.google.com/site/ucinetsoftware/datasets/centralityliteraturenetwork
- **References:** N.P. Hummon, P. Doreian, & L.C. Freeman, 'Analyzing the structure of the centrality-productivity literature created between 1948 and 1979' (in: Knowledge-Creation Diffusion Utilization, 11 (1990), 459-480). W. de Nooy, A. Mrvar, & V. Batagelj, Exploratory Social Network Analysis with Pajek (Cambridge: Cambridge University Press, 2004), Chapter 11.
- **Load:** `nwwebuse schoch cent_lit`

### clique_graph: Illustrating cliques
{: #clique_graph }
- **Network:** `clique_graph`: undirected; 30 nodes, 47 edges.
- **Description:** A small graph to illustrate the concept of cliques and k-cores.
- **Load:** `nwwebuse schoch clique_graph`

### coleman: Coleman's High School Friendship Data
{: #coleman }
- **Networks:** list of 2 networks `coleman_1` ... `coleman_2`: directed; 73-73 nodes, 243-263 edges.
- **Sizes (element:nodes/edges):** 1:73/243 2:73/263
- **Description:** James Coleman (1964) reports research on self-reported friendship ties among 73 boys in a small high school in Illinois over the 1957-1958 academic year. Networks of reported ties for all 73 informants are provided for two time points (fall and spring).
- **References:** Coleman, J. S. (1964). Introduction to Mathematical Sociology. New York: Free Press.
- **Load:** `nwwebuse schoch coleman`

### core_graph: Illustrating core-periphery
{: #core_graph }
- **Network:** `core_graph`: undirected; 100 nodes, 578 edges.
- **Description:** A graph to illustrate the concept of core-periphery.
- **Load:** `nwwebuse schoch core_graph`

### cosponsor: Senat 2015 Bill cosponsorship
{: #cosponsor }
- **Network:** `cosponsor`: two-mode; 3984 nodes, 26392 edges (modes: 110 + 3874).
- **Description:** Bill cosponsorship network for the 115th Senate obtained from govtrack.us
- **Load:** `nwwebuse schoch cosponsor`

### football_triad: Simplified football results
{: #football_triad }
- **Networks:** list of 112 networks `football_triad_1` ... `football_triad_112`: directed; 6-28 nodes, 20-273 edges.
- **Sizes (element:nodes/edges):** 1:10/73 2:16/140 3:12/27 4:8/39 5:10/53 6:28/273 7:6/28 8:8/45 9:10/48 10:12/73 11:16/136 12:10/50 13:8/33 14:16/132 15:20/229 16:16/127 17:16/133 18:12/77 19:18/175 20:16/141 21:16/145 22:8/35 23:7/31 24:13/110 25:10/41 26:20/221 27:10/57 28:16/141 29:10/62 30:8/33 31:12/83 32:20/219 33:12/63 34:10/68 35:18/180 36:10/59 37:16/127 38:10/42 39:14/102 40:16/110 41:10/48 42:10/53 43:12/71 44:10/54 45:18/208 46:10/69 47:20/219 48:18/195 49:12/73 50:12/99 51:12/95 52:12/83 53:8/40 54:8/37 55:8/33 56:8/45 57:12/71 58:13/87 59:14/104 60:10/49 61:10/72 62:16/133 63:12/84 64:14/103 65:14/102 66:14/105 67:10/62 68:8/42 69:10/43 70:10/69 71:16/142 72:16/152 73:12/80 74:16/135 75:12/79 76:20/171 77:16/137 78:14/108 79:12/75 80:12/98 81:6/23 82:18/184 83:8/26 84:12/81 85:14/109 86:16/136 87:15/98 88:12/89 89:14/103 90:12/98 91:9/45 92:8/44 93:10/46 94:16/127 95:20/222 96:13/90 97:14/94 98:16/134 99:8/35 100:16/127 101:18/183 102:16/135 103:10/53 104:18/184 105:8/44 106:6/20 107:16/136 108:12/75 109:12/94 110:14/108 111:20/216 112:18/165
- **Description:** A list of 112 networks of football leagues. A directed link between team A and B indicates that A won a match against B. Note that there can also be an edge from B to A, since most leagues play a double round robin. For the sake of simplicity, all draws were deleted so that there could also be null ties between two teams if both games ended in a draw. The data can be used to experiment with the triad census
- **Source:** soccerverse.com
- **Load:** `nwwebuse schoch football_triad`

### glasgow129: Teenage Friends and Lifestyle Study data
{: #glasgow129 }
- **Networks:** list of 3 networks `glasgow129_1` ... `glasgow129_3`: directed, loops (types differ between the networks); 129-129 nodes, 445-464 edges.
- **Sizes (element:nodes/edges):** 1:129/449 2:129/445 3:129/464
- **Description:** longitudinal, 3 waves, networks and behavior. For the codebook, see the link provided as source. Only sex.F was recoded to F/M.
- **Source:** Data downloaded from https://www.stats.ox.ac.uk/~snijders/siena/Glasgow\_data.htm
- **Load:** `nwwebuse schoch glasgow129`

### got: Game of Thrones Interactions
{: #got }
- **Networks:** list of 7 networks `got_1` ... `got_7`: undirected, valued; 81-172 nodes, 398-667 edges.
- **Sizes (element:nodes/edges):** 1:127/550 2:129/486 3:124/504 4:172/667 5:119/398 6:143/542 7:81/412
- **Description:** Character Interaction Networks for the HBO Series "Game of Thrones" (Season 1-7). These networks were created by parsing fan-generated scripts from https://genius.com/artists/Game-of-thrones. Pairs of characters are connected by (undirected) edges weighted by the number of interactions. There are five interaction types. Character A and Character B are connected whenever: Character A speaks directly after Character B Character A speaks about Character B Character C speaks about Character A and Character B Character A and Character B are mentioned in the same stage direction Character A and Character B appear in a scene together }
- **Source:** https://networkofthrones.wordpress.com, Downloaded from https://github.com/mathbeveridge/gameofthrones/
- **References:** Andrew Beveridge and Michael Chemers, "The Game of 'The Game of Thrones': Networked Concordances and Fractal Dramaturgy", in: Paola Brembilla and Ilaria De Pacalis (eds.), Reading Contemporary Serial Television Universes: A Narrative Ecosystem Framework, Routledge, 2018.
- **Load:** `nwwebuse schoch got`

### greys: Grey's Anatomy Hook-ups
{: #greys }
- **Network:** `greys`: undirected; 54 nodes, 57 edges.
- **Description:** Network of hook-ups of characters in "Grey's Anatomy".
- **Load:** `nwwebuse schoch greys`

### gss_egor: General Social Survey 2004 Egocentric Network Data
{: #gss_egor }
- **What:** not a network: ego-centered survey data in three tables (ego, alter, aatie). Load: `nwnetworkdata tables gss_egor, table(ego) clear`
- **Description:** A stratified sample of 594 respondents from the 2004 General Social Survey (GSS) containing egocentric network data. The dataset includes information about respondents (egos), their network members (alters), and the relationships between those network members (alter-alter ties). The sample was drawn using stratified random sampling without replacement across five stratification variables: age category (3 levels), race, sex, marital status, and number of alters named.
- **Source:** General Social Survey 2004. NORC at the University of Chicago. Data retrieved from https://gss.norc.org/
- **References:** Smith, Tom W., Michael Davern, Jeremy Freese, and Stephen Morgan. General Social Surveys, 1972-2021. Chicago: NORC, 2022.

### knecht: Knecht's School Data
{: #knecht }
- **Networks:** list of 4 networks `knecht_1` ... `knecht_4`: directed (types differ between the networks); 26-26 nodes, 91-133 edges.
- **Sizes (element:nodes/edges):** 1:26/91 2:26/118 3:26/133 4:26/119
- **Description:** This data is about a friendship network in a Dutch school class. The data were collected between September 2003 and June 2004 by Andrea Knecht, supervised by Chris Baerveldt, at the Department of Sociology of the University of Utrecht (NL). The entire study is reported in Knecht (2008). The 26 students were followed over their first year at secondary school during which friendship networks as well as other data were assessed at four time points at intervals of three months. There were 17 girls and 9 boys in the class, aged 11-13 at the beginning of the school year. Network data were assessed by asking students to indicate up to twelve classmates which they considered good friends. Delinquency is defined as a rounded average over four types of minor delinquency (stealing, vandalism, graffiti, and fighting), measured in each of the four waves of data collection. The five-point scale ranged from \`never' to \`more than 10 times', and the distribution is highly skewed. In a range of 1-5, the mode was 1 at all four waves, the average rose over time from 1.4 to 2.0, and the value 5 was never observed.
- **References:** Andrea Knecht (2006), Networks and actor attributes in early adolescence, Utrecht, The Netherlands Research School ICS, Department of Sociology, Utrecht University
- **Load:** `nwwebuse schoch knecht`

### s50: 50-actor excerpt from the Teenage Friends and Lifestyle Study data
{: #s50 }
- **Networks:** list of 3 networks `s50_1` ... `s50_3`: undirected; 50-50 nodes, 74-81 edges.
- **Sizes (element:nodes/edges):** 1:50/74 2:50/81 3:50/77
- **Description:** longitudinal, 3 waves, networks and behavior
- **Source:** Data downloaded from https://www.stats.ox.ac.uk/~snijders/siena/siena\_datasets.htm
- **Load:** `nwwebuse schoch s50`

### starwars: Star Wars Episode 1-7
{: #starwars }
- **Networks:** list of 7 networks `starwars_1` ... `starwars_7`: undirected, valued; 20-38 nodes, 55-135 edges.
- **Sizes (element:nodes/edges):** 1:38/135 2:33/101 3:24/65 4:21/60 5:21/55 6:20/55 7:27/92
- **Description:** Scene Co-occurrence of Star Wars Characters (Episode 1-7)
- **Source:** Data downloaded from https://github.com/evelinag/StarWars-social-network
- **Load:** `nwwebuse schoch starwars`

### us_flights: Flights within the US
{: #us_flights }
- **Network:** `us_flights`: undirected; 276 nodes, 2682 edges.
- **Description:** A network of flights between US airports
- **Load:** `nwwebuse schoch us_flights`

### wta: WTA Tennis (1968-2021)
{: #wta }
- **Networks:** list of 54 networks `wta_1` ... `wta_54`: directed, valued, multiple edges (types differ between the networks); 152-2513 nodes, 249-18901 edges.
- **Sizes (element:nodes/edges):** 1:236/377 2:167/288 3:181/299 4:152/249 5:178/303 6:187/346 7:192/361 8:189/352 9:196/358 10:220/944 11:247/1286 12:195/1254 13:311/1842 14:259/1776 15:255/1922 16:298/2179 17:289/2165 18:297/2344 19:341/2371 20:379/2631 21:389/2758 22:374/2668 23:322/2386 24:403/2672 25:415/2590 26:450/2722 27:411/2527 28:450/2462 29:506/2642 30:548/2845 31:541/2733 32:530/2735 33:511/2767 34:518/2968 35:493/2996 36:165/364 37:169/407 38:181/535 39:204/1273 40:255/1771 41:286/1866 42:286/2053 43:273/2072 44:284/2053 45:268/2094 46:283/2021 47:277/2126 48:368/2529 49:353/2650 50:356/2714 51:351/2749 52:2513/18901 53:314/1248 54:328/2509
- **Description:** The dataset includes all WTA tennis matches from 1968-2021 The networks are directed pointing from the loser to the winner. Each network contains the following attributes: Edge attributes: - surface: on which surface the match(es) took place (e.g. "Hard", "Grass", "Clay") - weight: number of times Player A lost to Player B on surface X Vertex attributes: - hand: if player is (L)eft or (R)ight handed (or (U)nknown) - age: age of player during the season - country: home country of player } Check out https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0017249 for a potential use case.
- **Source:** Networks constructed from data that was gathered and compiled by Jeff Sackmann (https://github.com/JeffSackmann). Please give credit to him if you use this data.
- **Load:** `nwwebuse schoch wta`

## Movie networks (Harvard Dataverse)

### movie_1: 10 Things I Hate About You
{: #movie_1 }
- **Network:** `movie_1`: undirected, valued; 21 nodes, 68 edges.
- **Description:** Interactions of characters in the movie "10 Things I Hate About You" (1999)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0147800
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_1`

### movie_10: 2012
{: #movie_10 }
- **Network:** `movie_10`: undirected, valued; 66 nodes, 211 edges.
- **Description:** Interactions of characters in the movie "2012" (2009)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1190080
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_10`

### movie_100: Big
{: #movie_100 }
- **Network:** `movie_100`: undirected, valued; 16 nodes, 41 edges.
- **Description:** Interactions of characters in the movie "Big" (1988)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0094737
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_100`

### movie_101: Bear in the Big Blue House
{: #movie_101 }
- **Network:** `movie_101`: undirected, valued; 28 nodes, 82 edges.
- **Description:** Interactions of characters in the movie "Bear in the Big Blue House" (1997)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0173664
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_101`

### movie_102: Big Fish
{: #movie_102 }
- **Network:** `movie_102`: undirected, valued; 37 nodes, 81 edges.
- **Description:** Interactions of characters in the movie "Big Fish" (2003)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0319061
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_102`

### movie_103: The Big Lebowski
{: #movie_103 }
- **Network:** `movie_103`: undirected, valued; 37 nodes, 81 edges.
- **Description:** Interactions of characters in the movie "The Big Lebowski" (1998)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0118715
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_103`

### movie_104: The Big White
{: #movie_104 }
- **Network:** `movie_104`: undirected, valued; 29 nodes, 64 edges.
- **Description:** Interactions of characters in the movie "The Big White" (2005)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0402850
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_104`

### movie_105: The Birds
{: #movie_105 }
- **Network:** `movie_105`: undirected, valued; 26 nodes, 137 edges.
- **Description:** Interactions of characters in the movie "The Birds" (1963)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0056869
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_105`

### movie_106: Birthday Girl
{: #movie_106 }
- **Network:** `movie_106`: undirected, valued; 16 nodes, 24 edges.
- **Description:** Interactions of characters in the movie "Birthday Girl" (2001)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0188453
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_106`

### movie_107: The Black Dahlia
{: #movie_107 }
- **Network:** `movie_107`: undirected, valued; 61 nodes, 144 edges.
- **Description:** Interactions of characters in the movie "The Black Dahlia" (2006)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0387877
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_107`

### movie_108: Black Rain
{: #movie_108 }
- **Network:** `movie_108`: undirected, valued; 27 nodes, 69 edges.
- **Description:** Interactions of characters in the movie "Black Rain" (1989)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0096933
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_108`

### movie_109: Black Snake Moan
{: #movie_109 }
- **Network:** `movie_109`: undirected, valued; 35 nodes, 76 edges.
- **Description:** Interactions of characters in the movie "Black Snake Moan" (2006)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0462200
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_109`

### movie_11: 44 Inch Chest
{: #movie_11 }
- **Network:** `movie_11`: undirected, valued; 11 nodes, 23 edges.
- **Description:** Interactions of characters in the movie "44 Inch Chest" (2009)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0914837
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_11`

### movie_110: Blade
{: #movie_110 }
- **Network:** `movie_110`: undirected, valued; 24 nodes, 54 edges.
- **Description:** Interactions of characters in the movie "Blade" (1998)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0120611
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_110`

### movie_111: Blade II
{: #movie_111 }
- **Network:** `movie_111`: undirected, valued; 33 nodes, 126 edges.
- **Description:** Interactions of characters in the movie "Blade II" (2002)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0187738
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_111`

### movie_112: Blade Runner
{: #movie_112 }
- **Network:** `movie_112`: undirected, valued; 25 nodes, 44 edges.
- **Description:** Interactions of characters in the movie "Blade Runner" (1982)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0083658
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_112`

### movie_113: Blade: Trinity
{: #movie_113 }
- **Network:** `movie_113`: undirected, valued; 42 nodes, 115 edges.
- **Description:** Interactions of characters in the movie "Blade: Trinity" (2004)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0359013
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_113`

### movie_114: Blast from the Past
{: #movie_114 }
- **Network:** `movie_114`: undirected, valued; 46 nodes, 119 edges.
- **Description:** Interactions of characters in the movie "Blast from the Past" (1999)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0124298
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_114`

### movie_115: Blood Simple.
{: #movie_115 }
- **Network:** `movie_115`: undirected, valued; 12 nodes, 21 edges.
- **Description:** Interactions of characters in the movie "Blood Simple." (1984)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0086979
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_115`

### movie_116: Blow
{: #movie_116 }
- **Network:** `movie_116`: undirected, valued; 54 nodes, 140 edges.
- **Description:** Interactions of characters in the movie "Blow" (2001)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0221027
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_116`

### movie_117: Blue Velvet
{: #movie_117 }
- **Network:** `movie_117`: undirected, valued; 30 nodes, 64 edges.
- **Description:** Interactions of characters in the movie "Blue Velvet" (1986)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0090756
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_117`

### movie_118: Bodies, Rest & Motion
{: #movie_118 }
- **Network:** `movie_118`: undirected, valued; 16 nodes, 29 edges.
- **Description:** Interactions of characters in the movie "Bodies, Rest & Motion" (1993)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0106447
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_118`

### movie_119: Body Heat
{: #movie_119 }
- **Network:** `movie_119`: undirected, valued; 20 nodes, 42 edges.
- **Description:** Interactions of characters in the movie "Body Heat" (1981)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0082089
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_119`

### movie_12: 48 Hrs.
{: #movie_12 }
- **Network:** `movie_12`: undirected, valued; 42 nodes, 124 edges.
- **Description:** Interactions of characters in the movie "48 Hrs." (1982)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0083511
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_12`

### movie_120: Body of Evidence
{: #movie_120 }
- **Network:** `movie_120`: undirected, valued; 26 nodes, 68 edges.
- **Description:** Interactions of characters in the movie "Body of Evidence" (1993)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0106453
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_120`

### movie_121: The Bodyguard
{: #movie_121 }
- **Network:** `movie_121`: undirected, valued; 40 nodes, 120 edges.
- **Description:** Interactions of characters in the movie "The Bodyguard" (1992)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0103855
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_121`

### movie_122: Bones
{: #movie_122 }
- **Network:** `movie_122`: undirected, valued; 27 nodes, 74 edges.
- **Description:** Interactions of characters in the movie "Bones" (2005)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0460627
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_122`

### movie_123: The Bonfire of the Vanities
{: #movie_123 }
- **Network:** `movie_123`: undirected, valued; 63 nodes, 260 edges.
- **Description:** Interactions of characters in the movie "The Bonfire of the Vanities" (1990)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0099165
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_123`

### movie_124: Bonnie and Clyde
{: #movie_124 }
- **Network:** `movie_124`: undirected, valued; 16 nodes, 39 edges.
- **Description:** Interactions of characters in the movie "Bonnie and Clyde" (1967)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0061418
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_124`

### movie_125: Boogie Nights
{: #movie_125 }
- **Network:** `movie_125`: undirected, valued; 55 nodes, 175 edges.
- **Description:** Interactions of characters in the movie "Boogie Nights" (1997)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0118749
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_125`

### movie_126: The Book of Eli
{: #movie_126 }
- **Network:** `movie_126`: undirected, valued; 27 nodes, 69 edges.
- **Description:** Interactions of characters in the movie "The Book of Eli" (2010)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1037705
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_126`

### movie_127: The Boondock Saints II: All Saints Day
{: #movie_127 }
- **Network:** `movie_127`: undirected, valued; 44 nodes, 143 edges.
- **Description:** Interactions of characters in the movie "The Boondock Saints II: All Saints Day" (2009)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1300851
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_127`

### movie_128: The Boondock Saints
{: #movie_128 }
- **Network:** `movie_128`: undirected, valued; 36 nodes, 95 edges.
- **Description:** Interactions of characters in the movie "The Boondock Saints" (1999)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0144117
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_128`

### movie_129: Bottle Rocket
{: #movie_129 }
- **Network:** `movie_129`: undirected, valued; 35 nodes, 122 edges.
- **Description:** Interactions of characters in the movie "Bottle Rocket" (1996)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0115734
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_129`

### movie_13: (500) Days of Summer
{: #movie_13 }
- **Network:** `movie_13`: undirected, valued; 20 nodes, 54 edges.
- **Description:** Interactions of characters in the movie "(500) Days of Summer" (2009)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1022603
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_13`

### movie_130: Bound
{: #movie_130 }
- **Network:** `movie_130`: undirected, valued; 15 nodes, 31 edges.
- **Description:** Interactions of characters in the movie "Bound" (1996)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0115736
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_130`

### movie_131: The Bounty Hunter
{: #movie_131 }
- **Network:** `movie_131`: undirected, valued; 35 nodes, 76 edges.
- **Description:** Interactions of characters in the movie "The Bounty Hunter" (2010)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1038919
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_131`

### movie_132: The Bourne Identity
{: #movie_132 }
- **Network:** `movie_132`: undirected, valued; 36 nodes, 101 edges.
- **Description:** Interactions of characters in the movie "The Bourne Identity" (2002)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0258463
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_132`

### movie_133: The Bourne Ultimatum
{: #movie_133 }
- **Network:** `movie_133`: undirected, valued; 46 nodes, 102 edges.
- **Description:** Interactions of characters in the movie "The Bourne Ultimatum" (2007)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0440963
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_133`

### movie_134: Braveheart
{: #movie_134 }
- **Network:** `movie_134`: undirected, valued; 67 nodes, 310 edges.
- **Description:** Interactions of characters in the movie "Braveheart" (1995)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0112573
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_134`

### movie_135: Brazil
{: #movie_135 }
- **Network:** `movie_135`: undirected, valued; 38 nodes, 98 edges.
- **Description:** Interactions of characters in the movie "Brazil" (1985)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0088846
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_135`

### movie_136: Breakdown
{: #movie_136 }
- **Network:** `movie_136`: undirected, valued; 20 nodes, 45 edges.
- **Description:** Interactions of characters in the movie "Breakdown" (1997)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0118771
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_136`

### movie_137: The Breakfast Club
{: #movie_137 }
- **Network:** `movie_137`: undirected, valued; 9 nodes, 22 edges.
- **Description:** Interactions of characters in the movie "The Breakfast Club" (1985)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0088847
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_137`

### movie_138: Brick
{: #movie_138 }
- **Network:** `movie_138`: undirected, valued; 22 nodes, 45 edges.
- **Description:** Interactions of characters in the movie "Brick" (2005)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0393109
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_138`

### movie_139: Bringing Out the Dead
{: #movie_139 }
- **Network:** `movie_139`: undirected, valued; 42 nodes, 130 edges.
- **Description:** Interactions of characters in the movie "Bringing Out the Dead" (1999)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0163988
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_139`

### movie_14: 8MM
{: #movie_14 }
- **Network:** `movie_14`: undirected, valued; 22 nodes, 38 edges.
- **Description:** Interactions of characters in the movie "8MM" (1999)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0134273
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_14`

### movie_140: Broadcast News
{: #movie_140 }
- **Network:** `movie_140`: undirected, valued; 52 nodes, 176 edges.
- **Description:** Interactions of characters in the movie "Broadcast News" (1987)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0092699
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_140`

### movie_141: Broken Arrow
{: #movie_141 }
- **Network:** `movie_141`: undirected, valued; 59 nodes, 195 edges.
- **Description:** Interactions of characters in the movie "Broken Arrow" (1996)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0115759
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_141`

### movie_142: Broken Embraces
{: #movie_142 }
- **Network:** `movie_142`: undirected, valued; 41 nodes, 115 edges.
- **Description:** Interactions of characters in the movie "Broken Embraces" (2009)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0913425
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_142`

### movie_143: Bruce Almighty
{: #movie_143 }
- **Network:** `movie_143`: undirected, valued; 50 nodes, 140 edges.
- **Description:** Interactions of characters in the movie "Bruce Almighty" (2003)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0315327
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_143`

### movie_144: Buffy the Vampire Slayer
{: #movie_144 }
- **Network:** `movie_144`: undirected, valued; 41 nodes, 203 edges.
- **Description:** Interactions of characters in the movie "Buffy the Vampire Slayer" (1997)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0118276
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_144`

### movie_145: Bull Durham
{: #movie_145 }
- **Network:** `movie_145`: undirected, valued; 35 nodes, 159 edges.
- **Description:** Interactions of characters in the movie "Bull Durham" (1988)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0094812
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_145`

### movie_146: Burlesque
{: #movie_146 }
- **Network:** `movie_146`: undirected, valued; 37 nodes, 152 edges.
- **Description:** Interactions of characters in the movie "Burlesque" (2010)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1126591
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_146`

### movie_147: Burn After Reading
{: #movie_147 }
- **Network:** `movie_147`: undirected, valued; 35 nodes, 75 edges.
- **Description:** Interactions of characters in the movie "Burn After Reading" (2008)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0887883
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_147`

### movie_148: The Butterfly Effect
{: #movie_148 }
- **Network:** `movie_148`: undirected, valued; 32 nodes, 73 edges.
- **Description:** Interactions of characters in the movie "The Butterfly Effect" (2004)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0289879
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_148`

### movie_149: The Cable Guy
{: #movie_149 }
- **Network:** `movie_149`: undirected, valued; 37 nodes, 105 edges.
- **Description:** Interactions of characters in the movie "The Cable Guy" (1996)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0115798
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_149`

### movie_15: A Few Good Men
{: #movie_15 }
- **Network:** `movie_15`: undirected, valued; 29 nodes, 76 edges.
- **Description:** Interactions of characters in the movie "A Few Good Men" (1992)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0104257
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_15`

### movie_150: Capote
{: #movie_150 }
- **Network:** `movie_150`: undirected, valued; 45 nodes, 104 edges.
- **Description:** Interactions of characters in the movie "Capote" (2005)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0379725
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_150`

### movie_151: Casino
{: #movie_151 }
- **Network:** `movie_151`: undirected, valued; 109 nodes, 326 edges.
- **Description:** Interactions of characters in the movie "Casino" (1995)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0112641
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_151`

### movie_152: Cast Away
{: #movie_152 }
- **Network:** `movie_152`: undirected, valued; 33 nodes, 65 edges.
- **Description:** Interactions of characters in the movie "Cast Away" (2000)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0162222
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_152`

### movie_153: Catch Me If You Can
{: #movie_153 }
- **Network:** `movie_153`: undirected, valued; 82 nodes, 162 edges.
- **Description:** Interactions of characters in the movie "Catch Me If You Can" (2002)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0264464
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_153`

### movie_154: The Cell
{: #movie_154 }
- **Network:** `movie_154`: undirected, valued; 24 nodes, 59 edges.
- **Description:** Interactions of characters in the movie "The Cell" (2000)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0209958
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_154`

### movie_155: Cellular
{: #movie_155 }
- **Network:** `movie_155`: undirected, valued; 48 nodes, 138 edges.
- **Description:** Interactions of characters in the movie "Cellular" (2004)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0337921
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_155`

### movie_156: Changeling
{: #movie_156 }
- **Network:** `movie_156`: undirected, valued; 59 nodes, 145 edges.
- **Description:** Interactions of characters in the movie "Changeling" (2008)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0824747
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_156`

### movie_157: Spin City
{: #movie_157 }
- **Network:** `movie_157`: undirected, valued; 31 nodes, 92 edges.
- **Description:** Interactions of characters in the movie "Spin City" (1996)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0115369
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_157`

### movie_158: Charade
{: #movie_158 }
- **Network:** `movie_158`: undirected, valued; 31 nodes, 108 edges.
- **Description:** Interactions of characters in the movie "Charade" (1963)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0056923
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_158`

### movie_159: Charlie's Angels: Full Throttle
{: #movie_159 }
- **Network:** `movie_159`: undirected, valued; 28 nodes, 80 edges.
- **Description:** Interactions of characters in the movie "Charlie's Angels: Full Throttle" (2003)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0305357
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_159`

### movie_16: Above the Law
{: #movie_16 }
- **Network:** `movie_16`: undirected, valued; 39 nodes, 95 edges.
- **Description:** Interactions of characters in the movie "Above the Law" (1988)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0094602
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_16`

### movie_160: Chasing Sleep
{: #movie_160 }
- **Network:** `movie_160`: undirected, valued; 17 nodes, 40 edges.
- **Description:** Interactions of characters in the movie "Chasing Sleep" (2000)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0221069
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_160`

### movie_161: Cherry Falls
{: #movie_161 }
- **Network:** `movie_161`: undirected, valued; 51 nodes, 112 edges.
- **Description:** Interactions of characters in the movie "Cherry Falls" (2000)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0175526
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_161`

### movie_162: Chinatown
{: #movie_162 }
- **Network:** `movie_162`: undirected, valued; 50 nodes, 125 edges.
- **Description:** Interactions of characters in the movie "Chinatown" (1974)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0071315
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_162`

### movie_163: The Chronicles of Narnia: The Lion, the Witch and the Wardrobe
{: #movie_163 }
- **Network:** `movie_163`: undirected, valued; 29 nodes, 146 edges.
- **Description:** Interactions of characters in the movie "The Chronicles of Narnia: The Lion, the Witch and the Wardrobe" (2005)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0363771
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_163`

### movie_164: The Cider House Rules
{: #movie_164 }
- **Network:** `movie_164`: undirected, valued; 38 nodes, 140 edges.
- **Description:** Interactions of characters in the movie "The Cider House Rules" (1999)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0124315
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_164`

### movie_165: The Cincinnati Kid
{: #movie_165 }
- **Network:** `movie_165`: undirected, valued; 36 nodes, 198 edges.
- **Description:** Interactions of characters in the movie "The Cincinnati Kid" (1965)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0059037
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_165`

### movie_166: Cinema Paradiso
{: #movie_166 }
- **Network:** `movie_166`: undirected, valued; 40 nodes, 100 edges.
- **Description:** Interactions of characters in the movie "Cinema Paradiso" (1988)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0095765
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_166`

### movie_167: Citizen Kane
{: #movie_167 }
- **Network:** `movie_167`: undirected, valued; 56 nodes, 148 edges.
- **Description:** Interactions of characters in the movie "Citizen Kane" (1941)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0033467
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_167`

### movie_168: City of Joy
{: #movie_168 }
- **Network:** `movie_168`: undirected, valued; 44 nodes, 143 edges.
- **Description:** Interactions of characters in the movie "City of Joy" (1992)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0103976
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_168`

### movie_169: Clash of the Titans
{: #movie_169 }
- **Network:** `movie_169`: undirected, valued; 27 nodes, 86 edges.
- **Description:** Interactions of characters in the movie "Clash of the Titans" (2010)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0800320
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_169`

### movie_17: Absolute Power
{: #movie_17 }
- **Network:** `movie_17`: undirected, valued; 27 nodes, 46 edges.
- **Description:** Interactions of characters in the movie "Absolute Power" (1997)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0118548
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_17`

### movie_170: Clerks.
{: #movie_170 }
- **Network:** `movie_170`: undirected, valued; 38 nodes, 117 edges.
- **Description:** Interactions of characters in the movie "Clerks." (1994)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0109445
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_170`

### movie_171: Cliffhanger
{: #movie_171 }
- **Network:** `movie_171`: undirected, valued; 23 nodes, 78 edges.
- **Description:** Interactions of characters in the movie "Cliffhanger" (1993)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0106582
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_171`

### movie_172: Cobb
{: #movie_172 }
- **Network:** `movie_172`: undirected, valued; 41 nodes, 109 edges.
- **Description:** Interactions of characters in the movie "Cobb" (1994)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0109450
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_172`

### movie_173: Code of Silence
{: #movie_173 }
- **Network:** `movie_173`: undirected, valued; 41 nodes, 105 edges.
- **Description:** Interactions of characters in the movie "Code of Silence" (1985)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0088936
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_173`

### movie_174: Cold Mountain
{: #movie_174 }
- **Network:** `movie_174`: undirected, valued; 45 nodes, 112 edges.
- **Description:** Interactions of characters in the movie "Cold Mountain" (2003)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0159365
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_174`

### movie_175: Collateral Damage
{: #movie_175 }
- **Network:** `movie_175`: undirected, valued; 42 nodes, 97 edges.
- **Description:** Interactions of characters in the movie "Collateral Damage" (2002)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0233469
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_175`

### movie_176: Confessions of a Dangerous Mind
{: #movie_176 }
- **Network:** `movie_176`: undirected, valued; 69 nodes, 135 edges.
- **Description:** Interactions of characters in the movie "Confessions of a Dangerous Mind" (2002)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0270288
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_176`

### movie_177: Confidence
{: #movie_177 }
- **Network:** `movie_177`: undirected, valued; 25 nodes, 81 edges.
- **Description:** Interactions of characters in the movie "Confidence" (2003)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0310910
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_177`

### movie_178: Constantine
{: #movie_178 }
- **Network:** `movie_178`: undirected, valued; 24 nodes, 44 edges.
- **Description:** Interactions of characters in the movie "Constantine" (2005)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0360486
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_178`

### movie_179: The Cooler
{: #movie_179 }
- **Network:** `movie_179`: undirected, valued; 31 nodes, 104 edges.
- **Description:** Interactions of characters in the movie "The Cooler" (2003)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0318374
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_179`

### movie_18: The Abyss
{: #movie_18 }
- **Network:** `movie_18`: undirected, valued; 28 nodes, 108 edges.
- **Description:** Interactions of characters in the movie "The Abyss" (1989)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0096754
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_18`

### movie_180: Copycat
{: #movie_180 }
- **Network:** `movie_180`: undirected, valued; 33 nodes, 72 edges.
- **Description:** Interactions of characters in the movie "Copycat" (1995)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0112722
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_180`

### movie_181: Coraline
{: #movie_181 }
- **Network:** `movie_181`: undirected, valued; 42 nodes, 108 edges.
- **Description:** Interactions of characters in the movie "Coraline" (2009)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0327597
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_181`

### movie_182: Cradle 2 the Grave
{: #movie_182 }
- **Network:** `movie_182`: undirected, valued; 36 nodes, 117 edges.
- **Description:** Interactions of characters in the movie "Cradle 2 the Grave" (2003)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0306685
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_182`

### movie_183: Crank
{: #movie_183 }
- **Network:** `movie_183`: undirected, valued; 40 nodes, 75 edges.
- **Description:** Interactions of characters in the movie "Crank" (2006)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0479884
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_183`

### movie_184: Crash
{: #movie_184 }
- **Network:** `movie_184`: undirected, valued; 15 nodes, 25 edges.
- **Description:** Interactions of characters in the movie "Crash" (2004)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0375679
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_184`

### movie_185: Crime Spree
{: #movie_185 }
- **Network:** `movie_185`: undirected, valued; 43 nodes, 152 edges.
- **Description:** Interactions of characters in the movie "Crime Spree" (2003)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0310924
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_185`

### movie_186: Crouching Tiger, Hidden Dragon
{: #movie_186 }
- **Network:** `movie_186`: undirected, valued; 32 nodes, 92 edges.
- **Description:** Interactions of characters in the movie "Crouching Tiger, Hidden Dragon" (2000)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0190332
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_186`

### movie_187: Croupier
{: #movie_187 }
- **Network:** `movie_187`: undirected, valued; 32 nodes, 69 edges.
- **Description:** Interactions of characters in the movie "Croupier" (1998)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0159382
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_187`

### movie_188: The Crow: Salvation
{: #movie_188 }
- **Network:** `movie_188`: undirected, valued; 33 nodes, 85 edges.
- **Description:** Interactions of characters in the movie "The Crow: Salvation" (2000)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0132910
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_188`

### movie_189: The Crow
{: #movie_189 }
- **Network:** `movie_189`: undirected, valued; 30 nodes, 68 edges.
- **Description:** Interactions of characters in the movie "The Crow" (1994)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0109506
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_189`

### movie_19: Ace Ventura: Pet Detective
{: #movie_19 }
- **Network:** `movie_19`: undirected, valued; 53 nodes, 148 edges.
- **Description:** Interactions of characters in the movie "Ace Ventura: Pet Detective" (1994)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0109040
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_19`

### movie_190: The Crow: City of Angels
{: #movie_190 }
- **Network:** `movie_190`: undirected, valued; 24 nodes, 60 edges.
- **Description:** Interactions of characters in the movie "The Crow: City of Angels" (1996)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0115986
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_190`

### movie_191: Cruel Intentions
{: #movie_191 }
- **Network:** `movie_191`: undirected, valued; 16 nodes, 33 edges.
- **Description:** Interactions of characters in the movie "Cruel Intentions" (1999)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0139134
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_191`

### movie_192: The Crying Game
{: #movie_192 }
- **Network:** `movie_192`: undirected, valued; 15 nodes, 39 edges.
- **Description:** Interactions of characters in the movie "The Crying Game" (1992)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0104036
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_192`

### movie_193: The Curious Case of Benjamin Button
{: #movie_193 }
- **Network:** `movie_193`: undirected, valued; 44 nodes, 129 edges.
- **Description:** Interactions of characters in the movie "The Curious Case of Benjamin Button" (2008)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0421715
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_193`

### movie_194: The Damned United
{: #movie_194 }
- **Network:** `movie_194`: undirected, valued; 37 nodes, 84 edges.
- **Description:** Interactions of characters in the movie "The Damned United" (2009)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1226271
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_194`

### movie_195: Dances with Wolves
{: #movie_195 }
- **Network:** `movie_195`: undirected, valued; 29 nodes, 73 edges.
- **Description:** Interactions of characters in the movie "Dances with Wolves" (1990)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0099348
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_195`

### movie_196: Dark Star
{: #movie_196 }
- **Network:** `movie_196`: undirected, valued; 8 nodes, 16 edges.
- **Description:** Interactions of characters in the movie "Dark Star" (1974)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0069945
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_196`

### movie_197: Darkman
{: #movie_197 }
- **Network:** `movie_197`: undirected, valued; 39 nodes, 137 edges.
- **Description:** Interactions of characters in the movie "Darkman" (1990)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0099365
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_197`

### movie_198: Date Night
{: #movie_198 }
- **Network:** `movie_198`: undirected, valued; 42 nodes, 141 edges.
- **Description:** Interactions of characters in the movie "Date Night" (2010)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1279935
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_198`

### movie_199: Day of the Dead
{: #movie_199 }
- **Network:** `movie_199`: undirected, valued; 35 nodes, 86 edges.
- **Description:** Interactions of characters in the movie "Day of the Dead" (1985)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0088993
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_199`

### movie_2: 12
{: #movie_2 }
- **Network:** `movie_2`: undirected, valued; 33 nodes, 61 edges.
- **Description:** Interactions of characters in the movie "12" (2007)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0488478
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_2`

### movie_20: Adaptation.
{: #movie_20 }
- **Network:** `movie_20`: undirected, valued; 30 nodes, 44 edges.
- **Description:** Interactions of characters in the movie "Adaptation." (2002)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0268126
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_20`

### movie_200: The Day the Clown Cried
{: #movie_200 }
- **Network:** `movie_200`: undirected, valued; 39 nodes, 151 edges.
- **Description:** Interactions of characters in the movie "The Day the Clown Cried" (1972)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0068451
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_200`

### movie_201: The Day the Earth Stood Still
{: #movie_201 }
- **Network:** `movie_201`: undirected, valued; 33 nodes, 104 edges.
- **Description:** Interactions of characters in the movie "The Day the Earth Stood Still" (1951)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0043456
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_201`

### movie_202: Days of Heaven
{: #movie_202 }
- **Network:** `movie_202`: undirected, valued; 17 nodes, 34 edges.
- **Description:** Interactions of characters in the movie "Days of Heaven" (1978)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0077405
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_202`

### movie_203: Dead Poets Society
{: #movie_203 }
- **Network:** `movie_203`: undirected, valued; 42 nodes, 275 edges.
- **Description:** Interactions of characters in the movie "Dead Poets Society" (1989)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0097165
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_203`

### movie_204: Death at a Funeral
{: #movie_204 }
- **Network:** `movie_204`: undirected, valued; 18 nodes, 89 edges.
- **Description:** Interactions of characters in the movie "Death at a Funeral" (2007)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0795368
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_204`

### movie_205: Death to Smoochy
{: #movie_205 }
- **Network:** `movie_205`: undirected, valued; 49 nodes, 118 edges.
- **Description:** Interactions of characters in the movie "Death to Smoochy" (2002)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0266452
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_205`

### movie_206: Deep Cover
{: #movie_206 }
- **Network:** `movie_206`: undirected, valued; 33 nodes, 92 edges.
- **Description:** Interactions of characters in the movie "Deep Cover" (1992)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0104073
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_206`

### movie_207: Deep Rising
{: #movie_207 }
- **Network:** `movie_207`: undirected, valued; 19 nodes, 71 edges.
- **Description:** Interactions of characters in the movie "Deep Rising" (1998)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0118956
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_207`

### movie_208: The Deer Hunter
{: #movie_208 }
- **Network:** `movie_208`: undirected, valued; 32 nodes, 74 edges.
- **Description:** Interactions of characters in the movie "The Deer Hunter" (1978)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0077416
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_208`

### movie_209: Defiance
{: #movie_209 }
- **Network:** `movie_209`: undirected, valued; 58 nodes, 248 edges.
- **Description:** Interactions of characters in the movie "Defiance" (2008)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1034303
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_209`

### movie_21: The Addams Family
{: #movie_21 }
- **Network:** `movie_21`: undirected, valued; 13 nodes, 44 edges.
- **Description:** Interactions of characters in the movie "The Addams Family" (1991)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0101272
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_21`

### movie_210: The Departed
{: #movie_210 }
- **Network:** `movie_210`: undirected, valued; 51 nodes, 117 edges.
- **Description:** Interactions of characters in the movie "The Departed" (2006)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0407887
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_210`

### movie_211: Detroit Rock City
{: #movie_211 }
- **Network:** `movie_211`: undirected, valued; 47 nodes, 153 edges.
- **Description:** Interactions of characters in the movie "Detroit Rock City" (1999)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0165710
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_211`

### movie_212: Devil in a Blue Dress
{: #movie_212 }
- **Network:** `movie_212`: undirected, valued; 34 nodes, 82 edges.
- **Description:** Interactions of characters in the movie "Devil in a Blue Dress" (1995)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0112857
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_212`

### movie_213: The Devil's Advocate
{: #movie_213 }
- **Network:** `movie_213`: undirected, valued; 43 nodes, 120 edges.
- **Description:** Interactions of characters in the movie "The Devil's Advocate" (1997)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0118971
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_213`

### movie_214: Die Hard
{: #movie_214 }
- **Network:** `movie_214`: undirected, valued; 47 nodes, 237 edges.
- **Description:** Interactions of characters in the movie "Die Hard" (1988)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0095016
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_214`

### movie_215: The Distinguished Gentleman
{: #movie_215 }
- **Network:** `movie_215`: undirected, valued; 49 nodes, 197 edges.
- **Description:** Interactions of characters in the movie "The Distinguished Gentleman" (1992)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0104114
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_215`

### movie_216: Disturbia
{: #movie_216 }
- **Network:** `movie_216`: undirected, valued; 20 nodes, 48 edges.
- **Description:** Interactions of characters in the movie "Disturbia" (2007)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0486822
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_216`

### movie_217: Do the Right Thing
{: #movie_217 }
- **Network:** `movie_217`: undirected, valued; 34 nodes, 171 edges.
- **Description:** Interactions of characters in the movie "Do the Right Thing" (1989)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0097216
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_217`

### movie_218: Dog Day Afternoon
{: #movie_218 }
- **Network:** `movie_218`: undirected, valued; 53 nodes, 410 edges.
- **Description:** Interactions of characters in the movie "Dog Day Afternoon" (1975)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0072890
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_218`

### movie_219: Donnie Brasco
{: #movie_219 }
- **Network:** `movie_219`: undirected, valued; 50 nodes, 160 edges.
- **Description:** Interactions of characters in the movie "Donnie Brasco" (1997)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0119008
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_219`

### movie_22: The Adventures of Buckaroo Banzai Across the 8th Dimension
{: #movie_22 }
- **Network:** `movie_22`: undirected, valued; 52 nodes, 206 edges.
- **Description:** Interactions of characters in the movie "The Adventures of Buckaroo Banzai Across the 8th Dimension" (1984)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0086856
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_22`

### movie_220: The Doors
{: #movie_220 }
- **Network:** `movie_220`: undirected, valued; 95 nodes, 567 edges.
- **Description:** Interactions of characters in the movie "The Doors" (1991)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0101761
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_220`

### movie_221: Double Indemnity
{: #movie_221 }
- **Network:** `movie_221`: undirected, valued; 20 nodes, 44 edges.
- **Description:** Interactions of characters in the movie "Double Indemnity" (1944)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0036775
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_221`

### movie_222: Drag Me to Hell
{: #movie_222 }
- **Network:** `movie_222`: undirected, valued; 30 nodes, 77 edges.
- **Description:** Interactions of characters in the movie "Drag Me to Hell" (2009)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1127180
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_222`

### movie_223: Dragonslayer
{: #movie_223 }
- **Network:** `movie_223`: undirected, valued; 15 nodes, 52 edges.
- **Description:** Interactions of characters in the movie "Dragonslayer" (1981)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0082288
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_223`

### movie_224: Drop Dead Gorgeous
{: #movie_224 }
- **Network:** `movie_224`: undirected, valued; 43 nodes, 199 edges.
- **Description:** Interactions of characters in the movie "Drop Dead Gorgeous" (1999)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0157503
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_224`

### movie_225: A Dry White Season
{: #movie_225 }
- **Network:** `movie_225`: undirected, valued; 53 nodes, 161 edges.
- **Description:** Interactions of characters in the movie "A Dry White Season" (1989)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0097243
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_225`

### movie_226: Dumb & Dumber
{: #movie_226 }
- **Network:** `movie_226`: undirected, valued; 37 nodes, 86 edges.
- **Description:** Interactions of characters in the movie "Dumb & Dumber" (1994)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0109686
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_226`

### movie_227: Dune
{: #movie_227 }
- **Network:** `movie_227`: undirected, valued; 34 nodes, 98 edges.
- **Description:** Interactions of characters in the movie "Dune" (1984)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0087182
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_227`

### movie_228: Eagle Eye
{: #movie_228 }
- **Network:** `movie_228`: undirected, valued; 76 nodes, 185 edges.
- **Description:** Interactions of characters in the movie "Eagle Eye" (2008)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1059786
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_228`

### movie_229: Eastern Promises
{: #movie_229 }
- **Network:** `movie_229`: undirected, valued; 23 nodes, 53 edges.
- **Description:** Interactions of characters in the movie "Eastern Promises" (2007)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0765443
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_229`

### movie_23: Affliction
{: #movie_23 }
- **Network:** `movie_23`: undirected, valued; 24 nodes, 57 edges.
- **Description:** Interactions of characters in the movie "Affliction" (1997)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0118564
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_23`

### movie_230: Edtv
{: #movie_230 }
- **Network:** `movie_230`: undirected, valued; 77 nodes, 246 edges.
- **Description:** Interactions of characters in the movie "Edtv" (1999)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0131369
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_230`

### movie_231: Ed Wood
{: #movie_231 }
- **Network:** `movie_231`: undirected, valued; 60 nodes, 246 edges.
- **Description:** Interactions of characters in the movie "Ed Wood" (1994)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0109707
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_231`

### movie_232: Eight Legged Freaks
{: #movie_232 }
- **Network:** `movie_232`: undirected, valued; 24 nodes, 86 edges.
- **Description:** Interactions of characters in the movie "Eight Legged Freaks" (2002)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0271367
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_232`

### movie_233: Election
{: #movie_233 }
- **Network:** `movie_233`: undirected, valued; 36 nodes, 91 edges.
- **Description:** Interactions of characters in the movie "Election" (1999)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0126886
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_233`

### movie_234: The Elephant Man
{: #movie_234 }
- **Network:** `movie_234`: undirected, valued; 39 nodes, 90 edges.
- **Description:** Interactions of characters in the movie "The Elephant Man" (1980)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0080678
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_234`

### movie_235: Elizabeth: The Golden Age
{: #movie_235 }
- **Network:** `movie_235`: undirected, valued; 43 nodes, 136 edges.
- **Description:** Interactions of characters in the movie "Elizabeth: The Golden Age" (2007)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0414055
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_235`

### movie_236: Enemy of the State
{: #movie_236 }
- **Network:** `movie_236`: undirected, valued; 60 nodes, 152 edges.
- **Description:** Interactions of characters in the movie "Enemy of the State" (1998)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0120660
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_236`

### movie_237: The English Patient
{: #movie_237 }
- **Network:** `movie_237`: undirected, valued; 34 nodes, 72 edges.
- **Description:** Interactions of characters in the movie "The English Patient" (1996)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0116209
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_237`

### movie_238: Entrapment
{: #movie_238 }
- **Network:** `movie_238`: undirected, valued; 10 nodes, 19 edges.
- **Description:** Interactions of characters in the movie "Entrapment" (1999)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0137494
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_238`

### movie_239: Erin Brockovich
{: #movie_239 }
- **Network:** `movie_239`: undirected, valued; 40 nodes, 73 edges.
- **Description:** Interactions of characters in the movie "Erin Brockovich" (2000)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0195685
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_239`

### movie_24: After Life
{: #movie_24 }
- **Network:** `movie_24`: undirected, valued; 35 nodes, 91 edges.
- **Description:** Interactions of characters in the movie "After Life" (2009)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0838247
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_24`

### movie_240: Escape from L.A.
{: #movie_240 }
- **Network:** `movie_240`: undirected, valued; 35 nodes, 91 edges.
- **Description:** Interactions of characters in the movie "Escape from L.A." (1996)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0116225
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_240`

### movie_241: Escape from New York
{: #movie_241 }
- **Network:** `movie_241`: undirected, valued; 26 nodes, 49 edges.
- **Description:** Interactions of characters in the movie "Escape from New York" (1981)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0082340
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_241`

### movie_242: Eternal Sunshine of the Spotless Mind
{: #movie_242 }
- **Network:** `movie_242`: undirected, valued; 32 nodes, 69 edges.
- **Description:** Interactions of characters in the movie "Eternal Sunshine of the Spotless Mind" (2004)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0338013
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_242`

### movie_243: Even Cowgirls Get the Blues
{: #movie_243 }
- **Network:** `movie_243`: undirected, valued; 37 nodes, 98 edges.
- **Description:** Interactions of characters in the movie "Even Cowgirls Get the Blues" (1993)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0106834
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_243`

### movie_244: Event Horizon
{: #movie_244 }
- **Network:** `movie_244`: undirected, valued; 19 nodes, 56 edges.
- **Description:** Interactions of characters in the movie "Event Horizon" (1997)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0119081
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_244`

### movie_245: The Evil Dead
{: #movie_245 }
- **Network:** `movie_245`: undirected, valued; 5 nodes, 10 edges.
- **Description:** Interactions of characters in the movie "The Evil Dead" (1981)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0083907
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_245`

### movie_246: Evil Dead II
{: #movie_246 }
- **Network:** `movie_246`: undirected, valued; 13 nodes, 30 edges.
- **Description:** Interactions of characters in the movie "Evil Dead II" (1987)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0092991
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_246`

### movie_247: Excalibur
{: #movie_247 }
- **Network:** `movie_247`: undirected, valued; 30 nodes, 97 edges.
- **Description:** Interactions of characters in the movie "Excalibur" (1981)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0082348
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_247`

### movie_248: Extract
{: #movie_248 }
- **Network:** `movie_248`: undirected, valued; 28 nodes, 75 edges.
- **Description:** Interactions of characters in the movie "Extract" (2009)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1225822
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_248`

### movie_249: The Fabulous Baker Boys
{: #movie_249 }
- **Network:** `movie_249`: undirected, valued; 36 nodes, 80 edges.
- **Description:** Interactions of characters in the movie "The Fabulous Baker Boys" (1989)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0097322
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_249`

### movie_25: Agnes of God
{: #movie_25 }
- **Network:** `movie_25`: undirected, valued; 21 nodes, 102 edges.
- **Description:** Interactions of characters in the movie "Agnes of God" (1985)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0088683
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_25`

### movie_250: Face/Off
{: #movie_250 }
- **Network:** `movie_250`: undirected, valued; 38 nodes, 106 edges.
- **Description:** Interactions of characters in the movie "Face/Off" (1997)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0119094
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_250`

### movie_251: Fair Game
{: #movie_251 }
- **Network:** `movie_251`: undirected, valued; 68 nodes, 214 edges.
- **Description:** Interactions of characters in the movie "Fair Game" (2010)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0977855
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_251`

### movie_252: The Family Man
{: #movie_252 }
- **Network:** `movie_252`: undirected, valued; 32 nodes, 64 edges.
- **Description:** Interactions of characters in the movie "The Family Man" (2000)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0218967
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_252`

### movie_253: Fantastic Four
{: #movie_253 }
- **Network:** `movie_253`: undirected, valued; 37 nodes, 114 edges.
- **Description:** Interactions of characters in the movie "Fantastic Four" (2005)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0120667
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_253`

### movie_254: Fantastic Mr. Fox
{: #movie_254 }
- **Network:** `movie_254`: undirected, valued; 32 nodes, 142 edges.
- **Description:** Interactions of characters in the movie "Fantastic Mr. Fox" (2009)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0432283
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_254`

### movie_255: Fargo
{: #movie_255 }
- **Network:** `movie_255`: undirected, valued; 32 nodes, 64 edges.
- **Description:** Interactions of characters in the movie "Fargo" (1996)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0116282
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_255`

### movie_256: Fast Times at Ridgemont High
{: #movie_256 }
- **Network:** `movie_256`: undirected, valued; 57 nodes, 151 edges.
- **Description:** Interactions of characters in the movie "Fast Times at Ridgemont High" (1982)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0083929
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_256`

### movie_257: Fatal Instinct
{: #movie_257 }
- **Network:** `movie_257`: undirected, valued; 39 nodes, 108 edges.
- **Description:** Interactions of characters in the movie "Fatal Instinct" (1993)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0106873
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_257`

### movie_258: Fear and Loathing in Las Vegas
{: #movie_258 }
- **Network:** `movie_258`: undirected, valued; 40 nodes, 84 edges.
- **Description:** Interactions of characters in the movie "Fear and Loathing in Las Vegas" (1998)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0120669
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_258`

### movie_259: Babette's Feast
{: #movie_259 }
- **Network:** `movie_259`: undirected, valued; 29 nodes, 254 edges.
- **Description:** Interactions of characters in the movie "Babette's Feast" (1987)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0092603
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_259`

### movie_26: Air Force One
{: #movie_26 }
- **Network:** `movie_26`: undirected, valued; 52 nodes, 150 edges.
- **Description:** Interactions of characters in the movie "Air Force One" (1997)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0118571
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_26`

### movie_260: Ferris Bueller's Day Off
{: #movie_260 }
- **Network:** `movie_260`: undirected, valued; 39 nodes, 99 edges.
- **Description:** Interactions of characters in the movie "Ferris Bueller's Day Off" (1986)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0091042
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_260`

### movie_261: The Fifth Element
{: #movie_261 }
- **Network:** `movie_261`: undirected, valued; 62 nodes, 186 edges.
- **Description:** Interactions of characters in the movie "The Fifth Element" (1997)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0119116
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_261`

### movie_262: Fight Club
{: #movie_262 }
- **Network:** `movie_262`: undirected, valued; 46 nodes, 94 edges.
- **Description:** Interactions of characters in the movie "Fight Club" (1999)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0137523
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_262`

### movie_263: Final Destination
{: #movie_263 }
- **Network:** `movie_263`: undirected, valued; 31 nodes, 150 edges.
- **Description:** Interactions of characters in the movie "Final Destination" (2000)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0195714
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_263`

### movie_264: Final Destination 2
{: #movie_264 }
- **Network:** `movie_264`: undirected, valued; 38 nodes, 171 edges.
- **Description:** Interactions of characters in the movie "Final Destination 2" (2003)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0309593
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_264`

### movie_265: Five Easy Pieces
{: #movie_265 }
- **Network:** `movie_265`: undirected, valued; 21 nodes, 61 edges.
- **Description:** Interactions of characters in the movie "Five Easy Pieces" (1970)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0065724
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_265`

### movie_266: Fletch
{: #movie_266 }
- **Network:** `movie_266`: undirected, valued; 48 nodes, 124 edges.
- **Description:** Interactions of characters in the movie "Fletch" (1985)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0089155
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_266`

### movie_267: The Flintstones
{: #movie_267 }
- **Network:** `movie_267`: undirected, valued; 35 nodes, 105 edges.
- **Description:** Interactions of characters in the movie "The Flintstones" (1960)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0053502
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_267`

### movie_268: Forrest Gump
{: #movie_268 }
- **Network:** `movie_268`: undirected, valued; 94 nodes, 271 edges.
- **Description:** Interactions of characters in the movie "Forrest Gump" (1994)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0109830
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_268`

### movie_269: Four Feathers
{: #movie_269 }
- **Network:** `movie_269`: undirected, valued; 19 nodes, 26 edges.
- **Description:** Interactions of characters in the movie "Four Feathers" (1915)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0005353
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_269`

### movie_27: Airplane!
{: #movie_27 }
- **Network:** `movie_27`: undirected, valued; 25 nodes, 62 edges.
- **Description:** Interactions of characters in the movie "Airplane!" (1980)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0080339
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_27`

### movie_270: Four Rooms
{: #movie_270 }
- **Network:** `movie_270`: undirected, valued; 28 nodes, 70 edges.
- **Description:** Interactions of characters in the movie "Four Rooms" (1995)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0113101
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_270`

### movie_271: Fracture
{: #movie_271 }
- **Network:** `movie_271`: undirected, valued; 35 nodes, 68 edges.
- **Description:** Interactions of characters in the movie "Fracture" (2007)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0488120
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_271`

### movie_272: French Kiss
{: #movie_272 }
- **Network:** `movie_272`: undirected, valued; 68 nodes, 158 edges.
- **Description:** Interactions of characters in the movie "French Kiss" (1995)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0113117
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_272`

### movie_273: Frankenstein
{: #movie_273 }
- **Network:** `movie_273`: undirected, valued; 56 nodes, 160 edges.
- **Description:** Interactions of characters in the movie "Frankenstein" (1994)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0109836
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_273`

### movie_274: Freddy vs. Jason
{: #movie_274 }
- **Network:** `movie_274`: undirected, valued; 37 nodes, 92 edges.
- **Description:** Interactions of characters in the movie "Freddy vs. Jason" (2003)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0329101
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_274`

### movie_275: The French Connection
{: #movie_275 }
- **Network:** `movie_275`: undirected, valued; 40 nodes, 78 edges.
- **Description:** Interactions of characters in the movie "The French Connection" (1971)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0067116
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_275`

### movie_276: Frequency
{: #movie_276 }
- **Network:** `movie_276`: undirected, valued; 39 nodes, 90 edges.
- **Description:** Interactions of characters in the movie "Frequency" (2000)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0186151
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_276`

### movie_277: Friday the 13th
{: #movie_277 }
- **Network:** `movie_277`: undirected, valued; 14 nodes, 36 edges.
- **Description:** Interactions of characters in the movie "Friday the 13th" (1980)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0080761
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_277`

### movie_278: Friday the 13th Part VIII: Jason Takes Manhattan
{: #movie_278 }
- **Network:** `movie_278`: undirected, valued; 27 nodes, 88 edges.
- **Description:** Interactions of characters in the movie "Friday the 13th Part VIII: Jason Takes Manhattan" (1989)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0097388
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_278`

### movie_279: From Dusk Till Dawn
{: #movie_279 }
- **Network:** `movie_279`: undirected, valued; 21 nodes, 86 edges.
- **Description:** Interactions of characters in the movie "From Dusk Till Dawn" (1996)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0116367
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_279`

### movie_28: Airplane II: The Sequel
{: #movie_28 }
- **Network:** `movie_28`: undirected, valued; 95 nodes, 378 edges.
- **Description:** Interactions of characters in the movie "Airplane II: The Sequel" (1982)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0083530
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_28`

### movie_280: Cashback
{: #movie_280 }
- **Network:** `movie_280`: undirected, valued; 9 nodes, 21 edges.
- **Description:** Interactions of characters in the movie "Cashback" (2006)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0460740
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_280`

### movie_281: Frozen River
{: #movie_281 }
- **Network:** `movie_281`: undirected, valued; 22 nodes, 32 edges.
- **Description:** Interactions of characters in the movie "Frozen River" (2008)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0978759
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_281`

### movie_282: The Fugitive
{: #movie_282 }
- **Network:** `movie_282`: undirected, valued; 58 nodes, 146 edges.
- **Description:** Interactions of characters in the movie "The Fugitive" (1993)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0106977
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_282`

### movie_283: Funny People
{: #movie_283 }
- **Network:** `movie_283`: undirected, valued; 43 nodes, 104 edges.
- **Description:** Interactions of characters in the movie "Funny People" (2009)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1201167
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_283`

### movie_284: G.I. Jane
{: #movie_284 }
- **Network:** `movie_284`: undirected, valued; 41 nodes, 141 edges.
- **Description:** Interactions of characters in the movie "G.I. Jane" (1997)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0119173
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_284`

### movie_285: G.I. Joe: The Rise of Cobra
{: #movie_285 }
- **Network:** `movie_285`: undirected, valued; 29 nodes, 84 edges.
- **Description:** Interactions of characters in the movie "G.I. Joe: The Rise of Cobra" (2009)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1046173
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_285`

### movie_286: Game 6
{: #movie_286 }
- **Network:** `movie_286`: undirected, valued; 33 nodes, 73 edges.
- **Description:** Interactions of characters in the movie "Game 6" (2005)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0425055
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_286`

### movie_287: The Game
{: #movie_287 }
- **Network:** `movie_287`: undirected, valued; 49 nodes, 116 edges.
- **Description:** Interactions of characters in the movie "The Game" (1997)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0119174
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_287`

### movie_288: Gamer
{: #movie_288 }
- **Network:** `movie_288`: undirected, valued; 43 nodes, 104 edges.
- **Description:** Interactions of characters in the movie "Gamer" (2009)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1034032
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_288`

### movie_289: Gandhi
{: #movie_289 }
- **Network:** `movie_289`: undirected, valued; 76 nodes, 200 edges.
- **Description:** Interactions of characters in the movie "Gandhi" (1982)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0083987
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_289`

### movie_29: Ali
{: #movie_29 }
- **Network:** `movie_29`: undirected, valued; 75 nodes, 249 edges.
- **Description:** Interactions of characters in the movie "Ali" (2001)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0248667
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_29`

### movie_290: Gang Related
{: #movie_290 }
- **Network:** `movie_290`: undirected, valued; 57 nodes, 189 edges.
- **Description:** Interactions of characters in the movie "Gang Related" (1997)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0118900
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_290`

### movie_291: Gangs of New York
{: #movie_291 }
- **Network:** `movie_291`: undirected, valued; 70 nodes, 266 edges.
- **Description:** Interactions of characters in the movie "Gangs of New York" (2002)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0217505
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_291`

### movie_292: Gattaca
{: #movie_292 }
- **Network:** `movie_292`: undirected, valued; 30 nodes, 71 edges.
- **Description:** Interactions of characters in the movie "Gattaca" (1997)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0119177
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_292`

### movie_293: Get Carter
{: #movie_293 }
- **Network:** `movie_293`: undirected, valued; 27 nodes, 58 edges.
- **Description:** Interactions of characters in the movie "Get Carter" (1971)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0067128
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_293`

### movie_294: The Getaway
{: #movie_294 }
- **Network:** `movie_294`: undirected, valued; 31 nodes, 60 edges.
- **Description:** Interactions of characters in the movie "The Getaway" (1972)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0068638
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_294`

### movie_295: Ghost
{: #movie_295 }
- **Network:** `movie_295`: undirected, valued; 37 nodes, 118 edges.
- **Description:** Interactions of characters in the movie "Ghost" (1990)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0099653
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_295`

### movie_296: Ghost Rider
{: #movie_296 }
- **Network:** `movie_296`: undirected, valued; 74 nodes, 251 edges.
- **Description:** Interactions of characters in the movie "Ghost Rider" (2007)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0259324
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_296`

### movie_297: Ghost Ship
{: #movie_297 }
- **Network:** `movie_297`: undirected, valued; 15 nodes, 46 edges.
- **Description:** Interactions of characters in the movie "Ghost Ship" (2002)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0288477
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_297`

### movie_298: Ghost World
{: #movie_298 }
- **Network:** `movie_298`: undirected, valued; 53 nodes, 144 edges.
- **Description:** Interactions of characters in the movie "Ghost World" (2001)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0162346
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_298`

### movie_299: Ghostbusters
{: #movie_299 }
- **Network:** `movie_299`: undirected, valued; 14 nodes, 41 edges.
- **Description:** Interactions of characters in the movie "Ghostbusters" (1984)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0087332
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_299`

### movie_3: Twelve and Holding
{: #movie_3 }
- **Network:** `movie_3`: undirected, valued; 25 nodes, 47 edges.
- **Description:** Interactions of characters in the movie "Twelve and Holding" (2005)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0417385
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_3`

### movie_30: Alien 3
{: #movie_30 }
- **Network:** `movie_30`: undirected, valued; 25 nodes, 77 edges.
- **Description:** Interactions of characters in the movie "Alien 3" (1992)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0103644
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_30`

### movie_300: Ghostbusters II
{: #movie_300 }
- **Network:** `movie_300`: undirected, valued; 33 nodes, 106 edges.
- **Description:** Interactions of characters in the movie "Ghostbusters II" (1989)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0097428
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_300`

### movie_301: Ginger Snaps
{: #movie_301 }
- **Network:** `movie_301`: undirected, valued; 27 nodes, 82 edges.
- **Description:** Interactions of characters in the movie "Ginger Snaps" (2000)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0210070
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_301`

### movie_302: Gladiator
{: #movie_302 }
- **Network:** `movie_302`: undirected, valued; 29 nodes, 82 edges.
- **Description:** Interactions of characters in the movie "Gladiator" (2000)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0172495
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_302`

### movie_303: Go
{: #movie_303 }
- **Network:** `movie_303`: undirected, valued; 34 nodes, 96 edges.
- **Description:** Interactions of characters in the movie "Go" (1999)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0139239
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_303`

### movie_304: The Godfather
{: #movie_304 }
- **Network:** `movie_304`: undirected, valued; 42 nodes, 104 edges.
- **Description:** Interactions of characters in the movie "The Godfather" (1972)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0068646
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_304`

### movie_305: The Godfather: Part II
{: #movie_305 }
- **Network:** `movie_305`: undirected, valued; 78 nodes, 219 edges.
- **Description:** Interactions of characters in the movie "The Godfather: Part II" (1974)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0071562
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_305`

### movie_306: Gods and Monsters
{: #movie_306 }
- **Network:** `movie_306`: undirected, valued; 26 nodes, 70 edges.
- **Description:** Interactions of characters in the movie "Gods and Monsters" (1998)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0120684
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_306`

### movie_307: Godzilla
{: #movie_307 }
- **Network:** `movie_307`: undirected, valued; 49 nodes, 151 edges.
- **Description:** Interactions of characters in the movie "Godzilla" (1998)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0120685
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_307`

### movie_308: Gone in Sixty Seconds
{: #movie_308 }
- **Network:** `movie_308`: undirected, valued; 39 nodes, 117 edges.
- **Description:** Interactions of characters in the movie "Gone in Sixty Seconds" (2000)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0187078
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_308`

### movie_309: Good Will Hunting
{: #movie_309 }
- **Network:** `movie_309`: undirected, valued; 31 nodes, 65 edges.
- **Description:** Interactions of characters in the movie "Good Will Hunting" (1997)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0119217
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_309`

### movie_31: Alien Nation
{: #movie_31 }
- **Network:** `movie_31`: undirected, valued; 30 nodes, 82 edges.
- **Description:** Interactions of characters in the movie "Alien Nation" (1988)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0094631
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_31`

### movie_310: Gothika
{: #movie_310 }
- **Network:** `movie_310`: undirected, valued; 22 nodes, 59 edges.
- **Description:** Interactions of characters in the movie "Gothika" (2003)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0348836
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_310`

### movie_311: The Graduate
{: #movie_311 }
- **Network:** `movie_311`: undirected, valued; 34 nodes, 97 edges.
- **Description:** Interactions of characters in the movie "The Graduate" (1967)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0061722
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_311`

### movie_312: Gran Torino
{: #movie_312 }
- **Network:** `movie_312`: undirected, valued; 39 nodes, 105 edges.
- **Description:** Interactions of characters in the movie "Gran Torino" (2008)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1205489
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_312`

### movie_313: Grand Theft Parsons
{: #movie_313 }
- **Network:** `movie_313`: undirected, valued; 28 nodes, 59 edges.
- **Description:** Interactions of characters in the movie "Grand Theft Parsons" (2003)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0338075
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_313`

### movie_314: The Green Mile
{: #movie_314 }
- **Network:** `movie_314`: undirected, valued; 47 nodes, 268 edges.
- **Description:** Interactions of characters in the movie "The Green Mile" (1999)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0120689
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_314`

### movie_315: Gremlins
{: #movie_315 }
- **Network:** `movie_315`: undirected, valued; 51 nodes, 286 edges.
- **Description:** Interactions of characters in the movie "Gremlins" (1984)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0087363
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_315`

### movie_316: Gremlins 2: The New Batch
{: #movie_316 }
- **Network:** `movie_316`: undirected, valued; 64 nodes, 251 edges.
- **Description:** Interactions of characters in the movie "Gremlins 2: The New Batch" (1990)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0099700
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_316`

### movie_317: The Grifters
{: #movie_317 }
- **Network:** `movie_317`: undirected, valued; 33 nodes, 61 edges.
- **Description:** Interactions of characters in the movie "The Grifters" (1990)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0099703
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_317`

### movie_318: Grosse Pointe Blank
{: #movie_318 }
- **Network:** `movie_318`: undirected, valued; 39 nodes, 84 edges.
- **Description:** Interactions of characters in the movie "Grosse Pointe Blank" (1997)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0119229
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_318`

### movie_319: Groundhog Day
{: #movie_319 }
- **Network:** `movie_319`: undirected, valued; 54 nodes, 139 edges.
- **Description:** Interactions of characters in the movie "Groundhog Day" (1993)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0107048
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_319`

### movie_32: AVP: Alien vs. Predator
{: #movie_32 }
- **Network:** `movie_32`: undirected, valued; 24 nodes, 76 edges.
- **Description:** Interactions of characters in the movie "AVP: Alien vs. Predator" (2004)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0370263
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_32`

### movie_320: The Grudge
{: #movie_320 }
- **Network:** `movie_320`: undirected, valued; 20 nodes, 30 edges.
- **Description:** Interactions of characters in the movie "The Grudge" (2004)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0391198
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_320`

### movie_321: Hackers
{: #movie_321 }
- **Network:** `movie_321`: undirected, valued; 51 nodes, 190 edges.
- **Description:** Interactions of characters in the movie "Hackers" (1995)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0113243
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_321`

### movie_322: Halloween: The Curse of Michael Myers
{: #movie_322 }
- **Network:** `movie_322`: undirected, valued; 50 nodes, 181 edges.
- **Description:** Interactions of characters in the movie "Halloween: The Curse of Michael Myers" (1995)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0113253
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_322`

### movie_323: Hancock
{: #movie_323 }
- **Network:** `movie_323`: undirected, valued; 44 nodes, 87 edges.
- **Description:** Interactions of characters in the movie "Hancock" (2008)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0448157
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_323`

### movie_324: The Hangover
{: #movie_324 }
- **Network:** `movie_324`: undirected, valued; 37 nodes, 158 edges.
- **Description:** Interactions of characters in the movie "The Hangover" (2009)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1119646
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_324`

### movie_325: Hannah and Her Sisters
{: #movie_325 }
- **Network:** `movie_325`: undirected, valued; 42 nodes, 134 edges.
- **Description:** Interactions of characters in the movie "Hannah and Her Sisters" (1986)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0091167
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_325`

### movie_326: Hard to Kill
{: #movie_326 }
- **Network:** `movie_326`: undirected, valued; 30 nodes, 54 edges.
- **Description:** Interactions of characters in the movie "Hard to Kill" (1990)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0099739
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_326`

### movie_327: Harold & Kumar Go to White Castle
{: #movie_327 }
- **Network:** `movie_327`: undirected, valued; 41 nodes, 138 edges.
- **Description:** Interactions of characters in the movie "Harold & Kumar Go to White Castle" (2004)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0366551
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_327`

### movie_328: The Haunting
{: #movie_328 }
- **Network:** `movie_328`: undirected, valued; 15 nodes, 35 edges.
- **Description:** Interactions of characters in the movie "The Haunting" (1999)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0171363
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_328`

### movie_329: He's Just Not That Into You
{: #movie_329 }
- **Network:** `movie_329`: undirected, valued; 51 nodes, 114 edges.
- **Description:** Interactions of characters in the movie "He's Just Not That Into You" (2009)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1001508
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_329`

### movie_33: Alien: Resurrection
{: #movie_33 }
- **Network:** `movie_33`: undirected, valued; 27 nodes, 141 edges.
- **Description:** Interactions of characters in the movie "Alien: Resurrection" (1997)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0118583
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_33`

### movie_330: Heat
{: #movie_330 }
- **Network:** `movie_330`: undirected, valued; 59 nodes, 135 edges.
- **Description:** Interactions of characters in the movie "Heat" (1995)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0113277
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_330`

### movie_331: Heathers
{: #movie_331 }
- **Network:** `movie_331`: undirected, valued; 44 nodes, 231 edges.
- **Description:** Interactions of characters in the movie "Heathers" (1988)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0097493
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_331`

### movie_332: Heavenly Creatures
{: #movie_332 }
- **Network:** `movie_332`: undirected, valued; 13 nodes, 25 edges.
- **Description:** Interactions of characters in the movie "Heavenly Creatures" (1994)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0110005
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_332`

### movie_333: The Hebrew Hammer
{: #movie_333 }
- **Network:** `movie_333`: undirected, valued; 39 nodes, 121 edges.
- **Description:** Interactions of characters in the movie "The Hebrew Hammer" (2003)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0317640
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_333`

### movie_334: Hellbound: Hellraiser II
{: #movie_334 }
- **Network:** `movie_334`: undirected, valued; 16 nodes, 46 edges.
- **Description:** Interactions of characters in the movie "Hellbound: Hellraiser II" (1988)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0095294
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_334`

### movie_335: Hellboy
{: #movie_335 }
- **Network:** `movie_335`: undirected, valued; 38 nodes, 91 edges.
- **Description:** Interactions of characters in the movie "Hellboy" (2004)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0167190
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_335`

### movie_336: Hellboy II: The Golden Army
{: #movie_336 }
- **Network:** `movie_336`: undirected, valued; 35 nodes, 148 edges.
- **Description:** Interactions of characters in the movie "Hellboy II: The Golden Army" (2008)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0411477
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_336`

### movie_337: Hellraiser
{: #movie_337 }
- **Network:** `movie_337`: undirected, valued; 16 nodes, 42 edges.
- **Description:** Interactions of characters in the movie "Hellraiser" (1987)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0093177
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_337`

### movie_338: Hellraiser III: Hell on Earth
{: #movie_338 }
- **Network:** `movie_338`: undirected, valued; 42 nodes, 112 edges.
- **Description:** Interactions of characters in the movie "Hellraiser III: Hell on Earth" (1992)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0104409
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_338`

### movie_339: Hellraiser: Deader
{: #movie_339 }
- **Network:** `movie_339`: undirected, valued; 21 nodes, 70 edges.
- **Description:** Interactions of characters in the movie "Hellraiser: Deader" (2005)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0337636
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_339`

### movie_34: Aliens
{: #movie_34 }
- **Network:** `movie_34`: undirected, valued; 24 nodes, 106 edges.
- **Description:** Interactions of characters in the movie "Aliens" (1986)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0090605
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_34`

### movie_340: Hellraiser: Hellseeker
{: #movie_340 }
- **Network:** `movie_340`: undirected, valued; 35 nodes, 84 edges.
- **Description:** Interactions of characters in the movie "Hellraiser: Hellseeker" (2002)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0274546
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_340`

### movie_341: Henry Fool
{: #movie_341 }
- **Network:** `movie_341`: undirected, valued; 31 nodes, 79 edges.
- **Description:** Interactions of characters in the movie "Henry Fool" (1997)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0122529
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_341`

### movie_342: High Fidelity
{: #movie_342 }
- **Network:** `movie_342`: undirected, valued; 28 nodes, 67 edges.
- **Description:** Interactions of characters in the movie "High Fidelity" (2000)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0146882
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_342`

### movie_343: Highlander
{: #movie_343 }
- **Network:** `movie_343`: undirected, valued; 59 nodes, 108 edges.
- **Description:** Interactions of characters in the movie "Highlander" (1986)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0091203
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_343`

### movie_344: Highlander: Endgame
{: #movie_344 }
- **Network:** `movie_344`: undirected, valued; 49 nodes, 134 edges.
- **Description:** Interactions of characters in the movie "Highlander: Endgame" (2000)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0144964
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_344`

### movie_345: His Girl Friday
{: #movie_345 }
- **Network:** `movie_345`: undirected, valued; 40 nodes, 154 edges.
- **Description:** Interactions of characters in the movie "His Girl Friday" (1940)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0032599
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_345`

### movie_346: The Hitchhiker's Guide to the Galaxy
{: #movie_346 }
- **Network:** `movie_346`: undirected, valued; 31 nodes, 101 edges.
- **Description:** Interactions of characters in the movie "The Hitchhiker's Guide to the Galaxy" (2005)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0371724
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_346`

### movie_347: Hollow Man
{: #movie_347 }
- **Network:** `movie_347`: undirected, valued; 13 nodes, 35 edges.
- **Description:** Interactions of characters in the movie "Hollow Man" (2000)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0164052
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_347`

### movie_348: Honeydripper
{: #movie_348 }
- **Network:** `movie_348`: undirected, valued; 33 nodes, 114 edges.
- **Description:** Interactions of characters in the movie "Honeydripper" (2007)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0829193
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_348`

### movie_349: The Horse Whisperer
{: #movie_349 }
- **Network:** `movie_349`: undirected, valued; 26 nodes, 86 edges.
- **Description:** Interactions of characters in the movie "The Horse Whisperer" (1998)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0119314
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_349`

### movie_35: All About Eve
{: #movie_35 }
- **Network:** `movie_35`: undirected, valued; 19 nodes, 79 edges.
- **Description:** Interactions of characters in the movie "All About Eve" (1950)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0042192
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_35`

### movie_350: The Kingdom
{: #movie_350 }
- **Network:** `movie_350`: undirected, valued; 50 nodes, 148 edges.
- **Description:** Interactions of characters in the movie "The Kingdom" (1994)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0108906
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_350`

### movie_351: Hostage
{: #movie_351 }
- **Network:** `movie_351`: undirected, valued; 38 nodes, 105 edges.
- **Description:** Interactions of characters in the movie "Hostage" (2005)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0340163
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_351`

### movie_352: Hot Tub Time Machine
{: #movie_352 }
- **Network:** `movie_352`: undirected, valued; 33 nodes, 138 edges.
- **Description:** Interactions of characters in the movie "Hot Tub Time Machine" (2010)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1231587
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_352`

### movie_353: Hotel Rwanda
{: #movie_353 }
- **Network:** `movie_353`: undirected, valued; 66 nodes, 182 edges.
- **Description:** Interactions of characters in the movie "Hotel Rwanda" (2004)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0395169
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_353`

### movie_354: House of 1000 Corpses
{: #movie_354 }
- **Network:** `movie_354`: undirected, valued; 33 nodes, 121 edges.
- **Description:** Interactions of characters in the movie "House of 1000 Corpses" (2003)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0251736
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_354`

### movie_355: Hudson Hawk
{: #movie_355 }
- **Network:** `movie_355`: undirected, valued; 24 nodes, 97 edges.
- **Description:** Interactions of characters in the movie "Hudson Hawk" (1991)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0102070
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_355`

### movie_356: The Hudsucker Proxy
{: #movie_356 }
- **Network:** `movie_356`: undirected, valued; 57 nodes, 180 edges.
- **Description:** Interactions of characters in the movie "The Hudsucker Proxy" (1994)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0110074
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_356`

### movie_357: Human Nature
{: #movie_357 }
- **Network:** `movie_357`: undirected, valued; 18 nodes, 38 edges.
- **Description:** Interactions of characters in the movie "Human Nature" (2001)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0219822
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_357`

### movie_358: I Am Sam
{: #movie_358 }
- **Network:** `movie_358`: undirected, valued; 47 nodes, 140 edges.
- **Description:** Interactions of characters in the movie "I Am Sam" (2001)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0277027
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_358`

### movie_359: I Love You Phillip Morris
{: #movie_359 }
- **Network:** `movie_359`: undirected, valued; 51 nodes, 94 edges.
- **Description:** Interactions of characters in the movie "I Love You Phillip Morris" (2009)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1045772
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_359`

### movie_36: All About Steve
{: #movie_36 }
- **Network:** `movie_36`: undirected, valued; 44 nodes, 110 edges.
- **Description:** Interactions of characters in the movie "All About Steve" (2009)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0881891
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_36`

### movie_360: I Still Know What You Did Last Summer
{: #movie_360 }
- **Network:** `movie_360`: undirected, valued; 18 nodes, 46 edges.
- **Description:** Interactions of characters in the movie "I Still Know What You Did Last Summer" (1998)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0130018
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_360`

### movie_361: I'll Do Anything
{: #movie_361 }
- **Network:** `movie_361`: undirected, valued; 47 nodes, 189 edges.
- **Description:** Interactions of characters in the movie "I'll Do Anything" (1994)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0110097
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_361`

### movie_362: I, Robot
{: #movie_362 }
- **Network:** `movie_362`: undirected, valued; 29 nodes, 72 edges.
- **Description:** Interactions of characters in the movie "I, Robot" (2004)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0343818
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_362`

### movie_363: The Ice Storm
{: #movie_363 }
- **Network:** `movie_363`: undirected, valued; 29 nodes, 65 edges.
- **Description:** Interactions of characters in the movie "The Ice Storm" (1997)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0119349
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_363`

### movie_364: The Imaginarium of Doctor Parnassus
{: #movie_364 }
- **Network:** `movie_364`: undirected, valued; 39 nodes, 183 edges.
- **Description:** Interactions of characters in the movie "The Imaginarium of Doctor Parnassus" (2009)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1054606
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_364`

### movie_365: In the Loop
{: #movie_365 }
- **Network:** `movie_365`: undirected, valued; 33 nodes, 130 edges.
- **Description:** Interactions of characters in the movie "In the Loop" (2009)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1226774
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_365`

### movie_366: Independence Day
{: #movie_366 }
- **Network:** `movie_366`: undirected, valued; 66 nodes, 209 edges.
- **Description:** Interactions of characters in the movie "Independence Day" (1996)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0116629
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_366`

### movie_367: Indiana Jones and the Last Crusade
{: #movie_367 }
- **Network:** `movie_367`: undirected, valued; 24 nodes, 65 edges.
- **Description:** Interactions of characters in the movie "Indiana Jones and the Last Crusade" (1989)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0097576
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_367`

### movie_368: Indiana Jones and the Temple of Doom
{: #movie_368 }
- **Network:** `movie_368`: undirected, valued; 16 nodes, 41 edges.
- **Description:** Interactions of characters in the movie "Indiana Jones and the Temple of Doom" (1984)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0087469
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_368`

### movie_369: Raiders of the Lost Ark
{: #movie_369 }
- **Network:** `movie_369`: undirected, valued; 32 nodes, 134 edges.
- **Description:** Interactions of characters in the movie "Raiders of the Lost Ark" (1981)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0082971
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_369`

### movie_37: All the King's Men
{: #movie_37 }
- **Network:** `movie_37`: undirected, valued; 37 nodes, 145 edges.
- **Description:** Interactions of characters in the movie "All the King's Men" (1949)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0041113
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_37`

### movie_370: The Insider
{: #movie_370 }
- **Network:** `movie_370`: undirected, valued; 45 nodes, 109 edges.
- **Description:** Interactions of characters in the movie "The Insider" (1999)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0140352
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_370`

### movie_371: Insomnia
{: #movie_371 }
- **Network:** `movie_371`: undirected, valued; 32 nodes, 91 edges.
- **Description:** Interactions of characters in the movie "Insomnia" (2002)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0278504
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_371`

### movie_372: Interview with the Vampire: The Vampire Chronicles
{: #movie_372 }
- **Network:** `movie_372`: undirected, valued; 23 nodes, 56 edges.
- **Description:** Interactions of characters in the movie "Interview with the Vampire: The Vampire Chronicles" (1994)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0110148
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_372`

### movie_373: Into the Wild
{: #movie_373 }
- **Network:** `movie_373`: undirected, valued; 27 nodes, 38 edges.
- **Description:** Interactions of characters in the movie "Into the Wild" (2007)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0758758
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_373`

### movie_374: Intolerable Cruelty
{: #movie_374 }
- **Network:** `movie_374`: undirected, valued; 40 nodes, 113 edges.
- **Description:** Interactions of characters in the movie "Intolerable Cruelty" (2003)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0138524
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_374`

### movie_375: Inventing the Abbotts
{: #movie_375 }
- **Network:** `movie_375`: undirected, valued; 17 nodes, 39 edges.
- **Description:** Interactions of characters in the movie "Inventing the Abbotts" (1997)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0119381
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_375`

### movie_376: The Invention of Lying
{: #movie_376 }
- **Network:** `movie_376`: undirected, valued; 61 nodes, 291 edges.
- **Description:** Interactions of characters in the movie "The Invention of Lying" (2009)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1058017
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_376`

### movie_377: The Island
{: #movie_377 }
- **Network:** `movie_377`: undirected, valued; 27 nodes, 45 edges.
- **Description:** Interactions of characters in the movie "The Island" (2005)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0399201
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_377`

### movie_378: It's a Wonderful Life
{: #movie_378 }
- **Network:** `movie_378`: undirected, valued; 70 nodes, 339 edges.
- **Description:** Interactions of characters in the movie "It's a Wonderful Life" (1946)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0038650
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_378`

### movie_379: It's Complicated
{: #movie_379 }
- **Network:** `movie_379`: undirected, valued; 28 nodes, 81 edges.
- **Description:** Interactions of characters in the movie "It's Complicated" (2009)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1230414
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_379`

### movie_38: Almost Famous
{: #movie_38 }
- **Network:** `movie_38`: undirected, valued; 53 nodes, 206 edges.
- **Description:** Interactions of characters in the movie "Almost Famous" (2000)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0181875
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_38`

### movie_380: The Italian Job
{: #movie_380 }
- **Network:** `movie_380`: undirected, valued; 29 nodes, 57 edges.
- **Description:** Interactions of characters in the movie "The Italian Job" (2003)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0317740
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_380`

### movie_381: The Jacket
{: #movie_381 }
- **Network:** `movie_381`: undirected, valued; 26 nodes, 47 edges.
- **Description:** Interactions of characters in the movie "The Jacket" (2005)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0366627
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_381`

### movie_382: Jackie Brown
{: #movie_382 }
- **Network:** `movie_382`: undirected, valued; 25 nodes, 61 edges.
- **Description:** Interactions of characters in the movie "Jackie Brown" (1997)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0119396
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_382`

### movie_383: Jacob's Ladder
{: #movie_383 }
- **Network:** `movie_383`: undirected, valued; 54 nodes, 144 edges.
- **Description:** Interactions of characters in the movie "Jacob's Ladder" (1990)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0099871
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_383`

### movie_384: Jason X
{: #movie_384 }
- **Network:** `movie_384`: undirected, valued; 26 nodes, 150 edges.
- **Description:** Interactions of characters in the movie "Jason X" (2001)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0211443
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_384`

### movie_385: Jaws
{: #movie_385 }
- **Network:** `movie_385`: undirected, valued; 36 nodes, 85 edges.
- **Description:** Interactions of characters in the movie "Jaws" (1975)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0073195
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_385`

### movie_386: Jaws 2
{: #movie_386 }
- **Network:** `movie_386`: undirected, valued; 49 nodes, 232 edges.
- **Description:** Interactions of characters in the movie "Jaws 2" (1978)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0077766
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_386`

### movie_387: Jay and Silent Bob Strike Back
{: #movie_387 }
- **Network:** `movie_387`: undirected, valued; 61 nodes, 228 edges.
- **Description:** Interactions of characters in the movie "Jay and Silent Bob Strike Back" (2001)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0261392
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_387`

### movie_388: Jennifer Eight
{: #movie_388 }
- **Network:** `movie_388`: undirected, valued; 25 nodes, 61 edges.
- **Description:** Interactions of characters in the movie "Jennifer Eight" (1992)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0104549
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_388`

### movie_389: Jennifer's Body
{: #movie_389 }
- **Network:** `movie_389`: undirected, valued; 26 nodes, 55 edges.
- **Description:** Interactions of characters in the movie "Jennifer's Body" (2009)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1131734
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_389`

### movie_39: Alone in the Dark
{: #movie_39 }
- **Network:** `movie_39`: undirected, valued; 27 nodes, 71 edges.
- **Description:** Interactions of characters in the movie "Alone in the Dark" (2005)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0369226
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_39`

### movie_390: Jerry Maguire
{: #movie_390 }
- **Network:** `movie_390`: undirected, valued; 48 nodes, 128 edges.
- **Description:** Interactions of characters in the movie "Jerry Maguire" (1996)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0116695
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_390`

### movie_391: JFK
{: #movie_391 }
- **Network:** `movie_391`: undirected, valued; 101 nodes, 293 edges.
- **Description:** Interactions of characters in the movie "JFK" (1991)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0102138
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_391`

### movie_392: Jimmy and Judy
{: #movie_392 }
- **Network:** `movie_392`: undirected, valued; 19 nodes, 42 edges.
- **Description:** Interactions of characters in the movie "Jimmy and Judy" (2006)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0425151
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_392`

### movie_393: John Q
{: #movie_393 }
- **Network:** `movie_393`: undirected, valued; 46 nodes, 190 edges.
- **Description:** Interactions of characters in the movie "John Q" (2002)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0251160
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_393`

### movie_394: Juno
{: #movie_394 }
- **Network:** `movie_394`: undirected, valued; 25 nodes, 55 edges.
- **Description:** Interactions of characters in the movie "Juno" (2007)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0467406
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_394`

### movie_395: Jurassic Park
{: #movie_395 }
- **Network:** `movie_395`: undirected, valued; 24 nodes, 115 edges.
- **Description:** Interactions of characters in the movie "Jurassic Park" (1993)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0107290
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_395`

### movie_396: Jurassic Park III
{: #movie_396 }
- **Network:** `movie_396`: undirected, valued; 20 nodes, 57 edges.
- **Description:** Interactions of characters in the movie "Jurassic Park III" (2001)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0163025
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_396`

### movie_397: The Lost World: Jurassic Park
{: #movie_397 }
- **Network:** `movie_397`: undirected, valued; 27 nodes, 93 edges.
- **Description:** Interactions of characters in the movie "The Lost World: Jurassic Park" (1997)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0119567
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_397`

### movie_398: Kalifornia
{: #movie_398 }
- **Network:** `movie_398`: undirected, valued; 43 nodes, 159 edges.
- **Description:** Interactions of characters in the movie "Kalifornia" (1993)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0107302
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_398`

### movie_399: Kate & Leopold
{: #movie_399 }
- **Network:** `movie_399`: undirected, valued; 24 nodes, 54 edges.
- **Description:** Interactions of characters in the movie "Kate & Leopold" (2001)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0035423
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_399`

### movie_4: 127 Hours
{: #movie_4 }
- **Network:** `movie_4`: undirected, valued; 9 nodes, 10 edges.
- **Description:** Interactions of characters in the movie "127 Hours" (2010)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1542344
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_4`

### movie_40: Amadeus
{: #movie_40 }
- **Network:** `movie_40`: undirected, valued; 43 nodes, 152 edges.
- **Description:** Interactions of characters in the movie "Amadeus" (1984)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0086879
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_40`

### movie_400: Kids
{: #movie_400 }
- **Network:** `movie_400`: undirected, valued; 41 nodes, 130 edges.
- **Description:** Interactions of characters in the movie "Kids" (1995)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0113540
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_400`

### movie_401: Kill Bill: Vol. 1
{: #movie_401 }
- **Network:** `movie_401`: undirected, valued; 38 nodes, 78 edges.
- **Description:** Interactions of characters in the movie "Kill Bill: Vol. 1" (2003)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0266697
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_401`

### movie_402: Killing Zoe
{: #movie_402 }
- **Network:** `movie_402`: undirected, valued; 21 nodes, 64 edges.
- **Description:** Interactions of characters in the movie "Killing Zoe" (1993)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0110265
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_402`

### movie_403: King Kong
{: #movie_403 }
- **Network:** `movie_403`: undirected, valued; 50 nodes, 169 edges.
- **Description:** Interactions of characters in the movie "King Kong" (2005)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0360717
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_403`

### movie_404: The King of Comedy
{: #movie_404 }
- **Network:** `movie_404`: undirected, valued; 43 nodes, 144 edges.
- **Description:** Interactions of characters in the movie "The King of Comedy" (1982)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0085794
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_404`

### movie_405: The King's Speech
{: #movie_405 }
- **Network:** `movie_405`: undirected, valued; 26 nodes, 80 edges.
- **Description:** Interactions of characters in the movie "The King's Speech" (2010)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1504320
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_405`

### movie_406: Indiana Jones and the Kingdom of the Crystal Skull
{: #movie_406 }
- **Network:** `movie_406`: undirected, valued; 44 nodes, 182 edges.
- **Description:** Interactions of characters in the movie "Indiana Jones and the Kingdom of the Crystal Skull" (2008)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0367882
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_406`

### movie_407: Klute
{: #movie_407 }
- **Network:** `movie_407`: undirected, valued; 37 nodes, 71 edges.
- **Description:** Interactions of characters in the movie "Klute" (1971)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0067309
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_407`

### movie_408: Kramer vs. Kramer
{: #movie_408 }
- **Network:** `movie_408`: undirected, valued; 57 nodes, 266 edges.
- **Description:** Interactions of characters in the movie "Kramer vs. Kramer" (1979)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0079417
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_408`

### movie_409: Kundun
{: #movie_409 }
- **Network:** `movie_409`: undirected, valued; 33 nodes, 60 edges.
- **Description:** Interactions of characters in the movie "Kundun" (1997)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0119485
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_409`

### movie_41: Amelia
{: #movie_41 }
- **Network:** `movie_41`: undirected, valued; 26 nodes, 54 edges.
- **Description:** Interactions of characters in the movie "Amelia" (2001)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0211915
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_41`

### movie_410: Kung Fu Panda
{: #movie_410 }
- **Network:** `movie_410`: undirected, valued; 21 nodes, 70 edges.
- **Description:** Interactions of characters in the movie "Kung Fu Panda" (2008)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0441773
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_410`

### movie_411: L.A. Confidential
{: #movie_411 }
- **Network:** `movie_411`: undirected, valued; 53 nodes, 131 edges.
- **Description:** Interactions of characters in the movie "L.A. Confidential" (1997)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0119488
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_411`

### movie_412: The Ladykillers
{: #movie_412 }
- **Network:** `movie_412`: undirected, valued; 33 nodes, 86 edges.
- **Description:** Interactions of characters in the movie "The Ladykillers" (2004)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0335245
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_412`

### movie_413: Lake Placid
{: #movie_413 }
- **Network:** `movie_413`: undirected, valued; 22 nodes, 65 edges.
- **Description:** Interactions of characters in the movie "Lake Placid" (1999)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0139414
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_413`

### movie_414: Land of the Dead
{: #movie_414 }
- **Network:** `movie_414`: undirected, valued; 51 nodes, 221 edges.
- **Description:** Interactions of characters in the movie "Land of the Dead" (2005)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0418819
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_414`

### movie_415: The Last Boy Scout
{: #movie_415 }
- **Network:** `movie_415`: undirected, valued; 44 nodes, 100 edges.
- **Description:** Interactions of characters in the movie "The Last Boy Scout" (1991)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0102266
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_415`

### movie_416: Last Chance Harvey
{: #movie_416 }
- **Network:** `movie_416`: undirected, valued; 41 nodes, 96 edges.
- **Description:** Interactions of characters in the movie "Last Chance Harvey" (2008)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1046947
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_416`

### movie_417: The Last Flight of Noah's Ark
{: #movie_417 }
- **Network:** `movie_417`: undirected, valued; 26 nodes, 127 edges.
- **Description:** Interactions of characters in the movie "The Last Flight of Noah's Ark" (1980)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0081031
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_417`

### movie_418: The Last of the Mohicans
{: #movie_418 }
- **Network:** `movie_418`: undirected, valued; 29 nodes, 134 edges.
- **Description:** Interactions of characters in the movie "The Last of the Mohicans" (1992)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0104691
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_418`

### movie_419: The Last Samurai
{: #movie_419 }
- **Network:** `movie_419`: undirected, valued; 20 nodes, 54 edges.
- **Description:** Interactions of characters in the movie "The Last Samurai" (2003)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0325710
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_419`

### movie_42: American Beauty
{: #movie_42 }
- **Network:** `movie_42`: undirected, valued; 22 nodes, 46 edges.
- **Description:** Interactions of characters in the movie "American Beauty" (1999)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0169547
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_42`

### movie_420: The Last Station
{: #movie_420 }
- **Network:** `movie_420`: undirected, valued; 15 nodes, 47 edges.
- **Description:** Interactions of characters in the movie "The Last Station" (2009)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0824758
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_420`

### movie_421: Law Abiding Citizen
{: #movie_421 }
- **Network:** `movie_421`: undirected, valued; 41 nodes, 117 edges.
- **Description:** Interactions of characters in the movie "Law Abiding Citizen" (2009)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1197624
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_421`

### movie_422: Leaving Las Vegas
{: #movie_422 }
- **Network:** `movie_422`: undirected, valued; 34 nodes, 57 edges.
- **Description:** Interactions of characters in the movie "Leaving Las Vegas" (1995)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0113627
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_422`

### movie_423: Legion
{: #movie_423 }
- **Network:** `movie_423`: undirected, valued; 23 nodes, 86 edges.
- **Description:** Interactions of characters in the movie "Legion" (2010)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1038686
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_423`

### movie_424: Leviathan
{: #movie_424 }
- **Network:** `movie_424`: undirected, valued; 12 nodes, 44 edges.
- **Description:** Interactions of characters in the movie "Leviathan" (1989)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0097737
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_424`

### movie_425: Liar Liar
{: #movie_425 }
- **Network:** `movie_425`: undirected, valued; 50 nodes, 187 edges.
- **Description:** Interactions of characters in the movie "Liar Liar" (1997)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0119528
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_425`

### movie_426: Life
{: #movie_426 }
- **Network:** `movie_426`: undirected, valued; 56 nodes, 212 edges.
- **Description:** Interactions of characters in the movie "Life" (1999)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0123964
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_426`

### movie_427: Life as a House
{: #movie_427 }
- **Network:** `movie_427`: undirected, valued; 29 nodes, 99 edges.
- **Description:** Interactions of characters in the movie "Life as a House" (2001)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0264796
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_427`

### movie_428: The Life of David Gale
{: #movie_428 }
- **Network:** `movie_428`: undirected, valued; 55 nodes, 143 edges.
- **Description:** Interactions of characters in the movie "The Life of David Gale" (2003)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0289992
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_428`

### movie_429: Light Sleeper
{: #movie_429 }
- **Network:** `movie_429`: undirected, valued; 23 nodes, 32 edges.
- **Description:** Interactions of characters in the movie "Light Sleeper" (1992)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0102307
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_429`

### movie_43: American Gangster
{: #movie_43 }
- **Network:** `movie_43`: undirected, valued; 59 nodes, 119 edges.
- **Description:** Interactions of characters in the movie "American Gangster" (2007)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0765429
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_43`

### movie_430: The Limey
{: #movie_430 }
- **Network:** `movie_430`: undirected, valued; 22 nodes, 48 edges.
- **Description:** Interactions of characters in the movie "The Limey" (1999)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0165854
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_430`

### movie_431: Little Athens
{: #movie_431 }
- **Network:** `movie_431`: undirected, valued; 47 nodes, 124 edges.
- **Description:** Interactions of characters in the movie "Little Athens" (2005)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0417907
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_431`

### movie_432: Little Nicky
{: #movie_432 }
- **Network:** `movie_432`: undirected, valued; 53 nodes, 202 edges.
- **Description:** Interactions of characters in the movie "Little Nicky" (2000)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0185431
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_432`

### movie_433: Living in Oblivion
{: #movie_433 }
- **Network:** `movie_433`: undirected, valued; 21 nodes, 91 edges.
- **Description:** Interactions of characters in the movie "Living in Oblivion" (1995)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0113677
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_433`

### movie_434: Lock, Stock and Two Smoking Barrels
{: #movie_434 }
- **Network:** `movie_434`: undirected, valued; 42 nodes, 134 edges.
- **Description:** Interactions of characters in the movie "Lock, Stock and Two Smoking Barrels" (1998)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0120735
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_434`

### movie_435: Logan's Run
{: #movie_435 }
- **Network:** `movie_435`: undirected, valued; 21 nodes, 69 edges.
- **Description:** Interactions of characters in the movie "Logan's Run" (1976)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0074812
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_435`

### movie_436: Lone Star
{: #movie_436 }
- **Network:** `movie_436`: undirected, valued; 52 nodes, 142 edges.
- **Description:** Interactions of characters in the movie "Lone Star" (1996)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0116905
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_436`

### movie_437: The Long Kiss Goodnight
{: #movie_437 }
- **Network:** `movie_437`: undirected, valued; 48 nodes, 114 edges.
- **Description:** Interactions of characters in the movie "The Long Kiss Goodnight" (1996)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0116908
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_437`

### movie_438: Lord of Illusions
{: #movie_438 }
- **Network:** `movie_438`: undirected, valued; 28 nodes, 64 edges.
- **Description:** Interactions of characters in the movie "Lord of Illusions" (1995)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0113690
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_438`

### movie_439: The Lord of the Rings: The Fellowship of the Ring
{: #movie_439 }
- **Network:** `movie_439`: undirected, valued; 23 nodes, 102 edges.
- **Description:** Interactions of characters in the movie "The Lord of the Rings: The Fellowship of the Ring" (2001)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0120737
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_439`

### movie_44: American History X
{: #movie_44 }
- **Network:** `movie_44`: undirected, valued; 39 nodes, 114 edges.
- **Description:** Interactions of characters in the movie "American History X" (1998)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0120586
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_44`

### movie_440: The Lord of the Rings: The Return of the King
{: #movie_440 }
- **Network:** `movie_440`: undirected, valued; 35 nodes, 98 edges.
- **Description:** Interactions of characters in the movie "The Lord of the Rings: The Return of the King" (2003)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0167260
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_440`

### movie_441: Lord of War
{: #movie_441 }
- **Network:** `movie_441`: undirected, valued; 43 nodes, 91 edges.
- **Description:** Interactions of characters in the movie "Lord of War" (2005)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0399295
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_441`

### movie_442: The Losers
{: #movie_442 }
- **Network:** `movie_442`: undirected, valued; 33 nodes, 108 edges.
- **Description:** Interactions of characters in the movie "The Losers" (2010)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0480255
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_442`

### movie_443: Lost Highway
{: #movie_443 }
- **Network:** `movie_443`: undirected, valued; 33 nodes, 78 edges.
- **Description:** Interactions of characters in the movie "Lost Highway" (1997)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0116922
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_443`

### movie_444: Lost Horizon
{: #movie_444 }
- **Network:** `movie_444`: undirected, valued; 30 nodes, 77 edges.
- **Description:** Interactions of characters in the movie "Lost Horizon" (1937)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0029162
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_444`

### movie_445: Lost in Space
{: #movie_445 }
- **Network:** `movie_445`: undirected, valued; 27 nodes, 96 edges.
- **Description:** Interactions of characters in the movie "Lost in Space" (1998)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0120738
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_445`

### movie_446: Lost in Translation
{: #movie_446 }
- **Network:** `movie_446`: undirected, valued; 27 nodes, 48 edges.
- **Description:** Interactions of characters in the movie "Lost in Translation" (2003)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0335266
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_446`

### movie_447: Love & Basketball
{: #movie_447 }
- **Network:** `movie_447`: undirected, valued; 39 nodes, 126 edges.
- **Description:** Interactions of characters in the movie "Love & Basketball" (2000)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0199725
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_447`

### movie_448: Magnolia
{: #movie_448 }
- **Network:** `movie_448`: undirected, valued; 82 nodes, 239 edges.
- **Description:** Interactions of characters in the movie "Magnolia" (1999)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0175880
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_448`

### movie_449: The Majestic
{: #movie_449 }
- **Network:** `movie_449`: undirected, valued; 47 nodes, 159 edges.
- **Description:** Interactions of characters in the movie "The Majestic" (2001)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0268995
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_449`

### movie_45: American Pie
{: #movie_45 }
- **Network:** `movie_45`: undirected, valued; 33 nodes, 106 edges.
- **Description:** Interactions of characters in the movie "American Pie" (1999)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0163651
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_45`

### movie_450: Major League
{: #movie_450 }
- **Network:** `movie_450`: undirected, valued; 54 nodes, 306 edges.
- **Description:** Interactions of characters in the movie "Major League" (1989)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0097815
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_450`

### movie_451: Malcolm X
{: #movie_451 }
- **Network:** `movie_451`: undirected, valued; 76 nodes, 174 edges.
- **Description:** Interactions of characters in the movie "Malcolm X" (1992)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0104797
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_451`

### movie_452: Malibu's Most Wanted
{: #movie_452 }
- **Network:** `movie_452`: undirected, valued; 34 nodes, 166 edges.
- **Description:** Interactions of characters in the movie "Malibu's Most Wanted" (2003)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0328099
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_452`

### movie_453: The Man in the Iron Mask
{: #movie_453 }
- **Network:** `movie_453`: undirected, valued; 38 nodes, 107 edges.
- **Description:** Interactions of characters in the movie "The Man in the Iron Mask" (1998)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0120744
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_453`

### movie_454: Man on Fire
{: #movie_454 }
- **Network:** `movie_454`: undirected, valued; 36 nodes, 73 edges.
- **Description:** Interactions of characters in the movie "Man on Fire" (2004)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0328107
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_454`

### movie_455: Man on the Moon
{: #movie_455 }
- **Network:** `movie_455`: undirected, valued; 67 nodes, 186 edges.
- **Description:** Interactions of characters in the movie "Man on the Moon" (1999)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0125664
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_455`

### movie_456: Knight and Day
{: #movie_456 }
- **Network:** `movie_456`: undirected, valued; 29 nodes, 79 edges.
- **Description:** Interactions of characters in the movie "Knight and Day" (2010)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1013743
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_456`

### movie_457: The Man Who Knew Too Much
{: #movie_457 }
- **Network:** `movie_457`: undirected, valued; 42 nodes, 109 edges.
- **Description:** Interactions of characters in the movie "The Man Who Knew Too Much" (1956)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0049470
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_457`

### movie_458: The Man Who Wasn't There
{: #movie_458 }
- **Network:** `movie_458`: undirected, valued; 38 nodes, 107 edges.
- **Description:** Interactions of characters in the movie "The Man Who Wasn't There" (2001)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0243133
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_458`

### movie_459: The Manchurian Candidate
{: #movie_459 }
- **Network:** `movie_459`: undirected, valued; 40 nodes, 131 edges.
- **Description:** Interactions of characters in the movie "The Manchurian Candidate" (1962)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0056218
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_459`

### movie_46: The American President
{: #movie_46 }
- **Network:** `movie_46`: undirected, valued; 49 nodes, 163 edges.
- **Description:** Interactions of characters in the movie "The American President" (1995)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0112346
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_46`

### movie_460: Manhunter
{: #movie_460 }
- **Network:** `movie_460`: undirected, valued; 47 nodes, 100 edges.
- **Description:** Interactions of characters in the movie "Manhunter" (1986)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0091474
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_460`

### movie_461: Margot at the Wedding
{: #movie_461 }
- **Network:** `movie_461`: undirected, valued; 16 nodes, 57 edges.
- **Description:** Interactions of characters in the movie "Margot at the Wedding" (2007)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0757361
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_461`

### movie_462: Desperado
{: #movie_462 }
- **Network:** `movie_462`: undirected, valued; 12 nodes, 20 edges.
- **Description:** Interactions of characters in the movie "Desperado" (1995)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0112851
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_462`

### movie_463: Marley & Me
{: #movie_463 }
- **Network:** `movie_463`: undirected, valued; 30 nodes, 67 edges.
- **Description:** Interactions of characters in the movie "Marley & Me" (2008)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0822832
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_463`

### movie_464: Marty
{: #movie_464 }
- **Network:** `movie_464`: undirected, valued; 26 nodes, 59 edges.
- **Description:** Interactions of characters in the movie "Marty" (1955)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0048356
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_464`

### movie_465: The Mask
{: #movie_465 }
- **Network:** `movie_465`: undirected, valued; 77 nodes, 318 edges.
- **Description:** Interactions of characters in the movie "The Mask" (1994)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0110475
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_465`

### movie_466: The Matrix Reloaded
{: #movie_466 }
- **Network:** `movie_466`: undirected, valued; 27 nodes, 81 edges.
- **Description:** Interactions of characters in the movie "The Matrix Reloaded" (2003)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0234215
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_466`

### movie_467: The Matrix
{: #movie_467 }
- **Network:** `movie_467`: undirected, valued; 31 nodes, 88 edges.
- **Description:** Interactions of characters in the movie "The Matrix" (1999)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0133093
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_467`

### movie_468: Max Payne
{: #movie_468 }
- **Network:** `movie_468`: undirected, valued; 62 nodes, 331 edges.
- **Description:** Interactions of characters in the movie "Max Payne" (2008)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0467197
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_468`

### movie_469: Meet Joe Black
{: #movie_469 }
- **Network:** `movie_469`: undirected, valued; 22 nodes, 68 edges.
- **Description:** Interactions of characters in the movie "Meet Joe Black" (1998)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0119643
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_469`

### movie_47: American Psycho
{: #movie_47 }
- **Network:** `movie_47`: undirected, valued; 26 nodes, 59 edges.
- **Description:** Interactions of characters in the movie "American Psycho" (2000)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0144084
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_47`

### movie_470: Megamind
{: #movie_470 }
- **Network:** `movie_470`: undirected, valued; 35 nodes, 96 edges.
- **Description:** Interactions of characters in the movie "Megamind" (2010)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1001526
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_470`

### movie_471: Memento
{: #movie_471 }
- **Network:** `movie_471`: undirected, valued; 14 nodes, 19 edges.
- **Description:** Interactions of characters in the movie "Memento" (2000)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0209144
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_471`

### movie_472: Men in Black
{: #movie_472 }
- **Network:** `movie_472`: undirected, valued; 32 nodes, 75 edges.
- **Description:** Interactions of characters in the movie "Men in Black" (1997)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0119654
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_472`

### movie_473: The Men Who Stare at Goats
{: #movie_473 }
- **Network:** `movie_473`: undirected, valued; 46 nodes, 96 edges.
- **Description:** Interactions of characters in the movie "The Men Who Stare at Goats" (2009)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1234548
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_473`

### movie_474: Subway
{: #movie_474 }
- **Network:** `movie_474`: undirected, valued; 54 nodes, 108 edges.
- **Description:** Interactions of characters in the movie "Subway" (1985)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0090095
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_474`

### movie_475: Miami Vice
{: #movie_475 }
- **Network:** `movie_475`: undirected, valued; 28 nodes, 82 edges.
- **Description:** Interactions of characters in the movie "Miami Vice" (2006)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0430357
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_475`

### movie_476: Midnight Cowboy
{: #movie_476 }
- **Network:** `movie_476`: undirected, valued; 28 nodes, 47 edges.
- **Description:** Interactions of characters in the movie "Midnight Cowboy" (1969)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0064665
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_476`

### movie_477: Mighty Morphin Power Rangers: The Movie
{: #movie_477 }
- **Network:** `movie_477`: undirected, valued; 36 nodes, 200 edges.
- **Description:** Interactions of characters in the movie "Mighty Morphin Power Rangers: The Movie" (1995)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0113820
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_477`

### movie_478: Milk
{: #movie_478 }
- **Network:** `movie_478`: undirected, valued; 41 nodes, 133 edges.
- **Description:** Interactions of characters in the movie "Milk" (2008)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1013753
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_478`

### movie_479: Mimic
{: #movie_479 }
- **Network:** `movie_479`: undirected, valued; 23 nodes, 52 edges.
- **Description:** Interactions of characters in the movie "Mimic" (1997)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0119675
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_479`

### movie_48: American Shaolin
{: #movie_48 }
- **Network:** `movie_48`: undirected, valued; 32 nodes, 73 edges.
- **Description:** Interactions of characters in the movie "American Shaolin" (1991)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0101327
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_48`

### movie_480: Mini's First Time
{: #movie_480 }
- **Network:** `movie_480`: undirected, valued; 42 nodes, 114 edges.
- **Description:** Interactions of characters in the movie "Mini's First Time" (2006)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0425253
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_480`

### movie_481: Minority Report
{: #movie_481 }
- **Network:** `movie_481`: undirected, valued; 51 nodes, 149 edges.
- **Description:** Interactions of characters in the movie "Minority Report" (2002)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0181689
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_481`

### movie_482: Mirrors
{: #movie_482 }
- **Network:** `movie_482`: undirected, valued; 26 nodes, 45 edges.
- **Description:** Interactions of characters in the movie "Mirrors" (2008)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0790686
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_482`

### movie_483: Mission: Impossible
{: #movie_483 }
- **Network:** `movie_483`: undirected, valued; 28 nodes, 86 edges.
- **Description:** Interactions of characters in the movie "Mission: Impossible" (1996)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0117060
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_483`

### movie_484: Mission: Impossible II
{: #movie_484 }
- **Network:** `movie_484`: undirected, valued; 22 nodes, 105 edges.
- **Description:** Interactions of characters in the movie "Mission: Impossible II" (2000)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0120755
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_484`

### movie_485: Mission to Mars
{: #movie_485 }
- **Network:** `movie_485`: undirected, valued; 40 nodes, 188 edges.
- **Description:** Interactions of characters in the movie "Mission to Mars" (2000)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0183523
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_485`

### movie_486: Monkeybone
{: #movie_486 }
- **Network:** `movie_486`: undirected, valued; 52 nodes, 146 edges.
- **Description:** Interactions of characters in the movie "Monkeybone" (2001)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0166276
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_486`

### movie_487: Moon
{: #movie_487 }
- **Network:** `movie_487`: undirected, valued; 12 nodes, 27 edges.
- **Description:** Interactions of characters in the movie "Moon" (2009)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1182345
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_487`

### movie_488: Moonstruck
{: #movie_488 }
- **Network:** `movie_488`: undirected, valued; 40 nodes, 141 edges.
- **Description:** Interactions of characters in the movie "Moonstruck" (1987)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0093565
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_488`

### movie_489: Mr. Blandings Builds His Dream House
{: #movie_489 }
- **Network:** `movie_489`: undirected, valued; 37 nodes, 157 edges.
- **Description:** Interactions of characters in the movie "Mr. Blandings Builds His Dream House" (1948)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0040613
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_489`

### movie_49: American Splendor
{: #movie_49 }
- **Network:** `movie_49`: undirected, valued; 35 nodes, 82 edges.
- **Description:** Interactions of characters in the movie "American Splendor" (2003)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0305206
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_49`

### movie_490: Mr. Brooks
{: #movie_490 }
- **Network:** `movie_490`: undirected, valued; 37 nodes, 80 edges.
- **Description:** Interactions of characters in the movie "Mr. Brooks" (2007)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0780571
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_490`

### movie_491: Mr. Deeds Goes to Town
{: #movie_491 }
- **Network:** `movie_491`: undirected, valued; 61 nodes, 331 edges.
- **Description:** Interactions of characters in the movie "Mr. Deeds Goes to Town" (1936)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0027996
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_491`

### movie_492: Her Majesty, Mrs. Brown
{: #movie_492 }
- **Network:** `movie_492`: undirected, valued; 23 nodes, 44 edges.
- **Description:** Interactions of characters in the movie "Her Majesty, Mrs. Brown" (1997)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0119280
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_492`

### movie_493: Mulholland Dr.
{: #movie_493 }
- **Network:** `movie_493`: undirected, valued; 49 nodes, 163 edges.
- **Description:** Interactions of characters in the movie "Mulholland Dr." (2001)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0166924
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_493`

### movie_494: Mumford
{: #movie_494 }
- **Network:** `movie_494`: undirected, valued; 24 nodes, 58 edges.
- **Description:** Interactions of characters in the movie "Mumford" (1999)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0140397
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_494`

### movie_495: The Mummy
{: #movie_495 }
- **Network:** `movie_495`: undirected, valued; 22 nodes, 77 edges.
- **Description:** Interactions of characters in the movie "The Mummy" (1999)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0120616
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_495`

### movie_496: Music of the Heart
{: #movie_496 }
- **Network:** `movie_496`: undirected, valued; 58 nodes, 201 edges.
- **Description:** Interactions of characters in the movie "Music of the Heart" (1999)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0166943
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_496`

### movie_497: My Best Friend's Wedding
{: #movie_497 }
- **Network:** `movie_497`: undirected, valued; 24 nodes, 69 edges.
- **Description:** Interactions of characters in the movie "My Best Friend's Wedding" (1997)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0119738
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_497`

### movie_498: My Girl
{: #movie_498 }
- **Network:** `movie_498`: undirected, valued; 33 nodes, 108 edges.
- **Description:** Interactions of characters in the movie "My Girl" (1991)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0102492
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_498`

### movie_499: My Mother Dreams the Satan's Disciples in New York
{: #movie_499 }
- **Network:** `movie_499`: undirected, valued; 18 nodes, 50 edges.
- **Description:** Interactions of characters in the movie "My Mother Dreams the Satan's Disciples in New York" (1998)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0177023
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_499`

### movie_5: 1492: Conquest of Paradise
{: #movie_5 }
- **Network:** `movie_5`: undirected, valued; 34 nodes, 86 edges.
- **Description:** Interactions of characters in the movie "1492: Conquest of Paradise" (1992)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0103594
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_5`

### movie_50: An American Werewolf in London
{: #movie_50 }
- **Network:** `movie_50`: undirected, valued; 31 nodes, 86 edges.
- **Description:** Interactions of characters in the movie "An American Werewolf in London" (1981)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0082010
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_50`

### movie_500: Mystery Men
{: #movie_500 }
- **Network:** `movie_500`: undirected, valued; 53 nodes, 299 edges.
- **Description:** Interactions of characters in the movie "Mystery Men" (1999)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0132347
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_500`

### movie_501: Nashville
{: #movie_501 }
- **Network:** `movie_501`: undirected, valued; 40 nodes, 131 edges.
- **Description:** Interactions of characters in the movie "Nashville" (1975)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0073440
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_501`

### movie_502: Natural Born Killers
{: #movie_502 }
- **Network:** `movie_502`: undirected, valued; 50 nodes, 147 edges.
- **Description:** Interactions of characters in the movie "Natural Born Killers" (1994)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0110632
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_502`

### movie_503: Newsies
{: #movie_503 }
- **Network:** `movie_503`: undirected, valued; 76 nodes, 629 edges.
- **Description:** Interactions of characters in the movie "Newsies" (1992)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0104990
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_503`

### movie_504: Next
{: #movie_504 }
- **Network:** `movie_504`: undirected, valued; 41 nodes, 150 edges.
- **Description:** Interactions of characters in the movie "Next" (2007)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0435705
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_504`

### movie_505: Next Friday
{: #movie_505 }
- **Network:** `movie_505`: undirected, valued; 21 nodes, 83 edges.
- **Description:** Interactions of characters in the movie "Next Friday" (2000)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0195945
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_505`

### movie_506: The Next Three Days
{: #movie_506 }
- **Network:** `movie_506`: undirected, valued; 43 nodes, 87 edges.
- **Description:** Interactions of characters in the movie "The Next Three Days" (2010)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1458175
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_506`

### movie_507: Nick of Time
{: #movie_507 }
- **Network:** `movie_507`: undirected, valued; 34 nodes, 100 edges.
- **Description:** Interactions of characters in the movie "Nick of Time" (1995)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0113972
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_507`

### movie_508: A Nightmare on Elm Street
{: #movie_508 }
- **Network:** `movie_508`: undirected, valued; 31 nodes, 73 edges.
- **Description:** Interactions of characters in the movie "A Nightmare on Elm Street" (1984)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0087800
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_508`

### movie_509: Freddy's Dead: The Final Nightmare
{: #movie_509 }
- **Network:** `movie_509`: undirected, valued; 36 nodes, 104 edges.
- **Description:** Interactions of characters in the movie "Freddy's Dead: The Final Nightmare" (1991)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0101917
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_509`

### movie_51: An Education
{: #movie_51 }
- **Network:** `movie_51`: undirected, valued; 18 nodes, 46 edges.
- **Description:** Interactions of characters in the movie "An Education" (2009)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1174732
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_51`

### movie_510: The Nines
{: #movie_510 }
- **Network:** `movie_510`: undirected, valued; 23 nodes, 53 edges.
- **Description:** Interactions of characters in the movie "The Nines" (2007)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0810988
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_510`

### movie_511: Ninja Assassin
{: #movie_511 }
- **Network:** `movie_511`: undirected, valued; 23 nodes, 38 edges.
- **Description:** Interactions of characters in the movie "Ninja Assassin" (2009)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1186367
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_511`

### movie_512: Ninotchka
{: #movie_512 }
- **Network:** `movie_512`: undirected, valued; 34 nodes, 115 edges.
- **Description:** Interactions of characters in the movie "Ninotchka" (1939)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0031725
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_512`

### movie_513: Notting Hill
{: #movie_513 }
- **Network:** `movie_513`: undirected, valued; 34 nodes, 103 edges.
- **Description:** Interactions of characters in the movie "Notting Hill" (1999)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0125439
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_513`

### movie_514: Nurse Betty
{: #movie_514 }
- **Network:** `movie_514`: undirected, valued; 52 nodes, 173 edges.
- **Description:** Interactions of characters in the movie "Nurse Betty" (2000)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0171580
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_514`

### movie_515: O Brother, Where Art Thou?
{: #movie_515 }
- **Network:** `movie_515`: undirected, valued; 44 nodes, 170 edges.
- **Description:** Interactions of characters in the movie "O Brother, Where Art Thou?" (2000)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0190590
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_515`

### movie_516: Observe and Report
{: #movie_516 }
- **Network:** `movie_516`: undirected, valued; 31 nodes, 70 edges.
- **Description:** Interactions of characters in the movie "Observe and Report" (2009)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1197628
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_516`

### movie_517: Wicker Park
{: #movie_517 }
- **Network:** `movie_517`: undirected, valued; 27 nodes, 99 edges.
- **Description:** Interactions of characters in the movie "Wicker Park" (2004)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0324554
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_517`

### movie_518: Ocean's Eleven
{: #movie_518 }
- **Network:** `movie_518`: undirected, valued; 50 nodes, 145 edges.
- **Description:** Interactions of characters in the movie "Ocean's Eleven" (2001)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0240772
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_518`

### movie_519: Ocean's Twelve
{: #movie_519 }
- **Network:** `movie_519`: undirected, valued; 42 nodes, 147 edges.
- **Description:** Interactions of characters in the movie "Ocean's Twelve" (2004)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0349903
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_519`

### movie_52: Analyze That
{: #movie_52 }
- **Network:** `movie_52`: undirected, valued; 47 nodes, 130 edges.
- **Description:** Interactions of characters in the movie "Analyze That" (2002)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0289848
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_52`

### movie_520: One Flew Over the Cuckoo's Nest
{: #movie_520 }
- **Network:** `movie_520`: undirected, valued; 32 nodes, 178 edges.
- **Description:** Interactions of characters in the movie "One Flew Over the Cuckoo's Nest" (1975)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0073486
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_520`

### movie_521: Ordinary People
{: #movie_521 }
- **Network:** `movie_521`: undirected, valued; 43 nodes, 121 edges.
- **Description:** Interactions of characters in the movie "Ordinary People" (1980)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0081283
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_521`

### movie_522: Orphan
{: #movie_522 }
- **Network:** `movie_522`: undirected, valued; 48 nodes, 199 edges.
- **Description:** Interactions of characters in the movie "Orphan" (2009)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1148204
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_522`

### movie_523: The Other Boleyn Girl
{: #movie_523 }
- **Network:** `movie_523`: undirected, valued; 35 nodes, 109 edges.
- **Description:** Interactions of characters in the movie "The Other Boleyn Girl" (2008)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0467200
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_523`

### movie_524: Out of Sight
{: #movie_524 }
- **Network:** `movie_524`: undirected, valued; 37 nodes, 135 edges.
- **Description:** Interactions of characters in the movie "Out of Sight" (1998)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0120780
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_524`

### movie_525: The Pacifier
{: #movie_525 }
- **Network:** `movie_525`: undirected, valued; 46 nodes, 191 edges.
- **Description:** Interactions of characters in the movie "The Pacifier" (2005)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0395699
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_525`

### movie_526: Panic Room
{: #movie_526 }
- **Network:** `movie_526`: undirected, valued; 11 nodes, 25 edges.
- **Description:** Interactions of characters in the movie "Panic Room" (2002)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0258000
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_526`

### movie_527: The Patriot
{: #movie_527 }
- **Network:** `movie_527`: undirected, valued; 51 nodes, 182 edges.
- **Description:** Interactions of characters in the movie "The Patriot" (2000)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0187393
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_527`

### movie_528: Pearl Harbor
{: #movie_528 }
- **Network:** `movie_528`: undirected, valued; 54 nodes, 113 edges.
- **Description:** Interactions of characters in the movie "Pearl Harbor" (2001)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0213149
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_528`

### movie_529: Peeping Tom
{: #movie_529 }
- **Network:** `movie_529`: undirected, valued; 33 nodes, 111 edges.
- **Description:** Interactions of characters in the movie "Peeping Tom" (1960)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0054167
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_529`

### movie_53: Analyze This
{: #movie_53 }
- **Network:** `movie_53`: undirected, valued; 39 nodes, 130 edges.
- **Description:** Interactions of characters in the movie "Analyze This" (1999)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0122933
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_53`

### movie_530: A Perfect World
{: #movie_530 }
- **Network:** `movie_530`: undirected, valued; 52 nodes, 140 edges.
- **Description:** Interactions of characters in the movie "A Perfect World" (1993)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0107808
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_530`

### movie_531: Pet Sematary
{: #movie_531 }
- **Network:** `movie_531`: undirected, valued; 20 nodes, 43 edges.
- **Description:** Interactions of characters in the movie "Pet Sematary" (1989)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0098084
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_531`

### movie_532: Pet Sematary II
{: #movie_532 }
- **Network:** `movie_532`: undirected, valued; 31 nodes, 79 edges.
- **Description:** Interactions of characters in the movie "Pet Sematary II" (1992)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0105128
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_532`

### movie_533: Petulia
{: #movie_533 }
- **Network:** `movie_533`: undirected, valued; 42 nodes, 137 edges.
- **Description:** Interactions of characters in the movie "Petulia" (1968)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0063426
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_533`

### movie_534: Philadelphia
{: #movie_534 }
- **Network:** `movie_534`: undirected, valued; 65 nodes, 258 edges.
- **Description:** Interactions of characters in the movie "Philadelphia" (1993)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0107818
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_534`

### movie_535: Phone Booth
{: #movie_535 }
- **Network:** `movie_535`: undirected, valued; 17 nodes, 40 edges.
- **Description:** Interactions of characters in the movie "Phone Booth" (2002)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0183649
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_535`

### movie_536: Pi
{: #movie_536 }
- **Network:** `movie_536`: undirected, valued; 15 nodes, 26 edges.
- **Description:** Interactions of characters in the movie "Pi" (1998)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0138704
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_536`

### movie_537: The Pianist
{: #movie_537 }
- **Network:** `movie_537`: undirected, valued; 39 nodes, 103 edges.
- **Description:** Interactions of characters in the movie "The Pianist" (2002)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0253474
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_537`

### movie_538: The Piano
{: #movie_538 }
- **Network:** `movie_538`: undirected, valued; 25 nodes, 73 edges.
- **Description:** Interactions of characters in the movie "The Piano" (1993)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0107822
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_538`

### movie_539: Pineapple Express
{: #movie_539 }
- **Network:** `movie_539`: undirected, valued; 31 nodes, 78 edges.
- **Description:** Interactions of characters in the movie "Pineapple Express" (2008)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0910936
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_539`

### movie_54: Anastasia
{: #movie_54 }
- **Network:** `movie_54`: undirected, valued; 31 nodes, 98 edges.
- **Description:** Interactions of characters in the movie "Anastasia" (1997)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0118617
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_54`

### movie_540: Pirates of the Caribbean: The Curse of the Black Pearl
{: #movie_540 }
- **Network:** `movie_540`: undirected, valued; 27 nodes, 93 edges.
- **Description:** Interactions of characters in the movie "Pirates of the Caribbean: The Curse of the Black Pearl" (2003)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0325980
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_540`

### movie_541: Pitch Black
{: #movie_541 }
- **Network:** `movie_541`: undirected, valued; 12 nodes, 42 edges.
- **Description:** Interactions of characters in the movie "Pitch Black" (2000)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0134847
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_541`

### movie_542: Planet of the Apes
{: #movie_542 }
- **Network:** `movie_542`: undirected, valued; 19 nodes, 56 edges.
- **Description:** Interactions of characters in the movie "Planet of the Apes" (1968)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0063442
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_542`

### movie_543: Platinum Blonde
{: #movie_543 }
- **Network:** `movie_543`: undirected, valued; 30 nodes, 99 edges.
- **Description:** Interactions of characters in the movie "Platinum Blonde" (1931)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0022268
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_543`

### movie_544: Platoon
{: #movie_544 }
- **Network:** `movie_544`: undirected, valued; 39 nodes, 197 edges.
- **Description:** Interactions of characters in the movie "Platoon" (1986)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0091763
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_544`

### movie_545: Pleasantville
{: #movie_545 }
- **Network:** `movie_545`: undirected, valued; 45 nodes, 167 edges.
- **Description:** Interactions of characters in the movie "Pleasantville" (1998)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0120789
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_545`

### movie_546: Point Break
{: #movie_546 }
- **Network:** `movie_546`: undirected, valued; 31 nodes, 79 edges.
- **Description:** Interactions of characters in the movie "Point Break" (1991)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0102685
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_546`

### movie_547: Il Postino: The Postman
{: #movie_547 }
- **Network:** `movie_547`: undirected, valued; 49 nodes, 195 edges.
- **Description:** Interactions of characters in the movie "Il Postino: The Postman" (1994)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0110877
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_547`

### movie_548: The Power of One
{: #movie_548 }
- **Network:** `movie_548`: undirected, valued; 43 nodes, 114 edges.
- **Description:** Interactions of characters in the movie "The Power of One" (1992)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0105159
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_548`

### movie_549: Precious
{: #movie_549 }
- **Network:** `movie_549`: undirected, valued; 35 nodes, 93 edges.
- **Description:** Interactions of characters in the movie "Precious" (2009)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0929632
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_549`

### movie_55: Angel Eyes
{: #movie_55 }
- **Network:** `movie_55`: undirected, valued; 33 nodes, 85 edges.
- **Description:** Interactions of characters in the movie "Angel Eyes" (2001)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0225071
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_55`

### movie_550: Predator
{: #movie_550 }
- **Network:** `movie_550`: undirected, valued; 13 nodes, 29 edges.
- **Description:** Interactions of characters in the movie "Predator" (1987)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0093773
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_550`

### movie_551: Pretty Woman
{: #movie_551 }
- **Network:** `movie_551`: undirected, valued; 36 nodes, 69 edges.
- **Description:** Interactions of characters in the movie "Pretty Woman" (1990)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0100405
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_551`

### movie_552: The Princess Bride
{: #movie_552 }
- **Network:** `movie_552`: undirected, valued; 21 nodes, 64 edges.
- **Description:** Interactions of characters in the movie "The Princess Bride" (1987)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0093779
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_552`

### movie_553: The Private Life of Sherlock Holmes
{: #movie_553 }
- **Network:** `movie_553`: undirected, valued; 22 nodes, 62 edges.
- **Description:** Interactions of characters in the movie "The Private Life of Sherlock Holmes" (1970)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0066249
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_553`

### movie_554: The Jack Benny Program
{: #movie_554 }
- **Network:** `movie_554`: undirected, valued; 61 nodes, 239 edges.
- **Description:** Interactions of characters in the movie "The Jack Benny Program" (1950)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0042116
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_554`

### movie_555: The Prophecy
{: #movie_555 }
- **Network:** `movie_555`: undirected, valued; 50 nodes, 178 edges.
- **Description:** Interactions of characters in the movie "The Prophecy" (1995)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0114194
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_555`

### movie_556: The Proposal
{: #movie_556 }
- **Network:** `movie_556`: undirected, valued; 31 nodes, 90 edges.
- **Description:** Interactions of characters in the movie "The Proposal" (2009)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1041829
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_556`

### movie_557: Psycho
{: #movie_557 }
- **Network:** `movie_557`: undirected, valued; 21 nodes, 49 edges.
- **Description:** Interactions of characters in the movie "Psycho" (1960)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0054215
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_557`

### movie_558: Public Enemies
{: #movie_558 }
- **Network:** `movie_558`: undirected, valued; 99 nodes, 317 edges.
- **Description:** Interactions of characters in the movie "Public Enemies" (2009)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1152836
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_558`

### movie_559: Pulp Fiction
{: #movie_559 }
- **Network:** `movie_559`: undirected, valued; 38 nodes, 102 edges.
- **Description:** Interactions of characters in the movie "Pulp Fiction" (1994)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0110912
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_559`

### movie_56: Angels & Demons
{: #movie_56 }
- **Network:** `movie_56`: undirected, valued; 25 nodes, 55 edges.
- **Description:** Interactions of characters in the movie "Angels & Demons" (2009)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0808151
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_56`

### movie_560: Punch-Drunk Love
{: #movie_560 }
- **Network:** `movie_560`: undirected, valued; 34 nodes, 92 edges.
- **Description:** Interactions of characters in the movie "Punch-Drunk Love" (2002)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0272338
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_560`

### movie_561: Purple Rain
{: #movie_561 }
- **Network:** `movie_561`: undirected, valued; 30 nodes, 89 edges.
- **Description:** Interactions of characters in the movie "Purple Rain" (1984)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0087957
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_561`

### movie_562: Queen of the Damned
{: #movie_562 }
- **Network:** `movie_562`: undirected, valued; 38 nodes, 98 edges.
- **Description:** Interactions of characters in the movie "Queen of the Damned" (2002)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0238546
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_562`

### movie_563: The Queen
{: #movie_563 }
- **Network:** `movie_563`: undirected, valued; 39 nodes, 123 edges.
- **Description:** Interactions of characters in the movie "The Queen" (2006)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0436697
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_563`

### movie_564: Rachel Getting Married
{: #movie_564 }
- **Network:** `movie_564`: undirected, valued; 21 nodes, 65 edges.
- **Description:** Interactions of characters in the movie "Rachel Getting Married" (2008)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1084950
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_564`

### movie_565: Raging Bull
{: #movie_565 }
- **Network:** `movie_565`: undirected, valued; 35 nodes, 89 edges.
- **Description:** Interactions of characters in the movie "Raging Bull" (1980)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0081398
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_565`

### movie_566: Raising Arizona
{: #movie_566 }
- **Network:** `movie_566`: undirected, valued; 29 nodes, 59 edges.
- **Description:** Interactions of characters in the movie "Raising Arizona" (1987)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0093822
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_566`

### movie_567: Rambling Rose
{: #movie_567 }
- **Network:** `movie_567`: undirected, valued; 19 nodes, 43 edges.
- **Description:** Interactions of characters in the movie "Rambling Rose" (1991)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0102753
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_567`

### movie_568: Rambo: First Blood Part II
{: #movie_568 }
- **Network:** `movie_568`: undirected, valued; 23 nodes, 55 edges.
- **Description:** Interactions of characters in the movie "Rambo: First Blood Part II" (1985)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0089880
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_568`

### movie_569: The Reader
{: #movie_569 }
- **Network:** `movie_569`: undirected, valued; 29 nodes, 55 edges.
- **Description:** Interactions of characters in the movie "The Reader" (2008)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0976051
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_569`

### movie_57: Annie Hall
{: #movie_57 }
- **Network:** `movie_57`: undirected, valued; 52 nodes, 183 edges.
- **Description:** Interactions of characters in the movie "Annie Hall" (1977)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0075686
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_57`

### movie_570: Real Genius
{: #movie_570 }
- **Network:** `movie_570`: undirected, valued; 55 nodes, 223 edges.
- **Description:** Interactions of characters in the movie "Real Genius" (1985)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0089886
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_570`

### movie_571: Rear Window
{: #movie_571 }
- **Network:** `movie_571`: undirected, valued; 12 nodes, 17 edges.
- **Description:** Interactions of characters in the movie "Rear Window" (1954)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0047396
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_571`

### movie_572: Red Planet
{: #movie_572 }
- **Network:** `movie_572`: undirected, valued; 22 nodes, 65 edges.
- **Description:** Interactions of characters in the movie "Red Planet" (2000)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0199753
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_572`

### movie_573: The Relic
{: #movie_573 }
- **Network:** `movie_573`: undirected, valued; 34 nodes, 97 edges.
- **Description:** Interactions of characters in the movie "The Relic" (1997)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0120004
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_573`

### movie_574: Remember Me
{: #movie_574 }
- **Network:** `movie_574`: undirected, valued; 27 nodes, 81 edges.
- **Description:** Interactions of characters in the movie "Remember Me" (2010)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1403981
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_574`

### movie_575: The Replacements
{: #movie_575 }
- **Network:** `movie_575`: undirected, valued; 53 nodes, 233 edges.
- **Description:** Interactions of characters in the movie "The Replacements" (2000)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0191397
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_575`

### movie_576: Reservoir Dogs
{: #movie_576 }
- **Network:** `movie_576`: undirected, valued; 21 nodes, 82 edges.
- **Description:** Interactions of characters in the movie "Reservoir Dogs" (1992)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0105236
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_576`

### movie_577: Resident Evil
{: #movie_577 }
- **Network:** `movie_577`: undirected, valued; 22 nodes, 81 edges.
- **Description:** Interactions of characters in the movie "Resident Evil" (2002)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0120804
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_577`

### movie_578: Revolutionary Road
{: #movie_578 }
- **Network:** `movie_578`: undirected, valued; 18 nodes, 34 edges.
- **Description:** Interactions of characters in the movie "Revolutionary Road" (2008)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0959337
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_578`

### movie_579: Ring
{: #movie_579 }
- **Network:** `movie_579`: undirected, valued; 29 nodes, 69 edges.
- **Description:** Interactions of characters in the movie "Ring" (1998)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0178868
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_579`

### movie_58: The Anniversary Party
{: #movie_58 }
- **Network:** `movie_58`: undirected, valued; 28 nodes, 188 edges.
- **Description:** Interactions of characters in the movie "The Anniversary Party" (2001)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0254099
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_58`

### movie_580: RKO 281
{: #movie_580 }
- **Network:** `movie_580`: undirected, valued; 41 nodes, 126 edges.
- **Description:** Interactions of characters in the movie "RKO 281" (1999)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0120801
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_580`

### movie_581: The Road
{: #movie_581 }
- **Network:** `movie_581`: undirected, valued; 13 nodes, 23 edges.
- **Description:** Interactions of characters in the movie "The Road" (2009)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0898367
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_581`

### movie_582: Robin Hood: Prince of Thieves
{: #movie_582 }
- **Network:** `movie_582`: undirected, valued; 39 nodes, 174 edges.
- **Description:** Interactions of characters in the movie "Robin Hood: Prince of Thieves" (1991)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0102798
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_582`

### movie_583: The Rock
{: #movie_583 }
- **Network:** `movie_583`: undirected, valued; 36 nodes, 90 edges.
- **Description:** Interactions of characters in the movie "The Rock" (1996)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0117500
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_583`

### movie_584: RocknRolla
{: #movie_584 }
- **Network:** `movie_584`: undirected, valued; 40 nodes, 144 edges.
- **Description:** Interactions of characters in the movie "RocknRolla" (2008)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1032755
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_584`

### movie_585: Rocky
{: #movie_585 }
- **Network:** `movie_585`: undirected, valued; 46 nodes, 170 edges.
- **Description:** Interactions of characters in the movie "Rocky" (1976)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0075148
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_585`

### movie_586: The Rocky Horror Picture Show
{: #movie_586 }
- **Network:** `movie_586`: undirected, valued; 20 nodes, 63 edges.
- **Description:** Interactions of characters in the movie "The Rocky Horror Picture Show" (1975)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0073629
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_586`

### movie_587: Romeo Juliet
{: #movie_587 }
- **Network:** `movie_587`: undirected, valued; 41 nodes, 120 edges.
- **Description:** Interactions of characters in the movie "Romeo Juliet" (1996)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0117509
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_587`

### movie_588: Ronin
{: #movie_588 }
- **Network:** `movie_588`: undirected, valued; 18 nodes, 48 edges.
- **Description:** Interactions of characters in the movie "Ronin" (1998)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0122690
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_588`

### movie_589: Gunsmoke
{: #movie_589 }
- **Network:** `movie_589`: undirected, valued; 25 nodes, 133 edges.
- **Description:** Interactions of characters in the movie "Gunsmoke" (1953)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0045847
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_589`

### movie_59: Antitrust
{: #movie_59 }
- **Network:** `movie_59`: undirected, valued; 43 nodes, 113 edges.
- **Description:** Interactions of characters in the movie "Antitrust" (2001)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0218817
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_59`

### movie_590: The Ruins
{: #movie_590 }
- **Network:** `movie_590`: undirected, valued; 19 nodes, 73 edges.
- **Description:** Interactions of characters in the movie "The Ruins" (2008)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0963794
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_590`

### movie_591: Runaway Bride
{: #movie_591 }
- **Network:** `movie_591`: undirected, valued; 31 nodes, 98 edges.
- **Description:** Interactions of characters in the movie "Runaway Bride" (1999)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0163187
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_591`

### movie_592: Rush Hour
{: #movie_592 }
- **Network:** `movie_592`: undirected, valued; 39 nodes, 108 edges.
- **Description:** Interactions of characters in the movie "Rush Hour" (1998)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0120812
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_592`

### movie_593: Rush Hour 2
{: #movie_593 }
- **Network:** `movie_593`: undirected, valued; 24 nodes, 51 edges.
- **Description:** Interactions of characters in the movie "Rush Hour 2" (2001)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0266915
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_593`

### movie_594: Donnie Darko
{: #movie_594 }
- **Network:** `movie_594`: undirected, valued; 28 nodes, 80 edges.
- **Description:** Interactions of characters in the movie "Donnie Darko" (2001)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0246578
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_594`

### movie_595: The Saint
{: #movie_595 }
- **Network:** `movie_595`: undirected, valued; 53 nodes, 115 edges.
- **Description:** Interactions of characters in the movie "The Saint" (1997)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0120053
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_595`

### movie_596: The Salton Sea
{: #movie_596 }
- **Network:** `movie_596`: undirected, valued; 28 nodes, 55 edges.
- **Description:** Interactions of characters in the movie "The Salton Sea" (2002)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0235737
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_596`

### movie_597: The Sandlot
{: #movie_597 }
- **Network:** `movie_597`: undirected, valued; 39 nodes, 230 edges.
- **Description:** Interactions of characters in the movie "The Sandlot" (1993)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0108037
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_597`

### movie_598: Save the Last Dance
{: #movie_598 }
- **Network:** `movie_598`: undirected, valued; 33 nodes, 93 edges.
- **Description:** Interactions of characters in the movie "Save the Last Dance" (2001)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0206275
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_598`

### movie_599: Saving Private Ryan
{: #movie_599 }
- **Network:** `movie_599`: undirected, valued; 34 nodes, 227 edges.
- **Description:** Interactions of characters in the movie "Saving Private Ryan" (1998)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0120815
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_599`

### movie_6: 15 Minutes
{: #movie_6 }
- **Network:** `movie_6`: undirected, valued; 45 nodes, 141 edges.
- **Description:** Interactions of characters in the movie "15 Minutes" (2001)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0179626
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_6`

### movie_60: Antz
{: #movie_60 }
- **Network:** `movie_60`: undirected, valued; 37 nodes, 140 edges.
- **Description:** Interactions of characters in the movie "Antz" (1998)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0120587
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_60`

### movie_600: Scarface
{: #movie_600 }
- **Network:** `movie_600`: undirected, valued; 49 nodes, 157 edges.
- **Description:** Interactions of characters in the movie "Scarface" (1983)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0086250
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_600`

### movie_601: Schindler's List
{: #movie_601 }
- **Network:** `movie_601`: undirected, valued; 45 nodes, 76 edges.
- **Description:** Interactions of characters in the movie "Schindler's List" (1993)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0108052
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_601`

### movie_602: Scream
{: #movie_602 }
- **Network:** `movie_602`: undirected, valued; 26 nodes, 69 edges.
- **Description:** Interactions of characters in the movie "Scream" (1996)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0117571
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_602`

### movie_603: Scream 2
{: #movie_603 }
- **Network:** `movie_603`: undirected, valued; 43 nodes, 186 edges.
- **Description:** Interactions of characters in the movie "Scream 2" (1997)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0120082
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_603`

### movie_604: Scream 3
{: #movie_604 }
- **Network:** `movie_604`: undirected, valued; 30 nodes, 124 edges.
- **Description:** Interactions of characters in the movie "Scream 3" (2000)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0134084
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_604`

### movie_605: Se7en
{: #movie_605 }
- **Network:** `movie_605`: undirected, valued; 49 nodes, 100 edges.
- **Description:** Interactions of characters in the movie "Se7en" (1995)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0114369
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_605`

### movie_606: The Searchers
{: #movie_606 }
- **Network:** `movie_606`: undirected, valued; 40 nodes, 152 edges.
- **Description:** Interactions of characters in the movie "The Searchers" (1956)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0049730
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_606`

### movie_607: Semi-Pro
{: #movie_607 }
- **Network:** `movie_607`: undirected, valued; 56 nodes, 275 edges.
- **Description:** Interactions of characters in the movie "Semi-Pro" (2008)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0839980
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_607`

### movie_608: Sense and Sensibility
{: #movie_608 }
- **Network:** `movie_608`: undirected, valued; 25 nodes, 128 edges.
- **Description:** Interactions of characters in the movie "Sense and Sensibility" (1995)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0114388
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_608`

### movie_609: Serenity
{: #movie_609 }
- **Network:** `movie_609`: undirected, valued; 39 nodes, 158 edges.
- **Description:** Interactions of characters in the movie "Serenity" (2005)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0379786
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_609`

### movie_61: The Apartment
{: #movie_61 }
- **Network:** `movie_61`: undirected, valued; 33 nodes, 76 edges.
- **Description:** Interactions of characters in the movie "The Apartment" (1960)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0053604
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_61`

### movie_610: Serial Mom
{: #movie_610 }
- **Network:** `movie_610`: undirected, valued; 48 nodes, 167 edges.
- **Description:** Interactions of characters in the movie "Serial Mom" (1994)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0111127
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_610`

### movie_611: Sex and the City
{: #movie_611 }
- **Network:** `movie_611`: undirected, valued; 46 nodes, 117 edges.
- **Description:** Interactions of characters in the movie "Sex and the City" (1998)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0159206
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_611`

### movie_612: Sex, Lies, and Videotape
{: #movie_612 }
- **Network:** `movie_612`: undirected, valued; 10 nodes, 25 edges.
- **Description:** Interactions of characters in the movie "Sex, Lies, and Videotape" (1989)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0098724
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_612`

### movie_613: Sexual Life
{: #movie_613 }
- **Network:** `movie_613`: undirected, valued; 28 nodes, 56 edges.
- **Description:** Interactions of characters in the movie "Sexual Life" (2005)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0376874
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_613`

### movie_614: Shakespeare in Love
{: #movie_614 }
- **Network:** `movie_614`: undirected, valued; 47 nodes, 219 edges.
- **Description:** Interactions of characters in the movie "Shakespeare in Love" (1998)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0138097
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_614`

### movie_615: Shallow Grave
{: #movie_615 }
- **Network:** `movie_615`: undirected, valued; 16 nodes, 27 edges.
- **Description:** Interactions of characters in the movie "Shallow Grave" (1994)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0111149
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_615`

### movie_616: Shampoo
{: #movie_616 }
- **Network:** `movie_616`: undirected, valued; 44 nodes, 209 edges.
- **Description:** Interactions of characters in the movie "Shampoo" (1975)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0073692
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_616`

### movie_617: The Shawshank Redemption
{: #movie_617 }
- **Network:** `movie_617`: undirected, valued; 35 nodes, 136 edges.
- **Description:** Interactions of characters in the movie "The Shawshank Redemption" (1994)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0111161
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_617`

### movie_618: She's Out of My League
{: #movie_618 }
- **Network:** `movie_618`: undirected, valued; 56 nodes, 192 edges.
- **Description:** Interactions of characters in the movie "She's Out of My League" (2010)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0815236
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_618`

### movie_619: Sherlock Holmes
{: #movie_619 }
- **Network:** `movie_619`: undirected, valued; 33 nodes, 69 edges.
- **Description:** Interactions of characters in the movie "Sherlock Holmes" (2009)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0988045
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_619`

### movie_62: Apocalypse Now
{: #movie_62 }
- **Network:** `movie_62`: undirected, valued; 40 nodes, 211 edges.
- **Description:** Interactions of characters in the movie "Apocalypse Now" (1979)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0078788
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_62`

### movie_620: The Shining
{: #movie_620 }
- **Network:** `movie_620`: undirected, valued; 21 nodes, 48 edges.
- **Description:** Interactions of characters in the movie "The Shining" (1980)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0081505
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_620`

### movie_621: The Shipping News
{: #movie_621 }
- **Network:** `movie_621`: undirected, valued; 29 nodes, 63 edges.
- **Description:** Interactions of characters in the movie "The Shipping News" (2001)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0120824
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_621`

### movie_622: They Came from Within
{: #movie_622 }
- **Network:** `movie_622`: undirected, valued; 16 nodes, 30 edges.
- **Description:** Interactions of characters in the movie "They Came from Within" (1975)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0073705
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_622`

### movie_623: Sideways
{: #movie_623 }
- **Network:** `movie_623`: undirected, valued; 41 nodes, 119 edges.
- **Description:** Interactions of characters in the movie "Sideways" (2004)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0375063
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_623`

### movie_624: The Siege
{: #movie_624 }
- **Network:** `movie_624`: undirected, valued; 45 nodes, 132 edges.
- **Description:** Interactions of characters in the movie "The Siege" (1998)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0133952
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_624`

### movie_625: Signs
{: #movie_625 }
- **Network:** `movie_625`: undirected, valued; 21 nodes, 51 edges.
- **Description:** Interactions of characters in the movie "Signs" (2002)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0286106
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_625`

### movie_626: The Silence of the Lambs
{: #movie_626 }
- **Network:** `movie_626`: undirected, valued; 35 nodes, 78 edges.
- **Description:** Interactions of characters in the movie "The Silence of the Lambs" (1991)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0102926
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_626`

### movie_627: Silver Bullet
{: #movie_627 }
- **Network:** `movie_627`: undirected, valued; 29 nodes, 54 edges.
- **Description:** Interactions of characters in the movie "Silver Bullet" (1985)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0090021
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_627`

### movie_628: S1m0ne
{: #movie_628 }
- **Network:** `movie_628`: undirected, valued; 48 nodes, 116 edges.
- **Description:** Interactions of characters in the movie "S1m0ne" (2002)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0258153
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_628`

### movie_629: Sister Act
{: #movie_629 }
- **Network:** `movie_629`: undirected, valued; 51 nodes, 217 edges.
- **Description:** Interactions of characters in the movie "Sister Act" (1992)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0105417
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_629`

### movie_63: Apt Pupil
{: #movie_63 }
- **Network:** `movie_63`: undirected, valued; 21 nodes, 56 edges.
- **Description:** Interactions of characters in the movie "Apt Pupil" (1998)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0118636
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_63`

### movie_630: The Sixth Sense
{: #movie_630 }
- **Network:** `movie_630`: undirected, valued; 24 nodes, 41 edges.
- **Description:** Interactions of characters in the movie "The Sixth Sense" (1999)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0167404
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_630`

### movie_631: Sleepless in Seattle
{: #movie_631 }
- **Network:** `movie_631`: undirected, valued; 53 nodes, 154 edges.
- **Description:** Interactions of characters in the movie "Sleepless in Seattle" (1993)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0108160
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_631`

### movie_632: Sleepy Hollow
{: #movie_632 }
- **Network:** `movie_632`: undirected, valued; 30 nodes, 84 edges.
- **Description:** Interactions of characters in the movie "Sleepy Hollow" (1999)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0162661
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_632`

### movie_633: Sling Blade
{: #movie_633 }
- **Network:** `movie_633`: undirected, valued; 31 nodes, 83 edges.
- **Description:** Interactions of characters in the movie "Sling Blade" (1996)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0117666
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_633`

### movie_634: Slither
{: #movie_634 }
- **Network:** `movie_634`: undirected, valued; 31 nodes, 88 edges.
- **Description:** Interactions of characters in the movie "Slither" (2006)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0439815
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_634`

### movie_635: Slumdog Millionaire
{: #movie_635 }
- **Network:** `movie_635`: undirected, valued; 39 nodes, 95 edges.
- **Description:** Interactions of characters in the movie "Slumdog Millionaire" (2008)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1010048
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_635`

### movie_636: Smokin' Aces
{: #movie_636 }
- **Network:** `movie_636`: undirected, valued; 49 nodes, 180 edges.
- **Description:** Interactions of characters in the movie "Smokin' Aces" (2006)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0475394
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_636`

### movie_637: Snatch
{: #movie_637 }
- **Network:** `movie_637`: undirected, valued; 35 nodes, 133 edges.
- **Description:** Interactions of characters in the movie "Snatch" (2000)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0208092
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_637`

### movie_638: Snow Falling on Cedars
{: #movie_638 }
- **Network:** `movie_638`: undirected, valued; 39 nodes, 87 edges.
- **Description:** Interactions of characters in the movie "Snow Falling on Cedars" (1999)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0120834
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_638`

### movie_639: So I Married an Axe Murderer
{: #movie_639 }
- **Network:** `movie_639`: undirected, valued; 53 nodes, 154 edges.
- **Description:** Interactions of characters in the movie "So I Married an Axe Murderer" (1993)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0108174
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_639`

### movie_64: Army of Darkness
{: #movie_64 }
- **Network:** `movie_64`: undirected, valued; 23 nodes, 68 edges.
- **Description:** Interactions of characters in the movie "Army of Darkness" (1992)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0106308
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_64`

### movie_640: Solaris
{: #movie_640 }
- **Network:** `movie_640`: undirected, valued; 5 nodes, 10 edges.
- **Description:** Interactions of characters in the movie "Solaris" (2002)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0307479
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_640`

### movie_641: Soldier
{: #movie_641 }
- **Network:** `movie_641`: undirected, valued; 26 nodes, 82 edges.
- **Description:** Interactions of characters in the movie "Soldier" (1998)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0120157
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_641`

### movie_642: Someone to Watch Over Me
{: #movie_642 }
- **Network:** `movie_642`: undirected, valued; 25 nodes, 60 edges.
- **Description:** Interactions of characters in the movie "Someone to Watch Over Me" (1987)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0094008
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_642`

### movie_643: Something's Gotta Give
{: #movie_643 }
- **Network:** `movie_643`: undirected, valued; 28 nodes, 128 edges.
- **Description:** Interactions of characters in the movie "Something's Gotta Give" (2003)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0337741
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_643`

### movie_644: Spanglish
{: #movie_644 }
- **Network:** `movie_644`: undirected, valued; 24 nodes, 71 edges.
- **Description:** Interactions of characters in the movie "Spanglish" (2004)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0371246
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_644`

### movie_645: Spare Me
{: #movie_645 }
- **Network:** `movie_645`: undirected, valued; 27 nodes, 94 edges.
- **Description:** Interactions of characters in the movie "Spare Me" (1994)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0108200
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_645`

### movie_646: Meet the Spartans
{: #movie_646 }
- **Network:** `movie_646`: undirected, valued; 54 nodes, 154 edges.
- **Description:** Interactions of characters in the movie "Meet the Spartans" (2008)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1073498
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_646`

### movie_647: Speed Racer
{: #movie_647 }
- **Network:** `movie_647`: undirected, valued; 76 nodes, 274 edges.
- **Description:** Interactions of characters in the movie "Speed Racer" (2008)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0811080
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_647`

### movie_648: Sphere
{: #movie_648 }
- **Network:** `movie_648`: undirected, valued; 15 nodes, 38 edges.
- **Description:** Interactions of characters in the movie "Sphere" (1998)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0120184
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_648`

### movie_649: Spider-Man
{: #movie_649 }
- **Network:** `movie_649`: undirected, valued; 37 nodes, 113 edges.
- **Description:** Interactions of characters in the movie "Spider-Man" (2002)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0145487
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_649`

### movie_65: As Good as It Gets
{: #movie_65 }
- **Network:** `movie_65`: undirected, valued; 35 nodes, 74 edges.
- **Description:** Interactions of characters in the movie "As Good as It Gets" (1997)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0119822
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_65`

### movie_650: Star Trek
{: #movie_650 }
- **Network:** `movie_650`: undirected, valued; 57 nodes, 177 edges.
- **Description:** Interactions of characters in the movie "Star Trek" (1966)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0060028
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_650`

### movie_651: Star Trek II: The Wrath of Khan
{: #movie_651 }
- **Network:** `movie_651`: undirected, valued; 25 nodes, 107 edges.
- **Description:** Interactions of characters in the movie "Star Trek II: The Wrath of Khan" (1982)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0084726
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_651`

### movie_652: Star Trek: First Contact
{: #movie_652 }
- **Network:** `movie_652`: undirected, valued; 30 nodes, 79 edges.
- **Description:** Interactions of characters in the movie "Star Trek: First Contact" (1996)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0117731
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_652`

### movie_653: Star Trek: Generations
{: #movie_653 }
- **Network:** `movie_653`: undirected, valued; 41 nodes, 162 edges.
- **Description:** Interactions of characters in the movie "Star Trek: Generations" (1994)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0111280
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_653`

### movie_654: Star Trek: Insurrection
{: #movie_654 }
- **Network:** `movie_654`: undirected, valued; 21 nodes, 75 edges.
- **Description:** Interactions of characters in the movie "Star Trek: Insurrection" (1998)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0120844
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_654`

### movie_655: Star Trek: The Motion Picture
{: #movie_655 }
- **Network:** `movie_655`: undirected, valued; 28 nodes, 104 edges.
- **Description:** Interactions of characters in the movie "Star Trek: The Motion Picture" (1979)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0079945
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_655`

### movie_656: Star Wars: Episode IV - A New Hope
{: #movie_656 }
- **Network:** `movie_656`: undirected, valued; 42 nodes, 124 edges.
- **Description:** Interactions of characters in the movie "Star Wars: Episode IV - A New Hope" (1977)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0076759
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_656`

### movie_657: Star Wars: Episode II - Attack of the Clones
{: #movie_657 }
- **Network:** `movie_657`: undirected, valued; 47 nodes, 148 edges.
- **Description:** Interactions of characters in the movie "Star Wars: Episode II - Attack of the Clones" (2002)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0121765
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_657`

### movie_658: Star Wars: Episode VI - Return of the Jedi
{: #movie_658 }
- **Network:** `movie_658`: undirected, valued; 32 nodes, 84 edges.
- **Description:** Interactions of characters in the movie "Star Wars: Episode VI - Return of the Jedi" (1983)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0086190
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_658`

### movie_659: Star Wars: Episode V - The Empire Strikes Back
{: #movie_659 }
- **Network:** `movie_659`: undirected, valued; 37 nodes, 82 edges.
- **Description:** Interactions of characters in the movie "Star Wars: Episode V - The Empire Strikes Back" (1980)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0080684
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_659`

### movie_66: Assassins
{: #movie_66 }
- **Network:** `movie_66`: undirected, valued; 16 nodes, 23 edges.
- **Description:** Interactions of characters in the movie "Assassins" (1995)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0112401
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_66`

### movie_660: Starman
{: #movie_660 }
- **Network:** `movie_660`: undirected, valued; 38 nodes, 96 edges.
- **Description:** Interactions of characters in the movie "Starman" (1984)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0088172
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_660`

### movie_661: Starship Troopers
{: #movie_661 }
- **Network:** `movie_661`: undirected, valued; 49 nodes, 187 edges.
- **Description:** Interactions of characters in the movie "Starship Troopers" (1997)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0120201
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_661`

### movie_662: State and Main
{: #movie_662 }
- **Network:** `movie_662`: undirected, valued; 42 nodes, 208 edges.
- **Description:** Interactions of characters in the movie "State and Main" (2000)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0120202
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_662`

### movie_663: Station West
{: #movie_663 }
- **Network:** `movie_663`: undirected, valued; 30 nodes, 101 edges.
- **Description:** Interactions of characters in the movie "Station West" (1948)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0040835
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_663`

### movie_664: Stepmom
{: #movie_664 }
- **Network:** `movie_664`: undirected, valued; 21 nodes, 40 edges.
- **Description:** Interactions of characters in the movie "Stepmom" (1998)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0120686
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_664`

### movie_665: The Sting
{: #movie_665 }
- **Network:** `movie_665`: undirected, valued; 36 nodes, 113 edges.
- **Description:** Interactions of characters in the movie "The Sting" (1973)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0070735
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_665`

### movie_666: Stir of Echoes
{: #movie_666 }
- **Network:** `movie_666`: undirected, valued; 32 nodes, 116 edges.
- **Description:** Interactions of characters in the movie "Stir of Echoes" (1999)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0164181
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_666`

### movie_667: Storytelling
{: #movie_667 }
- **Network:** `movie_667`: undirected, valued; 21 nodes, 43 edges.
- **Description:** Interactions of characters in the movie "Storytelling" (2001)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0250081
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_667`

### movie_668: Strange Days
{: #movie_668 }
- **Network:** `movie_668`: undirected, valued; 38 nodes, 103 edges.
- **Description:** Interactions of characters in the movie "Strange Days" (1995)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0114558
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_668`

### movie_669: Strangers on a Train
{: #movie_669 }
- **Network:** `movie_669`: undirected, valued; 50 nodes, 197 edges.
- **Description:** Interactions of characters in the movie "Strangers on a Train" (1951)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0044079
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_669`

### movie_67: The Assignment
{: #movie_67 }
- **Network:** `movie_67`: undirected, valued; 51 nodes, 142 edges.
- **Description:** Interactions of characters in the movie "The Assignment" (1997)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0118647
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_67`

### movie_670: Sugar
{: #movie_670 }
- **Network:** `movie_670`: undirected, valued; 45 nodes, 129 edges.
- **Description:** Interactions of characters in the movie "Sugar" (2008)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0990413
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_670`

### movie_671: Sugar & Spice
{: #movie_671 }
- **Network:** `movie_671`: undirected, valued; 40 nodes, 124 edges.
- **Description:** Interactions of characters in the movie "Sugar & Spice" (2001)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0186589
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_671`

### movie_672: Sunset Blvd.
{: #movie_672 }
- **Network:** `movie_672`: undirected, valued; 35 nodes, 75 edges.
- **Description:** Interactions of characters in the movie "Sunset Blvd." (1950)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0043014
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_672`

### movie_673: Sunshine Cleaning
{: #movie_673 }
- **Network:** `movie_673`: undirected, valued; 30 nodes, 59 edges.
- **Description:** Interactions of characters in the movie "Sunshine Cleaning" (2008)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0862846
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_673`

### movie_674: Superbad
{: #movie_674 }
- **Network:** `movie_674`: undirected, valued; 35 nodes, 94 edges.
- **Description:** Interactions of characters in the movie "Superbad" (2007)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0829482
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_674`

### movie_675: The Surfer King
{: #movie_675 }
- **Network:** `movie_675`: undirected, valued; 30 nodes, 60 edges.
- **Description:** Interactions of characters in the movie "The Surfer King" (2006)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0418206
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_675`

### movie_676: Suspect Zero
{: #movie_676 }
- **Network:** `movie_676`: undirected, valued; 27 nodes, 50 edges.
- **Description:** Interactions of characters in the movie "Suspect Zero" (2004)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0324127
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_676`

### movie_677: The Sweet Hereafter
{: #movie_677 }
- **Network:** `movie_677`: undirected, valued; 18 nodes, 38 edges.
- **Description:** Interactions of characters in the movie "The Sweet Hereafter" (1997)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0120255
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_677`

### movie_678: Sweet Smell of Success
{: #movie_678 }
- **Network:** `movie_678`: undirected, valued; 37 nodes, 111 edges.
- **Description:** Interactions of characters in the movie "Sweet Smell of Success" (1957)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0051036
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_678`

### movie_679: Swingers
{: #movie_679 }
- **Network:** `movie_679`: undirected, valued; 22 nodes, 74 edges.
- **Description:** Interactions of characters in the movie "Swingers" (1996)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0117802
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_679`

### movie_68: At First Sight
{: #movie_68 }
- **Network:** `movie_68`: undirected, valued; 27 nodes, 73 edges.
- **Description:** Interactions of characters in the movie "At First Sight" (1999)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0132512
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_68`

### movie_680: Swordfish
{: #movie_680 }
- **Network:** `movie_680`: undirected, valued; 28 nodes, 51 edges.
- **Description:** Interactions of characters in the movie "Swordfish" (2001)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0244244
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_680`

### movie_681: Synecdoche, New York
{: #movie_681 }
- **Network:** `movie_681`: undirected, valued; 71 nodes, 264 edges.
- **Description:** Interactions of characters in the movie "Synecdoche, New York" (2008)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0383028
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_681`

### movie_682: Taking Lives
{: #movie_682 }
- **Network:** `movie_682`: undirected, valued; 29 nodes, 55 edges.
- **Description:** Interactions of characters in the movie "Taking Lives" (2004)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0364045
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_682`

### movie_683: Taking Sides
{: #movie_683 }
- **Network:** `movie_683`: undirected, valued; 19 nodes, 45 edges.
- **Description:** Interactions of characters in the movie "Taking Sides" (2001)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0260414
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_683`

### movie_684: The Talented Mr. Ripley
{: #movie_684 }
- **Network:** `movie_684`: undirected, valued; 22 nodes, 42 edges.
- **Description:** Interactions of characters in the movie "The Talented Mr. Ripley" (1999)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0134119
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_684`

### movie_685: Taxi Driver
{: #movie_685 }
- **Network:** `movie_685`: undirected, valued; 22 nodes, 57 edges.
- **Description:** Interactions of characters in the movie "Taxi Driver" (1976)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0075314
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_685`

### movie_686: The Terminator
{: #movie_686 }
- **Network:** `movie_686`: undirected, valued; 32 nodes, 52 edges.
- **Description:** Interactions of characters in the movie "The Terminator" (1984)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0088247
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_686`

### movie_687: Terminator 2: Judgment Day
{: #movie_687 }
- **Network:** `movie_687`: undirected, valued; 26 nodes, 57 edges.
- **Description:** Interactions of characters in the movie "Terminator 2: Judgment Day" (1991)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0103064
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_687`

### movie_688: Terminator Salvation
{: #movie_688 }
- **Network:** `movie_688`: undirected, valued; 31 nodes, 98 edges.
- **Description:** Interactions of characters in the movie "Terminator Salvation" (2009)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0438488
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_688`

### movie_689: Thelma & Louise
{: #movie_689 }
- **Network:** `movie_689`: undirected, valued; 20 nodes, 43 edges.
- **Description:** Interactions of characters in the movie "Thelma & Louise" (1991)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0103074
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_689`

### movie_69: Austin Powers: International Man of Mystery
{: #movie_69 }
- **Network:** `movie_69`: undirected, valued; 40 nodes, 103 edges.
- **Description:** Interactions of characters in the movie "Austin Powers: International Man of Mystery" (1997)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0118655
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_69`

### movie_690: They
{: #movie_690 }
- **Network:** `movie_690`: undirected, valued; 2 nodes, 1 edges.
- **Description:** Interactions of characters in the movie "They" (2002)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0283632
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_690`

### movie_691: The Thing
{: #movie_691 }
- **Network:** `movie_691`: undirected, valued; 21 nodes, 126 edges.
- **Description:** Interactions of characters in the movie "The Thing" (1982)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0084787
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_691`

### movie_692: Thirteen Days
{: #movie_692 }
- **Network:** `movie_692`: undirected, valued; 48 nodes, 146 edges.
- **Description:** Interactions of characters in the movie "Thirteen Days" (2000)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0146309
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_692`

### movie_693: This Boy's Life
{: #movie_693 }
- **Network:** `movie_693`: undirected, valued; 30 nodes, 64 edges.
- **Description:** Interactions of characters in the movie "This Boy's Life" (1993)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0108330
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_693`

### movie_694: Three Kings
{: #movie_694 }
- **Network:** `movie_694`: undirected, valued; 40 nodes, 176 edges.
- **Description:** Interactions of characters in the movie "Three Kings" (1999)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0120188
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_694`

### movie_695: Kings of the Turf
{: #movie_695 }
- **Network:** `movie_695`: undirected, valued; 9 nodes, 16 edges.
- **Description:** Interactions of characters in the movie "Kings of the Turf" (1941)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0033788
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_695`

### movie_696: 3 Men and a Baby
{: #movie_696 }
- **Network:** `movie_696`: undirected, valued; 43 nodes, 147 edges.
- **Description:** Interactions of characters in the movie "3 Men and a Baby" (1987)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0094137
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_696`

### movie_697: The Three Musketeers
{: #movie_697 }
- **Network:** `movie_697`: undirected, valued; 32 nodes, 120 edges.
- **Description:** Interactions of characters in the movie "The Three Musketeers" (1993)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0108333
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_697`

### movie_698: Thunderheart
{: #movie_698 }
- **Network:** `movie_698`: undirected, valued; 39 nodes, 154 edges.
- **Description:** Interactions of characters in the movie "Thunderheart" (1992)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0105585
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_698`

### movie_699: Timber Falls
{: #movie_699 }
- **Network:** `movie_699`: undirected, valued; 9 nodes, 24 edges.
- **Description:** Interactions of characters in the movie "Timber Falls" (2007)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0857295
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_699`

### movie_7: 17 Again
{: #movie_7 }
- **Network:** `movie_7`: undirected, valued; 36 nodes, 128 edges.
- **Description:** Interactions of characters in the movie "17 Again" (2009)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0974661
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_7`

### movie_70: Austin Powers: The Spy Who Shagged Me
{: #movie_70 }
- **Network:** `movie_70`: undirected, valued; 41 nodes, 117 edges.
- **Description:** Interactions of characters in the movie "Austin Powers: The Spy Who Shagged Me" (1999)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0145660
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_70`

### movie_700: The Time Machine
{: #movie_700 }
- **Network:** `movie_700`: undirected, valued; 12 nodes, 22 edges.
- **Description:** Interactions of characters in the movie "The Time Machine" (2002)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0268695
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_700`

### movie_701: Tin Cup
{: #movie_701 }
- **Network:** `movie_701`: undirected, valued; 33 nodes, 123 edges.
- **Description:** Interactions of characters in the movie "Tin Cup" (1996)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0117918
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_701`

### movie_702: The Day After Tomorrow
{: #movie_702 }
- **Network:** `movie_702`: undirected, valued; 42 nodes, 171 edges.
- **Description:** Interactions of characters in the movie "The Day After Tomorrow" (2004)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0319262
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_702`

### movie_703: Titanic
{: #movie_703 }
- **Network:** `movie_703`: undirected, valued; 70 nodes, 299 edges.
- **Description:** Interactions of characters in the movie "Titanic" (1997)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0120338
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_703`

### movie_704: TMNT
{: #movie_704 }
- **Network:** `movie_704`: undirected, valued; 32 nodes, 202 edges.
- **Description:** Interactions of characters in the movie "TMNT" (2007)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0453556
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_704`

### movie_705: To Sleep with Anger
{: #movie_705 }
- **Network:** `movie_705`: undirected, valued; 30 nodes, 115 edges.
- **Description:** Interactions of characters in the movie "To Sleep with Anger" (1990)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0100791
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_705`

### movie_706: Tombstone
{: #movie_706 }
- **Network:** `movie_706`: undirected, valued; 48 nodes, 337 edges.
- **Description:** Interactions of characters in the movie "Tombstone" (1993)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0108358
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_706`

### movie_707: Tomorrow Never Dies
{: #movie_707 }
- **Network:** `movie_707`: undirected, valued; 75 nodes, 217 edges.
- **Description:** Interactions of characters in the movie "Tomorrow Never Dies" (1997)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0120347
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_707`

### movie_708: Top Gun
{: #movie_708 }
- **Network:** `movie_708`: undirected, valued; 34 nodes, 167 edges.
- **Description:** Interactions of characters in the movie "Top Gun" (1986)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0092099
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_708`

### movie_709: Total Recall
{: #movie_709 }
- **Network:** `movie_709`: undirected, valued; 41 nodes, 85 edges.
- **Description:** Interactions of characters in the movie "Total Recall" (1990)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0100802
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_709`

### movie_71: Autumn in New York
{: #movie_71 }
- **Network:** `movie_71`: undirected, valued; 33 nodes, 96 edges.
- **Description:** Interactions of characters in the movie "Autumn in New York" (2000)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0174480
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_71`

### movie_710: The Tourist
{: #movie_710 }
- **Network:** `movie_710`: undirected, valued; 19 nodes, 46 edges.
- **Description:** Interactions of characters in the movie "The Tourist" (2010)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1243957
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_710`

### movie_711: Toy Story
{: #movie_711 }
- **Network:** `movie_711`: undirected, valued; 39 nodes, 204 edges.
- **Description:** Interactions of characters in the movie "Toy Story" (1995)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0114709
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_711`

### movie_712: Traffic
{: #movie_712 }
- **Network:** `movie_712`: undirected, valued; 68 nodes, 131 edges.
- **Description:** Interactions of characters in the movie "Traffic" (2000)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0181865
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_712`

### movie_713: Trainspotting
{: #movie_713 }
- **Network:** `movie_713`: undirected, valued; 22 nodes, 60 edges.
- **Description:** Interactions of characters in the movie "Trainspotting" (1996)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0117951
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_713`

### movie_714: The Transformers: The Movie
{: #movie_714 }
- **Network:** `movie_714`: undirected, valued; 63 nodes, 591 edges.
- **Description:** Interactions of characters in the movie "The Transformers: The Movie" (1986)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0092106
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_714`

### movie_715: Tremors
{: #movie_715 }
- **Network:** `movie_715`: undirected, valued; 16 nodes, 74 edges.
- **Description:** Interactions of characters in the movie "Tremors" (1990)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0100814
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_715`

### movie_716: TRON
{: #movie_716 }
- **Network:** `movie_716`: undirected, valued; 27 nodes, 111 edges.
- **Description:** Interactions of characters in the movie "TRON" (1982)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0084827
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_716`

### movie_717: Tropic Thunder
{: #movie_717 }
- **Network:** `movie_717`: undirected, valued; 44 nodes, 219 edges.
- **Description:** Interactions of characters in the movie "Tropic Thunder" (2008)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0942385
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_717`

### movie_718: True Lies
{: #movie_718 }
- **Network:** `movie_718`: undirected, valued; 29 nodes, 59 edges.
- **Description:** Interactions of characters in the movie "True Lies" (1994)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0111503
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_718`

### movie_719: True Romance
{: #movie_719 }
- **Network:** `movie_719`: undirected, valued; 43 nodes, 237 edges.
- **Description:** Interactions of characters in the movie "True Romance" (1993)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0108399
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_719`

### movie_72: Avatar
{: #movie_72 }
- **Network:** `movie_72`: undirected, valued; 30 nodes, 105 edges.
- **Description:** Interactions of characters in the movie "Avatar" (2009)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0499549
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_72`

### movie_720: The Truman Show
{: #movie_720 }
- **Network:** `movie_720`: undirected, valued; 44 nodes, 87 edges.
- **Description:** Interactions of characters in the movie "The Truman Show" (1998)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0120382
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_720`

### movie_721: Twilight
{: #movie_721 }
- **Network:** `movie_721`: undirected, valued; 31 nodes, 135 edges.
- **Description:** Interactions of characters in the movie "Twilight" (2008)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1099212
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_721`

### movie_722: New Moon
{: #movie_722 }
- **Network:** `movie_722`: undirected, valued; 36 nodes, 130 edges.
- **Description:** Interactions of characters in the movie "New Moon" (2009)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1259571
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_722`

### movie_723: Twin Peaks
{: #movie_723 }
- **Network:** `movie_723`: undirected, valued; 56 nodes, 144 edges.
- **Description:** Interactions of characters in the movie "Twin Peaks" (1990)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0098936
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_723`

### movie_724: Dead Ringers
{: #movie_724 }
- **Network:** `movie_724`: undirected, valued; 45 nodes, 99 edges.
- **Description:** Interactions of characters in the movie "Dead Ringers" (1988)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0094964
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_724`

### movie_725: Two for the Money
{: #movie_725 }
- **Network:** `movie_725`: undirected, valued; 40 nodes, 103 edges.
- **Description:** Interactions of characters in the movie "Two for the Money" (2005)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0417217
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_725`

### movie_726: U Turn
{: #movie_726 }
- **Network:** `movie_726`: undirected, valued; 20 nodes, 52 edges.
- **Description:** Interactions of characters in the movie "U Turn" (1997)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0120399
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_726`

### movie_727: Unbreakable
{: #movie_727 }
- **Network:** `movie_727`: undirected, valued; 30 nodes, 60 edges.
- **Description:** Interactions of characters in the movie "Unbreakable" (2000)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0217869
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_727`

### movie_728: Up
{: #movie_728 }
- **Network:** `movie_728`: undirected, valued; 22 nodes, 49 edges.
- **Description:** Interactions of characters in the movie "Up" (2009)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1049413
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_728`

### movie_729: Up in the Air
{: #movie_729 }
- **Network:** `movie_729`: undirected, valued; 27 nodes, 47 edges.
- **Description:** Interactions of characters in the movie "Up in the Air" (2009)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1193138
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_729`

### movie_73: The Avengers
{: #movie_73 }
- **Network:** `movie_73`: undirected, valued; 21 nodes, 48 edges.
- **Description:** Interactions of characters in the movie "The Avengers" (1961)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0054518
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_73`

### movie_730: The Usual Suspects
{: #movie_730 }
- **Network:** `movie_730`: undirected, valued; 35 nodes, 130 edges.
- **Description:** Interactions of characters in the movie "The Usual Suspects" (1995)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0114814
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_730`

### movie_731: V for Vendetta
{: #movie_731 }
- **Network:** `movie_731`: undirected, valued; 44 nodes, 100 edges.
- **Description:** Interactions of characters in the movie "V for Vendetta" (2006)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0434409
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_731`

### movie_732: Valkyrie
{: #movie_732 }
- **Network:** `movie_732`: undirected, valued; 45 nodes, 101 edges.
- **Description:** Interactions of characters in the movie "Valkyrie" (2008)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0985699
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_732`

### movie_733: Vanilla Sky
{: #movie_733 }
- **Network:** `movie_733`: undirected, valued; 29 nodes, 69 edges.
- **Description:** Interactions of characters in the movie "Vanilla Sky" (2001)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0259711
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_733`

### movie_734: The Verdict
{: #movie_734 }
- **Network:** `movie_734`: undirected, valued; 42 nodes, 114 edges.
- **Description:** Interactions of characters in the movie "The Verdict" (1982)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0084855
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_734`

### movie_735: Very Bad Things
{: #movie_735 }
- **Network:** `movie_735`: undirected, valued; 30 nodes, 118 edges.
- **Description:** Interactions of characters in the movie "Very Bad Things" (1998)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0124198
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_735`

### movie_736: Virtuosity
{: #movie_736 }
- **Network:** `movie_736`: undirected, valued; 35 nodes, 84 edges.
- **Description:** Interactions of characters in the movie "Virtuosity" (1995)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0114857
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_736`

### movie_737: Wag the Dog
{: #movie_737 }
- **Network:** `movie_737`: undirected, valued; 60 nodes, 269 edges.
- **Description:** Interactions of characters in the movie "Wag the Dog" (1997)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0120885
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_737`

### movie_738: A Walk to Remember
{: #movie_738 }
- **Network:** `movie_738`: undirected, valued; 20 nodes, 42 edges.
- **Description:** Interactions of characters in the movie "A Walk to Remember" (2002)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0281358
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_738`

### movie_739: Walking Tall
{: #movie_739 }
- **Network:** `movie_739`: undirected, valued; 38 nodes, 142 edges.
- **Description:** Interactions of characters in the movie "Walking Tall" (2004)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0351977
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_739`

### movie_74: Awakenings
{: #movie_74 }
- **Network:** `movie_74`: undirected, valued; 52 nodes, 261 edges.
- **Description:** Interactions of characters in the movie "Awakenings" (1990)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0099077
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_74`

### movie_740: Wall Street
{: #movie_740 }
- **Network:** `movie_740`: undirected, valued; 53 nodes, 162 edges.
- **Description:** Interactions of characters in the movie "Wall Street" (1987)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0094291
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_740`

### movie_741: WALL-E
{: #movie_741 }
- **Network:** `movie_741`: undirected, valued; 34 nodes, 206 edges.
- **Description:** Interactions of characters in the movie "WALL-E" (2008)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0910970
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_741`

### movie_742: Wanted
{: #movie_742 }
- **Network:** `movie_742`: undirected, valued; 25 nodes, 54 edges.
- **Description:** Interactions of characters in the movie "Wanted" (2008)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0493464
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_742`

### movie_743: War of the Worlds
{: #movie_743 }
- **Network:** `movie_743`: undirected, valued; 31 nodes, 114 edges.
- **Description:** Interactions of characters in the movie "War of the Worlds" (2005)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0407304
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_743`

### movie_744: Warm Springs
{: #movie_744 }
- **Network:** `movie_744`: undirected, valued; 49 nodes, 193 edges.
- **Description:** Interactions of characters in the movie "Warm Springs" (2005)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0423510
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_744`

### movie_745: Watchmen
{: #movie_745 }
- **Network:** `movie_745`: undirected, valued; 76 nodes, 201 edges.
- **Description:** Interactions of characters in the movie "Watchmen" (2009)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0409459
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_745`

### movie_746: We Own the Night
{: #movie_746 }
- **Network:** `movie_746`: undirected, valued; 57 nodes, 204 edges.
- **Description:** Interactions of characters in the movie "We Own the Night" (2007)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0498399
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_746`

### movie_747: What About Bob?
{: #movie_747 }
- **Network:** `movie_747`: undirected, valued; 51 nodes, 134 edges.
- **Description:** Interactions of characters in the movie "What About Bob?" (1991)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0103241
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_747`

### movie_748: What Lies Beneath
{: #movie_748 }
- **Network:** `movie_748`: undirected, valued; 18 nodes, 32 edges.
- **Description:** Interactions of characters in the movie "What Lies Beneath" (2000)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0161081
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_748`

### movie_749: When a Stranger Calls
{: #movie_749 }
- **Network:** `movie_749`: undirected, valued; 41 nodes, 117 edges.
- **Description:** Interactions of characters in the movie "When a Stranger Calls" (2006)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0455857
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_749`

### movie_75: Babel
{: #movie_75 }
- **Network:** `movie_75`: undirected, valued; 71 nodes, 154 edges.
- **Description:** Interactions of characters in the movie "Babel" (2006)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0449467
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_75`

### movie_750: While She Was Out
{: #movie_750 }
- **Network:** `movie_750`: undirected, valued; 19 nodes, 42 edges.
- **Description:** Interactions of characters in the movie "While She Was Out" (2008)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0887971
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_750`

### movie_751: White Christmas
{: #movie_751 }
- **Network:** `movie_751`: undirected, valued; 28 nodes, 114 edges.
- **Description:** Interactions of characters in the movie "White Christmas" (1954)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0047673
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_751`

### movie_752: White Jazz
{: #movie_752 }
- **Network:** `movie_752`: undirected, valued; 41 nodes, 119 edges.
- **Description:** Interactions of characters in the movie "White Jazz" (2012)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0892384
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_752`

### movie_753: White Squall
{: #movie_753 }
- **Network:** `movie_753`: undirected, valued; 43 nodes, 279 edges.
- **Description:** Interactions of characters in the movie "White Squall" (1996)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0118158
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_753`

### movie_754: Whiteout
{: #movie_754 }
- **Network:** `movie_754`: undirected, valued; 24 nodes, 62 edges.
- **Description:** Interactions of characters in the movie "Whiteout" (2009)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0365929
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_754`

### movie_755: Who Framed Roger Rabbit
{: #movie_755 }
- **Network:** `movie_755`: undirected, valued; 43 nodes, 138 edges.
- **Description:** Interactions of characters in the movie "Who Framed Roger Rabbit" (1988)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0096438
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_755`

### movie_756: Wild at Heart
{: #movie_756 }
- **Network:** `movie_756`: undirected, valued; 41 nodes, 84 edges.
- **Description:** Interactions of characters in the movie "Wild at Heart" (1990)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0100935
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_756`

### movie_757: The Wild Bunch
{: #movie_757 }
- **Network:** `movie_757`: undirected, valued; 55 nodes, 392 edges.
- **Description:** Interactions of characters in the movie "The Wild Bunch" (1969)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0065214
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_757`

### movie_758: Where the Wild Things Are
{: #movie_758 }
- **Network:** `movie_758`: undirected, valued; 28 nodes, 88 edges.
- **Description:** Interactions of characters in the movie "Where the Wild Things Are" (2009)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0386117
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_758`

### movie_759: Wild Wild West
{: #movie_759 }
- **Network:** `movie_759`: undirected, valued; 28 nodes, 77 edges.
- **Description:** Interactions of characters in the movie "Wild Wild West" (1999)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0120891
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_759`

### movie_76: Bachelor Party
{: #movie_76 }
- **Network:** `movie_76`: undirected, valued; 62 nodes, 284 edges.
- **Description:** Interactions of characters in the movie "Bachelor Party" (1984)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0086927
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_76`

### movie_760: Willow
{: #movie_760 }
- **Network:** `movie_760`: undirected, valued; 39 nodes, 123 edges.
- **Description:** Interactions of characters in the movie "Willow" (1988)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0096446
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_760`

### movie_761: Witness
{: #movie_761 }
- **Network:** `movie_761`: undirected, valued; 48 nodes, 231 edges.
- **Description:** Interactions of characters in the movie "Witness" (1985)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0090329
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_761`

### movie_762: Wonder Boys
{: #movie_762 }
- **Network:** `movie_762`: undirected, valued; 29 nodes, 86 edges.
- **Description:** Interactions of characters in the movie "Wonder Boys" (2000)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0185014
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_762`

### movie_763: The Woodsman
{: #movie_763 }
- **Network:** `movie_763`: undirected, valued; 15 nodes, 25 edges.
- **Description:** Interactions of characters in the movie "The Woodsman" (2004)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0361127
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_763`

### movie_764: The Wrestler
{: #movie_764 }
- **Network:** `movie_764`: undirected, valued; 43 nodes, 81 edges.
- **Description:** Interactions of characters in the movie "The Wrestler" (2008)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1125849
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_764`

### movie_765: The X Files
{: #movie_765 }
- **Network:** `movie_765`: undirected, valued; 24 nodes, 41 edges.
- **Description:** Interactions of characters in the movie "The X Files" (1998)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0120902
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_765`

### movie_766: X-Men
{: #movie_766 }
- **Network:** `movie_766`: undirected, valued; 25 nodes, 91 edges.
- **Description:** Interactions of characters in the movie "X-Men" (2000)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0120903
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_766`

### movie_767: X-Men Origins: Wolverine
{: #movie_767 }
- **Network:** `movie_767`: undirected, valued; 38 nodes, 67 edges.
- **Description:** Interactions of characters in the movie "X-Men Origins: Wolverine" (2009)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0458525
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_767`

### movie_768: xXx
{: #movie_768 }
- **Network:** `movie_768`: undirected, valued; 27 nodes, 60 edges.
- **Description:** Interactions of characters in the movie "xXx" (2002)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0295701
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_768`

### movie_769: Yes Man
{: #movie_769 }
- **Network:** `movie_769`: undirected, valued; 50 nodes, 132 edges.
- **Description:** Interactions of characters in the movie "Yes Man" (2008)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1068680
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_769`

### movie_77: Backdraft
{: #movie_77 }
- **Network:** `movie_77`: undirected, valued; 40 nodes, 174 edges.
- **Description:** Interactions of characters in the movie "Backdraft" (1991)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0101393
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_77`

### movie_770: You Can Count on Me
{: #movie_770 }
- **Network:** `movie_770`: undirected, valued; 16 nodes, 39 edges.
- **Description:** Interactions of characters in the movie "You Can Count on Me" (2000)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0203230
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_770`

### movie_771: You've Got Mail
{: #movie_771 }
- **Network:** `movie_771`: undirected, valued; 38 nodes, 96 edges.
- **Description:** Interactions of characters in the movie "You've Got Mail" (1998)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0128853
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_771`

### movie_772: Youth in Revolt
{: #movie_772 }
- **Network:** `movie_772`: undirected, valued; 42 nodes, 129 edges.
- **Description:** Interactions of characters in the movie "Youth in Revolt" (2009)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0403702
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_772`

### movie_773: Zerophilia
{: #movie_773 }
- **Network:** `movie_773`: undirected, valued; 14 nodes, 44 edges.
- **Description:** Interactions of characters in the movie "Zerophilia" (2005)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0421090
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_773`

### movie_78: Bad Boys
{: #movie_78 }
- **Network:** `movie_78`: undirected, valued; 38 nodes, 95 edges.
- **Description:** Interactions of characters in the movie "Bad Boys" (1995)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0112442
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_78`

### movie_79: Bad Day at Black Rock
{: #movie_79 }
- **Network:** `movie_79`: undirected, valued; 15 nodes, 50 edges.
- **Description:** Interactions of characters in the movie "Bad Day at Black Rock" (1955)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0047849
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_79`

### movie_8: One Eight Seven
{: #movie_8 }
- **Network:** `movie_8`: undirected, valued; 33 nodes, 68 edges.
- **Description:** Interactions of characters in the movie "One Eight Seven" (1997)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0118531
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_8`

### movie_80: The Bad Lieutenant: Port of Call - New Orleans
{: #movie_80 }
- **Network:** `movie_80`: undirected, valued; 39 nodes, 84 edges.
- **Description:** Interactions of characters in the movie "The Bad Lieutenant: Port of Call - New Orleans" (2009)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1095217
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_80`

### movie_81: Bad Santa
{: #movie_81 }
- **Network:** `movie_81`: undirected, valued; 27 nodes, 64 edges.
- **Description:** Interactions of characters in the movie "Bad Santa" (2003)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0307987
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_81`

### movie_82: Badlands
{: #movie_82 }
- **Network:** `movie_82`: undirected, valued; 18 nodes, 28 edges.
- **Description:** Interactions of characters in the movie "Badlands" (1973)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0069762
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_82`

### movie_83: Bamboozled
{: #movie_83 }
- **Network:** `movie_83`: undirected, valued; 56 nodes, 198 edges.
- **Description:** Interactions of characters in the movie "Bamboozled" (2000)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0215545
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_83`

### movie_84: Barry Lyndon
{: #movie_84 }
- **Network:** `movie_84`: undirected, valued; 47 nodes, 95 edges.
- **Description:** Interactions of characters in the movie "Barry Lyndon" (1975)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0072684
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_84`

### movie_85: Basic
{: #movie_85 }
- **Network:** `movie_85`: undirected, valued; 22 nodes, 65 edges.
- **Description:** Interactions of characters in the movie "Basic" (2003)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0264395
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_85`

### movie_86: Basic Instinct
{: #movie_86 }
- **Network:** `movie_86`: undirected, valued; 25 nodes, 84 edges.
- **Description:** Interactions of characters in the movie "Basic Instinct" (1992)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0103772
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_86`

### movie_87: Basquiat
{: #movie_87 }
- **Network:** `movie_87`: undirected, valued; 59 nodes, 365 edges.
- **Description:** Interactions of characters in the movie "Basquiat" (1996)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0115632
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_87`

### movie_88: Batman
{: #movie_88 }
- **Network:** `movie_88`: undirected, valued; 49 nodes, 127 edges.
- **Description:** Interactions of characters in the movie "Batman" (1989)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0096895
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_88`

### movie_89: Batman Returns
{: #movie_89 }
- **Network:** `movie_89`: undirected, valued; 51 nodes, 124 edges.
- **Description:** Interactions of characters in the movie "Batman Returns" (1992)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0103776
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_89`

### movie_9: 2001: A Space Odyssey
{: #movie_9 }
- **Network:** `movie_9`: undirected, valued; 27 nodes, 102 edges.
- **Description:** Interactions of characters in the movie "2001: A Space Odyssey" (1968)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0062622
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_9`

### movie_90: The Battle of Algiers
{: #movie_90 }
- **Network:** `movie_90`: undirected, valued; 33 nodes, 67 edges.
- **Description:** Interactions of characters in the movie "The Battle of Algiers" (1966)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0058946
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_90`

### movie_91: The Battle of Shaker Heights
{: #movie_91 }
- **Network:** `movie_91`: undirected, valued; 32 nodes, 80 edges.
- **Description:** Interactions of characters in the movie "The Battle of Shaker Heights" (2003)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0357470
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_91`

### movie_92: The Beach
{: #movie_92 }
- **Network:** `movie_92`: undirected, valued; 35 nodes, 104 edges.
- **Description:** Interactions of characters in the movie "The Beach" (2000)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0163978
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_92`

### movie_93: Bean
{: #movie_93 }
- **Network:** `movie_93`: undirected, valued; 32 nodes, 84 edges.
- **Description:** Interactions of characters in the movie "Bean" (1997)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0118689
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_93`

### movie_94: Beavis and Butt-Head Do America
{: #movie_94 }
- **Network:** `movie_94`: undirected, valued; 56 nodes, 150 edges.
- **Description:** Interactions of characters in the movie "Beavis and Butt-Head Do America" (1996)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0115641
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_94`

### movie_95: Being Human
{: #movie_95 }
- **Network:** `movie_95`: undirected, valued; 59 nodes, 154 edges.
- **Description:** Interactions of characters in the movie "Being Human" (2008)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt1349938
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_95`

### movie_96: Being John Malkovich
{: #movie_96 }
- **Network:** `movie_96`: undirected, valued; 34 nodes, 83 edges.
- **Description:** Interactions of characters in the movie "Being John Malkovich" (1999)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0120601
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_96`

### movie_97: Being There
{: #movie_97 }
- **Network:** `movie_97`: undirected, valued; 48 nodes, 114 edges.
- **Description:** Interactions of characters in the movie "Being There" (1979)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0078841
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_97`

### movie_98: The Believer
{: #movie_98 }
- **Network:** `movie_98`: undirected, valued; 50 nodes, 150 edges.
- **Description:** Interactions of characters in the movie "The Believer" (2001)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0247199
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_98`

### movie_99: Beloved
{: #movie_99 }
- **Network:** `movie_99`: undirected, valued; 31 nodes, 65 edges.
- **Description:** Interactions of characters in the movie "Beloved" (1998)
- **Source:** https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/T4HBA3 https://www.imdb.com/title/tt0120603
- **References:** Kaminski, Jermain; Schober, Michael; Albaladejo, Raymond; Zastupailo, Oleksandr; Hidalgo, César, 2018, Moviegalaxies - Social Networks in Movies, https://doi.org/10.7910/DVN/T4HBA3, Harvard Dataverse, V3
- **Load:** `nwwebuse schoch movie_99`

## Shakespeare's plays

### shakespeare_1: A Comedy of Errors
{: #shakespeare_1 }
- **Network:** `shakespeare_1`: undirected, valued; 20 nodes, 130 edges.
- **Description:** scene co-occurences in Shakespeare's "A Comedy of Errors"
- **Source:** Raw data downloaded from https://github.com/mallaham/Shakespeare-Plays
- **Load:** `nwwebuse schoch shakespeare_1`

### shakespeare_10: Henry IV
{: #shakespeare_10 }
- **Network:** `shakespeare_10`: undirected, valued; 35 nodes, 152 edges.
- **Description:** scene co-occurences in Shakespeare's "Henry IV"
- **Source:** Raw data downloaded from https://github.com/mallaham/Shakespeare-Plays
- **Load:** `nwwebuse schoch shakespeare_10`

### shakespeare_11: Henry V
{: #shakespeare_11 }
- **Network:** `shakespeare_11`: undirected, valued; 47 nodes, 228 edges.
- **Description:** scene co-occurences in Shakespeare's "Henry V"
- **Source:** Raw data downloaded from https://github.com/mallaham/Shakespeare-Plays
- **Load:** `nwwebuse schoch shakespeare_11`

### shakespeare_12: Henry VI Part 1
{: #shakespeare_12 }
- **Network:** `shakespeare_12`: undirected, valued; 52 nodes, 314 edges.
- **Description:** scene co-occurences in Shakespeare's "Henry VI Part 1"
- **Source:** Raw data downloaded from https://github.com/mallaham/Shakespeare-Plays
- **Load:** `nwwebuse schoch shakespeare_12`

### shakespeare_13: Henry VI Part 2
{: #shakespeare_13 }
- **Network:** `shakespeare_13`: undirected, valued; 64 nodes, 422 edges.
- **Description:** scene co-occurences in Shakespeare's "Henry VI Part 2"
- **Source:** Raw data downloaded from https://github.com/mallaham/Shakespeare-Plays
- **Load:** `nwwebuse schoch shakespeare_13`

### shakespeare_14: Henry VI Part 3
{: #shakespeare_14 }
- **Network:** `shakespeare_14`: undirected, valued; 46 nodes, 272 edges.
- **Description:** scene co-occurences in Shakespeare's "Henry VI Part 3"
- **Source:** Raw data downloaded from https://github.com/mallaham/Shakespeare-Plays
- **Load:** `nwwebuse schoch shakespeare_14`

### shakespeare_15: Henry VIII
{: #shakespeare_15 }
- **Network:** `shakespeare_15`: undirected, valued; 46 nodes, 212 edges.
- **Description:** scene co-occurences in Shakespeare's "Henry VIII"
- **Source:** Raw data downloaded from https://github.com/mallaham/Shakespeare-Plays
- **Load:** `nwwebuse schoch shakespeare_15`

### shakespeare_16: Julius Caesar
{: #shakespeare_16 }
- **Network:** `shakespeare_16`: undirected, valued; 50 nodes, 290 edges.
- **Description:** scene co-occurences in Shakespeare's "Julius Caesar"
- **Source:** Raw data downloaded from https://github.com/mallaham/Shakespeare-Plays
- **Load:** `nwwebuse schoch shakespeare_16`

### shakespeare_17: King John
{: #shakespeare_17 }
- **Network:** `shakespeare_17`: undirected, valued; 29 nodes, 161 edges.
- **Description:** scene co-occurences in Shakespeare's "King John"
- **Source:** Raw data downloaded from https://github.com/mallaham/Shakespeare-Plays
- **Load:** `nwwebuse schoch shakespeare_17`

### shakespeare_18: King Lear
{: #shakespeare_18 }
- **Network:** `shakespeare_18`: undirected, valued; 26 nodes, 161 edges.
- **Description:** scene co-occurences in Shakespeare's "King Lear"
- **Source:** Raw data downloaded from https://github.com/mallaham/Shakespeare-Plays
- **Load:** `nwwebuse schoch shakespeare_18`

### shakespeare_19: Loves Labours Lost
{: #shakespeare_19 }
- **Network:** `shakespeare_19`: undirected, valued; 20 nodes, 143 edges.
- **Description:** scene co-occurences in Shakespeare's "Loves Labours Lost"
- **Source:** Raw data downloaded from https://github.com/mallaham/Shakespeare-Plays
- **Load:** `nwwebuse schoch shakespeare_19`

### shakespeare_2: A Midsummer nights dream
{: #shakespeare_2 }
- **Network:** `shakespeare_2`: undirected, valued; 30 nodes, 238 edges.
- **Description:** scene co-occurences in Shakespeare's "A Midsummer nights dream"
- **Source:** Raw data downloaded from https://github.com/mallaham/Shakespeare-Plays
- **Load:** `nwwebuse schoch shakespeare_2`

### shakespeare_20: macbeth
{: #shakespeare_20 }
- **Network:** `shakespeare_20`: undirected, valued; 41 nodes, 188 edges.
- **Description:** scene co-occurences in Shakespeare's "macbeth"
- **Source:** Raw data downloaded from https://github.com/mallaham/Shakespeare-Plays
- **Load:** `nwwebuse schoch shakespeare_20`

### shakespeare_21: Measure for measure
{: #shakespeare_21 }
- **Network:** `shakespeare_21`: undirected, valued; 25 nodes, 110 edges.
- **Description:** scene co-occurences in Shakespeare's "Measure for measure"
- **Source:** Raw data downloaded from https://github.com/mallaham/Shakespeare-Plays
- **Load:** `nwwebuse schoch shakespeare_21`

### shakespeare_22: Merchant of Venice
{: #shakespeare_22 }
- **Network:** `shakespeare_22`: undirected, valued; 23 nodes, 119 edges.
- **Description:** scene co-occurences in Shakespeare's "Merchant of Venice"
- **Source:** Raw data downloaded from https://github.com/mallaham/Shakespeare-Plays
- **Load:** `nwwebuse schoch shakespeare_22`

### shakespeare_23: Merry Wives of Windsor
{: #shakespeare_23 }
- **Network:** `shakespeare_23`: undirected, valued; 24 nodes, 182 edges.
- **Description:** scene co-occurences in Shakespeare's "Merry Wives of Windsor"
- **Source:** Raw data downloaded from https://github.com/mallaham/Shakespeare-Plays
- **Load:** `nwwebuse schoch shakespeare_23`

### shakespeare_24: Much Ado about nothing
{: #shakespeare_24 }
- **Network:** `shakespeare_24`: undirected, valued; 24 nodes, 140 edges.
- **Description:** scene co-occurences in Shakespeare's "Much Ado about nothing"
- **Source:** Raw data downloaded from https://github.com/mallaham/Shakespeare-Plays
- **Load:** `nwwebuse schoch shakespeare_24`

### shakespeare_25: Othello
{: #shakespeare_25 }
- **Network:** `shakespeare_25`: undirected, valued; 27 nodes, 172 edges.
- **Description:** scene co-occurences in Shakespeare's "Othello"
- **Source:** Raw data downloaded from https://github.com/mallaham/Shakespeare-Plays
- **Load:** `nwwebuse schoch shakespeare_25`

### shakespeare_26: Pericles
{: #shakespeare_26 }
- **Network:** `shakespeare_26`: undirected, valued; 46 nodes, 185 edges.
- **Description:** scene co-occurences in Shakespeare's "Pericles"
- **Source:** Raw data downloaded from https://github.com/mallaham/Shakespeare-Plays
- **Load:** `nwwebuse schoch shakespeare_26`

### shakespeare_27: Richard II
{: #shakespeare_27 }
- **Network:** `shakespeare_27`: undirected, valued; 35 nodes, 170 edges.
- **Description:** scene co-occurences in Shakespeare's "Richard II"
- **Source:** Raw data downloaded from https://github.com/mallaham/Shakespeare-Plays
- **Load:** `nwwebuse schoch shakespeare_27`

### shakespeare_28: Richard III
{: #shakespeare_28 }
- **Network:** `shakespeare_28`: undirected, valued; 68 nodes, 477 edges.
- **Description:** scene co-occurences in Shakespeare's "Richard III"
- **Source:** Raw data downloaded from https://github.com/mallaham/Shakespeare-Plays
- **Load:** `nwwebuse schoch shakespeare_28`

### shakespeare_29: Romeo and Juliet
{: #shakespeare_29 }
- **Network:** `shakespeare_29`: undirected, valued; 34 nodes, 233 edges.
- **Description:** scene co-occurences in Shakespeare's "Romeo and Juliet"
- **Source:** Raw data downloaded from https://github.com/mallaham/Shakespeare-Plays
- **Load:** `nwwebuse schoch shakespeare_29`

### shakespeare_3: A Winters Tale
{: #shakespeare_3 }
- **Network:** `shakespeare_3`: undirected, valued; 35 nodes, 174 edges.
- **Description:** scene co-occurences in Shakespeare's "A Winters Tale"
- **Source:** Raw data downloaded from https://github.com/mallaham/Shakespeare-Plays
- **Load:** `nwwebuse schoch shakespeare_3`

### shakespeare_30: Taming of the Shrew
{: #shakespeare_30 }
- **Network:** `shakespeare_30`: undirected, valued; 37 nodes, 226 edges.
- **Description:** scene co-occurences in Shakespeare's "Taming of the Shrew"
- **Source:** Raw data downloaded from https://github.com/mallaham/Shakespeare-Plays
- **Load:** `nwwebuse schoch shakespeare_30`

### shakespeare_31: The Tempest
{: #shakespeare_31 }
- **Network:** `shakespeare_31`: undirected, valued; 20 nodes, 121 edges.
- **Description:** scene co-occurences in Shakespeare's "The Tempest"
- **Source:** Raw data downloaded from https://github.com/mallaham/Shakespeare-Plays
- **Load:** `nwwebuse schoch shakespeare_31`

### shakespeare_32: Timon of Athens
{: #shakespeare_32 }
- **Network:** `shakespeare_32`: undirected, valued; 55 nodes, 352 edges.
- **Description:** scene co-occurences in Shakespeare's "Timon of Athens"
- **Source:** Raw data downloaded from https://github.com/mallaham/Shakespeare-Plays
- **Load:** `nwwebuse schoch shakespeare_32`

### shakespeare_33: Titus Andronicus
{: #shakespeare_33 }
- **Network:** `shakespeare_33`: undirected, valued; 27 nodes, 179 edges.
- **Description:** scene co-occurences in Shakespeare's "Titus Andronicus"
- **Source:** Raw data downloaded from https://github.com/mallaham/Shakespeare-Plays
- **Load:** `nwwebuse schoch shakespeare_33`

### shakespeare_34: Troilus and Cressida
{: #shakespeare_34 }
- **Network:** `shakespeare_34`: undirected, valued; 28 nodes, 160 edges.
- **Description:** scene co-occurences in Shakespeare's "Troilus and Cressida"
- **Source:** Raw data downloaded from https://github.com/mallaham/Shakespeare-Plays
- **Load:** `nwwebuse schoch shakespeare_34`

### shakespeare_35: Twelfth Night
{: #shakespeare_35 }
- **Network:** `shakespeare_35`: undirected, valued; 18 nodes, 101 edges.
- **Description:** scene co-occurences in Shakespeare's "Twelfth Night"
- **Source:** Raw data downloaded from https://github.com/mallaham/Shakespeare-Plays
- **Load:** `nwwebuse schoch shakespeare_35`

### shakespeare_36: Two Gentlemen of Verona
{: #shakespeare_36 }
- **Network:** `shakespeare_36`: undirected, valued; 17 nodes, 55 edges.
- **Description:** scene co-occurences in Shakespeare's "Two Gentlemen of Verona"
- **Source:** Raw data downloaded from https://github.com/mallaham/Shakespeare-Plays
- **Load:** `nwwebuse schoch shakespeare_36`

### shakespeare_4: Alls well that ends well
{: #shakespeare_4 }
- **Network:** `shakespeare_4`: undirected, valued; 24 nodes, 112 edges.
- **Description:** scene co-occurences in Shakespeare's "Alls well that ends well"
- **Source:** Raw data downloaded from https://github.com/mallaham/Shakespeare-Plays
- **Load:** `nwwebuse schoch shakespeare_4`

### shakespeare_5: Antony and Cleopatra
{: #shakespeare_5 }
- **Network:** `shakespeare_5`: undirected, valued; 54 nodes, 313 edges.
- **Description:** scene co-occurences in Shakespeare's "Antony and Cleopatra"
- **Source:** Raw data downloaded from https://github.com/mallaham/Shakespeare-Plays
- **Load:** `nwwebuse schoch shakespeare_5`

### shakespeare_6: As you like it
{: #shakespeare_6 }
- **Network:** `shakespeare_6`: undirected, valued; 27 nodes, 110 edges.
- **Description:** scene co-occurences in Shakespeare's "As you like it"
- **Source:** Raw data downloaded from https://github.com/mallaham/Shakespeare-Plays
- **Load:** `nwwebuse schoch shakespeare_6`

### shakespeare_7: Coriolanus
{: #shakespeare_7 }
- **Network:** `shakespeare_7`: undirected, valued; 61 nodes, 429 edges.
- **Description:** scene co-occurences in Shakespeare's "Coriolanus"
- **Source:** Raw data downloaded from https://github.com/mallaham/Shakespeare-Plays
- **Load:** `nwwebuse schoch shakespeare_7`

### shakespeare_8: Cymbeline
{: #shakespeare_8 }
- **Network:** `shakespeare_8`: undirected, valued; 39 nodes, 200 edges.
- **Description:** scene co-occurences in Shakespeare's "Cymbeline"
- **Source:** Raw data downloaded from https://github.com/mallaham/Shakespeare-Plays
- **Load:** `nwwebuse schoch shakespeare_8`

### shakespeare_9: Hamlet
{: #shakespeare_9 }
- **Network:** `shakespeare_9`: undirected, valued; 34 nodes, 207 edges.
- **Description:** scene co-occurences in Shakespeare's "Hamlet"
- **Source:** Raw data downloaded from https://github.com/mallaham/Shakespeare-Plays
- **Load:** `nwwebuse schoch shakespeare_9`
