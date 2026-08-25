capture program drop nw_deployfile
program nw_deployfile
	syntax [anything(name=cmd)][, force overwrite(string) v(string) c(real 0) only first fileonly]
	
	if "`v'" == "" {
		local v = "2.0.0"
	}
	
	
	// Get list of sub-programs in file
	file open r using `cmd'.ado, read

	file read r line
	local cmds ""
	local stop 0
	capture while (r(eof)==0 & `stop' == 0) {
		local z = strpos(`"`line'"', "capture program drop") != 0
		if `z' != 0 {
			 local newcmd = subinstr(`"`line'"', "capture program drop","",.)
			 local cmds "`cmds' `newcmd'"
			 if "`first'" != "" {
				local stop 1
			 }
			 
		 }
		 capture file read r line
	}
	
	if "`overwrite'" != "" {
		local cmds "`overwrite'"
	}
	di "{txt}Programs found:`cmds'"
	file close r
	
	file open helpreader using `cmd'.ado, read
	local index = 1
	local flag = 1
	
	di "Prepare file handlers"
	foreach h in `cmds' {
		local h = trim("`h'")
		file open `h' using "`h'.sthlp", write replace
	}
	
	di "Write help files"
	file read helpreader line 
	while (r(eof)==0) & `"`line'"' != "***/"{	
		capture if `"`line'"' == "/***" {
			local flag = 1
			file read helpreader line
		}
		capture if `"`line'"' == "***/" {
			local flag = 0
			local index = `index' + 1
		}
		
		local w = word("`cmds'", `index')
		local w = trim("`w'")
		if (`flag' == 1){
			capture file write `w' `"`line'"' _newline
		}
		capture file read helpreader line 
	}
	
	di "Run certification: `c'"
	
	if "`fileonly'" != "" {
		di "{txt}Only certify this file..."
		local h `cmd'
		local h = trim("`h'")
		capture do cscripts/test_`h'.do
		di "{txt}Check for broken program (file only)"
		if "`only'" == "" {
			do cscripts/test_`h'.do
		}
		di _rc
		
		if _rc == 0 | "`force'" != "" {
			file write `h' "" _newline
			file write `h' "" _newline
			file write `h' "version: `v'" _newline
			file write `h' "file only certified: `c(current_date)', `c(current_time)'" _newline
		}
		file close `h'
	}
	else {
	  foreach h of local cmds {
		local h = trim("`h'")
		capture do cscripts/test_`h'.do
		di "{txt}Check for broken programs"
		if "`only'" == "" {
			do test.do
		}
		di _rc
	
		if _rc == 0 | "`force'" != ""{
			di "Force: `force'"
			file write `h' "" _newline
			file write `h' "" _newline
			file write `h' "version: `v'" _newline
			file write `h' "certified: `c(current_date)', `c(current_time)'" _newline
		}
		file close `h'
	 }
	}
	
	file close helpreader
	file close _all
	

	
	help `cmd'
	
end
