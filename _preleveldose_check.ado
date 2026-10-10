*! _preleveldose_check 0.6 09oct2026 -- validate the active collection
program define _preleveldose_check
    version 15.1
    if !inlist("`: char _dta[preleveldose_schema]'","1","2","3","4") | _N == 0 {
        display as error "Expected a nonempty preleveldose_collect dataset (schema 1, 2, 3 or 4)."
        exit 459
    }
    confirm string variable row_name set_status se_status
    confirm numeric variable beta rho_obs b R2 rho_lo rho_hi kappa c_obs anchor_share anchor_gap rho_imp channel_bound L U width dU_drhohi dL_drhohi se_L se_U se_width corr_LU
    quietly count if missing(beta,rho_obs,b,R2,rho_lo,rho_hi,kappa,c_obs,channel_bound) | R2<0 | R2>1 | rho_lo>rho_hi | channel_bound<0
    if r(N) {
        display as error "Collection contains invalid moments or persistence limits."
        exit 459
    }
    quietly count if (b==0 & R2!=0) | (b!=0 & R2==0) | !inlist(set_status,"bounded","all_real","empty")
    if r(N) {
        display as error "Collection contains inconsistent moments or set status."
        exit 459
    }
    quietly count if (b!=0 & (set_status!="bounded" | missing(L,U,width) | L>U | width<0)) | (b==0 & (set_status=="bounded" | !missing(L) | !missing(U) | !missing(width)))
    if r(N) {
        display as error "Collection endpoint storage does not match its set status."
        exit 459
    }
    quietly count if b==0 & ((inrange(rho_obs,rho_lo,rho_hi) & set_status!="all_real") | (!inrange(rho_obs,rho_lo,rho_hi) & set_status!="empty"))
    if r(N) {
        display as error "Zero-b feasibility status is inconsistent."
        exit 459
    }
    if "`: char _dta[preleveldose_schema]'"=="1" {
        // In-memory migration only; legacy unknown inference remains missing.
        foreach v in anchor_ratio anchor_percent weak_b bwarn window working_factor working_excess working_rho gamma se_gamma df_gamma p_equal p_cap p_equal_wild p_cap_wild bootstrap_reps bootstrap_seed sigma2 varpre {
            quietly generate double `v' = .
        }
        quietly replace anchor_ratio = channel_bound/abs(beta) if beta!=0
        quietly replace anchor_percent = 100*anchor_ratio
        quietly generate str28 aggregation_status = "legacy_unknown"
        quietly generate str20 inference = "not_requested"
        quietly generate str32 cluster = ""
    }
    confirm numeric variable anchor_ratio anchor_percent weak_b bwarn window working_factor working_excess working_rho gamma se_gamma df_gamma p_equal p_cap p_equal_wild p_cap_wild bootstrap_reps bootstrap_seed sigma2 varpre
    confirm string variable aggregation_status inference cluster
    quietly count if (!missing(p_equal) & !inrange(p_equal,0,1)) | (!missing(p_cap) & !inrange(p_cap,0,1)) | (!missing(p_equal_wild) & !inrange(p_equal_wild,0,1)) | (!missing(p_cap_wild) & !inrange(p_cap_wild,0,1))
    if r(N) exit 459
    if !inlist("`: char _dta[preleveldose_schema]'","3","4") {
        foreach v in beta1 projection_gap projection_tol N_common {
            quietly generate double `v' = .
        }
        quietly generate str20 projection_status = "legacy_unchecked"
        quietly generate str24 origin = "legacy_unknown"
    }
    confirm numeric variable beta1 projection_gap projection_tol N_common
    confirm string variable projection_status origin
    quietly count if !inlist(projection_status,"passed","not_checked","legacy_unchecked") | (projection_status=="passed" & (missing(beta1,projection_gap,projection_tol) | projection_tol<=0 | abs(projection_gap)>projection_tol))
    if r(N) exit 459
    if "`: char _dta[preleveldose_schema]'"!="4" {
        // In-memory migration to schema 4 (v0.6): bound_ratio is the pre-0.6
        // anchor_ratio; Fieller sets, IV side and control type were not stored.
        foreach v in bound_ratio bound_percent g gb_ratio gb_lo gb_hi bound_ratio_lo bound_ratio_hi one_plus_gamma rho_bench tau_bench tau_lo tau_hi g_iv beta_iv giv_ratio Q channel_iv bound_iv bound_ratio_iv giv_lo giv_hi givb_lo givb_hi Q_lo Q_hi level {
            quietly generate double `v' = .
        }
        quietly replace bound_ratio = anchor_ratio
        quietly replace bound_percent = anchor_percent
        quietly replace g = cond(b==0, 0, -R2/b)
        quietly replace gb_ratio = g/beta if beta!=0
        foreach k in gb_shape tau_shape giv_shape givb_shape Q_shape {
            quietly generate str16 `k' = "not_computed"
        }
        quietly generate str16 control_type = "legacy_unknown"
    }
    confirm numeric variable bound_ratio bound_percent g gb_ratio gb_lo gb_hi bound_ratio_lo bound_ratio_hi one_plus_gamma rho_bench tau_bench tau_lo tau_hi g_iv beta_iv giv_ratio Q channel_iv bound_iv bound_ratio_iv giv_lo giv_hi givb_lo givb_hi Q_lo Q_hi level
    confirm string variable gb_shape tau_shape giv_shape givb_shape Q_shape control_type
    quietly count if !inlist(gb_shape,"bounded","two_rays","whole_line","not_computed") | !inlist(tau_shape,"bounded","two_rays","whole_line","not_computed") | !inlist(giv_shape,"bounded","two_rays","whole_line","not_computed") | !inlist(givb_shape,"bounded","two_rays","whole_line","not_computed") | !inlist(Q_shape,"bounded","two_rays","whole_line","not_computed")
    if r(N) {
        display as error "Collection contains an unknown Fieller-set shape."
        exit 459
    }
    quietly count if !inlist(control_type,"none","own_baseline","proxy","legacy_unknown") | (control_type=="proxy" & !missing(rho_imp))
    if r(N) {
        display as error "Collection control type is inconsistent: a proxy row cannot carry an implied persistence."
        exit 459
    }

end
