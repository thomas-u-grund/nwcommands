* nwegoplot: ego in the center, alters on the unit circle, two-step contacts at radius 2 (3.20.1)
clear all
set more off
nwclear
clear
input str8 ego str8 alter
"Anna" "Gwen"
"Sophie" "Gwen"
"Fion" "Leh"
"Magalie" "Leh"
"Gwen" "Antonia"
"Leh" "Antonia"
end
nwset ego alter, edgelist directed name(firm)
nwegoplot firm, ego(Gwen) generate(x y)
assert r(alters) == 3 & r(ego) == "Gwen"
assert x == 0 & y == 0 if _nwnode == "Gwen"
assert abs(x^2 + y^2 - 1) < 1e-9 if inlist(_nwnode, "Anna", "Sophie", "Antonia")
assert x >= . if inlist(_nwnode, "Leh", "Fion", "Magalie")
* the same ego by number (Gwen is node 4 in alphabetical order)
nwegoplot firm, ego(4) generate(x y) replace
assert r(ego) == "Gwen"
capture nwegoplot firm, ego(4) generate(x y)
assert _rc == 110
nwegoplot firm, ego(Gwen) hop(2) generate(x2 y2)
assert r(alters) == 4
assert abs(x2^2 + y2^2 - 4) < 1e-9 if _nwnode == "Leh"
* the plot changes no network: firm is still the only network
nwset
assert r(networks) == 1
capture nwegoplot firm, ego(nobody)
assert _rc == 198
capture nwegoplot firm, ego(Gwen) hop(3)
assert _rc == 198
nwwebuse lazega, nwclear
nwegoplot lazega_adv, ego(n41) sortby(officenum) color(officenum)
assert r(alters) == 22
di "test_nwegoplot: all passed"
