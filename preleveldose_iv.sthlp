{smcl}
{* *! version 0.6 09oct2026}{...}
{title:preleveldose_iv -- the instrumented side of the template from moments}

{p 8 12 2}
{cmd:preleveldose_iv}, {opt rho(#)} {opt czs(#)} {opt czh(#)} {opt czy(#)}
[{opt v(matname)} {opt rholo(#)} {opt rhohi(#)} {opt level(#)} {opt noprint}]

{p 4 4 2}
Inputs are rho_obs and the covariances of the residualised instrument Z with the
baseline level S_pre ({opt czs}), the dose H_pre ({opt czh}) and the change
S_post-S_pre ({opt czy}), on the design's sample, weights and controls; any common
rescaling of the three (e.g. their slopes on Z) gives the same results.

{p 4 4 2}
Following Tang, Gong and Chen (2026), unpublished manuscript, the instrumented lever is
g_IV = cov(Z,S_pre)/cov(Z,H_pre). Note the sign convention: g_IV carries no minus
sign (b does), so its least-squares analogue is g = -R2/b. beta_IV = czy/czh is the
just-identified IV coefficient. Under rho_0 in [0,1] the instrumented channel
(rho_0-1) g_IV is at most |g_IV| in absolute value; r(bound_iv) is
|g_IV|*max(|1-rholo|,|1-rhohi|) and r(bound_ratio_iv) = bound_iv/|beta_IV|.
Q = (rho_obs-1) g_IV/beta_IV is the instrumented analogue of kappa/beta evaluated at
rho_obs, with the same caveat: it contains part of the effect.

{p 4 4 2}
{opt v(matname)} is the 4x4 covariance of the estimates (rho_obs, czs, czh, czy), in
that order. Fieller sets are then returned for g_IV (N=czs, D=czh), for
g_IV/beta_IV = czs/czy, and for Q (N=(rho_obs-1)czs with gradient (czs, rho_obs-1),
D=czy). See {help preleveldose_fieller} for shapes. An instrument removes the
channel only if it is uncorrelated with the outcome's baseline level;
predeterminedness does not ensure that. The least-squares lever and g_IV are
reported each against its own coefficient.

{title:Stored results}
{p 4 4 2}
r(rho_obs), r(g_iv), r(beta_iv), r(giv_ratio), r(Q), r(channel_iv), r(bound_iv),
r(bound_ratio_iv), r(giv_shape), r(giv_lo), r(giv_hi), r(givb_shape), r(givb_lo),
r(givb_hi), r(Q_shape), r(Q_lo), r(Q_hi), r(level). Shapes are not_computed without v().

{title:Tests}
{p 4 4 2}
tests/template_assertions.do runs this command, {cmd:preleveldose} with {opt czs()}
{opt czh()} {opt czy()} {opt ivv()}, and {cmd:preleveldose_ols} with {opt iv()} on
three synthetic clustered designs (tests/synthetic_iv.csv) whose Fieller sets for
g_IV/beta_IV are bounded, two rays and the whole line, and compares every returned
value with an independent NumPy calculation (tests/make_reference.py).

{title:See also}
{p 4 4 2}{help preleveldose}, {help preleveldose_ols}, {help preleveldose_fieller}.
