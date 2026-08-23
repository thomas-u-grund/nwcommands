class `NWs' {
	class `NWsdef' scalar nws
	class `NWsder' scalar nwsder
	
	void preserve()
	
}

void `NWs'::preserve(string filename){
	real scalar fh
	"a"
	_unlink(filename)
	fh = fopen(filename, "w")
	"c"
	fputmatrix(fh, this) 
	fclose(fh)
}
