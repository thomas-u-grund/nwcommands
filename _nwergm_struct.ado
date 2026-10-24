*! _nwergm_struct: parse and register the structural ergm terms given in nwergm's structural() option
capture program drop _nwergm_struct
program _nwergm_struct, rclass
	version 14
	syntax anything(name=netname) , TERMS(string asis) NODES(integer) DIRECTED(string) [ TYPE(string) ]
	local dir = ("`directed'" == "true")
	if "`type'" == "" local type "OTP"
	local rest = trim(`"`terms'"')
	local temps ""
	local allcn ""
	local dep 0
	local nterm 0
	while `"`rest'"' != "" {
		gettoken tname rest : rest, parse(" (")
		local rest = trim(`"`rest'"')
		local args ""
		if substr(`"`rest'"', 1, 1) == "(" {
			local pos = strpos(`"`rest'"', ")")
			if `pos' == 0 {
				di "{err}structural(): unbalanced parenthesis after {bf:`tname'}"
				error 198
			}
			local args = substr(`"`rest'"', 2, `pos' - 2)
			local rest = trim(substr(`"`rest'"', `pos' + 1, .))
		}
		local ++nterm
		_nwergm_struct_args `tname' , args(`args')
		local ATTR "`r(attr)'"
		local DIFF = r(diff)
		local BYV "`r(by)'"
		local SAMEV "`r(same)'"
		local DV "`r(d)'"
		local KV "`r(k)'"
		local LAM "`r(lambda)'"
		local FIXED = r(fixed)
		local SEMI = r(semi)
		local LEVS "`r(levels)'"
		local XV "`r(x)'"
		local TYPEV "`r(type)'"
		local FROMV "`r(from)'"
		local TOV "`r(to)'"
		local HOMO = r(homophily)
		local POSV "`r(pos)'"
		local KEEP "`r(keep)'"
		if inlist("`tname'", "triangle", "tripercent", "ttriple", "ctriple", "asymmetric") & "`ATTR'" == "" {
			local ATTR "`POSV'"
			local POSV ""
		}
		if inlist("`tname'", "concurrent", "concurrentties") & "`BYV'" == "" {
			local BYV "`POSV'"
			local POSV ""
		}
		if "`tname'" == "mutual" & "`SAMEV'`BYV'" == "" {
			local SAMEV "`POSV'"
			local POSV ""
		}
		if "`tname'" == "cycle" & "`KV'" == "" {
			local KV "`POSV'"
		}
		if "`tname'" == "nsp" & "`DV'" == "" {
			local DV "`POSV'"
		}
		if "`tname'" == "altkstar" & "`LAM'" == "" {
			local LAM "`POSV'"
		}
		if "`tname'" == "triadcensus" & "`LEVS'" == "" & "`DV'" == "" {
			local LEVS "`POSV'"
		}
		// slots: code,p1,p2,empty,hasattr,hascov ; separated by ;
		local slots ""
		local cn ""
		local attrvar ""
		local attrmode 0
		local covnet ""
		local key "`tname'"
		local isdep 1
		local useattr 0
		local plain 0
		local special ""
		// ---- dispatch ----
		if "`tname'" == "density" {
			_nwergm_struct_noargs `tname', pos(`POSV') attr(`ATTR')
			local slots "1001,0,0,0,0,0"
			local cn "density"
			local isdep 0
		}
		else if "`tname'" == "meandeg" {
			_nwergm_struct_noargs `tname', pos(`POSV') attr(`ATTR')
			local slots "1002,0,0,0,0,0"
			local cn "meandeg"
			local isdep 0
		}
		else if "`tname'" == "twopath" {
			_nwergm_struct_noargs `tname', pos(`POSV') attr(`ATTR')
			if `dir' local slots "1003,0,0,0,0,0"
			else local slots "21,2,0,0,0,0"
			local cn "twopath"
		}
		else if "`tname'" == "m2star" {
			_nwergm_struct_need dir `dir' `tname' `netname'
			_nwergm_struct_noargs `tname', pos(`POSV') attr(`ATTR')
			local slots "1003,0,0,0,0,0"
			local cn "m2star"
		}
		else if "`tname'" == "isolates" {
			_nwergm_struct_noargs `tname', pos(`POSV') attr(`ATTR')
			local slots "1004,0,0,`nodes',0,0"
			local cn "isolates"
		}
		else if "`tname'" == "isolatededges" {
			_nwergm_struct_need und `dir' `tname' `netname'
			_nwergm_struct_noargs `tname', pos(`POSV') attr(`ATTR')
			local slots "1005,0,0,0,0,0"
			local cn "isolatededges"
		}
		else if "`tname'" == "degree1.5" {
			_nwergm_struct_need und `dir' `tname' `netname'
			_nwergm_struct_noargs `tname', pos(`POSV') attr(`ATTR')
			local slots "1006,0,0,0,0,0"
			local cn "degree1.5"
		}
		else if "`tname'" == "odegree1.5" {
			_nwergm_struct_need dir `dir' `tname' `netname'
			_nwergm_struct_noargs `tname', pos(`POSV') attr(`ATTR')
			local slots "1007,0,0,0,0,0"
			local cn "odegree1.5"
		}
		else if "`tname'" == "idegree1.5" {
			_nwergm_struct_need dir `dir' `tname' `netname'
			_nwergm_struct_noargs `tname', pos(`POSV') attr(`ATTR')
			local slots "1008,0,0,0,0,0"
			local cn "idegree1.5"
		}
		else if "`tname'" == "degcrossprod" {
			_nwergm_struct_need und `dir' `tname' `netname'
			_nwergm_struct_noargs `tname', pos(`POSV') attr(`ATTR')
			local __ns_ne2 ""
			capture mata: st_local("__ns_ne2", strofreal(2 * __nwergm_last_G.nties))
			if "`__ns_ne2'" == "" {
				di "{err}degcrossprod needs an observed network (it is scaled by the observed number of ties); it is not available in nwergm simulate."
				error 198
			}
			local slots "1009,`__ns_ne2',0,0,0,0"
			local cn "degcrossprod"
		}
		else if "`tname'" == "degcor" {
			_nwergm_struct_need und `dir' `tname' `netname'
			_nwergm_struct_noargs `tname', pos(`POSV') attr(`ATTR')
			local __ns_sig ""
			capture mata: st_local("__ns_sig", strofreal(ns_degcor_sigma2(__nwergm_last_G), "%25.17g"))
			if "`__ns_sig'" == "" {
				di "{err}degcor needs an observed network (its change statistic is standardised by the observed degree variance); it is not available in nwergm simulate."
				error 198
			}
			local slots "1010,`__ns_sig',0,0,0,0"
			local cn "degcor"
			local special "degcor"
		}
		else if "`tname'" == "concurrentties" | "`tname'" == "concurrent" {
			_nwergm_struct_need und `dir' `tname' `netname'
			local attrvar "`BYV'"
			if "`attrvar'" == "" {
				if "`tname'" == "concurrent" local slots "20,0,0,0,0,0"
				else local slots "1011,0,0,0,0,0"
				local cn "`tname'"
			}
			else {
				local attrmode 3
				local useattr 1
			}
		}
		else if "`tname'" == "altkstar" {
			_nwergm_struct_need und `dir' `tname' `netname'
			if `FIXED' {
				if "`LAM'" == "" {
					di "{err}Term {bf:altkstar} with {bf:fixed} requires a decay parameter {bf:lambda}."
					error 198
				}
				local slots "1012,`LAM',0,0,0,0"
				local cn "altkstar.`LAM'"
			}
			else {
				di "{err}altkstar without {bf:fixed} (the curved form) is not available yet; use altkstar(lambda=# fixed)."
				error 198
			}
		}
		else if "`tname'" == "asymmetric" {
			_nwergm_struct_need dir `dir' `tname' `netname'
			local attrvar "`ATTR'"
			local attrmode 1
			if "`attrvar'" == "" {
				local slots "1013,0,0,0,0,0"
				local cn "asymmetric"
			}
			else local useattr 1
		}
		else if "`tname'" == "mutual" {
			_nwergm_struct_need dir `dir' `tname' `netname'
			if "`SAMEV'" != "" {
				local attrvar "`SAMEV'"
				local attrmode 1
				local useattr 1
			}
			else if "`BYV'" != "" {
				local attrvar "`BYV'"
				local attrmode 1
				local useattr 1
			}
			else {
				local slots "1028,0,0,0,0,0"
				local cn "mutual"
			}
		}
		else if "`tname'" == "transitive" | "`tname'" == "intransitive" {
			_nwergm_struct_need dir `dir' `tname' `netname'
			_nwergm_struct_noargs `tname', pos(`POSV') attr(`ATTR')
			local slots = cond("`tname'" == "transitive", "1014,0,0,0,0,0", "1015,0,0,0,0,0")
			local cn "`tname'"
		}
		else if "`tname'" == "cycle" {
			if "`KV'" == "" {
				di "{err}Term {bf:cycle} requires the argument {bf:k}."
				error 198
			}
			local ksel ""
			foreach kk of numlist `KV' {
				if `kk' > `nodes' {
					di "{txt}cycles of length greater than the network size cannot exist and their statistics will be omitted"
					continue
				}
				if !`dir' & `kk' < 3 {
					di "{txt}cycles of length less than 3 cannot exist in an undirected network and their statistics will be omitted"
					continue
				}
				if `kk' < 2 {
					di "{txt}cycles of length less than 2 cannot exist and their statistics will be omitted"
					continue
				}
				if `dir' & `SEMI' & `kk' == 2 {
					di "{txt}semicycles of length 2 are not currently supported and their statistics will be omitted"
					continue
				}
				if `kk' > 100 {
					di "{err}cycle(): k larger than 100 is not supported."
					error 198
				}
				local ksel "`ksel' `kk'"
			}
			if "`ksel'" == "" {
				continue
			}
			local semi = (`dir' & `SEMI')
			local bn = cond(`semi', "semicycle", "cycle")
			foreach kk of local ksel {
				local slots "`slots'1016,`kk',`semi',0,0,0;"
				local cn "`cn' `bn'`kk'"
			}
		}
		else if inlist("`tname'", "ttriple", "ctriple") {
			_nwergm_struct_need dir `dir' `tname' `netname'
			local attrvar "`ATTR'"
			local attrmode 2
			if "`attrvar'" == "" {
				local slots = cond("`tname'" == "ttriple", "1017,0,0,0,0,0", "1018,0,0,0,0,0")
				local cn "`tname'"
			}
			else local useattr 1
		}
		else if "`tname'" == "triangle" {
			local attrvar "`ATTR'"
			local attrmode 0
			if "`attrvar'" == "" {
				local slots "1019,0,0,0,0,0"
				local cn "triangle"
			}
			else local useattr 1
		}
		else if "`tname'" == "tripercent" {
			_nwergm_struct_need und `dir' `tname' `netname'
			local attrvar "`ATTR'"
			local attrmode 2
			if "`attrvar'" == "" {
				local slots "1020,0,0,0,0,0"
				local cn "tripercent"
			}
			else local useattr 1
		}
		else if "`tname'" == "opentriad" {
			_nwergm_struct_need und `dir' `tname' `netname'
			_nwergm_struct_noargs `tname', pos(`POSV') attr(`ATTR')
			local slots "1021,0,0,0,0,0"
			local cn "opentriad"
		}
		else if "`tname'" == "threetrail" | "`tname'" == "threepath" {
			if !`dir' {
				local slots "1022,0,0,0,0,0"
				local cn "threetrail"
			}
			else {
				local vals "RRR RRL LRR LRL"
				local sel ""
				if "`LEVS'" != "" local sel "`LEVS'"
				else if "`KEEP'" != "" {
					foreach kk of numlist `KEEP' {
						local sel "`sel' `: word `kk' of `vals''"
					}
				}
				else local sel "`vals'"
				foreach tv of local sel {
					local idx 0
					forvalues q = 1/4 {
						if "`: word `q' of `vals''" == "`tv'" local idx `q'
					}
					if `idx' == 0 {
						di "{err}threetrail(): unknown type {bf:`tv'}; use RRR, RRL, LRR, LRL."
						error 198
					}
					local slots "`slots'1022,`idx',0,0,0,0;"
					local cn "`cn' threetrail_`tv'"
				}
			}
		}
		else if inlist("`tname'", "nearsimmelian", "simmelian", "simmelianties") {
			_nwergm_struct_need dir `dir' `tname' `netname'
			_nwergm_struct_noargs `tname', pos(`POSV') attr(`ATTR')
			local code = cond("`tname'" == "nearsimmelian", 1023, cond("`tname'" == "simmelian", 1024, 1025))
			local slots "`code',0,0,0,0,0"
			local cn "`tname'"
		}
		else if "`tname'" == "localtriangle" {
			local covnet "`XV'"
			if "`covnet'" == "" local covnet "`POSV'"
			if "`covnet'" == "" {
				di "{err}Term {bf:localtriangle} requires the argument {bf:x} (a network name)."
				error 198
			}
			local slots "1026,0,0,0,0,1"
			local cn "localtriangle_`covnet'"
		}
		else if "`tname'" == "triadcensus" {
			if `dir' {
				local tcn "003 012 102 021D 021U 021C 111D 111U 030T 030C 201 120D 120U 120C 210 300"
			}
			else local tcn "0 1 2 3"
			local ntc : word count `tcn'
			local sel ""
			if "`LEVS'`DV'" == "" {
				forvalues q = 2/`ntc' {
					local sel "`sel' `: word `q' of `tcn''"
				}
			}
			else {
				foreach lv in `LEVS' `DV' {
					capture confirm number `lv'
					if !_rc & `dir' == 0 {
						local sel "`sel' `lv'"
					}
					else if !_rc & "`LEVS'" == "" {
						local sel "`sel' `: word `=`lv'+1' of `tcn''"
					}
					else local sel "`sel' `lv'"
				}
			}
			foreach lv of local sel {
				local idx 0
				forvalues q = 1/`ntc' {
					if "`: word `q' of `tcn''" == "`lv'" local idx `q'
				}
				if `idx' == 0 {
					di "{err}triadcensus(): unknown triad type {bf:`lv'}."
					error 198
				}
				local emp = cond(`idx' == 1, `nodes' * (`nodes' - 1) * (`nodes' - 2) / 6, 0)
				local slots "`slots'1027,`idx',0,`emp',0,0;"
				local cn "`cn' triadcensus_`lv'"
			}
		}
		else if inlist("`tname'", "degree", "odegree", "idegree", "degrange", "odegrange", "idegrange") {
			local pfx = cond(substr("`tname'", 1, 1) == "o", "o", cond(substr("`tname'", 1, 1) == "i", "i", ""))
			local isrange = (substr("`tname'", -5, .) == "range")
			if "`pfx'" == "" {
				_nwergm_struct_need und `dir' `tname' `netname'
			}
			else {
				_nwergm_struct_need dir `dir' `tname' `netname'
			}
			if `isrange' {
				if "`FROMV'" == "" {
					local FROMV : word 1 of `POSV'
					if "`TOV'" == "" local TOV : word 2 of `POSV'
				}
				if "`FROMV'" == "" {
					di "{err}Term {bf:`tname'} requires the argument {bf:from}."
					error 198
				}
				if "`TOV'" == "" local TOV "Inf"
				local nf : word count `FROMV'
				local nt : word count `TOV'
				if `nt' == 1 & `nf' > 1 {
					local t1 `TOV'
					local TOV ""
					forvalues q = 1/`nf' {
						local TOV "`TOV' `t1'"
					}
				}
				else if `nf' == 1 & `nt' > 1 {
					local f1 `FROMV'
					local FROMV ""
					forvalues q = 1/`nt' {
						local FROMV "`FROMV' `f1'"
					}
				}
				else if `nf' != `nt' {
					di "{err}The arguments of term {bf:`tname'} must have either the same length, or one of them must have length 1."
					error 198
				}
				local nf : word count `FROMV'
				local f2 ""
				local t2 ""
				forvalues q = 1/`nf' {
					local fq : word `q' of `FROMV'
					local tq : word `q' of `TOV'
					if inlist("`tq'", "Inf", "inf", ".") | real("`tq'") >= . {
						local tq = max(`fq', `nodes') + 1
					}
					if `fq' >= `tq' {
						di "{err}Term {bf:`tname'} must have from < to."
						error 198
					}
					local f2 "`f2' `fq'"
					local t2 "`t2' `tq'"
				}
			}
			else {
				if "`DV'" == "" local DV "`POSV'"
				if "`DV'" == "" {
					di "{err}Term {bf:`tname'} requires the argument {bf:d}."
					error 198
				}
				local f2 ""
				local t2 ""
				foreach dq of numlist `DV' {
					local f2 "`f2' `dq'"
					local t2 "`t2' `=`dq'+1'"
				}
			}
			local nf : word count `f2'
			local attrvar "`BYV'"
			local code0 = cond("`pfx'" == "", 17, cond("`pfx'" == "o", 18, 19))
			if `isrange' local code0 = cond("`pfx'" == "", 24, cond("`pfx'" == "o", 25, 26))
			local cpre "`pfx'deg"
			if "`attrvar'" == "" {
				forvalues q = 1/`nf' {
					local fq : word `q' of `f2'
					local tq : word `q' of `t2'
					local emp = cond(`fq' == 0, `nodes', 0)
					if `isrange' {
						local ts = cond(`tq' >= `nodes' + 1, "`fq'plus", "`fq'to`tq'")
						local cn "`cn' `cpre'`ts'"
						local slots "`slots'`code0',`fq',`tq',`emp',0,0;"
					}
					else {
						local cn "`cn' `pfx'degree`fq'"
						local slots "`slots'`code0',`fq',0,`emp',0,0;"
					}
				}
			}
			else {
				local useattr 1
				local attrmode 2
				local special "degby"
			}
		}
		else if inlist("`tname'", "kstar", "ostar", "istar") {
			if "`tname'" == "kstar" {
				_nwergm_struct_need und `dir' `tname' `netname'
			}
			else {
				_nwergm_struct_need dir `dir' `tname' `netname'
			}
			if "`KV'" == "" local KV "`POSV'"
			if "`KV'" == "" {
				di "{err}Term {bf:`tname'} requires the argument {bf:k}."
				error 198
			}
			local attrvar "`ATTR'"
			if "`attrvar'" == "" {
				local code0 = cond("`tname'" == "kstar", 21, cond("`tname'" == "ostar", 22, 23))
				foreach kq of numlist `KV' {
					local slots "`slots'`code0',`kq',0,0,0,0;"
					local cn "`cn' `tname'`kq'"
				}
			}
			else {
				local useattr 1
				local attrmode 2
				local special "kstarattr"
			}
		}
		else if "`tname'" == "nsp" {
			if "`DV'" == "" {
				di "{err}Term {bf:nsp} requires the argument {bf:d}."
				error 198
			}
			local tp = upper(cond("`TYPEV'" != "", "`TYPEV'", "`type'"))
			local __td_nsp "__nwst_td`nterm'"
			mata: `__td_nsp' = ErgmTermData()
			mata: `__td_nsp'.levels = strtoreal(tokens("`DV'"))'
			if `dir' mata: `__td_nsp'.sptype = "`tp'"
			foreach dv of numlist `DV' {
				local cn "`cn' nsp`=cond(`dir', "_" + "`tp'", "")'`dv'"
			}
			local nd : word count `DV'
			mata: __nwergm_last_M.addterm("nsp", `nd', &stat_nsp(), &change_nsp(), `__td_nsp', tokens("`cn'"))
			local temps "`temps' `__td_nsp'"
			local allcn "`allcn' `cn'"
			local dep 1
			continue
		}
		else {
			di "{err}structural(): unknown or unsupported term {bf:`tname'}."
			error 198
		}
		// ---- attribute based terms: build slots per level ----
		if `useattr' {
			confirm variable `attrvar'
			capture confirm numeric variable `attrvar'
			if _rc {
				di "{err}{bf:`tname'}: attribute {bf:`attrvar'} is a string variable; nwergm needs a numeric attribute. Encode it first."
				error 109
			}
		}
		// a unique Mata td for this term
		local __td "__nwst_td`nterm'"
		mata: `__td' = ErgmTermData()
		if `useattr' {
			mata: st_local("__ns_nlev", strofreal(ns_attr_load(`__td', "`attrvar'", `nodes', `attrmode')))
			mata: st_local("__ns_levs", invtokens(strofreal(`__td'.levels')))
			if "`tname'" == "concurrentties" & `__ns_nlev' == 1 {
				di "{err}Attribute given to concurrentties() has only one value"
				error 198
			}
			local slots ""
			local cn ""
			if "`tname'" == "concurrentties" | "`tname'" == "concurrent" {
				local code = cond("`tname'" == "concurrent", 1030, 1011)
				local q 0
				foreach lv of local __ns_levs {
					local ++q
					local slots "`slots'`code',`q',0,0,1,0;"
					local cn "`cn' `tname'_`attrvar'`lv'"
				}
			}
			else if "`special'" == "degby" {
				local isrange = (substr("`tname'", -5, .) == "range")
				local q 0
				if `HOMO' {
					forvalues r = 1/`nf' {
						local fq : word `r' of `f2'
						local tq : word `r' of `t2'
						local emp = cond(`fq' == 0, `nodes', 0)
						local c3 = cond("`pfx'" == "", 1034, cond("`pfx'" == "o", 1035, 1036))
						local slots "`slots'`c3',`fq',`tq',`emp',1,0;"
						if `isrange' {
							local ts = cond(`tq' >= `nodes' + 1, "`fq'plus", "`fq'to`tq'")
							local cn "`cn' `cpre'`ts'_homophily_`attrvar'"
						}
						else local cn "`cn' `cpre'`fq'_homophily_`attrvar'"
					}
				}
				else {
					local c3 = cond("`pfx'" == "", 1031, cond("`pfx'" == "o", 1032, 1033))
					forvalues lv = 1/`__ns_nlev' {
						local lvv : word `lv' of `__ns_levs'
						forvalues r = 1/`nf' {
							local fq : word `r' of `f2'
							local tq : word `r' of `t2'
							local emp 0
							if `fq' == 0 {
								mata: st_local("emp", strofreal(sum(`__td'.attr :== `lv')))
							}
							local p2 = `tq' + `lv' * 1000000
							local slots "`slots'`c3',`fq',`p2',`emp',1,0;"
							if `isrange' {
								local ts = cond(`tq' >= `nodes' + 1, "`fq'plus", "`fq'to`tq'")
								local cn "`cn' `cpre'`ts'_`attrvar'`lvv'"
							}
							else local cn "`cn' `cpre'`fq'_`attrvar'_`lvv'"
						}
					}
				}
			}
			else if "`special'" == "kstarattr" {
				local c3 = cond("`tname'" == "kstar", 1037, cond("`tname'" == "ostar", 1038, 1039))
				foreach kq of numlist `KV' {
					local slots "`slots'`c3',`kq',0,0,1,0;"
					local cn "`cn' `tname'`kq'_`attrvar'"
				}
			}
			else if "`tname'" == "mutual" & "`SAMEV'" == "" {
				local q 0
				foreach lv of local __ns_levs {
					local ++q
					local slots "`slots'1029,`q',0,0,1,0;"
					local cn "`cn' mutual_by_`attrvar'_`lv'"
				}
			}
			else {
				local code = cond("`tname'" == "asymmetric", 1013, cond("`tname'" == "mutual", 1028, cond("`tname'" == "ttriple", 1017, cond("`tname'" == "ctriple", 1018, cond("`tname'" == "triangle", 1019, 1020)))))
				local dflag = `DIFF'
				if `dflag' {
					local q 0
					foreach lv of local __ns_levs {
						local ++q
						local slots "`slots'`code',`q',1,0,1,0;"
						local cn "`cn' `tname'_`=cond("`tname'" == "mutual", "same_", "")'`attrvar'_`lv'"
					}
				}
				else {
					local slots "`code',0,0,0,1,0"
					local cn "`tname'_`attrvar'"
				}
			}
		}
		else {
			// plain term: td already created above only for attr; create now
		}
		if `"`covnet'"' != "" {
			_nwsyntax `covnet', max(1) other(lt`nterm')
			if `lt`nterm'nodes' != `nodes' {
				di "{err}localtriangle(): network {bf:`covnet'} has a different number of nodes than {bf:`netname'}."
				error 198
			}
			mata: `__td'.edgecovmat = *(`lt`nterm'netobj'->get_matrix_mod(0,("`directed'"=="true")))
			mata: `__td'.edgecovmat = (`__td'.edgecovmat :* `__td'.edgecovmat') 
		}
		mata: `__td'.sptype = "`special'"
		mata: `__td'.levelpairs = ns_slots("`slots'")
		local np : word count `cn'
		mata: __nwergm_last_M.addterm("ns:`tname'", `np', &stat_ns(), &change_ns(), `__td', tokens("`cn'"))
		local temps "`temps' `__td'"
		local allcn "`allcn' `cn'"
		if `isdep' local dep 1
	}
	return local temps "`temps'"
	return local cnames "`allcn'"
	return scalar dep = `dep'
end

capture program drop _nwergm_struct_need
program _nwergm_struct_need
	args need dir tname netname
	if "`need'" == "dir" & `dir' == 0 {
		di "{err}structural(): term {bf:`tname'} requires a directed network; {bf:`netname'} is undirected."
		error 198
	}
	if "`need'" == "und" & `dir' == 1 {
		di "{err}structural(): term {bf:`tname'} requires an undirected network; {bf:`netname'} is directed."
		error 198
	}
