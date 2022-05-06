
* GENERATE DATASET FOR ANALYSIS OF OUD INCIDENCE  

* Loop over events 
	*foreach j in oud oa opi oat1 {
	 foreach j in oat1 {
	
		* Long dataset 
			use "$clean/analyseLong", clear
					
		* Generate _d
				
			* No event 
				gen byte d = 0
				*list patient baseline_d start end oud_sd oud oud_tvc d if inlist(patient, 2091, 131), sepby(patient)
				
			* Event 
				bysort patient (start): replace d = 1 if `j'_tvc[_n+1]==1 & `j'_tvc==0
				*list patient baseline_d start end oud_sd oud oud_tvc d if inlist(patient, 2091, 131), sepby(patient)
				
			* Event on baseline date 
				*list patient baseline_d start end oud_sd oud oud_tvc d if oud_sd == baseline_d, sepby(pat) 
				bysort patient (start): replace d = 1 if baseline_d == `j'_sd & _n ==1
				bysort patient (start): replace end = baseline_d + 1 if baseline_d == `j'_sd & _n ==1
				
			* Event on end_d 
				*list patient baseline_d start end oud_sd oud oud_tvc d if oud_sd == end_d, sepby(pat) 		
				bysort patient (start): replace d = 1 if `j'_sd == end_d & _n ==_N
				
			* Drop follow-up time after d 
				gen temp = 1 if start >= `j'_sd & `j'_sd !=. 
				bysort patient (start): replace temp = . if `j'_sd == baseline_d & _n ==1 // don't drop first row of cases with event on baseline date
				*list patient baseline_d start end oud_sd oud oud_tvc d temp if oud_sd == baseline_d, sepby(pat) // event on baseline date 
				*list patient baseline_d start end oud_sd oud oud_tvc d temp if oud_sd == end_d, sepby(pat) // event on last day 
				*list patient baseline_d start end oud_sd oud oud_tvc d temp if inlist(patient, 2091, 131), sepby(patient)
				drop if temp ==1
				drop temp
						
			* Check that number of events match 
				gunique patient if d ==1
				local d = r(J)
				gunique patient if `j'_sd < .
				assert `d' == `r(J)'  
				
		* Stset  
		
			* Stset without id 
				stset end, failure(d==1) enter(start) origin(baseline_d) 
				*list patient start end plan baseline_d end_d _t0 _t _st if inlist(patient, 4688820), sepby(pat) // gap between 31 Jan 2018 - 01 Apr 2018 taken into account 
				
			* Follow-up time 
				gen fup = (_t-_t0)
				total fup
				global fup = e(b)[1,1]
				di %16.0fc $fup // 1,799,212,506
				
			* Save _t0 variables 
				rename _t0 t0 
				
			* Stest with id 
				stset end, failure(d==1) enter(start) origin(baseline_d) id(patient)
				*list patient start end plan baseline_d end_d _t0 _t _st if inlist(patient, 4688820), sepby(pat) // patient considered at risk between 31 Jan 2018 - 01 Apr 2018, gap in follow-up ignored
				
			* Fix _t0 
				replace _t0 =t0 
				
			* Follow-up time 
				gen fup1 = (_t-_t0)
				total fup1
				global fup1 = e(b)[1,1]
				di %16.0fc $fup1 // 1,799,212,506
				assert $fup == $fup1
				
			* Clean 
				keep patient sex baseline_d pop start end plan *_tvc age year d _* oat1
				
		* Save 
			save "$clean/`j'", replace
			
	}
	