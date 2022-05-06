capture program drop splittvc // see Example 3: Explanatory variables that change with time in Stata help pdf
program define splittvc
* version 1.0  AH 20 Aug 2021 
	* id start end event_d event
	syntax varlist(min=5 max=5), [ LISTID(string asis) NOLABel TVCMIssing ]  
		token `varlist' 
		qui local id `1'
		qui local start `2'
		qui local end `3'
		qui local event_d `4'
		qui local event `5'
		* list 
		di " --- Cases specified in listid() before splitting ---"
	    list `id' `start' `end' `event_d' `event' if inlist(`id', `listid'), sepby(`id') `nolabel'
		* number of events before end of follow-up
		tempvar end_d 
		qui bysort `id' (`start'): egen `end_d' = max(`end')
		qui gunique `id' if `event' ==1 
		local ne_total = `r(unique)'
		qui gunique `id' if `event' ==1 & `event_d' != `end_d'
		local ne = `r(unique)'
		* check events
		qui assert inlist(`event', 1, 0)
		* reference date 
		qui sum `start', format
		local ref_d = `r(min)' 
		* failure 
		tempvar f
		qui gen `f'=0
		* fake ID 
		tempvar fid
		sort patient start 
		gen `fid' = _n
		* Initial stset to estimate follow-up time 
		qui stset end, failure(`f'==1) origin(`start') id(`fid')
		tempvar fup 
		qui gen `fup' = (_t-_t0)	
		qui total `fup'
		local fup = e(b)[1,1]
		di " --- Follow-up time before splitting ---"
		di %16.0fc `fup'
		di " --- Number of events recorded in `event' --- "
		di %10.0fc `ne_total'	
		di " --- Number of events recorded in `event' (excluding events occurring on end date) --- "
		di %10.0fc `ne'	
		* Stset: set origin to reference date
		qui stset `end', failure(`f'==1) enter(`start') origin(time `ref_d') id(`fid')
		* Scale event date to reference date and set event date to zero for cases without event 
		tempvar eDr 
		qui gen `eDr' = `event_d' - `ref_d'
		qui replace `eDr' = 0 if `event' ==0
		* Generate a number that is larger than the maximum `eDR'
		qui sum `eDr' 
		local t = `r(max)' + 1000		
		tempvar enter 
		tempvar exit 
		* Enter & exit // approach described in example 3 in Stata help has been generalised to work for long tables 
		qui gen `enter' = `t' - `eDr' + _t0
		qui gen `exit' = `enter' + _t - _t0 
		* Stset: time scale changed: event happens at time `t' 
		qui stset `exit', enter(time `enter') failure(`f') id(`fid')
		* Stsplit at zero and time `t'
		stsplit `event'_tvc, at(0, `t') nopreserve
		* Create time-varying event
		qui replace `event'_tvc = 1 if `event' ==1 & _t0 >=`t'
		qui replace `event'_tvc = 0 if `event'_tvc ==`t'
		* Update start & end variable 
		qui replace `start' = _t0 - (`t' - `eDr' ) + `ref_d'
		qui replace `end' = _t - (`t' - `eDr' ) + `ref_d'
		* Stset with updated start & end 
		qui stset `end', failure(`f'==1) enter(`start') id(`fid')
		* Assert total follow-up time has not changed with new stset 
		tempvar fup1 
		qui gen `fup1' = (_t-_t0)
		qui total `fup1'
		local fup1 = e(b)[1,1]
		* Number of event in tvc
		qui gunique `id' if `event'_tvc ==1
		local ne_tvc = `r(unique)'
		* List 
		di " --- Cases specified in listid() after splitting ---"
		list  `id' `start' `end' `event_d' `event' `event'_tvc  if inlist(`id', `listid'), sepby(`id') `nolabel'
		di " --- Follow-up time after splitting ---"
		di %16.0fc `fup1'
		di " --- Number of events recorded in `event'_tvc (excluding events occurring on end date) --- "
		di %10.0fc `ne_tvc'
		* Checks
		assert `fup' == `fup1'
		assert `ne' == `ne_tvc'
		qui count if !inlist(`event'_tvc, 0, 1) 
		if `r(N)' !=0 {
			tab `event'_tvc, mi
			di "`event'_tvc is non binary and/or contains missing values"
			error 198
		}
		if "`tcvmissing'" != "" {
			* List events occurring in event but not in event_tvc 
			tempvar maxTvc 
			qui bysort `id' (`start'): egen `maxTvc' =max(`event'_tvc)
			listif  `id' `start' `end' `event_d' `event' `event'_tvc if `event' != `maxTvc', id(`id') sort(`id' `start') 
		}
   end 

