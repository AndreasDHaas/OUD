
* GENERATE DATASET FOR MORTALITY ANALYSIS - PATIENTS ARE FOLLOWED FROM BASELINE TO LINKAGE DATE OR DEATH D. 
	* Individuals are follwed from baseline_d to linkage_d or death_d, whichever happend first. Earlier censoring, e.g. at the end of active plan + x days can be implemented using the exit() option in stset
	* For individuals who died while being on an active plan end has been set to death_d 
	
	* Merge wide patient table and follow-up table 
		use "$clean/analyseWide", clear
		merge 1:m patient using "$clean/tblFUP", keep(match master)  
		assert _merge ==3
			
	* Clean 
		keep patient baseline_d end_d start end death_y death_d linkage_d linked plan oud* mhd* smi* dep* anx* omd* opi* alc* osu* hiv* n07bc* sud* mdu* t40 t40_sd birth_d sex pop oa*
		compress
	
	* Follow-up vairables for mortality analysis: start1 & end1 
		gen int start1 = start
		gen int end1 = end	
		format start1 end1 %tdD_m_CY
		
	* Indicator for active follow-up (active plan with Medical Aid) or passive follow-up through linkage to NPR
		gen byte active = 1 
		
	* Checks 
		assert start1 !=.
		assert end1 !=.		
		assert linkage_d !=. if linked ==1
		assert death_d !=. if death_y ==1
		assert death_y ==1 if death_d !=.
		
	* OAT initiation 
		mmerge patient using "$clean/analyseOAU", uif(event==1) ukeep(oat1_sd)
		gunique pat if oat1_sd !=.
		assert $oat == `r(J)'
		gen oat1 = 1 if oat1_sd !=.
		replace oat1 = 0 if oat1 ==.
		
	* Extend follow-up to linkage date for people who have been linked 
		
		* List examples 
			*listif patient baseline_d start end start1 end1 death_d death_y linked linkage_d if linked==1, id(patient) sort(patient start1) seed(5) n(5) nolab

		* Flag cases 
			bysort patient (start1): gen temp = 1 if linked ==1 & end1 < linkage_d & _n ==_N
			*listif patient baseline_d start end start1 end1 death_d death_y linked linkage_d active temp if linked==1, id(patient) sort(patient start1) seed(5) n(5) nolab
		
		* Create addition record for passive follow-up period 
			expand 2 if temp==1, gen(temp1)
			replace active = 0 if temp==1 & temp1 ==1
			*listif patient baseline_d start end start1 end1 death_d death_y linked linkage_d active temp* if temp==1, id(patient) sort(patient start1 temp1) seed(5) n(5) nolab	
			
		* Assert number of rows added matches the number of linked individuals 
			count if active ==0
			local N = `r(N)'
			gunique pat if linked==1
			assert `r(J)' == `N'
			
		* Start date of passive follow-up 
			bysort patient (start1 temp1): replace start1 = end1[_n-1] if active ==0
			*listif patient baseline_d start end start1 end1 death_d death_y linked linkage_d active temp* if temp==1, id(patient) sort(patient start1 temp1) seed(5) n(5) sepby(pat) nolab
		
		* End date of passive follow-up 
			replace end1 = linkage_d if active ==0
			*listif patient baseline_d start end start1 end1 death_d death_y linked linkage_d active temp* if temp==1, id(patient) sort(patient start1 temp1) seed(5) n(5) sepby(pat) nolab
			drop temp*
		
		
	* Extend follow-up for people who have not been linked but a death_d after end of plan 
		
		* List examples 
			*listif patient baseline_d start end start1 end1 end_d death_d death_y linked linkage_d active if death_d > end_d & linked ==0 & death_y ==1, id(patient) sort(patient start1) seed(5) n(5) sepby(pat) nolab
		
		* Flag cases 
			bysort patient (start1): gen temp = 1 if death_d > end1 & linked ==0 & death_y ==1 & _n ==_N
			
		* Confirm number of cases 
			count if temp ==1
			local N = `r(N)'
			gunique pat if death_d > end_d & death_d !=. & linked ==0
			assert `r(J)' == `N'
			
		* Create addition record for passive follow-up period 
			expand 2 if temp==1, gen(temp1) // without linkage only few deaths were recorded after end of plan. 
			replace active = 0 if temp==1 & temp1 ==1 & linked ==0
			*listif patient baseline_d start end start1 end1 end_d death_d death_y linked linkage_d active if death_d > end_d & linked ==0 & death_y ==1, id(patient) sort(patient start1 temp1) seed(5) n(5) sepby(pat) nolab
				
		* Start date of passive follow-up 
			bysort patient (start1 temp1): replace start1 = end1[_n-1] if active ==0 & linked ==0
			
		* End date of passive follow-up 
			replace end1 = death_d if active ==0 & linked ==0
			*listif patient baseline_d start end start1 end1 end_d death_d death_y linked linkage_d active if death_d > end_d & linked ==0 & death_y ==1, id(patient) sort(patient start1 temp1) seed(5) n(5) sepby(pat) nolab
	
	* Death indicator 
		gen byte d = 0
		
	* Set end1 to death_d if patients died 
		
		* Died during active follow-up: end in _n=_N has been set to death_d 
			*listif patient baseline_d start end start1 end1 end_d death_d death_y linked active d if death_d == end_d, id(patient) sort(patient start1) seed(5) n(5)sepby(pat) nolab
			
		* Indiviudals who died during follow-up had no passive follow-up: last row can be dropped 
			drop if active ==0 & end_d == death_d
			replace d = 1 if death_d == end1 & end_d == death_d
		
		* Assert number of deaths during active follow-up match _d 
			count if d == 1
			local N = `r(N)'
			gunique pat if end_d == death_d
			assert `r(J)' == `N'
			
		* Died after end of active plan 
			*listif patient baseline_d start end start1 end1 end_d death_d death_y linked active d if death_d > end_d & death_d !=., id(patient) sort(patient start1) seed(5) n(5)sepby(pat) nolab
			replace d = 1 if active ==0 & death_d !=. & death_d >= start1 & death_d <=end1
			replace end1=death_d if active ==0 & death_d !=. & death_d >= start1 & death_d <=end1
		
	* Checks 
			
		* Assert number of deaths match _d
			count if d ==1
			local N = `r(N)'
			gunique pat if death_d !=.
			assert `r(J)' == `N'	
			
		* Assert event date is death_d if d==1
			assert death_d == end1 if d ==1	
			
		* Missings 
			foreach var in patient baseline_d end_d start end start1 end1 active d linked {
				assert `var' !=. 
			}
			
	* Clean 
		drop start end temp*
		rename start1 start
		rename end1 end
		order patient baseline_d start end active d
		lab var end_d "End of active follow-up"
			
	* Stset 
		
		* Initial stset: without id() to account for gaps in follow-up. id() ignores gaps in follow-up. see e.g. if inlist(patient, 4688820)
			gen f=0
			stset end, failure(f==1) enter(start) origin(baseline_d) // 
			format _origin %tdD_m_CY
			list patient baseline_d start end plan _t0 _t _d _origin _st if inlist(patient, 131, 220, 3277519, 7943775, 10607658, 4688820), sepby(pat) // example patients: 4688820 has a gap in follow-up
			
		* Follow-up time  
			gen fup = (_t-_t0)
			total fup
			global fup = e(b)[1,1]
			di %16.0fc $fup // 2,963,287,124 total analysis time at risk and under observation
		
		* Assert that all indiviudals in study have time at risk 
			bysort patient (start): egen st = max(_st) 
			assert st ==1 
			drop st
			
		* Drop rows without follow-up time
			drop if _st ==0
		
		* Left truncate at baseline_date -> set start1 to baseline date in first observation 
			gen start1 = _origin + _t0, after(start)
			format start1 %tdD_m_CY
			list patient baseline_d start start1 end plan _t0 _t _d _origin _st if inlist(patient, 131, 220, 3277519, 7943775, 10607658, 4688820), sepby(pat) // example patients: 4688820 has a gap in follow-up
			drop start
			rename start1 start
								
		* Stset with new stset 
			stset end, failure(f==1) origin(start) 
			format _origin %tdD_m_CY
			list patient baseline_d start end plan _t0 _t _d _origin _st if inlist(patient, 131, 220, 3277519, 7943775, 10607658, 4688820), sepby(pat) // example patients: 4688820 has a gap in follow-up
			
		* Assert total follow-up time has not changed with new stset 
			gen fup1 = (_t-_t0)
			total fup1
			global fup1 = e(b)[1,1]
			di %16.0fc $fup1 
			assert $fup == $fup1
			drop fup fup1
			macro drop fup1
							
	* Split at event date and create time-varying predictor: see Example 3: Explanatory variables that change with time in Stata help pdf 
		
		* Checks 
			foreach var in patient start end oud mhd smi dep anx omd opi alc osu hiv n07bc sud mdu {
				assert `var' !=.
			}
			assert _st ==1
			
		* Split 
			splittvc patient start end oa_sd oa, listid(131, 5631) nolab  // OA sd 
			splittvc patient start end oud_sd oud, listid(131, 5631) nolab  // Opioid use disorder
			splittvc patient start end n07bc_sd n07bc, listid(131, 5631) nolab  // Drugs used in opioid dependence 		
			splittvc patient start end t40_sd t40, listid(131, 5631) nolab  // T40
			splittvc patient start end oat1_sd oat1, listid(10024488, 7776865, 8527979) nolab  // OAT initiation 
			splittvc patient start end mhd_sd mhd, listid(161, 2148, 1253, 4688820) nolab  // Mental health diagnosis
				splittvc patient start end smi_sd smi, listid(161, 10232799, 1555, 4688820) nolab  // Serious mental disorder		
				splittvc patient start end dep_sd dep, listid(131, 13568265, 1555) nolab  // Depression
				splittvc patient start end anx_sd anx, listid(131, 10564787, 1555) nolab  // Anxiety 		
				splittvc patient start end omd_sd omd, listid(1253, 9708396, 1555) nolab  // Other mental disorder
			splittvc patient start end sud_sd sud, listid(35108, 1555) nolab  // Substance use diagnosis 		
				splittvc patient start end opi_sd opi, listid(359284, 1555) nolab  // Opioid use diagnosis
				splittvc patient start end alc_sd alc, listid(77300, 1555) nolab  // Alcohol use diagnosis
				splittvc patient start end osu_sd osu, listid(38004, 1555) nolab  // Other substance use diagnosis		
				splittvc patient start end mdu_sd mdu, listid(77300, 1555) nolab  // Multiple drug use	
			splittvc patient start end hiv_sd hiv, listid(22916, 1555) nolab  // HIV
			
		* Checks 
			foreach var in patient start end oud {
				assert `var' !=.
			}
			assert _st ==1
			
	* Split follow-up time by age_group 
	
		* Generate fake id	
			sort patient start 
			gen fid = _n
			
		* Stset 
			stset end, failure(f==1) enter(start) origin(birth_d) scale(365) id(fid)
			format _origin %tdD_m_CY
			list fid patient baseline_d start end plan _t0 _t _d _origin _st if pat==4688820
			stsplit age, every(10)
			list fid patient baseline_d start end plan _t0 _t _d _origin _st age if pat==4688820
			lab var age "Age (time-varying)"
			lab define age 10 "11-19" 20 "20-29" 30 "30-39" 40 "40-49" 50 "50-59" 60 "60-69" 70 "70+", replace
			lab val age age
			replace age = 70 if age >70 & age !=.
			tab age, mi
			assert age !=. 
			gen start1 = _origin + _t0*365, after(start) // stsplit is updating _t0 _t _d and end but not start <- update start based on _origin and _t0
			format start1 %tdD_m_CY 
			list patient age baseline_d start start1 end plan _t0 _t _d _origin _st if pat==4688820
			drop start 
			rename start1 start
			
		* Assert total follow-up time has not changed with new stset 
			stset end, failure(f==1) enter(start) origin(time d(01/01/2011)) scale(365) 			
			gen fup1 = (_t-_t0)*365
			total fup1
			global fup1 = e(b)[1,1]
			di %16.0fc $fup1 // 
			assert $fup == $fup1
			drop fup1 fid
			macro drop fup1
		
	* Split by calendar year 
	
		* Generate fake id	
			sort patient start 
			gen fid = _n
		
		* Stset 
			stset end, failure(f==1) id(fid) enter(start) origin(time d(01/01/2011)) 
			list patient age baseline_d start end plan _t0 _t _d _st if inlist(patient, 131), sepby(pat) 
			stsplit year, at(365 731 1096 1461 1826 2192 2557 2922 3287 3653 4018 4383 4748 5114) // every 365 or 366 days for leap years (2012, 2016, 2020)
			list patient age year baseline_d start end plan _t0 _t _d _st if inlist(patient, 131), sepby(pat) 
			replace year = round(2011 + year/365)
			gen start1 = d(01/01/2011) + _t0, after(start)
			format start1 %tdD_m_CY 
			list patient age year baseline_d start* end plan _t0 _t _d _st if inlist(patient, 131), sepby(pat) 
			drop start fid
			rename start1 start
			
		* Assert total follow-up time has not changed with new stset 
			stset end, failure(f==1) origin(start) 
			gen fup1 = (_t-_t0)
			total fup1
			global fup1 = e(b)[1,1]
			di %16.0fc $fup1 // 2,963,287,124
			assert $fup == $fup1
			macro drop fup1
			
		* Year_cat
			recode year (2011/2012=1 "2011-2012") (2013/2014=2 "2013-2014") (2015/2016=3 "2015-2016") (2017/2018=4 "2017-2018") (2019/2021=5 "2019-2021") (else=9), gen(year_cat5) 
			recode year (2011/2013=1 "2011-2013") (2014/2016=2 "2014-2016") (2017/2019=3 "2017-2019") (2020/2021=4 "2020-2021") (else=9), gen(year_cat4) test
			
	* Correct _d	
		listif patient start end death_d d if d==1, sepby(pat) id(patient) sort(patient start) seed(5) n(5) nolab
		replace d = 0 if end < death_d
			
	* Checks 	
			
		* Assert number of deaths match _d
			count if d ==1
			local N = `r(N)'
			gunique pat if death_d !=.
			assert `r(J)' == `N'	
			
		* Assert event date is death_d if d==1
			assert death_d == end if d ==1	
			
		* Missings 
			foreach var in patient baseline_d end_d start end start end active d linked {
				assert `var' !=. 
			}
			
		* Checks 
			foreach var in patient start end oud_tvc mhd_tvc smi_tvc dep_tvc anx_tvc omd_tvc opi_tvc alc_tvc osu_tvc hiv_tvc year age {
				assert `var' !=.
			}
			assert _st ==1
			
		* Clean 
			drop _* fup1
			
		* Compress
			compress
			
		* Passive 
			gen byte passive = 1-active 
		
	* Save 
		save "$clean/Mortality", replace
		use "$clean/Mortality",clear
		

