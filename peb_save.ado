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
outdir(string)                  ///
datetime(numlist)               ///
]

* Indicator-specific conditions
qui {
	if inlist("`indic'", "pov", "ine") {
		local mergevar "countrycode year case"
	}
	
	
	cap confirm file "`outdir'\02.input/peb_master.dta"
	local rcmaster = _rc
	
	* Save file
	tempfile indicfile
	save `indicfile', replace
	
	cap confirm new file "`outdir'\02.input/peb_`indic'.dta"
	if (_rc) {
		use "`outdir'\02.input/peb_`indic'.dta", clear
		merge 1:1 `mergevar' using `indicfile', replace update nogen
	}
	
	cap noi datasignature confirm, strict
	local rcindic  = _rc
	
	if (`rcindic' | `rcmaster') { // IF file does not exist or is different
		
		datasignature set, reset saving("`outdir'\02.input/_datasignature/peb_`indic'_`datetime'")
		save "`outdir'\02.input/_vintage/peb_`indic'_`datetime'.dta" 
		save "`outdir'\02.input/peb_`indic'.dta", replace
		noi disp in y "file /peb_`indic'.dta has been updated"
		
		*** ---- Update master file--------***
		if (`rcmaster' == 0) { // If master DOES exist
			use "`outdir'\02.input/peb_master.dta", clear
			merge 1:1 `mergevar' indicator using "`outdir'\02.input/peb_`indic'.dta", /* 
			*/       replace update nogen
		} 
		
		cap noi datasignature confirm, strict
		if (_rc | `rcmaster') {  // IF file is different of dile does not exist
			
			* DTA file
			datasignature set, reset saving("`outdir'\02.input/_datasignature/peb_master_`datetime'")
			save "`outdir'\02.input/_vintage/peb_master_`datetime'.dta" 
			save "`outdir'\02.input/peb_master.dta", replace
			noi disp in y "file /peb_master.dta has been updated"
			
			* Excel Tool
			cap export excel using "`outdir'\05.tools\PEB_template_AM18.xlsm" , /* 
			*/         sheet("master") sheetreplace first(variables) 
			if (_rc) {
				noi disp in red "Error updating PEB_template_AM18.xlsm." _n /* 
				*/   "Fix and then resubmit by clicking " _c /* 
				*/   `"{stata export excel using "`outdir'\05.tools\PEB_template_AM18.xlsm" , sheet("master") sheetreplace first(variables):here}"' _n
			}
			else {
				noi disp in y "file PEB_template_AM18.xlsm updated successfully"
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
