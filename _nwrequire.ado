*! version 3.1.1  24oct2026
// _nwrequire pkgname: stop with a clear message if an optional
// user-written package is not installed. Never installs anything and never
// touches the user's PLUS directory.
program define _nwrequire
	version 14
	args pkg cmd
	if "`cmd'" == "" local cmd "`pkg'"
	capture quietly which `cmd'
	if _rc {
		di as err "{p 0 4 2}this option requires the user-written package {bf:`pkg'}, which is not installed; nwcommands never installs it for you. To install it, type {stata ssc install `pkg'}{p_end}"
		exit 199
	}
end
