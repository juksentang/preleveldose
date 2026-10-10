version 15.1
clear all
set more off
adopath ++ "."
set obs 1

preleveldose, beta(1) rho(-.5) b(1) r2(.5)
assert reldif(r(kappa), .75) < 1e-12
assert reldif(r(anchor_gap), .25) < 1e-12
assert reldif(r(channel_bound), .5) < 1e-12
assert "`r(set_status)'" == "bounded"

preleveldose, beta(.4) rho(.8) b(.5) r2(.3) serho(.04) seb(.02) corr(-.4)
scalar pos_L = r(L)
scalar pos_U = r(U)
scalar pos_sl = r(se_L)
scalar pos_su = r(se_U)
preleveldose, beta(-.4) rho(.8) b(-.5) r2(.3) serho(.04) seb(.02) corr(.4)
assert reldif(r(L), -pos_U) < 1e-12
assert reldif(r(U), -pos_L) < 1e-12
assert reldif(r(se_L), pos_su) < 1e-12
assert reldif(r(se_U), pos_sl) < 1e-12
assert r(dU_drhohi) == 0
assert r(dL_drhohi) == -2

preleveldose, beta(.4) rho(.5) b(0) r2(0)
assert "`r(set_status)'" == "all_real"
assert missing(r(L)) & missing(r(U)) & missing(r(width))
assert r(kappa) == 0
assert r(c_obs) == .4
preleveldose, beta(.4) rho(2) b(0) r2(0)
assert "`r(set_status)'" == "empty"
assert "`r(se_status)'" == "unavailable_zero_b"
preleveldose, beta(0) rho(.5) b(1) r2(.5)
assert missing(r(anchor_share))

capture preleveldose, beta(1) rho(.5) b(0) r2(.5)
assert _rc == 198
capture preleveldose, beta(1) rho(.5) b(1) r2(.5) serho(.1)
assert _rc == 198
capture preleveldose, beta(1) rho(.5) b(1) r2(.5) rholo(2) rhohi(1)
assert _rc == 198
capture preleveldose, beta(1) rho(.) b(1) r2(.5)
assert _rc == 198

// Machine-generated commands compare numerical outputs with Python toolkit.
do tests/reference_assertions.do
do tests/template_assertions.do
do tests/export.do
do tests/boundaries.do
do tests/collections.do
do tests/consistency.do
do tests/diagnostics.do
do tests/docx.do
do tests/ols.do
do tests/template.do
do examples/full_audit.do
do tests/install.do
display "PASS: preleveldose Stata regression checks"
