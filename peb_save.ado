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
	
	local mergevar "countrycode year case"
	
	
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
	
	cap noi datasignature confirm using /* 
	 */ "`outdir'\02.input/_datasignature/peb_`indic'", strict
	local rcindic  = _rc
	if (`rcindic' != 0) {
		noi disp in y "detailed report of changes in peb_`indic'.dta"
		noi datasignature report
	}
	
	
	if (`rcindic' | `rcmaster') { // IF file does not exist or is different
		
		datasignature set, reset saving("`outdir'\02.input/_datasignature/peb_`indic'_`datetime'")
		datasignature set, reset saving("`outdir'\02.input/_datasignature/peb_`indic'", replace)
		save "`outdir'\02.input/_vintage/peb_`indic'_`datetime'.dta" 
		save "`outdir'\02.input/peb_`indic'.dta", replace
		noi disp in y "file /peb_`indic'.dta has been updated"
		
		*** ---- Update master file--------***
		if (`rcmaster' == 0) { // If master DOES exist
			use "`outdir'\02.input/peb_master.dta", clear
			merge 1:1 `mergevar' indicator using "`outdir'\02.input/peb_`indic'.dta", /* 
			*/       replace update nogen
			
			if inlist("`indic'", "pov", "ine") {
				peb_exception apply, outdir("`outdir'")				
			}
			
		} 
		
		cap noi datasignature confirm using /* 
		 */ "`outdir'\02.input/_datasignature/peb_master", strict
		local rcmastsign = _rc
		if (`rcmastsign' != 0) {
			noi disp in y "detailed report of changes in peb_master.dta"
			noi datasignature report
		}
		
		if (`rcmastsign' | `rcmaster') {  // IF file is different of dile does not exist
			
			* DTA file
			datasignature set, reset saving("`outdir'\02.input/_datasignature/peb_master_`datetime'")
			datasignature set, reset saving("`outdir'\02.input/_datasignature/peb_master", replace)
			save "`outdir'\02.input/_vintage/peb_master_`datetime'.dta" 
			save "`outdir'\02.input/peb_master.dta", replace
			noi disp in y "file /peb_master.dta has been updated"
			
			* CSV master file
			
			cap export delimited using "`outdir'\05.tools\peb_master.csv" , replace 
			
			if (_rc) {
				noi disp in red "Error updating /peb_master.csv." _n /* 
				*/   "Fix and then resubmit by clicking " _c /* 
				*/   `"{stata export delimited using "`outdir'\05.tools\peb_master.csv" , replace:here}"' _n
				error
			}
			else {
				noi disp in y "file peb_master.csv updated successfully"
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
