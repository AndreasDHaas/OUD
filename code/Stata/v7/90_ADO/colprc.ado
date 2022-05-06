
capture program drop colprc
program define colprc
* version 1.2  AH 16 Aug 2021 
	syntax varlist(min=2 max=2) [if] [in] [, append(string) NOPERCENT PERCENTSIGN BRackets MIDpoint FREQFormat(string) PERCENTFormat(string) HEADing(string) INDent(integer 2) NOHEADing COLUMNTotals PLEVEL(numlist int max=1) ///
	NOMIssings LABELFormat CLEAN PFormat(string) DROP(string) VAR(string) varsuffix(string) missingcode(numlist max=1) EXACT CHI] 
	token `varlist' 
	marksample touse, novarlist
		preserve
		qui drop if !`touse'
			* encode string var 1
			tempname encoded
            capture confirm string variable `1'
            if !_rc {
				encode `1', gen(`encoded') 
				qui drop `1'
				rename `encoded' `1'
			}
			* encode string var 2
			tempname encoded
            capture confirm string variable `2'
            if !_rc {
				encode `2', gen(`encoded') 
				qui drop `2'
				rename `encoded' `2'
			}
			* drop observations with missing values in categorical variables 
			if "`nomissings'" != "" qui drop if `1' ==. 
			* value labels 
			tempname unlabeled
			local lbl: value label `1'
			if "`lbl'" == "" { //  
					lab val `1' `unlabeled' // assign empty label if unlabeled 
					local lbl: value label `1'
					assert "`lbl'" != "" 
			}
			qui levelsof `1', missing  	// levels of categorical variable 
			local categories `r(levels)'
			local i = 1
			foreach c in `categories' {
				local lab`i++' : label `lbl' `c'
			}
			* column levels (levels of stratifier variable)
			qui levelsof `2', missing
			local c `r(levels)'
			* locals 
			qui sum `1'
			local min = `r(min)'
			qui levelsof `1', missing
			local cats `r(r)' // number of categories  
			qui levelsof `2', missing
			local col `r(r)' // number of cols 
			local t = `r(r)' + 1 // number of cols + total column 
			* pvalue
			if "`exact'" != "" local test = "exact"
			else if "`chi'" != "" local test = "chi"
			if "`missingcode'" == "" {
				tab `1' `2', col `test' 	
			}
			else  {
				tab `1' `2' if `1' != `missingcode', col `test'
			}
			if "`exact'" != "" local P `r(p_exact)'
			else if "`chi'" != "" local P `r(p)'
			* tabulate variables and write frequencies in dataset
			tab `1' `2', col matcell(freq) matrow(levels) mi 
			matrix colnames levels = `1'
			matrix freq = levels, freq			
			clear
			qui svmat2 freq, names(col)
			* total column 
			qui egen c`t' = rowtotal(c*)
			* column totals & column percentages 
			qui set obs `=_N+1'
			qui replace `1' = `min' - 1 if _n ==_N
			sort `1'
			forval y = 1/`t' { 
				qui total(c`y')
				qui replace c`y' = e(b)[1,1] if _n ==1
				qui gen p`y' = (c`y'/c`y'[1])*100, after(c`y')
			}
			* format frequencies
			forval y = 1/`t' {
				qui format `freqformat' c`y'	
				qui tostring c`y', replace usedisplay force
				*qui replace c`y' = "`freqlab'"  +  c`y' 
			}
			* format percentages 
			if "`percentsign'" != "" local ps = "%"
			if "`brackets'" != "" local l = "["	
			if "`brackets'" != "" local r = "]"	
			if "`brackets'" == "" local l = "("	
			if "`brackets'" == "" local r = ")"				
			forval y = 1/`t' {
				qui format `percentformat' p`y'
				qui tostring p`y', replace usedisplay force
				qui replace p`y' = "`l'" + p`y' + "`ps'`r'" 
				qui replace p`y' = "" if p`y' =="`ps'`r'"
				qui rename p`y' e`y' 
				if "`nopercent'" != "" replace e`y' = ""
				if "`midpoint'" != "" replace e`y' = subinstr(e`y', ".", "·", .) 
			} 
			* supress column totals
			if "`columntotals'" == "" {
				forval y = 1/`t' {
					qui replace c`y' = "" if `1' == `min' - 1
					qui replace e`y' = "" if `1' == `min' - 1
				}
			}
			* row labels 
			qui gen level = "h" if `1' == `min' - 1
			qui gen label = "`heading'" if `1' == `min' - 1, before(`1') 
			if "`noheading'" != "" drop if `1' == `min' - 1
			tempvar blanks 
			qui gen `blanks' = ""
			forvalues j = 1/`indent' {
				qui replace `blanks' = `blanks' + " "
			}
			local i = 1
			foreach y in `categories' {
				qui replace label = `blanks' + "`lab`i++''" if `1' == `y'
				qui replace level = "`y'" if `1' == `y'
			} 
			qui replace label = `blanks' + "." if `1' == .
			if "`labelformat'" == "" qui format %-40s label
			qui format `labelformat' label
			* rename variables: according to string position 
			* $c t is is the string posistion of header `n' is the level of the column in this table 
			local old=1
			*local strMin = 1 
			*local strMax = 1
			foreach n in `c' t { 
				local new = strpos("$c t", "`n'")  // returns string positon of the level of column in the string with all levels from the header command  
				rename c`old' C`new'
				rename e`old' E`new'
				local old = `old' + 1 
				*if `new'  < `strMin' local strMin = `new' 
				*if `new'  > `strMax' local strMax = `new' 
			}
			* variable name 
			if "`var'" == "" qui gen var = "`1'"
			if "`var'" != "" qui gen var = "`var'"			
			qui drop `1' `blanks'
			qui gen header = 0 
			* drop 
			if "`drop'" != "" {
				foreach j in `drop' {
					drop if level == "`j'"
				}
			}
			* pvalue 
			if "`plevel'" == "" local z "h"
			if "`plevel'" != "" local z "`plevel'"
			if "`exact'" == "" & "`chi'" == "" di ""
			else { 
				if "`pformat'" == "" qui gen pvalue = "`: di %4.3fc `P' '" if level=="`z'", before(level)
				if "`pformat'" != "" qui gen pvalue = "`: di `pformat' `P' '" if level=="`z'", before(level)
			}
			* varsuffix 
			qui ds level var header label, not 
			local varlist  `r(varlist)'
			if "`varsuffix'" != "" {
				foreach j of var `varlist' {
					rename `j' `j'`varsuffix'
				}
			}
			* append 
			if "`append'" != "" {
				tempfile file 
				qui save "`file'"
				qui use "`append'", clear 
				qui append using "`file'"  
			}
			* varlist 
			qui ds level var header label, not 
			local varlist  `r(varlist)'
			if "`append'" != "" save "`append'", replace 
			* list 
			if "`clean'" == "" list, sepby(header)
			if "`clean'" != "" list label `varlist', sepby(header) noheader
		restore
	end 

