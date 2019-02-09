/*==================================================
project:       save PEB files
Author:        Andres Castaneda 
----------------------------------------------------------------------
Creation Date:     4 Jun 2018 - 14:15:15
==================================================*/

/*==================================================
0: Program set up
==================================================*/
program define peb_save, rclass

syntax anything(name=indic id=indicator), [  ///
outdir(string)   pause          ///
datetime(numlist)   force       ///
auxdir(string)                  ///
noexcel                         ///
]

if ("`pause'" == "pause") pause on
else                      pause off



* Indicator-specific conditions
qui {
	* Save file
	tempfile indicfile
	save `indicfile', replace
	
	if ("`force'" == "force") {
		global peb_excel_use = 0
	}
	
	*-----------------------------------------------
	* --------------- Procedure for write up file
	*-----------------------------------------------
	
	if ("`indic'" == "wup") {
		
		cap confirm new file "`outdir'\02.input/peb_`indic'.dta"
		if (_rc) {
			peb countriesin, load `pause'
			tempfile countryfile
			save `countryfile'
			
			use "`outdir'\02.input/peb_`indic'.dta", clear
			
			tostring topublish toclearance, force replace 
			merge 1:1 id using `indicfile', replace update nogen
			replace writeup = "no write-up available for " + countrycode /* 
			*/ if writeup == ""
			
			merge m:1 countrycode using `countryfile', nogen
			expand 2 if id == ""
			bysort countrycode: egen seq = seq() if id == ""
			
			replace id = countrycode + "keyf" if seq == 1
			replace id = countrycode + "nati" if seq == 2
			
			replace case = "keyfindings"  if case == "" & seq == 1
			replace case = "nationaldata" if case == "" & seq == 2
			
			replace toclearance = "0" if toclearance == "" 
			replace topublish   = "0" if topublish   == "" 
			
			local keepvars id countrycode case upi date time datetime /* 
			*/ toclearance topublish writeup region cleared 
			order `keepvars'
			keep `keepvars'
			
			peb_addregion
			
		}
		
		cap noi datasignature confirm using /* 
		*/ "`outdir'\02.input/_datasignature/peb_`indic'", strict
		local rcindic  = _rc
		
		* If data has not changed but noexcel was executed before
		if (`rcindic' == 0 & "`force'" == "" & "${peb_excel_use}" == "1") {
			noi disp in r "Warning: " in y "You previously used option {it:noexcel}. " _n /* 
		  */	 "You need to use option {it:force} to replace the current version of " _n /* 
		  */	 "the excel files."
		}
		
		if (`rcindic' != 0 | "`force'" != "") {
			noi disp in y "detailed report of changes in peb_`indic'.dta"
			noi datasignature report
			
			datasignature set, reset saving("`outdir'\02.input/_datasignature/peb_`indic'_`datetime'")
			datasignature set, reset saving("`outdir'\02.input/_datasignature/peb_`indic'", replace)
			save "`outdir'\02.input/_vintage/peb_`indic'_`datetime'.dta" 
			save "`outdir'\02.input/peb_`indic'.dta", replace
			noi disp in y "file /peb_`indic'.dta has been updated"
			
			if ("`noexcel'" == "") {
				cap export excel using "`outdir'\05.tools\peb_`indic'.xlsx" , /* 
				*/  replace first(variable) sheet(peb_`indic')
				
				* Update WUP in PEs directory
				cap export excel using "`auxdir'\peb_`indic'.xlsx" , /* 
				*/  replace first(variable) sheet(peb_`indic')
				shell attrib +s +h "`auxdir'\peb_`indic'.xlsx"
				
				if (_rc) {
					noi disp in red "Error updating /peb_`indic'.xlsx." _n /* 
					*/   "Fix and then resubmit by clicking " _c /* 
					*/   `"{stata export excel using "`outdir'\05.tools\peb_`indic'.xlsx" , replace first(variable) sheet(peb_`indic'):here}"' _n
					error
				}
				else {
					noi disp in y "file peb_`indic'.xlsx updated successfully"
				}
			} // Save Excel file end			
		} // update results data 
		exit
	}  // end of procedure for write up file
	
	*------------------------------------------------------------
	* ---------------  procedure for indicators files
	*-----------------------------------------------------------
	
	local mergevar "countrycode year case"
	local keepvars id region countrycode year source date time datetime /* 
	*/ case values indicator comparable
	
	
	
	cap confirm file "`outdir'\02.input/peb_master.dta"
	local rcmaster = _rc
	
	
	cap confirm new file "`outdir'\02.input/peb_`indic'.dta"
	if (_rc) {
		* use "`outdir'\02.input/peb_`indic'.dta", clear
		qui peb `indic', load `pause' 
		cap rename filename source
		
		cap drop _merge
		if inlist("`indic'", "shp", "key") { // this has to be changed in next round.
			cap drop in 1/l
		}
		merge 1:1 `mergevar' using `indicfile', replace update  nogen
		pause save - right after merge with indicators file
		
		* drop if inlist(values, ., 0)
		drop if values == .
		if inlist("`indic'", "pov", "ine") {
			peb_exception apply, outdir("`outdir'") `pause'	
		}
		peb_addregion
	}
	
	cap noi datasignature confirm using /* 
	*/ "`outdir'\02.input/_datasignature/peb_`indic'", strict
	local rcindic  = _rc
	if (`rcindic' != 0) {
		noi disp in y "detailed report of changes in peb_`indic'.dta"
		cap noi datasignature report
	}
		
	* If data has not changed but noexcel was executed before
	if (`rcindic' == 0 & "`force'" == "" & "${peb_excel_use}" == "1") {
		noi disp in r _n "Warning: " in y "You previously used option {it:noexcel}. " _n /* 
	  */	 "You need to use option {it:force} to replace the current version of " _n /* 
	  */	 "the excel files."
	}
	
	if (`rcindic' | `rcmaster' | "`force'" != "") { // IF file does not exist or is different
		
		datasignature set, reset saving("`outdir'\02.input/_datasignature/peb_`indic'_`datetime'")
		datasignature set, reset saving("`outdir'\02.input/_datasignature/peb_`indic'", replace)
		save "`outdir'\02.input/_vintage/peb_`indic'_`datetime'.dta" 
		save "`outdir'\02.input/peb_`indic'.dta", replace
		noi disp in y "file /peb_`indic'.dta has been updated"
		
		*** ---- Update master file--------***
		if (`rcmaster' == 0 | "`force'" != "") { // If master DOES exist
			
			qui peb master, load `pause'
			cap rename filename source
			
			drop if indicator == "`indic'" // for next round this has to change. 
			merge 1:1 `mergevar' indicator using "`outdir'\02.input/peb_`indic'.dta", /* 
			*/       replace update nogen
			
			pause save - right after merge with MASTER file 
			
			if inlist("`indic'", "pov", "ine") {
				peb_exception apply, outdir("`outdir'")	`pause'			
			}
			
			keep `keepvars'
			order `keepvars'
			
			* drop if inlist(values, ., 0)
			drop if values == .
			peb_addregion
		} 
		
		cap noi datasignature confirm using /* 
		*/ "`outdir'\02.input/_datasignature/peb_master", strict
		local rcmastsign = _rc
		if (`rcmastsign' != 0) {
			noi disp in y "detailed report of changes in peb_master.dta"
			noi datasignature report
		}
		
		if (`rcmastsign' | `rcmaster' | "`force'" != "") {  // IF file is different or does not exist
			
			* DTA file
			sort indicator countrycode source year case
			datasignature set, reset saving("`outdir'\02.input/_datasignature/peb_master_`datetime'")
			datasignature set, reset saving("`outdir'\02.input/_datasignature/peb_master", replace)
			save "`outdir'\02.input/_vintage/peb_master_`datetime'.dta" 
			save "`outdir'\02.input/peb_master.dta", replace
			noi disp in y "file /peb_master.dta has been updated"
			
			* xlsx master file
			
			cap drop __00*
			
			if ("`excel'" == "") {			
				cap export excel using "`outdir'\05.tools\peb_master.xlsx" , /* 
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
			}
			
			
		} // End of master file update
		
	} // end of indicator file update 
	else {
		noi disp in y "files /peb_`indic'.dta and /peb_master.dta not updated"
	}
	
	if ("`noexcel'" != "") {
		
		noi disp in r _n "Note:" in y "You are not saving the Excel files. " _c /* 
   */ "Make sure to use option {it:force} next time you want to " _n /* 
	 */  "replace the current Excel files."
		global peb_excel_use = 1
		
	}
	
} // end of qui


end
exit
/* End of do-file */

><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><

