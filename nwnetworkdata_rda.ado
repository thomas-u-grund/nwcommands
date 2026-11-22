*! Date        : 22nov2026
*! Version     : 1.0.0
*! Author      : Thomas Grund (nwcommands)
*! Purpose     : read the .rda files of the R package networkdata (Schoch, MIT licence) without R: gzip inflate, R serialization, igraph objects -> csv tables
*
* Part of nwnetworkdata. Ships NO data. nwnetworkdata_rda <file.rda> <output folder> [, maxout() maxin()] reads ONE downloaded .rda file
* with Stata's own Mata code and writes the same csv tables that the R script nwnetworkdata_convert.R writes (<obj>_index.csv,
* _edges.csv, _nodes.csv, _attrs.csv), so that everything after the conversion is shared by both readers.
*
* What the code does, in this order (every step checks its input; nothing is executed, nothing is evaluated):
*   1. nwrd_gunzip():  gzip header, DEFLATE decoder (stored, fixed and dynamic Huffman blocks), CRC-32 and length check; the output goes
*      to a temporary file in blocks of 1 MB (memory stays small); the size of the input and of the output is capped.
*   2. nwrd_rds:       the R serialization format (XDR, versions 2 and 3, the RDX2/RDX3 wrapper of .rda files): vectors, lists, pairlists,
*      attributes, references, environments (skipped), ALTREP compact sequences. Every length is checked against the bytes that are left
*      in the file, the nesting depth, the number of objects and the total number of elements are capped.
*   3. nwrd_igraph:    igraph objects (the list of ten elements that igraph has used since 0.5; the same layout in the versions of
*      igraph that were used to save the networkdata files) and lists of igraph objects -> tables. Anything it does not understand
*      stops with r(9001) and a message (nwnetworkdata then uses R, if you have it, or says so); it never guesses.
*
* Return codes: 0 ok; 9001 = the file is valid but holds something this reader does not handle (use R); 9002 = the file is damaged or
* exceeds a limit (not a valid .rda / gzip file, truncated, checksum, size caps).

capture program drop nwnetworkdata_rda
program nwnetworkdata_rda, rclass
	version 14
	syntax anything(name=args) [, MAXOut(real 536870912) MAXIn(real 67108864) KEEPraw]
	gettoken rda rest : args
	gettoken outdir rest : rest
	if `"`rda'"' == "" | `"`outdir'"' == "" | trim(`"`rest'"') != "" {
		di as err "nwnetworkdata_rda: usage: nwnetworkdata_rda <file.rda> <output folder>"
		exit 198
	}
	capture confirm file `"`rda'"'
	if _rc {
		di as err `"{p 0 0 2}file not found: {bf:`rda'}{p_end}"'
		exit 601
	}
	capture mkdir `"`outdir'"'
	tempfile raw
	capture mata: nwrd_run(st_local("rda"), st_local("raw"), st_local("outdir"), `maxout', `maxin')
	local rc = _rc
	local msg `"$NWND_MSG"'
	capture mata: nwrd_cleanup()
	capture quietly erase `"`raw'"'
	if `rc' != 0 {
		if !inlist(`rc', 9001, 9002) {
			local msg "unexpected error r(`rc') while reading the file (the file is damaged or not an .rda file)"
			global NWND_MSG `"`msg'"'
			local rc 9002
		}
		di as err `"{p 0 0 2}`msg'{p_end}"'
		exit `rc'
	}
	return local obj `"`msg'"'
end

capture mata: mata drop nwrd_*()
mata:
mata set matastrict off

// ================================================================================================================
// 1. gzip / DEFLATE
// ================================================================================================================

// CRC-32 (polynomial 0xEDB88320) without bit operators: 32-bit words are handled as four bytes, the exclusive or of two bytes
// is a table lookup, long blocks are cut into 1024 pieces that are processed in parallel (vector operations) and joined with the
// operator "L zero bytes".
class nwrd_crc {
	real colvector Xv, T, tb0, tb1, tb2, tb3
	real scalar zL
	real matrix Zt
	void init()
	real scalar x32()
	real colvector x32v()
	real scalar upd()
	void zmake()
	real scalar zapply()
}

