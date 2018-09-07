/*==================================================
project:       Update shared prosperity spell 
Author:        Andres Castaneda 
Dependencies:  The World Bank
----------------------------------------------------
Creation Date:    24 jul 2018 
Modification Date:   
Do-file version:    01
References:          
Output:             dta and csv file
==================================================*/

/*==================================================
0: Program set up
==================================================*/
program define peb_shpupdate, rclass
version 13

syntax , [ ///
outdir(string)     ///
ttldir(string)     ///
pause              ///
]


if ("`pause'" == "pause") pause on
else                      pause off

*-------------------------New File
local dir    "`outdir'/_aux"
local tllbku: subinstr local ttldir "\01.PovEcon_input" "", all
local tllbku = "`tllbku'/_vintage/01.PovEcon_input_backup"



import excel using "`dir'/Draft - SP AM2018 and all rounds@1.xlsx", describe 
if regexm("`r(range_1)'", "([0-9]+)$") local lrow = regexs(1)

import excel using "`dir'/Draft - SP AM2018 and all rounds@1.xlsx", /* 
*/ sheet("SP AM18") case(lower) allstring firstrow  cellrange(A1:H`lrow' ) clear

split period, parse(-) 
rename (period1 period2) (yeart0 yeart1)
rename code countrycode

duplicates tag countrycode, gen(tag)
keep if (tag==0 |(tag>0 & regexm(lower(spam2018), "yes")))

drop period tag grow*
tempfile shpspell
save `shpspell'

*------------------------- OLD file
import excel using "`tllbku'/ShPUpdate_20jul2018.xlsx", sheet("ShPUpdate") /* 
*/   firstrow case(lower) clear allstring

missings dropobs, force
desc, varlist
local vars = "`r(varlist)'"

foreach var of local vars {
	replace `var' = trim(`var')	
}

*-------------------------Merge files
merge 1:1 countrycode using `shpspell', update replace
replace check = "Updated on `c(current_date)'" if _merge == 5
replace check = "NOT updated on `c(current_date)'" if _merge == 3 & check == ""
replace check = "New data added on `c(current_date)'" if _merge == 2 

replace welfaret0 = "welfare" if _merge == 2
replace welfaret1 = "welfare" if _merge == 2

drop _merge


*------------------------- Save new file
export excel using "`ttldir'/ShPUpdate.xlsx", sheet("ShPUpdate") /* 
*/ replace firstrow(variable)


end



exit
/* End of do-file */

><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><

Notes:
1.
2.
3.


Version Control:


/*==================================================

==================================================*/