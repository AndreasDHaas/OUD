capture program drop tblout
program define tblout
* version 1.0  AH 18 Apr 2021 
	syntax using/ [, clear MErge ALign Format(string) ] 
		use using `"`using'"', `clear'
		qui drop level var header
		local i = 1
		foreach var of varlist C* {
			qui rename `var' c`i++'
		}
		local i = 1
		foreach var of varlist E* {
			qui rename `var' e`i++'
		}
		if "`merge'" != "" {  
			capture macro drop m
			global m = `i'-1
			forval y = 1/$m {
				qui replace c`y' = c`y' + " " + e`y'
				qui drop e`y'
				qui if "`format'" == "" format %15s c`y'
				qui if "`format'" != "" format `format' c`y'
			}
		}
		if "`align'" != "" { 
			forval y = 1/$m {
				qui replace c`y' = regexr(c`y', " ", "     ") if substr(c`y',-5,1) == "("
				qui replace c`y' = regexr(c`y', " ", "   ") if substr(c`y',-6,1) == "("
			}
		}
		list, separator(`=_N') noheader
	end