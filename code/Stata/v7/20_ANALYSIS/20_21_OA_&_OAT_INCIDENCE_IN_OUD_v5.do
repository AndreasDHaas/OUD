
* FACTORS ASSOCIATED WITH OPIOID AGONIST USE AMONG PERSONS WITH OPIOID USE DIAGNOSIS

	* People with opioid disorder
		use if opi ==1 using "$clean/analyseLong", clear
		listif patient start end n07bc n07bc_sd oa oa_sd oat1 oat1_sd if oat1==1, sepby(pat) id(pat) sort(pat start)	
		listif patient start end n07bc n07bc_sd oa oa_sd oat1 oat1_sd if oa==1, sepby(pat) id(pat) sort(pat start)
		listif patient start end n07bc n07bc_sd opi opi_sd if n07bc_sd < opi_sd , sepby(pat) id(pat) sort(pat start)
		
	* Ns 
		gunique pat if opi ==1 // 831 
		gunique pat if n07bc ==1 // 831
		gunique pat if death_d !=. & death_d <= end_d & death_d < n07bc_sd  // 28 death before study end and still under follow-up (not earlier n07bc_sd)
		gunique patient if n07bc_sd < opi_sd // OA use before OA diagnoses 
		
	* Cumulative incidence for no event 

		* Drop follow-up time before F11 diagnosis
			gunique pat if opi_sd ==end_d // two patients have opi_sd & end_d -> not at risk 
			listif patient start end opi_sd oa_sd oat1_sd death_d end_d opi_tvc if opi_sd ==end_d , sepby(pat) id(pat) sort(pat start)	
			replace opi_tvc = 1 if opi_sd ==end & opi_sd ==end_d
			replace start = opi_sd if opi_sd ==end & opi_sd ==end_d
			listif patient start end opi_sd oa_sd oat1_sd death_d end_d opi_tvc if opi_sd ==end_d , sepby(pat) id(pat) sort(pat start)
			listif patient start end opi_sd oa_sd oat1_sd death_d end_d opi_tvc, sepby(pat) id(pat) sort(pat start)	
			drop if opi_tvc ==0
			
		* Start == opi_sd in _n ==1
			bysort patient (start): assert start == opi_sd if _n ==1
			
		* Censoring date 
			listif patient start end opi_sd oa_sd oat1_sd death_d end_d if oat1_sd !=., sepby(pat) id(pat) sort(pat start)	n(5)
			
		* Opioid agonist use (n07bc): censor at n07bc n07bc_sd. Death_d is competing event
			
			* Exit at n07bc_sd 
				gen exit = n07bc_sd if n07bc_sd !=. 
				*assert opi_sd !=.
				*replace exit = opi_sd + 1 if n07bc_sd <= opi_sd 
				format exit %tdD_m_CY
				
			* Outcome 
				gen outcome = 1 if n07bc_sd !=. 
				lab define outcome 1 "OA use" 3 "Dead" 0 "Censored", replace
				lab val outcome outcome
				
			* Count
				gunique pat if outcome ==1
				
			* List 
				listif patient start end opi_sd oa_sd oat1_sd death_d end_d exit outcome if n07bc_sd !=., sepby(pat) id(pat) sort(pat start) n(20)
				listif patient start end opi_sd oa_sd oat1_sd death_d end_d exit outcome if n07bc_sd !=. & death_d !=., sepby(pat) id(pat) sort(pat start) n(20)

			* Exit at death if patients died and still under follow-up 
			
				* Death can't be before event 
					assert death_d > n07bc_sd if n07bc_sd !=. & death_d !=.
					
				* Death before end of study 
					replace exit = death_d if death_d !=. & death_d <= end_d & death_d < n07bc_sd 
					replace outcome = 3 if death_d !=. & death_d <= end_d & death_d < n07bc_sd 
					gunique pat if outcome ==3
					
			* Censored	
				replace outcome = 0 if exit ==.
				replace exit = end_d if exit ==. 
							
			* List 
				listif patient start end opi_sd oa_sd oat1_sd death_d end_d exit outcome, sepby(pat) id(pat) sort(pat start) n(20)			
				
			* Checks 	
			
				* Censored 
					assert outcome ==0 if n07bc_sd==. & death_d ==.
					assert exit == end_d if n07bc_sd==. & death_d ==. 
					
				* Death 
					assert outcome ==3 if death_d !=. & death_d < n07bc_sd & death_d <= end_d
					assert exit == death_d if death_d !=. & death_d < n07bc_sd & death_d <= end_d
									
				* OA use  
					assert outcome ==1 if n07bc_sd !=. 
					assert exit == n07bc_sd if n07bc_sd !=. 
					*listif patient start end opi_sd oa_sd oat1_sd death_d end_d exit outcome if outcome != 1 & oa_sd !=. & oa_sd != oat1_sd, sepby(pat) id(pat) sort(pat start) n(20)
												
				* Event before start: set to start + 1 day
					assert exit !=.
					assert opi_sd !=.
					listif patient start end opi_sd oa_sd oat1_sd death_d end_d exit outcome if exit < opi_sd , sepby(pat) id(pat) sort(pat start) n(100)
					gunique pat if  exit <= opi_sd
					replace exit = opi_sd + 1 if  exit <= opi_sd
					
				* Drop rows after censoring 
					listif patient start end opi_sd oa_sd oat1_sd death_d end_d exit outcome if start>=exit, sepby(pat) id(pat) sort(pat start) n(20)
					gen temp = 1 if start >= exit
					listif patient start end opi_sd oa_sd oat1_sd death_d end_d exit outcome temp if temp==1, sepby(pat) id(pat) sort(pat start) n(20)
					drop if temp ==1
					drop temp
					
				* Set end_d to exit date in last row 
					bysort patient (start): gen n = _n
					bysort patient (start): gen N = _N				
					listif patient start end opi_sd oa_sd oat1_sd death_d end_d exit outcome if exit !=end & n ==N , sepby(pat) id(pat) sort(pat start) n(100)				
					listif patient start end opi_sd oa_sd oat1_sd death_d end_d exit outcome if pat ==1557119 , sepby(pat) id(pat) sort(pat start) n(20)
					replace end = exit if exit !=end & n ==N 
					bysort patient (start): assert exit == end if _n ==_N
					
				* Out 
					gen out = 0
					bysort patient (start): replace out = outcome if _n ==_N	
					lab define out 1 "OA" 3 "Dead" 0 "0", replace
					lab val out out
					listif patient start end opi_sd oa_sd oat1_sd death_d end_d exit outcome out, sepby(pat) id(pat) sort(pat start) n(100)
					tab out
					
			* No event: probablity to be alive, under follow-up and not receiving OA
			
				* Stset without id 
					stset end, failure(out==1 3) enter(start) origin(opi_sd) scale(365.25)
					listif patient start end opi_sd oa_sd oat1_sd death_d end_d exit outcome out _t0 _t _d if oa_sd!=. , sepby(pat) id(pat) sort(pat start) n(5)
						
				* Save _t0 variables 
					rename _t0 t0 
					
				* Stest with id 
					stset end, failure(out==1) enter(start) origin(opi_sd) id(patient) scale(365.25)
				
				* Fix _t0 
					replace _t0 =t0 
					drop t0
					
				* List 
					listif patient start end opi_sd oa_sd oat1_sd death_d end_d exit outcome out _t0 _t _d if oa_sd <opi_sd , sepby(pat) id(pat) sort(pat start) n(100)
					listif patient start end opi_sd oa_sd oat1_sd death_d end_d exit outcome out _t0 _t _d , sepby(pat) id(pat) sort(pat start) n(100)
					
				* Sts graph
					*sts graph, tmax(5) risktable ci by(sex) 
					sts list, by(sex) at(.00273973 1 2 3 4 5) saving("$temp/est_0_sex", replace)   
					sts list, at(.00273973 1 2 3 4 5) saving("$temp/est_0", replace)
					
			* OA use: death is competing events  
			
				* Stset without id 
					stset end, failure(out==1) enter(start) origin(opi_sd) scale(365.25)
					listif patient start end opi_sd oa_sd oat1_sd death_d end_d exit outcome out _t0 _t _d if oa_sd!=. , sepby(pat) id(pat) sort(pat start) n(5)
						
				* Save _t0 variables 
					rename _t0 t0 
					
				* Stest with id 
					stset end, failure(out==1) enter(start) origin(opi_sd) id(patient) scale(365.25)
				
				* Fix _t0 
					replace _t0 =t0 
					
				* List 
					listif patient start end opi_sd oa_sd oat1_sd death_d end_d exit outcome out _t0 _t _d if oa_sd <opi_sd , sepby(pat) id(pat) sort(pat start) n(100)
					listif patient start end opi_sd oa_sd oat1_sd death_d end_d exit outcome out _t0 _t _d , sepby(pat) id(pat) sort(pat start) n(100)
					
				* Loop over sex
					foreach j in 1 2 9 {
					
					* Select 
						preserve 
						if inlist(`j', 1, 2) keep if sex == `j'
				
					* Sts graph
						stcompet ci=ci, compet1(3)  
						stcompet hi=hi, compet1(3) 
						stcompet lo=lo, compet1(3)  

					* Keep OA	
						keep if outcome ==1
						
					* List 
						sort _t
						list outcome _t ci lo hi 
						
					* Clean 
						keep outcome _t ci lo hi 
						keep if ci !=.
						list _t ci lo hi
						bysort _t: keep if _n ==1
						
					* Add dummies for timepoints 
						set obs `=_N+5'
						replace outcome = 1 if outcome ==.
						replace _t = _N-_n+1 if _t ==.
						
					* Carry-forward last ci, lo, hi if missing 
						sort _t
						list _t ci lo hi
						bysort outcome (_t): replace ci = ci[_n-1] if ci ==. & _n >1 
						bysort outcome (_t): replace hi = hi[_n-1] if hi ==. & _n >1 
						bysort outcome (_t): replace lo = lo[_n-1] if lo ==. & _n >1 
						sort _t
						keep if _n ==1 | inlist(_t, 0, 1, 2, 3, 4, 5)
						*list outcome _t ci lo hi if inlist(_t, 0, 1, 2, 3, 4, 5)
						
					* Rename 
						capture drop est
						gen est_1_`j' = string(ci*100, "%3.1f") + " (" + string(lo*100, "%3.1f") + "-" + string(hi*100, "%3.1f") + ")"
						keep _t est_*
						list
						
					* Save 
						save "$temp/est_1_`j'", replace
						restore 
						
					} 
					
	
	* Create final tables
		
		* Clean KM 
			use "$temp/est_0_sex", clear
			list
			gen est_0_1 = string(survivor*100, "%3.1f") + " (" + string(lb*100, "%3.1f") + "-" + string(ub*100, "%3.1f") + ")" if sex ==1
			gen est_0_2 = string(survivor*100, "%3.1f") + " (" + string(lb*100, "%3.1f") + "-" + string(ub*100, "%3.1f") + ")" if sex ==2
			keep time est_0*
			preserve 
			keep time est_0_1
			rename time _t
			keep if est_0_1 !=""
			sort _t
			gen int id =_n
			save "$temp/est_0_1", replace
			restore
			keep time est_0_2
			rename time _t
			keep if est_0_2 !=""
			sort _t
			gen int id =_n
			save "$temp/est_0_2", replace
			
			use "$temp/est_0", clear
			list
			gen est_0_9 = string(survivor*100, "%3.1f") + " (" + string(lb*100, "%3.1f") + "-" + string(ub*100, "%3.1f") + ")" 
			keep time est_0_9
			rename time _t
			keep if est_0_9 !=""
			sort _t
			gen int id =_n
			save "$temp/est_0_9", replace
			
		* Merge 
			use "$temp/est_1_1", clear
			merge 1:1 _t using "$temp/est_1_2", assert(match) nogen
			merge 1:1 _t using "$temp/est_1_9", assert(match) nogen
			gen b1 = ""
			sort _t
			gen int id =_n
			merge 1:1 id using "$temp/est_0_1", assert(match) nogen
			merge 1:1 id using "$temp/est_0_2", assert(match) nogen
			merge 1:1 id using "$temp/est_0_9", assert(match) nogen			
			set obs `=_N+2'
			replace id = _n*-1 if id ==. 
			sort id
			order id
			replace _t = round(_t)
			list
			
		replace est_1_1 = "Opioid agonist use Cumulative incidence, % (95% CI)" in 1
		replace est_0_1 = "Alive, under follow up and no opioid agonist use Survival probability, % (95% CI)" in 1	
		foreach var in est_1_1 est_0_1 {
			replace `var' = "Men" in 2
		}
		foreach var in est_1_2 est_0_2 {
			replace `var' = "Women" in 2
		}
		foreach var in est_1_9 est_0_9 {
			replace `var' = "Total" in 2
		}
		list
		sort id 
		drop id
		tostring _t, replace
		replace _t = "" if _t =="."
		replace _t = "Years after diagnosis" in 2
		
	* Create word table 
		capture putdocx clear
		putdocx begin, font("Arial", 8) landscape
		putdocx paragraph, spacing(after, 0) 
		putdocx text ("Table 3. Cumulative incidence of opioid agonist use after opioid use disorder diagnosis among beneficiaries of a South African medical aid scheme"), font("Arial", 9, black) bold 
		putdocx table tbl3 = data(*), border(all, nil) border(top, single) border(bottom, single) layout(autofitcontent) 
		putdocx table tbl3(., .), halign(right)  font("Arial", 8)
		putdocx table tbl3(., 1), halign(left)  
		putdocx table tbl3(1, 2), colspan(3)  bold halign(center)  
		putdocx table tbl3(1, 4), colspan(3)  bold halign(center) 
		* Borders sub headdings
		foreach c in 2 3 4 6 7 8 9  {
			putdocx table tbl3(2, `c'), border(top, single) 
		}
		foreach c in 1 2 3 4 6 7 8  {
			putdocx table tbl3(2, `c'), border(bottom, single) halign(center) 
		}
		putdocx pagebreak
		putdocx save "$tables/DisplayItems.docx", append
		
	