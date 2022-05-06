
* BASELINE CHARACTERISTICS:  
		
	* Wide table 
		use "$clean/analyseWide", clear
		
	* Age at first OUD event 
		assert oud_sd !=. if oud ==1
		gen age_oud = floor((oud_sd-birth_d)/365)
		recode age_oud (11/19 = 1 "11-19") (20/29 = 2 "20-29") (30/39 = 3 "30-39") (40/49 = 4 "40-49") (50/59 = 5 "50-59") (60/max = 6 "60+") (else=9 "Missing"), gen(age_oud_cat) test
		
	* Stata
		lab define strata 1 "Persons with opioid use disorder" 2 "Persons without opioid use disorder", replace
		
	* SU disorders excluing F11
		egen SUnotF11 = rowmax(alc osu mdu)
		lab define SUnotF11 1 "Substance use disorder diagnosis (excl. F11)", replace
		lab val SUnotF11 SUnotF11
		
	* Infectious diseases 
		egen id = rowmax(hiv tb hcv)
		lab define id 1 "Infectious diseases", replace
		lab val id id
		
	* Opioid agonist use 
		lab define oa 1 "Opioid agonist use", replace
		lab val oa oa 
		
	* Equity 
		lab define equity 1 "Methadone", replace
		lab val equity equity
		
	* buprenorphine-naloxone 
		gen bpn = 1
		lab define bpn 1 "Buprenorphine-Naloxone", replace 
		lab val bpn bpn 
	
	* F11 
		lab define f11 1 "Opioid related disorder"
		
	* Table 
		header strata, saving("$temp/chrBAS") percentformat(%3.1fc) freqlab("N=") clean freqf(%9.0fc) 
		colprc sex strata, append("$temp/chrBAS") percentformat(%3.1fc) freqf(%9.0fc) heading("Sex") clean 
		colprc age_bl_cat strata, append("$temp/chrBAS") percentformat(%3.1fc) freqf(%9.0fc) heading("Age at baseline, years") clean  
		sumstats age_bl strata, append("$temp/chrBAS") format(%3.0fc) median clean 
		colprc pop strata, append("$temp/chrBAS") percentformat(%3.1fc) freqf(%9.0fc) heading("Population group") clean  
		colprc mhd strata, append("$temp/chrBAS") percentformat(%3.1fc) freqf(%9.0fc) noheading clean drop("0") indent(0) 
		colprc smi strata, append("$temp/chrBAS") percentformat(%3.1fc) freqf(%9.0fc) clean drop("0") noheading
		colprc dep strata, append("$temp/chrBAS") percentformat(%3.1fc) freqf(%9.0fc) clean drop("0") noheading 
		colprc anx strata, append("$temp/chrBAS") percentformat(%3.1fc) freqf(%9.0fc) clean drop("0") noheading 
		colprc omd strata, append("$temp/chrBAS") percentformat(%3.1fc) freqf(%9.0fc) clean drop("0") noheading 
		colprc SUnotF11 strata, append("$temp/chrBAS") percentformat(%3.1fc) freqf(%9.0fc) noheading clean drop("0") indent(0)
		colprc alc strata, append("$temp/chrBAS") percentformat(%3.1fc) freqf(%9.0fc) clean drop("0") noheading 
		colprc mdu strata, append("$temp/chrBAS") percentformat(%3.1fc) freqf(%9.0fc) clean drop("0") noheading 
		colprc osu strata, append("$temp/chrBAS") percentformat(%3.1fc) freqf(%9.0fc) clean drop("0") noheading 
		colprc id strata, append("$temp/chrBAS") percentformat(%3.1fc) freqf(%9.0fc) clean drop("0") noheading indent(0) 		
		colprc hiv strata, append("$temp/chrBAS") percentformat(%3.1fc) freqf(%9.0fc) clean drop("0") noheading
		colprc hcv strata, append("$temp/chrBAS") percentformat(%3.1fc) freqf(%9.0fc) clean drop("0") noheading 
		colprc tb strata, append("$temp/chrBAS") percentformat(%3.1fc) freqf(%9.0fc) clean drop("0") noheading 
		colprc i330 strata, append("$temp/chrBAS") percentformat(%3.1fc) freqf(%9.0fc) clean drop("0") indent(0) noheading
		colprc f11 strata, append("$temp/chrBAS") percentformat(%3.1fc) freqf(%9.0fc) clean  drop("0") indent(2) heading("Proxies for opioid use disorder") 
		colprc t40 strata, append("$temp/chrBAS") percentformat(%3.1fc) freqf(%9.0fc) noheading clean  drop("0") indent(2) 
		colprc oa strata, append("$temp/chrBAS") percentformat(%3.1fc) freqf(%9.0fc) clean indent(2) nomissing drop("0") noheading
		colprc equity strata, append("$temp/chrBAS") percentformat(%3.1fc) freqf(%9.0fc) clean noheading indent(4) nomissing drop("0")	
		colprc buprenorphine strata, append("$temp/chrBAS") percentformat(%3.1fc) freqf(%9.0fc) clean indent(4) nomissing drop("0")	noheading	
		colprc bpn strata, append("$temp/chrBAS") percentformat(%3.1fc) freqf(%9.0fc) clean indent(4) nomissing noheading	// set to zero 		
		colprc age_oud_cat strata, append("$temp/chrBAS") percentformat(%3.1fc) freqf(%9.0fc) heading("Age at first opioid use disorder proxy, years") clean drop("9")
		sumstats age_oud strata, append("$temp/chrBAS") format(%3.0fc) median nomissing clean

	* Load and prepare table for export 
		tblout using "$temp/chrBAS", clear merge align format("%25s")
		replace c1 = "0     (0.0)" if label =="    Buprenorphine-Naloxone"
		replace c2 = "0     (0.0)" if label =="    Buprenorphine-Naloxone"
		replace c3 = "0     (0.0)" if label =="    Buprenorphine-Naloxone"
							   
	* Create word table 
		capture putdocx clear
		putdocx begin, font("Arial", 8)
		putdocx paragraph, spacing(after, 0)
		putdocx text ("Table 1: Characteristics of beneficiaries of a South African medical aid scheme by problematic opioid use"), font("Arial", 9, black) bold 
		putdocx table tbl1 = data(*), border(all, nil) border(top, single) border(bottom, single) layout(autofitcontent) 
		putdocx table tbl1(., .), halign(right)  font("Arial", 8)
		putdocx table tbl1(., 1), halign(left)  
		putdocx table tbl1(1, .), halign(center) bold 
		putdocx table tbl1(2, .), halign(center)  border(bottom, single)
		putdocx pagebreak
		putdocx save "$tables/DisplayItems.docx", replace
		