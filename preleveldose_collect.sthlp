{smcl}
{* *! version 0.6 09oct2026}{...}
{title:preleveldose_collect -- save a named specification for a combined table}

{p 8 12 2}{cmd:preleveldose_collect using} {it:collection.dta}, {opt name(text)} [{opt replace}]

{p 4 4 2}
Run immediately after {help preleveldose}. The command snapshots its r()
results, including the persistence interval, ordered effect endpoints,
status and endpoint standard errors, into one double-precision row.
It does not estimate new models. Avoid intervening r-class commands.

{p 4 4 2}
A missing collection is created. An existing collection is appended to,
provided its schema is recognized and name() is unique. replace starts a
new collection, discarding an existing file; use it only on the first row
when intentionally rebuilding. Filenames must end in .dta.

{p 4 4 2}
The active dataset, order and existing e() estimates are preserved on
success and on validation errors. r() is replaced with collection results:
r(rows), r(collection), and r(cmd). A second collect requires another
preleveldose calculation. Do not edit the collection schema or computed fields.

{title:Example}
{phang}{cmd:. preleveldose, beta(1) rho(-.5) b(1) r2(.5) beta1(.5)}
{phang}{cmd:. preleveldose_collect using "audit.dta", name("Baseline") replace}
{phang}{cmd:. preleveldose, beta(-.4) rho(.8) b(-.5) r2(.3) beta1(-.4)}
{phang}{cmd:. preleveldose_collect using "audit.dta", name("Alternative window")}
{phang}{cmd:. preleveldose_table using "audit.dta", saving("audit.tex") replace}

{title:See also}
{p 4 4 2}{help preleveldose}, {help preleveldose_table}.

{p 4 4 2}
Version 0.6 writes schema 4, adding bound_ratio (= the former anchor_ratio, which is
kept), g, the Fieller sets of g/beta, of the implied effect and of the IV quantities
(shape, lo, hi), the IV side (g_iv, beta_iv, giv_ratio, Q, bound_ratio_iv),
one_plus_gamma and control_type (none, own_baseline, proxy; legacy_unknown for
migrated rows). Collections written in an earlier schema are migrated in memory
and can be appended to; fields they did not record remain missing.
