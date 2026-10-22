#!/bin/zsh
# nwsaom test runner (macOS). Usage: cscripts/run_nwsaom_tests.sh quick|full [plugin_dir]
#   quick: the tests of the newer features and the ado checks (a few minutes) - run after every change
#   full : everything, including the RSiena regression tests (30-40 minutes) - run once in a while / before a merge
# plugin_dir: a directory with a freshly built saom_sim_macos.plugin (put on the adopath ahead of Stata's PLUS copy)
cd "$(dirname "$0")/.." || exit 1
mode=${1:-quick}
plug=${2:-}
STATA=${STATA:-/Applications/Stata/StataBE.app/Contents/MacOS/StataBE}
quick=(test_nwsaom_ado test_nwsaom_dyadcov test_nwsaom_covmiss test_nwsaom_multibeh test_nwsaom_twomode test_nwsaom_tvcov test_nwsaom_degfx test_nwsaom_cov2)
full=($quick test_nwsaom_netendow_multi test_nwsaom_native test_nwsaom_mata test_nwsaom_multiplex test_nwsaom_coev_rsiena test_nwsaom_covariates test_nwsaom_engine test_nwsaom_rsiena)
[[ $mode == full ]] && tests=($full) || tests=($quick)
tmp=$(mktemp -d)
for t in $tests; do
  { [[ -n $plug ]] && echo "adopath ++ \"$plug\""; echo "do cscripts/$t.do"; } > $tmp/run_$t.do
  $STATA -e do $tmp/run_$t.do > /dev/null 2>&1
  log=run_$t.log
  printf '%-34s PASS lines: %3s   errors: %s\n' $t "$(grep -c PASS $log)" "$(grep -E '^r\([0-9]+\)' $log | sort -u | tr '\n' ' ')"
  rm -f $log
done
rm -rf $tmp
echo "done ($mode)"
