* nwcommands tutorial 16: valued networks
* Requires the core nwcommands.
nwwebuse sampson, nwclear

* 1. A valued network: how many times was a pair named?
nwsymmetrize samplike, generate(likes)
nwsummarize likes

* 2. A network from an edge list with a value variable
clear
input str5 ego str5 alter int mails
"Ann" "Bob" 12
"Ann" "Cy"   1
"Bob" "Cy"   5
"Cy"  "Dee"  2
"Dee" "Ann"  7
end
nwfromedge ego alter mails, name(mailnet) directed
nwsummarize mailnet

* 3. Degree is strength for a valued network
nwwebuse sampson, nwclear
nwsymmetrize samplike, generate(likes)
nwdegree likes, generate(strength)
nwdegree likes, generate(ties) binary
summarize strength ties

* 4. Clustering, weighted and binary
nwclustering likes, generate(wclu) silent
nwclustering likes, generate(bclu) measure(binary) silent
summarize wclu bclu

nwbetween likes, generate(wbtw) silent
nwbetween likes, generate(bbtw) binary silent
correlate wbtw bbtw

* 5. Dichotomize with a cutoff
nwdichotomize likes, threshold(2) generate(likes2)
nwsummarize likes2
nwdegree likes2, generate(deg2)
