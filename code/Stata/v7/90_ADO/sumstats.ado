
capture program drop sumstats
program define sumstats
* version 1.2  AH 16 Aug 2021 
	syntax varlist(min=2 max=2) [if] [in] [, append(string) BRackets MIDpoint FORMAT(string) HEADing(string) INDent(integer 2) ///
	LABELFormat CLEAN MEAN LABel(string) EXTreme MEDIAN TTEST WILCoxon PFormat(string) varsuffix(string) NOMISsings ] 
	token `varlist' 
	marksample touse, novarlist
		preserve
		qui drop if !`touse'
			* encode string var
			tempname encoded
            capture confirm string variable `1'
            if !_rc {
				encode `1', gen(`encoded') 
				qui drop `1'
				rename `encoded' `1'
			}
			* encode string var
			tempname encoded
            capture confirm string variable `2'
            if !_rc {
				encode `2', gen(`encoded') 
				qui drop `2'
				rename `encoded' `2'
			}
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
			local col `r(r)' // number of cols 
			local t = `r(r)' + 1 // number of cols + total column
			* T-test 
			if "`ttest'" != "" {
				qui ttest `1', by(`2')
				local P `r(p)'
			}
			if "`wilcoxon'" != "" {
				ranksum `1', by(`2') exact 
				local P `r(p_exact)'
			}
			if "`median'" != "" {
				* calculate median IQR 
				tempfile data
				tempfile total 
				qui save `data', replace 
				qui collapse (median) c=`1' (p25)p25=`1' (p75)p75=`1'
				qui gen `2' = `t' 
				qui gen y = `t', before(`2') 
				qui save `total', replace  
				qui use `data', clear
				qui collapse (median) c=`1' (p25)p25=`1' (p75)p75=`1', by(`2')
				qui gen y = _n, before(`2')  
				append using `total' 
				* format 
				foreach v in c p25 p75 {
					qui format `format' `v'	
					qui tostring `v', replace usedisplay force
				}
				if "`brackets'" != "" local l = "["	
				if "`brackets'" != "" local r = "]"	
				if "`brackets'" == "" local l = "("	
				if "`brackets'" == "" local r = ")"				
				qui gen e = "`l'" + p25 + "-" + p75 + "`r'"
				qui drop p25 p75 
				if "`midpoint'" != ""  qui replace e = subinstr(e, ".", "·", .) 
				if "`nomissings'" !="" qui replace e = "" if e =="`l'.-.`r'"
				if "`nomissings'" !="" qui replace c = "" if c =="."
				* label 
				qui drop `2'
				qui gen level =88
				qui gen label = "  Median (IRQ)"
			}
			if "`extreme'" != "" {
				* calculate min & max  
				tempfile data
				tempfile total 
				qui save `data', replace 
				qui collapse (min) c=`1' (max)max=`1' 
				qui gen `2' = `t' 
				qui gen y = `t', before(`2') 
				qui save `total', replace  
				qui use `data', clear
				qui collapse (min) c=`1' (max)max=`1' , by(`2')
				qui gen y = _n, before(`2')  
				qui append using `total' 
				* format 
				foreach v in c max {
					qui format `format' `v'	
					qui tostring `v', replace usedisplay force
				}
				if "`brackets'" != "" local l = "["	
				if "`brackets'" != "" local r = "]"	
				if "`brackets'" == "" local l = "("	
				if "`brackets'" == "" local r = ")"				
				qui gen e = "`l'" + max + "`r'"
				qui drop max
				if "`midpoint'" != ""  qui replace e = subinstr(e, ".", "·", .) 
				if "`nomissings'" !="" qui replace e = "" if e =="`l'.-.`r'"
				if "`nomissings'" !="" qui replace c = "" if c =="."
				* label 
				qui drop `2'
				qui gen level =77
				qui gen label = "  Min (Max)"
			}
			if "`extreme'" == "" & "`median'" == "" {
				* calculate mean SD  
				tempfile data
				tempfile total 
				qui save `data', replace 
				qui collapse (mean) c=`1' (sd)sd=`1' 
				qui gen `2' = `t' 
				qui gen y = `t', before(`2') 
				qui save `total', replace  
				qui use `data', clear
				qui collapse (mean) c=`1' (sd)sd=`1' , by(`2')
				qui gen y = _n, before(`2')  
				qui append using `total' 
				* format 
				foreach v in c sd {
					qui format `format' `v'	
					qui tostring `v', replace usedisplay force
				}
				if "`brackets'" != "" local l = "["	
				if "`brackets'" != "" local r = "]"	
				if "`brackets'" == "" local l = "("	
				if "`brackets'" == "" local r = ")"				
				qui gen e = "`l'" + sd + "`r'"
				qui drop sd
				if "`midpoint'" != "" replace e = subinstr(e, ".", "·", .) 
				if "`nomissings'" !="" qui replace e = "" if e =="`l'.-.`r'"
				if "`nomissings'" !="" qui replace c = "" if c =="."
				* label
				qui drop `2'
				qui gen level =99
				qui gen label = "  Mean (SD)"
			}				
			* reshape 
			qui reshape wide c e, j(y) i(level)
			order label, first
			order level, last
			* label option 
			if "`label'" != "" replace label = "`label'"
			* heading 
			if "`heading'" != "" {
				qui set obs 2 
				qui replace level = -1 if level ==.
				sort level
				qui replace label = "`heading'" if level == -1
			}		
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
			qui gen var = "`1'"
			qui gen header = 0 
			qui tostring level, replace
			* pvalue 
			if "`ttest'" == "" & "`wilcoxon'" == "" qui di ""
			else { 
				if "`pformat'" == "" qui gen pvalue = "`: di %4.3fc `P' '" if _n ==1, before(level)
				if "`pformat'" != "" qui gen pvalue = "`: di `pformat' `P' '" if _n ==1, before(level)
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
			if "`append'" != "" save "`append'", replace 
			* varlist
			qui ds level var header label, not 
			local varlist  `r(varlist)'
			* list 
			if "`clean'" == "" list, sepby(header)
			if "`clean'" != "" list label `varlist', sepby(header) noheader
		restore
	end 

