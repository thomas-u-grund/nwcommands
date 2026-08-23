capture program drop nwrestore
program nwrestore
	unw_defs
	capture confirm file `nw_tempfile'.nwdta
	if _rc != 0 {
		di "{err}Nothing to restore"
		exit
	}
	nwuse `nw_tempfile', clear
	erase `nw_tempfile'.nwdta
end
