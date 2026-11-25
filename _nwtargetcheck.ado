*! _nwtargetcheck: guards the name of a result network. It stops when the name is the input network (dropping the old result
*! would delete the input) and, with given(1), when a network of that name exists and neither replace nor nwreplace is given.
capture program drop _nwtargetcheck
program _nwtargetcheck, rclass
	syntax anything(name=target), source(string) given(integer) [replace nwreplace]
	_nwreservedname `target'
	if "`target'" == "`source'" {
		di "{err}{p 0 0 2}{bf:name(`target')} is the input network; give the result another name.{p_end}"
		exit 483
	}
	if `given' & "`replace'`nwreplace'" == "" {
		nwvalidate `target'
		if "`r(exists)'" == "true" {
			di "{err}{p 0 0 2}Network {bf:`target'} already exists; specify {bf:replace} or a different {bf:name()}.{p_end}"
			exit 483
		}
	}
end
