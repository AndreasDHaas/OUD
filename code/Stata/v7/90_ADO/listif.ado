* Listif - List values of variables of all records of a random sample of patients if expression is true. 
	* syntax [varlist] [if] [in], ID(varname) SORT(varlist) [ SEPBY(varlist) N(integer) SEED(integer) ] 
	* if no varlist is specified, the values of all the variables are displayed
	* Options: 
		* id(varname); required patient identifier 
		* sort(varlist); required; determines sorting of listif
		* sepby(varlist); optional; specifies that a separator line be drawn whenever any of the variables in sepby(varlist2) change their values
		* n(integer); optional; default is 10 
		* seed(integer); optional, seed can not be set to -88888 (used as default)
	* Examples: 
		* listif patient treatment_date nappi_code icd10_code atccode if nappi_code=="800325", id(patient) sort(patient treatment_date nappi_code) sepby(patient treatment_date) n(3) seed(100)
		capture program drop listif
		program define listif
		* version 1.0  AH 6 Jan 2021 
			version 16
			syntax [varlist] [if] [in], ID(varname) SORT(varlist) [ SEPBY(varlist) N(integer 10) SEED(integer -88888) NOLABel ]
			marksample touse, novarlist
			if `seed' != -88888 set seed `seed'
			preserve
			qui drop if !`touse'
			tempvar random
			qui gen `random' = runiform()
			qui bysort `id' (`random'): keep if _n ==1
			qui sample `n', count
			qui levelsof `id', clean
			restore
			sort `sort'
			capture confirm numeric variable `id' 
			if !_rc {
				foreach j in `r(levels)' {
						list `varlist' if `id' ==`j', sepby(`sepby') `nolabel'
				}
			}
			else {
				foreach j in `r(levels)' {
						list `varlist' if `id' =="`j'", sepby(`sepby') `nolabel' 
				}			
			}
		end