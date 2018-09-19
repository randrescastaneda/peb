/*==================================================
project:       Load and apply exceptions to peb output
Author:        Andres Castaneda 
Dependencies:  The World Bank
----------------------------------------
Creation Date:     6 Jun 2018 - 16:03:36
Modification Date:   
Do-file version:    01
References:          
Output:             modify peb_master file
==================================================*/

/*==================================================
0: Program set up
==================================================*/
program define peb_purge, rclass
syntax anything(name=action id=action), [  ///
country(string)                ///
ttldir(string)                   ///
outdir(string)                   ///
indics(string)                   ///
pause update                     ///
datetime(numlist)                ///
]


*---------- conditions
if ("`pause'" == "pause") pause on
else                      pause off

local auxdir "\\gpvfile\GPV\Knowledge_Learning\Global_Stats_Team\PEB\AM2018\01.tool\_aux"

* Action
if !inlist("`action'", "purge", "restore") {
	noi disp as err " {it:action} must be either load or apply"
	error
}


if ("`indics'" == "all") local indics "pov ine key"

qui {
	
	******************************************************
	* Purge a file from a particular country
	******************************************************
	if ("`action'" == "purge") {
		noi disp in y "Purging files"
		peb master, load
		datasignature set, reset saving("`outdir'\02.input/_datasignature/peb_pgd_master_`datetime'")
		save "`outdir'\02.input/_vintage/peb_pgd_master_`datetime'.dta" 
		
		
		foreach indic of local indics {
			
			* Indicator file
			peb `indic', load
			datasignature set, reset saving("`outdir'\02.input/_datasignature/peb_pgd_`indic'_`datetime'")
			save "`outdir'\02.input/_vintage/peb_`indic'_`datetime'.dta" 
			
			
			if (lower("`country'") ==  "all") {
				cap drop in 1/l
			}
			else {
				drop if countrycode == "`country'"
			}
			
			datasignature set, reset saving("`outdir'\02.input/_datasignature/peb_pgd_`indic'", replace)
			save "`outdir'\02.input/peb_`indic'.dta", replace
			noi disp in y "file /peb_`indic'.dta has been updated"
			
			
			* Master file
			
			peb master, load
			if (lower("`country'") ==  "all") {
				drop if indicator == "`indic'" 
			}
			else {
				drop if (countrycode == "`country'" & indicator == "`indic'" )
			}
			
			save "`outdir'\02.input/peb_master.dta", replace
			noi disp in y "file /peb_master.dta has been updated"
			
		}
		datasignature set, reset saving("`outdir'\02.input/_datasignature/peb_master", replace)
		
		* update is required. 
		if ("`update'" == "update") {
			noi disp in y "Updating files"
			foreach indic of local indics {
				peb `indic', force
			}
		}
		
	} // end of purge
	
	******************************************************
	* Restore a particular version of the file
	******************************************************
	
	if ("`action'" == "restore") {
		
		if wordcount("`indics'")!= 1  {
			noi disp in red "you must select only one indicator when using options {it:restore}"
			error
		}
		
		* local outdir "\\wbgfscifs01\GTSD\03.projects_corp\01.PEB\01.PEB_AM18\01.PEB_AM18_QA"
		* local indics "pov"
		
		local files: dir "`outdir'/02.input\_vintage" files "peb_`indics'*"
		local vcnumbers: subinstr local files "peb_`indics'_" "", all
		local vcnumbers: subinstr local vcnumbers ".dta" "", all
		local vcnumbers: list sort vcnumbers
		
		disp `"`vcnumbers'"'
		
		* return local vcnumbers = "`vcnumbers'"
		noi disp in y "list of available vintage control dates for file peb_`indics'"
		local alldates ""
		local i = 0
		foreach vc of local vcnumbers {
			
			local ++i
			if (length("`i'") == 1 ) local i = "00`i'"
			if (length("`i'") == 2 ) local i = "0`i'"
			
			if regexm("`vc'", "([0-9]+)_(rf)([a-z]*)_([0-9]+)") {  // if version was restored 
				local vc1 = regexs(1)
				local vc2 = regexs(4)
				local find = "restored from " + regexs(3)
			}
			else {
				local vc1  = "`vc'"
				local vc2  = ""
				local find = ""
			}
			
			
			local dispdate: disp %tcDDmonCCYY_HH:MM:SS `vc1'
			local dispdate = trim("`dispdate'")
			
			if ("`vc2'" != "") {
				local dispdate2: disp %tcDDmonCCYY_HH:MM:SS `vc2'
				local dispdate2 = trim("`dispdate2'")
			}
			
			
			noi disp `"   `i' {c |} {stata `vc1':`dispdate'} `find' `dispdate2'"'
			
			local alldates "`alldates' `dispdate'"
		}
		
		noi disp _n "select vintage control date from the list above" _request(_vcnumber)
		local vcdate: disp %tcDDmonCCYY_HH:MM:SS `vcnumber' 
		
		confirm file "`outdir'/02.input\_vintage/peb_`indics'_`vcnumber'.dta"
		
		cap window stopbox rusure /* 
		*/  "You are about to replace current peb_`indics' files with "  /* 
		*/  "file peb_`indics'_`vcnumber' from `vcdate'" /* 
		*/  "Are you sure want to make that change?"
		if (_rc != 0) error
		
		use "`outdir'/02.input\_vintage/peb_`indics'_`vcnumber'.dta", clear
		local basename "peb_`indics'"
		
		cap noi datasignature confirm using /* 
		*/ "`outdir'\02.input/_datasignature/peb_`indics'", strict
		local rcindic  = _rc
		if (`rcindic' != 0) {
		
			noi disp in y "detailed report of changes in peb_`indics'.dta"
			cap noi datasignature report
			
			datasignature set, reset saving("`outdir'\02.input/_datasignature/peb_`indics'", replace)
			save "`outdir'\02.input/_vintage/peb_`indics'_`datetime'_rf_`vcnumber'.dta" 
			save "`outdir'\02.input/peb_`indics'.dta", replace
			noi disp in y "file /peb_`indics'.dta has been updated"
			
			* For the WUP
			if ("`indics'" == "wup") {
				cap export excel using "`outdir'\05.tools\peb_`indics'.xlsx" , /* 
				*/  replace first(variable) sheet(peb_`indics')
				
				* Update WUP in PEs directory
				cap export excel using "`auxdir'\peb_`indics'.xlsx" , /* 
				*/  replace first(variable) sheet(peb_`indics')
				
				shell attrib +s +h "`auxdir'\peb_`indics'.xlsx"
			}  // end of wup
			
			* For the Master
			if regexm("`indics'", "pov|ine|npl|shp|plc|^key$|key_GD") {
				
				local mergevar "countrycode year case"
				qui peb master, load `pause'
				cap rename filename source
				
				drop if indicator == "`indics'" // for next round this has to change. 
				merge 1:1 `mergevar' indicator using "`outdir'\02.input/peb_`indics'.dta", /* 
				*/       replace update nogen
				
				sort indicator countrycode source year case
				datasignature set, reset saving("`outdir'\02.input/_datasignature/peb_master", replace)
				save "`outdir'\02.input/_vintage/peb_master_`datetime'_rf`indics'_`vcnumber'.dta" 
				save "`outdir'\02.input/peb_master.dta", replace
				noi disp in y "file /peb_master.dta has been updated"
				
				* xlsx master file
			} // end of no master in indics
			
			* save to Excel file
			if regexm("`indics'", "pov|ine|npl|shp|plc|^key$|key_GD|master") {
			cap drop __00*
				export excel using "`outdir'\05.tools\peb_master.xlsx" , /* 
				*/  replace first(variable) sheet(peb_master)
				
				* Update master in PEs directory
				cap export excel using "`auxdir'\peb_master.xlsx" , /* 
				*/  replace first(variable) sheet(peb_master)
				
				shell attrib +s +h "`auxdir'\peb_master.xlsx"
				
				if (_rc) {
					noi disp in red "Error updating /peb_master.xlsx." _n /* 
					*/   "Fix and then resubmit by clicking " _c /* 
					*/   `"{stata export excel using "`outdir'\05.tools\peb_master.xlsx" , replace first(variable) sheet(peb_master):here}"' _n
					error
				}
				else {
					noi disp in y "file peb_master.xlsx updated successfully"
				}	
				
			}	 // end of saving to Excel file
			
		} // end of when datasignature is different (whish should always be)
		
	} // end of restore
	
} // end of qui

end

exit
/* End of do-file */

		><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
		
		Notes:
		1.
		2.
		3.
		
		
		Version Control:
		
		
				