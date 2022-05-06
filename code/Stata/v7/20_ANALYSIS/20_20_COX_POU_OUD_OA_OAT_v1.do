
* FACTORS ASSOCIATED WITH OUD, F11, AND N07BC INCIDENCE 

* Loop over events 
	foreach j in oud oa opi {
		
	* Dataset 
		use "$clean/`j'", clear
		use "$clean/oud", clear
		*stphplot, by(pop)
		*stphplot, by(sex)
				
	* Drop individuals who initiated opioid use disorder from OA users 
			*gunique pat if oat1 ==1
			*if "`j'" == "n07bc" drop if oat1==1
		
	* Univariable analysis 
	
		* Sex 
			stcox year
			matrix A = r(table)'
			regtable A `j', label1("Year") adjusted(0) save(`j'_uni) indent(0)
	
		* Sex 
			stcox ib2.sex 
			matrix B = r(table)'
			regtable B `j', heading("Sex") label1("Male") label2("Female") adjusted(0) append(`j'_uni) 
		
		* Age 
			stcox ib40.age
			matrix C = r(table)'
			regtable C `j', heading("Age, years") label1("11-19") label2("20-29") label3("30-39") label4("40-49") label5("50-59") label6("60-69") label7("70+") adjusted(0) append(`j'_uni)
			testvar age, format(%5.4fc)
			
		* Population group 
			stcox ib2.pop
			matrix D = r(table)'
			regtable D `j', heading("Population group") label1("Indian") label2("Black") label3("Mixed") label4("White") label5("Missing") adjusted(0) append(`j'_uni)
			testvar pop, format(%5.4fc)
		
		* Serious mental illness 
			stcox i.smi_tvc
			matrix E = r(table)'
			regtable E `j', heading("Mental health diagnoses") label2("Serious mental disorders") adjusted(0) drop(0b.smi_tvc) append(`j'_uni)
					
		* Depression 
			stcox i.dep_tvc
			matrix F = r(table)'
			regtable F `j', label2("Depression") adjusted(0) append(`j'_uni) drop(0b.dep_tvc)
			
		* Anxiety  
			stcox i.anx_tvc
			matrix G = r(table)'
			regtable G `j', label2("Anxiety") adjusted(0) append(`j'_uni) drop(0b.anx_tvc)
			
		* Other mental disorders   
			stcox i.omd_tvc
			matrix H = r(table)'
			regtable H `j', label2("Other mental disorders") adjusted(0) append(`j'_uni) drop(0b.omd_tvc)
			
		* Substance use  
			stcox i.alc_tvc
			matrix I = r(table)'
			regtable I `j', heading("Substance use diagnoses") label2("Alcohol use disorder") adjusted(0) append(`j'_uni) drop(0b.alc_tvc)
			
		* Multiple drug use 
			stcox i.mdu_tvc
			matrix J = r(table)'
			regtable J `j', label2("Multiple drug use") adjusted(0) append(`j'_uni) drop(0b.mdu_tvc)
			
		* Other substance use disorders (excl opioid use)
			stcox i.osu_tvc
			matrix K = r(table)'
			regtable K `j', label2("Other disorders (excl. OUD)") adjusted(0) append(`j'_uni) drop(0b.osu_tvc)
	
	* Multivariable analysis 
		
		* Model without mdu (may include opioid use)
			stcox year ib2.sex ib40.age ib2.pop i.smi_tvc i.dep_tvc i.anx_tvc i.omd_tvc i.alc_tvc i.osu_tvc
			*estat phtest, detail
			matrix L = r(table)'
			regtable L `j', adjusted(1) save(`j'_multi)	drop(0b.smi_tvc 0b.dep_tvc 0b.anx_tvc 0b.omd_tvc 0b.alc_tvc 0b.osu_tvc)
			
	* Merge 
		use label est coef using `j'_uni, clear	
		gen id = _n
		order id coef
		rename est est_`j'_uni 
		merge 1:1 coef using `j'_multi, keepusing(est) nogen
		sort id
		rename est est_`j'_multi
		save `j', replace
		list label est_`j'_uni est_`j'_multi, separator(`=_N')
		
	}	
	
	* Merge final table 
		use oud, clear
		gen b1 = " "
		merge 1:1 coef using opi, assert(match) nogen
		gen b2 = ""
		merge 1:1 coef using oa, assert(match) nogen
		set obs `=_N+2'
		replace id = _n * -1 if id ==.
		sort id
		replace est_oud_uni = "Problematic opioid use" in 1
		replace est_opi_uni = "Opioid use disorder" in 1
		replace est_oa_uni = "Opioid agonist use" in 1	
		replace est_oud_uni = "HR (95% CI)" in 2
		replace est_opi_uni = "HR (95% CI)" in 2
		replace est_oa_uni = "HR (95% CI)" in 2	
		
		replace est_oud_multi = "aHR (95% CI)" in 2
		replace est_opi_multi = "aHR (95% CI)" in 2
		replace est_oa_multi = "aHR (95% CI)" in 2	
		
		drop id coef
		
	* Create word table 
		capture putdocx clear
		putdocx begin, font("Arial", 8) landscape
		putdocx paragraph, spacing(after, 0) 
		putdocx text ("Table 2. Hazard ratios for factors associated with opioid use disorder, F11 diagnoses and opioid agonist use among beneficiaries of a South African medical aid scheme"), font("Arial", 9, black) bold 
		putdocx table tbl3 = data(*), border(all, nil) border(top, single) border(bottom, single) layout(autofitcontent) 
		putdocx table tbl3(., .), halign(right)  font("Arial", 8)
		putdocx table tbl3(., 1), halign(left)  
		putdocx table tbl3(1, 2), colspan(2)  bold halign(center)  
		putdocx table tbl3(1, 4), colspan(2)  bold halign(center) 
		putdocx table tbl3(1, 6), colspan(2)  bold halign(center) 
		* Borders sub headdings
		foreach c in 2 3 5 6 8 9  {
			putdocx table tbl3(2, `c'), border(top, single) 
		}
		forvalues c= 1/9 {
			putdocx table tbl3(2, `c'), border(bottom, single) 
		}
		putdocx pagebreak
		putdocx save "$tables/DisplayItems.docx", append
		
	
	/* Year as categorical predictor  
		use "$clean/n07bc", clear
		recode year (2011/2012=1 "2011-2012") (2013/2014=2 "2013-2014") (2015/2016=3 "2015-2016") (2017/2018=4 "2017-2018")  (2019/2020=5 "2019-2020"), gen(year_cat) 
		assert year_cat !=.
		tab year year_cat, mi
		stcox i.year_cat 
		matrix M = r(table)'
		regtable M n07bc, adjusted(0) save(n07bc_year) heading("Year") label1("2011-2012") label2("2013-2014") label3("2015-2016") label4("2017-2018") label5("2019-2020")
		stcox i.year_cat ib2.sex ib40.age ib2.pop i.smi_tvc i.dep_tvc i.anx_tvc i.omd_tvc i.alc_tvc i.osu_tvc 
		matrix N = r(table)'
		regtable N n07bc, adjusted(1) append(n07bc_year) heading("Year") label1("2011-2012") label2("2013-2014") label3("2015-2016") label4("2017-2018") label5("2019-2020") ///
		drop(0b.smi_tvc 0b.dep_tvc 0b.anx_tvc 0b.omd_tvc 0b.alc_tvc 0b.osu_tvc) 
			
	* Year as categorical predictor  
		use "$clean/opi", clear
		recode year (2011/2012=1 "2011-2012") (2013/2014=2 "2013-2014") (2015/2016=3 "2015-2016") (2017/2018=4 "2017-2018")  (2019/2020=5 "2019-2020"), gen(year_cat) 
		assert year_cat !=.
		tab year year_cat, mi
		stcox i.year_cat 
		matrix O = r(table)'
		regtable O opi, adjusted(0) save(opi_year) heading("Year") label1("2011-2012") label2("2013-2014") label3("2015-2016") label4("2017-2018") label5("2019-2020")
		stcox i.year_cat ib2.sex ib40.age ib2.pop i.smi_tvc i.dep_tvc i.anx_tvc i.omd_tvc i.alc_tvc i.osu_tvc
		matrix P = r(table)'
		regtable P opi, adjusted(1) append(opi_year) heading("Year") label1("2011-2012") label2("2013-2014") label3("2015-2016") label4("2017-2018") label5("2019-2020") ///
		drop(0b.smi_tvc 0b.dep_tvc 0b.anx_tvc 0b.omd_tvc 0b.alc_tvc 0b.osu_tvc)
		
	* Year as categorical predictor  
		use "$clean/oat1", clear
		recode year (2011/2012=1 "2011-2012") (2013/2014=2 "2013-2014") (2015/2016=3 "2015-2016") (2017/2018=4 "2017-2018")  (2019/2020=5 "2019-2020"), gen(year_cat) 
		assert year_cat !=.
		tab year year_cat, mi
		stcox i.year_cat 
		matrix Q = r(table)'
		regtable Q oat1, adjusted(0) save(oat1_year) heading("Year") label1("2011-2012") label2("2013-2014") label3("2015-2016") label4("2017-2018") label5("2019-2020")
		stcox i.year_cat ib2.sex ib40.age ib2.pop i.smi_tvc i.dep_tvc i.anx_tvc i.omd_tvc i.alc_tvc i.osu_tvc 
		matrix R = r(table)'
		regtable R oat1, adjusted(1) append(oat1_year) heading("Year") label1("2011-2012") label2("2013-2014") label3("2015-2016") label4("2017-2018") label5("2019-2020") ///
		drop(0b.smi_tvc 0b.dep_tvc 0b.anx_tvc 0b.omd_tvc 0b.alc_tvc 0b.osu_tvc) 
		
	* Plot opi
		use opi_year, clear
		drop _*
		gen year_cat = substr(coef, 1, 1) if regexm(coef, "year_cat")
		destring year_cat, replace
		lab define year_cat 1 "2011-2012" 2 "2013-2014"  3 "2015-2016" 4 "2017-2018" 5 "2019-2020", replace
		lab val year_cat year_cat
		replace year_cat = year_cat - 0.1 if adjusted ==0
		replace year_cat = year_cat + 0.1 if adjusted ==1
		drop if year_cat ==.
		
		twoway  	scatter b year_cat if adjusted ==0, mcolor("$blue") ///
				|| 	rcap ll ul year_cat if adjusted ==0, color("$blue") ///
				||	scatter b year_cat if adjusted ==1, mcolor("$red") ///
				|| 	rcap ll ul year_cat if adjusted ==1, color("$red") ///
				, scheme(cleanplots) xlab(1 "2011-2012" 2 "2013-2014"  3 "2015-2016" 4 "2017-2018" 5 "2019-2020", labsize(*1.4)) xtitle("Year", size(large)) ysize(4) xsize(4) ///
				ylab(1(.5)3, labsize(*1.4)) ytitle("Hazard Ratios", size(large)) ///
				legend(label(1 "Unadjusted")) legend(label(3 "Adjusted")) legend(order(1 3)) legend(ring(0) position(11) bmargin(small)) text(3 0.15 "A", size(*2)) legend(size(large)) ///
				name(A, replace) nodraw
		
	* Plot n07bc
		use n07bc_year, clear
		drop _*
		gen year_cat = substr(coef, 1, 1) if regexm(coef, "year_cat")
		destring year_cat, replace
		lab define year_cat 1 "2011-2012" 2 "2013-2014"  3 "2015-2016" 4 "2017-2018" 5 "2019-2020", replace
		lab val year_cat year_cat
		replace year_cat = year_cat - 0.1 if adjusted ==0
		replace year_cat = year_cat + 0.1 if adjusted ==1
		drop if year_cat ==.
		
		twoway  	scatter b year_cat if adjusted ==0, mcolor("$blue") ///
				|| 	rcap ll ul year_cat if adjusted ==0, color("$blue") ///
				||	scatter b year_cat if adjusted ==1, mcolor("$red") ///
				|| 	rcap ll ul year_cat if adjusted ==1, color("$red") ///
				, scheme(cleanplots) xlab(1 "2011-2012" 2 "2013-2014"  3 "2015-2016" 4 "2017-2018" 5 "2019-2020", labsize(*1.4)) xtitle("Year", size(large)) ysize(4) xsize(4) ///
				ylab(.25(.25)1, labsize(*1.4)) ytitle("Hazard Ratios", size(large)) ///
				legend(label(1 "Unadjusted")) legend(label(3 "Adjusted")) legend(order(1 3)) legend(ring(0) position(1) bmargin(tiny)) text(1 0.15 "B", size(*2)) legend(off) ///
				name(B, replace) nodraw
			
	* Combine & export
		graph combine A B, ysize(4.5) xsize(2.25) scheme(cleanplots) col(1) imargin(small) graphregion(margin(r+3)) name(figureS1, replace)	
		graph export "$figures/Figure S1.pdf", as(pdf) name(figureS1) replace  
		graph export "$figures/Figure S1.tif", as(tif) name(figureS1) replace  width(400)
			
	* Figure 2: 
		capture putdocx clear
		putdocx begin, font("Arial", 8)
		putdocx paragraph, spacing(after, 8 pt)
		putdocx text ("Figure S1: Temporal trends in the incidence of new opioid use diagnoses and first use of opioid agonists"), font("Arial", 9, black) bold 
		putdocx paragraph, spacing(after, 0)
		putdocx text ("Figure shows unadjusted and adjusted hazard ratios for (A) temporal trends in new opioid use diagnoses, and (B) first use of opioid agonists among beneficiaries of a medical aid scheme. Error bars show 95% confidence intervals. "),font("Arial", 9, black)  
		putdocx text ("Error bars show 95% confidence intervals."), font("Arial", 9, black)  
		putdocx image "$figures/Figure S1.tif"
		putdocx pagebreak
		putdocx save "$tables/DisplayItems.docx", append 
		