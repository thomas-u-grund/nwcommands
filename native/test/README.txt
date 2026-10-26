native/test -- Stata-free tests of the native kernels of nwcommands (core)

What is here
  test_kernels.c         the test program (one file; it #includes ../nwgraph.c, so it runs the shipped kernels)
  stub/stplugin.h        stand-in for Stata's plugin interface (five SF_ functions over plain arrays)
  fixtures/golden.txt    inputs and results of every kernel, recorded from the macOS plugin through Stata
  tools/make_golden_fixtures.do   the Stata do-file that writes golden.txt (run it again only when a kernel
                         changes ON PURPOSE; see "Regenerating")
  fixtures from R        not copied here: the program reads the igraph / bmotif fixtures that the Stata cscripts
                         use (../cscripts/native370_fixture, native380_fixture, burt_valued_fixture)

Build and run (repository root)
  cc -O2 -ffp-contract=off -I native/test/stub -I native native/test/test_kernels.c -o test_kernels -lm
  ./test_kernels                       # everything, about 35 s at -O2 (the large cases take most of it)
  ./test_kernels --small               # without the large cases, under a second
  ./test_kernels --only betweenness    # cases whose name contains the text
  ./test_kernels --stress 1500         # dense random graph through the counting kernels (for sanitizer runs)
  cl /O2 /I native\test\stub /I native native\test\test_kernels.c      (MSVC, x64 Native Tools prompt)
  make -C native test                  # the same with the Makefile's compiler
Output: one PASS or FAIL line per case, a summary line, exit status 0 / 1 (a case failed) / 2 (a fixture is missing).

Comparison rules: integer-valued results are compared exactly, other numbers with a relative tolerance of
1e-9 (|a-b| <= tol * max(1, |b|)); a missing value must be missing on both sides.

Golden file format (text, whitespace separated; written by tools/make_golden_fixtures.do)
  case NAME                  start of a case
  args ALG N NTIES P1 P2 ... the argument string exactly as Mata hands it to `plugin call nwgraph_native'
  var K COUNT  v1 ... vCOUNT  the contents of variable K (1 = ego, 2 = alter, 3 = value, 4 = node value) before the call
  xs NAME VALUE TOL          expected scalar (__nwg_status, __nwg_a1 ...)
  xv K COUNT TOL v1 ...      expected contents of variable K after the call (older kernels 1, 2, 20, 21)
  xr ROWS COLS TOL1..TOLC v11 v12 ...   expected result matrix (row-major) as copied out by the FETCH call (alg 99)
  end
  "." is the missing value.

Regenerating the golden file (only when a kernel's results change on purpose, with a new NWCOMB_VERSION):
  1. adopath ++ the directory with the macOS plugin you trust (built with Stata-17-compatible tooling: make macos)
  2. from the repository root: global NWGOLD "native/test/fixtures/golden.txt"  then  do native/test/tools/make_golden_fixtures.do
  3. review the diff; a change in a number is a change in a result.

What this does NOT cover
  Stata's plugin interface on Windows and Linux (loading the .plugin, SF_vdata / SF_vstore / SF_scal_save behaviour,
  the 32-bit row index), the ado and Mata layers that call the plugin, the dialogs and the GUI, the macOS
  universal-binary / codesign step, and performance on real data.  Those are covered by cscripts/ (Stata)
  on macOS and by a manual smoke test on the other platforms.