void nwrd_crc::init()
{
	real colvector a, ba, lb
	real scalar k, pk
	a = (0::255)
	Xv = J(65536, 1, 0)
	for (k = 0; k < 8; k++) {
		pk = 2^k
		ba = mod(floor(a / pk), 2)
		Xv = Xv + pk * colshape(abs(ba * J(1, 256, 1) - J(256, 1, 1) * ba'), 1)
	}
	T = a
	for (k = 1; k <= 8; k++) {
		lb = mod(T, 2)
		T = floor(T / 2)
		T = (1 :- lb) :* T + lb :* x32v(T, J(256, 1, 3988292384))
	}
	tb0 = mod(T, 256)
	tb1 = mod(floor(T / 256), 256)
	tb2 = mod(floor(T / 65536), 256)
	tb3 = floor(T / 16777216)
	zL = -1
}

real scalar nwrd_crc::x32(real scalar a, real scalar b)
{
	return(Xv[mod(a, 256) + 256 * mod(b, 256) + 1] + 256 * Xv[mod(floor(a / 256), 256) + 256 * mod(floor(b / 256), 256) + 1] ///
		+ 65536 * Xv[mod(floor(a / 65536), 256) + 256 * mod(floor(b / 65536), 256) + 1] + 16777216 * Xv[floor(a / 16777216) + 256 * floor(b / 16777216) + 1])
}

real colvector nwrd_crc::x32v(real colvector a, real colvector b)
{
	return(Xv[mod(a, 256) + 256 * mod(b, 256) :+ 1] + 256 * Xv[mod(floor(a / 256), 256) + 256 * mod(floor(b / 256), 256) :+ 1] ///
		+ 65536 * Xv[mod(floor(a / 65536), 256) + 256 * mod(floor(b / 65536), 256) :+ 1] + 16777216 * Xv[floor(a / 16777216) + 256 * floor(b / 16777216) :+ 1])
}

// Zt: the effect of L zero bytes on a CRC register, as four byte-wise tables
void nwrd_crc::zmake(real scalar L)
{
	real colvector c, z
	real scalar k, bit, i
	if (L == zL) return
	c = 2:^(0::31)
	for (i = 1; i <= L; i++) c = x32v(T[mod(c, 256) :+ 1], floor(c / 256))
	Zt = J(256, 4, 0)
	for (k = 0; k < 4; k++) {
		z = J(256, 1, 0)
		for (bit = 0; bit < 8; bit++) {
			z[|2^bit + 1 \ 2^(bit + 1)|] = x32v(z[|1 \ 2^bit|], J(2^bit, 1, c[8 * k + bit + 1]))
		}
		Zt[., k + 1] = z
	}
	zL = L
}

real scalar nwrd_crc::zapply(real scalar a)
{
	return(x32(x32(Zt[mod(a, 256) + 1, 1], Zt[mod(floor(a / 256), 256) + 1, 2]), x32(Zt[mod(floor(a / 65536), 256) + 1, 3], Zt[floor(a / 16777216) + 1, 4])))
}

// register after the bytes of the rowvector b, starting from register reg (the standard CRC is reg = 0xFFFFFFFF at the start, xor 0xFFFFFFFF at the end)
real scalar nwrd_crc::upd(real scalar reg, real rowvector b)
{
	real scalar n, K, L, i, j, used, idx
	real matrix M
	real colvector r
	real rowvector s0, s1, s2, s3, t, Xr, t0, t1, t2, t3
	n = cols(b)
	K = 1024
	used = 0
	if (n >= 4 * K) {
		L = floor(n / K)
		zmake(L)
		M = colshape(b[|1 \ K * L|], L)'
		s0 = J(1, K, 0); s1 = s0; s2 = s0; s3 = s0
		Xr = Xv'
		t0 = tb0'; t1 = tb1'; t2 = tb2'; t3 = tb3'
		for (i = 1; i <= L; i++) {
			t = Xr[s0 + 256 * M[i, .] :+ 1] :+ 1
			s0 = Xr[s1 + 256 * t0[t] :+ 1]
			s1 = Xr[s2 + 256 * t1[t] :+ 1]
			s2 = Xr[s3 + 256 * t2[t] :+ 1]
			s3 = t3[t]
		}
		r = (s0 + 256 * s1 + 65536 * s2 + 16777216 * s3)'
		for (j = 1; j <= K; j++) reg = x32(zapply(reg), r[j])
		used = K * L
	}
	for (i = used + 1; i <= n; i++) {
		idx = Xv[mod(reg, 256) + 256 * b[i] + 1]
		reg = x32(T[idx + 1], floor(reg / 256))
	}
	return(reg)
}

void nwrd_fail(string scalar m)
{
	st_global("NWND_MSG", m)
}

// canonical Huffman code -> lookup table indexed by the next maxl bits (least significant bit first, as DEFLATE delivers them).
// returns 0 if the code is over-subscribed, 1 otherwise (incomplete codes are allowed; unused table entries have length 0)
real scalar nwrd_huff(real rowvector lens, real colvector sym, real colvector len, real scalar maxl)
{
	real rowvector cnt, nxt
	real scalar l, code, s, c, r, i, ns
	real colvector idx
	ns = cols(lens)
	maxl = max(lens)
	if (maxl == 0) {
		maxl = 1
		sym = J(2, 1, 0); len = J(2, 1, 0)
		return(1)
	}
	cnt = J(1, 16, 0)
	for (s = 1; s <= ns; s++) if (lens[s] > 0) cnt[lens[s] + 1] = cnt[lens[s] + 1] + 1
	// over-subscription: sum of 2^-len must not exceed 1
	c = 0
	for (l = 1; l <= maxl; l++) c = c + cnt[l + 1] * 2^(maxl - l)
	if (c > 2^maxl) return(0)
	nxt = J(1, 16, 0)
	code = 0
	for (l = 1; l <= maxl; l++) {
		code = (code + cnt[l]) * 2
		if (l == 1) code = 0
		nxt[l + 1] = code
	}
	sym = J(2^maxl, 1, 0); len = J(2^maxl, 1, 0)
	for (s = 1; s <= ns; s++) {
		l = lens[s]
		if (l == 0) continue
		c = nxt[l + 1]
		nxt[l + 1] = c + 1
		r = 0
		for (i = 1; i <= l; i++) {
			r = 2 * r + mod(c, 2)
			c = floor(c / 2)
		}
		idx = r :+ 2^l * (0::(2^(maxl - l) - 1)) :+ 1
		sym[idx] = J(rows(idx), 1, s - 1)
		len[idx] = J(rows(idx), 1, l)
	}
	return(1)
}

// the canonical code of length l starts at (code of length l-1 + number of codes of length l-1) * 2: the loop above has cnt[l] = number
// of codes of length l-1 (cnt is indexed by length + 1), so code = (code + cnt[l]) * 2, with cnt[1] (length 0) counted as 0.

// gunzip infile -> outfile. Returns the number of bytes written, or -1 (message in nwrd_msg).
real scalar nwrd_gunzip(string scalar infile, string scalar outfile, real scalar maxout, real scalar maxin)
{
	real scalar fh, fo, n, p, flg, dend, pos, bitbuf, bitcnt, bfinal, btype, op, flushat, total, BLK, i, k, sym, l, idx, ln, dist, dsym, eb
	real scalar lmax, dmax, hlit, hdist, hclen, nl, prev, rep, plim, crcreg, isize, crcfile, len2, nlen, stored, from, m, endpos, ok, cmax
	real rowvector src, ob, p2, lbase, lext, dbase, dext, order, cl, lens, pat
	real colvector ls, ll, ds, dl, cs, cll
	real scalar nbits
	class nwrd_crc scalar crc
	transmorphic C

	BLK = 1048576
	st_global("NWND_MSG", "")
	fh = fopen(infile, "r")
	nwrd_reg(fh)
	fseek(fh, 0, 1)
	n = ftell(fh)
	fseek(fh, 0, -1)
	if (n > maxin) { fclose(fh); nwrd_fail("the file is larger than the limit of " + strofreal(maxin) + " bytes"); return(-1); }
	if (n < 18) { fclose(fh); nwrd_fail("the file is too short to be a gzip file"); return(-1); }
	C = bufio()
	src = fbufget(C, fh, "%1bu", 1, n)
	fclose(fh)
	if (src[1] != 31 | src[2] != 139 | src[3] != 8) { nwrd_fail("not a gzip file (wrong magic bytes); .rda files are gzip-compressed R files"); return(-1); }
	flg = src[4]
	if (flg >= 32) { nwrd_fail("gzip header with reserved flags"); return(-1); }
	p = 11
	if (mod(floor(flg / 4), 2)) {
		if (p + 1 > n - 8) { nwrd_fail("damaged gzip header"); return(-1); }
		p = p + 2 + src[p] + 256 * src[p + 1]
	}
	for (k = 3; k <= 4; k++) {
		if (mod(floor(flg / 2^k), 2)) {
			while (p <= n - 8 & src[p] != 0) p++
			p++
		}
	}
	if (mod(floor(flg / 2), 2)) p = p + 2
	dend = n - 8
	if (p > dend) { nwrd_fail("damaged gzip header"); return(-1); }
	crcfile = src[dend + 1] + 256 * src[dend + 2] + 65536 * src[dend + 3] + 16777216 * src[dend + 4]
	isize = src[dend + 5] + 256 * src[dend + 6] + 65536 * src[dend + 7] + 16777216 * src[dend + 8]
	if (isize > maxout) { nwrd_fail("the decompressed size (" + strofreal(isize, "%15.0fc") + " bytes) is larger than the limit of " + strofreal(maxout, "%15.0fc") + " bytes"); return(-1); }
	src = (src[|1 \ dend|], J(1, 16, 0))
	plim = dend + 8
	pos = p

	p2 = 2:^(0..52)
	lbase = (3,4,5,6,7,8,9,10,11,13,15,17,19,23,27,31,35,43,51,59,67,83,99,115,131,163,195,227,258)
	lext = (0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4,5,5,5,5,0)
	dbase = (1,2,3,4,5,7,9,13,17,25,33,49,65,97,129,193,257,385,513,769,1025,1537,2049,3073,4097,6145,8193,12289,16385,24577)
	dext = (0,0,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13)
	order = (16,17,18,0,8,7,9,6,10,5,11,4,12,3,13,2,14,1,15)

	crc.init()
	crcreg = 4294967295
	(void) _unlink(outfile)
	fo = fopen(outfile, "w")
	nwrd_reg(fo)
	ob = J(1, BLK + 32768 + 70000, 0)
	op = 1
	flushat = BLK + 32768
	total = 0
	bitbuf = 0
	bitcnt = 0
	ok = 1
	do {
		if (bitcnt < 30) { bitbuf = bitbuf + (src[pos] + 256 * src[pos + 1] + 65536 * src[pos + 2]) * p2[bitcnt + 1]; pos = pos + 3; bitcnt = bitcnt + 24; }
		bfinal = mod(bitbuf, 2)
		btype = mod(floor(bitbuf / 2), 4)
		bitbuf = floor(bitbuf / 8)
		bitcnt = bitcnt - 3
		if (pos > plim) { nwrd_fail("the gzip data end too early (truncated file)"); ok = 0; break; }
		if (btype == 3) { nwrd_fail("damaged gzip data (invalid block type)"); ok = 0; break; }
		if (btype == 0) {
			// stored block: go back to a byte boundary
			pos = pos - floor(bitcnt / 8)
			bitbuf = 0; bitcnt = 0
			if (pos + 3 > dend) { nwrd_fail("the gzip data end too early (truncated file)"); ok = 0; break; }
			len2 = src[pos] + 256 * src[pos + 1]
			nlen = src[pos + 2] + 256 * src[pos + 3]
			if (len2 + nlen != 65535) { nwrd_fail("damaged gzip data (stored block length)"); ok = 0; break; }
			pos = pos + 4
			if (pos + len2 - 1 > dend) { nwrd_fail("the gzip data end too early (truncated file)"); ok = 0; break; }
			if (len2 > 0) {
				ob[|op \ op + len2 - 1|] = src[|pos \ pos + len2 - 1|]
				op = op + len2
				pos = pos + len2
			}
		}
		else {
			if (btype == 1) {
				lens = (J(1, 144, 8), J(1, 112, 9), J(1, 24, 7), J(1, 8, 8))
				(void) nwrd_huff(lens, ls, ll, lmax)
				lens = J(1, 30, 5)
				(void) nwrd_huff(lens, ds, dl, dmax)
			}
			else {
				if (bitcnt < 30) { bitbuf = bitbuf + (src[pos] + 256 * src[pos + 1] + 65536 * src[pos + 2]) * p2[bitcnt + 1]; pos = pos + 3; bitcnt = bitcnt + 24; }
				hlit = mod(bitbuf, 32) + 257
				hdist = mod(floor(bitbuf / 32), 32) + 1
				hclen = mod(floor(bitbuf / 1024), 16) + 4
				bitbuf = floor(bitbuf / 16384)
				bitcnt = bitcnt - 14
				if (hlit > 286 | hdist > 30) { nwrd_fail("damaged gzip data (too many codes)"); ok = 0; break; }
				cl = J(1, 19, 0)
				for (i = 1; i <= hclen; i++) {
					if (bitcnt < 3) { bitbuf = bitbuf + (src[pos] + 256 * src[pos + 1] + 65536 * src[pos + 2]) * p2[bitcnt + 1]; pos = pos + 3; bitcnt = bitcnt + 24; }
					cl[order[i] + 1] = mod(bitbuf, 8)
					bitbuf = floor(bitbuf / 8)
					bitcnt = bitcnt - 3
				}
				if (nwrd_huff(cl, cs, cll, cmax) == 0) { nwrd_fail("damaged gzip data (code lengths)"); ok = 0; break; }
				lens = J(1, hlit + hdist, 0)
				i = 1
				while (i <= hlit + hdist) {
					if (bitcnt < 30) { bitbuf = bitbuf + (src[pos] + 256 * src[pos + 1] + 65536 * src[pos + 2]) * p2[bitcnt + 1]; pos = pos + 3; bitcnt = bitcnt + 24; }
					if (pos > plim) { nwrd_fail("the gzip data end too early (truncated file)"); ok = 0; break; }
					idx = mod(bitbuf, 2^cmax) + 1
					l = cll[idx]
					if (l == 0) { nwrd_fail("damaged gzip data (invalid code length code)"); ok = 0; break; }
					sym = cs[idx]
					bitbuf = floor(bitbuf / p2[l + 1]); bitcnt = bitcnt - l
					if (sym < 16) { lens[i] = sym; i++; }
					else {
						if (sym == 16) {
							if (i == 1) { nwrd_fail("damaged gzip data (repeat without previous length)"); ok = 0; break; }
							prev = lens[i - 1]; rep = 3 + mod(bitbuf, 4); bitbuf = floor(bitbuf / 4); bitcnt = bitcnt - 2
						}
						else if (sym == 17) { prev = 0; rep = 3 + mod(bitbuf, 8); bitbuf = floor(bitbuf / 8); bitcnt = bitcnt - 3; }
						else { prev = 0; rep = 11 + mod(bitbuf, 128); bitbuf = floor(bitbuf / 128); bitcnt = bitcnt - 7; }
						if (i + rep - 1 > hlit + hdist) { nwrd_fail("damaged gzip data (code lengths overflow)"); ok = 0; break; }
						lens[|i \ i + rep - 1|] = J(1, rep, prev)
						i = i + rep
					}
				}
				if (!ok) break
				if (lens[256 + 1] == 0) { nwrd_fail("damaged gzip data (no end-of-block code)"); ok = 0; break; }
				if (nwrd_huff(lens[|1 \ hlit|], ls, ll, lmax) == 0) { nwrd_fail("damaged gzip data (literal codes)"); ok = 0; break; }
				if (nwrd_huff(lens[|hlit + 1 \ hlit + hdist|], ds, dl, dmax) == 0) { nwrd_fail("damaged gzip data (distance codes)"); ok = 0; break; }
			}
			lmax = 2^lmax; dmax = 2^dmax
			// the symbols of the block
			while (1) {
				if (bitcnt < 30) {
					if (pos > plim) { nwrd_fail("the gzip data end too early (truncated file)"); ok = 0; break; }
					bitbuf = bitbuf + (src[pos] + 256 * src[pos + 1] + 65536 * src[pos + 2]) * p2[bitcnt + 1]; pos = pos + 3; bitcnt = bitcnt + 24
				}
				idx = mod(bitbuf, lmax) + 1
				l = ll[idx]
				if (l == 0) { nwrd_fail("damaged gzip data (invalid literal/length code)"); ok = 0; break; }
				sym = ls[idx]
				bitbuf = floor(bitbuf / p2[l + 1]); bitcnt = bitcnt - l
				if (sym < 256) {
					ob[op] = sym
					op++
					if (op > flushat) {
						if (total + BLK > maxout) { nwrd_fail("the decompressed data exceed the limit of " + strofreal(maxout, "%15.0fc") + " bytes"); ok = 0; break; }
						crcreg = crc.upd(crcreg, ob[|1 \ BLK|])
						fbufput(C, fo, "%1bu", ob[|1 \ BLK|])
						ob[|1 \ op - 1 - BLK|] = ob[|BLK + 1 \ op - 1|]
						op = op - BLK
						total = total + BLK
					}
					continue
				}
				if (sym == 256) break
				sym = sym - 257
				if (sym > 28) { nwrd_fail("damaged gzip data (invalid length symbol)"); ok = 0; break; }
				ln = lbase[sym + 1]
				eb = lext[sym + 1]
				if (eb > 0) { ln = ln + mod(bitbuf, p2[eb + 1]); bitbuf = floor(bitbuf / p2[eb + 1]); bitcnt = bitcnt - eb; }
				if (bitcnt < 30) {
					if (pos > plim) { nwrd_fail("the gzip data end too early (truncated file)"); ok = 0; break; }
					bitbuf = bitbuf + (src[pos] + 256 * src[pos + 1] + 65536 * src[pos + 2]) * p2[bitcnt + 1]; pos = pos + 3; bitcnt = bitcnt + 24
				}
				idx = mod(bitbuf, dmax) + 1
				l = dl[idx]
				if (l == 0) { nwrd_fail("damaged gzip data (invalid distance code)"); ok = 0; break; }
				dsym = ds[idx]
				bitbuf = floor(bitbuf / p2[l + 1]); bitcnt = bitcnt - l
				if (dsym > 29) { nwrd_fail("damaged gzip data (invalid distance symbol)"); ok = 0; break; }
				dist = dbase[dsym + 1]
				eb = dext[dsym + 1]
				if (eb > 0) { dist = dist + mod(bitbuf, p2[eb + 1]); bitbuf = floor(bitbuf / p2[eb + 1]); bitcnt = bitcnt - eb; }
				if (dist > total + op - 1) { nwrd_fail("damaged gzip data (distance too far back)"); ok = 0; break; }
				from = op - dist
				if (dist >= ln) ob[|op \ op + ln - 1|] = ob[|from \ from + ln - 1|]
				else if (dist == 1) ob[|op \ op + ln - 1|] = J(1, ln, ob[from])
				else {
					pat = ob[|from \ op - 1|]
					ob[|op \ op + ln - 1|] = rowshape(J(ceil(ln / dist), 1, 1) # pat, 1)[|1 \ ln|]
				}
				op = op + ln
				if (op > flushat) {
					if (total + BLK > maxout) { nwrd_fail("the decompressed data exceed the limit of " + strofreal(maxout, "%15.0fc") + " bytes"); ok = 0; break; }
					crcreg = crc.upd(crcreg, ob[|1 \ BLK|])
					fbufput(C, fo, "%1bu", ob[|1 \ BLK|])
					ob[|1 \ op - 1 - BLK|] = ob[|BLK + 1 \ op - 1|]
					op = op - BLK
					total = total + BLK
				}
			}
			if (!ok) break
		}
		if (op > flushat) {
			if (total + BLK > maxout) { nwrd_fail("the decompressed data exceed the limit of " + strofreal(maxout, "%15.0fc") + " bytes"); ok = 0; break; }
			crcreg = crc.upd(crcreg, ob[|1 \ BLK|])
			fbufput(C, fo, "%1bu", ob[|1 \ BLK|])
			ob[|1 \ op - 1 - BLK|] = ob[|BLK + 1 \ op - 1|]
			op = op - BLK
			total = total + BLK
		}
	} while (!bfinal)
	if (ok) {
		if (total + op - 1 > maxout) { nwrd_fail("the decompressed data exceed the limit of " + strofreal(maxout, "%15.0fc") + " bytes"); ok = 0; }
	}
	if (ok) {
		if (op > 1) {
			crcreg = crc.upd(crcreg, ob[|1 \ op - 1|])
			fbufput(C, fo, "%1bu", ob[|1 \ op - 1|])
		}
		total = total + op - 1
	}
	fclose(fo)
	if (!ok) return(-1)
	// consumed input: whole bytes in use
	endpos = pos - floor(bitcnt / 8)
	if (endpos - 1 > dend) { nwrd_fail("the gzip data end too early (truncated file)"); return(-1); }
	if (endpos - 1 != dend) { nwrd_fail("the gzip file has data after the end of the compressed stream (not a plain .rda file)"); return(-1); }
	crcreg = crc.x32(crcreg, 4294967295)
	if (crcreg != crcfile) { nwrd_fail("checksum error: the file is damaged (CRC-32 of the decompressed data does not match)"); return(-1); }
	if (mod(total, 4294967296) != isize) { nwrd_fail("size error: the file is damaged (length of the decompressed data does not match)"); return(-1); }
	return(total)
}

// ================================================================================================================
// 1b. bzip2 (a few of the files of the collection are compressed with it)
// ================================================================================================================

// bzip2 -> outfile. Returns the number of bytes written, or -1 (message in NWND_MSG). Same limits as nwrd_gunzip().
real scalar nwrd_bunzip2(string scalar infile, string scalar outfile, real scalar maxout, real scalar maxin)
{
	real scalar fh, fo, n, pos, bitbuf, bitcnt, total, level, maxblock, ok, i, j, k, g, a, nsel, ngroups, nin, alpha, curr, v, l
	real scalar sel, gpos, gno, sym, es, nn, N, nblk, origptr, rnd, crcstored, combined, bcrc, ch, run, cnt, last, op, eob, T, idx, m
	real rowvector src, p2, inuse, seqtounseq, yy, selmtf, selector, lens, out, blk, rev, ob, ar
	real colvector srt
	real matrix lensall, TSYM, TLEN, PERM, BASE, LIMIT
	class nwrd_crc scalar crc
	transmorphic C

	st_global("NWND_MSG", "")
	fh = fopen(infile, "r")
	nwrd_reg(fh)
	fseek(fh, 0, 1)
	n = ftell(fh)
	fseek(fh, 0, -1)
	if (n > maxin) { fclose(fh); nwrd_fail("the file is larger than the limit of " + strofreal(maxin) + " bytes"); return(-1); }
	if (n < 14) { fclose(fh); nwrd_fail("the file is too short to be a bzip2 file"); return(-1); }
	C = bufio()
	src = fbufget(C, fh, "%1bu", 1, n)
	fclose(fh)
	if (src[1] != 66 | src[2] != 90 | src[3] != 104 | src[4] < 49 | src[4] > 57) { nwrd_fail("not a bzip2 file (wrong magic bytes)"); return(-1); }
	level = src[4] - 48
	maxblock = level * 100000
	src = (src, J(1, 16, 0))
	pos = 5
	bitbuf = 0; bitcnt = 0
	p2 = 2:^(0..52)
	crc.init()
	// bit-reversal of a byte (bzip2 computes its CRC most significant bit first; the reflected CRC of nwrd_crc gives the same value on reversed bytes)
	rev = J(1, 256, 0)
	for (i = 0; i < 256; i++) {
		v = 0; k = i
		for (j = 1; j <= 8; j++) { v = 2 * v + mod(k, 2); k = floor(k / 2); }
		rev[i + 1] = v
	}
	(void) _unlink(outfile)
	fo = fopen(outfile, "w")
	nwrd_reg(fo)
	total = 0
	combined = 0
	ok = 1
	while (1) {
		// 48 bits: block magic or end-of-stream magic
		a = nwrd_bz(src, pos, bitbuf, bitcnt, 24, p2); b2 = nwrd_bz(src, pos, bitbuf, bitcnt, 24, p2)
		if (pos > n + 4) { nwrd_fail("the bzip2 data end too early (truncated file)"); ok = 0; break; }
		if (a == 1536581 & b2 == 3690640) {
			// end of stream: combined CRC
			crcstored = nwrd_bz(src, pos, bitbuf, bitcnt, 16, p2) * 65536 + nwrd_bz(src, pos, bitbuf, bitcnt, 16, p2)
			if (crcstored != combined) { nwrd_fail("checksum error: the file is damaged (bzip2 stream CRC)"); ok = 0; }
			break
		}
		if (a != 3227993 | b2 != 2511705) { nwrd_fail("damaged bzip2 data (block header)"); ok = 0; break; }
		crcstored = nwrd_bz(src, pos, bitbuf, bitcnt, 16, p2) * 65536 + nwrd_bz(src, pos, bitbuf, bitcnt, 16, p2)
		rnd = nwrd_bz(src, pos, bitbuf, bitcnt, 1, p2)
		if (rnd) { nwrd_fail("a randomised bzip2 block (not handled here)"); ok = 0; break; }
		origptr = nwrd_bz(src, pos, bitbuf, bitcnt, 24, p2)
		// symbols in use
		inuse = J(1, 256, 0)
		a = nwrd_bz(src, pos, bitbuf, bitcnt, 16, p2)
		for (i = 0; i < 16; i++) {
			if (mod(floor(a / 2^(15 - i)), 2)) {
				b2 = nwrd_bz(src, pos, bitbuf, bitcnt, 16, p2)
				for (j = 0; j < 16; j++) if (mod(floor(b2 / 2^(15 - j)), 2)) inuse[16 * i + j + 1] = 1
			}
		}
		seqtounseq = selectindex(inuse) :- 1
		nin = cols(seqtounseq)
		if (nin == 0) { nwrd_fail("damaged bzip2 data (no symbols)"); ok = 0; break; }
		alpha = nin + 2
		ngroups = nwrd_bz(src, pos, bitbuf, bitcnt, 3, p2)
		if (ngroups < 2 | ngroups > 6) { nwrd_fail("damaged bzip2 data (number of tables)"); ok = 0; break; }
		nsel = nwrd_bz(src, pos, bitbuf, bitcnt, 15, p2)
		if (nsel < 1) { nwrd_fail("damaged bzip2 data (number of selectors)"); ok = 0; break; }
		selmtf = J(1, nsel, 0)
		for (i = 1; i <= nsel; i++) {
			j = 0
			while (nwrd_bz(src, pos, bitbuf, bitcnt, 1, p2)) {
				j++
				if (j >= ngroups) { nwrd_fail("damaged bzip2 data (selector)"); ok = 0; break; }
			}
			if (!ok) break
			selmtf[i] = j
			if (pos > n + 4) { nwrd_fail("the bzip2 data end too early (truncated file)"); ok = 0; break; }
		}
		if (!ok) break
		// undo the move-to-front of the selectors
		selector = J(1, nsel, 0)
		yy = (0..ngroups - 1)
		for (i = 1; i <= nsel; i++) {
			j = selmtf[i]
			v = yy[j + 1]
			if (j > 0) yy[|2 \ j + 1|] = yy[|1 \ j|]
			yy[1] = v
			selector[i] = v
		}
		// coding tables
		lensall = J(ngroups, alpha, 0)
		for (g = 1; g <= ngroups; g++) {
			curr = nwrd_bz(src, pos, bitbuf, bitcnt, 5, p2)
			for (i = 1; i <= alpha; i++) {
				while (1) {
					if (curr < 1 | curr > 20) { nwrd_fail("damaged bzip2 data (code length)"); ok = 0; break; }
					if (nwrd_bz(src, pos, bitbuf, bitcnt, 1, p2) == 0) break
					if (nwrd_bz(src, pos, bitbuf, bitcnt, 1, p2) == 0) curr++
					else curr--
					if (pos > n + 4) { nwrd_fail("the bzip2 data end too early (truncated file)"); ok = 0; break; }
				}
				if (!ok) break
				lensall[g, i] = curr
			}
			if (!ok) break
		}
		if (!ok) break
		// decoding tables (most significant bit first): a lookup table for the first TB bits, limit/base/perm for longer codes
		TB = 12
		TSYM = J(2^TB, ngroups, 0); TLEN = TSYM
		PERM = J(alpha, ngroups, 0); BASE = J(22, ngroups, 0); LIMIT = J(22, ngroups, -1)
		for (g = 1; g <= ngroups; g++) {
			lens = lensall[g, .]
			// canonical codes: symbols sorted by (length, symbol)
			srt = order((lens', (1::alpha)), (1, 2))
			PERM[., g] = srt :- 1
			code = 0; idx = 0
			for (l = 1; l <= 20; l++) {
				cntl = sum(lens :== l)
				if (code + cntl > 2^l) { nwrd_fail("damaged bzip2 data (over-subscribed code)"); ok = 0; break; }
				BASE[l, g] = idx - code
				LIMIT[l, g] = code + cntl - 1
				if (l <= TB) {
					for (m = 0; m < cntl; m++) {
						a = (code + m) * 2^(TB - l)
						TSYM[|a + 1, g \ a + 2^(TB - l), g|] = J(2^(TB - l), 1, PERM[idx + m + 1, g])
						TLEN[|a + 1, g \ a + 2^(TB - l), g|] = J(2^(TB - l), 1, l)
					}
				}
				code = (code + cntl) * 2
				idx = idx + cntl
			}
			if (!ok) break
		}
		if (!ok) break
		// the symbols: run-length coded zeros (RUNA, RUNB) and move-to-front indices
		eob = nin + 1
		blk = J(1, 4096, 0)
		nblk = 0
		yy = (0..nin - 1)
		gno = 0; gpos = 0
		es = 0; N = 1; run = 0
		sym = -1
		while (1) {
			if (gpos == 0) {
				gno++
				if (gno > nsel) { nwrd_fail("damaged bzip2 data (ran out of selectors)"); ok = 0; break; }
				gpos = 50
				g = selector[gno] + 1
			}
			gpos--
			if (pos > n + 4) { nwrd_fail("the bzip2 data end too early (truncated file)"); ok = 0; break; }
			// decode one symbol with table g
			if (bitcnt < 24) { bitbuf = bitbuf * 16777216 + src[pos] * 65536 + src[pos + 1] * 256 + src[pos + 2]; pos = pos + 3; bitcnt = bitcnt + 24; }
			v = floor(bitbuf / p2[bitcnt - TB + 1])
			v = v - 4096 * floor(v / 4096)
			l = TLEN[v + 1, g]
			if (l > 0) sym = TSYM[v + 1, g]
			else {
				l = TB + 1
				while (l <= 20) {
					v = floor(bitbuf / p2[bitcnt - l + 1])
					v = v - p2[l + 1] * floor(v / p2[l + 1])
					if (v <= LIMIT[l, g]) break
					l++
				}
				if (l > 20) { nwrd_fail("damaged bzip2 data (invalid code)"); ok = 0; break; }
				sym = PERM[v + BASE[l, g] + 1, g]
			}
			bitcnt = bitcnt - l
			bitbuf = bitbuf - p2[bitcnt + 1] * floor(bitbuf / p2[bitcnt + 1])
			if (sym <= 1) {
				// RUNA = 0 adds N, RUNB = 1 adds 2N
				es = es + (sym + 1) * N
				N = N * 2
				if (es > maxblock) { nwrd_fail("damaged bzip2 data (run too long)"); ok = 0; break; }
				continue
			}
			if (es > 0) {
				if (nblk + es > maxblock) { nwrd_fail("damaged bzip2 data (block too long)"); ok = 0; break; }
				if (nblk + es > cols(blk)) blk = (blk, J(1, max((es, cols(blk))), 0))
				blk[|nblk + 1 \ nblk + es|] = J(1, es, seqtounseq[yy[1] + 1])
				nblk = nblk + es
				es = 0; N = 1
			}
			if (sym == eob) break
			nn = sym - 1
			if (nn >= nin) { nwrd_fail("damaged bzip2 data (symbol)"); ok = 0; break; }
			v = yy[nn + 1]
			if (nn > 0) yy[|2 \ nn + 1|] = yy[|1 \ nn|]
			yy[1] = v
			if (nblk + 1 > maxblock) { nwrd_fail("damaged bzip2 data (block too long)"); ok = 0; break; }
			if (nblk + 1 > cols(blk)) blk = (blk, J(1, cols(blk), 0))
			nblk++
			blk[nblk] = seqtounseq[v + 1]
		}
		if (!ok) break
		if (nblk == 0 | origptr >= nblk) { nwrd_fail("damaged bzip2 data (block length or start position)"); ok = 0; break; }
		blk = blk[|1 \ nblk|]
		// inverse Burrows-Wheeler transform
		srt = order((blk', (1::nblk)), (1, 2))
		out = J(1, nblk, 0)
		idx = origptr + 1
		for (i = 1; i <= nblk; i++) {
			idx = srt[idx]
			out[i] = blk[idx]
		}
		// run-length decoding (four equal bytes are followed by a count)
		ob = J(1, nblk + 1000, 0)
		op = 0
		run = 0
		last = -1
		for (i = 1; i <= nblk; i++) {
			ch = out[i]
			if (run == 4) {
				if (op + ch > maxout - total) { nwrd_fail("the decompressed data exceed the limit of " + strofreal(maxout, "%15.0fc") + " bytes"); ok = 0; break; }
				if (op + ch + 1 > cols(ob)) ob = (ob, J(1, op + ch + 1, 0))
				if (ch > 0) ob[|op + 1 \ op + ch|] = J(1, ch, last)
				op = op + ch
				run = 0
				last = -1
				continue
			}
			if (ch == last) run++
			else { run = 1; last = ch; }
			if (op + 1 > cols(ob)) ob = (ob, J(1, cols(ob), 0))
			op++
			ob[op] = ch
		}
		if (!ok) break
		if (total + op > maxout) { nwrd_fail("the decompressed data exceed the limit of " + strofreal(maxout, "%15.0fc") + " bytes"); ok = 0; break; }
		if (op > 0) {
			ar = ob[|1 \ op|]
			// the CRC register works on bit-reversed bytes; the result is bit-reversed back
			bcrc = crc.upd(4294967295, rev[ar :+ 1])
			bcrc = crc.x32(bcrc, 4294967295)
			bcrc = nwrd_revbits(bcrc, rev)
			if (bcrc != crcstored) { nwrd_fail("checksum error: the file is damaged (bzip2 block CRC)"); ok = 0; break; }
			combined = crc.x32(mod(combined * 2, 4294967296) + floor(combined / 2147483648), bcrc)
			fbufput(C, fo, "%1bu", ar)
			total = total + op
		}
	}
	fclose(fo)
	if (!ok) return(-1)
	// nothing may follow the end of the stream except the padding bits of its last byte
	if (pos - 1 - floor(bitcnt / 8) != n) { nwrd_fail("the bzip2 file has data after the end of the compressed stream (not a plain .rda file)"); return(-1); }
	return(total)
}

// n bits (n <= 24), most significant bit first
real scalar nwrd_bz(real rowvector src, real scalar pos, real scalar bitbuf, real scalar bitcnt, real scalar n, real rowvector p2)
{
	real scalar v
	while (bitcnt < n) {
		bitbuf = bitbuf * 256 + src[pos]
		pos++
		bitcnt = bitcnt + 8
	}
	bitcnt = bitcnt - n
	v = floor(bitbuf / p2[bitcnt + 1])
	bitbuf = bitbuf - v * p2[bitcnt + 1]
	return(v)
}

real scalar nwrd_revbits(real scalar x, real rowvector rev)
{
	return(rev[mod(x, 256) + 1] * 16777216 + rev[mod(floor(x / 256), 256) + 1] * 65536 + rev[mod(floor(x / 65536), 256) + 1] * 256 + rev[floor(x / 16777216) + 1])
}

// ================================================================================================================
// 2. R serialization (XDR, versions 2 and 3)
// ================================================================================================================

// stops the reading: code 9001 = valid, but not handled here (use R); 9002 = damaged or over a limit
void nwrd_stop(real scalar code, string scalar m)
{
	st_global("NWND_MSG", m)
	_error(code)
}

class nwrd_obj {
	real scalar type, isobj
	real colvector num
	string colvector str
	real colvector sna
	pointer(class nwrd_obj scalar) colvector kids
	string colvector tags
	pointer(class nwrd_obj scalar) scalar attr
}

pointer(class nwrd_obj scalar) scalar nwrd_new(real scalar type)
{
	class nwrd_obj scalar o
	pointer(class nwrd_obj scalar) scalar p
	o = nwrd_obj()
	o.type = type
	o.isobj = 0
	o.attr = NULL
	p = &o
	return(p)
}

// character string from the bytes of an R string: strings marked latin1 (and strings that are not valid UTF-8) are converted
string scalar nwrd_utf8(string scalar s, real scalar lv)
{
	if (lv >= 64 | s == "") return(s)
	if (mod(floor(lv / 4), 2) == 1) return(ustrfrom(s, "windows-1252", 1))
	if (mod(floor(lv / 8), 2) == 1) {
		if (ustrinvalidcnt(s) > 0) return(ustrfrom(s, "windows-1252", 1))
		return(s)
	}
	if (ustrinvalidcnt(s) > 0) return(ustrfrom(s, "windows-1252", 1))
	return(s)
}

class nwrd_rds {
	real scalar fh, flen, depth, nobj, nelem, nref, maxelem
	transmorphic C
	pointer(class nwrd_obj scalar) colvector reft
	void open(), close()
	real scalar rint(), left()
	real rowvector rints()
	pointer(class nwrd_obj scalar) scalar item(), itemf(), pairlist(), vec(), altrep()
	void addref()
	string scalar charsxp()
	void need()
}

void nwrd_rds::open(string scalar fn, real scalar maxel)
{
	fh = fopen(fn, "r")
	nwrd_reg(fh)
	fseek(fh, 0, 1)
	flen = ftell(fh)
	fseek(fh, 0, -1)
	C = bufio()
	bufbyteorder(C, 1)
	depth = 0; nobj = 0; nelem = 0; nref = 0; maxelem = maxel
	reft = J(0, 1, NULL)
}

void nwrd_rds::close()
{
	fclose(fh)
}

real scalar nwrd_rds::left()
{
	return(flen - ftell(fh))
}

// at least n bytes must be left in the file
void nwrd_rds::need(real scalar n)
{
	if (n < 0 | n > left()) nwrd_stop(9002, "the R data are damaged or truncated (a length in the file is larger than the data that follow)")
}

real scalar nwrd_rds::rint()
{
	real scalar x
	need(4)
	x = fbufget(C, fh, "%4bs")
	return(x)
}

real rowvector nwrd_rds::rints(real scalar n)
{
	need(4 * n)
	nelem = nelem + n
	if (nelem > maxelem) nwrd_stop(9002, "the R data hold more elements than the limit of " + strofreal(maxelem, "%15.0fc"))
	if (n == 0) return(J(1, 0, .))
	return(fbufget(C, fh, "%4bs", 1, n))
}

void nwrd_rds::addref(pointer(class nwrd_obj scalar) scalar p)
{
	if (nref >= 1000000) nwrd_stop(9002, "too many references in the R data")
	nref++
	if (nref > rows(reft)) reft = reft \ J(max((16, rows(reft))), 1, NULL)
	reft[nref] = p
}

string scalar nwrd_rds::charsxp(real scalar flags)
{
	real scalar ln, lv
	real rowvector h
	string scalar s
	if (mod(flags, 256) != 9) nwrd_stop(9002, "damaged R data (a character string was expected)")
	lv = floor(flags / 4096)
	ln = rint()
	if (ln == -1) return("")
	need(ln)
	s = ""
	if (ln > 0) s = fread(fh, ln)
	if (strlen(s) != ln) nwrd_stop(9002, "damaged R data (truncated string)")
	return(nwrd_utf8(s, lv))
}

pointer(class nwrd_obj scalar) scalar nwrd_rds::item()
{
	return(itemf(rint()))
}

// a pairlist whose first cell has the flags fl (the cell type is LISTSXP): kids = the values, tags = the tags
pointer(class nwrd_obj scalar) scalar nwrd_rds::pairlist(real scalar fl)
{
	pointer(class nwrd_obj scalar) scalar res, a, t, v, rest
	real scalar n, f2
	res = nwrd_new(2)
	(*res).kids = J(0, 1, NULL)
	(*res).tags = J(0, 1, "")
	n = 0
	while (1) {
		nobj++
		if (nobj > 20000000) nwrd_stop(9002, "too many objects in the R data")
		if (mod(floor(fl / 512), 2)) a = itemf(rint())      // attributes of the cell: read and dropped
		t = NULL
		if (mod(floor(fl / 1024), 2)) t = itemf(rint())
		v = itemf(rint())
		n++
		(*res).kids = (*res).kids \ v
		if (t != NULL) (*res).tags = (*res).tags \ (*t).str[1]
		else (*res).tags = (*res).tags \ ""
		if (n > 5000000) nwrd_stop(9002, "damaged R data (pairlist too long)")
		f2 = rint()
		if (mod(f2, 256) == 2) { fl = f2; continue; }
		if (mod(f2, 256) == 254) break
		// dotted pair: the rest is a value of its own (kept as the last kid with an empty tag)
		rest = itemf(f2)
		(*res).kids = (*res).kids \ rest
		(*res).tags = (*res).tags \ "."
		break
	}
	return(res)
}

pointer(class nwrd_obj scalar) scalar nwrd_rds::vec(real scalar type, real scalar flags)
{
	pointer(class nwrd_obj scalar) scalar p, e
	real scalar ln, i, hi, lo, n2, k
	real rowvector w
	real colvector x, nav
	string colvector sv
	pointer(class nwrd_obj scalar) colvector kv
	string scalar s
	p = nwrd_new(type)
	ln = rint()
	if (ln == -1) {
		hi = rint(); lo = rint()
		ln = hi * 4294967296 + (lo < 0 ? lo + 4294967296 : lo)
	}
	if (ln < 0) nwrd_stop(9002, "damaged R data (negative length)")
	if (type == 10 | type == 13) {
		(*p).num = rints(ln)'
		(*p).num = editvalue((*p).num, -2147483648, .)
	}
	else if (type == 14) {
		need(8 * ln)
		nelem = nelem + ln
		if (nelem > maxelem) nwrd_stop(9002, "the R data hold more elements than the limit of " + strofreal(maxelem, "%15.0fc"))
		if (ln == 0) (*p).num = J(0, 1, .)
		else {
			k = ftell(fh)
			(*p).num = fbufget(C, fh, "%8z", 1, ln)'
			if (hasmissing((*p).num)) {
				// NA_real_ is a NaN with the payload 1954; any other non-finite number is not handled here
				fseek(fh, k, -1)
				w = fbufget(C, fh, "%4bu", 1, 2 * ln)
				x = ((*p).num)
				for (i = 1; i <= ln; i++) {
					if (x[i] >= .) {
						if (w[2 * i - 1] == 2146435072 & w[2 * i] == 1954) x[i] = .
						else nwrd_stop(9001, "the data contain a number that is NaN or infinite (not handled without R)")
					}
				}
				(*p).num = x
			}
		}
	}
	else if (type == 15) {
		need(16 * ln)
		nwrd_stop(9001, "the data contain complex numbers (not handled without R)")
	}
	else if (type == 24) {
		need(ln)
		nelem = nelem + ln
		if (nelem > maxelem) nwrd_stop(9002, "the R data hold more elements than the limit of " + strofreal(maxelem, "%15.0fc"))
		if (ln > 0) (*p).num = fbufget(C, fh, "%1bu", 1, ln)'
		else (*p).num = J(0, 1, .)
	}
	else if (type == 16) {
		need(8 * ln)
		nelem = nelem + ln
		if (nelem > maxelem) nwrd_stop(9002, "the R data hold more elements than the limit of " + strofreal(maxelem, "%15.0fc"))
		sv = J(ln, 1, "")
		nav = J(ln, 1, 0)
		for (i = 1; i <= ln; i++) {
			w = fbufget(C, fh, "%4bs", 1, 2)
			if (mod(w[1], 256) != 9) nwrd_stop(9002, "damaged R data (a character string was expected)")
			if (w[2] == -1) nav[i] = 1
			else {
				if (w[2] < 0 | w[2] > left()) nwrd_stop(9002, "damaged R data (truncated string)")
				if (w[2] > 0) {
					s = fread(fh, w[2])
					if (strlen(s) != w[2]) nwrd_stop(9002, "damaged R data (truncated string)")
					sv[i] = nwrd_utf8(s, floor(w[1] / 4096))
				}
			}
		}
		(*p).str = sv
		(*p).sna = nav
	}
	else {
		// VECSXP, EXPRSXP
		need(4 * ln)
		nelem = nelem + ln
		if (nelem > maxelem) nwrd_stop(9002, "the R data hold more elements than the limit of " + strofreal(maxelem, "%15.0fc"))
		kv = J(ln, 1, NULL)
		for (i = 1; i <= ln; i++) kv[i] = itemf(rint())
		(*p).kids = kv
	}
	return(p)
}

// ALTREP objects (R >= 3.5): compact integer / real sequences, deferred strings and wrappers are expanded; others are not handled
pointer(class nwrd_obj scalar) scalar nwrd_rds::altrep()
{
	pointer(class nwrd_obj scalar) scalar info, state, att, p, x
	string scalar cls
	real scalar n, st, inc, i
	info = itemf(rint())
	state = itemf(rint())
	att = itemf(rint())
	if ((*info).type != 2 | rows((*info).kids) < 1) nwrd_stop(9002, "damaged R data (ALTREP info)")
	cls = (*(*info).kids[1]).str[1]
	if (cls == "compact_intseq" | cls == "compact_realseq") {
		if ((*state).type != 14 | rows((*state).num) != 3) nwrd_stop(9002, "damaged R data (compact sequence)")
		n = (*state).num[1]; st = (*state).num[2]; inc = (*state).num[3]
		if (n < 0 | n != floor(n)) nwrd_stop(9002, "damaged R data (compact sequence length)")
		nelem = nelem + n
		if (nelem > maxelem) nwrd_stop(9002, "the R data hold more elements than the limit of " + strofreal(maxelem, "%15.0fc"))
		p = nwrd_new(cls == "compact_intseq" ? 13 : 14)
		(*p).num = st :+ inc * (0::(n - 1))
		if (n == 0) (*p).num = J(0, 1, .)
	}
	else if (substr(cls, 1, 5) == "wrap_") {
		if ((*state).type != 2 | rows((*state).kids) < 1) nwrd_stop(9002, "damaged R data (wrapper)")
		p = (*state).kids[1]
	}
	else if (cls == "deferred_string") {
		if ((*state).type != 2 | rows((*state).kids) < 1) nwrd_stop(9002, "damaged R data (deferred string)")
		x = (*state).kids[1]
		if ((*x).type != 13) nwrd_stop(9001, "the data contain a deferred string of numbers (not handled without R)")
		p = nwrd_new(16)
		(*p).str = strofreal((*x).num, "%15.0f")
		(*p).sna = ((*x).num :>= .)
		(*p).str = ((*p).sna :* J(rows((*x).num), 1, "")) + ((1 :- (*p).sna) :* J(1, 1, 1)) * J(0, 0, "")
	}
	else nwrd_stop(9001, "the data contain an ALTREP object of class " + cls + " (not handled without R)")
	if (att != NULL & (*att).type == 2) (*p).attr = att
	return(p)
}

pointer(class nwrd_obj scalar) scalar nwrd_rds::itemf(real scalar flags)
{
	real scalar type, k, ix, locked, i
	pointer(class nwrd_obj scalar) scalar p, q, r
	string scalar s
	real rowvector w
	type = mod(flags, 256)
	nobj++
	if (nobj > 20000000) nwrd_stop(9002, "too many objects in the R data")
	if (type == 254) return(NULL)
	if (type == 242 | type == 241 | type == 253 | type == 252 | type == 251 | type == 250) {
		p = nwrd_new(4)
		(*p).str = ("special")
		return(p)
	}
	if (type == 255) {
		ix = floor(flags / 256)
		if (ix == 0) ix = rint()
		if (ix < 1 | ix > nref) nwrd_stop(9002, "damaged R data (invalid reference)")
		return(reft[ix])
	}
	depth++
	if (depth > 200) nwrd_stop(9002, "the R data are nested too deeply")
	if (type == 1) {
		r = itemf(rint())
		p = nwrd_new(1)
		(*p).str = (*r).str[1] \ ""
		(*p).str = (*p).str[1]
		addref(p)
	}
	else if (type == 247 | type == 248 | type == 249) {
		// persistent name, package, namespace: a string vector (int 0, length, strings)
		k = rint()
		ix = rint()
		if (ix < 0 | ix > 1000) nwrd_stop(9002, "damaged R data (reference name)")
		p = nwrd_new(type == 247 ? 16 : 4)
		(*p).str = J(max((ix, 1)), 1, "")
		for (i = 1; i <= ix; i++) { r = itemf(rint()); }
		addref(p)
	}
	else if (type == 4) {
		locked = rint()
		p = nwrd_new(4)
		(*p).str = ("env")
		addref(p)
		r = itemf(rint())
		r = itemf(rint())
		r = itemf(rint())
		r = itemf(rint())
	}
	else if (type == 2) {
		p = pairlist(flags)
	}
	else if (type == 9) {
		p = nwrd_new(16)
		(*p).str = charsxp(flags)
		(*p).sna = 0
	}
	else if (type == 10 | type == 13 | type == 14 | type == 15 | type == 16 | type == 19 | type == 20 | type == 24) {
		p = vec(type, flags)
		if (mod(floor(flags / 256), 2)) (*p).isobj = 1
		if (mod(floor(flags / 512), 2)) {
			q = itemf(rint())
			if (q == NULL | (*q).type != 2) nwrd_stop(9002, "damaged R data (attributes)")
			(*p).attr = q
		}
	}
	else if (type == 25) {
		p = nwrd_new(25)
		if (mod(floor(flags / 512), 2)) {
			q = itemf(rint())
			(*p).attr = q
		}
		nwrd_stop(9001, "the data contain an S4 object (not handled without R)")
	}
	else if (type == 238) {
		p = altrep()
	}
	else if (type == 22 | type == 23) {
		p = nwrd_new(type)
		addref(p)
		if (type == 22) { r = itemf(rint()); r = itemf(rint()); }
		if (mod(floor(flags / 512), 2)) r = itemf(rint())
	}
	else if (type == 3 | type == 5 | type == 6 | type == 7 | type == 8 | type == 17 | type == 21) {
		nwrd_stop(9001, "the data contain code or a language object (SEXP type " + strofreal(type) + "); not handled without R")
	}
	else nwrd_stop(9002, "damaged R data (unknown SEXP type " + strofreal(type) + ")")
	depth--
	return(p)
}

// the file as a list of named objects (the pairlist of save()), or the single object of saveRDS()
// returns: a pairlist object (tags = object names)
pointer(class nwrd_obj scalar) scalar nwrd_readrda(string scalar fn, real scalar maxel)
{
	class nwrd_rds scalar r
	string scalar hd
	real scalar ver, ne, fl
	pointer(class nwrd_obj scalar) scalar res
	r.open(fn, maxel)
	if (r.left() < 14) { r.close(); nwrd_stop(9002, "the decompressed data are too short to be an R file"); }
	hd = fread(r.fh, 5)
	if (hd != "RDX2" + char(10) & hd != "RDX3" + char(10)) { r.close(); nwrd_stop(9002, "not an R data file (the .rda header RDX2/RDX3 is missing)"); }
	hd = fread(r.fh, 2)
	if (hd != "X" + char(10)) { r.close(); nwrd_stop(9001, "the R data are not in the XDR format (not handled without R)"); }
	ver = r.rint()
	(void) r.rint()
	(void) r.rint()
	if (ver != 2 & ver != 3) { r.close(); nwrd_stop(9001, "R serialization version " + strofreal(ver) + " is not handled without R"); }
	if (ver == 3) {
		ne = r.rint()
		if (ne < 0 | ne > 64) { r.close(); nwrd_stop(9002, "damaged R data (encoding name)"); }
		if (ne > 0) hd = fread(r.fh, ne)
	}
	fl = r.rint()
	if (mod(fl, 256) != 2) { r.close(); nwrd_stop(9002, "damaged R data (an .rda file holds a list of named objects)"); }
	res = r.pairlist(fl)
	r.close()
	return(res)
}

// ================================================================================================================
// 3. igraph objects -> csv tables (the tables of nwnetworkdata_convert.R)
// ================================================================================================================

// the value of the attribute nm of an object, or NULL
pointer(class nwrd_obj scalar) scalar nwrd_getattr(pointer(class nwrd_obj scalar) scalar o, string scalar nm)
{
	pointer(class nwrd_obj scalar) scalar a
	real scalar i
	a = (*o).attr
	if (a == NULL) return(NULL)
	for (i = 1; i <= rows((*a).kids); i++) {
		if ((*a).tags[i] == nm) return((*a).kids[i])
	}
	return(NULL)
}

string colvector nwrd_names(pointer(class nwrd_obj scalar) scalar o)
{
	pointer(class nwrd_obj scalar) scalar nm
	nm = nwrd_getattr(o, "names")
	if (nm == NULL) return(J(0, 1, ""))
	if ((*nm).type != 16) return(J(0, 1, ""))
	return((*nm).str)
}

real scalar nwrd_isinherit(pointer(class nwrd_obj scalar) scalar o, string scalar cls)
{
	pointer(class nwrd_obj scalar) scalar c
	c = nwrd_getattr(o, "class")
	if (c == NULL) return(0)
	if ((*c).type != 16) return(0)
	return(any((*c).str :== cls))
}

// unique values: u = the sorted unique strings, id[i] = row of u that holds s[i]
void nwrd_uniq(string colvector s, string colvector u, real colvector id)
{
	real colvector p, first
	string colvector ss
	if (rows(s) == 0) { u = J(0, 1, ""); id = J(0, 1, .); return; }
	p = order(s, 1)
	ss = s[p]
	first = J(rows(ss), 1, 1)
	if (rows(ss) > 1) first[|2 \ rows(ss)|] = (ss[|2 \ rows(ss)|] :!= ss[|1 \ rows(ss) - 1|])
	u = ss[selectindex(first)]
	id = J(rows(s), 1, .)
	id[p] = runningsum(first)
}

// the replacement of every character that is not a letter, digit or _ (done on the bytes): see above
string scalar nwrd_srmod(string scalar s)
{
	real rowvector b, bad
	b = ascii(s)
	if (cols(b) == 0) return(s)
	if (max(b) > 127) {
		s = ustrnormalize(s, "nfd")
		s = ustrregexra(s, "[\x{0300}-\x{036F}]", "")
		s = subinstr(s, "ß", "ss"); s = subinstr(s, "æ", "ae"); s = subinstr(s, "Æ", "AE"); s = subinstr(s, "œ", "oe"); s = subinstr(s, "Œ", "OE")
		s = subinstr(s, "ø", "o"); s = subinstr(s, "Ø", "O"); s = subinstr(s, "đ", "d"); s = subinstr(s, "Đ", "D"); s = subinstr(s, "ł", "l"); s = subinstr(s, "Ł", "L")
		b = ascii(s)
	}
	bad = !((b :>= 48 :& b :<= 57) :| (b :>= 65 :& b :<= 90) :| (b :>= 97 :& b :<= 122) :| (b :== 95))
	b = b :* (1 :- bad) + 95 :* bad
	return(invtokens(char(b), ""))
}

// nwnetworkdata_convert.R: .sanit(x, prefix, maxlen, taken): valid, unique names; NA or "" -> prefix
string colvector nwrd_sanit(string colvector x, real colvector na, string scalar prefix, real scalar maxlen, string colvector taken)
{
	string colvector u, s, res, uu
	real colvector id, bad, p, first, dup, isn
	real scalar i, k, n
	string scalar cand, suf
	transmorphic A
	n = rows(x)
	if (n == 0) return(J(0, 1, ""))
	nwrd_uniq(x, u, id)
	uu = u
	for (i = 1; i <= rows(u); i++) uu[i] = nwrd_srmod(u[i])
	s = uu[id]
	bad = (s :== "") :| na
	if (any(bad)) s[selectindex(bad)] = J(sum(bad), 1, prefix)
	isn = (substr(s, 1, 1) :>= "0") :& (substr(s, 1, 1) :<= "9")
	if (any(isn)) s[selectindex(isn)] = prefix :+ s[selectindex(isn)]
	s = substr(s, 1, maxlen)
	// unique already (and none taken)? then nothing to do
	nwrd_uniq(s, u, id)
	dup = (rows(u) < n)
	if (!dup & rows(taken) > 0) {
		for (i = 1; i <= rows(taken); i++) if (any(s :== taken[i])) { dup = 1; break; }
	}
	if (!dup) return(s)
	A = asarray_create()
	for (i = 1; i <= rows(taken); i++) asarray(A, taken[i], 1)
	res = s
	for (i = 1; i <= n; i++) {
		cand = s[i]
		k = 1
		while (asarray_contains(A, cand)) {
			k++
			suf = "_" + strofreal(k)
			cand = substr(s[i], 1, maxlen - strlen(suf)) + suf
		}
		res[i] = cand
		asarray(A, cand, 1)
	}
	return(res)
}

// .clean: line breaks and tabs -> blank
string colvector nwrd_clean(string colvector x)
{
	real colvector bad
	real scalar i, j
	string scalar t
	bad = (strpos(x, char(10)) :> 0) :| (strpos(x, char(13)) :> 0) :| (strpos(x, char(9)) :> 0)
	if (any(bad)) {
		bad = selectindex(bad)
		for (j = 1; j <= rows(bad); j++) {
			i = bad[j]
			t = x[i]
			x[i] = ustrregexra(t, "[\x{0D}\x{0A}\x{09}]+", " ")
		}
	}
	return(x)
}

// one number as R prints it with 15 significant digits: fixed notation (fixed = 1: format(, scientific = FALSE)),
// or the shorter of fixed and scientific (as.character)
string scalar nwrd_num2s(real scalar x, real scalar fixed)
{
	string scalar m, f, e, sg
	real scalar e10, sd, wf, ws, d
	if (x >= .) return("")
	if (x == 0) return("0")
	sg = ""
	if (x < 0) { sg = "-"; x = -x; }
	m = strofreal(x, "%25.14e")                       // d.dddddddddddddde+XXX
	e10 = strtoreal(substr(m, strpos(m, "e") + 1, .))
	m = substr(m, 1, strpos(m, "e") - 1)
	m = substr(m, 1, 1) + substr(m, 3, .)              // 15 digits
	while (strlen(m) > 1 & substr(m, -1, 1) == "0") m = substr(m, 1, strlen(m) - 1)
	sd = strlen(m)
	d = max((0, sd - 1 - e10))
	f = strtrim(strofreal(x, "%30." + strofreal(d) + "f"))
	if (e10 > 14 & d == 0) {
		// large integers: digits and zeros
		f = m + substr("00000000000000000000000000000000000000000000", 1, max((0, e10 + 1 - sd)))
	}
	if (fixed) return(sg + f)
	e = strofreal(abs(e10))
	if (strlen(e) < 2) e = "0" + e
	wf = strlen(f)
	ws = (sd > 1 ? sd + 1 : 1) + 2 + strlen(e)
	if (wf <= ws) return(sg + f)
	return(sg + substr(m, 1, 1) + (sd > 1 ? "." + substr(m, 2, .) : "") + "e" + (e10 < 0 ? "-" : "+") + e)
}

string colvector nwrd_nums(real colvector x, real scalar fixed)
{
	string colvector s
	real colvector isint, i
	real scalar j
	s = J(rows(x), 1, "")
	if (rows(x) == 0) return(s)
	isint = (x :< .) :& (x :== floor(x)) :& (abs(x) :< 1e15)
	if (all(isint :| (x :>= .)) & fixed) {
		i = selectindex(x :< .)
		if (length(i)) s[i] = strtrim(strofreal(x[i], "%21.0f"))
		return(s)
	}
	for (j = 1; j <= rows(x); j++) {
		if (x[j] < .) s[j] = nwrd_num2s(x[j], fixed)
	}
	return(s)
}

// the type of an attribute vector as nwnetworkdata_convert.R sees it: "logical", "numeric" or "character" (factors and strings);
// an attribute of another kind (lists, dates, ...) is not handled
string scalar nwrd_rtype(pointer(class nwrd_obj scalar) scalar o, string scalar nm)
{
	pointer(class nwrd_obj scalar) scalar c
	if ((*o).type == 16) return("character")
	if ((*o).type == 10) return("logical")
	if ((*o).type == 13 | (*o).type == 14) {
		c = nwrd_getattr(o, "class")
		if (c == NULL) return("numeric")
		if (nwrd_isinherit(o, "factor") & (*o).type == 13) return("character")
		nwrd_stop(9001, "the attribute " + nm + " has the class " + (*c).str[1] + " (not handled without R)")
	}
	nwrd_stop(9001, "the attribute " + nm + " is of a type that is not handled without R (SEXP type " + strofreal((*o).type) + ")")
}

// as.character of an attribute vector: strings and NA flags
void nwrd_atomstr(pointer(class nwrd_obj scalar) scalar o, string colvector s, real colvector na)
{
	pointer(class nwrd_obj scalar) scalar lv
	string colvector lev
	real colvector i
	real scalar j
	if ((*o).type == 16) { s = (*o).str; na = (*o).sna; return; }
	na = ((*o).num :>= .)
	if ((*o).type == 10) {
		s = J(rows(na), 1, "")
		i = selectindex((*o).num :== 1)
		if (length(i)) s[i] = J(length(i), 1, "TRUE")
		i = selectindex((*o).num :== 0)
		if (length(i)) s[i] = J(length(i), 1, "FALSE")
		return
	}
	if ((*o).type == 13 & nwrd_isinherit(o, "factor")) {
		lv = nwrd_getattr(o, "levels")
		if (lv == NULL) nwrd_stop(9002, "damaged R data (factor without levels)")
		lev = (*lv).str
		s = J(rows(na), 1, "")
		for (j = 1; j <= rows(na); j++) {
			if (!na[j]) {
				if ((*o).num[j] < 1 | (*o).num[j] > rows(lev)) nwrd_stop(9002, "damaged R data (factor code)")
				s[j] = lev[(*o).num[j]]
			}
		}
		return
	}
	if ((*o).type == 13) { s = nwrd_nums((*o).num, 1); return; }
	s = nwrd_nums((*o).num, 0)
}

// .tocol
string colvector nwrd_tocol(pointer(class nwrd_obj scalar) scalar o, string scalar type)
{
	string colvector s, r
	real colvector na, i
	if (type == "logical") {
		r = J(rows((*o).num), 1, "")
		i = selectindex((*o).num :== 1)
		if (length(i)) r[i] = J(length(i), 1, "1")
		i = selectindex((*o).num :== 0)
		if (length(i)) r[i] = J(length(i), 1, "0")
		return(r)
	}
	if (type == "numeric") return(nwrd_nums((*o).num, 1))
	nwrd_atomstr(o, s, na)
	s = nwrd_clean(s)
	if (any(na)) s[selectindex(na)] = J(sum(na), 1, "")
	return(s)
}

string colvector nwrd_csvfield(string colvector s)
{
	return(char(34) :+ subinstr(s, char(34), char(34) + char(34)) :+ char(34))
}

// write the rows (string matrix rows x cols, already quoted where needed) to a csv file
void nwrd_write(string scalar fn, string rowvector head, string matrix body)
{
	real scalar fh, i
	string colvector ln
	string scalar h
	real scalar j
	(void) _unlink(fn)
	fh = fopen(fn, "w")
	nwrd_reg(fh)
	h = nwrd_csvfield(head')[1]
	for (j = 2; j <= cols(head); j++) h = h + "," + nwrd_csvfield(head')[j]
	fput(fh, h)
	if (rows(body) > 0) {
		ln = body[., 1]
		for (j = 2; j <= cols(body); j++) ln = ln :+ "," :+ body[., j]
		for (i = 1; i <= rows(ln); i = i + 5000) {
			j = min((i + 4999, rows(ln)))
			fwrite(fh, invtokens(ln[|i \ j|]', char(10)) + char(10))
		}
	}
	fclose(fh)
}

// rank of every node: two-mode: mode 1 (type FALSE) first, then mode 2, within a mode in the original order
real colvector nwrd_ranks(real colvector ty, real scalar two)
{
	real colvector ord, rk
	real scalar n
	n = rows(ty)
	if (!two) return((1::n))
	ord = order((ty, (1::n)), (1, 2))
	rk = J(n, 1, .)
	rk[ord] = (1::n)
	return(rk)
}

// the 10-element list of an igraph object: returns n, directed, from (1-based), to, the attribute lists
void nwrd_graph(pointer(class nwrd_obj scalar) scalar g, real scalar n, real scalar dir, real colvector from, real colvector to, ///
	pointer(class nwrd_obj scalar) scalar ga, pointer(class nwrd_obj scalar) scalar va, pointer(class nwrd_obj scalar) scalar ea)
{
	pointer(class nwrd_obj scalar) scalar at
	real scalar m
	if ((*g).type != 19 | rows((*g).kids) < 9) nwrd_stop(9001, "an igraph object with a layout that is not handled without R")
	if ((*(*g).kids[1]).type != 14 & (*(*g).kids[1]).type != 13) nwrd_stop(9001, "an igraph object with a layout that is not handled without R")
	if ((*(*g).kids[2]).type != 10 | rows((*(*g).kids[2]).num) != 1) nwrd_stop(9001, "an igraph object with a layout that is not handled without R")
	if (rows((*(*g).kids[1]).num) != 1) nwrd_stop(9001, "an igraph object with a layout that is not handled without R")
	n = (*(*g).kids[1]).num[1]
	dir = (*(*g).kids[2]).num[1]
	if (n < 0 | n != floor(n) | n >= .) nwrd_stop(9002, "damaged R data (number of vertices)")
	if ((*(*g).kids[3]).type != 14 & (*(*g).kids[3]).type != 13) nwrd_stop(9001, "an igraph object with a layout that is not handled without R")
	if ((*(*g).kids[4]).type != 14 & (*(*g).kids[4]).type != 13) nwrd_stop(9001, "an igraph object with a layout that is not handled without R")
	from = (*(*g).kids[3]).num
	to = (*(*g).kids[4]).num
	m = rows(from)
	if (rows(to) != m) nwrd_stop(9002, "damaged R data (edge lists of different length)")
	if (m > 0) {
		if (min(from) < 0 | min(to) < 0 | max(from) >= n | max(to) >= n | any(from :!= floor(from)) | any(to :!= floor(to)) | hasmissing(from) | hasmissing(to)) ///
			nwrd_stop(9002, "damaged R data (an edge points to a vertex that does not exist)")
	}
	at = (*g).kids[9]
	if ((*at).type != 19 | rows((*at).kids) < 4) nwrd_stop(9001, "an igraph object with a layout that is not handled without R")
	ga = (*at).kids[2]; va = (*at).kids[3]; ea = (*at).kids[4]
	if ((*ga).type != 19 & (*ga).type != 0 & (*ga).type != 2) nwrd_stop(9001, "an igraph object with a layout that is not handled without R")
	if ((*va).type != 19 | (*ea).type != 19) nwrd_stop(9001, "an igraph object with a layout that is not handled without R")
	from = from :+ 1
	to = to :+ 1
}

string matrix nwrd_i(real matrix x)
{
	return(strtrim(strofreal(x, "%21.0f")))
}

void nwrd_reg(real scalar fh)
{
	st_global("NWND_FHS", st_global("NWND_FHS") + " " + strofreal(fh))
}

void nwrd_cleanup()
{
	string rowvector t
	real scalar i
	t = tokens(st_global("NWND_FHS"))
	for (i = 1; i <= cols(t); i++) (void) _fclose(strtoreal(t[i]))
	st_global("NWND_FHS", "")
}

void nwrd_conv(string scalar obj, pointer(class nwrd_obj scalar) scalar o, string scalar outdir)
{
	pointer(class nwrd_obj scalar) colvector units
	pointer(class nwrd_obj scalar) scalar g, ga, va, ea, vo, eo
	string scalar kind, netname, vatt, eatt, gname, tp
	string colvector vaN, vaT, eaN, eaT, vs, es, vnm, enm, nmv, lab, reserved, tmpS, tmpL
	real colvector from, to, ty, tyna, el1, el2, rk, ord, wt, key, pa, pb, pv, p, sw, keepm, offd, na, ids, nameNA, nameidx
	real scalar n, dir, m, k, nu, i, j, jj, two, two_ok, weighted, hasname, multi, loops, nloops, npairs, npairsl, niso, nlab
	string matrix ED, ND, IX, AT, ndk, edk
	string rowvector edhead, ndhead
	real scalar anyna, t1, pos, totn, totm, rn, rm
	real colvector tmpR, info, ukey, first
	string colvector tcol

	if (nwrd_isinherit(o, "igraph")) {
		units = o
		kind = "igraph"
	}
	else if ((*o).type == 19 & rows((*o).kids) > 0) {
		for (k = 1; k <= rows((*o).kids); k++) {
			if (!nwrd_isinherit((*o).kids[k], "igraph")) nwrd_stop(9001, "the object " + obj + " is a list that holds something other than igraph objects (not handled without R)")
		}
		units = (*o).kids
		kind = "list_of_igraph"
	}
	else nwrd_stop(9001, "the object " + obj + " is neither an igraph object nor a list of igraph objects (not handled without R)")
	nu = rows(units)

	// ---- pass 1: attribute names and types over all networks ----
	vaN = J(0, 1, ""); vaT = J(0, 1, ""); eaN = J(0, 1, ""); eaT = J(0, 1, "")
	totn = 0; totm = 0
	for (k = 1; k <= nu; k++) {
		nwrd_graph(units[k], n, dir, from, to, ga, va, ea)
		m = rows(from)
		totn = totn + n; totm = totm + m
		vnm = nwrd_names(va)
		enm = nwrd_names(ea)
		if (rows(vnm) != rows((*va).kids) | rows(enm) != rows((*ea).kids)) nwrd_stop(9001, "an igraph object whose attributes are not named (not handled without R)")
		for (j = 1; j <= rows(vnm); j++) {
			if (rows((*(*va).kids[j]).num) != n & rows((*(*va).kids[j]).str) != n) nwrd_stop(9001, "a vertex attribute whose length is not the number of vertices (not handled without R)")
			if ((*(*va).kids[j]).type != 16 & rows((*(*va).kids[j]).num) != n) nwrd_stop(9001, "a vertex attribute whose length is not the number of vertices (not handled without R)")
			if (vnm[j] == "name") continue
			tp = nwrd_rtype((*va).kids[j], vnm[j])
			jj = selectindex(vaN :== vnm[j])
			if (length(jj) == 0) { vaN = vaN \ vnm[j]; vaT = vaT \ tp; }
			else if (vaT[jj[1]] != tp) vaT[jj[1]] = "character"
		}
		for (j = 1; j <= rows(enm); j++) {
			if ((*(*ea).kids[j]).type != 16 & rows((*(*ea).kids[j]).num) != m) nwrd_stop(9001, "an edge attribute whose length is not the number of edges (not handled without R)")
			if ((*(*ea).kids[j]).type == 16 & rows((*(*ea).kids[j]).str) != m) nwrd_stop(9001, "an edge attribute whose length is not the number of edges (not handled without R)")
			tp = nwrd_rtype((*ea).kids[j], enm[j])
			jj = selectindex(eaN :== enm[j])
			if (length(jj) == 0) { eaN = eaN \ enm[j]; eaT = eaT \ tp; }
			else if (eaT[jj[1]] != tp) eaT[jj[1]] = "character"
		}
	}
	reserved = ("nd_elem", "nd_id", "nd_order", "nd_label", "nd_name", "nd_from", "nd_to", "nd_mode")'
	vs = J(0, 1, ""); es = J(0, 1, "")
	if (rows(vaN)) vs = nwrd_sanit(vaN, J(rows(vaN), 1, 0), "v", 32, reserved)
	if (rows(eaN)) es = nwrd_sanit(eaN, J(rows(eaN), 1, 0), "e", 32, reserved)

	// ---- pass 2: the tables ----
	ndhead = ("nd_elem", "nd_id", "nd_order", "nd_label", "nd_name", "nd_mode", vs')
	edhead = ("nd_elem", "nd_from", "nd_to", es')
	ND = J(totn, cols(ndhead), "")
	ED = J(totm, cols(edhead), "")
	rn = 0; rm = 0
	IX = J(0, 26, "")
	for (k = 1; k <= nu; k++) {
		g = units[k]
		nwrd_graph(g, n, dir, from, to, ga, va, ea)
		m = rows(from)
		vnm = nwrd_names(va)
		enm = nwrd_names(ea)
		// two-mode: logical vertex attribute "type", every edge joins the two types
		ty = J(n, 1, 0); tyna = J(n, 1, 0); two = 0; two_ok = 1
		jj = selectindex(vnm :== "type")
		if (length(jj)) {
			vo = (*va).kids[jj[1]]
			if ((*vo).type == 10) {
				tyna = ((*vo).num :>= .)
				ty = ((*vo).num :== 1)
				if (m > 0) {
					na = tyna[from] :| tyna[to]
					sw = (ty[from] :!= ty[to]) :| na
					if (any(!sw)) two_ok = 0
					else if (any(na)) two_ok = .
				}
				two = (two_ok == 1)
			}
		}
		if (!dir) { el1 = rowmin((from, to)); el2 = rowmax((from, to)); }
		else { el1 = from; el2 = to; }
		if (two & m > 0) {
			sw = ty[el1]
			p = selectindex(sw)
			if (length(p)) { tmpR = el1[p]; el1[p] = el2[p]; el2[p] = tmpR; }
		}
		rk = nwrd_ranks(ty + 2 * tyna, two)
		ord = (1::n)
		if (two) ord = order(rk, 1)
		weighted = 0
		jj = selectindex(enm :== "weight")
		wt = J(m, 1, 1)
		if (length(jj)) {
			eo = (*ea).kids[jj[1]]
			if (((*eo).type == 13 | (*eo).type == 14) & nwrd_getattr(eo, "class") == NULL) { weighted = 1; wt = (*eo).num; }
		}
		// labels
		hasname = any(vnm :== "name")
		nameNA = J(n, 1, 0)
		if (hasname) {
			jj = selectindex(vnm :== "name")
			nwrd_atomstr((*va).kids[jj[1]], nmv, nameNA)
			nmv = nwrd_clean(nmv)
			lab = nwrd_sanit(nmv, nameNA, "n", 28, J(0, 1, ""))
			if (any(nameNA)) {
				p = selectindex(nameNA)
				lab[p] = "n" :+ nwrd_i(p)
							}
			lab = nwrd_sanit(lab, J(n, 1, 0), "n", 28, J(0, 1, ""))
		}
		else {
			nmv = J(n, 1, "")
			lab = "n" :+ nwrd_i((1::n))
		}
		// node table (in the order of the Stata nodes)
		ndk = J(n, cols(ndhead), "")
		ndk[., 1] = J(n, 1, nwrd_i(k))
		ndk[., 2] = nwrd_i(ord)
		ndk[., 3] = nwrd_i((1::n))
		ndk[., 4] = nwrd_csvfield(lab[ord])
		if (hasname) {
			ndk[., 5] = nwrd_csvfield(nmv[ord])
			if (any(nameNA)) { p = selectindex(nameNA[ord]); if (length(p)) ndk[p, 5] = J(length(p), 1, ""); }
		}
		else ndk[., 5] = J(n, 1, char(34) + char(34))
		if (two) ndk[., 6] = nwrd_i(2 :* ty[ord] :+ (1 :- ty[ord]))
		else ndk[., 6] = J(n, 1, "0")
						for (j = 1; j <= rows(vaN); j++) {
			jj = selectindex(vnm :== vaN[j])
			if (length(jj)) {
				tcol = nwrd_tocol((*va).kids[jj[1]], vaT[j])
				ndk[., 6 + j] = nwrd_csvfield(tcol[ord])
			}
			else ndk[., 6 + j] = J(n, 1, char(34) + char(34))
		}
		if (n > 0) ND[|rn + 1, 1 \ rn + n, cols(ndhead)|] = ndk
		rn = rn + n
		// edge table
		pa = rk[el1]; pb = rk[el2]
		edk = J(m, cols(edhead), "")
		if (m > 0) {
			edk[., 1] = J(m, 1, nwrd_i(k))
			edk[., 2] = nwrd_i(pa)
			edk[., 3] = nwrd_i(pb)
			for (j = 1; j <= rows(eaN); j++) {
				jj = selectindex(enm :== eaN[j])
				if (length(jj)) {
					tcol = nwrd_tocol((*ea).kids[jj[1]], eaT[j])
					edk[., 3 + j] = nwrd_csvfield(tcol)
				}
				else edk[., 3 + j] = J(m, 1, char(34) + char(34))
			}
		}
		if (m > 0) ED[|rm + 1, 1 \ rm + m, cols(edhead)|] = edk
		rm = rm + m
		// the line of the index table
		multi = 0; loops = 0; nloops = 0; npairs = 0; npairsl = 0
		if (m > 0) {
			key = rowmin((from, to)) * (n + 1) + rowmax((from, to))
			if (dir) key = from * (n + 1) + to
			multi = (rows(uniqrows(key)) < m)
			nloops = sum(from :== to)
			loops = (nloops > 0)
			if (any(wt :>= .)) npairs = .
			else {
				if (!dir) { key = rowmin((pa, pb)) * (n + 1) + rowmax((pa, pb)); }
				else key = pa * (n + 1) + pb
				p = order(key, 1)
				key = key[p]
				info = panelsetup(key, 1)
				pv = panelsum(wt[p], info)
				ukey = key[info[., 1]]
				keepm = (pv :!= 0)
				offd = (floor(ukey / (n + 1)) :!= ukey - floor(ukey / (n + 1)) * (n + 1))
				npairs = sum(keepm :& offd)
				npairsl = sum(keepm)
			}
		}
		ids = J(n, 1, 0)
		if (m > 0) { ids[from] = J(m, 1, 1); ids[to] = J(m, 1, 1); }
		niso = n - sum(ids)
		vatt = ""
		for (j = 1; j <= rows(vnm); j++) {
			if (vnm[j] == "name") continue
			jj = selectindex(vaN :== vnm[j])
			vatt = vatt + (vatt == "" ? "" : ";") + vs[jj[1]]
		}
		eatt = ""
		for (j = 1; j <= rows(enm); j++) {
			jj = selectindex(eaN :== enm[j])
			eatt = eatt + (eatt == "" ? "" : ";") + es[jj[1]]
		}
		gname = ""
		jj = selectindex(nwrd_names(ga) :== "name")
		if (length(jj)) {
			nwrd_atomstr((*ga).kids[jj[1]], tmpS, na)
			if (rows(tmpS) > 0) {
				tmpS = nwrd_clean(tmpS[1])
				gname = tmpS[1]
			}
		}
		netname = (kind == "igraph" ? obj : obj + "_" + nwrd_i(k))
		IX = IX \ (nwrd_csvfield(netname), nwrd_csvfield(obj), nwrd_i(kind == "igraph" ? 0 : k), nwrd_i(nu), nwrd_csvfield(kind), ///
			nwrd_i(n), nwrd_i(m), nwrd_i(dir), nwrd_i(two), nwrd_i(two_ok == 0), ///
			nwrd_i(two ? sum(!ty) : 0), nwrd_i(two ? sum(ty) : 0), nwrd_i(weighted), nwrd_i(multi), ///
			nwrd_i(loops), nwrd_i(nloops), (npairs >= . ? "" : nwrd_i(npairs)), (npairs >= . ? "" : nwrd_i(npairsl)), ///
			nwrd_i(niso), nwrd_i(sum(vnm :!= "name")), nwrd_i(rows(enm)), nwrd_i(hasname), ///
			nwrd_csvfield(vatt), nwrd_csvfield(eatt), nwrd_i(any((enm :== "time") :| (enm :== "timestamp"))), nwrd_csvfield(gname))
	}
	AT = J(0, 5, "")
	for (j = 1; j <= rows(vaN); j++) AT = AT \ (nwrd_csvfield(obj), nwrd_csvfield("node"), nwrd_csvfield(vaN[j]), nwrd_csvfield(vs[j]), nwrd_csvfield(vaT[j]))
	for (j = 1; j <= rows(eaN); j++) AT = AT \ (nwrd_csvfield(obj), nwrd_csvfield("edge"), nwrd_csvfield(eaN[j]), nwrd_csvfield(es[j]), nwrd_csvfield(eaT[j]))
		nwrd_write(outdir + "/" + obj + "_edges.csv", edhead, ED)
	nwrd_write(outdir + "/" + obj + "_nodes.csv", ndhead, ND)
	nwrd_write(outdir + "/" + obj + "_attrs.csv", ("obj", "scope", "attr", "stata", "rtype"), AT)
	// the index is written last: its presence says that the conversion is complete
	nwrd_write(outdir + "/" + obj + "_index.csv", ("net", "obj", "element", "nelem", "kind", "n", "m_igraph", "directed", "twomode", "twomode_attr_invalid", "n1", "n2", ///
		"weighted", "multi", "loops", "nloops", "npairs", "npairs_incl_loops", "nisolates", "nvattr", "neattr", "named", "vattrs", "eattrs", "temporal", "graph_name"), IX)
}

// the whole job: file -> raw R data -> tables. Stops with _error(9001 / 9002) and the message in the global NWND_MSG.
void nwrd_run(string scalar rda, string scalar raw, string scalar outdir, real scalar maxout, real scalar maxin)
{
	real scalar fh, n
	string scalar magic, obj
	pointer(class nwrd_obj scalar) scalar pl, o
	st_global("NWND_MSG", "")
	st_global("NWND_FHS", "")
	fh = fopen(rda, "r")
	nwrd_reg(fh)
	fseek(fh, 0, 1)
	n = ftell(fh)
	fseek(fh, 0, -1)
	magic = ""
	if (n >= 4) magic = fread(fh, 4)
	fclose(fh)
	if (n < 14) nwrd_stop(9002, "the file is too short to be an .rda file")
	if (n > maxin) nwrd_stop(9002, "the file is larger than the limit of " + strofreal(maxin, "%15.0fc") + " bytes")
	if (substr(magic, 1, 2) == char(31) + char(139)) {
		if (nwrd_gunzip(rda, raw, maxout, maxin) < 0) nwrd_stop(9002, st_global("NWND_MSG"))
	}
	else if (substr(magic, 1, 3) == "BZh") {
		if (nwrd_bunzip2(rda, raw, maxout, maxin) < 0) nwrd_stop(9002, st_global("NWND_MSG"))
	}
	else if (substr(magic, 1, 3) == char(253) + "7z") {
		nwrd_stop(9001, "the file is compressed with xz (not handled without R)")
	}
	else if (substr(magic, 1, 3) == "RDX") raw = rda
	else nwrd_stop(9002, "not an .rda file (unknown file type)")
	pl = nwrd_readrda(raw, 60000000)
	if (rows((*pl).kids) < 1) nwrd_stop(9002, "the .rda file holds no object")
	obj = (*pl).tags[1]
	o = (*pl).kids[1]
	if (nwrd_isinherit(o, "egor")) nwrd_stop(9001, "the object is an egor object (read with R)")
	nwrd_conv(obj, o, outdir)
	st_global("NWND_MSG", obj)
}
end
