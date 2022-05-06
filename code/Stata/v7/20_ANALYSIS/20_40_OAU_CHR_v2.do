
* CHARACTERISTICS OF OPIOID USERS 
		
	* Generate Stata table 
		use if oa ==1 using "$clean/analyseWide", clear
		
	* Age at first OAU event 
		assert oa_sd !=. 
		gen age_oau = floor((oa_sd-birth_d)/365)
		recode age_oau (11/19 = 1 "11-19") (20/29 = 2 "20-29") (30/39 = 3 "30-39") (40/49 = 4 "40-49") (50/59 = 5 "50-59") (60/max = 6 "60+") (else=9 "Missing"), gen(age_oau_cat) test
		tab age_oau age_oau_cat, mi
		
	* Table 
		header sex, saving("$temp/chrOAU") percentformat(%3.1fc) freqlab("N=") clean freqf(%9.0fc) pvalue
		colprc age_oau_cat sex, append("$temp/chrOAU") percentformat(%3.1fc) freqf(%9.0fc) heading("Age at first OA use") clean chi
		sumstats age_oau sex, append("$temp/chrOAU") format(%3.0fc) median clean ttest 
		*colprc sex sex, append("$temp/chrOAU") percentformat(%3.1fc) freqf(%9.0fc) heading("Sex") clean chi
		*colprc pop sex, append("$temp/chrOAU") percentformat(%3.1fc) freqf(%9.0fc) heading("Population group") clean chi
		*colprc mhd sex, append("$temp/chrOAU") percentformat(%3.1fc) freqf(%9.0fc) noheading clean drop("0") indent(0) chi plevel(1)
		*colprc smi sex, append("$temp/chrOAU") percentformat(%3.1fc) freqf(%9.0fc) clean drop("0") noheading chi plevel(1)
		*colprc dep sex, append("$temp/chrOAU") percentformat(%3.1fc) freqf(%9.0fc) clean drop("0") noheading chi plevel(1)
		*colprc anx sex, append("$temp/chrOAU") percentformat(%3.1fc) freqf(%9.0fc) clean drop("0") noheading chi plevel(1)
		*colprc omd sex, append("$temp/chrOAU") percentformat(%3.1fc) freqf(%9.0fc) clean drop("0") noheading chi plevel(1)
		*colprc sud sex, append("$temp/chrOAU") percentformat(%3.1fc) freqf(%9.0fc) noheading clean drop("0") indent(0) chi plevel(1)
		*colprc alc sex, append("$temp/chrOAU") percentformat(%3.1fc) freqf(%9.0fc) clean drop("0") noheading chi plevel(1)
		*colprc osu sex, append("$temp/chrOAU") percentformat(%3.1fc) freqf(%9.0fc) clean drop("0") noheading chi plevel(1)
		*colprc mdu sex, append("$temp/chrOAU") percentformat(%3.1fc) freqf(%9.0fc) clean drop("0") noheading chi plevel(1)
		colprc opi sex, append("$temp/chrOAU") percentformat(%3.1fc) freqf(%9.0fc) noheading clean drop("0") chi plevel(1)
		forvalues j = 0/9 {
			*colprc f11`j' sex, append("$temp/chrOAU") percentformat(%3.1fc) freqf(%9.0fc) noheading clean  drop("0") indent(4) chi plevel(1)
		}		
		colprc t40 sex, append("$temp/chrOAU") percentformat(%3.1fc) freqf(%9.0fc) noheading clean  drop("0") chi plevel(1)		
		colprc methadone sex, append("$temp/chrOAU") percentformat(%3.1fc) freqf(%9.0fc) clean  drop("0") heading("Drug") indent(2) chi plevel(1)
		colprc buprenorphine sex, append("$temp/chrOAU") percentformat(%3.1fc) freqf(%9.0fc) noheading clean  drop("0") indent(2) chi plevel(1)
		
		use "$clean/analyseOAU", clear
		colprc N_cat sex if event ==1, append("$temp/chrOAU") percentformat(%3.1fc) freqf(%9.0fc) heading("Number of OA claims submitted") clean columntotal chi
		sumstats N sex if event==1, append("$temp/chrOAU") format(%3.0fc) median clean ttest
		sumstats N sex if event==1, append("$temp/chrOAU") format(%3.0fc) mean clean ttest
		bysort patient (med_sd): egen total_mg = total(mg) if drug ==1
		listif patient med_sd mg total, id(pat) sort(pat med_sd) sepby(pat)
		sumstats total_mg sex if event==1, append("$temp/chrOAU") format(%3.0fc) median clean ttest heading("Total amount of methadone received, mg")
		sumstats total_mg sex if event==1, append("$temp/chrOAU") format(%3.0fc) mean clean ttest 

				
	* Load table and prepare for export 
		tblout using "$temp/chrOAU", clear merge align format("%25s")	
		
	* Create word table 
		capture putdocx clear
		putdocx begin, font("Arial", 8)
		putdocx paragraph, spacing(after, 0)
		putdocx text ("Table S1: Characteristics of beneficiaries who received an opioid agonist"), font("Arial", 9, black) bold 
		putdocx table tbl1 = data(*), border(all, nil) border(top, single) border(bottom, single) layout(autofitcontent) 
		putdocx table tbl1(., .), halign(right)  font("Arial", 8)
		putdocx table tbl1(., 1), halign(left)  
		putdocx table tbl1(1, .), halign(center) bold 
		putdocx table tbl1(2, .), halign(center)  border(bottom, single)
		putdocx pagebreak
		putdocx save "$tables/DisplayItems.docx", append
		
		
		
	
	