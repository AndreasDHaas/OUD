
* GENERATE DATASET FOR BASELINE TABLE 

	* Merge datasets 
		use "$temp/patients", clear
		merge 1:1 patient using "$temp/exposure", nogen assert(match)
		merge 1:1 patient using "$clean/tblBAS", keep(match) nogen
		merge 1:1 patient using "$clean/tblVITAL", nogen keep(match)
	
	* Generate variables 
			
		* Age at baseline 
			assert baseline_d !=. 
			*recode age_bl (0/10 = 0 "<11") (11/29 = 1 "11-29") (30/44 = 2 "30-44") (45/59 = 3 "45-59") (60/max = 4 "60+") (else=9 "Missing"), gen(age_bl_cat) test
			recode age_bl (0/10 = 0 "<11") (11/19 = 1 "11-19") (20/29 = 2 "20-29") (30/39 = 3 "30-39") (40/49 = 4 "40-49") (50/59 = 5 "50-59") (60/max = 6 "60+") (else=9 "Missing"), gen(age_bl_cat) test
			tab age_bl age_bl_cat, mi
			assert age_bl !=. 
			assert age_bl_cat !=.
			
		* Sex 
			tab sex
			assert sex !=.
			
		* Population group 
			gen pop = 1 if race =="A"
			replace pop = 2 if race =="B"
			replace pop = 3 if race =="C"
			replace pop = 4 if race =="W"
			replace pop = 9 if race =="U"
			replace pop = 9 if race =="N"
			replace pop = 9 if race ==""
			lab define pop 1 "Indian" 2 "Black" 3 "Mixed" 4 "White" 9 "Missing", replace 
			lab val pop pop 
			tab race pop, mi
			assert pop !=. 
		
		* OUD - recode for Table 1  
			gen strata = oud 
			replace strata = 2 if strata ==0
			lab define strata 1 "Persons with problematic opioid use" 2 "Persons without problematic opioid use", replace
			lab val strata strata
		
		* Linked to NPR 
			tab linked, mi
			labe define linked 0 "" 1 "Linked to NPR", replace
			lab val linked linked		
			
		* COD
			lab define cod1 1 "Natural causes" 2 "Unnatural causes" 3 "Under investigation" 4 "Unknown causes", replace
			lab define cod2 1 "Natural causes" 2 "Unnatural causes" 4 "Unknown cause", replace 
						
		* Death_y 
			tab death_y 
			tab npr_death_y, mi
			tab npr_death_y oud if linked ==1, col
			tab cod1 oud if linked ==1, col
			foreach var in bon npr {
				labe define `var'_death_y 0 "Alive" 1 "Died", replace
				lab val `var'_death_y `var'_death_y
			}
			labe define death_y 0 "Alive" 1 "Died", replace
			lab val death_y death_y
			
		* Age at death 
			gen age_death = floor((death_d-birth_d)/365)
			bysort oud: sum age_death

	* Save 
		save "$clean/analyseWide", replace
	
	
		
			