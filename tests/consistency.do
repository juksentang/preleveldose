// Reject both inconsistent examples identified in review.
capture preleveldose, beta(1) rho(-.5) b(1) r2(.5) beta1(1)
assert _rc==459
capture preleveldose, beta(.4) rho(.8) b(-.5) r2(.3) beta1(-.5)
assert _rc==459
preleveldose, beta(1) rho(-.5) b(1) r2(.5) beta1(.5)
assert r(projection_gap)==0
assert r(rho_imp)==0
assert "`r(projection_status)'"=="passed"
preleveldose, beta(.4) rho(.8) b(-.5) r2(.3) beta1(.742857)
assert abs(r(projection_gap))<=r(projection_tol)
capture preleveldose, beta(.4) rho(.8) b(-.5) r2(.3) beta1(.74)
assert _rc==459
preleveldose, beta(.4) rho(.5) b(0) r2(0) beta1(.4)
assert r(projection_gap)==0
capture preleveldose, beta(.4) rho(.5) b(0) r2(0) beta1(.5)
assert _rc==459
capture preleveldose, beta(.5) rho(.5) b(1) r2(1) beta1(1)
assert _rc==198
// A perfect auxiliary fit may still be evaluated as supplied scalar algebra.
preleveldose, beta(.5) rho(.5) b(1) r2(1)
assert "`r(projection_status)'"=="not_checked"
// Reject before rendering/overwriting; active data are preserved.
capture preleveldose, beta(1) rho(-.5) b(1) r2(.5) beta1(1) saving("tests/rejected.tex") replace
assert _rc==459
capture confirm file "tests/rejected.tex"
assert _rc==601
