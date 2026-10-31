* nwcommands tutorial 4: a reproducible workflow
* Requires the core nwcommands.
version 17
clear all
set seed 20261031

* 1. Raw data: one file of ties, one file of people (written here so the script is self-contained)
input str6 ego str6 alter
"Ann" "Bob"
"Ann" "Cy"
"Bob" "Cy"
"Cy"  "Dee"
"Dee" "Eli"
"Eli" "Fay"
"Dee" "Fay"
end
export delimited using "edges.csv", replace
clear
input str6 name str6 dept byte age
"Ann" "sales" 31
"Bob" "sales" 45
"Cy"  "tech"  38
"Dee" "tech"  29
"Eli" "tech"  52
"Fay" "sales" 41
end
export delimited using "people.csv", replace

* 2. Read the ties and build the network
clear
import delimited using "edges.csv", varnames(1) stringcols(_all) clear
nwfromedge ego alter, name(friends) undirected
nwsummarize friends

* 3. Attach the node attributes by name
generate name = _nwnode
preserve
import delimited using "people.csv", varnames(1) stringcols(1 2) clear
tempfile people
save `people'
restore
merge 1:1 name using `people', nogenerate
list, noobs

* 4. Analyse and keep the results as variables
nwdegree friends, generate(deg) silent
nwbetween friends, generate(btw) silent
list name dept age deg btw, noobs

* 5. Save everything: network and attributes in one file
nwsave friends_project, replace
nwclear
clear
nwuse friends_project
nwsummarize friends

* 6. Hand the network to another program
nwtoedge friends
keep if friends == 1
keep _ego _alter
export delimited using "friends_edges.csv", replace
type friends_edges.csv
