*! preleveldose_docx 0.6 09oct2026 -- native editable Word report
program define preleveldose_docx, rclass
    version 15.1
    syntax using/ , SAVing(string) [TITLE(string) DECimals(integer 4) REPLACE]
    if !regexm(lower(`"`saving'"'), "[.]docx$") {
        di as error "saving() must end in .docx."
        exit 198
    }
    if `decimals'<0 | `decimals'>8 exit 198
    if "`replace'"=="" confirm new file `"`saving'"'
    preserve
    quietly use `"`using'"', clear
    _preleveldose_check
    local rows = _N
    // Never clear an existing unsaved putdocx document owned by the user.
    capture putdocx begin, font("Calibri",10) pagesize(A4) margin(all,0.7)
    if _rc {
        di as error "Cannot start Word report. Save or clear any active putdocx document first."
        exit 110
    }
    tempfile rendered
    local docfile "`rendered'.docx"
    capture noisily _preleveldose_docx_write, saving(`"`docfile'"') title(`"`title'"') decimals(`decimals')
    local rc = _rc
    if `rc' {
        capture putdocx clear
        exit `rc'
    }
    // Rendering errors never truncate an existing destination.
    capture copy `"`docfile'"' `"`saving'"', `replace'
    local rc = _rc
    capture erase `"`docfile'"'
    if `rc' exit `rc' 
    restore
    return scalar rows = `rows'
    return local docx_file `"`saving'"'
    return local cmd "preleveldose_docx"
    di as text "Word diagnostic report saved to " as result `"`saving'"'
end

program define _preleveldose_docx_write
    version 15.1
    syntax , SAVing(string) DECimals(integer) [TITLE(string)]
    tempname caption
    mata: st_strscalar(st_local("caption"), st_local("title"))
    if `caption'=="" scalar `caption' = "Pre-level dose diagnostic audit"
    putdocx paragraph, style(Title)
    putdocx text (`caption')
    putdocx paragraph
    putdocx text ("Each row describes its named specification. Reconstructed baselines are not automatically published estimates. All results retain the row-specific assumptions reported below.")
    local fmt "%21.`decimals'f"
    // Display strings for Fieller sets (missing end = infinite) and for 1+gamma.
    tempvar gbset tauset givbset Qset opgcell
    _pld_docx_setvar `gbset' gb "`fmt'"
    _pld_docx_setvar `tauset' tau "`fmt'"
    _pld_docx_setvar `givbset' givb "`fmt'"
    _pld_docx_setvar `Qset' Q "`fmt'"
    quietly generate str40 `opgcell' = cond(missing(rho_imp),"---",strtrim(string(rho_imp,"`fmt'")))
    quietly replace `opgcell' = cond(missing(one_plus_gamma),"---",strtrim(string(one_plus_gamma,"`fmt'"))+" (proxy: not a persistence)") if control_type=="proxy"
    forvalues panel=1/6 {
        if `panel'==1 {
            local heading "A. Diagnostic moments"
            local fields beta R2 b rho_obs
            local h2 "Baseline beta"
            local h3 "R-squared"
            local h4 "Lever b"
            local h5 "Observed rho"
        }
        if `panel'==2 {
            local heading "B. Bound relative to the coefficient (main reading)"
            local fields channel_bound bound_ratio `gbset' `tauset'
            local h2 "Max. channel"
            local h3 "Bound / |beta|"
            local h4 "Fieller set, g/beta"
            local h5 "Fieller set, tau(rho_bench)"
        }
        if `panel'==3 {
            local heading "C. Persistence reading: own baseline level only"
            local fields `opgcell' gamma p_equal p_cap
            local h2 "1+gamma"
            local h3 "Gamma"
            local h4 "Two-sided p"
            local h5 "Upper-tail p"
        }
        if `panel'==4 {
            local heading "D. Null-imposed wild cluster bootstrap"
            local fields p_equal_wild p_cap_wild bootstrap_reps bootstrap_seed
            local h2 "Two-sided p"
            local h3 "Upper-tail p"
            local h4 "Replications"
            local h5 "Seed"
        }
        if `panel'==5 {
            local heading "E. Aggregation and effect-set width"
            local fields window working_excess working_rho width
            local h2 "Window"
            local h3 "Working excess"
            local h4 "RW benchmark"
            local h5 "Set width"
        }
        if `panel'==6 {
            local heading "F. Instrumented side"
            local fields g_iv giv_ratio `givbset' Q
            local h2 "g_IV"
            local h3 "g_IV / beta_IV"
            local h4 "Fieller set"
            local h5 "Q"
        }
        putdocx paragraph, style(Heading2)
        putdocx text ("`heading'")
        local displays
        local j=1
        foreach field of local fields {
            local ++j
            tempvar value
            local nfmt "`fmt'"
            if (`panel'==4 & `j'>=4) | (`panel'==5 & `j'==2) local nfmt "%21.0f"
            capture confirm string variable `field'
            if !_rc quietly generate str80 `value' = `field'
            else {
                quietly generate str30 `value' = cond(missing(`field'),"---",strtrim(string(`field',"`nfmt'")))
                quietly replace `value' = strtrim(string(`field',"%12.5g")) if !missing(`field') & (abs(`field')>=1e7 | (`field'!=0 & abs(`field')<10^(-`decimals')))
            }
            local displays `displays' `value'
        }
        putdocx table t`panel' = data(row_name `displays'), varnames headerrow(1) width(100%) border(all,nil)
        putdocx table t`panel'(1,1) = ("Specification")
        forvalues j=2/5 {
            putdocx table t`panel'(1,`j') = ("`h`j''")
        }
        putdocx table t`panel'(.,.), font("Calibri",9)
        putdocx table t`panel'(1,.), bold shading("E8EEF5") border(bottom,single)
        putdocx table t`panel'(.,1), width(32%)
        forvalues col=2/5 {
            putdocx table t`panel'(.,`col'), halign(right) width(17%)
        }
        putdocx table t`panel'(.,.), valign(center)
        drop `displays'
    }
    putdocx paragraph, style(Heading2)
    putdocx text ("Specification assumptions and checks")
    tempvar note
    quietly generate strL `note' = row_name+": persistence ["+strtrim(string(rho_lo,"`fmt'"))+", "+strtrim(string(rho_hi,"`fmt'"))+"]. "
    quietly replace `note' = `note'+"Effect set: "+cond(set_status=="all_real","all real",set_status)+". "
    quietly replace `note' = `note'+"Projection identity: "+cond(projection_status=="passed","passed",cond(projection_status=="legacy_unchecked","not checked (legacy row)","not checked (no beta1)"))+". "
    quietly replace `note' = `note'+"Reconstructed baseline OLS, not automatically a published estimate. " if origin=="reconstructed_ols"
    quietly replace `note' = `note'+"Cluster: "+cluster+". " if cluster!=""
    quietly replace `note' = `note'+"Added control: own baseline level. " if control_type=="own_baseline"
    quietly replace `note' = `note'+"Added control: proxy; 1+gamma is not a persistence. " if control_type=="proxy"
    quietly replace `note' = `note'+"Fieller set for Q: "+`Qset'+". " if Q_shape!="not_computed"
    quietly replace `note' = `note'+"Secondary: anchor share kappa/beta = "+strtrim(string(anchor_share,"`fmt'"))+". " if !missing(anchor_share)
    quietly replace `note' = `note'+"Multi-year averaging declared. " if !missing(window) & window>1
    quietly replace `note' = `note'+"Working random-walk benchmark supplied. " if aggregation_status=="random_walk_benchmark"
    quietly replace `note' = `note'+"Variance inputs unavailable; aggregation correction not computed. " if aggregation_status=="inputs_missing"
    quietly replace `note' = `note'+"ALERT: |b| is below the user threshold "+strtrim(string(bwarn,"%12.5g"))+". " if weak_b==1
    forvalues i=1/`=_N' {
        putdocx paragraph
        putdocx text (`note'[`i'])
    }
    putdocx paragraph, style(Heading2)
    putdocx text ("Interpretation")
    putdocx paragraph
    putdocx text ("Panel B is the main reading: the channel bound relative to the coefficient, |R2/b|/|beta| (times the largest distance of the persistence restriction from one), read as a magnitude without a cut-off, together with the Fieller set of the signed ratio g/beta (g = -R2/b). A union of rays or the whole line means the data do not bound the ratio. A small R2 alone does not end the check, because the bound also scales with sd(S)/sd(H). The bound concerns one baseline channel, not total bias. beta denotes a baseline coefficient; this report does not certify causality or full-model sharp identification. The anchor share kappa/beta is a secondary quantity reported in the row notes (see help preleveldose).")
    putdocx paragraph
    putdocx text ("Panel C applies only when the added control is the outcome's own baseline level, estimated by OLS: 1+gamma is then an implied counterfactual persistence read against the restriction. For a proxy control 1+gamma is not a persistence and the cap test is not reported. The equality null is gamma = 0 (two-sided). The cap null is gamma <= rho_hi - 1 (upper-tail). Nonrejection does not establish no contamination. Wild-bootstrap columns use separately restricted null fits and cluster Rademacher signs; dashes denote unavailable results.")
    putdocx paragraph
    putdocx text ("Panel F reports the instrumented lever g_IV = cov(Z,S_pre)/cov(Z,H_pre) against beta_IV, its Fieller set, and Q = (rho_obs-1) g_IV/beta_IV.")
    putdocx paragraph
    putdocx text ("Common controls mean the controls BEFORE additionally including the baseline level. Working values require a declared averaging window and matching variance inputs under a random-walk benchmark; they do not automatically change the persistence cap. A missing width at b = 0 is not a zero-width singleton: consult the effect-set status.")
    putdocx save `"`saving'"', replace
end

program define _pld_docx_setvar
    version 15.1
    args newvar p fmt
    quietly generate str80 `newvar' = "---"
    quietly replace `newvar' = "["+strtrim(string(`p'_lo,"`fmt'"))+", "+strtrim(string(`p'_hi,"`fmt'"))+"]" if `p'_shape=="bounded"
    quietly replace `newvar' = "(-inf, "+strtrim(string(`p'_lo,"`fmt'"))+"] U ["+strtrim(string(`p'_hi,"`fmt'"))+", inf)" if `p'_shape=="two_rays" & !missing(`p'_lo) & !missing(`p'_hi)
    quietly replace `newvar' = "["+strtrim(string(`p'_hi,"`fmt'"))+", inf)" if `p'_shape=="two_rays" & missing(`p'_lo)
    quietly replace `newvar' = "(-inf, "+strtrim(string(`p'_lo,"`fmt'"))+"]" if `p'_shape=="two_rays" & missing(`p'_hi)
    quietly replace `newvar' = "whole line" if `p'_shape=="whole_line"
end
