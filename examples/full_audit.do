version 15.1
// Run from the package directory, preferably in a fresh Stata session.
// Synthetic demonstration; these are not results from any published study.
adopath ++ "."
preserve
tempname prior controlled
capture estimates store `prior'
local had_estimates = (_rc==0)
clear
set obs 120
generate long group = ceil(_n/10)
generate double baseline = sin(_n*.37)+group*.02
generate double dose = cos(_n*.71)-.4*baseline
generate double control = sin(_n*.13)
generate double change = .3+.25*dose+.12*baseline-.1*control+sin(group*.7)*.25+cos(_n*.43)*.2
quietly regress change dose baseline control, vce(cluster group)
estimates store `controlled'
local beta1 = _b[dose]
// All observations are complete here. Real analyses must freeze the common sample.
quietly regress change dose control
local beta = _b[dose]
quietly regress change baseline control
local rho = 1+_b[baseline]
quietly regress dose control
predict double rd, residuals
quietly regress baseline control
predict double rs, residuals
quietly summarize rs
local varpre = r(Var)
quietly regress rd rs
local b = -_b[rs]
local r2 = e(r2)
estimates restore `controlled'
estimates drop `controlled'
// sigma2=.2 is an illustrative assumption, not estimated from these synthetic data.
preleveldose, beta(`beta') rho(`rho') b(`b') r2(`r2') beta1(`beta1') ///
    gammafrom(baseline) rhohi(1.2) reps(999) seed(2468) ///
    window(5) sigma2(.2) varpre(`varpre')
preleveldose_collect using "examples/full_audit.dta", name("Synthetic clustered OLS") replace
preleveldose_table using "examples/full_audit.dta", saving("examples/full_audit.tex") ///
    diagnostics title("Full diagnostic audit: synthetic example") replace
preleveldose_docx using "examples/full_audit.dta", saving("examples/full_audit.docx") ///
    title("Full diagnostic audit: synthetic example") replace
restore
if `had_estimates'  {
    estimates restore `prior'
    estimates drop `prior'
}
else ereturn clear
