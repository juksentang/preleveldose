{smcl}
{* *! version 0.6 09oct2026}{...}
{title:preleveldose_infer — clustered persistence tests}
{p 4 4 2}
{cmd:preleveldose_infer, baseline(varname) [rhocap(#) reps(#) seed(#)]}
{p 4 4 2}
After {cmd:regress change dose baseline controls, vce(cluster group)}, reads the
baseline coefficient gamma, its cluster SE, and e(df_r). Computes two-sided
H0: gamma=0 and upper-tail H0: gamma<=rhocap-1 using the t distribution.
The user must supply the change-outcome specification in the paper, with the
same sample, controls and weights as the diagnostic moments. The command cannot
infer that semantic meaning from variable names. Nonrejection is not proof of
no contamination. beta is a baseline estimate, not certified causal by this command.
{p 4 4 2}
Optional reps(#) performs a null-imposed, residual wild cluster bootstrap-t,
with one Rademacher sign per cluster, restricted OLS fits separately at zero and
rhocap-1, and (1+exceedances)/(reps+1) Monte Carlo p-values. The equality test
uses absolute t and the cap test uses the upper tail directly. No halving of a
two-sided bootstrap p-value is used. Tail comparisons include numerical ties
within 1e-12*max(1,abs(observed t)). Default reps(0) skips bootstrap;
seed defaults to 20260921. Choose adequate replications for substantive use.
{p 4 4 2}
Bootstrap supports unweighted regress with explicit numeric regressors only;
factors/interactions must first be generated as variables. Weighted clustered
regress results support t tests, not this bootstrap. Other estimators, omitted
baseline coefficients, nonpositive SEs, and degenerate bootstrap draws fail
explicitly. No few-cluster guarantee is claimed. Data, estimates, e(sample),
and RNG state are restored after bootstrap, including on an ordinary error.
{p 4 4 2}
Returns r(gamma), r(se_gamma), r(df_gamma), r(rho_imp), r(p_equal), r(p_cap),
r(p_equal_wild), r(p_cap_wild), r(bootstrap_reps), r(bootstrap_seed), r(cluster).
To attach results to a collected diagnostic row use {cmd:preleveldose, ... gammafrom(baseline) reps(999)}.
{p 4 4 2}
The cap test reads gamma as a persistence and therefore applies only when the added
control is the outcome's own baseline level. Called through
{cmd:preleveldose, gammafrom() proxy}, the cap p-values are set to missing.
