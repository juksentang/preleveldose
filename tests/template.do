// v0.6 reporting template: names, control type, error handling, collections
// and exports. Numerical parity with Python is in tests/template_assertions.do.
version 15.1

// bound_ratio is the main reading; anchor_ratio is kept as an alias.
preleveldose, beta(.2) rho(.6) b(-.5) r2(.3)
assert reldif(r(bound_ratio),3)<1e-12
assert r(bound_ratio)==r(anchor_ratio)
assert r(bound_percent)==r(anchor_percent)
assert reldif(r(g),.6)<1e-12
assert reldif(r(gb_ratio),3)<1e-12
assert "`r(gb_shape)'"=="not_computed"
assert missing(r(gb_lo)) & missing(r(gb_hi))
assert "`r(control_type)'"=="none"
assert missing(r(rho_imp)) & missing(r(one_plus_gamma))
assert "`r(giv_shape)'"=="not_computed" & missing(r(g_iv))
// g = -R2/b is zero, not undefined, at b=0; the bound ratio is then zero.
preleveldose, beta(.4) rho(.5) b(0) r2(0)
assert r(g)==0 & r(bound_ratio)==0
// Fieller set for g/beta with a precise and an imprecise coefficient.
preleveldose, beta(.4) rho(.8) b(-.5) r2(.3) seg(.05) sebeta(.05) corrgb(.2)
assert "`r(gb_shape)'"=="bounded"
assert r(gb_lo)<r(gb_ratio) & r(gb_ratio)<r(gb_hi)
assert r(bound_ratio_lo)<=r(bound_ratio) & r(bound_ratio)<=r(bound_ratio_hi)
preleveldose, beta(.4) rho(.8) b(-.5) r2(.3) seg(.05) sebeta(.5)
assert inlist("`r(gb_shape)'","two_rays","whole_line")
assert missing(r(bound_ratio_hi))
capture preleveldose, beta(.4) rho(.8) b(-.5) r2(.3) seg(.05)
assert _rc==198
capture preleveldose, beta(.4) rho(.8) b(-.5) r2(.3) seg(.05) sebeta(-.1)
assert _rc==198

// Own-baseline control: 1+gamma is the implied persistence.
preleveldose, beta(1) rho(-.5) b(1) r2(.5) beta1(.5)
assert "`r(control_type)'"=="own_baseline"
assert r(rho_imp)==0 & r(one_plus_gamma)==0
preleveldose, beta(.2) rho(.6) b(-.5) r2(.3) gamma(-.1)
assert "`r(control_type)'"=="own_baseline"
assert reldif(r(rho_imp),.9)<1e-12
// Proxy control: 1+gamma is reported but is NOT a persistence.
preleveldose, beta(.2) rho(.6) b(-.5) r2(.3) gamma(-.1) proxy
assert "`r(control_type)'"=="proxy"
assert missing(r(rho_imp))
assert reldif(r(one_plus_gamma),.9)<1e-12
assert reldif(r(gamma),-.1)<1e-12
capture preleveldose, beta(1) rho(-.5) b(1) r2(.5) beta1(.5) proxy
assert _rc==198
capture preleveldose, beta(1) rho(-.5) b(1) r2(.5) proxy
assert _rc==198
// The b=0 consistency check is own-baseline algebra and does not bind a proxy.
preleveldose, beta(1) rho(.5) b(0) r2(0) gamma(.1) proxy
assert reldif(r(one_plus_gamma),1.1)<1e-12

// Implied effect at a benchmark persistence: point value without SEs.
preleveldose, beta(.4) rho(.8) b(-.5) r2(.3) rhobench(.9)
assert reldif(r(tau_bench),-.2)<1e-12
assert "`r(tau_shape)'"=="not_computed"
preleveldose, beta(.4) rho(.8) b(-.5) r2(.3) rhobench(.9) serho(.03) seb(.02) corr(0)
assert "`r(tau_shape)'"=="bounded"
assert r(tau_lo)<=-.2 & -.2<=r(tau_hi)
capture preleveldose, beta(.4) rho(.8) b(-.5) r2(.3) sebench(.1)
assert _rc==198

