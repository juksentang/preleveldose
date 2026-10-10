// Run from the unpacked stata/ directory. All numbers are illustrative.
// This example does not clear or replace your active dataset.
preleveldose, beta(1) rho(-.5) b(1) r2(.5) beta1(.5)
preleveldose_collect using "examples/audit_results.dta", name("Baseline") replace

preleveldose, beta(-.4) rho(.8) b(-.5) r2(.3) beta1(-.4) rholo(-.2) rhohi(1.2) serho(.04) seb(.02) corr(.4)
preleveldose_collect using "examples/audit_results.dta", name("Alternative window")

preleveldose, beta(.4) rho(.5) b(0) r2(0)
preleveldose_collect using "examples/audit_results.dta", name("Zero b: compatible")

preleveldose_table using "examples/audit_results.dta", saving("examples/audit_table.tex") title("Pre-level dose audit") label("tab:prelevel") decimals(3) replace
