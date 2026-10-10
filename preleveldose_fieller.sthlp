{smcl}
{* *! version 0.6 09oct2026}{...}
{title:preleveldose_fieller -- Fieller confidence set for a ratio}

{p 8 12 2}
{cmd:preleveldose_fieller}, {opt n(#)} {opt d(#)}
{c -(}{opt vn(#)} {opt vd(#)} [{opt cov(#)}] | {opt sen(#)} {opt sed(#)} [{opt corr(#)}]{c )-}
[{opt level(#)} {opt noprint}]

{p 4 4 2}
Returns the Fieller (1954) set for theta = N/D,
{c -(}theta: (N - theta D)^2 <= z^2 var(N - theta D){c )-}, for jointly asymptotically
normal estimates (N, D) with variances vn, vd and covariance cov (or standard errors
and the correlation of the two estimates). Tang, Gong and Chen (2026) take this
covariance from joint influence functions clustered as the design clusters.

{p 4 4 2}
With a = D^2 - z^2 vd, the set is {cmd:bounded} when a>0 (D significantly different
from zero), {cmd:two_rays} (the complement of an open interval) when a<0 and the
discriminant is positive, and {cmd:whole_line} otherwise. An unbounded set says the
data do not bound the ratio and is reported as computed. Stata has no infinities:
for two_rays, r(lo) and r(hi) are the inner endpoints, (-inf,lo] U [hi,inf); a
missing end marks the single-ray boundary case a=0. For whole_line both are missing.

{p 4 4 2}
The classification and endpoints reproduce {cmd:fieller()} in the Python reference
implementation (toolkit/prelevel_dose.py).

{title:Stored results}
{p 4 4 2}
r(shape), r(lo), r(hi), r(estimate) (= N/D, missing at D=0), r(den_t) (= D/se(D)),
r(z), r(level), r(num), r(den), r(var_num), r(var_den), r(cov_numden), r(cmd).

{title:Examples}
{phang}{cmd:. preleveldose_fieller, n(1) d(2) vn(.04) vd(.09) cov(.01)}{p_end}
{phang}{cmd:. preleveldose_fieller, n(.7) d(-1.3) sen(.2) sed(.5) corr(-.3) level(90)}{p_end}

{title:See also}
{p 4 4 2}{help preleveldose}, {help preleveldose_iv}.
