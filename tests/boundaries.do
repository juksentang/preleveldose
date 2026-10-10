// Degenerate but valid covariance inputs, without invented significance tests.
foreach direction in -1 1 {
    preleveldose, beta(.4) rho(.8) b(-.5) r2(.3) serho(.04) seb(.02) corr(`direction')
    assert r(se_L)>=0 & r(se_U)>=0
    assert !missing(r(se_width))
}
preleveldose, beta(.4) rho(.8) b(-.5) r2(.3) serho(0) seb(0) corr(0)
assert r(se_L)==0 & r(se_U)==0 & r(se_width)==0
assert missing(r(corr_LU))
preleveldose, beta(.4) rho(.8) b(-.5) r2(.3) rholo(.6) rhohi(.6) serho(.04) seb(.02) corr(.4)
assert r(L)==r(U) & r(width)==0 & r(se_width)==0
// Near-zero is not silently set to zero.
preleveldose, beta(.4) rho(.8) b(-1e-12) r2(1e-12)
assert "`r(set_status)'"=="bounded"
assert r(width)>1e11 & !missing(r(width))
// Complete uncertainty inputs, finite values, and overflow checks.
capture preleveldose, beta(1) rho(.5) b(1) r2(.5) serho(.1) seb(.1) corr(1.1)
assert _rc==198
capture preleveldose, beta(1) rho(.5) b(1) r2(.5) serho(-.1) seb(.1) corr(0)
assert _rc==198
capture preleveldose, beta(1) rho(.5) b(1) r2(.5) serho(.a) seb(.1) corr(0)
assert _rc==198
capture preleveldose, beta(1) rho(.5) b(1) r2(0)
assert _rc==198
capture preleveldose, beta(5e199) rho(.5) b(1e200) r2(.5) beta1(1e200)
assert _rc==498
capture preleveldose, beta(1e-310) rho(.5) b(1) r2(.5)
assert _rc==498
// Compare the near-point width SE with the analytic derivative; avoid subtracting close covariances.
preleveldose, beta(1) rho(.5) b(-.5) r2(.5) rholo(.6) rhohi(.6000000001) serho(.1) seb(.01) corr(.99)
assert reldif(r(se_width),r(width)*(.01/.5))<1e-12
