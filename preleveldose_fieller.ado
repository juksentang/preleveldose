*! preleveldose_fieller 0.6 09oct2026 -- Fieller confidence set for a ratio N/D
program define preleveldose_fieller, rclass
    version 15.1
    syntax , N(real) D(real) [VN(string) VD(string) COV(string) ///
        SEN(string) SED(string) CORR(string) Level(cilevel) NOPRINT]
    // Either variances (vn vd [cov]) or standard errors (sen sed [corr]).
    local byvar = (`"`vn'`vd'`cov'"' != "")
    local byse = (`"`sen'`sed'`corr'"' != "")
    if `byvar' == `byse' {
        di as error "Supply either vn() vd() [cov()] or sen() sed() [corr()], not both and not neither."
        exit 198
    }
    tempname NN DD vnn vdd vnd z a bq c disc r lo hi est dent r1 r2
    scalar `NN' = `n'
    scalar `DD' = `d'
    if `byvar' {
        if `"`cov'"' == "" local cov 0
        foreach o in vn vd cov {
            capture confirm number ``o''
            if _rc {
                di as error "vn(), vd() and cov() must be numbers."
                exit 198
            }
        }
        scalar `vnn' = `vn'
        scalar `vdd' = `vd'
        scalar `vnd' = `cov'
    }
    else {
        if `"`corr'"' == "" local corr 0
        foreach o in sen sed corr {
            capture confirm number ``o''
            if _rc {
                di as error "sen(), sed() and corr() must be numbers."
                exit 198
            }
        }
        if (`sen') < 0 | (`sed') < 0 | abs(`corr') > 1 {
            di as error "Require sen()>=0, sed()>=0 and |corr()|<=1."
            exit 198
        }
        scalar `vnn' = (`sen')*(`sen')
        scalar `vdd' = (`sed')*(`sed')
        scalar `vnd' = (`corr')*(`sen')*(`sed')
    }
    if missing(`NN', `DD', `vnn', `vdd', `vnd') | `vnn' < 0 | `vdd' < 0 {
        di as error "Fieller inputs must be finite with nonnegative variances."
        exit 198
    }
    if `vnd'*`vnd' > `vnn'*`vdd'*(1+1e-10) + 1e-300 {
        di as error "The covariance matrix of (N, D) is not positive semidefinite."
        exit 198
    }
    scalar `z' = invnormal(1-(1-`level'/100)/2)
    scalar `a' = `DD'*`DD' - `z'*`z'*`vdd'
    scalar `bq' = -2*(`NN'*`DD' - `z'*`z'*`vnd')
    scalar `c' = `NN'*`NN' - `z'*`z'*`vnn'
    scalar `disc' = `bq'*`bq' - 4*`a'*`c'
    scalar `est' = cond(`DD' != 0, `NN'/`DD', .)
    scalar `dent' = cond(`vdd' > 0, `DD'/sqrt(`vdd'), .)
    scalar `lo' = .
    scalar `hi' = .
    // Stata has no infinities: a missing endpoint of an unbounded set is
    // -infinity (lo) or +infinity (hi); read r(shape) first.
    if `a' > 0 {
        local shape "bounded"
        scalar `r' = sqrt(max(`disc', 0))
        scalar `lo' = (-`bq' - `r')/(2*`a')
        scalar `hi' = (-`bq' + `r')/(2*`a')
    }
    else if `a' < 0 {
        if `disc' > 0 {
            local shape "two_rays"
            scalar `r1' = (-`bq' - sqrt(`disc'))/(2*`a')
            scalar `r2' = (-`bq' + sqrt(`disc'))/(2*`a')
            scalar `lo' = min(`r1', `r2')
            scalar `hi' = max(`r1', `r2')
        }
        else local shape "whole_line"
    }
    else {
        // a = 0 exactly: a single ray, stored as two_rays with one missing end.
        if `bq' > 0 {
            local shape "two_rays"
            scalar `lo' = -`c'/`bq'
        }
        else if `bq' < 0 {
            local shape "two_rays"
            scalar `hi' = -`c'/`bq'
        }
        else local shape "whole_line"
    }
    if "`noprint'" == "" {
        di as text "Fieller " as result `level' as text "% set for N/D (estimate " as result %12.6g `est' as text "): " _c
        if "`shape'" == "bounded" di as text "[" as result %12.6g `lo' as text ", " as result %12.6g `hi' as text "]"
        else if "`shape'" == "two_rays" di as text "(-inf, " as result %12.6g `lo' as text "] U [" as result %12.6g `hi' as text ", inf)  (unbounded; missing = infinite)"
        else di as text "the whole real line (the data do not bound the ratio)"
    }
    return scalar estimate = `est'
    return scalar lo = `lo'
    return scalar hi = `hi'
    return scalar den_t = `dent'
    return scalar z = `z'
    return scalar level = `level'
    return scalar num = `NN'
    return scalar den = `DD'
    return scalar var_num = `vnn'
    return scalar var_den = `vdd'
    return scalar cov_numden = `vnd'
    return local shape "`shape'"
    return local cmd "preleveldose_fieller"
end
