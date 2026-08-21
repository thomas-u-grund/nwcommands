capture program drop nw_helpwriter
program nw_helpwriter
	syntax [anything(name=cmd)]
	file open helpwriter using "`cmd'.sthlp", write replace
	file open helpreader using `cmd'.ado, read
	local flag = 1
	
	file read helpreader line 
	while r(eof)==0 {	
		di `"`line'"'
		if `"`line'"' == "/***" {
			local flag = 1
			file read helpreader line
		}
		if `"`line'"' == "***/" {
			local flag = 0
		}
		if (`flag' == 1){
			file write helpwriter `"`line'"' _newline
		}
		file read helpreader line 
	}
	
	// A bare -do- leaves Stata's ambient _rc reading whatever the test
	// file's OWN last-executed command set it to - which is frequently a
	// deliberately-triggered error code from a `capture badcmd` +
	// `assert _rc != 0` check near the end of the file, since a
	// successful `assert` does not itself reset _rc back to 0. That
	// false-negative silently skipped writing "last certified" for a
	// fully-passing test - confirmed via an isolated repro before fixing.
	// `capture noisily do` instead reports whether the do-file itself
	// completed without an UNCAUGHT error (the only thing this check
	// should care about), while `noisily` keeps the test's own output
	// visible exactly as before.
	capture noisily do cscripts/test_`cmd'.do
	if _rc == 0 {
		file write helpwriter "last certified : `c(current_date)'" _newline
	}
	file close helpwriter
	file close helpreader
	
end
