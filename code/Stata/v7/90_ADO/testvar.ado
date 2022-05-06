capture program drop testvar 
	program testvar 
	* version 1.1  AH 20 Aug 2021 
	syntax varlist(max=1 min=1), [ GLOBAL FORMAT(string) ]
		* Obtain string with independent variables 
		if "`e(cmd)'" == "cox" {
			local iv = regexr("`e(cmdline)'", "`e(cmd2)'", "") //  remove cmd
		}
		else {
			local iv = regexr("`e(cmdline)'", "`e(cmd)'", "") //  remove cmd 
			local iv = regexr("`iv'", "`e(depvar)'", "") //  remove depvar
		}
		if regexm("`iv'", "`varlist'") ==0 {
			di "variable `varlist' not used in last estimation command"
			error 198 
		}
		if regexm("`iv'", "i.`varlist'") ==0 & regexm("`iv'", "ib[0-9]+.`varlist'") ==0  {
			di "variable `varlist' modelled as continuous predictors. Use i.`varlist' or ib2.`varlist' in estimation command if variable `varlist' is a categorical variable"
			error 198 
		}
		if regexm("`iv'", " in ") local iv = substr("`iv'", 1, strpos("`iv'", " in ")) // remove after in 
		if regexm("`iv'", " if ") local iv = substr("`iv'", 1, strpos("`iv'", " if ")) // remove after if 
		if regexm("`iv'", "\,") local iv = substr("`iv'", 1, strpos("`iv'", ",")-1)
		* Obtain base-level 
		qui forval x = 1/`=wordcount("`iv'")' { 
			local y = word("`iv'", `x') 
			if regexm("`y'", "`varlist'") { 
				local z = regexr("`y'", "`varlist'", "")
					qui sum `varlist'
					if "`z'" ==  "i." local b = "`r(min)'"
					else {
						local b = regexr("`z'", "ib", "")
						local b = regexr("`b'", "\.", "")
						local b = trim("`b'")
					}
			}
		}	
		* Remove baselieve 
		qui levelsof `varlist'
		local levels = regexr("`r(levels)'", "`b'", "") 
		* Generate teststring 
		qui foreach t in `levels' {
			local test = "`t'.`varlist' "   + "`test'"
		}
		di "Base-level: `b'.`varlist'"
		test `test'
		if "`global'" !="" {
			if "`format'" =="" global p_`varlist' : di %5.4fc = r(p)
			if "`format'" !="" global p_`varlist' : di `format' = r(p)
			di "Global p_`varlist': ${p_`varlist'}"
		}
		if "`global'" =="" {
			if "`format'" =="" local p : di %5.4fc = r(p)
			if "`format'" !="" local p : di `format' = r(p)
			di "Local p: `p'"
		}
	end 