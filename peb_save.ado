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
	if ("`indic'" == "pov") {
		local mergevar "countrycode year line"
	}
	
	
	* Save file
	tempfile indicfile
	save `indicfile', replace
	
	cap confirm new file "`outdir'/peb_`indic'.dta"
	if (_rc) {
		use "`outdir'/peb_`indic'.dta", clear
		merge 1:1 `mergevar' using `indicfile', replace update nogen
	}
	cap noi datasignature confirm, strict
	if (_rc) {
		datasignature set, reset saving("`outdir'/_datasignature/peb_`indic'_`datetime'")
		save "`outdir'/_vintage/peb_`indic'_`datetime'.dta" 
		save "`outdir'/peb_`indic'.dta", replace
		noi disp in y "file /peb_`indic'.dta has been updated"
	}
	else {
		noi disp in y "file /peb_`indic'.dta not updated"
	}
		
}


end
exit
/* End of do-file */

><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
