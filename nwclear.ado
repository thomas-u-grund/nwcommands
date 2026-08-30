
capture program drop nwclear
program nwclear
	clear
	unw_defs
	capture mata: mata drop `nw'
	mata: st_rclear()
end

