*! preleveldose_collect 0.6 09oct2026
program define preleveldose_collect, rclass
    version 15.1
    if "`r(cmd)'" != "preleveldose" {
        display as error "Run preleveldose immediately before collecting its results."
        exit 301
    }
    // Snapshot r() before syntax, file checks, or any r-class command.
    tempname result
    local fields beta rho_obs b R2 rho_lo rho_hi kappa c_obs anchor_share anchor_gap rho_imp channel_bound L U width dU_drhohi dL_drhohi se_L se_U se_width corr_LU anchor_ratio anchor_percent weak_b bwarn window working_factor working_excess working_rho gamma se_gamma df_gamma p_equal p_cap p_equal_wild p_cap_wild bootstrap_reps bootstrap_seed sigma2 varpre beta1 projection_gap projection_tol N_common bound_ratio bound_percent g gb_ratio gb_lo gb_hi bound_ratio_lo bound_ratio_hi one_plus_gamma rho_bench tau_bench tau_lo tau_hi g_iv beta_iv giv_ratio Q channel_iv bound_iv bound_ratio_iv giv_lo giv_hi givb_lo givb_hi Q_lo Q_hi level
    local nfields : word count `fields'
    matrix `result' = J(1,`nfields',.)
    local j = 0
    foreach field of local fields {
        local ++j
        matrix `result'[1,`j'] = r(`field')
    }
    matrix colnames `result' = `fields'
    local setstatus "`r(set_status)'"
    local sestatus "`r(se_status)'"
    local aggstatus "`r(aggregation_status)'"
    local inference "`r(inference)'"
    local cluster "`r(cluster)'"
    local projection_status "`r(projection_status)'"
    local origin "`r(origin)'"
    // v0.6 string results; empty r() locals (older callers) are stored as "not_computed".
    foreach k in gb_shape tau_shape giv_shape givb_shape Q_shape control_type {
        local s_`k' "`r(`k')'"
        if "`s_`k''"=="" local s_`k' "not_computed"
    }
    syntax using/ , NAME(string) [REPLACE]
    if strtrim(`"`name'"') == "" {
        display as error "name() must not be blank."
        exit 198
    }
    if !regexm(lower(`"`using'"'), "[.]dta$") {
        display as error "Collection filename must end in .dta."
        exit 198
    }
    preserve
    quietly clear
    quietly svmat double `result', names(col)
    quietly generate strL row_name = ""
    mata: st_sstore(1, "row_name", st_local("name"))
    quietly generate str16 set_status = "`setstatus'"
    quietly generate str24 se_status = "`sestatus'"
    quietly generate str28 aggregation_status = "`aggstatus'"
    quietly generate str20 inference = "`inference'"
    quietly generate str32 cluster = "`cluster'"
    quietly generate str20 projection_status = "`projection_status'"
    quietly generate str24 origin = "`origin'"
    foreach k in gb_shape tau_shape giv_shape givb_shape Q_shape control_type {
        quietly generate str16 `k' = "`s_`k''"
    }
    char _dta[preleveldose_schema] "4"
    tempfile row
    quietly save `row'
    capture confirm file `"`using'"'
    if !_rc & "`replace'" == "" {
        quietly use `"`using'"', clear
        _preleveldose_check
        mata: st_local("duplicate", strofreal(any(st_sdata(., "row_name") :== st_local("name"))))
        if `duplicate' {
            display as error "Duplicate row name; use a distinct specification/window name."
            exit 198
        }
        quietly append using `row'
        char _dta[preleveldose_schema] "4"
        quietly save `"`using'"', replace
    }
    else {
        quietly save `"`using'"', `replace'
    }
    local rows = _N
    restore
    return scalar rows = `rows'
    return local collection `"`using'"'
    return local cmd "preleveldose_collect"
    display as text "Collected `rows' row(s) in " as result `"`using'"'
end
