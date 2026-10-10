version 15.1
preleveldose, beta(.2) rho(.6) b(-.5) r2(.3) rhohi(1)
scalar bound01 = r(channel_bound)
assert reldif(r(anchor_ratio),3)<1e-12
assert reldif(r(anchor_percent),300)<1e-12
assert r(anchor_share)!=r(anchor_ratio)
preleveldose, beta(.2) rho(.6) b(-.5) r2(.3) rhohi(2) gamma(.2) window(5) sigma2(.2) varpre(.4) bwarn(.6)
assert r(channel_bound)==bound01
assert reldif(r(working_factor),.8)<1e-12
assert reldif(r(working_excess),.4)<1e-12
assert reldif(r(working_rho),1.4)<1e-12
assert r(rho_hi)==2
assert reldif(r(rho_imp),1.2)<1e-12
assert r(weak_b)==1
assert missing(r(p_equal))
preleveldose, beta(0) rho(.5) b(0) r2(0) window(3)
assert missing(r(anchor_ratio))
assert "`r(aggregation_status)'"=="inputs_missing"
preleveldose, beta(.6) rho(.5) b(1) r2(.5) beta1(.7) gamma(.2) window(1) sigma2(1) varpre(2)
assert r(working_excess)==0
capture preleveldose, beta(.6) rho(.5) b(1) r2(.5) beta1(.7) gamma(.3)
assert _rc==459
capture preleveldose, beta(1) rho(.5) b(1) r2(.5) window(0)
assert _rc==198
capture preleveldose, beta(1) rho(.5) b(1) r2(.5) sigma2(1)
assert _rc==198
capture preleveldose, beta(1) rho(.5) b(1) r2(.5) sigma2(-1) varpre(2)
assert _rc==198
capture preleveldose, beta(1) rho(.5) b(1) r2(.5) reps(10)
assert _rc==198

