* xt_meas_00_helpers.do
* Non-stopping checks for the extended measure suite cscripts/xt_meas_*.do.
*
* Use (after clear all and do unw_core.do):
*       run cscripts/xt_meas_00_helpers.do
*       xt_minit <filename>
*       xa <assert expression [if] [in]>     (Stata assert; a failure is counted, the file goes on)
*       xm <Mata statement>                  (e.g. xm assert(x == 1); an error is counted as a failure)
*       xt_mend                               (lists the failures; stops with r(9) if there are any)
* xa and xm are n-class programs: they leave r(), e() and _rc as they were (xa restores _rc).

capture program drop xt_minit
program xt_minit
	global XTM_FAILS 0
	global XTM_N 0
	global XTM_LIST ""
	global XTM_FILE `"`0'"'
end

capture program drop xa
program xa
	local rc0 = _rc
	global XTM_N = $XTM_N + 1
	capture assert `0'
	local rc1 = _rc
	if `rc1' {
		global XTM_FAILS = $XTM_FAILS + 1
		di as err `"  FAIL #$XTM_N (rc `rc1'): assert `0'"'
		global XTM_LIST `"$XTM_LIST [#$XTM_N: `0']"'
	}
	capture error `rc0'
end

capture program drop xm
program xm
	local rc0 = _rc
	global XTM_N = $XTM_N + 1
	capture mata: `0'
	local rc1 = _rc
	if `rc1' {
		global XTM_FAILS = $XTM_FAILS + 1
		di as err `"  FAIL #$XTM_N (rc `rc1'): mata: `0'"'
		global XTM_LIST `"$XTM_LIST [#$XTM_N: mata `0']"'
	}
	capture error `rc0'
end

capture program drop xt_mend
program xt_mend
	di as txt "$XTM_N checks run in $XTM_FILE"
	if $XTM_FAILS > 0 {
		di as err "XTM SUMMARY: $XTM_FAILS check(s) failed in $XTM_FILE:"
		di as err `"$XTM_LIST"'
		exit 9
	}
	di as txt "XTM SUMMARY: all checks of $XTM_FILE passed"
end
