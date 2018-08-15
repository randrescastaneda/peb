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
]

if ("`pause'" == "pause") pause on
else                      pause off



* Indicator-specific conditions
qui {
	* Save file
	tempfile indicfile
	save `indicfile', replace
	
	
	
	* --------------- Procedure for write up file
	
	if ("`indic'" == "wup") {
		
		cap confirm new file "`outdir'\02.input/peb_`indic'.dta"
		if (_rc) {
			use "`outdir'\02.input/peb_`indic'.dta", clear
			
			tostring topublish toclearance, force replace 
			merge 1:1 id using `indicfile', replace update nogen
			drop if writeup == ""
		}
		
		cap noi datasignature confirm using /* 
		*/ "`outdir'\02.input/_datasignature/peb_`indic'", strict
		local rcindic  = _rc
		if (`rcindic' != 0) {
			noi disp in y "detailed report of changes in peb_`indic'.dta"
			noi datasignature report
		}
		
		peb_addregion
		order id countrycode case upi date time datetime /* 
		 */ toclearance topublish writeup region cleared 
		
		datasignature set, reset saving("`outdir'\02.input/_datasignature/peb_`indic'_`datetime'")
		datasignature set, reset saving("`outdir'\02.input/_datasignature/peb_`indic'", replace)
		save "`outdir'\02.input/_vintage/peb_`indic'_`datetime'.dta" 
		save "`outdir'\02.input/peb_`indic'.dta", replace
		noi disp in y "file /peb_`indic'.dta has been updated"
		
		cap drop __00*
		cap export excel using "`outdir'\05.tools\peb_`indic'.xlsx" , /* 
		 */  replace first(variable) sheet(peb_`indic')
		
		if (_rc) {
			noi disp in red "Error updating /peb_`indic'.xlsx." _n /* 
			*/   "Fix and then resubmit by clicking " _c /* 
			*/   `"{stata export excel using "`outdir'\05.tools\peb_`indic'.xlsx" , replace first(variable) sheet(peb_`indic'):here}"' _n
			error
		}
		else {
			noi disp in y "file peb_`indic'.xlsx updated successfully"
		}
		
		exit
	}  // end of procedure for write up file
	
	* ---------------  procedure for indicators files
	
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
		merge 1:1 `mergevar' using `indicfile', replace update  nogen
		pause save - right after merge with indicators file
		
		drop if inlist(values, ., 0)
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
	
	
	if (`rcindic' | `rcmaster' | "`force'" != "") { // IF file does not exist or is different
		
		datasignature set, reset saving("`outdir'\02.input/_datasignature/peb_`indic'_`datetime'")
		datasignature set, reset saving("`outdir'\02.input/_datasignature/peb_`indic'", replace)
		save "`outdir'\02.input/_vintage/peb_`indic'_`datetime'.dta" 
		save "`outdir'\02.input/peb_`indic'.dta", replace
		noi disp in y "file /peb_`indic'.dta has been updated"
		
		*** ---- Update master file--------***
		if (`rcmaster' == 0 | "`force'" != "") { // If master DOES exist
			* use "`outdir'\02.input/peb_master.dta", clear
			qui peb master, load `pause'
			cap rename filename source
			
			merge 1:1 `mergevar' indicator using "`outdir'\02.input/peb_`indic'.dta", /* 
			*/       replace update nogen
			
			pause save - right after merge with MASTER file 
			
			if inlist("`indic'", "pov", "ine") {
				peb_exception apply, outdir("`outdir'")	`pause'			
			}

			keep `keepvars'
			order `keepvars'
			
			drop if inlist(values, ., 0)
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
			cap export excel using "`outdir'\05.tools\peb_master.xlsx" , /* 
		 */  replace first(variable) sheet(peb_master)
		
			
			if (_rc) {
				noi disp in red "Error updating /peb_master.xlsx." _n /* 
				*/   "Fix and then resubmit by clicking " _c /* 
				*/   `"{stata export excel using "`outdir'\05.tools\peb_master.xlsx" , replace first(variable) sheet(peb_master):here}"' _n
				error
			}
			else {
				noi disp in y "file peb_master.xlsx updated successfully"
			}
			
		} // End of master file update
		
	} // end of indicator file update 
	else {
		noi disp in y "files /peb_`indic'.dta and /peb_master.dta not updated"
	}
}


end
exit
/* End of do-file */

><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><

