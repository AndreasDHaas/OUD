* KM for mortality by OUD 
		
	* Dateset 
		use if linked ==1 using "$clean/Mortality",clear
	
	* List 
		listif patient start end d baseline_d end_d oud_sd oud if oud_sd !=. & d ==1, sepby(patient) id(patient) sort(patient start) seed(1) n(1) nolab 
		listif patient start end d baseline_d end_d oud_sd oud if pat==9190538, sepby(patient) id(patient) sort(patient start) seed(1) n(1) nolab 
		
	* Keep only last row and set start date to oud_sd if oud ==1 and else to baseline_d
		bysort patient (start): keep if _n ==_N
		save "$temp/lyl", replace
		replace start = oud_sd if oud_sd !=. 
		replace start = baseline_d if oud_sd ==.
		
	* Stset 
		stset end, failure(d==1) enter(start) origin(birth_d) id(patient) scale(365)
		stci, by(oud) 
		
	* List 
		listif patient start end d baseline_d end_d oud_sd oud _t0 _t _d death_d if pat==9190538, sepby(patient) id(patient) sort(patient start) seed(1) n(1) nolab 
		listif patient start end d baseline_d end_d oud_sd oud _t0 _t _d death_d if oud==1 & death_d ==., sepby(patient) id(patient) sort(patient start) seed(1) n(1) nolab 
		
	* Plot 
		sts graph, by(oud) ci scheme(cleanplots) title("") xtitle("Age", size(large)) ytitle("Survival probability", size(large)) ylab(, labsize(*1.4)) xlab(, labsize(*1.4)) ///
		legend(label(2 "No opioid use disorder")) legend(label(4 "Opioid use disorder")) legend(order(2 4)) legend(ring(0) position(1) bmargin(tiny))  xsize(4.25) ysize(4) name(figure1, replace) ///
		plot1opts(lcolor("$red") lwidth(*1)) ///
		ci1opts(color("$red")  fintensity(inten10) lcolor("$red")) 
			
	* Export
		graph export "$figures/Figure 1.pdf", as(pdf) name(figure1) replace  
		graph export "$figures/Figure 1.tif", as(tif) name(figure1) replace  width(400)
			
	* Write in word doc  
		capture putdocx clear
		putdocx begin, font("Arial", 8)
		putdocx paragraph, spacing(after, 8 pt)
		putdocx text ("Figure 1: Survival probability of persons with and without opioid use problems"), font("Arial", 9, black) bold 
		putdocx paragraph, spacing(after, 0)
		putdocx text ("Shaded areas show 95% confidence intervals."),font("Arial", 9, black)  
		putdocx image "$figures/Figure 1.tif"
		putdocx pagebreak
		putdocx save "$tables/DisplayItems.docx", append 
		