* Reusable helper for the plot tests: nw_pngwidth "file.png" reads the PNG header and returns r(w) = width and r(h) = height in pixels
* (IHDR: bytes 17-20 width, 21-24 height, big-endian). Use: run cscripts/nw_pngwidth.do
capture program drop nw_pngwidth
program define nw_pngwidth, rclass
	args f
	confirm file `"`f'"'
	tempname fh b
	file open `fh' using `"`f'"', read binary
	file seek `fh' 16
	local w 0
	forvalues i = 1/4 {
		file read `fh' %1bu `b'
		local w = `w' * 256 + scalar(`b')
	}
	local h 0
	forvalues i = 1/4 {
		file read `fh' %1bu `b'
		local h = `h' * 256 + scalar(`b')
	}
	file close `fh'
	return scalar w = `w'
	return scalar h = `h'
end
* nw_assertwidth "file.png" N: the exported PNG is N pixels wide (message on failure, rc 9)
capture program drop nw_assertwidth
program define nw_assertwidth
	args f n
	nw_pngwidth `"`f'"'
	if r(w) != `n' {
		di as error `"  FAIL: width of `f' is `=r(w)', expected `n'"'
		exit 9
	}
end
