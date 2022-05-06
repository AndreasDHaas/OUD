		
	* DEDUPLICATE TABLE BY PATIENT MED_SD
		
		* Open medclaims and select methadone or buprenorphine
			use if regexm(med_id, "N07BC") using "$clean/tblMED_ATC_N", clear
			
		* Remove claims of patients not in patient table 
			merge m:1 patient using "$clean/analyseWide", keep(match) keepusing(baseline_d equity) nogen
			listif patient baseline_d med_sd med_id nappi_code nappi_suffix quantity strength type nappi_description equity if equity ==0 & nappi_description=="EQUITY METHADONE", sort(patient med_sd) sepby(patient) seed(1) n(10) id(pat) 
			
		* Drop prescriptions before baseline_d
			drop if med_sd < baseline_d
			
		* Drugs 
			tab nappi_code, sort
			*listif patient med_sd med_id nappi_code nappi_suffix quantity strength type nappi_description if nappi_code=="714417", sort(patient med_sd) sepby(patient) seed(1) n(10) id(pat) // EQUITY METHADONE
			*listif patient med_sd med_id nappi_code nappi_suffix quantity strength type nappi_description if nappi_code=="755303", sort(patient med_sd) sepby(patient) seed(1) n(10) id(pat) // PHYSEPTONE LINCTUS	
			*listif patient med_sd med_id nappi_code nappi_suffix quantity strength type nappi_description if nappi_code=="714064", sort(patient med_sd) sepby(patient) seed(1) n(10) id(pat) // SUBOXONE 8MG/2MG
			*listif patient med_sd med_id nappi_code nappi_suffix quantity strength type nappi_description if nappi_code=="714063", sort(patient med_sd) sepby(patient) seed(1) n(10) id(pat) // SUBOXONE 2MG/0.50MG			
			
		* Mg active agent per unit (ml or tablet) 
			tab strength
			gen mpu = 2 if strength == "2mg/1mL" // 		2mg/1mL    SOL   	EQUITY METHADONE
			replace mpu = 0.4 if strength == "2mg/5ml" // 	2mg/5ml    SUS  	PHYSEPTONE LINCTUS
			replace mpu = 8 if nappi_code=="714064"   // 	8MG 	   ""	   	SUBOXONE 8MG/2MG		
			replace mpu = 2 if nappi_code=="714063"   // 	2MG        ""	    SUBOXONE 2MG/0.50MG	
			assert mpu !=.
							
		* Amount of active ingridients dispensed (in mg)
			gen mg = mpu * quantity, after(strength)		

		* List 
			*listif patient med_sd med_id nappi_code nappi_suffix quantity strength mpu mg type nappi_description if nappi_code=="714417", sort(patient med_sd) sepby(patient) seed(1) n(10) id(pat) // EQUITY METHADONE
			*listif patient med_sd med_id nappi_code nappi_suffix quantity strength mpu mg type nappi_description if nappi_code=="755303", sort(patient med_sd) sepby(patient) seed(1) n(10) id(pat) // PHYSEPTONE LINCTUS	
				
		* Add up mg for several claims with same nappi_code on same med_sd 
			listif patient med_sd med_id nappi_code nappi_suffix quantity strength mpu mg if pat ==1826000, sort(patient med_sd) sepby(patient) seed(1) n(10) id(pat) 	
			bysort patient med_sd nappi_code: egen mg1 = total(mg)
			listif patient med_sd med_id nappi_code nappi_suffix quantity strength mpu mg mg1 if pat ==1826000, sort(patient med_sd) sepby(patient) seed(1) n(10) id(pat) 
			bysort patient med_sd nappi_code: keep if _n ==1
			
		* Drop zero mg
			listif patient med_sd med_id nappi_code nappi_suffix quantity strength mpu mg mg1 if mg1==0, sort(patient med_sd) sepby(patient) seed(1) n(100) id(pat) 
			drop if mg1 ==0
			assert mg1 > 0
			drop mg
			
		* Merge baselines 
			mmerge patient using "$clean/analyseWide", unmatched(master) ukeep(sex baseline_d end_d methadone_sd methadone f11 f11_sd t40 t40_sd oud_sd oud birth_d pop n07bc)
			gen age = floor((med_sd-birth_d)/365)
			drop birth_d
			
		* Dropo after end 
			drop if med_sd > end_d 
			
		* Drop physeptone only 			
			tab nappi_description if equity ==0
			drop if equity ==0 & !regexm(nappi_desc, "SUBOXONE")
			
		* Drop patients who only received 

		* All on n07bc
			assert n07bc==1
			
		* Confirm number of patients who received equity ==1 | buprenorphine drugs according to master table
			preserve 
			use "$clean/analyseWide", clear
			count if equity ==1 | buprenorphine ==1
			local N = `r(N)'
			restore 
			gunique patient 
			assert `r(J)' ==`N'
				
		* Medication event: new med_sd   
			preserve 
			keep patient med_sd 
			bysort patient med_sd: keep if _n ==1 
			bysort patient (med_sd):  gen int event = _n 
			tempfile event
			save `event'
			restore 
			merge m:1 patient med_sd using `event', assert(match) nogen
			*listif patient med_sd med_id nappi_code nappi_suffix quantity strength mpu mg nappi_description event if inlist(pat, 490199,  6094133, 11861898), sort(patient med_sd) sepby(patient) seed(1) n(10) id(pat) 	
			
		* Several drugs per event 
			bysort patient event (med_sd): gen N = _N
			*listif patient med_sd med_id nappi_code nappi_suffix quantity strength mpu mg* nappi_description event N if N>1, sort(patient med_sd) sepby(patient N) seed(1) n(100) id(pat) 	
			
		* Drug 
			gen drug = inlist(nappi_code, "714417", "755303")
			lab define drug 1 "Methadone" 0 "Buprenorphine", replace
			lab val drug drug
			
		* Combine data of several claims with same drug on same med_sd: e.g. EQUITY METHADONE & PHYSEPTONE LINCTUS on same day 
		
			* Add up mg 
				*listif patient med_sd med_id nappi_code nappi_suffix quantity strength mpu mg* nappi_description event N if N>1, sort(patient med_sd) sepby(patient N) seed(1) n(100) id(pat) 	
				bysort patient event drug: egen mg2 = total(mg1)
				*listif patient med_sd med_id nappi_code nappi_suffix quantity strength mpu mg* nappi_description event N if N>1, sort(patient med_sd) sepby(patient N) seed(1) n(100) id(pat) 
				
			* Combine nappi code & nappi description
				levelsof nappi_code, clean
				foreach n in `r(levels)' {
					gen temp_`n' = 1 if nappi_code == "`n'"
					bysort patient event: egen temp1_`n' = max(temp_`n')
					drop temp_`n'
				}
				gen nappi_code1 = nappi_code, after(nappi_code)
				*listif patient med_sd med_id nappi_code quantity strength mpu mg* nappi_description event N temp1_* if N>1, sort(patient med_sd) sepby(patient N) seed(1) n(100) id(pat) 
				replace nappi_code1 = "714063 714064" if temp1_714063 ==1 & temp1_714064 ==1
				replace nappi_code1 = "755303 714417" if temp1_755303 ==1 & temp1_714417 ==1
				gen nappi_description1 = nappi_description
				replace nappi_description1 = "SUBOXONE 2MG/0.50MG & 8MG/2MG"  if temp1_714063 ==1 & temp1_714064 ==1
				replace nappi_description1 = "EQUITY METHADONE & PHYSEPTONE LINCTUS" if temp1_755303 ==1 & temp1_714417 ==1
				*listif patient med_sd med_id nappi_code quantity strength mpu mg* nappi_description1 event N temp1_* if N>1, sort(patient med_sd) sepby(patient N) seed(1) n(100) id(pat) 			
				drop temp*
				*listif patient med_sd med_id nappi_code1 nappi_suffix quantity strength mpu mg* nappi_description1 event N if N>1, sort(patient med_sd) sepby(patient N) seed(1) n(100) id(pat) 
				bysort patient event drug: keep if _n ==1
				*listif patient med_sd med_id nappi_code quantity strength mpu mg* nappi_description1 event N if N>1, sort(patient med_sd) sepby(patient N) seed(1) n(100) id(pat)
			
		* Update N 
			bysort patient event: replace N =_N
			assert N ==1 // no patient received methadone and buprenorphine on the same day 
			
		* Clean & rename updated variables 
			drop nappi_code nappi_description mg1 mpu strength quantity N
			rename nappi_code1 nappi_code
			rename nappi_description1 nappi_description
			rename mg2 mg
			*listif patient med_sd med_id nappi_code mg nappi_description event if event>1, sort(patient med_sd) sepby(patient) seed(1) n(100) id(pat)	
				
		* Days to next claim 
			bysort patient (med_sd): gen dtn = med_sd[_n+1] - med_sd
			*listif patient med_sd med_id nappi_code mg nappi_description event dtn if event>1, sort(patient med_sd) sepby(patient) seed(1) n(100) id(pat)				
			
		* Dose per day 
			gen dose = mg/dtn
			format dose %3.1fc
			*listif patient med_sd med_id nappi_code mg nappi_description event dtn dose if event>1, sort(patient med_sd) sepby(patient) seed(1) n(100) id(pat)		
			
	* DEFINE TREATMENT EPISODES AND OAT EPISODES
			
		* Treatment episode: refill within 30 35 90 days is same episode 
			
			* Calculate days from previous claim 
				bysort patient (med_sd): gen dfp = (med_sd[_n-1] - med_sd) *-1
				*listif patient med_sd med_id nappi_code mg nappi_description event dfp dose if event>1, sort(patient med_sd) sepby(patient) seed(1) n(100) id(pat)
				*listif patient med_sd med_id nappi_code mg nappi_description event dfp dose,  sort(patient med_sd) sepby(patient) seed(1) n(100) id(pat)
				
			* Loop over time intervals considered the same treatment episode 
				foreach j in 35 65 95 {	
				
					* Episode number 
						gen episode`j' = 0 if dfp <=`j' 
						replace episode`j' = 1 if dfp >`j' & dfp !=. 
						replace episode`j' = 0 if dfp ==.
						*listif patient med_sd med_id nappi_code mg nappi_description event dfp dose episode`j' if episode`j'>5, sort(patient med_sd) sepby(patient) seed(1) n(100) id(pat)
						*listif patient med_sd med_id nappi_code mg nappi_description event dfp dose episode`j', sort(patient med_sd) sepby(patient) seed(1) n(100) id(pat)
						assert episode`j' !=.
						bysort patient (med_sd): replace episode`j' = episode`j' + episode`j'[_n-1] if episode`j'[_n-1] !=. 
						replace episode`j' = episode`j' + 1
						*listif patient med_sd med_id nappi_code mg nappi_description event dfp dose episode`j', sort(patient med_sd) sepby(patient) seed(1) n(100) id(pat)	
						*listif patient med_sd med_id nappi_code mg nappi_description event dfp dose episode`j', sort(patient med_sd) sepby(patient) seed(1) n(100) id(pat)		
					
					* Set dose to missing if new episode begins. Dose can only be estimated during a treatment episode 
						gen dose`j' = dose
						format dose`j' %3.1fc
						bysort patient (med_sd): replace dose`j' =. if episode`j'!=episode`j'[_n+1]
						
					* Event within episode 
						bysort patient episode`j' (med_sd): gen epi`j'_n =_n
						
					* Number of episodes 
						bysort patient (med_sd): egen epi`j'_N =max(episode`j')
						recode epi`j'_N (1=1 "1") (2=2 "2") (3/max =3 "3+"), gen(epi`j'_N_cat) 
				}
				
		* List 
			listif patient med_sd med_id nappi_code mg nappi_description event dfp dose episode35 dose35 epi35_n epi35_N, sort(patient med_sd) sepby(patient) seed(1) n(100) id(pat)		
			listif patient med_sd med_id nappi_code mg nappi_description event dfp dose episode35 dose35 epi35_n epi35_N if inlist(pat, 8983264, 8539974, 5993130, 5847229, 4506436), sort(patient med_sd) sepby(patient) seed(1) n(100) id(pat)	
			
		* OAT episode: oat initiation if refilled within 35 dfp 
		
			* Mark oat episodes 
				bysort patient (med_sd): gen oat = 1 if episode35[_n+1]==episode35
				
			* Mark beginning of new oat episodes 
				bysort patient (med_sd): gen oat1 = 1 if oat[_n-1]==. & oat ==1
			
			* Add up episode number 
				replace oat1 = 0 if oat1 ==.
				bysort patient (med_sd): replace oat1 = oat1 + oat1[_n-1] if oat1[_n-1] !=. 
				replace oat1 = 0 if oat ==.
				
			* End of oat 
				bysort patient (med_sd): replace oat1 = oat1[_n-1] if  oat1[_n-1] >= 1 & dfp <35
				
			* List 
				*listif patient med_sd med_id nappi_code mg nappi_description event dfp dose episode35 dose35 epi35_n epi35_N oat*, sort(patient med_sd) sepby(patient) seed(1) n(10) id(pat)
				
			* oat_sd & ed 
				levelsof oat1 if oat1 >0
				foreach j in `r(levels)' {
					qui bysort patient: egen int oat`j'_sd = min(med_sd) if oat1 ==`j' 
					qui bysort patient (oat`j'_sd): replace oat`j'_sd = oat`j'_sd[1] 
					qui bysort patient: egen int oat`j'_ed = max(med_sd) if oat1 ==`j' 
					qui bysort patient (oat`j'_ed): replace oat`j'_ed = oat`j'_ed[1]
					format oat`j'_sd oat`j'_ed %tdD_m_CY
				}
			
			* oat_episode 
				drop oat
				rename oat1 oat_epi
				
			* oat_dose: average dose of oat episode 
				bysort patient oat_epi (med_sd): egen days_oat = total(dtn) if oat_epi !=0
				bysort patient oat_epi (med_sd): egen mg_oat = total(mg) if dtn!=. & oat_epi !=0
				gen dose_oat = mg_oat/days_oat
				format dose_oat %3.1fc
				sort patient med_sd 
				
			* oat_event 
				bysort patient oat_epi (med_sd): gen oat_epi_n = _n  if oat_epi !=0
				bysort patient oat_epi (med_sd): gen oat_epi_N = _N  if oat_epi !=0
				replace oat_epi = . if oat_epi ==0
				listif patient med_sd event dtn dfp mg episode35 epi35_n epi35_N oat_epi days_oat mg_oat dose_oat oat_epi oat_epi_n oat_epi_N drug if inlist(pat, 13196861, 8983264, 8539974, 5993130, 4506436), sort(patient med_sd) sepby(patient) seed(1) n(10) id(pat)	
				
			* patient initiated oat
				bysort patient (med_sd): egen int oat = max(oat_epi)
				replace oat = 0 if oat ==.
				replace oat = 1 if oat >1 & oat !=.
		
		* Clean 
			drop account_amount tariff_amount type _merge
			
		* Total number of medication events
			bysort patient (med_sd): gen N = _N
			recode N (1=1 "1") (2=2 "2") (3/5 =3 "3-5") (6/10=6 "5-10") (11/max = 11 ">10"), gen(N_cat) test  
			tab N N_cat
			
		* Descripton 
			gen desc = "" 
			replace desc = "Equity methadone 2mg/1mL" if nappi_code=="714417"	
			replace desc = "Physeptone linctus 2mg/5mL" if nappi_code=="755303"	
			replace desc = "Suboxone 8mg/2mg" if nappi_code=="714064"	
			replace desc = "Suboxone 2mg/0.5mg" if nappi_code=="714063"	
			*replace desc = "Physeptone linctus 2mg/5mL & Equity methadone 2mg/1mL" if nappi_code=="714063 714064"	
			replace desc = "Equity methadone 2mg/1mL" if nappi_code=="714063 714064"	
			*replace desc = "Suboxone 2mg/0.5mg & 8mg/2mg" if nappi_code=="755303 714417"	
			replace desc = "Suboxone 8mg/2mg" if nappi_code=="755303 714417"
			assert desc !=""
	
		* Save 
			save "$clean/analyseOAU", replace
			
		
			
		
		