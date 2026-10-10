// Preserve real user data, sort order, and estimation results during collection/export.
preserve
clear
set obs 20
generate double x = _n
generate double y = 3 + 2*x + mod(_n,3)
quietly regress y x
matrix old_b = e(b)
local old_N = e(N)
local old_cmd "`e(cmd)'"
generate byte old_sample = e(sample)
local original "tests/unrelated.dta"
quietly save `original', replace

preleveldose, beta(1) rho(-.5) b(1) r2(.5) beta1(.5)
preleveldose_collect using "tests/collection small.dta", name("Positive & baseline_1") replace
assert r(rows)==1
preleveldose, beta(-.4) rho(.8) b(-.5) r2(.3) beta1(-.4) rholo(-.2) rhohi(1.2) serho(.04) seb(.02) corr(.4)
preleveldose_collect using "tests/collection small.dta", name("Negative b (20%)")
assert r(rows)==2
preleveldose, beta(.4) rho(.5) b(0) r2(0)
preleveldose_collect using "tests/collection small.dta", name("Zero b: compatible")
preleveldose, beta(.4) rho(2) b(0) r2(0)
preleveldose_collect using "tests/collection small.dta", name("Zero b: incompatible")
preleveldose, beta(0) rho(.5) b(1) r2(.5)
preleveldose_collect using "tests/collection small.dta", name("Zero beta")
assert r(rows)==5
assert _N==20
assert x==_n
assert y==3+2*x+mod(_n,3)
assert "`e(cmd)'"=="`old_cmd'"
assert e(N)==`old_N'
mata: assert(all(st_matrix("e(b)"):==st_matrix("old_b")))
assert e(sample)==old_sample

// Duplicates and unrelated .dta files cannot be silently appended to.
preleveldose, beta(1) rho(.5) b(1) r2(.5)
capture preleveldose_collect using "tests/collection small.dta", name("Zero beta")
assert _rc==198
assert _N==20
preleveldose, beta(1) rho(.5) b(1) r2(.5)
capture preleveldose_collect using `"`original'"', name("No overwrite")
assert _rc==459
assert _N==20
quietly summarize x
capture preleveldose_collect using "tests/stale.dta", name("Stale result")
assert _rc==301

preleveldose_table using "tests/collection small.dta", saving("tests/collection_example.tex") title("Audit & robustness: 20%") label("tab:prelevel_audit") decimals(3) replace
assert r(rows)==5
assert _N==20
assert e(sample)==old_sample
mata: assert(all(st_matrix("e(b)"):==st_matrix("old_b")))
preleveldose_table using "tests/collection small.dta", saving("tests/collection_fragment.tex") replace
assert r(rows)==5
capture preleveldose_table using "tests/collection small.dta", saving("tests/collection_example.tex")
assert _rc==602
capture preleveldose_table using "tests/collection small.dta", saving("tests/collection small.dta") replace
assert _rc==198
capture preleveldose_table using "tests/collection small.dta", saving("tests/bad.tex") decimals(9)
assert _rc==198
capture preleveldose_table using "tests/collection small.dta", saving("tests/bad.tex") label("no:caption")
assert _rc==198
capture preleveldose_table using "tests/collection small.dta", saving("tests/bad.tex") title("ok") label("bad label}")
assert _rc==198
capture preleveldose_table using `"`original'"', saving("tests/collection_example.tex") replace
assert _rc==459
assert _N==20

// Confirm escaped text, readable degenerate states, and row-specific cap.
tempname fh
local amp=0
local allreal=0
local emptyset=0
local caps=0
local unavailable=0
file open `fh' using "tests/collection_example.tex", read text
file read `fh' line
while r(eof)==0 {
    if strpos(`"`line'"', char(92)+"&") local amp=1
    if strpos(`"`line'"', "All real") local allreal=1
    if strpos(`"`line'"', "Empty") local emptyset=1
    if strpos(`"`line'"', "[-0.200, 1.200]") local caps=1
    if strpos(`"`line'"', "---") local unavailable=1
    file read `fh' line
}
file close `fh'
assert `amp' & `allreal' & `emptyset' & `caps' & `unavailable'
restore
