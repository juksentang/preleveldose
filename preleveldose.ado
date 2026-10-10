*! preleveldose 0.6 09oct2026 -- reporting template: bound ratio, Fieller sets, IV side
program define preleveldose, rclass
    version 15.1
    syntax , BETA(real) RHO(real) B(real) R2(real) ///
        [ RHOLO(real 0) RHOHI(real 1) SERHO(string) SEB(string) CORR(string) ///
          BETA1(string) GAMMA(string) GAMMAFROM(name) REPS(integer 0) SEED(integer 20260921) ///
          WINDOW(integer 1) SIGMA2(string) VARPRE(string) BWARN(real 0) ///
          SAVing(string) REPLACE ///
          SEG(string) SEBETA(string) CORRGB(string) PROXY ///
          RHOBENCH(string) SEBENCH(string) CORRBRHO(string) CORRBB(string) ///
          CZS(string) CZH(string) CZY(string) IVV(name) Level(cilevel) ]

    if missing(`beta', `rho', `b', `r2', `rholo', `rhohi') {
        display as error "Moments and persistence limits must be nonmissing."
        exit 198
    }
    if `r2' < 0 | `r2' > 1 | `rholo' > `rhohi' {
        display as error "Require 0 <= r2 <= 1 and rholo <= rhohi."
        exit 198
    }
    if (`b' == 0 & `r2' != 0) | (`b' != 0 & `r2' == 0) {
        display as error "Inconsistent moments: b=0 iff R2=0 with positive variances."
        display as error "Supply unrounded moments; no near-zero replacement is applied."
        exit 198
    }
    local infer = ("`serho'" != "" | "`seb'" != "" | "`corr'" != "")
    if `infer' {
        foreach opt in serho seb corr {
            capture confirm number ``opt''
            if _rc {
                display as error "Supply numeric serho(), seb(), and corr() together."
                exit 198
            }
        }
        if missing(`serho', `seb', `corr') | `serho' < 0 | `seb' < 0 | abs(`corr') > 1 {
            display as error "Supply serho(), seb(), and corr() together; SEs >= 0, |corr| <= 1."
            exit 198
        }
    }

    if "`replace'" != "" & `"`saving'"' == "" {
        display as error "replace requires saving(filename)."
        exit 198
    }
    tempname projection_gap projection_tol checkkap controlledpart
    scalar `projection_gap' = .
    scalar `projection_tol' = .
    local projection_status "not_checked"
    if "`beta1'" != "" {
        capture confirm number `beta1'
        if _rc {
            display as error "beta1() must be a nonmissing controlled dose coefficient."
            exit 198
        }
        if missing(`beta1') {
            display as error "beta1() must be nonmissing."
            exit 198
        }
    }
    if "`beta1'"!="" {
        if `r2'==1 {
            di as error "beta1() is not uniquely identified when R2=1; supply a noncollinear controlled regression."
            exit 198
        }
        scalar `checkkap' = 0
        if `b'!=0 scalar `checkkap' = `r2'*(1-`rho')/`b'
        scalar `controlledpart' = (1-`r2')*`beta1'
        scalar `projection_gap' = `beta'-`checkkap'-`controlledpart'
        scalar `projection_tol' = 1e-8+1e-6*max(abs(`beta'),abs(`checkkap'),abs(`controlledpart'))
        if missing(`checkkap',`controlledpart',`projection_gap',`projection_tol') exit 498
        if abs(`projection_gap')>`projection_tol' {
            di as error "Inconsistent projections: beta must equal R2*(1-rho)/b + (1-R2)*beta1."
            di as error "At b=0 the channel term is zero. Use the same sample, weights and pre-baseline controls."
            di as error "Discrepancy = " %12.6g `projection_gap' "; rounding tolerance = " %12.6g `projection_tol'
            exit 459
        }
        local projection_status "passed"
    }
    if `bwarn'<0 | missing(`bwarn') | `window'<1 | `reps'<0 {
        di as error "Require bwarn()>=0, window()>=1 and reps()>=0."
        exit 198
    }
    if "`gamma'"!="" & "`gammafrom'"!="" {
        di as error "Choose gamma() or gammafrom(), not both."
        exit 198
    }
    if `reps'>0 & "`gammafrom'"=="" {
        di as error "reps() requires gammafrom() and current clustered regress results."
        exit 198
    }
    // Item 5 of the template: which control is the added baseline variable?
    local control_type "none"
    if "`gamma'`gammafrom'`beta1'"!="" local control_type "own_baseline"
    if "`proxy'"!="" {
        if "`beta1'"!="" {
            di as error "proxy: beta1() and rho+b*beta1 are own-baseline algebra; omit beta1() for a proxy control."
            exit 198
        }
        if "`gamma'`gammafrom'"=="" {
            di as error "proxy requires gamma() or gammafrom(), the coefficient on the proxy control."
            exit 198
        }
        local control_type "proxy"
    }
    tempname sg df pe pc pwe pwc bsseed
    foreach v in sg df pe pc pwe pwc bsseed {
        scalar ``v'' = .
    }
    local inference "not_requested"
    local cluster ""
    if "`gammafrom'"!="" {
        preleveldose_infer, baseline(`gammafrom') rhocap(`rhohi') reps(`reps') seed(`seed')
        local gamma = r(gamma)
        scalar `sg' = r(se_gamma)
        scalar `df' = r(df_gamma)
        scalar `pe' = r(p_equal)
        scalar `pc' = r(p_cap)
        scalar `pwe' = r(p_equal_wild)
        scalar `pwc' = r(p_cap_wild)
        scalar `bsseed' = r(bootstrap_seed)
        local inference "cluster_t"
        local cluster "`r(cluster)'"
        if "`control_type'"=="proxy" {
            // The cap null gamma<=rhohi-1 is a persistence test; undefined for a proxy.
            scalar `pc' = .
            scalar `pwc' = .
        }
    }
    if "`gamma'"!="" {
        capture confirm number `gamma'
        if _rc exit 198
        if missing(`gamma') exit 198
    }
    tempname excess aggcap factor
    scalar `factor' = (`window'-1/`window')/6
    scalar `excess' = .
    scalar `aggcap' = .
    local aggstatus "not_declared"
    if `window'>1 local aggstatus "inputs_missing"
    if "`sigma2'"!="" | "`varpre'"!="" {
        foreach v in sigma2 varpre {
            capture confirm number ``v''
            if _rc exit 198
        }
        if missing(`sigma2',`varpre') | `sigma2'<0 | `varpre'<=0 exit 198
        scalar `excess' = `factor'*(`sigma2'/`varpre')
        scalar `aggcap' = 1+`excess'
        if missing(`excess',`aggcap') exit 498
        local aggstatus "random_walk_benchmark"
    }
    tempname imp
    scalar `imp' = .
    if "`beta1'" != "" {
        scalar `imp' = `rho' + `b'*`beta1'
        if missing(`imp') {
            display as error "Implied persistence overflow: rescale inputs."
            exit 498
        }
    }

    tempname opg
    scalar `opg' = .
    if "`gamma'"!="" & "`control_type'"=="proxy" {
        scalar `opg' = 1+`gamma'
        if missing(`opg') exit 498
    }
    else if "`gamma'"!="" {
        if "`beta1'"!="" {
            if abs(`imp'-(1+`gamma'))>1e-8*max(1,abs(`imp'),abs(1+`gamma')) {
                di as error "gamma() and rho+b*beta1 disagree; check sample, weights and controls."
                exit 459
            }
        }
        if `b'==0 & abs(`rho'-(1+`gamma'))>1e-8*max(1,abs(`rho'),abs(1+`gamma')) {
            di as error "At b=0, gamma must equal rho_obs-1 in the same projection space."
            exit 459
        }
        scalar `imp' = 1+`gamma'
        if missing(`imp') exit 498
    }
    if "`control_type'"=="own_baseline" scalar `opg' = `imp'
    tempname kap shape share gap bound lo hi width du dl sl su sw rlu V G E
    scalar `kap' = 0
    scalar `bound' = 0
    scalar `lo' = .
    scalar `hi' = .
    scalar `width' = .
    scalar `du' = .
    scalar `dl' = .
    scalar `sl' = .
    scalar `su' = .
    scalar `sw' = .
    scalar `rlu' = .
    local status "bounded"
    local sestatus "not_requested"

    if `b' == 0 {
        local status "empty"
        if `rho' >= `rholo' & `rho' <= `rhohi' local status "all_real"
        // Missing endpoints/width never encode infinities or a singleton.
        local sestatus "unavailable_zero_b"
    }
    else {
        scalar `kap' = `r2' * (1-`rho') / `b'
        scalar `bound' = abs(`r2'/`b') * max(abs(1-`rholo'), abs(1-`rhohi'))
        scalar `lo' = min((`rholo'-`rho')/`b', (`rhohi'-`rho')/`b')
        scalar `hi' = max((`rholo'-`rho')/`b', (`rhohi'-`rho')/`b')
        scalar `width' = (`rhohi'-`rholo')/abs(`b')
        scalar `du' = cond(`b' > 0, 1/`b', 0)
        scalar `dl' = cond(`b' < 0, 1/`b', 0)
        if missing(`kap', `bound', `lo', `hi', `width', `du', `dl') {
            display as error "Numerical overflow: rescale inputs; b was not replaced by a tolerance."
            exit 498
        }
        if `infer' {
            local lowercap = cond(`b' > 0, `rholo', `rhohi')
            local uppercap = cond(`b' > 0, `rhohi', `rholo')
            matrix `V' = (`serho'^2, `corr'*`serho'*`seb' \ `corr'*`serho'*`seb', `seb'^2)
            matrix `G' = (-1/`b', -(`lowercap'-`rho')/(`b')^2 \ -1/`b', -(`uppercap'-`rho')/(`b')^2)
            matrix `E' = `G' * `V' * `G''
            scalar `sl' = sqrt(max(0, `E'[1,1]))
            scalar `su' = sqrt(max(0, `E'[2,2]))
            scalar `sw' = `width'*(`seb'/abs(`b'))
            if missing(`E'[1,1], `E'[2,2], `E'[1,2], `sl', `su', `sw') {
                display as error "Endpoint variance overflow: rescale inputs."
                exit 498
            }
            if `sl' > 0 & `su' > 0 scalar `rlu' = max(-1, min(1, (`E'[1,2]/`sl')/`su'))
            local sestatus "delta"
        }
    }
    scalar `shape' = `beta' - `kap'
    scalar `share' = .
    scalar `gap' = .
    if `beta' != 0 {
        scalar `share' = `kap'/`beta'
        scalar `gap' = `share'-`r2'
    }

    if missing(`shape') | (`beta'!=0 & missing(`share',`gap')) {
        display as error "Observable decomposition overflow: rescale inputs."
        exit 498
    }

    tempname ar pct weak
    scalar `ar' = .
    scalar `pct' = .
    if `beta'!=0 {
        scalar `ar' = `bound'/abs(`beta')
        scalar `pct' = 100*`ar'
        if missing(`ar',`pct') exit 498
    }
    scalar `weak' = (`b'!=0 & `bwarn'>0 & abs(`b')<=`bwarn')

    // ---- v0.6 template items 3-4: bound ratio, lever g and Fieller sets ----
    // bound_ratio = channel_bound/|beta| = |R2/b|/|beta| on [0,1]; the pre-0.6
    // name anchor_ratio is kept as an alias. g = cov(S_pre,H)/var(H) = -R2/b.
    tempname g scl gbr gblo gbhi brlo brhi taub taulo tauhi rbench
    scalar `g' = 0
    if `b'!=0 scalar `g' = -`r2'/`b'
    scalar `scl' = max(abs(1-`rholo'), abs(1-`rhohi'))
    foreach v in gbr gblo gbhi brlo brhi taub taulo tauhi rbench {
        scalar ``v'' = .
    }
    if `beta'!=0 scalar `gbr' = `g'/`beta'
    local gb_shape "not_computed"
    local tau_shape "not_computed"
    if `"`seg'`sebeta'`corrgb'"'!="" {
        if `"`corrgb'"'=="" local corrgb 0
        foreach opt in seg sebeta corrgb {
            capture confirm number ``opt''
            if _rc {
                di as error "Supply numeric seg() and sebeta() (and optionally corrgb())."
                exit 198
            }
        }
        if (`seg')<0 | (`sebeta')<0 | abs(`corrgb')>1 {
            di as error "Require seg()>=0, sebeta()>=0 and |corrgb()|<=1."
            exit 198
        }
        quietly preleveldose_fieller, n(`=`g'') d(`beta') sen(`seg') sed(`sebeta') corr(`corrgb') level(`level') noprint
        local gb_shape "`r(shape)'"
        scalar `gblo' = r(lo)
        scalar `gbhi' = r(hi)
        // Image of the signed set under theta -> scale*|theta|: the set for
        // bound_ratio itself. A missing upper limit means +infinity.
        if "`gb_shape'"=="bounded" {
            if `gblo'<=0 & `gbhi'>=0 {
                scalar `brlo' = 0
                scalar `brhi' = `scl'*max(abs(`gblo'),abs(`gbhi'))
            }
            else {
                scalar `brlo' = `scl'*min(abs(`gblo'),abs(`gbhi'))
                scalar `brhi' = `scl'*max(abs(`gblo'),abs(`gbhi'))
            }
        }
        else if "`gb_shape'"=="two_rays" {
            local leftneg = missing(`gblo') | (`gblo'<0)
            local rightpos = missing(`gbhi') | (!missing(`gbhi') & `gbhi'>0)
            if `leftneg' & `rightpos' {
                if missing(`gblo') scalar `brlo' = `scl'*`gbhi'
                else if missing(`gbhi') scalar `brlo' = -`scl'*`gblo'
                else scalar `brlo' = `scl'*min(-`gblo',`gbhi')
            }
            else scalar `brlo' = 0
        }
        else scalar `brlo' = 0
    }
    if `"`rhobench'`sebench'`corrbrho'`corrbb'"'!="" {
        capture confirm number `rhobench'
        if _rc {
            di as error "rhobench() must be a number (the benchmark persistence)."
            exit 198
        }
        scalar `rbench' = `rhobench'
        if `b'!=0 scalar `taub' = (`rbench'-(`rho'))/(`b')
        if `"`sebench'"'=="" local sebench 0
        if `"`corrbrho'"'=="" local corrbrho 0
        if `"`corrbb'"'=="" local corrbb 0
        foreach opt in sebench corrbrho corrbb {
            capture confirm number ``opt''
            if _rc {
                di as error "sebench(), corrbrho() and corrbb() must be numbers."
                exit 198
            }
        }
        if (`sebench')<0 | abs(`corrbrho')>1 | abs(`corrbb')>1 {
            di as error "Require sebench()>=0, |corrbrho()|<=1 and |corrbb()|<=1."
            exit 198
        }
        if `infer' {
            // tau(rho_bench) = (rho_bench-rho_obs)/b: N = rho_bench-rho_obs, D = b.
            tempname tvn tvd tcv
            scalar `tvn' = (`sebench')^2 + (`serho')^2 - 2*(`corrbrho')*(`sebench')*(`serho')
            scalar `tvd' = (`seb')^2
            scalar `tcv' = (`corrbb')*(`sebench')*(`seb') - (`corr')*(`serho')*(`seb')
            quietly preleveldose_fieller, n(`=`rbench'-(`rho')') d(`b') vn(`=`tvn'') vd(`=`tvd'') cov(`=`tcv'') level(`level') noprint
            local tau_shape "`r(shape)'"
            scalar `taulo' = r(lo)
            scalar `tauhi' = r(hi)
        }
    }
    // ---- instrumented side from supplied moments ----
    local hasiv = (`"`czs'`czh'`czy'"'!="")
    foreach v in g_iv beta_iv giv_ratio Q channel_iv bound_iv bound_ratio_iv giv_lo giv_hi givb_lo givb_hi Q_lo Q_hi {
        tempname iv_`v'
        scalar `iv_`v'' = .
    }
    foreach k in giv givb Q {
        local iv_`k'_shape "not_computed"
    }
    if `hasiv' {
        foreach opt in czs czh czy {
            capture confirm number ``opt''
            if _rc {
                di as error "Supply numeric czs(), czh() and czy() together."
                exit 198
            }
        }
        local ivvopt
        if "`ivv'"!="" local ivvopt v(`ivv')
        quietly preleveldose_iv, rho(`rho') czs(`czs') czh(`czh') czy(`czy') `ivvopt' rholo(`rholo') rhohi(`rhohi') level(`level') noprint
        foreach v in g_iv beta_iv giv_ratio Q channel_iv bound_iv bound_ratio_iv giv_lo giv_hi givb_lo givb_hi Q_lo Q_hi {
            scalar `iv_`v'' = r(`v')
        }
        foreach k in giv givb Q {
            local iv_`k'_shape "`r(`k'_shape)'"
        }
    }
    else if "`ivv'"!="" {
        di as error "ivv() requires czs(), czh() and czy()."
        exit 198
    }
    di as text "Diagnostic moments: beta=" as result %12.6g `beta' as text " R2=" as result %12.6g `r2' as text " b=" as result %12.6g `b' as text " rho_obs=" as result %12.6g `rho'
    di as text "Bound / |beta| (main reading) = " as result %12.6g `ar' as text " (" as result %12.6g `pct' as text " percent of |beta|)"
    if "`gb_shape'"=="bounded" di as text "  Fieller `level'% set for g/beta: [" as result %12.6g `gblo' as text ", " as result %12.6g `gbhi' as text "]"
    if "`gb_shape'"=="two_rays" di as text "  Fieller `level'% set for g/beta: (-inf, " as result %12.6g `gblo' as text "] U [" as result %12.6g `gbhi' as text ", inf): unbounded"
    if "`gb_shape'"=="whole_line" di as text "  Fieller `level'% set for g/beta: the whole line; the data do not bound the ratio"
    if "`gb_shape'"=="not_computed" di as text "  Fieller set for g/beta not computed: supply seg(), sebeta() and corrgb()."
    if !missing(`taub') di as text "Implied effect at rho_bench=" as result %9.4g `rbench' as text ": tau=" as result %12.6g `taub' as text "  Fieller shape: " as result "`tau_shape'"
    if `hasiv' di as text "IV side: g_IV=" as result %12.6g `iv_g_iv' as text " g_IV/beta_IV=" as result %12.6g `iv_giv_ratio' as text " Q=" as result %12.6g `iv_Q' as text "  Fieller g_IV/beta_IV: " as result "`iv_givb_shape'"
    if "`control_type'"=="own_baseline" & !missing(`imp') di as text "Own baseline control: implied persistence 1+gamma = " as result %12.6g `imp'
    if "`control_type'"=="proxy" di as text "Proxy control: 1+gamma = " as result %12.6g `opg' as text " is NOT a persistence; report R2 and b after partialling the proxy."
    di as text "Secondary: anchor share kappa/beta = " as result %12.6g `share' as text " (see help preleveldose; not the main reading)"
    if `weak' di as text "ALERT: |b| is below your units-dependent threshold; inspect effect-set width."
    if `window'>1 di as text "AGGREGATION ALERT: declared multi-year means; do not mechanically impose rho0<=1."
    if "`aggstatus'"=="random_walk_benchmark" di as text "Working random-walk benchmark: excess=" as result %12.6g `excess' as text " measured persistence=" as result %12.6g `aggcap' as text "; supplied cap unchanged."
    display as text "Pre-level dose: supplied-moment calculation"
    display as text "Observable kappa = " as result %12.6g `kap' ///
        as text "   c_obs = " as result %12.6g `shape'
    display as text "Conditional channel bound = " as result %12.6g `bound'
    display as text "Effect set status: " as result "`status'"
    if "`status'" == "bounded" {
        display as text "Ordered set: [" as result %12.6g `lo' as text ", " ///
            as result %12.6g `hi' as text "]   width = " as result %12.6g `width'
    }
    if "`status'" == "all_real" display as text "All real effects are feasible under unrestricted c."
    if "`status'" == "empty" display as text "Persistence restriction is incompatible with the supplied moments."
    if "`sestatus'" == "delta" {
        display as text "Endpoint delta SEs: " as result %12.6g `sl' "  " %12.6g `su'
        display as text "Delta SEs do not provide weak-denominator-robust coverage."
    }
    if `b' == 0 display as text "Zero baseline channel does not imply zero total bias; ratio inference is unavailable."

    if `"`saving'"' != "" {
        local texcontrol
        if "`control_type'"=="proxy" local texcontrol proxy
        _preleveldose_tex using `"`saving'"', r2(`r2') b(`b') ///
            ratio(`=`ar'') imp(`=`opg'') rholo(`rholo') rhohi(`rhohi') `texcontrol' `replace'
        display as text "LaTeX fragment saved to " as result `"`saving'"'
    }

    return scalar N_common = .
    return local origin "supplied_moments"
    return scalar beta1 = .
    if "`beta1'"!="" return scalar beta1 = `beta1'
    return scalar projection_gap = `projection_gap'
    return scalar projection_tol = `projection_tol'
    return local projection_status "`projection_status'"
    return scalar bound_ratio = `ar'
    return scalar bound_percent = `pct'
    return scalar anchor_ratio = `ar'
    return scalar anchor_percent = `pct'
    return scalar g = `g'
    return scalar gb_ratio = `gbr'
    return scalar gb_lo = `gblo'
    return scalar gb_hi = `gbhi'
    return local gb_shape "`gb_shape'"
    return scalar bound_ratio_lo = `brlo'
    return scalar bound_ratio_hi = `brhi'
    return scalar rho_bench = `rbench'
    return scalar tau_bench = `taub'
    return scalar tau_lo = `taulo'
    return scalar tau_hi = `tauhi'
    return local tau_shape "`tau_shape'"
    foreach v in g_iv beta_iv giv_ratio Q channel_iv bound_iv bound_ratio_iv giv_lo giv_hi givb_lo givb_hi Q_lo Q_hi {
        return scalar `v' = `iv_`v''
    }
    foreach k in giv givb Q {
        return local `k'_shape "`iv_`k'_shape'"
    }
    return scalar one_plus_gamma = `opg'
    return local control_type "`control_type'"
    return scalar level = `level'
    return scalar weak_b = `weak'
    return scalar bwarn = `bwarn'
    return scalar sigma2 = .
    return scalar varpre = .
    if "`sigma2'"!="" return scalar sigma2 = `sigma2'
    if "`varpre'"!="" return scalar varpre = `varpre'
    return scalar window = `window' 
    return scalar working_factor = `factor'
    return scalar working_excess = `excess'
    return scalar working_rho = `aggcap'
    return local aggregation_status "`aggstatus'"
    return local inference "`inference'"
    return local cluster "`cluster'"
    return scalar gamma = .
    if "`gamma'"!="" return scalar gamma = `gamma'
    return scalar se_gamma = `sg'
    return scalar df_gamma = `df'
    return scalar p_equal = `pe'
    return scalar p_cap = `pc'
    return scalar p_equal_wild = `pwe'
    return scalar p_cap_wild = `pwc'
    return scalar bootstrap_reps = `reps'
    return scalar bootstrap_seed = `bsseed'
    return scalar rho_imp = `imp'
    return local latex_file `"`saving'"'
    return scalar beta = `beta'
    return scalar rho_obs = `rho'
    return scalar b = `b'
    return scalar R2 = `r2'
    return scalar rho_lo = `rholo'
    return scalar rho_hi = `rhohi'
    return scalar kappa = `kap'
    return scalar c_obs = `shape'
    return scalar anchor_share = `share'
    return scalar anchor_gap = `gap'
    return scalar channel_bound = `bound'
    return scalar L = `lo'
    return scalar U = `hi'
    return scalar width = `width'
    return scalar dU_drhohi = `du'
    return scalar dL_drhohi = `dl'
    return scalar se_L = `sl'
    return scalar se_U = `su'
    return scalar se_width = `sw'
    return scalar corr_LU = `rlu'
    return local set_status "`status'"
    return local se_status "`sestatus'"
    return local cmd "preleveldose"
end
