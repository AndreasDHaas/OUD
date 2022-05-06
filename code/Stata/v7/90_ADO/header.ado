
capture program drop header
program define header
* version 1.2  AH 16 Aug 2021 
	syntax varlist(max=1) [if] [in], [SAVing(string)] [NOPERCENT] [NOFREQUency] [PERCENTSIGN] [FREQLAB(string)] [BRackets] [MIDpoint] [FREQFormat(string)] [PERCENTFormat(string) ///
	LABELFormat(string) CLEAN VARSUffix(string) PVALue ]
		marksample touse, novarlist
		preserve
		qui drop if !`touse'
			* encode string variables 
			tempname encoded
            capture confirm string variable `varlist'
            if !_rc {
				qui encode `varlist', gen(`encoded') 
				drop `varlist'
				rename `encoded' `varlist'
			}
			* value labels 
			tempname unlabeled
			local lbl: value label `varlist' 
			if "`lbl'" == "" { // 
					lab val `varlist' `unlabeled'     // assign empty label if unlabeled 
					local lbl: value label `varlist'
					assert "`lbl'" != "" 
			}
			local i = 1  
			qui levelsof `varlist', missing
			local c `r(levels)' // column levels
			foreach level in `c' {
				local lab`i++' : label `lbl' `level'  // load macros with value labels 
			}
			* save global with column levels $c for strpos matching 			
			capture macro drop c
			global c = "`c'" 	
			* write frequencies in dataset
			tab `varlist', mi
			qui tab `varlist' `varlist', col matcell(freq) matrow(L) mi
			local m `r(r)'
			local t = `r(r)' + 1
			matrix colnames L = `varlist'
			matrix freq = L, freq 
			clear
			qui svmat2 freq, names(col)
			forval y = 1/`m' {
				qui replace c`y' = c`y'[`y'] 
			}
			* total column 
			qui egen c`t' = rowtotal(c*)
			qui keep if _n ==1
			* percentages 
			forval y = 1/`t' {
				qui gen p`y' = c`y' / c`t' * 100 
				order p`y', after(c`y')
			} 
			* format frequencies
			forval y = 1/`t' {
				qui format `freqformat' c`y'	
				qui tostring c`y', replace usedisplay force
				qui replace c`y' = "`freqlab'"  +  c`y' 
			}
			* format percentages 
			if "`percentsign'" != "" local ps = "%"
			if "`brackets'" != "" local l = "["	
			if "`brackets'" != "" local r = "]"	
			if "`brackets'" == "" local l = "("	
			if "`brackets'" == "" local r = ")"				
			forval y = 1/`t' {
				qui format `percentformat' p`y'
				qui tostring p`y', replace usedisplay force
				qui replace p`y' = "`l'" + p`y' + "`ps'`r'" 
				qui replace p`y' = "" if p`y' =="`ps'`r'"
				qui rename p`y' e`y' 
				if "`nopercent'" != "" qui replace e`y' = ""
				if "`midpoint'" != "" qui replace e`y' = subinstr(e`y', ".", "·", .) 
			} 
			* add value labels in table header 
			qui set obs 2
			qui replace `varlist' = -1 if  `varlist' ==.
			sort `varlist'
			forval y = 1/`m' {
				qui replace c`y' = "`lab`y''" if `varlist' ==-1
			} 
			qui replace c`t' = "Total" if `varlist' ==-1					        // strpos 1234567		
			* rename variables: according to string position in $c : for example di "$c" >>> "0 1 . t" , 1st col = 1, 2nd = 3, 3rd = 5, 4th = 7, last column t is for totals
			* columns with percentages and summary statisics assign the same index and rename variables to ensure that the correct columns are appended, dimension of the matrix depend on missings, if selection etc. 
			local old=1
			local strMin = 1 
			local strMax = 1
			foreach n in $c t {   // levels of column + total column 
				local new = strpos("$c t", "`n'") // new variable name (stringposition of column)
				rename c`old' C`new'
				rename e`old' E`new'
				local old = `old' + 1 
				if `new'  < `strMin' local strMin = `new' 
				if `new'  > `strMax' local strMax = `new' 
			}
			* level 
			gen level = string(_n)
			* variable name 
			qui gen var = "`varlist'"
			* row labels
			qui gen label = "", before(`varlist')
			if "`labelformat'" == "" qui format %-40s label
			qui format `labelformat' label
			drop `varlist' 
			qui gen header = 1 
			* P-value 
			qui gen pvalue ="p-value" in 1, before(level)
			* rename variables with suffix 
			if "`varsuffix'" != "" {
				foreach j of varlist label header C* E* pvalue {
					rename `j' `j'`varsuffix'
				}
			}
			if "`pvalue'" == "" drop pvalue 
			if "`nofrequency'" !="" qui drop if _n ==2
			* list 
			if "`clean'" == "" list, sepby(header)
			if "`clean'" != "" list label C`strMin'-E`strMax' `pvalue', sepby(header) noheader
			* save 
			if "`saving'" != "" save "`saving'", replace 
		restore 
	end 

