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
VCdate(passthru)               ///
MAXdate                        ///
]


drop _all
gtsd check peb

/*==================================================
               Consistency Check
==================================================*/
* Directory Paths
if ("`indir'"  == "") local indir  "\\wbgfscifs01\gtsd\02.core_team\02.data\01.Indicators"
if ("`outdir'" == "") local outdir "\\wbgfscifs01\GTSD\03.projects_corp\01.PEB\01.PEB_AM18\01.PEB_AM18_QA\02.input"


* vintage control
if ("`vcdate'" == "" & "`maxdate'" == "") local maxdate "maxdate"


/*==================================================
               1: Poverty
==================================================*/

*---------1.1: clean the file
if ("`indicator'" == "pov") {
	use "`indir'\indicators_pov_long.dta", clear
}

*----- Organize data 
destring year, force replace // convert to values
keep if fgt == 0

* vintage control
peb_vcontrol, `maxdate' `vcdate'
local vcvar = "`r(maxdate)'" // modify to make it flexible between max and vcontrol
keep if `vcvar' == 1

*------- remove duplicates 
* by module
duplicates tag countrycode year line , gen(tag)
keep if (tag ==  0| (tag == 1 & module == "ALL"))
drop tag

* by survey. 
duplicates report countrycode year line 


/* NOTE: we need to include here the default survey for each 
country in case there are more than one.  */

* ----- Create id for INDEX formula

gen id = region + countrycode + strofreal(year) /* 
 */      + "pov" + strofreal(line) 


keep id region countrycode year filename line /* 
 */  date time datetime values

order id region countrycode year filename date time  datetime line values

*---------Include Exceptions


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

