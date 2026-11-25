*! _nwdetemporal netname: after a command has changed the ties of a network itself (not its history), the times, events
*! or intervals no longer describe them; the network stops being temporal and the user is told.
capture program drop _nwdetemporal
program _nwdetemporal
	args netname
	_nwsyntax `netname', max(1)
	if "`istemporal'" != "true" exit
	mata: `netobj'->set_temporal(0)
	mata: `netobj'->set_temporal_type("")
	di "{txt}{p 0 0 2}(note: network {bf:`netname'} is no longer temporal: its times no longer describe the changed ties){p_end}"
end
