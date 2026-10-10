{smcl}
{* *! version 0.6 09oct2026}{...}
{title:preleveldose_table -- export a multi-specification LaTeX table}

{p 8 12 2}{cmd:preleveldose_table using} {it:collection.dta}, {opt saving(filename.tex)}
[{opt title(text)} {opt label(identifier)} {opt decimals(#)} {opt diagnostics} {opt replace}]

{p 4 4 2}
Input must be a nonempty, unmodified dataset made by {help preleveldose_collect}.
Rows are exported in collected order. Columns are specification, R-squared,
b, the bound relative to the coefficient |R2/b|/|beta| (the main reading), the
Fieller set of the signed ratio g/beta, 1+gamma, the ordered effect set, and the
maintained persistence interval for that row. Thus different caps are visible
rather than silently combined. 1+gamma is the implied persistence for an
own-baseline control; for a proxy control it is marked with a dagger and the notes
state that it is not a persistence. The anchor share kappa/beta is stored in the
collection as a secondary quantity; it is not printed.

{p 4 4 2}
At zero b, effect sets display All real or Empty. Undefined statistics display
a dash. Implied persistence requires beta1(), gamma() or gammafrom() in the original calculation.
It is a point statistic, not a p-value; effect sets are not confidence intervals.

{p 4 4 2}
decimals() accepts 0 through 8, default 4. Small nonzero and very large values
use significant digits so nonzero b is not printed as zero. All stored numbers
retain their original precision. Row names and title are plain text: LaTeX
special characters are escaped, not executed. Ordinary Stata macro expansion
still applies when typing options. Non-ASCII labels need an appropriate LaTeX
engine and fonts in the consuming document.

{p 4 4 2}
Without title(), the output is a fragment suitable for input inside an existing
table. With title(), a complete floating table is written; do not wrap it in
another table environment. label() requires title() and permits only letters,
digits, colon, period, underscore and hyphen.

{p 4 4 2}
Load booktabs and tabularx in the LaTeX preamble. The specification column wraps;
other columns use numeric alignment. This is a single-page table layout, not
an automatically paginated longtable; split large collections into smaller tables.

{p 4 4 2}
Existing outputs require replace. The .dta input cannot be used as the .tex
output. Validation and rendering occur before copying to the destination.
The active dataset, order and existing estimation results are preserved.
Returns r(rows), r(latex_file) and r(cmd).

{title:Example}
{phang}{cmd:. preleveldose_table using "audit.dta", saving("audit.tex") title("Audit and robustness") label("tab:audit") decimals(3) replace}

{title:See also}
{p 4 4 2}{help preleveldose}, {help preleveldose_collect}.

{title:Diagnostic panels}
{p 4 4 2}
Option {cmd:diagnostics} exports six panels: A four diagnostic moments; B the
bound relative to the coefficient (main reading) with the Fieller sets of g/beta and
of the implied effect at a benchmark persistence; C the persistence reading for an
own-baseline control (1+gamma, cluster t p-values); D null-imposed wild cluster
bootstrap p-values, replications and seed; E declared aggregation benchmark and
effect width; F the instrumented side (g_IV, g_IV/beta_IV with its Fieller set, Q).
Fieller sets print as [lo, hi], a union of two rays, or the whole line. Per-row notes report
persistence limits, set status, cluster variable and small-b alerts.
Schema-1 to schema-3 collections are migrated in memory; unrecorded inference and Fieller sets remain missing (not_computed).
No confidence intervals or significance stars are inferred from unavailable data.
For many specifications split into separate tables to retain a single-page layout.

{p 4 4 2}
Per-row notes also report projection-check status and flag reconstructed OLS
origin. Legacy rows cannot be certified retrospectively when beta1 was not stored.
For editable Word output see {help preleveldose_docx}.
