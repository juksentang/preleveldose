preleveldose_docx using "tests/collection small.dta", saving("tests/diagnostics.docx") title("Audit & comparison: 20%") replace
assert r(rows)==5
assert "`r(docx_file)'"=="tests/diagnostics.docx"
confirm file "tests/diagnostics.docx"
capture preleveldose_docx using "tests/collection small.dta", saving("tests/diagnostics.docx")
assert _rc==602
capture preleveldose_docx using "tests/collection small.dta", saving("tests/collection small.dta") replace
assert _rc==198
capture preleveldose_docx using "tests/collection small.dta", saving("tests/diagnostics.docx") decimals(9) replace
assert _rc==198
// A report cannot erase a user's active unsaved Word document.
putdocx begin
putdocx paragraph
putdocx text ("Keep my unsaved document")
capture preleveldose_docx using "tests/collection small.dta", saving("tests/diagnostics.docx") replace
assert _rc==110
putdocx save "tests/preserved_draft.docx", replace
// UTF-8 and literal special characters travel as data, not injected Stata code.
preleveldose, beta(1) rho(-.5) b(1) r2(.5) beta1(.5)
preleveldose_collect using "tests/unicode.dta", name("重构基准 & 20% <not published>") replace
preleveldose_docx using "tests/unicode.dta", saving("tests/unicode.docx") title("诊断表 & 比较") replace
preleveldose_docx using "tests/legacy.dta", saving("tests/legacy.docx") replace

// Invalid input cannot truncate an existing report.
copy "tests/diagnostics.docx" "tests/protected_before.docx", replace
capture preleveldose_docx using "tests/unrelated.dta", saving("tests/diagnostics.docx") replace
assert _rc==459
