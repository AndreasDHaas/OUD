	
* Patients who received OA drugs 
	use "$clean/analyseOAU", clear
	keep patient med_sd med_id nappi_code nappi_description mg drug event age pop oat
		lab define oat 0 "Detoxification" 1 "Opioid agonist therapy", replace
		lab val oat oat
	
* Merge diagnoses 
	gen int icd10_date = med_sd
	format icd10_date %tdD_m_CY
	sort patient icd10_date
	assertunique patient icd10_date
	merge 1:m patient icd10_date using "C:/Data/IeDEA/Bonitas/v1/clean/tblICD10", keep(match master) sorted
	
* Select 10 most common diagnoses 
	tab icd10_code, mi sort
	gen icd_123 = substr(icd10_code, 1, 3)
	tab icd_123, mi sort
	tab icd_1, mi sort
	bysort icd_123: gen N =_N
	*replace icd_123 = "" if N <22
	
* Determine patients who received diagnoses: icd_123 level 
	levelsof icd_123, clean
	di wordcount("`r(levels)'")
	local j = "`r(levels)'"
	foreach var in `r(levels)' {
		qui gen `var' = 1 if icd_123 == "`var'"
		qui bysort patient (`var'): replace `var' = `var'[1]
		lab define `var' 1 "`var'", replace 
		lab val `var' `var'
	}
	
* Determine patients who received diagnoses: icd_1234 level 
	gen icd_12345 = substr(icd10_code, 1, 5)	
	levelsof icd_12345 if icd_123 =="Z76", clean
	foreach var in `r(levels)' {
	local k = subinstr("`r(levels)'",".","_",.) 
		local varname = regexr("`var'", "\.", "_")
		qui gen `varname' = 1 if icd_12345 == "`var'"
		qui bysort patient (`varname'): replace `varname' = `varname'[1]
		lab define `varname' 1 "`var'", replace 
		lab val `varname' `varname'
	}
	
* Make table unique 
	bysort patient: keep if _n ==1

* Table 
	header oat, saving("$temp/diagOA") percentformat(%3.1fc) freqlab("N=") clean freqf(%9.0fc) 
	foreach var in `j' {
		colprc `var' oat, append("$temp/diagOA") percentformat(%3.1fc) freqf(%9.0fc) drop(".") noheading indent(0) clean
	}
	foreach var in `k' {
		colprc `var' oat, append("$temp/diagOA") percentformat(%3.1fc) freqf(%9.0fc) drop(".") noheading indent(1) clean
	}

* Load table and prepare for export 
	tblout using "$temp/diagOA", clear merge align format("%25s")	
		
* Create word table 
	capture putdocx clear
	putdocx begin, font("Arial", 8)
	putdocx paragraph, spacing(after, 0)
	putdocx text ("Table S2: ICD10 diagnosis received on the date beneficiaries were prescribed opioid agonists"), font("Arial", 9, black) bold 
	putdocx table tbl1 = data(*), border(all, nil) border(top, single) border(bottom, single) layout(autofitcontent) 
	putdocx table tbl1(., .), halign(right)  font("Arial", 8)
	putdocx table tbl1(., 1), halign(left)  
	putdocx table tbl1(1, .), halign(center) bold 
	putdocx table tbl1(2, .), halign(center)  border(bottom, single)
	putdocx pagebreak
	putdocx save "$tables/DisplayItems.docx", append
