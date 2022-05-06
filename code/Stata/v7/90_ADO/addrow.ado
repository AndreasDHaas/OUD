
capture program drop addrow
program define addrow
* version 1.0  AH 28 Apr 2021 
	syntax namelist(min=1 max=1), [LABELFormat varsuffix(string) LABEL(string) SAVE CLEAN TOP ] 
			token `namelist' 
			preserve
			qui use `1', clear 
			set obs `=_N+1'
			replace header = 0 if _n ==_N
			replace var ="addrow" if _n ==_N
			tempvar levelint 
			destring level, gen(`levelint') force
			replace `levelint' = 0 if _n ==_N
			sum `levelint' if var =="addrow"
			replace `levelint' = `r(max)' + 1 if _n ==_N
			replace level = string(`levelint') if _n ==_N
			drop `levelint'
			replace label = "`label'" if _n ==_N
			if "`labelformat'" == "" qui format %-40s label
			qui format `labelformat' label
			* Varsuffix 
			ds level var header, not 
			if "`varsuffix'" != "" {
				foreach j of var `r(varlist)' {
					rename `j' `j'`varsuffix'
				}
			}
			if "`top'" !="" {
				gen temp = _n 
				replace temp = -1 if var =="addrow" 
				sort temp 
				drop temp 
			}
			if "`save'" !="" save `append', replace 
			*list 
			if "`clean'" != "" list `r(varlist)', sepby(header) noheader
			if "`clean'" == "" list, sepby(header)
		restore
	end 