// IV side from moments; errors for irrelevant instruments and bad matrices.
preleveldose_iv, rho(.7) czs(.3) czh(-.6) czy(.12)
assert reldif(r(g_iv),-.5)<1e-12
assert reldif(r(beta_iv),-.2)<1e-12
assert reldif(r(giv_ratio),2.5)<1e-12
assert reldif(r(Q),-.75)<1e-12
assert reldif(r(bound_ratio_iv),2.5)<1e-12
assert "`r(givb_shape)'"=="not_computed"
capture preleveldose_iv, rho(.7) czs(.3) czh(0) czy(.12)
assert _rc==498
matrix pld_bad = I(3)
capture preleveldose_iv, rho(.7) czs(.3) czh(-.6) czy(.12) v(pld_bad)
assert _rc==503
capture preleveldose, beta(.4) rho(.8) b(-.5) r2(.3) czs(.3) czh(-.6)
assert _rc==198
capture preleveldose, beta(.4) rho(.8) b(-.5) r2(.3) ivv(pld_bad)
assert _rc==198
capture preleveldose_fieller, n(1) d(1) vn(1) vd(1) sen(1) sed(1)
assert _rc==198
capture preleveldose_fieller, n(1) d(1) vn(1) vd(1) cov(2)
assert _rc==198

// Collections: schema 4 stores the template; proxy rows carry no persistence.
preserve
clear
set obs 5
generate double x = _n
matrix pld_iv4 = (.0004,0,0,0 \ 0,.0025,0,0 \ 0,0,.0016,0 \ 0,0,0,.0009)
preleveldose, beta(.4) rho(.8) b(-.5) r2(.3) seg(.05) sebeta(.05) corrgb(.2) beta1(.7428571428571429) ///
    rhobench(.9) serho(.03) seb(.02) corr(0) czs(.3) czh(.6) czy(.4) ivv(pld_iv4)
preleveldose_collect using "tests/template.dta", name("Own baseline, IV") replace
preleveldose, beta(.2) rho(.6) b(-.5) r2(.3) gamma(-.1) proxy seg(.05) sebeta(.5)
preleveldose_collect using "tests/template.dta", name("Proxy control")
assert r(rows)==2
assert _N==5
preleveldose_table using "tests/template.dta", saving("tests/template_table.tex") replace
preleveldose_table using "tests/template.dta", saving("tests/template_diagnostics.tex") diagnostics replace
preleveldose_docx using "tests/template.dta", saving("tests/template.docx") replace
use "tests/template.dta", clear
assert "`: char _dta[preleveldose_schema]'"=="4"
assert control_type[1]=="own_baseline" & control_type[2]=="proxy"
assert missing(rho_imp[2]) & reldif(one_plus_gamma[2],.9)<1e-12
assert bound_ratio==anchor_ratio
assert gb_shape[1]=="bounded" & givb_shape[1]!="not_computed" & Q_shape[2]=="not_computed"
restore
tempname fh
local main=0
local fieller=0
local dagger=0
local secondary=0
local old=0
file open `fh' using "tests/template_table.tex", read text
file read `fh' line
while r(eof)==0 {
    if strpos(`"`line'"', "main reading") local main=1
    if strpos(`"`line'"', "Fieller set") local fieller=1
    if strpos(`"`line'"', "dag") local dagger=1
    if strpos(`"`line'"', "secondary quantity") local secondary=1
    if strpos(`"`line'"', "anchor-share benchmark") local old=1
    file read `fh' line
}
file close `fh'
assert `main' & `fieller' & `dagger' & `secondary' & !`old'
local panelF=0
local proxynote=0
file open `fh' using "tests/template_diagnostics.tex", read text
file read `fh' line
while r(eof)==0 {
    if strpos(`"`line'"', "F. Instrumented side") local panelF=1
    if strpos(`"`line'"', "Added control: proxy, not a persistence") local proxynote=1
    file read `fh' line
}
file close `fh'
assert `panelF' & `proxynote'
// Legacy schema-3 collections migrate in memory: bound_ratio = anchor_ratio.
preserve
use "tests/template.dta", clear
drop bound_ratio bound_percent g gb_ratio gb_lo gb_hi bound_ratio_lo bound_ratio_hi one_plus_gamma rho_bench tau_bench tau_lo tau_hi g_iv beta_iv giv_ratio Q channel_iv bound_iv bound_ratio_iv giv_lo giv_hi givb_lo givb_hi Q_lo Q_hi level gb_shape tau_shape giv_shape givb_shape Q_shape control_type
replace rho_imp = . in 2
char _dta[preleveldose_schema] "3"
save "tests/template_legacy.dta", replace
restore
preleveldose_table using "tests/template_legacy.dta", saving("tests/template_legacy.tex") diagnostics replace
preleveldose, beta(1) rho(.5) b(.5) r2(.3)
preleveldose_collect using "tests/template_legacy.dta", name("New v0.6 row")
assert r(rows)==3
display "PASS: v0.6 template checks"
