{smcl}
{* *! version 0.6 09oct2026}{...}
{title:preleveldose_docx — editable Word diagnostic reports}
{p 4 4 2}
{cmd:preleveldose_docx using collection.dta, saving(report.docx)}
[{cmd:title(text) decimals(#) replace}]
{p 4 4 2}
Exports six native Word tables (the panels of {help preleveldose_table}, with the bound relative to the coefficient and its Fieller set as the main reading, and the instrumented side in panel F), row-specific restrictions, projection check
status, and interpretation notes from a preleveldose collection. Requires Stata
15.1 or later; tested on Windows Stata 18. Uses native putdocx, with no Python
or Microsoft Word dependency for generating files. decimals() is 0 through 8.
Small nonzero values use significant digits. Missing values are dashes.
{p 4 4 2}
Data and existing estimation results are preserved. An active unsaved putdocx
document causes an error and is never cleared. Existing output requires replace;
validation/rendering failures do not overwrite an existing destination.
Legacy collections lack beta1 and are explicitly marked unchecked.
{p 4 4 2}
Returns r(rows), r(docx_file), and r(cmd). Results are editable tables, not screenshots.
