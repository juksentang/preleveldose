{smcl}
{* *! version 0.6 09oct2026}{...}
{title:preleveldose_ols — common-sample unweighted OLS diagnostic entry}
{p 4 4 2}
{cmd:preleveldose_ols change dose baseline [controls] [if] [in],}
[{cmd:cluster(group) iv(varname) rhobench(#) sebench(#) rholo(#) rhohi(#) reps(#) seed(#) window(#) sigma2(#) bwarn(#) level(#)}]
{p 4 4 2}
The first variable is the change in outcome, not the post-period level. Remaining
controls must be explicit numeric variables. No weights, factor notation,
time-series operators or absorbed effects are supported. An intercept is included.
The controlled design must have full column rank and positive residual degrees of freedom.
{p 4 4 2}
Locks the complete-case sample jointly across change, dose, baseline, controls
and cluster (when supplied), respecting if/in. The common control space consists
of the extra controls BEFORE adding baseline: residualizing away baseline itself
would degenerate the auxiliary projection. Estimates baseline OLS, two auxiliary
projections and controlled OLS, then calls preleveldose with full-precision moments.
Checks the projection identity and the gamma identity using the same locked sample.
{p 4 4 2}
Returns preleveldose results plus r(N_common) and r(origin)=reconstructed_ols;
can be followed immediately by preleveldose_collect. The coefficient is a reconstructed
baseline, not automatically the original author's published estimate. cluster()
adds the existing clustered gamma inference; reps() requires cluster(). No new
statistical method is introduced. With sigma2(), the variance of the baseline
residual is computed on the locked sample for the Working benchmark; sigma2 must
refer to the matching innovation process/space.
{p 4 4 2}
Original data and preexisting estimation results are restored, including on errors.
No replacement estimation result is left in e(); use returned diagnostics or collect them.
{title:Template quantities (0.6)}
{p 4 4 2}
The baseline variable is treated as the outcome's OWN baseline level, so
{cmd:r(control_type)} is own_baseline and 1+gamma is the implied persistence. For a
proxy control use {help preleveldose} with {opt proxy} and supplied moments.
{p 4 4 2}
On the locked sample the command also residualizes the change, dose, baseline (and
instrument) on the controls and computes per-cluster influence-function sums (each
observation is its own cluster without cluster()); raw sandwich, no small-sample
factor, as in the Python reference implementation. From them it passes serho/seb/corr (delta
SEs of the effect set) and seg/sebeta/corrgb (the Fieller set of g/beta) to
preleveldose. rhobench()/sebench() add the implied effect at a benchmark
persistence; the benchmark estimate is treated as uncorrelated with this window.
{p 4 4 2}
{opt iv(varname)} adds the instrumented side on the same common sample and controls
(missing values of the instrument are excluded jointly): g_IV, beta_IV (the
just-identified ratio cov(Z,dS)/cov(Z,H)), g_IV/beta_IV, Q and their Fieller sets, via
{help preleveldose_iv}. Returns r(iv_instrument). Weighted or overidentified 2SLS is
not supported; supply moments to {help preleveldose_iv} instead.
