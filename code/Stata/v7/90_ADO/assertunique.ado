* Assertunique: asserts that varlist uniquely identifies records 
	capture program drop assertunique
	program define assertunique 
		version 16
		syntax [varlist] [if] [in]
		marksample touse, novarlist	
		preserve
		qui drop if !`touse'
		tempvar N
		bysort `varlist': gen N =_N 
		assert N ==1
	end