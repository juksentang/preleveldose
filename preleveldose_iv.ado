*! preleveldose_iv 0.6 09oct2026 -- instrumented lever g_IV, g_IV/beta_IV and Q from moments
program define preleveldose_iv, rclass
    version 15.1
    syntax , RHO(real) CZS(real) CZH(real) CZY(real) ///
        [V(name) RHOLO(real 0) RHOHI(real 1) Level(cilevel) NOPRINT]
    // czs = cov(Z,S_pre), czh = cov(Z,H_pre), czy = cov(Z, S_post-S_pre), all
    // on the design's sample, weights and controls (any common rescaling,
    // e.g. slopes on Z, gives the same ratios). v() is the 4x4 covariance of
    // the estimates (rho_obs, czs, czh, czy), in that order.
    if missing(`rho', `czs', `czh', `czy', `rholo', `rhohi') | `rholo' > `rhohi' {
        di as error "Moments must be nonmissing and rholo() <= rhohi()."
        exit 198
    }
    if `czh' == 0 {
        di as error "cov(Z,H_pre)=0: the instrument is irrelevant; g_IV and beta_IV are undefined."
        exit 498
    }
    tempname R S H Y giv biv ratio Q chan bound bratio scale VV vn vd cv
    scalar `R' = `rho'
    scalar `S' = `czs'
    scalar `H' = `czh'
    scalar `Y' = `czy'
    // Sign convention: g_IV = cov(Z,S_pre)/cov(Z,H_pre), with no
    // minus sign (b carries one); the OLS analogue is g = -R2/b.
    scalar `giv' = `S'/`H'
    scalar `biv' = `Y'/`H'
    scalar `ratio' = cond(`Y' != 0, `S'/`Y', .)
    scalar `Q' = (`R' - 1)*`ratio'
    scalar `chan' = (`R' - 1)*`giv'
    scalar `scale' = max(abs(1-`rholo'), abs(1-`rhohi'))
    scalar `bound' = abs(`giv')*`scale'
    scalar `bratio' = cond(`biv' != 0, `bound'/abs(`biv'), .)
    if missing(`giv', `biv', `chan', `bound') {
        di as error "Numerical overflow: rescale the moments."
        exit 498
    }
    foreach k in giv givb Q {
        local `k'_shape "not_computed"
        tempname `k'_lo `k'_hi
        scalar ``k'_lo' = .
        scalar ``k'_hi' = .
    }
    if "`v'" != "" {
        confirm matrix `v'
        if rowsof(`v') != 4 | colsof(`v') != 4 {
            di as error "v() must be the 4x4 covariance of (rho_obs, czs, czh, czy)."
            exit 503
        }
        matrix `VV' = `v'
        // g_IV: N = czs, D = czh
        quietly preleveldose_fieller, n(`=`S'') d(`=`H'') vn(`=`VV'[2,2]') vd(`=`VV'[3,3]') cov(`=`VV'[2,3]') level(`level') noprint
        local giv_shape "`r(shape)'"
        scalar `giv_lo' = r(lo)
        scalar `giv_hi' = r(hi)
        // g_IV/beta_IV: N = czs, D = czy
        quietly preleveldose_fieller, n(`=`S'') d(`=`Y'') vn(`=`VV'[2,2]') vd(`=`VV'[4,4]') cov(`=`VV'[2,4]') level(`level') noprint
        local givb_shape "`r(shape)'"
        scalar `givb_lo' = r(lo)
        scalar `givb_hi' = r(hi)
        // Q: N = (rho-1)*czs with gradient (czs, rho-1, 0, 0); D = czy
        scalar `vn' = `S'*`S'*`VV'[1,1] + 2*`S'*(`R'-1)*`VV'[1,2] + (`R'-1)*(`R'-1)*`VV'[2,2]
        scalar `vd' = `VV'[4,4]
        scalar `cv' = `S'*`VV'[1,4] + (`R'-1)*`VV'[2,4]
        quietly preleveldose_fieller, n(`=(`R'-1)*`S'') d(`=`Y'') vn(`=`vn'') vd(`=`vd'') cov(`=`cv'') level(`level') noprint
        local Q_shape "`r(shape)'"
        scalar `Q_lo' = r(lo)
        scalar `Q_hi' = r(hi)
    }
    if "`noprint'" == "" {
        di as text "Instrumented side: g_IV=cov(Z,S_pre)/cov(Z,H_pre)"
        di as text "  g_IV = " as result %12.6g `giv' as text "   beta_IV = " as result %12.6g `biv'
        di as text "  g_IV/beta_IV = " as result %12.6g `ratio' as text "   bound_IV/|beta_IV| = " as result %12.6g `bratio'
        di as text "  Q = (rho_obs-1) g_IV/beta_IV = " as result %12.6g `Q'
        foreach k in giv givb Q {
            if "``k'_shape'" == "bounded" di as text "  Fieller `k': [" as result %12.6g ``k'_lo' as text ", " as result %12.6g ``k'_hi' as text "]"
            else if "``k'_shape'" == "two_rays" di as text "  Fieller `k': (-inf, " as result %12.6g ``k'_lo' as text "] U [" as result %12.6g ``k'_hi' as text ", inf)"
            else if "``k'_shape'" == "whole_line" di as text "  Fieller `k': whole real line"
        }
    }
    return scalar rho_obs = `R'
    return scalar g_iv = `giv'
    return scalar beta_iv = `biv'
    return scalar giv_ratio = `ratio'
    return scalar Q = `Q'
    return scalar channel_iv = `chan'
    return scalar bound_iv = `bound'
    return scalar bound_ratio_iv = `bratio'
    foreach k in giv givb Q {
        return scalar `k'_lo = ``k'_lo'
        return scalar `k'_hi = ``k'_hi'
        return local `k'_shape "``k'_shape'"
    }
    return scalar level = `level'
    return local cmd "preleveldose_iv"
end