preserve
clear
set obs 120
generate long group = ceil(_n/10)
generate double baseline = sin(_n*.37)+group*.02
generate double dose = cos(_n*.71)-.4*baseline
generate double control = sin(_n*.13)
generate double change = .3+.25*dose+.12*baseline-.1*control+sin(group*.7)*.25+cos(_n*.43)*.2
export delimited group baseline dose control change using "tests/bootstrap_fixture.csv", replace
quietly regress change dose baseline control, vce(cluster group)
matrix original_b = e(b)
generate byte original_sample = e(sample)
scalar expected_gamma = _b[baseline]
scalar expected_se = _se[baseline]
scalar expected_pc = ttail(e(df_r),(_b[baseline]-.2)/_se[baseline])
quietly test baseline=0
scalar expected_pe = r(p)
preleveldose_infer, baseline(baseline) rhocap(1.2)
assert reldif(r(p_equal),expected_pe)<1e-10
assert reldif(r(p_cap),expected_pc)<1e-10
assert missing(r(p_equal_wild))
local before_rng `"`c(rngstate)'"'
preleveldose_infer, baseline(baseline) rhocap(1.2) reps(99) seed(2468)
scalar pw0 = r(p_equal_wild)
scalar pwcap = r(p_cap_wild)
assert inrange(pw0,.01,1) & inrange(pwcap,.01,1)
assert `"`c(rngstate)'"'==`"`before_rng'"'
assert e(sample)==original_sample
mata: assert(all(st_matrix("e(b)"):==st_matrix("original_b")))
tempname f
file open `f' using "tests/bootstrap_results.csv", write text replace
file write `f' "gamma,se,p_equal_wild,p_cap_wild" _n
file write `f' %21.16g (expected_gamma) "," %21.16g (expected_se) "," %21.16g (pw0) "," %21.16g (pwcap) _n
file close `f'
// Record the uniform stream separately for an independent NumPy CR1 implementation.
file open `f' using "tests/bootstrap_uniforms.csv", write text replace
file write `f' "h,rep,group,u" _n
set seed 2468
forvalues h=1/2 {
    forvalues j=1/99 {
        forvalues g=1/12 {
            local u = runiform()
            file write `f' "`h',`j',`g'," %21.16g (`u') _n
        }
    }
}
file close `f'
set rngstate `before_rng'
// Derive the diagnostic moments in exactly the controlled model's sample/space.
tempname controlled
estimates store `controlled'
scalar input_beta1 = _b[dose]
quietly regress change dose control
scalar input_beta = _b[dose]
quietly regress change baseline control
scalar input_rho = 1+_b[baseline]
quietly regress dose control
predict double rd, residuals
quietly regress baseline control
predict double rs, residuals
quietly regress rd rs
scalar input_b = -_b[rs]
scalar input_r2 = e(r2)
quietly summarize rs
scalar input_varpre = r(Var)
estimates restore `controlled'
estimates drop `controlled'
preleveldose, beta(`=input_beta') rho(`=input_rho') b(`=input_b') r2(`=input_r2') beta1(`=input_beta1') gammafrom(baseline) rhohi(1.2) reps(99) seed(2468) window(5) sigma2(.2) varpre(`=input_varpre')
assert reldif(r(gamma),expected_gamma)<1e-12
assert reldif(r(p_equal),expected_pe)<1e-10
assert r(p_equal_wild)==pw0
assert r(p_cap_wild)==pwcap
preleveldose_collect using "tests/diagnostics.dta", name("Illustrative clustered OLS") replace
preleveldose_table using "tests/diagnostics.dta", saving("tests/diagnostics.tex") diagnostics title("Diagnostic audit: illustrative data") decimals(4) replace
assert e(sample)==original_sample
mata: assert(all(st_matrix("e(b)"):==st_matrix("original_b")))
// Explicit failures for unsupported estimation/inference inputs.
capture preleveldose_infer, baseline(no_such_coefficient)
assert _rc==111
quietly regress change dose baseline control
capture preleveldose_infer, baseline(baseline)
assert _rc==301
generate double aw = 1+group/12
quietly regress change dose baseline control [aw=aw], vce(cluster group)
preleveldose_infer, baseline(baseline)
capture preleveldose_infer, baseline(baseline) reps(9)
assert _rc==198
quietly regress change baseline, noconstant vce(cluster group)
preleveldose_infer, baseline(baseline) reps(9) seed(42)
assert inrange(r(p_equal_wild),.1,1)
// All-equal cluster-sign draws tie the observed absolute t statistic.
// With two clusters these draws are frequent and must count in the tail.
generate byte two_groups = 1+(group>6)
quietly regress change dose baseline control, vce(cluster two_groups)
set seed 42
local tied = 0
forvalues j=1/19 {
    local s1 = runiform()>.5
    local s2 = runiform()>.5
    local tied = `tied'+(`s1'==`s2')
}
preleveldose_infer, baseline(baseline) reps(19) seed(42)
assert r(p_equal_wild)>=(1+`tied')/20-1e-12
quietly regress change dose baseline i.group, vce(cluster group)
capture preleveldose_infer, baseline(baseline) reps(9)
assert _rc==198
restore

// Schema-1 collections remain readable and can be extended without losing rows.
preserve
use "tests/diagnostics.dta", clear
keep beta rho_obs b R2 rho_lo rho_hi kappa c_obs anchor_share anchor_gap rho_imp channel_bound L U width dU_drhohi dL_drhohi se_L se_U se_width corr_LU row_name set_status se_status
char _dta[preleveldose_schema] "1"
save "tests/legacy.dta", replace
restore
preleveldose_table using "tests/legacy.dta", saving("tests/legacy.tex") diagnostics replace
preleveldose, beta(1) rho(.5) b(.5) r2(.3)
preleveldose_collect using "tests/legacy.dta", name("New row")
assert r(rows)==2
preleveldose_table using "tests/legacy.dta", saving("tests/legacy.tex") diagnostics replace
capture preleveldose, beta(1) rho(.5) b(0) r2(0) gamma(.1)
assert _rc==459
