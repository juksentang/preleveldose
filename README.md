# preleveldose

Stata tools for pre-level dose designs (version 0.6): a reporting template for
designs whose dose is built from baseline composition, so that the dose is
correlated with the outcome's own baseline level and mean reversion can load
onto the dose coefficient.

The package implements the method of Tang, Gong and Chen (2026), unpublished
manuscript. It targets Stata 15.1 or later.

## What it does

All moments refer to the same sample, weights and control space, where the
control space is the set of controls *before* the baseline level is added.
Write $S_{\mathrm{pre}}$ for the outcome's baseline level, $H$ for the dose,
$\beta$ for the coefficient of the change in outcome on the dose and
$\rho_{\mathrm{obs}}$ for the observed persistence slope. The template has five
items plus an instrumented side.

| Item | Quantity | Stata |
|---|---|---|
| 1 | $R^2$ between the dose and the outcome's **own** baseline level | `r(R2)` |
| 2 | $b = -\mathrm{cov}(H,S_{\mathrm{pre}})/\mathrm{var}(S_{\mathrm{pre}})$ and its standard error | `r(b)`; `seb()` as input, or computed by `preleveldose_ols` |
| 3 | The bound relative to the coefficient, $\lvert R^2/b\rvert / \lvert\beta\rvert$ (the main reading) | `r(bound_ratio)` |
| 4 | A Fieller set, with its shape, for every printed ratio | `r(gb_*)`, `r(tau_*)`, `r(giv_*)`, `r(givb_*)`, `r(Q_*)` |
| 5 | $\gamma$ and $1+\gamma$ when the outcome's own baseline level is added by OLS | `r(gamma)`, `r(one_plus_gamma)`, `r(rho_imp)`, `r(control_type)` |
| IV | $g_{\mathrm{IV}}$, $g_{\mathrm{IV}}/\beta_{\mathrm{IV}}$ and $Q$ | `r(g_iv)`, `r(giv_ratio)`, `r(Q)`, `r(bound_ratio_iv)` |

The main quantities are

$$
\text{channel bound} = \left\lvert \frac{R^2}{b} \right\rvert \max\left(\lvert 1-\rho_{\mathrm{lo}}\rvert,\ \lvert 1-\rho_{\mathrm{hi}}\rvert\right),
\qquad
\text{bound ratio} = \frac{\text{channel bound}}{\lvert\beta\rvert},
$$

where $[\rho_{\mathrm{lo}},\rho_{\mathrm{hi}}]$ is the maintained counterfactual
persistence interval (default $[0,1]$; on $[0,1]$ and on $[0,2]$ the channel bound
equals $\lvert R^2/b\rvert$). The least-squares lever is

$$
g = \frac{\mathrm{cov}(S_{\mathrm{pre}},H)}{\mathrm{var}(H)} = -\frac{R^2}{b},
$$

and its Fieller set is computed for the signed ratio $g/\beta$. On the
instrumented side, with an instrument $Z$,

$$
g_{\mathrm{IV}} = \frac{\mathrm{cov}(Z,S_{\mathrm{pre}})}{\mathrm{cov}(Z,H_{\mathrm{pre}})},
\qquad
\beta_{\mathrm{IV}} = \frac{\mathrm{cov}(Z,S_{\mathrm{post}}-S_{\mathrm{pre}})}{\mathrm{cov}(Z,H_{\mathrm{pre}})},
\qquad
Q = (\rho_{\mathrm{obs}}-1)\,\frac{g_{\mathrm{IV}}}{\beta_{\mathrm{IV}}}.
$$

At a benchmark persistence $\rho_{\mathrm{bench}}$ the implied effect is
$\tau = (\rho_{\mathrm{bench}}-\rho_{\mathrm{obs}})/b$, and the ordered effect set
has endpoints $(\rho_{\mathrm{lo}}-\rho_{\mathrm{obs}})/b$ and
$(\rho_{\mathrm{hi}}-\rho_{\mathrm{obs}})/b$, with width
$(\rho_{\mathrm{hi}}-\rho_{\mathrm{lo}})/\lvert b\rvert$.

## Installation

From GitHub:

