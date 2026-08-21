capture program drop nw_helpwriter
program nw_helpwriter
	syntax [anything(name=cmd)]
	file open helpwriter using "`cmd'.sthlp", write replace
	file open helpreader using `cmd'.ado, read
	local flag = 1

	// The copy loop below macro-processes every line of the .ado file
	// via compound double quotes (doc header or program body alike -
	// see the note further down), so a line anywhere in the file that
	// happens to contain a backtick-quote pattern the macro processor
	// misreads can abort mid-copy with a "too few quotes" error. Left
	// uncaught, that also leaked both open file handles, so a single
	// bad .ado file broke every command processed afterward in the
	// same session with a cascading "file already open" error -
	// confirmed the hard way while running a batch certification pass
	// across ~50 commands, where nwimport.ado's genuine program-body
	// content (not a doc-comment typo) triggers this and silently
	// took the rest of the batch down with it. Wrapped in capture so
	// one bad file is isolated and both handles are always released,
	// without changing anything about the successful-copy path. The
	// underlying macro-processing fragility itself is not fixed here
	// (see docs/CERTIFICATION.md's Pending table) - correctly
	// escaping arbitrary source lines is a larger, separate, riskier
	// change than isolating this specific failure mode.
	capture noisily {
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
	}
	local copyrc = _rc

	// A bare -do- leaves Stata's ambient _rc reading whatever the test
	// file's OWN last-executed command set it to - which is frequently a
	// deliberately-triggered error code from a "capture badcmd" +
	// "assert _rc != 0" check near the end of the file, since a
	// successful assert does not itself reset _rc back to 0. That
	// false-negative silently skipped writing "last certified" for a
	// fully-passing test - confirmed via an isolated repro before fixing.
	// "capture noisily do" instead reports whether the do-file itself
	// completed without an UNCAUGHT error (the only thing this check
	// should care about), while "noisily" keeps the test's own output
	// visible exactly as before.
	if `copyrc' == 0 {
		capture noisily do cscripts/test_`cmd'.do
		if _rc == 0 {
			file write helpwriter "last certified : `c(current_date)'" _newline
		}
	}
	capture file close helpwriter
	capture file close helpreader
	
end
