global NWERGM "/private/tmp/claude-501/-Users-tgrund-FILES-NEW-SOFTWARE-nwcommands/f80eded9-2ca1-45e7-9a6b-23ada6a895b2/scratchpad/ergm130t"
do hdr.do
do loadnet.do
do models.do
setupmodel Lazega
quietly nwergm lazega_adv, `cmd' seed(100)
file open fh using "ch22_times.csv", write replace
file write fh "impl,opt,seed,secs,iter" _n
foreach s in 12345 12346 12347 {
  foreach o in "" "mcmcsamplesize(9000)" {
    timer clear 8
    timer on 8
    quietly nwergm lazega_adv, `cmd' seed(`s') `o'
    timer off 8
    quietly timer list 8
    file write fh `"nwergm,"`o'",`s',`=r(t8)',`=e(mcmle_iterations)'"' _n
  }
}
file close fh
