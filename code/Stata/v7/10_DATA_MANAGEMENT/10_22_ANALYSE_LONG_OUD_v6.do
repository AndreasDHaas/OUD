
* GENERATE DATASET FOR ANALYSIS OF OUD INCIDENCE  

	* Merge datasets 
		use "$clean/analyseWide", clear
		gunique pat
		global N = r(J)
		assert `r(maxJ)' ==1
		merge 1:m patient using "$clean/tblFUP", keep(match) nogen 
		gunique pat
		assert r(J)==$N
		bysort patient (start): gen n = _n
		bysort patient (start): gen N = _N
		
	* Clean 
		drop f110_sd f110 f111_sd f111 f112_sd f112 f113_sd f113 f114_sd f114 f115_sd f115 f116_sd f116 f117_sd f117 f118_sd f118 f119_sd f119 t400_sd t400 t401_sd t401 t403_sd t403 afa ///
		med_id icd10_code program birth_d_a race invalid cod n
		
	* Compress
		compress
		
	* OAT initiation 
		mmerge patient using "$clean/analyseOAU", uif(event==1) ukeep(oat1_sd) unmatched(master)
		gunique pat if oat1_sd !=.
		assert $oat == `r(J)'
		gen oat1 = 1 if oat1_sd !=.
		replace oat1 = 0 if oat1 ==.
		
	* List
		list patient start end plan baseline_d end_d if inlist(patient, 4688820), sepby(pat) 
		*listif patient baseline_d start end plan if N >1, id(patient) sort(patient start) seed(1)
				
	* Stset 
		
		* Initial stset: without id() to account for gaps in follow-up. id() ignores gaps in follow-up. see e.g. if inlist(patient, 4688820)
			gen f=0
			stset end, failure(f==1) enter(start) origin(baseline_d) // 
			format _origin %tdD_m_CY
			*listif patient baseline_d start end plan _t0 _t _d _origin _st if N >1, id(patient) sort(patient start) seed(1) n(10)
			list patient baseline_d start end plan _t0 _t _d _origin _st if inlist(patient, 131, 220, 3277519, 7943775, 10607658), sepby(pat) // example patients
			list patient baseline_d start end plan _t0 _t _d _origin _st if inlist(patient, 4688820), sepby(pat) // patient with gap 31 Jan 2018 - 01 Apr 2018
			
		* Follow-up time  
			gen fup = (_t-_t0)
			total fup
			global fup = e(b)[1,1]
			di %16.0fc $fup // 1,798,765,969 total analysis time at risk and under observation, 1,489,206  observations remaining, representing
			
		* Median follow up time 
			bysort patient (start): egen fupY = total(fup)
			replace fupY = fupY/365
			bysort patient (start): replace fupY = . if _n !=1
			format fupY %3.1fc
			sum fupY, de f
		
		* Assert that all indiviudals in study have time at risk 
			bysort patient (start): egen st = max(_st) 
			listif patient baseline_d start end plan _t0 _t _d _origin _st st if st==0, id(patient) sort(patient start) seed(1)
			assert st ==1 
			drop st
			
		* Drop rows without follow-up time
			drop if _st ==0
		
		* Left truncate at baseline_date -> set start1 to baseline date in first observation 
			gen start1 = _origin + _t0, after(start)
			format start1 %tdD_m_CY
			list patient baseline_d start start1 end plan _t0 _t _d _origin _st if inlist(patient, 131, 3277519, 7943775, 10607658), sepby(pat) // example patients
			list patient baseline_d start start1 end plan _t0 _t _d _origin _st  if inlist(patient, 4688820), sepby(pat) // patient with gap 31 Jan 2018 - 01 Apr 2018
			drop start
			rename start1 start
								
		* Stset with new stset 
			stset end, failure(f==1) origin(start) 
			format _origin %tdD_m_CY
			list patient baseline_d start end plan _t0 _t _d _origin _st if inlist(patient, 131, 3277519, 7943775, 10607658), sepby(pat) // example patients
			list patient baseline_d start end plan _t0 _t _d _origin _st  if inlist(patient, 4688820), sepby(pat) // patient with gap 31 Jan 2018 - 01 Apr 2018
			
		* Assert total follow-up time has not changed with new stset 
			gen fup1 = (_t-_t0)
			total fup1
			global fup1 = e(b)[1,1]
			di %16.0fc $fup1 // 1,801,151,400
			assert $fup == $fup1
			drop fup fup1
			macro drop fup1
							
	* Split at event date and create time-varying predictor: see Example 3: Explanatory variables that change with time in Stata help pdf 
		
		* Checks 
			foreach var in patient start end oud mhd smi dep anx omd opi alc osu hiv {
				assert `var' !=.
			}
			assert _st ==1
			
		* Split 
			splittvc patient start end oud_sd oud, listid(131, 5631) nolab  // Opioid use disorder
			splittvc patient start end n07bc_sd n07bc, listid(131, 5631) nolab  // Drugs used in opioid dependence
			*splittvc patient start end equity_sd equity, listid(131, 5631) nolab  // Equity methadone
			splittvc patient start end oa_sd oa, listid(131, 5631) nolab  // OA sd 
			splittvc patient start end oat1_sd oat1, listid(10024488, 7776865, 8527979) nolab  // OAT initiation 
			splittvc patient start end mhd_sd mhd, listid(161, 2148, 1253, 4688820) nolab  // Mental health diagnosis
				splittvc patient start end smi_sd smi, listid(161, 10232799, 1555, 4688820) nolab  // Serious mental disorder		
				splittvc patient start end dep_sd dep, listid(131, 13568265, 1555) nolab  // Depression
				splittvc patient start end anx_sd anx, listid(131, 10564787, 1555) nolab  // Anxiety 		
				splittvc patient start end omd_sd omd, listid(1253, 9708396, 1555) nolab  // Other mental disorder
			splittvc patient start end sud_sd sud, listid(35108, 1555) nolab  // Substance use diagnosis 		
				splittvc patient start end opi_sd opi, listid(359284, 1555) nolab  // Opioid use diagnosis
				splittvc patient start end alc_sd alc, listid(77300, 1555) nolab  // Alcohol use diagnosis
				splittvc patient start end mdu_sd mdu, listid(77300, 1555) nolab  // Multiple drug use	
				splittvc patient start end osu_sd osu, listid(38004, 1555) nolab  // Other substance use diagnosis		
			splittvc patient start end hiv_sd hiv, listid(22916, 1555) nolab  // HIV
			
		* Checks 
			foreach var in patient start end oud {
				assert `var' !=.
			}
			assert _st ==1
			
	* Save 
		*save "$clean/analyseLong", replace
		*use "$clean/analyseLong",clear
			
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
			di %16.0fc $fup1 // 1,801,151,400
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
			di %16.0fc $fup1 // 1,801,151,400
			assert $fup == $fup1
			macro drop fup1
	
		* List 
			list patient baseline_d age year start end _t0 _t _d _st mhd_tvc mhd_sd dep_tvc smi_tvc smi_sd if inlist(patient, 131, 10642363), sepby(pat) 
			listif patient baseline_d age year start end _t0 _t _d _st n07bc_sd f11_sd t40_sd oud_sd oud_tvc end_d if oud ==1, sepby(patient) sort(patient start) n(5) id(patient) nolab
			
		* Checks 
			foreach var in patient start end oud_tvc mhd_tvc smi_tvc dep_tvc anx_tvc omd_tvc opi_tvc alc_tvc osu_tvc hiv_tvc {
				assert `var' !=.
			}
			assert _st ==1
			
		* Clean 
			drop _* N fup1
			
		* Compress
			compress
				
	* Save 
		save "$clean/analyseLong", replace
		use "$clean/analyseLong",clear
		
	/* Final st-set 
	
		* Stset without id 
			stset end, failure(f==1) enter(start) origin(baseline_d) 
			list patient start end plan baseline_d end_d _t0 _t _st if inlist(patient, 4688820), sepby(pat) // gap between 31 Jan 2018 - 01 Apr 2018 taken into account 
			
		* Save _t and _t0 variables 
			rename _t0 t0 
			rename _t t 
			
		* Stest with id 
			stset end, failure(f==1) enter(start) origin(baseline_d) id(patient)
			list patient start end plan baseline_d end_d _t0 _t _st if inlist(patient, 4688820), sepby(pat) // patient considered at risk between 31 Jan 2018 - 01 Apr 2018, gap in follow-up ignored
			
		* Fix _t0 
			replace _t0 =t0 
			replace _t =t
			
		* Follow-up time 
			gen fup1 = (_t-_t0)
			total fup1
			global fup1 = e(b)[1,1]
			di %16.0fc $fup1 // 1,801,151,400
			assert $fup == $fup1
			macro drop fup1			
			
		* Total follow-up time for each patient 
			bysort patient (start): egen fupT = total(fup1)
			bysort patient (start): replace fupT = . if _n !=1
			total fupT
			global fup1 = e(b)[1,1]
			di %16.0fc $fup1 // 1,801,151,400
			list patient start end plan baseline_d end_d _t0 _t _st fup1 fupT if inlist(patient, 4688820), sepby(pat) 
			
		* Median follow-up time 
			replace fupT = fupT/365.25
			format fupT %3.1fc
			sum fupT, d f // 3.2 years IQR 1.2-6.3

