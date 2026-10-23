capture program drop e6fitchk
program define e6fitchk
	args kind nm a b c
	if "`kind'" == "omitted" {
		* R reports NA (collinear); nwergm omits the coefficient or reports it exactly 0
		exit
	}
	capture local bs = _b[`nm']
	if _rc {
		di as err "FAIL: coefficient `nm' not in e(b)"
		global e6fitfail 1
		exit
	}
	local ses = _se[`nm']
	if "`kind'" == "mple" {
		* a = R coefficient, b = R se
		local dif = abs(`bs' - `a')
		local sedif = abs(`ses' - `b')
		if `dif' > 1e-4 | (`sedif' > 2e-3 & `b' > 0) {
			di as err "FAIL MPLE `nm': nwergm `bs' (se `ses') vs R `a' (se `b')"
			global e6fitfail 1
		}
		else di "  ok MPLE `nm': nwergm `bs' R `a'  (|diff| " %9.2e `dif' ")"
	}
	else {
		* a = mean of R over seeds, b = sd across R seeds, c = R reported se
		local tol = max(4*`b', 0.06)
		local dif = abs(`bs' - `a')
		if `dif' > `tol' {
			di as err "FAIL MCMLE `nm': nwergm `bs' vs R `a' (tol `tol')"
			global e6fitfail 1
		}
		else di "  ok MCMLE `nm': nwergm " %8.4f `bs' " (se " %6.4f `ses' ") R " %8.4f `a' " (se " %6.4f `c' ")  |diff| " %7.4f `dif'
	}
end
