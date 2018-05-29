/*==================================================
project:       Create and organize all the indicators for the PEB
Author:        Andres Castaneda 
Dependencies:  The World Bank
-----------------------------------------------------
Creation Date:    29 May 2018 - 12:05:37
Modification Date:   
Do-file version:    01
References:          
Output:             csv dta
==================================================*/

/*==================================================
             0: Program set up
==================================================*/
program define peb, rclass
version 13

syntax anything(name=indicator id="indicator"), [ ///
CALCulate                      ///
indir(string)                  ///
outdir(string)                 ///
replace *                      /// 
]


drop _all
gtsd check peb
* Directory Paths
if ("`indir'"  == "") local indir  "\\wbgfscifs01\gtsd\02.core_team\02.data\01.Indicators"
if ("`outdir'" == "") local outdir ""


/*==================================================
               1: Poverty
==================================================*/

*---------1.1: clean the file
if ("`indicator'" == "pov") {
	use "`indir'\indicators_pov_long.dta", clear
}


split veralt, gen(valt) parse("0") 
split veralt, gen(vmst) parse("0") 
drop valt1 vmst1
destring valt2 vmst2, replace force

sort countrycode year
by countrycode year: egen maxmst = max(vmst2)
keep if maxmst == vmst2

by countrycode year: egen maxalt = max(valt2)
keep if maxalt == valt2

drop max* v*2 

* remove duplicates by module
duplicates tag countrycode year line fgt , gen(tag)
keep if (tag ==  0| (tag == 1 & module == "ALL"))
drop tag

*remove duplicates by survey. 
duplicates report countrycode year line fgt 
    
*---------1.2: Include Exceptions


/*==================================================
            2: 
==================================================*/


*--------------------2.1:


*--------------------2.2:


/*==================================================
             3: 
==================================================*/


*--------------------3.1:


*--------------------3.2:





end

exit
/* End of do-file */

><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><

Notes:
1.
adopath ++ "c:\Users\wb384996\OneDrive - WBG\GTSD\02.core_team\01.programs\01.ado\peb"
adopath - "c:\Users\wb384996\OneDrive - WBG\GTSD\02.core_team\01.programs\01.ado\peb"

2.
3.


Version Control:

local path "\\wbgfscifs01\GTSD\03.projects_corp\01.PEB\01.PEB_AM18"
shell attrib +s +h "`path'.git" & pause

shell git clone --bare -l "`path'" "`path'.git"

