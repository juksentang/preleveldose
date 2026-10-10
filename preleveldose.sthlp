{smcl}
{* *! version 0.6 09oct2026}{...}
{title:preleveldose -- the reporting template for pre-level dose designs}

{p 4 4 2}
Version 0.6 covers the reporting template (items 1-5) of Tang, Gong and Chen (2026),
unpublished manuscript. Targets Stata 15.1
or later; earlier releases were validated on Windows Stata 18 (see the versioned
validation logs). Accepts supplied moments; optional gammafrom() uses existing
clustered regress results. See {help preleveldose_ols} for a data entry point.

{title:Syntax}
{p 8 12 2}
{cmd:preleveldose}, {opt beta(#)} {opt rho(#)} {opt b(#)} {opt r2(#)}
[{opt rholo(#)} {opt rhohi(#)} {opt serho(#)} {opt seb(#)} {opt corr(#)}
{opt seg(#)} {opt sebeta(#)} {opt corrgb(#)}
{opt rhobench(#)} {opt sebench(#)} {opt corrbrho(#)} {opt corrbb(#)}
{opt czs(#)} {opt czh(#)} {opt czy(#)} {opt ivv(matname)}
{opt beta1(#)} {opt gamma(#)} {opt gammafrom(varname)} {opt proxy}
{opt reps(#)} {opt seed(#)} {opt window(#)} {opt sigma2(#)} {opt varpre(#)} {opt bwarn(#)}
{opt level(#)} {opt saving(filename)} {opt replace}]

{title:The template and how to read it}
{p 4 4 2}
All moments come from the same sample, weights and control space (the controls
BEFORE adding the baseline level). The items are:

{p 6 9 2}1. {cmd:r(R2)}, R-squared between the dose and the outcome's own baseline level.{p_end}
{p 6 9 2}2. {cmd:r(b)}, the exchange rate between persistence and effect; supply {opt seb()}.{p_end}
{p 6 9 2}3. {cmd:r(bound_ratio)} = channel_bound/|beta| = |R2/b|/|beta| on [0,1]: the
{bf:main reading}. Near or above one, the persistence restriction alone cannot rule
out that convergence produces the whole coefficient; well below one, it cannot
account for much of it. It is read as a magnitude, without a cut-off.{p_end}
{p 6 9 2}4. Fieller sets, with their shape, for every ratio printed: the signed
ratio g/beta with g = -R2/b ({opt seg()} {opt sebeta()} {opt corrgb()}), the implied
effect at a benchmark persistence ({opt rhobench()}), and g_IV/beta_IV and Q on
the instrumented side ({opt czs()} {opt czh()} {opt czy()} {opt ivv()}).{p_end}
{p 6 9 2}5. When the outcome's OWN baseline level is added by OLS: gamma and 1+gamma,
the implied persistence. With {opt proxy}, 1+gamma is returned in
{cmd:r(one_plus_gamma)} but is not a persistence and {cmd:r(rho_imp)} is missing.{p_end}

{p 4 4 2}
A small R2 is not a screen on its own: |R2/b| = sqrt(R2)*sd(S_pre)/sd(H_pre), so the
bound also scales with the ratio of standard deviations. Read the bound relative to
the coefficient with its Fieller set. A bounded set well below one ends the inquiry
into the least-squares channel (in an instrumented design g_IV/beta_IV must still be
read); a union of rays or the whole line says the data do not bound the ratio, and
that is the finding.

{title:Inputs}
{p 4 4 2}
beta is the coefficient of the change in outcome on the dose. rho is the
observed persistence slope. b = -Cov(H,S_pre)/Var(S_pre), and r2 is the squared
correlation of H and S_pre. Both baseline and dose variances must be positive.
Supply unrounded values; the command does not replace small b with zero.

{p 4 4 2}
rholo and rhohi specify the maintained counterfactual persistence interval,
defaulting to [0,1]. serho, seb and corr (the correlation of the estimates rho and
b) must be provided together for endpoint delta standard errors and for the Fieller
set of the implied effect. They must include the intended clustering.

{p 4 4 2}
{opt seg(#)} {opt sebeta(#)} [{opt corrgb(#)}]: standard errors of g = cov(S_pre,H)/var(H)
and beta and the correlation of the two estimates (default 0). They give the Fieller
set for the signed ratio g/beta, {cmd:r(gb_shape)}, {cmd:r(gb_lo)}, {cmd:r(gb_hi)}, and
its image under scale*|.|, {cmd:r(bound_ratio_lo)} and {cmd:r(bound_ratio_hi)}, which
is the set for bound_ratio itself (scale = max(|1-rholo|,|1-rhohi|)).

{p 4 4 2}
{opt rhobench(#)} is a benchmark persistence, e.g. from matched pre-shock windows;
the implied effect is tau = (rhobench-rho)/b. {opt sebench(#)} (default 0, a fixed
benchmark) and the correlations {opt corrbrho()} and {opt corrbb()} of the benchmark
estimate with rho and b (default 0) complete the covariance. With serho/seb/corr
the Fieller set is returned in {cmd:r(tau_shape)}, {cmd:r(tau_lo)}, {cmd:r(tau_hi)}.
Transferring a benchmark persistence is itself an assumption.

{p 4 4 2}
{opt czs(#)} {opt czh(#)} {opt czy(#)}: cov(Z,S_pre), cov(Z,H_pre) and cov(Z,S_post-S_pre)
for an instrument Z on the same sample, weights and controls (any common rescaling,
e.g. slopes on Z, is equivalent). {opt ivv(matname)} is the 4x4 covariance of the
estimates (rho_obs, czs, czh, czy), in that order. See {help preleveldose_iv}.

{p 4 4 2}
{opt level(#)} sets the Fieller confidence level (default c(level)).

{title:Results}
{p 4 4 2}
For nonzero b, observable kappa = r2*(1-rho)/b, and c_obs = beta-kappa. The
conditional channel bound is abs(r2/b)*max(abs(1-rholo),abs(1-rhohi)); on [0,1]
and on [0,2] it is abs(r2/b). The effect endpoints are the sorted values
(rholo-rho)/b and (rhohi-rho)/b; width = (rhohi-rholo)/abs(b). Raising rhohi moves
the upper endpoint for b>0 and the lower endpoint for b<0. Endpoint delta SEs do
not supply weak-denominator-robust inference; the Fieller sets do.

{p 4 4 2}
At b=0, r2 must also equal zero; the channel is zero from its covariance
representation, g=0, and bound_ratio=0. The effect set is all real when rho is in
[rholo,rhohi] and empty otherwise. Zero channel does not establish zero total bias.

{p 4 4 2}
{bf:Fieller sets.} Shapes are {cmd:bounded} ([lo,hi]), {cmd:two_rays}
((-inf,lo] U [hi,inf)) and {cmd:whole_line}; {cmd:not_computed} when the inputs were
not supplied. Stata has no infinities: a missing lo or hi of an unbounded set is
-inf or +inf. In the boundary case where the denominator's t statistic equals the
critical value exactly, the set is a single ray stored as two_rays with one missing
end. See {help preleveldose_fieller}.

{title:Control type: own baseline level versus proxy}
{p 4 4 2}
{cmd:r(control_type)} is {cmd:none}, {cmd:own_baseline} or {cmd:proxy}. gamma(#)
supplies a point coefficient; gammafrom(varname) reads it from current clustered
regress results with cluster t tests and optional wild bootstrap (see
{help preleveldose_infer}). Without {opt proxy}, the added control is the outcome's
own baseline level and rho_imp = 1+gamma = rho+b*beta1 is an implied counterfactual
persistence, read against the restriction and pre-shock benchmarks, not against
zero; with beta1() both formulas must agree within relative tolerance 1e-8.
Equation (gamma) is OLS algebra with no counterpart for 2SLS.

{p 4 4 2}
With {opt proxy} (the same share from another source or date), gamma is the
coefficient on the proxy: {cmd:r(one_plus_gamma)} = 1+gamma is reported and
labelled "not a persistence", {cmd:r(rho_imp)} is missing, beta1() is rejected
(its identity is own-baseline algebra), and the cap test p-values are missing.
Report items 1-3 computed after partialling the proxy.

{title:Secondary quantities}
{p 4 4 2}
{cmd:r(anchor_share)} = kappa/beta and {cmd:r(anchor_gap)} = kappa/beta-R2 are kept
for compatibility as secondary quantities; they are not the main
reading. {cmd:r(anchor_ratio)} and {cmd:r(anchor_percent)} are pre-0.6 names of
{cmd:r(bound_ratio)} and {cmd:r(bound_percent)}, kept as aliases.

{title:LaTeX export}
{p 4 4 2}
{cmd:saving(filename)} writes a booktabs tabular fragment with R-squared, b, the
bound ratio |R2/b|/|beta| and 1+gamma (the implied persistence; with {opt proxy}
marked with a dagger and labelled not a persistence). Use {cmd:replace} to overwrite.
Undefined values are dashes, not zeros. Collect rows with
{help preleveldose_collect} for the full template, including Fieller sets.

{title:Stored results}
{p 4 4 2}
Scalars: beta, rho_obs, b, R2, rho_lo, rho_hi, kappa, c_obs, channel_bound,
bound_ratio, bound_percent, g, gb_ratio, gb_lo, gb_hi, bound_ratio_lo,
bound_ratio_hi, rho_bench, tau_bench, tau_lo, tau_hi, g_iv, beta_iv, giv_ratio, Q,
channel_iv, bound_iv, bound_ratio_iv, giv_lo, giv_hi, givb_lo, givb_hi, Q_lo, Q_hi,
L, U, width, dU_drhohi, dL_drhohi, se_L, se_U, se_width, corr_LU, rho_imp,
one_plus_gamma, gamma, se_gamma, p_equal, p_cap, level, and the secondary/alias
scalars anchor_share, anchor_gap, anchor_ratio, anchor_percent, plus the 0.4
diagnostics (window, working_*, weak_b, bootstrap_*, projection_*).
Locals: set_status, se_status, gb_shape, tau_shape, giv_shape, givb_shape,
Q_shape, control_type, aggregation_status, inference, cluster, projection_status,
origin, latex_file. Undefined or unrequested quantities are missing.

{p 4 4 2}
{cmd:r(set_status)} is {cmd:bounded}, {cmd:all_real}, or {cmd:empty}; at b=0, L, U and
width are missing for both all_real and empty. Read set_status first.

{title:Examples}
{phang}{cmd:. preleveldose, beta(.4) rho(.8) b(-.5) r2(.3) seg(.05) sebeta(.05) corrgb(.2)}
{phang}{cmd:. preleveldose, beta(-.4) rho(.8) b(-.5) r2(.3) serho(.04) seb(.02) corr(.4) rhobench(.9)}
{phang}{cmd:. preleveldose, beta(.2) rho(.6) b(-.5) r2(.3) gamma(-.1) proxy}
{phang}{cmd:. matrix V = (.0004,0,0,0 \ 0,.0025,0,0 \ 0,0,.0016,0 \ 0,0,0,.0009)}
{phang}{cmd:. preleveldose, beta(.4) rho(.8) b(-.5) r2(.3) czs(.3) czh(.6) czy(.4) ivv(V)}
{phang}{cmd:. preleveldose, beta(1) rho(-.5) b(1) r2(.5) beta1(.5) saving("audit.tex") replace}

{title:Other diagnostics (0.4)}
{p 4 4 2}
window(p), sigma2(#), varpre(#) declare an averaging window and the Working
random-walk benchmark excess ((p^2-1)/(6p))*sigma2/varpre; no cap is changed
automatically. bwarn(#) enables a units-dependent alert when 0<abs(b)<=#; it is
not a weak-identification test. With beta1(), the command requires
beta=kappa+(1-r2)*beta1 within 1e-8+1e-6*max(abs(beta),abs(kappa),abs((1-r2)*beta1))
and returns r(projection_gap), r(projection_tol) and r(projection_status).

{title:Installation and validation}
{p 4 4 2}
{cmd:net install preleveldose, from("/absolute/path/to/stata") replace}; run
{cmd:do tests/run.do} from that directory. See README.md.

{title:See also}
{p 4 4 2}{help preleveldose_fieller}, {help preleveldose_iv}, {help preleveldose_ols},
{help preleveldose_collect}, {help preleveldose_table}, {help preleveldose_docx},
{help preleveldose_infer}.
