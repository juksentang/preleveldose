*! preleveldose_infer 0.6 09oct2026
program define preleveldose_infer, rclass
    version 15.1
    syntax , BASEline(name) [RHOCAP(real 1) REPS(integer 0) SEED(integer 20260921)]
    if "`e(cmd)'"!="regress" | "`e(vce)'"!="cluster" {
        di as error "Requires current regress results with vce(cluster clustvar)."
        exit 301
    }
    if missing(`rhocap') | `reps'<0 | `seed'<0 {
        di as error "Require finite rhocap(), reps()>=0 and seed()>=0."
        exit 198
    }
    local names : colnames e(b)
    local found : list baseline in names
    if !`found' {
        di as error "baseline() must name an estimated coefficient exactly."
        exit 111
    }
    tempname gam se df pe pc saved out
    capture scalar `gam' = _b[`baseline']
    if _rc exit 111
    scalar `se' = _se[`baseline']
    scalar `df' = e(df_r)
    if missing(`gam',`se',`df') | `se'<=0 | `df'<=0 {
        di as error "Baseline coefficient must be estimated with positive SE and degrees of freedom."
        exit 498
    }
    scalar `pe' = 2*ttail(`df',abs(`gam'/`se'))
    scalar `pc' = ttail(`df',(`gam'-(`rhocap'-1))/`se')
    matrix `out' = (.,.)
    if `reps'>0 {
        // Bootstrap is deliberately limited to an explicit, unweighted OLS design.
        if "`e(wtype)'"!="" {
            di as error "Wild bootstrap currently supports unweighted regress only."
            exit 198
        }
        local cols : colnames e(b)
        foreach v of local cols {
            if "`v'"!="_cons" {
                capture confirm numeric variable `v'
                if _rc {
                    di as error "Bootstrap requires explicit numeric regressors; expand factors first."
                    exit 198
                }
            }
        }
        estimates store `saved'
        local rngstate `"`c(rngstate)'"'
        capture noisily _preleveldose_wild, baseline(`baseline') rhocap(`rhocap') reps(`reps') seed(`seed')
        local rc = _rc
        if !`rc' matrix `out' = (r(p_equal_wild),r(p_cap_wild))
        quietly estimates restore `saved'
        quietly estimates drop `saved'
        quietly set rngstate `rngstate'
        if `rc' exit `rc'
    }
    return scalar gamma = `gam'
    return scalar se_gamma = `se'
    return scalar df_gamma = `df'
    return scalar rho_imp = 1+`gam'
    return scalar p_equal = `pe'
    return scalar p_cap = `pc'
    return scalar p_equal_wild = `out'[1,1]
    return scalar p_cap_wild = `out'[1,2]
    return scalar bootstrap_reps = `reps'
    return scalar bootstrap_seed = cond(`reps'>0,`seed',.)
    return local inference "cluster_t"
    return local cluster "`e(clustvar)'"
    return local cmd "preleveldose_infer"
    di as text "Cluster t p-values: gamma=0 (two-sided) " as result %9.5g `pe' as text "; gamma<=cap-1 (upper-tail) " as result %9.5g `pc'
    if `reps'>0 di as text "Null-imposed wild cluster bootstrap p-values: " as result %9.5g `out'[1,1] "  " %9.5g `out'[1,2]
end

program define _preleveldose_wild, rclass
    version 15.1
    syntax , BASEline(name) RHOCAP(real) REPS(integer) SEED(integer)
    local y "`e(depvar)'"
    local cluster "`e(clustvar)'"
    local cols : colnames e(b)
    local rhs
    local restricted
    local constant noconstant
    foreach v of local cols {
        if "`v'"=="_cons" local constant
        else {
            local rhs `rhs' `v'
            if "`v'"!="`baseline'" local restricted `restricted' `v'
        }
    }
    tempname g se pv
    scalar `g' = _b[`baseline']
    scalar `se' = _se[`baseline']
    matrix `pv' = J(1,2,.)
    preserve
    quietly keep if e(sample)
    tempvar order tag sign ynull fit resid ystar
    quietly generate long `order' = _n
    quietly sort `cluster' `order'
    quietly by `cluster': generate byte `tag' = _n==1
    quietly generate double `sign' = .
    quietly generate double `ynull' = .
    quietly generate double `ystar' = .
    set seed `seed'
    forvalues h=1/2 {
        local null = cond(`h'==1,0,`rhocap'-1)
        quietly replace `ynull' = `y'-`null'*`baseline'
        if "`restricted'"=="" & "`constant'"=="noconstant" {
            quietly generate double `fit' = 0
            quietly generate double `resid' = `ynull'
        }
        else {
            quietly regress `ynull' `restricted', `constant'
            quietly predict double `fit', xb
            quietly predict double `resid', residuals
        }
        local count = 0
        // Count numerical ties, including all-equal cluster sign draws.
        local target = (`g'-`null')/`se'
        local tietol = 1e-12*max(1,abs(`target'))
        forvalues j=1/`reps' {
            quietly replace `sign' = 2*(runiform()>.5)-1 if `tag'
            quietly by `cluster': replace `sign' = `sign'[1]
            quietly replace `ystar' = `fit'+`null'*`baseline'+`resid'*`sign'
            quietly regress `ystar' `rhs', vce(cluster `cluster') `constant'
            if missing(_se[`baseline']) | _se[`baseline']<=0 {
                di as error "Degenerate bootstrap draw; no p-value reported."
                exit 498
            }
            if `h'==1 local count = `count' + (abs((_b[`baseline']-`null')/_se[`baseline'])>=abs(`target')-`tietol')
            else local count = `count' + ((_b[`baseline']-`null')/_se[`baseline']>=`target'-`tietol')
        }
        matrix `pv'[1,`h'] = (1+`count')/(`reps'+1)
        drop `fit' `resid'
    }
    restore
    return scalar p_equal_wild = `pv'[1,1]
    return scalar p_cap_wild = `pv'[1,2]
end
