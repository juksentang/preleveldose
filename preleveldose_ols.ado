*! preleveldose_ols 0.6 09oct2026 -- common-sample unweighted OLS entry; Fieller sets and optional IV side
program define preleveldose_ols, rclass
    version 15.1
    syntax varlist(min=3 numeric) [if] [in], ///
        [CLuster(varname) RHOLO(real 0) RHOHI(real 1) REPS(integer 0) SEED(integer 20260921) ///
         WINDOW(integer 1) SIGMA2(string) BWARN(real 0) IV(varname numeric) ///
         RHOBENCH(string) SEBENCH(string) Level(cilevel)]
    marksample touse
    if "`cluster'"!="" markout `touse' `cluster', strok
    if "`iv'"!="" markout `touse' `iv'
    if `reps'>0 & "`cluster'"=="" {
        di as error "Cluster bootstrap requires cluster()."
        exit 198
    }
    local options rholo(`rholo') rhohi(`rhohi') reps(`reps') seed(`seed') window(`window') bwarn(`bwarn') level(`level')
    if "`cluster'"!="" local options `options' cluster(`cluster')
    if "`sigma2'"!="" local options `options' sigma2(`sigma2')
    if "`iv'"!="" local options `options' iv(`iv')
    if `"`rhobench'"'!="" local options `options' rhobench(`rhobench')
    if `"`sebench'"'!="" local options `options' sebench(`sebench')
    tempname original
    capture estimates store `original'
    local had_estimates = (_rc==0)
    capture noisily _preleveldose_ols_work `varlist' if `touse', `options'
    local rc = _rc
    if !`rc' return add
    if `had_estimates' {
        quietly estimates restore `original'
        quietly estimates drop `original'
    }
    else ereturn clear
    if `rc' exit `rc'
    return local cmd "preleveldose"
    return local origin "reconstructed_ols"
end

program define _preleveldose_ols_work, rclass
    version 15.1
    syntax varlist(min=3 numeric) [if], ///
        [CLuster(varname) RHOLO(real 0) RHOHI(real 1) REPS(integer 0) SEED(integer 20260921) ///
         WINDOW(integer 1) SIGMA2(string) BWARN(real 0) IV(varname numeric) ///
         RHOBENCH(string) SEBENCH(string) Level(cilevel)]
    gettoken outcome rest : varlist
    gettoken dose rest : rest
    gettoken baseline controls : rest
    marksample touse
    tempname beta rho b r2 beta1 gam varpre vardose ncommon M ivV
    tempvar rd rs ry rz cid
    quietly regress `outcome' `dose' `baseline' `controls' if `touse'
    local predictors : word count `controls'
    if e(rank)!=`predictors'+3 | e(df_r)<=0 {
        di as error "Require a full-rank controlled OLS design and positive residual degrees of freedom."
        exit 459
    }
    scalar `ncommon' = e(N)
    quietly regress `outcome' `dose' `controls' if `touse'
    scalar `beta' = _b[`dose']
    quietly regress `outcome' `baseline' `controls' if `touse'
    scalar `rho' = 1+_b[`baseline']
    // Residualize on the PRE-baseline controls only. Never remove baseline here.
    quietly regress `dose' `controls' if `touse'
    quietly predict double `rd' if `touse', residuals
    quietly summarize `rd' if `touse'
    scalar `vardose' = r(Var)
    quietly regress `baseline' `controls' if `touse'
    quietly predict double `rs' if `touse', residuals
    quietly summarize `rs' if `touse'
    scalar `varpre' = r(Var)
    quietly regress `outcome' `controls' if `touse'
    quietly predict double `ry' if `touse', residuals
    local zvar
    if "`iv'"!="" {
        quietly regress `iv' `controls' if `touse'
        quietly predict double `rz' if `touse', residuals
        local zvar `rz'
    }
    quietly regress `rd' `rs' if `touse'
    scalar `b' = -_b[`rs']
    // Squared partial correlation from the same slope/variances avoids loss
    // of a tiny R2 through subtracting nearly equal sums of squares.
    scalar `r2' = min(1,(`b'*sqrt(`varpre')/sqrt(`vardose'))^2)
    // Cluster ids for the influence-function sums (each observation is its
    // own cluster without cluster()). Raw sandwich, no small-sample factor,
    // as in the Python reference implementation.
    if "`cluster'"!="" quietly egen long `cid' = group(`cluster') if `touse'
    else quietly generate long `cid' = sum(`touse') if `touse'
    mata: _pld_ols_if("`ry' `rs' `rd' `zvar'", "`cid'", "`touse'", "`M'", "`ivV'")
    // M = (beta, rho-1, b, g, [pS, pH, pD]) estimates in row 1; V below.
    tempname se_rho se_b c_rb se_g se_beta c_gb
    scalar `se_beta' = sqrt(`M'[2,1])
    scalar `se_rho' = sqrt(`M'[3,2])
    scalar `se_b' = sqrt(`M'[4,3])
    scalar `se_g' = sqrt(`M'[5,4])
    scalar `c_rb' = cond(`se_rho'*`se_b'>0, `M'[3,3]/(`se_rho'*`se_b'), .)
    scalar `c_gb' = cond(`se_g'*`se_beta'>0, `M'[5,1]/(`se_g'*`se_beta'), .)
    local seopts
    if !missing(`se_rho',`se_b',`c_rb') local seopts serho(`=`se_rho'') seb(`=`se_b'') corr(`=max(-1,min(1,`c_rb'))')
    if !missing(`se_g',`se_beta',`c_gb') local seopts `seopts' seg(`=`se_g'') sebeta(`=`se_beta'') corrgb(`=max(-1,min(1,`c_gb'))')
    else if !missing(`se_g',`se_beta') local seopts `seopts' seg(`=`se_g'') sebeta(`=`se_beta'') corrgb(0)
    local ivopts
    if "`iv'"!="" local ivopts czs(`=`M'[1,5]') czh(`=`M'[1,6]') czy(`=`M'[1,7]') ivv(`ivV')
    local benchopts
    if `"`rhobench'"'!="" local benchopts rhobench(`rhobench')
    if `"`sebench'"'!="" local benchopts `benchopts' sebench(`sebench')
    local vce
    if "`cluster'"!="" local vce vce(cluster `cluster')
    quietly regress `outcome' `dose' `baseline' `controls' if `touse', `vce'
    scalar `beta1' = _b[`dose']
    scalar `gam' = _b[`baseline']
    local inference gamma(`=`gam'')
    if "`cluster'"!="" local inference gammafrom(`baseline')
    local aggregation
    if "`sigma2'"!="" local aggregation sigma2(`sigma2') varpre(`=`varpre'')
    preleveldose, beta(`=`beta'') rho(`=`rho'') b(`=`b'') r2(`=`r2'') beta1(`=`beta1'') ///
        `inference' rholo(`rholo') rhohi(`rhohi') reps(`reps') seed(`seed') ///
        window(`window') `aggregation' bwarn(`bwarn') `seopts' `ivopts' `benchopts' level(`level')
    return add
    return scalar N_common = `ncommon'
    return local origin "reconstructed_ols"
    return local iv_instrument "`iv'"
    di as text "Reconstructed baseline OLS; common sample N=" as result `ncommon'
    di as text "Common controls exclude the subsequently added baseline level. This is not automatically a published specification."
    di as text "The added baseline variable is treated as the outcome's OWN baseline level (control_type own_baseline)."
    if "`iv'"!="" di as text "IV side computed from moments of `iv' on the same common sample and controls; beta_IV is the just-identified ratio cov(Z,dS)/cov(Z,H)."
end

mata:
void _pld_ols_if(string scalar vars, string scalar cidvar, string scalar touse,
                 string scalar outname, string scalar ivname)
{
    real matrix X, P, V, est, out
    real colvector y, s, h, z, cid, x, yy, psi
    real scalar n, G, k, i, j, th, sxx
    real rowvector xi, yi
    X = st_data(., tokens(vars), touse)
    cid = st_data(., cidvar, touse)
    n = rows(X)
    G = max(cid)
    y = X[,1]
    s = X[,2]
    h = X[,3]
    // (y on H) beta; (y on S) rho-1; (H on S) -> b = -slope; (S on H) g
    xi = (3, 2, 2, 3)
    yi = (1, 1, 3, 2)
    k = 4
    if (cols(X) == 4) {
        // slopes of S, H and y on Z: pS, pH, pD
        xi = (xi, 4, 4, 4)
        yi = (yi, 2, 3, 1)
        k = 7
    }
    est = J(1, k, .)
    P = J(G, k, 0)
    for (j=1; j<=k; j++) {
        x = X[, xi[j]]
        yy = X[, yi[j]]
        sxx = cross(x, x)
        if (sxx <= 0) _error(3498, "a regressor has zero variance after residualization")
        th = cross(x, yy)/sxx
        psi = x :* (yy - th*x) / sxx
        if (j == 3) {
            th = -th
            psi = -psi
        }
        est[1, j] = th
        for (i=1; i<=n; i++) P[cid[i], j] = P[cid[i], j] + psi[i]
    }
    V = cross(P, P)
    out = est \ V[1..4, 1..k]
    st_matrix(outname, out)
    if (k == 7) {
        // covariance of (rho_obs, pS, pH, pD) for preleveldose_iv
        st_matrix(ivname, V[(2,5,6,7), (2,5,6,7)])
    }
}
end
