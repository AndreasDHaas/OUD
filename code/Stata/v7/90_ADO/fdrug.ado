capture program drop fdrug
program define fdrug
* version 1.1  AH 14 Aug 2021 
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
	qui use `using', clear
	* generate indicator variable sepcified in newvarname
	qui gen `varlist' = 1
	* select relevant medications 
	marksample touse
	qui drop if !`touse'
	* drop medication that was returned or zero quant
	qui bysort patient med_sd nappi_code: egen quantity1 = total(quantity)
	qui replace quantity = quantity1
	qui drop quantity1
	qui drop if quantity <=0 
	* select age 
	qui capture mmerge patient using "$clean/tblBAS", ukeep(birth_d) unmatched(master)
	if "`minage'" !="" qui drop if floor((med_sd - birth_d)/365) < `minage'
	qui drop birth_d 
	qui mmerge patient using "$temp/patients", ukeep(baseline_d end_d) unmatched(none)	
	* select time 
	if "`mindate'" != "" qui drop if med_sd < `mindate'
	if "`maxdate'" != "" qui drop if med_sd > `maxdate'

	
	* select first medicaton event 
	qui bysort patient (med_sd): keep if _n ==1
	* clean
	qui keep patient med_sd `varlist'
	* event date 
	qui rename med_sd `varlist'_sd
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
