// Test the actual file writer, missing-statistic display, and overwrite guard.
preleveldose, beta(1) rho(-.5) b(1) r2(.5) beta1(.5) saving("tests/table_check.tex") replace
assert r(rho_imp)==0
assert "`r(latex_file)'" == "tests/table_check.tex"
assert _N == 1
local found = 0
local header = 0
tempname fh
file open `fh' using "tests/table_check.tex", read text
file read `fh' line
while r(eof) == 0 {
    if strpos(`"`line'"', "0.5000 & 1.0000 & 0.5000 & 0.0000") local found = 1
    if strpos(`"`line'"', "widehat") local header = 1
    file read `fh' line
}
file close `fh'
assert `found' == 1
assert `header' == 1
capture preleveldose, beta(1) rho(-.5) b(1) r2(.5) saving("tests/table_check.tex")
assert _rc == 602
preleveldose, beta(0) rho(.5) b(0) r2(0) saving("tests/table_missing.tex") replace
assert missing(r(rho_imp))
assert missing(r(anchor_share))
local found = 0
file open `fh' using "tests/table_missing.tex", read text
file read `fh' line
while r(eof) == 0 {
    if strpos(`"`line'"', "0.0000 & 0.0000 & --- & ---") local found = 1
    file read `fh' line
}
file close `fh'
assert `found' == 1
capture preleveldose, beta(1) rho(.5) b(1) r2(.5) beta1(.)
assert _rc == 198
capture preleveldose, beta(1) rho(.5) b(1) r2(.5) replace
assert _rc == 198

preleveldose, beta(1) rho(.5) b(.000001) r2(.000001) saving("tests/table_small.tex") replace
assert r(b) != 0
assert "`r(set_status)'" == "bounded"
local found = 0
file open `fh' using "tests/table_small.tex", read text
file read `fh' line
while r(eof) == 0 {
    if strpos(`"`line'"', "0.0000 & 0.0000") local found = 1
    file read `fh' line
}
file close `fh'
assert `found' == 0
