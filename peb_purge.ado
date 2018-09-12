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
pause                            ///
datetime(numlist)                ///
]


*---------- conditions
if ("`pause'" == "pause") pause on
else                      pause off


* Action
if !inlist("`action'", "purge", "restore") {
	noi disp as err " {it:action} must be either load or apply"
	error
}

if ("`indics'" == "all") local indics "pov ine key"

qui {
	if ("`action'" == "purge") {
		
		peb master, load
		datasignature set, reset saving("`outdir'\02.input/_datasignature/peb_pgd_master_`datetime'")
		save "`outdir'\02.input/_vintage/peb_pgd_master_`datetime'.dta" 
		
		
		foreach indic of local indics {
			
			* Indicator file
			peb `indic', load
			datasignature set, reset saving("`outdir'\02.input/_datasignature/peb_pgd_`indic'_`datetime'")
			save "`outdir'\02.input/_vintage/peb_`indic'_`datetime'.dta" 
			
			
			if ("`country'" ==  "all") {
				drop in 1/l
			}
			else {
				drop if countrycode == "`country'"
			}
			
			datasignature set, reset saving("`outdir'\02.input/_datasignature/peb_pgd_`indic'", replace)
			save "`outdir'\02.input/peb_`indic'.dta", replace
			noi disp in y "file /peb_`indic'.dta has been updated"
			
			
			* Master file
			
			peb master, load
			if ("`country'" ==  "all") {
				drop if indicator == "`indic'" 
			}
			else {
				drop if (countrycode == "`country'" & indicator == "`indic'" )
			}
			
			save "`outdir'\02.input/peb_master.dta", replace
			noi disp in y "file /peb_master.dta has been updated"
			
		}
		datasignature set, reset saving("`outdir'\02.input/_datasignature/peb_master", replace)
		
	} // end of purge
	
	if ("`action'" == "restore") {
		noi disp "section not ready yet."
	}
	
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