end

capture program drop _nwergm_struct_noargs
program _nwergm_struct_noargs
	syntax anything(name=tname) [, POS(string) ATTR(string)]
	if "`pos'`attr'" != "" {
		di "{err}structural(): term {bf:`tname'} takes no arguments."
		error 198
	}
end

* parse "k=v k2=v2 flag 1 2 3" into r() macros
capture program drop _nwergm_struct_args
program _nwergm_struct_args, rclass
	syntax anything(name=tname) [, ARGS(string asis)]
	local a = subinstr(`"`args'"', ",", " ", .)
	local cur "pos"
	foreach nm in attr by same d k lambda levels x type pos keep from to {
		local v_`nm' ""
	}
	local diff 0
	local fixed 0
	local semi 0
	local homophily 0
	while `"`a'"' != "" {
		gettoken tok a : a
		local eq = strpos("`tok'", "=")
		if `eq' > 0 {
			local key = substr("`tok'", 1, `eq' - 1)
			local val = substr("`tok'", `eq' + 1, .)
			if "`key'" == "attrname" local key "attr"
			if "`key'" == "diff" | "`key'" == "fixed" | "`key'" == "semi" | "`key'" == "homophily" {
				local `key' = inlist(lower("`val'"), "true", "t", "1")
				local cur "pos"
				continue
			}
			if strpos(" attr by same d k lambda levels x type keep from to ", " `key' ") == 0 {
				di "{err}structural(): unknown argument {bf:`key'} for term {bf:`tname'}."
				error 198
			}
			local v_`key' "`val'"
			local cur "`key'"
		}
		else {
			capture confirm number `tok'
			if _rc {
				if inlist("`tok'", "diff", "fixed", "semi", "homophily") {
					local `tok' 1
					local cur "pos"
				}
				else {
					// a bare word: variable / network name / level label
					local v_`cur' "`v_`cur'' `tok'"
				}
			}
			else local v_`cur' "`v_`cur'' `tok'"
		}
	}
	foreach nm in attr by same d k lambda levels x type pos keep from to {
		return local `nm' = trim("`v_`nm''")
	}
	return scalar diff = `diff'
	return scalar fixed = `fixed'
	return scalar semi = `semi'
	return scalar homophily = `homophily'
end
