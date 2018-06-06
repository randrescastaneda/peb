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
program define peb_exception, rclass
syntax anything(name=action id=action), [  ///
ttldir(string)                   ///
outdir(string)                   ///
datetime(numlist)                ///
]

*---------- conditions

* Action
if !inlist("`action'", "load", "apply") {
	noi disp as err " {it:action} must be either load or apply"
	error
}

qui {
	
	
	/*==================================================
	1: Load
	==================================================*/
	*----------1.1:
	if ("`action'" == "load") {
		import excel using "`ttldir'/Exceptions.xlsx", sheet("Exceptions") /* 
		*/   firstrow case(lower) clear allstring
		
		* reshape long values, i(code) j(condition) string
		rename code countrycode
		drop countryname
		
		cap datasignature confirm using "`outdir'/02.input/_datasignature/peb_exceptions", strict 
		if (_rc) {
			noi disp in r "NOTE: " in y "peb_xceptions.dta has changed or does not exist. " _c /* 
			*/  " It will be updated/created from file Exceptions.xlsx in ttldir()" _n
			
			datasignature set, reset saving("`outdir'/02.input/_datasignature/peb_exceptions_`datetime'") 
			datasignature set, reset saving("`outdir'/02.input/_datasignature/peb_exceptions", replace) 
			save "`outdir'/02.input/peb_exceptions.dta", replace
		}
		else {
			noi disp in y "peb_xceptions.dta is up to date."
		}
	} // end of load condition
	
	/*==================================================
	2: Apply
	==================================================*/
	
	*----------2.1:
	if ("`action'" == "apply") {
		
		*merge 
		merge m:1 countrycode using "`outdir'/02.input/peb_exceptions.dta", /*  
		*/ nogen keep(master match)
		
		
		* Exclude countries
		drop if ex_country == "1"
		
		* Exclude years in particular countries
		sort countrycode year
		gen ex_n     = _n 
		gen ex_2drop = 0
		levelsof countrycode if ex_spell_pov_ine != "", local(codes)
		foreach code of local codes {
			sum ex_n if countrycode == "`code'", meanonly
			local minn = `r(min)'
			numlist "`=ex_spell_pov_ine[`minn']'"
			local yearlist = "`r(numlist)'"
			local yearlist: subinstr local yearlist " " "|", all
			replace ex_2drop = 1 if (countrycode == "`code'" &  /* 
			*/     !regexm(strofreal(year), "`yearlist'"))
		}
		
	
		drop if ex_2drop == 1
	
	* Exclude lines or gini
		local cases "190 190c 320 550 gini"
		foreach case of local cases {
			if (regexm("`case'", "[0-9]")) local casevar "fgt0_`case'"
			else                           local casevar "`case'"
			drop if case == "`case'" & ex_`casevar' == "1"
		}
		
		* drop ex_ vars
		drop ex_*
		noi disp in y _n "Exceptions apply successfully"
		
	} // end of apply condition
	
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


