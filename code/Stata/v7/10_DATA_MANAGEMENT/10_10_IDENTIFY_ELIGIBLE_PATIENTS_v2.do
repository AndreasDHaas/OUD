	* Identify patients with persontime at risk after 1 Jan 2011
			
		* Date 
			use "$clean/tblFUP", clear
			mmerge patient using "$clean/tblBAS", ukeep(birth_d sex) 
			drop if _merge ==2 // drop patients without record in FUP table 
			drop _merge
									
		* Failure 
			gen f = 0
					
		* List 
			list patient patient start end plan f if inlist(patient, 617, 3357038, 7186878, 9538622, 5684690, 13214104), sepby(patient)
			listif if end==., id(patient) sort(patient start) n(10) seed(10)
					
		* Set start before 1 Jan 2011 to 1 Jan 2011
			gen int start2011 = start, after(start)
			replace start2011 = d(01/01/2011) if start < d(01/01/2011) 
			format start2011 %tdD_m_CY
					
		* Setset 
			stset end, failure(f==1) scale(365.25) id(patient) origin(start2011) 
			format _origin %tdD_m_CY
			
		* Select patients at risk
			keep if _st==1
			
		* List 
			listif patient start start2011 end plan f _st _d _origin _t _t0 if start < d(01/01/2011), id(patient) sort(patient start) n(10) seed(10)
			list patient start start2011 end plan f _st _d _origin _t0 _t if inlist(patient, 617, 3357038, 7186878, 9538622, 5684690, 13214104), sepby(patient)
			
		* Clean
			keep patient start end birth_d sex
			
		* Determine baseline: start date of each plan, 1 Jan 2011 or 11th birthday, whichever occured later 
			gen age11 = birth_d + 365*11
			gen year2011 = d(01/01/2011)
			format %td age11 year2011
			egen baseline_d = rowmax(start age11 year2011)
			format baseline_d %tdD_m_CY
			list if inlist(patient, 617, 3357038, 7186878, 9538622), sepby(patient)
			list if inlist(patient, 981958, 2839099, 7605964, 8694130), sepby(pat) // special cases, earliest baseline date during gap in follow-up -> use baseline date of next follow-up interval 
			gunique patient
			global N = `r(J)'
			drop if baseline_d >= end 
			gunique patient 
			di $N-`r(J)'  // <- CONSORT:  excluded because younger than 11 during follow-up // 279,644
			list if inlist(patient, 981958, 2839099, 7605964, 8694130), sepby(pat) // special cases
			global drop N
			bysort patient (start): egen end_d = max(end)
			format end_d %tdD_m_CY
			list if pat ==1314657, sepby(pat)
			
		* Keep erliest baseline date
			bysort patient (baseline_d): keep if _n ==1
			
		* Drop patient with unknown gender
			drop if sex ==3
			
		* Missing age 
			gen age_bl = floor((baseline_d-birth_d)/365)
			drop if age_bl ==. 
			assert age_bl >=11
			
		* Death before baseline_d 
			merge 1:1 patient using "$clean/tblVITAL", nogen keep(match) keepusing(death_d)
			listif patient start end birth_d baseline_d death_d end_d if death_d < baseline_d & death_d !=., id(patient) sort(patient start) seed(1) n(10)
			assert death_d >= baseline_d if death_d !=.
		
		* Clean 		
			drop end birth_d age11 year2011 start death_d
			
		* Save 
			save "$temp/patients", replace
