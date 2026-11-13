* nwregular: exact regular equivalence classes (3.20.1)
* checked by hand (office) and against a greatest-fixpoint computation in Python (lazega_fr: 71 classes)
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
nwregular firm, generate(rc) silent
assert r(classes) == 3
matrix I = r(image)
assert I[1,3] == 1 & I[3,2] == 1 & I[1,1] == 0 & I[2,2] == 0
assert rc[1] == rc[3] & rc[1] == rc[6] & rc[1] == rc[7]
assert rc[4] == rc[5] & rc[4] != rc[1] & rc[2] != rc[4]
* replace required
capture nwregular firm, generate(rc)
assert _rc == 110
nwregular firm, generate(rc) replace silent
* undirected: everyone with a tie is in one class, isolates in another
nwclear
clear
input str4 a str4 b
"x" "y"
"y" "z"
"z" "w"
end
nwset a b, edgelist undirected name(path)
nwaddnodes path, nodenames(v)
nwregular path, generate(u) silent
assert r(classes) == 2
nwwebuse lazega, nwclear
nwregular lazega_adv, generate(ra) silent
assert r(classes) == 1
nwregular lazega_fr, generate(rf) silent
assert r(classes) == 71
di "test_nwregular: all passed"
