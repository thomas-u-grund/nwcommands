{smcl}
{* *! version 2.0 Thomas Grund}{...}
{marker topic}
{helpb nw_topical##manipulation:[NW-2.5] Manipulation}

{title:Title}

{p2colset 9 18 22 2}{...}
{p2col :nwnoderename {hline 2} Rename a single node in a network}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwnoderename} 
[{it:{help netname}}]
{cmd:,}
{opt old}({it:old_nwnode})
{opt new}({it:new_nwnode})

{marker description}{...}
{title:Description}

{pstd}
{cmd:nwnoderename} changes the name of a single node in a network. When a
node with name {it:old_nwnode} is found in {it:netname}, it is replaced with
{it:new_nwnode}.


{marker examples}{...}
{title:Examples}

	{com}. nwclear
	{com}. nwrandom 4, prob(1) name(mynet)
	{com}. list _nwnode _nwinclude
	{txt}
		 {c TLC}{hline 9}{c -}{hline 10}{c TRC}
		 {c |} {res}_nwnode   _nwinc~e {txt}{c |}
		 {c LT}{hline 9}{c -}{hline 10}{c RT}
	      1. {c |} {res}     n1          1 {txt}{c |}
	      2. {c |} {res}     n2          1 {txt}{c |}
	      3. {c |} {res}     n3          1 {txt}{c |}
	      4. {c |} {res}     n4          1 {txt}{c |}
		 {c BLC}{hline 9}{c -}{hline 10}{c BRC}

	{com}. nwnoderename mynet, old(n1) new(x1)
	{com}. list _nwnode _nwinclude
	{txt}
		 {c TLC}{hline 9}{c -}{hline 10}{c TRC}
		 {c |} {res}_nwnode   _nwinc~e {txt}{c |}
		 {c LT}{hline 9}{c -}{hline 10}{c RT}
	      1. {c |} {res}     x1          1 {txt}{c |}
	      2. {c |} {res}     n2          1 {txt}{c |}
	      3. {c |} {res}     n3          1 {txt}{c |}
	      4. {c |} {res}     n4          1 {txt}{c |}
	      5. {c |} {res}     n1          0 {txt}{c |}
		 {c BLC}{hline 9}{c -}{hline 10}{c BRC}


{title:See also}

	{help nwrename}, {help nwname}

