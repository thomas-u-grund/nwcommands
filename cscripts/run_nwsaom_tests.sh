#!/bin/zsh
# nwsaom test runner (macOS). Usage: cscripts/run_nwsaom_tests.sh quick|full [plugin_dir] [jobs]
#   quick: the tests of the newer features and the ado checks (about a minute) - run after every change
#   full : everything, including the RSiena regression tests (35 minutes one after the other, about 10-15 in parallel)
# plugin_dir: a directory with a freshly built saom_sim_macos.plugin (put on the adopath ahead of Stata's PLUS copy)
# jobs: how many tests run at the same time (default 6; 1 = one after the other). The tests are independent do-files (each
#   Stata process has its own memory, frames and Mata); their logs are run_<test>.log. The threaded plugin batch uses all
#   cores in every process, so more jobs than cores/3 stop paying off.
cd "$(dirname "$0")/.." || exit 1
mode=${1:-quick}
plug=${2:-}
jobs=${3:-6}
STATA=${STATA:-/Applications/Stata/StataBE.app/Contents/MacOS/StataBE}
quick=(test_nwsaom_ado test_nwsaom_dyadcov test_nwsaom_covmiss test_nwsaom_multibeh test_nwsaom_twomode test_nwsaom_tvcov test_nwsaom_degfx test_nwsaom_cov2 test_nwsaom_timedcomp test_nwsaom_meta test_nwsaom_behsel test_nwsaom_behnet test_nwsaom_covtriad test_nwsaom_symdeg test_nwsaom_covthr test_nwsaom_tmextra test_nwsaom_strate test_nwsaom_symcov test_nwsaom_behw test_nwsaom_dyadx test_nwsaom_symnb test_nwsaom_cz2 test_nwsaom_bshape test_nwsaom_multinet test_nwsaom_tvdyad test_nwsaom_bdyn test_nwsaom_ownx test_nwsaom_behnet2 test_nwsaom_twomode_cov test_nwsaom_fixsim test_nwsaom_mnpost test_nwsaom_netfx)
# slowest first, so that the long ones start at once
full=(test_nwsaom_rsiena test_nwsaom_mata test_nwsaom_native test_nwsaom_netendow_multi test_nwsaom_coev_rsiena test_nwsaom_multiplex test_nwsaom_covariates test_nwsaom_engine $quick)
[[ $mode == full ]] && tests=($full) || tests=($quick)
tmp=$(mktemp -d)
run_one() {
  local t=$1
  { [[ -n $plug ]] && echo "adopath ++ \"$plug\""; echo "do cscripts/$t.do"; } > $tmp/run_$t.do
  $STATA -e do $tmp/run_$t.do > /dev/null 2>&1
  printf '%-34s PASS lines: %3s   errors: %s\n' $t "$(grep -c PASS run_$t.log)" "$(grep -E '^r\([0-9]+\)' run_$t.log | sort -u | tr '\n' ' ')" > $tmp/res_$t.txt
  rm -f run_$t.log
}
running=0
for t in $tests; do
  run_one $t &
  running=$((running + 1))
  if (( running >= jobs )); then wait -n 2>/dev/null || wait; running=$((running - 1)); fi
done
wait
# report in the order of the quick list first, then the rest
for t in $quick ${full:#${(~j:|:)quick}}; do [[ -f $tmp/res_$t.txt ]] && cat $tmp/res_$t.txt; done | awk '!seen[$0]++'
rm -rf $tmp
echo "done ($mode)"