```stata
net install preleveldose, from("https://raw.githubusercontent.com/juksentang/preleveldose/main/") replace
help preleveldose
```

For a specific release, replace `main` by the tag, for example
`https://raw.githubusercontent.com/juksentang/preleveldose/v0.6/`.

From a local copy (Windows paths may be written as `C:/path/to/preleveldose`):

```stata
net install preleveldose, from("/absolute/path/to/preleveldose") replace
help preleveldose
```

The package is not on SSC.

## Quick start

From supplied moments, with standard errors for the Fieller set of $g/\beta$:

```stata
preleveldose, beta(.4) rho(.8) b(-.5) r2(.3) seg(.05) sebeta(.05) corrgb(.2)
display r(bound_ratio)
display "`r(gb_shape)'"  " [" r(gb_lo) ", " r(gb_hi) "]"
```

From data (unweighted OLS; `change`, `dose`, `baseline`, `controls` and `region`
stand for your own variables), collected and exported:

```stata
preleveldose_ols change dose baseline controls, cluster(region)
preleveldose_collect using "audit.dta", name("Reconstructed baseline OLS") replace
preleveldose_table using "audit.dta", saving("audit.tex") diagnostics title("Diagnostic audit") replace
preleveldose_docx using "audit.dta", saving("audit.docx") title("Diagnostic audit") replace
```

## Commands

### preleveldose

The main command. It takes estimated moments and returns the whole template.

```stata
preleveldose, beta(#) rho(#) b(#) r2(#) [options]
```

Inputs: `beta()` is the coefficient of the change in outcome on the dose,
`rho()` the observed persistence slope, `b()` and `r2()` as defined above. Supply
unrounded values; a small $b$ is never replaced by zero. Baseline and dose
variances must be positive.

Key options:

- `rholo(#)`, `rhohi(#)`: maintained persistence interval, default $[0,1]$.
- `serho(#) seb(#) corr(#)`: standard errors of $\rho_{\mathrm{obs}}$ and $b$ and
  the correlation of the two estimates, supplied together; they give endpoint
  delta standard errors and, with `rhobench()`, the Fieller set of the implied
  effect. They must reflect the intended clustering.
- `seg(#) sebeta(#) [corrgb(#)]`: standard errors of $g$ and $\beta$ and their
  correlation (default 0); they give the Fieller set of $g/\beta$ and its image
  for the bound ratio.
- `rhobench(#) [sebench(#) corrbrho(#) corrbb(#)]`: benchmark persistence, for
  example from matched pre-shock windows, its standard error (default 0, a fixed
  benchmark) and its correlations with $\rho_{\mathrm{obs}}$ and $b$ (default 0).
  Transferring a benchmark persistence is itself an assumption.
- `czs(#) czh(#) czy(#) ivv(matname)`: instrumented side from moments; see
  `preleveldose_iv`.
- `beta1(#)`, `gamma(#)`, `gammafrom(varname)`, `proxy`: persistence reading
  (item 5). `beta1()` is the dose coefficient after the baseline level is added;
  `gamma()` supplies the baseline coefficient directly; `gammafrom()` reads it from
  the current clustered `regress` results, with cluster $t$ tests. `proxy`
  declares that the added control is a proxy rather than the outcome's own
  baseline level.
- `reps(#) seed(#)`: with `gammafrom()`, adds the null-imposed wild cluster
  bootstrap of `preleveldose_infer`.
- `window(#) sigma2(#) varpre(#)`: declares an averaging window $p$ and, when both
  `sigma2()` and `varpre()` are given, the random-walk benchmark excess
  $\frac{p^2-1}{6p}\,\sigma^2/\mathrm{var}_{\mathrm{pre}}$. No persistence cap is
  changed automatically.
- `bwarn(#)`: a units-dependent alert when $0<\lvert b\rvert\le$ the threshold. It is
  not a weak-identification test.
- `level(#)`: Fieller confidence level, default `c(level)`.
- `saving(filename) [replace]`: writes a booktabs tabular fragment with $R^2$, $b$,
  the bound ratio and $1+\gamma$.

Main stored results:

- Scalars: `r(beta)`, `r(rho_obs)`, `r(b)`, `r(R2)`, `r(rho_lo)`, `r(rho_hi)`,
  `r(kappa)`, `r(c_obs)`, `r(channel_bound)`, `r(bound_ratio)`,
  `r(bound_percent)`, `r(g)`, `r(gb_ratio)`, `r(gb_lo)`, `r(gb_hi)`,
  `r(bound_ratio_lo)`, `r(bound_ratio_hi)`, `r(rho_bench)`, `r(tau_bench)`,
  `r(tau_lo)`, `r(tau_hi)`, the IV scalars listed under `preleveldose_iv`,
  `r(L)`, `r(U)`, `r(width)`, `r(dU_drhohi)`, `r(dL_drhohi)`, `r(se_L)`, `r(se_U)`,
  `r(se_width)`, `r(corr_LU)`, `r(rho_imp)`, `r(one_plus_gamma)`, `r(gamma)`,
  `r(se_gamma)`, `r(p_equal)`, `r(p_cap)`, `r(level)`, and
  `r(projection_gap)`, `r(projection_tol)`.
- Locals: `r(set_status)`, `r(se_status)`, `r(gb_shape)`, `r(tau_shape)`,
  `r(giv_shape)`, `r(givb_shape)`, `r(Q_shape)`, `r(control_type)`,
  `r(aggregation_status)`, `r(inference)`, `r(cluster)`,
  `r(projection_status)`, `r(origin)`, `r(latex_file)`.
- Secondary quantities: `r(anchor_share)` $=\kappa/\beta$ and `r(anchor_gap)`
  $=\kappa/\beta - R^2$, where $\kappa = R^2(1-\rho_{\mathrm{obs}})/b$ and
  $c_{\mathrm{obs}} = \beta-\kappa$. `r(anchor_ratio)` and `r(anchor_percent)` are
  aliases of `r(bound_ratio)` and `r(bound_percent)`.

Undefined or unrequested quantities are missing.

### preleveldose_ols

A common-sample entry point from data, for unweighted OLS.

```stata
preleveldose_ols change dose baseline [controls] [if] [in], [cluster(group) iv(varname) rhobench(#) sebench(#) rholo(#) rhohi(#) reps(#) seed(#) window(#) sigma2(#) bwarn(#) level(#)]
```

The first variable is the change in outcome (not the post-period level), then the
dose, the raw baseline level and optional extra controls. Controls must be explicit
numeric variables; weights, factor notation, time-series operators and absorbed
effects are not supported. An intercept is included and the controlled design must
have full column rank.

The command locks one complete-case sample across all variables (including the
cluster variable and instrument), respecting `if` and `in`; estimates the baseline
OLS, the auxiliary projections and the controlled OLS; checks the projection and
$\gamma$ identities; and calls `preleveldose` with full-precision moments. From
per-cluster influence-function sums (raw sandwich, no small-sample factor; each
observation is its own cluster without `cluster()`) it passes `serho`/`seb`/`corr`
and `seg`/`sebeta`/`corrgb`. `iv(varname)` adds the instrumented side on the same
sample and controls through `preleveldose_iv`. `reps()` requires `cluster()`.

The baseline variable is treated as the outcome's own baseline level, so
`r(control_type)` is `own_baseline`. For a proxy control, use `preleveldose` with
`proxy` and supplied moments.

Returns all `preleveldose` results plus `r(N_common)`, `r(origin)` (=
`reconstructed_ols`) and, with `iv()`, `r(iv_instrument)`. The data and any
existing estimation results are restored. The coefficient is a reconstructed
baseline specification, not automatically an author's published estimate.

### preleveldose_iv

The instrumented side from moments.

```stata
preleveldose_iv, rho(#) czs(#) czh(#) czy(#) [v(matname) rholo(#) rhohi(#) level(#) noprint]
```

`czs`, `czh` and `czy` are the covariances of the residualised instrument $Z$ with
$S_{\mathrm{pre}}$, $H_{\mathrm{pre}}$ and $S_{\mathrm{post}}-S_{\mathrm{pre}}$; any
common rescaling (for example slopes on $Z$) gives the same results. `v(matname)` is
the $4\times 4$ covariance of the estimates $(\rho_{\mathrm{obs}}, czs, czh, czy)$, in
that order; with it, Fieller sets are returned for $g_{\mathrm{IV}}$,
$g_{\mathrm{IV}}/\beta_{\mathrm{IV}}$ and $Q$. The bound is
$\lvert g_{\mathrm{IV}}\rvert \max(\lvert 1-\rho_{\mathrm{lo}}\rvert, \lvert 1-\rho_{\mathrm{hi}}\rvert)$.

Stored results: `r(rho_obs)`, `r(g_iv)`, `r(beta_iv)`, `r(giv_ratio)`, `r(Q)`,
`r(channel_iv)`, `r(bound_iv)`, `r(bound_ratio_iv)`, `r(giv_shape)`, `r(giv_lo)`,
`r(giv_hi)`, `r(givb_shape)`, `r(givb_lo)`, `r(givb_hi)`, `r(Q_shape)`, `r(Q_lo)`,
`r(Q_hi)`, `r(level)`. Shapes are `not_computed` without `v()`.

An instrument removes the channel only if it is uncorrelated with the outcome's
baseline level; predeterminedness does not ensure that.

### preleveldose_fieller

The Fieller set for any ratio $\theta = N/D$:

$$
\left\{\theta : (N-\theta D)^2 \le z^2\,\mathrm{var}(N-\theta D)\right\}.
$$

```stata
preleveldose_fieller, n(#) d(#) vn(#) vd(#) [cov(#)] [level(#) noprint]
preleveldose_fieller, n(#) d(#) sen(#) sed(#) [corr(#)] [level(#) noprint]
```

Stored results: `r(shape)`, `r(lo)`, `r(hi)`, `r(estimate)` ($=N/D$, missing at
$D=0$), `r(den_t)` ($=D/\mathrm{se}(D)$), `r(z)`, `r(level)`, `r(num)`, `r(den)`,
`r(var_num)`, `r(var_den)`, `r(cov_numden)`, `r(cmd)`.

### preleveldose_infer

Clustered persistence tests after
`regress change dose baseline controls, vce(cluster group)`.

```stata
preleveldose_infer, baseline(varname) [rhocap(#) reps(#) seed(#)]
```

Tests $H_0:\gamma=0$ (two-sided) and $H_0:\gamma\le \rho_{\mathrm{cap}}-1$ (upper
tail) with the cluster $t$ statistic and `e(df_r)`. `reps(#)` adds a null-imposed
residual wild cluster bootstrap-$t$ with one Rademacher sign per cluster, restricted
fits at each null and $(1+\text{exceedances})/(\text{reps}+1)$ Monte Carlo p-values;
the upper tail is counted directly, not obtained by halving a two-sided p-value.
The bootstrap supports unweighted `regress` with explicit numeric regressors only.
Data, estimates, `e(sample)` and the RNG state are restored.

Stored results: `r(gamma)`, `r(se_gamma)`, `r(df_gamma)`, `r(rho_imp)`,
`r(p_equal)`, `r(p_cap)`, `r(p_equal_wild)`, `r(p_cap_wild)`,
`r(bootstrap_reps)`, `r(bootstrap_seed)`, `r(cluster)`.

The cap test reads $\gamma$ as a persistence and applies only to an own-baseline
control; with `preleveldose, gammafrom() proxy` the cap p-values are missing.

### preleveldose_collect

Saves the current `preleveldose` results as a named row of a collection.

```stata
preleveldose_collect using collection.dta, name(text) [replace]
```

Run it immediately after `preleveldose` (or `preleveldose_ols`). A missing
collection is created; an existing one is appended to, and names must be unique;
`replace` starts a new collection. Version 0.6 writes schema 4; collections in an
earlier schema are migrated in memory and fields they did not record stay missing
(`not_computed`, or `legacy_unknown` for the control type). The data, sort order
and existing `e()` results are preserved. Do not edit the collection by hand.

Stored results: `r(rows)`, `r(collection)`, `r(cmd)`.

### preleveldose_table

Exports a collection as a LaTeX table.

```stata
preleveldose_table using collection.dta, saving(filename.tex) [title(text) label(identifier) decimals(#) diagnostics replace]
```

Compact columns: specification, $R^2$, $b$, the bound ratio, the Fieller set of
$g/\beta$, $1+\gamma$ (marked with a dagger for a proxy control), the ordered effect
set and the persistence interval of that row. `diagnostics` exports six panels:
A, the four moments; B, the bound ratio with the Fieller sets of $g/\beta$ and of the
implied effect; C, the persistence reading; D, wild bootstrap p-values; E, the
aggregation benchmark and effect width; F, the instrumented side.

`decimals()` is 0 to 8 (default 4); small nonzero and very large values use
significant digits. Without `title()` the output is a fragment for an existing
`table` environment; with `title()` it is a complete floating table. The preamble
needs `\usepackage{booktabs,tabularx}`. The layout is single-page; split large
collections.

Stored results: `r(rows)`, `r(latex_file)`, `r(cmd)`.

### preleveldose_docx

Exports a collection as an editable Word report.

```stata
preleveldose_docx using collection.dta, saving(report.docx) [title(text) decimals(#) replace]
```

Writes six native Word tables (the panels of `preleveldose_table`), row-specific
restrictions, projection-check status and interpretation notes, using `putdocx`;
neither Python nor Microsoft Word is needed. An active unsaved `putdocx` document
causes an error and is never cleared, and a failed run does not overwrite an
existing output file.

Stored results: `r(rows)`, `r(docx_file)`, `r(cmd)`.

## Reading the output

- **Read the bound relative to the coefficient with its Fieller set.** Near or above
  one, the persistence restriction alone cannot rule out that convergence produces
  the whole coefficient; well below one, it cannot account for much of it. It is
  read as a magnitude, without a cut-off.
- **A small $R^2$ is not enough on its own.** Since
  $\lvert R^2/b\rvert = \sqrt{R^2}\,\mathrm{sd}(S_{\mathrm{pre}})/\mathrm{sd}(H_{\mathrm{pre}})$,
  the bound also scales with the ratio of standard deviations.
- **With a proxy control, $1+\gamma$ is not a persistence.** It is returned in
  `r(one_plus_gamma)` and labelled as such, `r(rho_imp)` is missing, `beta1()` is
  rejected and the cap p-values are missing. With the outcome's own baseline level,
  $1+\gamma = \rho_{\mathrm{obs}} + b\,\beta_1$ is an implied counterfactual
  persistence, read against the maintained restriction and pre-shock benchmarks,
  not against zero.
- **Fieller sets have three shapes**: `bounded` ($[\mathrm{lo},\mathrm{hi}]$),
  `two_rays` ($(-\infty,\mathrm{lo}] \cup [\mathrm{hi},\infty)$) and `whole_line`;
  `not_computed` when the inputs were not supplied. A bounded set well below one
  ends the inquiry into the least-squares channel (in an instrumented design
  $g_{\mathrm{IV}}/\beta_{\mathrm{IV}}$ must still be read); a union of rays or the
  whole line means the data do not bound the ratio, and that is the finding.
- **Stata has no infinities.** A missing `lo` or `hi` of an unbounded set means
  $-\infty$ or $+\infty$; read the shape first. In the boundary case where the
  denominator's $t$ statistic equals the critical value exactly, the set is a single
  ray stored as `two_rays` with one missing end.
- **Effect sets.** `r(set_status)` is `bounded`, `all_real` or `empty`. At $b=0$
  (which requires $R^2=0$), `r(L)`, `r(U)` and `r(width)` are missing for both
  `all_real` and `empty`; a zero channel does not establish zero total bias.

## Conventions and limits

- **Signs.** $g = -R^2/b$ carries a minus sign through $b$;
  $g_{\mathrm{IV}} = \mathrm{cov}(Z,S_{\mathrm{pre}})/\mathrm{cov}(Z,H_{\mathrm{pre}})$
  carries none. The Fieller set of $g/\beta$ is for the *signed* ratio; its image
  under the absolute value is stored as `r(bound_ratio_lo)` and `r(bound_ratio_hi)`.
- **Common control space.** $\beta$ is the coefficient of the change on the dose and
  the extra controls. The auxiliary projections partial out only the extra controls;
  the controlled regression then adds the baseline level. Partialling out the
  baseline level itself would make the auxiliary projection degenerate.
- **beta1 consistency check.** With `beta1()`, the command requires
  $\beta = \kappa + (1-R^2)\beta_1$ (with $\kappa = 0$ at $b=0$) within a tolerance of
  $10^{-8} + 10^{-6}\max(\lvert\beta\rvert, \lvert\kappa\rvert, \lvert(1-R^2)\beta_1\rvert)$,
  and $\rho_{\mathrm{obs}} + b\,\beta_1$ must agree with $1+\gamma$ within relative
  tolerance $10^{-8}$. A violation exits with error r(459) before any result or file
  is written. The tolerance allows rounding to about six decimals, not mismatched
  inputs. At $R^2 = 1$ the controlled dose coefficient is not unique and `beta1()`
  is rejected.
- **Not covered.**
  - Bootstrap comparisons across specifications (percentile intervals for $Q$ and
    specification differences); $Q$ has a Fieller set only.
  - Weighted or overidentified 2SLS in `preleveldose_ols`; compute the moments and
    use `preleveldose_iv`.
  - The correlation between the benchmark persistence estimate and the current
    window must be supplied (`corrbrho()`, `corrbb()`); `preleveldose_ols` treats
    them as uncorrelated.
  - Imbens-Manski/Stoye intervals and window-averaging corrections.
  - Small-cluster corrections for Fieller variances; no few-cluster guarantee is
    claimed for the bootstrap.
  - Endpoint delta standard errors are not robust to a weak denominator; use the
    Fieller sets.

## Validation

Run the regression suite from the package directory:

```stata
do tests/run.do
```

or through a runner:

```sh
python3 tests/run_stata.py --stata /path/to/stata
python3 tests/run_windows_mcp.py --working-dir C:/path/to/preleveldose
```

`tests/run_windows_mcp.py` drives a Stata session on a Windows host through a Stata
MCP server (default `http://localhost:4000/mcp`, change with `--url`; needs
`requests`). Batch mode stalls on the test machine, so acceptance runs go through
MCP. A run passes only if it prints a fresh
`PASS: preleveldose Stata regression checks`; the exit code alone is not enough.

Version 0.6 passed the full suite in Windows Stata 18 on 2026-10-10:
`validation/stata18-v06-validation.log` is the log of that run.
`validation/SOURCE_SHA256SUMS` lists the hashes of the validated sources:

```sh
sha256sum -c validation/SOURCE_SHA256SUMS
```

All test data are synthetic. Reference values come from a Python reference
implementation (not part of this repository) and, for the instrumented side, from
an independent NumPy calculation in `tests/make_reference.py` on three synthetic
clustered designs (`tests/synthetic_iv.csv`) whose Fieller sets for
$g_{\mathrm{IV}}/\beta_{\mathrm{IV}}$ are bounded, two rays and the whole line.
The generated assertion files are shipped, so running the Stata tests needs no
Python. After `do tests/run.do`, `tests/check_bootstrap.py` (NumPy) and
`tests/check_docx.py` (standard library) cross-check the bootstrap and the Word
output written into `tests/`.

## Version scheme

From 0.6 the versions are $0.6 \to 0.66 \to 0.666 \to \cdots$, converging digit by
digit to $2/3$, the regression coefficient of filial on mid-parental stature in
Galton's (1886) "regression towards mediocrity". The scheme borrows from TeX's
convergence to $\pi$: each release adds one digit and carries compatible fixes, not
new statistical scope.

## Authors, contact, licence and citation

- Juk-Sen Tang (ORCID [0009-0009-8849-874X](https://orcid.org/0009-0009-8849-874X))
- Jing Gong (ORCID [0009-0001-5570-0819](https://orcid.org/0009-0001-5570-0819))
- Junhong Chen (ORCID [0009-0007-7201-3408](https://orcid.org/0009-0007-7201-3408))

Contact: Juk-Sen Tang, juksen.tang@mail.mcgill.ca. Questions and bug reports are
welcome as GitHub issues.

Licence: MIT (see `LICENSE`).

Citation: see `CITATION.cff`. The method is from Tang, Gong and Chen (2026),
unpublished manuscript.
