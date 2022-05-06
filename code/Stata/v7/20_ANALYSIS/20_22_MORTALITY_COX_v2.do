
* FACTORS ASSOCIATED WITH OUD, F11, AND oa INCIDENCE 
		
	* Dataset 
		use "$clean/Mortality",clear
		*keep if pat > 10671393
		
	* Stset: follow-up until linkage date, gaps in Bonitas follow-up ignored, indiviudals are always at risk of mortality 
		
		* Keep linked patients 
			*gunique pat if linked ==1
			*bysort patient (start): egen temp = min(linked)
			*assert temp ==1 if linked ==1
			*listif patient baseline_d start end end_d death_d d _t0 _t _d linked temp if linked==1, sepby(pat) id(patient) sort(patient start) seed(5) n(100) nolab
			keep if linked ==1
			*drop temp
	
		* Stest with id 
			stset end, failure(d==1) enter(start) origin(baseline_d) id(patient)
			*list   patient baseline_d start end end_d death_d d _t0 _t _d if inlist(patient, 4688820), sepby(pat) 
			listif year year_cat4 patient baseline_d start end end_d death_d d _t0 _t _d if d==1, sepby(pat) id(patient) sort(patient start) seed(5) n(5) nolab
			listif year year_cat4 patient baseline_d start end end_d death_d d _t0 _t _d if death_d ==., sepby(pat) id(patient) sort(patient start) seed(5) n(5) nolab
	
	* Univariable analysis 
				
		* Opoid use disorder 
			stcox i.oud_tvc
			matrix oud_tvc = r(table)'
			regtable oud_tvc d, label2("Opioid use problems") adjusted(0) save(d_uni) indent(0) drop(0b.oud_tvc)
			
		* Opi 
			stcox i.opi_tvc
			matrix opi_tvc = r(table)'
			regtable opi_tvc d, label2("Opioid use disorder") adjusted(0) append(d_uni) indent(2) drop(0b.opi_tvc)
			
		* T40 
			stcox i.t40_tvc
			matrix t40_tvc = r(table)'
			regtable t40_tvc d, label2("Opioid poisoning") adjusted(0) append(d_uni) indent(2)	drop(0b.t40_tvc)
			
		* Opi 
			stcox i.oa_tvc
			matrix oa_tvc = r(table)'
			regtable oa_tvc d, label2("Opioid agonist use") adjusted(0) append(d_uni) indent(2) drop(0b.oa_tvc)
		
		* Year 
			stcox i.year_cat4 
			matrix year_cat4 = r(table)'
			regtable year_cat4 d, heading("Year") label1("2011-2013") label2("2014-2016") label3("2017-2019") label4("2020-2021") adjusted(0) append(d_uni) 

		* Passive follow-up  
			stcox i.active
			matrix active = r(table)'
			regtable active d, label2("Active medical aid plan") adjusted(0) drop(0b.active) append(d_uni) indent(0)
						
		* Sex 
			stcox ib2.sex 
			matrix sex= r(table)'
			regtable sex d, heading("Sex") label1("Male") label2("Female") adjusted(0) append(d_uni) 
		
		* Age 
			stcox ib10.age
			matrix age = r(table)'
			regtable age d, heading("Age, years") label1("11-19") label2("20-29") label3("30-39") label4("40-49") label5("50-59") label6("60-69") label7("70+") adjusted(0) append(d_uni)
			
		* Population group 
			stcox ib2.pop
			matrix pop = r(table)'
			regtable pop d, heading("Population group") label1("Indian") label2("Black") label3("Mixed") label4("White") label5("Missing") adjusted(0) append(d_uni)
		
		* Serious mental illness 
			stcox i.smi_tvc
			matrix smi_tvc = r(table)'
			regtable smi_tvc d, heading("Mental health diagnoses") label2("Serious mental disorders") adjusted(0) drop(0b.smi_tvc) append(d_uni)
					
		* Depression 
			stcox i.dep_tvc
			matrix dep_tvc = r(table)'
			regtable dep_tvc d, label2("Depression") adjusted(0) append(d_uni) drop(0b.dep_tvc)
			
		* Anxiety  
			stcox i.anx_tvc
			matrix anx_tvc = r(table)'
			regtable anx_tvc d, label2("Anxiety") adjusted(0) append(d_uni) drop(0b.anx_tvc)
			
		* Other mental disorders   
			stcox i.omd_tvc
			matrix omd_tvc = r(table)'
			regtable omd_tvc d, label2("Other mental disorders") adjusted(0) append(d_uni) drop(0b.omd_tvc)
			
		* Substance use  
			stcox i.alc_tvc
			matrix alc_tvc = r(table)'
			regtable alc_tvc d, heading("Substance use diagnoses") label2("Alcohol use disorder") adjusted(0) append(d_uni) drop(0b.alc_tvc)
			
		* Multiple drug use 
			stcox i.mdu_tvc
			matrix mdu_tvc = r(table)'
			regtable mdu_tvc d, label2("Multiple drug use") adjusted(0) append(d_uni) drop(0b.mdu_tvc)
			
		* Other substance use disorders (excl opioid use)
			stcox i.osu_tvc
			matrix osu_tvc = r(table)'
			regtable osu_tvc d, label2("Other disorders (excl. OUD)") adjusted(0) append(d_uni) drop(0b.osu_tvc)
	
	* Multivariable analysis 
	
		* OUD 
		
			* Model 1 
				stcox i.oud_tvc ib2.sex ib10.age ib2.pop i.year_cat4 ib0.active
				matrix m1 = r(table)'
				regtable m1 d, adjusted(1) save(d_m1) drop(0b.oud_tvc 0b.active)		
				
			* Model 2 
				stcox i.oud_tvc ib2.sex ib10.age ib2.pop i.year_cat4 ib0.active i.dep_tvc i.anx_tvc i.omd_tvc i.smi_tvc i.alc_tvc i.osu_tvc 
				estat phtest, detail
				stphplot, by(sex) // looks good 
				stphplot, by(pop) // looks okayish
				stphplot, by(age) // looks good 
				stphplot, by(active) // looks weird
				stphplot, by(dep_tvc) // looks 
				stphplot, by(anx_tvc) // looks 
				
				matrix m2 = r(table)'
				regtable m2 d, adjusted(1) save(d_m2) drop(0b.oud_tvc 0b.dep_tvc 0b.anx_tvc 0b.omd_tvc 0b.smi_tvc 0b.alc_tvc 0b.osu_tvc 0b.active)				
			
		* Proxies 
			
			* Model 1 
				stcox i.opi_tvc i.t40_tvc i.oa_tvc ib2.sex ib10.age ib2.pop i.year_cat4 ib0.active			
				matrix m3 = r(table)'
				regtable m3 d, adjusted(1) save(d_m3) drop(0b.opi_tvc 0b.t40_tvc 0b.oa_tvc 0b.active)		
				
			* Model 2 	
				stcox i.opi_tvc i.t40_tvc i.oa_tvc ib2.sex ib10.age ib2.pop i.year_cat4 ib0.active i.dep_tvc i.anx_tvc i.omd_tvc i.smi_tvc i.alc_tvc i.osu_tvc			
				*matrix m4 = r(table)'
				*regtable m4 d, adjusted(1) save(d_m4) drop(0b.opi_tvc 0b.t40_tvc 0b.oa_tvc 0b.dep_tvc 0b.anx_tvc 0b.omd_tvc 0b.smi_tvc 0b.alc_tvc 0b.osu_tvc 0b.active)	
							
			
	* Tabel 4: Unadjusted and adjusted hazard ratios for excess mortality associated opioid use problems
			
		* Merge univariable analysis & multivariable models 
			use using d_uni, clear
			use label est coef using d_uni, clear	
			gen id = _n
			order id coef
			rename est est_d_uni 
			forvalues j = 1/3 {
				merge 1:1 coef using d_m`j', keepusing(est) 
				assert inlist(_merge, 1, 3)
				drop _merge 
				rename est est_d_m`j'
			}
			sort id
			save d1, replace
			list label est*, separator(`=_N')

		* Create final table 
			set obs `=_N+1'
			replace id = _n * -1 if id ==.
			sort id
			replace est_d_uni = "HR (95% CI)" in 1
			forvalues j = 1/3 {
				replace est_d_m`j' = "aHR (95% CI)" in 1
			}
			*drop if id > 28
			drop id coef
			
		* Create word table 
			capture putdocx clear
			putdocx begin, font("Arial", 8) landscape
			putdocx paragraph, spacing(after, 0) 
			putdocx text ("Table 4. Hazard ratios for factors associated with mortality"), font("Arial", 9, black) bold 
			putdocx table tbl4 = data(*), border(all, nil) border(top, single) border(bottom, single) layout(autofitcontent) 
			putdocx table tbl4(., .), halign(right)  font("Arial", 8)
			putdocx table tbl4(., 1), halign(left)  
			putdocx table tbl4(1, .), border(bottom, single) bold
			putdocx pagebreak
			putdocx save "$tables/DisplayItems.docx", append

	