capture program drop fdiag
program define fdiag
* version 1.1  AH 21 Aug 2021 
	syntax newvarname using if , [ MINAGE(integer 0) MINDATE(varlist numeric min=1 max=1) MAXDATE(varlist numeric min=1 max=1) LABel(string) ]
	if "`maxdate'" !="" {
		if `maxdate' ==. {
			di as err "`maxdate' must not contain missing values"
			exit 198
		}
	}
	if "`mindate'" !="" {
	   if `mindate' ==. {
			 di as err "`mindate' must not contain missing values"
			 exit 198
		}
	}	
	qui preserve
	use `using', clear
	* generate indicator variable sepcified in newvarname
	qui gen `varlist' = 1
	* select relevant diagnoses 
	marksample touse
	qui drop if !`touse'
	* select age 
	capture mmerge patient using "$clean/tblBAS", ukeep(birth_d) unmatched(master)
	if "`minage'" !="" qui drop if floor((icd10_date - birth_d)/365) < `minage'
	qui drop birth_d 
	qui mmerge patient using "$temp/patients", ukeep(baseline_d end_d) unmatched(none)	
	* select time 
	if "`mindate'" != "" qui drop if icd10_date < `mindate'
	if "`maxdate'" != "" qui drop if icd10_date > `maxdate'
	* select first diag event 
	qui bysort patient (icd10_date): keep if _n ==1
	* clean
	qui keep patient icd10_date `varlist'
	* event date 
	qui rename icd10_date `varlist'_sd
	* label 
    if "`label'" != "" {
		label define  `varlist' 1 "`label'" 
		lab val `varlist' `varlist'
	}
	* save events
	qui tempfile events
	qui save `events'
	* merge events to original dataset 
	restore 
	qui merge 1:1 patient using `events', keep(match master) nogen
	qui replace `varlist' = 0 if `varlist' ==. 
end
