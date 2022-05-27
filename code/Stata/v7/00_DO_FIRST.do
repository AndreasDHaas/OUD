
////////////////////////////////////////////////////////////////////////////////
***DO FIRST 
////////////////////////////////////////////////////////////////////////////////

*** FILE PATHS 

* Define project
 	
	*Versions
		global vDD "v2"   
		global vDO "v7" 
		
	*Project names 
		global project "IeDEA" 
		global concept "OUD" 
		
	* Folders
		global science "C:/Users/haas/Dropbox/Science"
		global data "C:/Data"
		
	* Ado
		sysdir set PERSONAL "C:/Repositories/OUD/code/Stata/v7/90_ADO"
		
* Generate project folders 
		
	*Project-level   
		capture mkdir "$science/$project"
		capture mkdir "$data/$project"
		
	*Concept-level   
		capture mkdir "C:/Users/haas/Dropbox/Do/$project/$concept" 		
		capture mkdir "$science/$project/$concept"
		capture mkdir "$data/$project/$concept"
		
	*Version-level   
		capture mkdir "C:/Users/haas/Dropbox/Do/$project/$concept/$vDO" 		
		capture mkdir "$data/$project/$concept/$vDD"
		
	*Science sub-folders
		foreach folder in concepts docs figures tables papers abstracts other  {  
			capture mkdir "$science/$project/$concept/`folder'"
		}
		
	*Data sub-folders
		foreach folder in clean source temp wd {  
			capture mkdir "$data/$project/$concept/$vDD/`folder'"
		}
	
* Define macros for file paths 

	*Science sub-folders
		foreach folder in figures tables  {  
			global `folder' "$science/$project/$concept/`folder'"
		}

	* Data sub-folders 
		foreach folder in clean source temp  {  
			global `folder' "$data/$project/$concept/$vDD/`folder'"
		}
		
	* Version number 
		global V =  substr("$vDD", 2, .)
		
* Working directory 
	cd "$data/$project/$concept/$vDD/wd"

* Define other macros 

	* Define closing date 
		global close_d = d(01/07/2020)
		
	* Colors 
		global blue "0 155 196"
		global green "112 177 68"
		global purple "161 130 188"
		global red "185 23 70"
		
	* Current date 
		global cymd : di %tdCYND date("$S_DATE" , "DMY")
		di $cymd
		global cdate = date("$S_DATE" , "DMY")
		di $cdate
		
	