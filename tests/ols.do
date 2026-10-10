preserve
import delimited using "tests/bootstrap_fixture.csv", clear
replace control=. in 13
replace baseline=. in 15
replace dose=. in 17
replace change=. in 19
replace group=. in 21
generate byte common = group>=2 & _n<=110 & !missing(change,dose,baseline,control,group)
quietly regress change dose baseline control if common, vce(cluster group)
tempname held
estimates store `held'
matrix ols_original_b=e(b)
generate byte ols_original_sample=e(sample)
scalar expected_N=e(N)
scalar expected_b1=_b[dose]
scalar expected_gamma=_b[baseline]
quietly regress change dose control if common
scalar expected_beta=_b[dose]
quietly regress change baseline control if common
scalar expected_rho=1+_b[baseline]
estimates restore `held'
estimates drop `held'
preleveldose_ols change dose baseline control if group>=2 in 1/110, cluster(group)
assert r(N_common)==expected_N
assert reldif(r(beta),expected_beta)<1e-12
assert reldif(r(beta1),expected_b1)<1e-12
assert reldif(r(rho_obs),expected_rho)<1e-12
assert reldif(r(gamma),expected_gamma)<1e-12
assert "`r(origin)'"=="reconstructed_ols"
assert "`r(projection_status)'"=="passed"
assert "`r(cmd)'"=="preleveldose"
assert e(sample)==ols_original_sample
mata: assert(all(st_matrix("e(b)"):==st_matrix("ols_original_b")))
preleveldose_collect using "tests/automatic.dta", name("Reconstructed OLS") replace
preleveldose_docx using "tests/automatic.dta", saving("tests/automatic.docx") replace
assert e(sample)==ols_original_sample
preleveldose_ols change dose baseline control if common, window(5) sigma2(.2)
assert missing(r(p_equal))
assert !missing(r(working_excess))
assert e(sample)==ols_original_sample
capture preleveldose_ols change dose baseline control if common, reps(9)
assert _rc==198
generate double samebaseline=baseline
capture preleveldose_ols change dose baseline samebaseline if common, cluster(group)
assert _rc==459
assert e(sample)==ols_original_sample
mata: assert(all(st_matrix("e(b)"):==st_matrix("ols_original_b")))
restore

// Exact orthogonality must not be converted to an inconsistent rounded R2.
preserve
clear
set obs 8
generate double baseline = cond(mod(_n,2),-1,1)
generate double dose = cond(mod(ceil(_n/2),2),-1,1)
generate double change = .3*dose+.2*baseline+cond(_n<=4,-.1,.1)
preleveldose_ols change dose baseline
assert abs(r(b))<1e-12
assert r(R2)<1e-20
assert reldif(r(beta),.3)<1e-12
assert "`r(projection_status)'"=="passed"
restore
