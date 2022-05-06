capture program drop regtable
program define regtable
* version 0.1  AH 25 Apr 2021 
	syntax anything [, append(string) save(string) BRackets MIDpoint PFormat(string) ESTFormat(string) HEADing(string) INDent(integer 2) LABELFormat adjusted(integer 9) addrow(integer 0) DROP(string) CLEAN ///
	LABEL1(string) LABEL2(string) LABEL3(string) LABEL4(string) LABEL5(string) LABEL6(string) LABEL7(string) LABEL8(string) LABEL9(string) LABEL10(string) LABEL11(string) LABEL12(string) LABEL13(string)  ///
	LABEL14(string) LABEL15(string) LABEL16(string) LABEL17(string) LABEL18(string) LABEL19(string) LABEL20(string) ]
		if "`save'" != "" & "`append'" != "" {
			di in red "specify either save or append"
			error 197
		}
		token `anything'
		if "`2'" == "" {
			di in red "too few values specified. The syntax is regtable matrixName outcomeID"
			error 134
		}
		if "`3'" != "" {
			di in red "too many values specified. The syntax is regtable matrixName outcomeID"
			error 197
		}
		* matrix to data 
		preserve 
		qui clear
		qui svmat2 `1', names(col) rnames(coef)
			* b & ci
			foreach var in b ll ul {
				format `var' %3.2fc
				if "`estformat'" != "" format `var' `estformat'
				qui tostring `var', gen(`var'f) force usedi
			}
			* row ID 
			qui gen rID =_n	
			* headding
			if "`heading'" != "" {	
				qui set obs `=_N+1'
				qui replace rID = 0 if rID ==.
				qui replace coef = "h.`1'" if coef ==""
				sort rID
			}
			* label 
			tempvar blanks 
			qui gen `blanks' = ""
			forvalues j = 1/`indent' {
				qui replace `blanks' = `blanks' + " "
			}
			gen label = "", before(b)
			forvalues i = 1/20 {
				qui replace label = `blanks' + "`label`i''" if rID==`i++'
			}
			if "`heading'" != "" qui replace label = "`heading'" if rID ==0
			if "`labelformat'" == "" qui format %-40s label
			qui format `labelformat' label
			* brackets 
			if "`brackets'" != "" local l = "["	
			if "`brackets'" != "" local r = "]"	
			if "`brackets'" == "" local l = "("	
			if "`brackets'" == "" local r = ")"		
			* estimate
			qui gen est = bf + " `l'" + llf + "-" + ulf + "`r'" if b !=. & ll!=., before(b)
			qui replace est = bf if b !=. & ll==.
			* p-value 
			if "`labelformat'" == "" format pvalue %5.4fc
			qui format pvalue `pformat'
			qui tostring pvalue, gen(p) force usedi
			qui replace p = "<0.0001" if pvalue < 0.0001
			qui replace p = "" if p == "."
			* midpoint
			if "`midpoint'" != "" qui replace est = subinstr(est, ".", "·", .) 
			if "`midpoint'" != "" qui replace p = subinstr(p, ".", "·", .) 
			* add blank rows 
			qui set obs `=_N+`addrow''
			qui replace rID = _n * -1 if rID ==.
			sort rID
			* adjusted 
			qui gen adjusted = `adjusted'
			* outcome
			qui gen outcome = "`2'"
			if regexm("`2'", "^[0-9]+$") destring outcome, replace force
			* drop 
			if "`drop'" !="" {
				foreach d in `drop' {
					qui drop if coef =="`d'" 
				}
			}
			* save 
			if "`save'" != "" save `save', replace 
			* append 
			if "`append'" != "" {
				tempfile file 
				qui save `file'
				clear
				capture qui use `append', clear 
				qui append using `file'  
				save `save', replace 
			}
			drop `blanks'
			* list 
			descr outcome rID
			format est %-20s
			if "`clean'" != "" list label est p, separator(`=_N')
			if "`clean'" == "" list label est p rID outcome adjusted coef, separator(`=_N')
	restore 
end 
