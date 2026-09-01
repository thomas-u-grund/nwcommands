{smcl}
{* *! version 1.0.2  17apr2009}
{marker topic}
{helpb nw_topical##concept:[NW-2.1] Concepts}
{hline}

{title:Example networks}

{pstd}The datasets listed are in {help nwsave##fileformat:Stata network file-format} and hosted on this package's own GitHub repository.
{p_end}
{hline}

        {help netexample##gang:gang}{col 29}{stata "nwwebuse gang":use} | {stata "sysdescribe gang.dta":describe}
        {help netexample##glasgow:glasgow}{col 29}{stata "nwwebuse glasgow":use} | {stata "sysdescribe glasgow.dta":describe}
        {help netexample##florentine:florentine}{col 29}{stata "nwwebuse florentine":use} | {stata "sysdescribe florentine.dta":describe}
        {help netexample##usstates:usstates}{col 29}{stata "nwwebuse usstates":use} | {stata "sysdescribe usstates.nwdta":describe}
        {help netexample##klas12b:klas12b}{col 29}{stata "nwwebuse klas12b":use} | {stata "sysdescribe klas12b.nwdta":describe}
        {help netexample##hpotter:hpotter}{col 29}{stata "nwwebuse hpotter":use} | {stata "sysdescribe hpotter.nwdta":describe}
        {help netexample##macaque:macaque}{col 29}{stata "nwwebuse macaque":use} | {stata "sysdescribe macaque.nwdta":describe}
        {help netexample##chesapeake:chesapeake}{col 29}{stata "nwwebuse chesapeake":use} | {stata "sysdescribe chesapeake.nwdta":describe}
        {help netexample##usair:usair}{col 29}{stata "nwwebuse usair":use} | {stata "sysdescribe usair.nwdta":describe}
        {help netexample##lazega:lazega}{col 29}{stata "nwwebuse lazega":use} | {stata "sysdescribe lazega.nwdta":describe}
        {help netexample##s50:s50}{col 29}{stata "nwwebuse s50":use} | {stata "sysdescribe s50.nwdta":describe}
        {help netexample##sampson:sampson}{col 29}{stata "nwwebuse sampson":use} | {stata "sysdescribe sampson.nwdta":describe}
        {help netexample##mesa:mesa}{col 29}{stata "nwwebuse mesa":use} | {stata "sysdescribe mesa.nwdta":describe}
        {help netexample##zachary:zachary}{col 29}{stata "nwwebuse zachary":use} | {stata "sysdescribe zachary.nwdta":describe}
        {help netexample##kapferer:kapferer}{col 29}{stata "nwwebuse kapferer":use} | {stata "sysdescribe kapferer.nwdta":describe}

{hline}

{marker gang}
{title:Gang data}

{pstd}
{bf:Networks:} {it:gang}{p_end}
{pstd}
{bf:Vertex attributes:} {it:Age, Birthplace, Residence, Arrests, Convictions, Prison, Music}.

{pstd}
This is a dataset of co-offending in a London-based youth gang. Data were collected by 
James Densley and Thomas Grund. The data has been used in Grund & Densley (2012) and Grund & Densley (2014). 

{pmore}
Network tie values:

		= 1 (hang out together)
		= 2 (co-offend together)
		= 3 (co-offend together, serious crime)
		= 4 (co-offend together, serious crime, kin)
		
{pmore}
{bf:References}

{pmore}
Grund, T. and Densley, J. (2014) Ethnic Homophily and Triad Closure: Mapping Internal Gang Structure Using Exponential Random Graph Models. Journal of Contemporary Criminal Justice. online first

{pmore}
Grund, T. and Densley, J. (2012) Ethnic Heterogeneity in the Activity and Structure of a Black Street Gang. European Journal of Criminology, Vol. 9, Issue 3, pp. 388-406.


{marker glasgow}
{title:Glasgow data}

{pstd}
{bf:Networks:} {it:glasgow1, glasgow2, glasgow3}{p_end}
{pstd}
{bf:Vertex attributes:} {it:smoke1, smoke2, smoke2, alcohol1, alcohol2, alcohol3, sport1, sport2, sport3}

{pstd}
This is an excerpt of 50 girls from the Teenage Friends and Lifestyle Study data set. The social network data were
collected in the Teenage Friends and Lifestyle Study (Michell and Amos 1997, 
Pearson and Michell 2000, Pearson and West 2003). Friendship network data and substance use were recorded for a cohort of pupils in
a school in the West of Scotland. The panel data were recorded over a three year period starting in 1995, when the pupils were
aged 13, and ending in 1997. A total of 160 pupils took part in the study, 129 of whom were present at all three measurement
points. The friendship networks were formed by allowing the pupils to name up to twelve best friends. Pupils were also asked
about substance use and adolescent behavior associated with, for instance, lifestyle, sporting behavior and tobacco, alcohol
and cannabis consumption. The question on sporting activity asked if the pupil regularly took part in any sport, or go training
for sport, out of school (e.g. football, gymnastics, skating, mountain biking). The school was representative of others in the
region in terms of social class composition (Pearson and West 2003).

{pmore}
The variables included are:

{pmore}
{it:smoke1, smoke2, smoke3}: Smoking behavior at waves 1, 2 and 3.{p_end}

		= 1 (non)
		= 2 (occasional)
		= 3 (regular, i.e. more than once per week).
	
{pmore}
{it:alcohol1, alcohol2, alcohol3}: Drinking behavior at waves 1, 2 and 3.{p_end}

		= 1 (non)
		= 2 (once or twice a year)
		= 3 (once a month)
		= 4 (once a week) 
		= 5 (more than once a week).

{pmore}
{it:sport1, sport2, sport3}: Sport behavior at waves 1, 2 and 3.{p_end}

		= 1 (not regular)
		= 2 (regular).

{pmore}
{bf:References}

{pmore}
Michell, L., and A. Amos 1997. Girls, pecking order and smoking. Social Science and Medicine, 44, 1861 - 1869.

{pmore}
Pearson, M.A., and L. Michell. 2000. Smoke Rings: Social network analysis of friendship groups, smoking and drug-taking. Drugs: education, prevention and policy, 7, 21-37.

{pmore}
Pearson, M., and P. West. 2003. Drifting Smoke Rings: Social Network Analysis and Markov Processes in a Longitudinal Study of Friendship Groups and Risk-Taking. Connections, 25(2), 59-76.

{pmore}
Pearson, Michael, Steglich, Christian, and Snijders, Tom. Homophily and assimilation among sport-active adolescent substance users. Connections 27(1), 47-63. 2006.



{marker florentine}
{title:Florentine data}

{pstd}
{bf:Networks:} {it:flomarriage} and {it:flobusiness}{p_end}
{pstd}
{bf:Vertex attributes:} {it:wealth} and {it:priorates}

{pstd}
This is a dataset of marriage and business ties among Renaissance Florentine families. The data is originally from Padgett
(1994). Breiger & Pattison (1986), in their discussion of local role analysis, use a subset of data on the social
relations among Renaissance Florentine families (person aggregates) collected by John Padgett from historical documents. The
relations are marriage alliances (flomarriage between the families) and business relationships (recorded financial ties such
as loans, credits and joint partnerships).

{pstd}
As Breiger & Pattison point out, the original data are symmetrically coded. This is perhaps acceptable perhaps for marital
ties. Vertex information is provided on (1) {it:wealth} each family's net wealth in 1427 (in thousands of lira); (2) 
the number of {it:priorates} (seats on the civic council) held between 1282- 1344.

{pstd}
Substantively, the data include families who were locked in a struggle for political control of the city of Florence around
1430. Two factions were dominant in this struggle: one revolved around the infamous Medicis (9), the other around the powerful Strozzis (15).

{pmore}
{bf:References}

{pmore}
Padgett, John F. 1994. Marriage and Elite Structure in Renaissance Florence, 1282-1500. Paper delivered to the Social Science History Association.

{pmore}
Breiger R. and Pattison P. (1986). Cumulated social roles: The duality of persons and their algebras, Social Networks, 8, 215-256.




{marker usstates}
{title:US states data}

{pstd}
{bf:Networks:} {it:usstates} (undirected){p_end}
{pstd}
{bf:Vertex attributes:} none - vertex labels are the two-letter state abbreviations.

{pstd}
A tie between two US states means they share a land border. 50 states, 107 border ties.



{marker klas12b}
{title:Klas12b data}

{pstd}
{bf:Networks:} {it:klas12b_wave1, klas12b_wave2, klas12b_wave3, klas12b_wave4, klas12b_primary} (directed){p_end}
{pstd}
{bf:Vertex attributes:}
{it:delinq1, delinq3, delinq3, delinq4, alcohol2, alcohol3, alcohol4, sex age, ethnicity, age, religion, advice}

{pstd}
As loaded via {opt nwwebuse}, each network's own tie indicator is binary (1 = nomination,
0 = otherwise) - the raw source coding's own {bf:9} (missing) and {bf:10} (not a member of the
classroom at that wave, a structural zero) both collapse to "no tie" rather than surviving as a
separate valued/missing distinction, so a "0" in the loaded network does not distinguish an
explicit non-nomination from a genuinely unobserved or structurally absent dyad.

{pstd}
This data is about a friendship network in a Dutch school class. The data were collected between September 2003 and June 2004 by Andrea 
Knecht, supervised by Chris Baerveldt, at the Department of Sociology of the University of Utrecht (NL). The entire study is reported in
Knecht (2008). The project was funded by the Netherlands Organisation for Scientific Research NWO, grant 401-01-554.

{pstd}
The 26 students were followed over their first year at secondary school during which friendship networks as well as other data were assessed 
at four time points at intervals of three months. There were 17 girls and 9 boys in the class, aged 11-13 at the beginning of the school
year. Network data were assessed by asking students to indicate up to twelve classmates which they considered good friends.

{pstd}
Delinquency is defined as a rounded average over four types of minor delinquency (stealing, vandalism, graffiti, and fighting), measured in
each of the four waves of data collection. The five-point scale ranged from `never' to `more than 10 times', and the distribution is highly
skewed. In a range of 1-5, the mode was 1 at all four waves, the average rose over time from 1.4 to 2.0, and the value 5 was never observed.

{pstd}
Friendship networks at four waves {it:klas12b_wave1-4}:	

	0 = no,
	1 = yes,
	9 = missing,
	10 = not a member of the classroom (structural zero).
	

{pstd}
Same primary school ({it:klas12b_primary}): 
	
	0 = no, 
	1 = yes.
	
{pstd}
{it:delinq1, delinq3, delinq3, delinq4}: Delinquency at waves 1, 2, 3 and 4; rounded average of four items (stealing, vandalizing, fighting, graffiti).{p_end}

	1 = never, 
	2 = once, 
	3 = 2-4 times, 
	4 = 5-10 times, 
	5 = more than 10 times;
	0 = missing.
	
{pstd}
{it:alcohol2, alcohol3, alcohol4}: Alcohol use ("How often did you drink alcohol with friends in the last three months?"), but it refers only to waves 2-3-4. 

	1 = never, 
	2 = once, 
	3 = 2-4 times, 
	4 = 5-10 times, 
	5 = more than 10 times;
	0 = missing.

{pstd}
{it:sex (1 = girl, 2 = boy)}

{pstd}
{it:age (in years)}

{pstd}
{it:ethnicity}
	
	1 = Dutch, 
	2 = other, 
	0 = missing

{pstd}	
{it:religion}

	1 = Christian, 
	2 = non-religious, 
	3 = non-Christian religion, 
	0 = missing
	
{pstd}
{it:advice} contains the variable "school advice", the assessment given at the end of primary school about the school capacities of the pupil

	4 = low, 
	8 = high, 
	0 = missing


{pmore}
{bf:Reference}

{pmore}
Knecht, A., 2008. Friendship Selection and Friends' Influence. Dynamics of Networks and Actor Attributes in Early Adolescence. PhD dissertation, University of Utrecht.

{pmore}
Andrea Knecht, Tom A. B. Snijders, Chris Baerveldt, Christian E. G. Steglich, and Werner Raub. Friendship and Delinquency: Selection and Influence Processes in Early Adolescence, Social Development.
http://dx.doi.org/10.1111/j.1467-9507.2009.00564.x.

{pmore}
Snijders, T.A.B., Steglich, C.E.G., and van de Bunt, G.G. (2010). Introduction to actor-based models for network dynamics. Social Networks, 32, 44-60.
http://dx.doi.org/10.1016/j.socnet.2009.02.004.

{pmore}
Steglich, Christian, and Knecht, Andrea (2009), Die statistische Analyse dynamischer Netzwerkdaten. In: Christian Stegbauer and Roger Häußling (Eds.), Handbuch der Netzwerkforschung, Wiesbaden (Verlag für Sozialwissenschaften).





{marker hpotter}
{title:Harry Potter data}

{pstd}
{bf:Networks:} {it:hpbook1, hpbook2, hpbook3, hpbook4, hpbook5, hpbook6} (directed){p_end}
{pstd}
{bf:Vertex attributes:}
{it:schoolyear, gender, and house}

{pstd}
Goele Bossaert and Nadine Meidert have coded the support ties between 64 characters in the well-known books about Harry Potter. They analyzed this by Siena; their findings were published in

{pmore}
{bf:Reference}

{pmore}
Goele Bossaert and Nadine Meidert (2013). 'We are only as strong as we are united, as weak as we are divided'. A dynamic analysis of the peer support networks in the Harry Potter books. Open Journal of Applied Sciences, Vol. 3 No. 2, pp. 174-185.
http://dx.doi.org/10.4236/ojapps.2013.32024



{marker macaque}
{title:Macaque cortical network data}

{pstd}
{bf:Networks:} {it:macaque}{p_end}
{pstd}
{bf:Vertex attributes:} none - vertex names are the cortical area labels themselves (V1, V2, MT, FEF, and so on).

{pstd}
This is a directed network of 45 visuotactile areas of the macaque cerebral cortex, with a tie from
area {it:i} to area {it:j} whenever a projection from {it:i} to {it:j} is documented in the neuroanatomical
literature. Not a social network: included as a worked example of a real, published, non-social
directed network of comparable size to this package's other bundled examples.

{pmore}
{bf:Reference}

{pmore}
Negyessy, L., Nepusz, T., Kocsis, L., and Bazso, F. (2006). Prediction of the main cortical areas and connections involved in the tactile function of the visual cortex by network analysis. European Journal of Neuroscience, 23(7), 1919-1930.



{marker chesapeake}
{title:Chesapeake Bay food web data}

{pstd}
{bf:Networks:} {it:chesapeake} (directed, valued - tie value is carbon flux){p_end}
{pstd}
{bf:Vertex attributes:} {it:ECO} and {it:Biomass}{p_end}

{pstd}
This is a food web of the Chesapeake Bay mesohaline ecosystem: 39 compartments (mostly species,
plus a handful of bookkeeping compartments - Input, Output, Respiration, and two organic-carbon
pools), with a directed, valued tie from compartment {it:i} to compartment {it:j} whenever carbon
flows from {it:i} to {it:j}. {it:ECO} codes the compartment type (1 = living organism, 2 = nonliving
organic pool, 3 = Input, 4 = Output, 5 = Respiration); {it:Biomass} is each compartment's standing
biomass. A handful of species names are truncated at 25 characters in the original source data
(e.g. "heterotrophic microflagel"), inherited as-is from that source rather than silently
guessed at. Not a social network: included as a worked example of a real, published food web of
comparable size to this package's other bundled examples.

{pmore}
{bf:Reference}

{pmore}
Baird, D. and Ulanowicz, R.E. (1989). The seasonal dynamics of the Chesapeake Bay ecosystem. Ecological Monographs, 59, 329-364.



{marker usair}
{title:US airports data}

{pstd}
{bf:Networks:} {it:usair}{p_end}
{pstd}
{bf:Vertex attributes:} {it:Name, City, Lat, Lon, degree}{p_end}

{pstd}
This is a directed network of the 50 busiest US airports (by direct-route degree) and the direct
routes between them, built from OpenFlights' airport and route databases. A tie from airport
{it:i} to airport {it:j} means at least one airline flew a direct, no-stop route from {it:i} to
{it:j} at the time OpenFlights' route data was current. Restricted to the top 50 airports by
degree, not the full set of several hundred US airports OpenFlights covers, to keep this network
at a size comparable to this package's other example networks - {it:degree} itself records each
airport's own direct-route degree in the {it:full}, unrestricted US network, not just within this
50-airport subset, so it will not generally match {help nwdegree:nwdegree}'s own count computed
on {it:usair} as loaded. Not a social network: included as a worked example of a real,
non-social, directed transportation network.

{pmore}
{bf:Reference}

{pmore}
OpenFlights.org Airport and Route Databases, https://openflights.org/data.php. Distributed under the Open Database License.



{marker lazega}
{title:Lazega lawyers data}

{pstd}
{bf:Networks:} {it:lazega_adv, lazega_cow, lazega_fr} (directed - advice, co-work, and friendship
ties among the same 71 lawyers){p_end}
{pstd}
{bf:Vertex attributes:} {it:age, gender, office, practice, school, seniority, status, yrs_frm}

{pstd}
This is Emmanuel Lazega's corporate law partnership network: three ties among 71 lawyers at a
Northeastern US corporate law firm - {it:lazega_adv} ("Who do you go to for professional advice?"),
{it:lazega_cow} ("Who do you work with?"), and {it:lazega_fr} ("Who is a personal friend?"). One of
the standard multiplex/multi-relational ERGM and SAOM teaching networks, widely used to illustrate
same-office/same-practice/same-status homophily. {it:status} is {it:partner} or {it:associate};
{it:practice} is {it:litigation} or {it:corporate}; {it:office} is the lawyer's own Boston/Hartford/
Providence location; {it:school} is {it:Harvard/Yale}, {it:UConnecticut}, or {it:other};
{it:seniority} is each lawyer's own rank by years since joining the firm; {it:yrs_frm} is years
with the firm. Node labels are plain sequential ids (1-71) - the original data anonymizes the
lawyers themselves.

{pmore}
{bf:Reference}

{pmore}
Lazega, E. (2001). The Collegial Phenomenon: The Social Mechanisms of Cooperation Among Peers in
a Corporate Law Partnership. Oxford University Press.

{pmore}
Lazega, E. and van Duijn, M. (1997). Position in formal structure, personal characteristics and
choices of advisors in a law firm: A logistic regression model for dyadic network data. Social
Networks, 19, 375-397.

{pmore}
Distributed with R's own {cmd:ergm.multi} package as {cmd:data(Lazega)} (part of the Statnet
Project).



{marker s50}
{title:s50 data}

{pstd}
{bf:Networks:} {it:s50_w1, s50_w2, s50_w3} (directed - friendship nominations among the same 50
university students at three time points){p_end}
{pstd}
{bf:Vertex attributes:} {it:alcohol1, alcohol2, alcohol3, smoke1, smoke2, smoke3}

{pstd}
This is Van de Bunt's university-freshmen friendship panel (a subset of 50 students from a larger
study), collected at three points during their first year - the single most commonly used
teaching dataset for Stochastic Actor-Oriented Models (SAOM, {help nwsaom}), distributed as the
"s50" example data with the RSiena software this package's own SAOM implementation was
cross-validated against. {it:alcohol1-3} (1 = never to 5 = more than once a week) and
{it:smoke1-3} (1 = non-smoker to 3 = regular smoker) are each student's own self-reported behavior
at the matching wave. Node labels are plain sequential ids (1-50).

{pmore}
{bf:Reference}

{pmore}
Van de Bunt, G.G., Van Duijn, M.A.J., and Snijders, T.A.B. (1999). Friendship networks through
time: An actor-oriented dynamic statistical network model. Computational and Mathematical
Organization Theory, 5, 167-192.

{pmore}
Distributed with the RSiena software/package (part of the Siena/RSiena project,
https://www.stats.ox.ac.uk/~snijders/siena/).



{marker sampson}
{title:Sampson monastery data}

{pstd}
{bf:Networks:} {it:samplk1, samplk2, samplk3} (directed, valued - positive-affect ranking among
the same 18 monks at three time points), {it:samplike} (directed, valued - the same monks' own
final-wave "liking" ranking, the relation most commonly used on its own in ERGM teaching){p_end}
{pstd}
{bf:Vertex attributes:} {it:faction, cloisterville}

{pstd}
This is Samuel Sampson's classic monastery study: 18 novice monks at a New England monastery,
each asked to rank their top three (later four) choices on several relations across the training
period leading up to a political crisis that split the monastery into factions. Every tie value is
1/2/3, ranking that choice's own strength (1 = highest). {it:faction} is each monk's own
eventually-revealed group - {it:Loyal} (supported the group in power), {it:Turks} (the opposition),
or {it:Outcasts} (aligned with neither) - the single most commonly cited example of using ERGM/SNA
methods to recover real-world faction structure from network data alone. {it:cloisterville}
flags the handful of monks who transferred in from a minor seminary already called "Cloisterville"
rather than entering directly. Node labels are the monks' own (pseudonymous, as originally
published) first names.

{pmore}
{bf:Reference}

{pmore}
Sampson, S.F. (1969). Crisis in a Cloister. Unpublished doctoral dissertation, Cornell University.

{pmore}
Distributed with R's own {cmd:ergm} package as {cmd:data(samplk)}/{cmd:data(sampson)} (part of the
Statnet Project).



{marker mesa}
{title:Mesa High data}

{pstd}
{bf:Networks:} {it:mesa} (undirected){p_end}
{pstd}
{bf:Vertex attributes:} {it:grade, race, sex}

{pstd}
This is "Faux Mesa High" - a simulated but realistic 205-student high-school friendship network
built to reproduce the same size, grade/race/sex composition, and homophily/degree structure as a
real school network from the National Longitudinal Study of Adolescent Health (Add Health), without
disclosing the real (restricted-access) data itself. The single most widely used worked example in
R {cmd:ergm}'s own documentation and teaching materials for {opt nodematch()}/{opt nodemix()}/
{opt gwesp()}-style homophily and triad-closure effects. {it:grade} is US school grade (7-12);
{it:race} is {it:White}, {it:Black}, {it:Hisp} (Hispanic), {it:NatAm} (Native American), or
{it:Other}; {it:sex} is {it:F}/{it:M}. 57 of the 205 students report no friendship ties at all
(isolates) - kept in the loaded network exactly as in the original data, not silently dropped.

{pmore}
{bf:Reference}

{pmore}
Resnick, M.D. et al. (1997). Protecting adolescents from harm: Findings from the National
Longitudinal Study on Adolescent Health. Journal of the American Medical Association, 278,
823-832.

{pmore}
Hunter, D.R., Handcock, M.S., Butts, C.T., Goodreau, S.M., and Morris, M. (2008). ergm: A Package
to Fit, Simulate and Diagnose Exponential-Family Models for Networks. Journal of Statistical
Software, 24(3).

{pmore}
Distributed with R's own {cmd:ergm} package as {cmd:data(faux.mesa.high)} (part of the Statnet
Project).



{marker zachary}
{title:Zachary karate club data}

{pstd}
{bf:Networks:} {it:zachary_bin} (undirected, binary), {it:zachary_val} (undirected, valued - the
same ties, weighted by the number of contexts the two members interacted in outside the club){p_end}
{pstd}
{bf:Vertex attributes:} {it:group}

{pstd}
Wayne Zachary's 1970s study of a university karate club: 34 members, a tie whenever two members
were observed interacting outside the club's own scheduled activities. Partway through the study a
dispute between the club's president and instructor split the club into two factions - {it:group}
(1/2) records which side each member ultimately joined, making this the single most widely used
worked example for community-detection/faction-recovery methods in network analysis. Node labels
are {it:Mr Hi} (the instructor), {it:Actor 2}-{it:Actor 34} (the officer/president is node 34).

{pmore}
{bf:Reference}

{pmore}
Zachary, W.W. (1977). An information flow model for conflict and fission in small groups. Journal
of Anthropological Research, 33, 452-473.

{pmore}
Distributed with R's own {cmd:igraphdata} package as {cmd:data(karate)}.



{marker kapferer}
{title:Kapferer tailor shop data}

{pstd}
{bf:Networks:} {it:kapferer_t1} (39 nodes), {it:kapferer_t2} (43 nodes) - both undirected{p_end}
{pstd}
{bf:Vertex attributes:} none

{pstd}
Bruce Kapferer's 1972 study of sociation among workers at a Zambian tailor shop, observed at two
time points around a labor dispute (an unsuccessful attempt to unionize) - {it:kapferer_t1} is the
"before" network, {it:kapferer_t2} the "after" one. The two networks do NOT share a common node
set (workers left and joined the shop between observations, a real and deliberate feature of the
original study, not a data-quality issue) - they are two independent networks, not a two-wave panel
on the same actors the way {help netexample##s50:s50}/{help netexample##klas12b:klas12b} are.

{pmore}
{bf:Reference}

{pmore}
Kapferer, B. (1972). Strategy and Transaction in an African Factory. Manchester University Press.

{pmore}
Distributed with R's own {cmd:ergm} package as {cmd:data(kapferer)} (part of the Statnet Project).
