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

syntax anything(name=indic id="indicator"), [ ///
CALCulate                      ///
indir(string)                  ///
outdir(string)                 ///
replace *                      /// 
VCdate(string)                 ///
MAXdate                        ///
]


drop _all
gtsd check peb

qui {
	
	/*==================================================
	Consistency Check
	==================================================*/
	* Directory Paths
	if ("`indir'"  == "") local indir  "\\wbgfscifs01\gtsd\02.core_team\02.data\01.Indicators"
	if ("`outdir'" == "") local outdir "\\wbgfscifs01\GTSD\03.projects_corp\01.PEB\01.PEB_AM18\01.PEB_AM18_QA\02.input"
	
	
	* vintage control
	if ("`vcdate'" == "" & "`maxdate'" == "") local maxdate "maxdate"
	if ("`vcdate'"  != "") local vconfirm "vcdate"
	if ("`maxdate'" != "") local vconfirm "maxdate"
	if ("`vcdate'"  != "" & "`maxdate'" != "" ) {
		noi disp as err "you must select either {cmd:vcdate()} or {cmd:maxdate}."
		error
	}
	
	
	* dates
	local date = date("`c(current_date)'", "DMY")  // %tdDDmonCCYY
	local time = clock("`c(current_time)'", "hms") // %tcHH:MM:SS
	loca datetime = `date'*24*60*60*1000 + `time'  // %tcDDmonCCYY_HH:MM:SS
	
	* indic
	if wordcount("`indic'") != 1 {
		noi disp as err "you must specify one {cmd:indicator} at a time."
		error 
	}
	
	
	/*==================================================
	Prepare final file
	==================================================*/
	
	* cap confirm file "`outdir'/peb_master.dta"
	
	
	/*==================================================
	1: Poverty
	==================================================*/
	
	*---------1.1: clean the file
	if ("`indic'" == "pov") {
		use "`indir'\indicators_`indic'_long.dta", clear
		
		*----- Organize data 
		destring year, force replace // convert to values
		keep if fgt == 0
		
		noi peb_vcontrol, `maxdate' vcdate(`vcdate')
		local vcvar = "`r(`vconfirm')'" 
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
		*/      + "`indic'" + strofreal(line) 
		
		
		keep id region countrycode year filename line /* 
		*/  date time datetime values
		
		order id region countrycode year filename date time  datetime line values
		
		*---------Include Exceptions
		
		* Save file
		noi peb_save `indic', datetime(`datetime') outdir("`outdir'")
		
	} // end of pov
	
	
	/*==================================================
	2: Inequality
	==================================================*/
	
	*--------------------2.1:
	if ("`indic'" == "ine") {
		use "`indir'\indicators_`indic'_long.dta", clear
	}
	
	*--------------------2.2:
	
	
	/*==================================================
	3: 
	==================================================*/
	
	
	*--------------------3.1:
	
	
	*--------------------3.2:
	
	
	
	
}

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

