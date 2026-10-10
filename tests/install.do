version 15.1
local source `"`c(pwd)'"'
local oldplus `"`c(sysdir_plus)'"'
capture mkdir tests/install_plus
capture mkdir tests/install_work
sysdir set PLUS "`source'/tests/install_plus"
net install preleveldose, from("`source'") replace
cd "`source'/tests/install_work"
adopath - "."
discard
findfile preleveldose_docx.ado
findfile preleveldose_ols.ado
findfile preleveldose_infer.ado
findfile preleveldose_infer.sthlp
findfile preleveldose_collect.ado
findfile preleveldose_table.ado
findfile _preleveldose_check.ado
findfile preleveldose_fieller.ado
findfile preleveldose_iv.ado
findfile preleveldose_fieller.sthlp
findfile preleveldose_iv.sthlp
preleveldose_fieller, n(1) d(2) vn(.04) vd(.09) cov(.01)
assert "`r(shape)'"=="bounded"
preleveldose_iv, rho(.7) czs(.3) czh(-.6) czy(.12)
assert reldif(r(Q),-.75)<1e-12
preleveldose, beta(1) rho(-.5) b(1) r2(.5) beta1(.5)
preleveldose_collect using "installed.dta", name("Installed package") replace
preleveldose_table using "installed.dta", saving("installed.tex") replace
confirm file "installed.tex"
preleveldose_docx using "installed.dta", saving("installed.docx") replace
confirm file "installed.docx"
preleveldose_table using "installed.dta", saving("installed_diagnostics.tex") diagnostics replace
preserve
import delimited using "`source'/tests/bootstrap_fixture.csv", clear
preleveldose_ols change dose baseline control, cluster(group)
assert r(projection_status)=="passed"
quietly regress change dose baseline control, vce(cluster group)
preleveldose_infer, baseline(baseline) reps(9) seed(42)
assert inrange(r(p_equal_wild),.1,1)
restore
help preleveldose_collect
help preleveldose_table
help preleveldose_fieller
help preleveldose_iv
cd "`source'"
sysdir set PLUS "`oldplus'"
adopath ++ "."
display "PASS: installed commands outside source directory"
