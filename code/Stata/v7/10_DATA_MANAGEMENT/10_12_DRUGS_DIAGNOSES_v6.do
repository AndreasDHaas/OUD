			
	* DEFINE EXPOSURES
				
		* Eligible patients
			use "$temp/patients", clear
				
		* Drugs used in opioid use disorder 
			
			* see helpfile for fdrug 
				*help fdrug
				
			* generate dummy varialbe med_id. Variables used in the if statement have to exist in the loaded dataset to pass syntax checking.
				gen med_id ="" 
				gen nappi_code=""
				
				*fdrug N02AE01 using "$clean/tblMED_ATC_N" if regexm(med_id, "N02AE01"), minage(11) label("Buprenorphine") mindate(baseline_d) maxdate(end_d)
								
			* drugs used in opioid dependence  
				fdrug n07bc using "$clean/tblMED_ATC_N" if regexm(med_id, "N07BC"), minage(11) label("Received opioid agonist") mindate(baseline_d) maxdate(end_d)
				fdrug methadone using "$clean/tblMED_ATC_N" if med_id=="N07BC02", minage(11) label("Methadone")	mindate(baseline_d) maxdate(end_d)
				fdrug equity using "$clean/tblMED_ATC_N" if nappi_code=="714417", minage(11) label("Equity methadone")	mindate(baseline_d) maxdate(end_d)
				fdrug physeptone using "$clean/tblMED_ATC_N" if nappi_code=="755303", minage(11) label("Physeptone")	mindate(baseline_d) maxdate(end_d)				
				fdrug buprenorphine using "$clean/tblMED_ATC_N" if med_id=="N07BC51", minage(11) label("Buprenorphine") mindate(baseline_d) maxdate(end_d)			
				
		* F11 & T40 diagnoses 
			
			* see helpfile  
				*help fdiag
				
			* generate dummy varialbe icd10_code. Variables used in the if statement have to exist in the loaded dataset to pass syntax checking. 
				gen icd10_code ="" 
				
			* F11 diagnoses
				fdiag f11 using "$clean/tblICD10_F" if regexm(icd10_code, "F11"), minage(11) mindate(baseline_d) maxdate(end_d)	label("Opioid use disorder diagnosis") 
				forvalues j = 0/9 {
					fdiag f11`j' using "$clean/tblICD10_F" if regexm(icd10_code, "F11.`j'"), minage(11) mindate(baseline_d) maxdate(end_d) 	label("F11.`j'") 
				}
				
			* T40 diagnoses
				fdiag t40 using "$clean/tblICD10_ST" if regexm(icd10_code, "T40.[0-1]") | regexm(icd10_code, "T40.3"), minage(11) label("Opioid poisoning diagnosis") mindate(baseline_d) maxdate(end_d)
				foreach j in 0 1 3 {
					fdiag t40`j' using "$clean/tblICD10_ST" if regexm(icd10_code, "T40.`j'"), minage(11) mindate(baseline_d) maxdate(end_d) label("T40.`j'")
				}
				
		* Opioid use disorders (OUD): F11 diagnosis, T40 diagnosis or equity drugs 
			egen oud = rowmax(f11 t40 equity buprenorphine)
			egen oud_sd = rowmin(equity_sd f11_sd t40_sd buprenorphine_sd)
			format oud_sd %tdD_m_Y
			list patient oud oud_sd f11_sd f11 t40 t40_sd equity_sd equity if pat ==6141
			
		* Substance use diagnoses
			fdiag sud using "$clean/tblICD10_F" if regexm(icd10_code, "F1"), minage(11) mindate(baseline_d) maxdate(end_d) label("Substance use diagnosis") 
			fdiag alc using "$clean/tblICD10_F" if regexm(icd10_code, "F10"), minage(11) mindate(baseline_d) maxdate(end_d) label("Alcohol use disorder") 
			fdiag opi using "$clean/tblICD10_F" if regexm(icd10_code, "F11"), minage(11) mindate(baseline_d) maxdate(end_d) label("Opioid use disorder") 
			fdiag osu using "$clean/tblICD10_F" if regexm(icd10_code, "F1[2-8]"), minage(11) mindate(baseline_d) maxdate(end_d) label("Other substance use disorders") 
			fdiag mdu using "$clean/tblICD10_F" if regexm(icd10_code, "F19"), minage(11) mindate(baseline_d) maxdate(end_d) label("Multiple drug use") 
			
		* Mental health diagnoses
			fdiag smi using "$clean/tblICD10_F" if regexm(icd10_code, "F2") |  regexm(icd10_code, "F31"), minage(11) mindate(baseline_d) maxdate(end_d) label("Serious mental disorder") 
			fdiag dep using "$clean/tblICD10_F" if regexm(icd10_code, "F32") |  regexm(icd10_code, "F33") |  regexm(icd10_code, "F34.1")  |  regexm(icd10_code, "F54"), ///
			minage(11) mindate(baseline_d) maxdate(end_d) label("Depression") 		
			fdiag anx using "$clean/tblICD10_F" if regexm(icd10_code, "F4"), minage(11) mindate(baseline_d) maxdate(end_d) label("Anxiety disorder") 			
			fdiag omd using "$clean/tblICD10_F" if regexm(icd10_code, "F0") | regexm(icd10_code, "F[5-9]"), minage(11) mindate(baseline_d) maxdate(end_d) label("Other mental disorder") 
			fdiag mhd using "$clean/tblICD10_F" if regexm(icd10_code, "F0") | regexm(icd10_code, "F[2-9]"), minage(11) mindate(baseline_d) maxdate(end_d) label("Mental health diagnosis")	
				
		* Infectious diseases
			fdiag hiv using "$clean/tblICD10_AB" if regexm(icd10_code, "B2[0-4]"), mindate(baseline_d) maxdate(end_d) label("HIV") 
			fdiag hcv using "$clean/tblICD10_AB" if regexm(icd10_code, "B17.1") | regexm(icd10_code, "B18.2"), mindate(baseline_d) maxdate(end_d) label("Hepatitis C virus") 
			fdiag tb using "$clean/tblICD10_AB" if regexm(icd10_code, "A1[5-9]"), mindate(baseline_d) maxdate(end_d) label("Tuberculosis") 
			fdiag i330 using "$clean/tblICD10_I" if regexm(icd10_code, "I33.0"), mindate(baseline_d) maxdate(end_d) label("Infective endocarditis") 
			
		* Cancer
			*fdiag cancer using "$clean/tblICD10_C00-D49" if icd10_code !="" , mindate(baseline_d) maxdate(end_d) label("Cancer") 
							
		* Compress & checks 
			compress
			gunique patient
			assert `r(minJ)' ==1
			
		* Clean 
			*drop baseline_d 
			
		* Methadone or buprenorphine 
			egen oa_sd = rowmin(equity_sd buprenorphine_sd)
			egen oa = rowmax(equity buprenorphine)
			format oa_sd %tdD_m_Y
			
		* Correct dates if physeptone was used before methadone or buprenorphine
			listif patient buprenorphine buprenorphine_sd equity_sd equity physeptone_sd physeptone oa_sd oa oud oud_sd n07bc_sd n07bc if physeptone_sd < oa_sd & oa_sd !=., sepby(pat) id(pat) sort(pat)
			replace oa_sd = physeptone_sd if physeptone_sd < oa_sd & oa_sd !=.
			replace oud_sd = physeptone_sd if physeptone_sd < oud_sd & oud_sd !=.
			
		* Save 
			save "$temp/exposure", replace
						