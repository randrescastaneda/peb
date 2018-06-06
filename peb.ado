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
ttldir(string)                 ///
replace *                      /// 
VCdate(string)                 ///
MAXdate                        ///
trace(string)                  ///
]


drop _all
gtsd check peb

qui {
	
	/*==================================================
	Consistency Check
	==================================================*/
	* Directory Paths
	if ("`indir'"  == "") local indir  "\\wbgfscifs01\gtsd\02.core_team\02.data\01.Indicators"
	if ("`outdir'" == "") local outdir "\\wbgfscifs01\GTSD\03.projects_corp\01.PEB\01.PEB_AM18\01.PEB_AM18_QA"
	if ("`ttldir'" == "") local ttldir "\\gpvfile\GPV\Knowledge_Learning\PEB\02.tool_output\01.PovEcon_input"
	
	
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
	Update exceptions
	==================================================*/
	peb_exception load, outdir("`outdir'") ttldir("`ttldir'") datetime(`datetime')
	
	/*==================================================
	1: Basic indicators
	==================================================*/
	
	*---------1.1: clean the file
	if inlist("`indic'", "pov", "ine") {
		use "`indir'\indicators_`indic'_long.dta", clear
		
		* ---- Indicator-specific conditions
		
		* pov
		if ("`indic'" == "pov") {
			keep if fgt == 0
			rename line case
			tostring case, replace force
		}
		
		*ine
		if ("`indic'" == "ine") {
			rename ineq case 
		}
		
		*----- Organize data 
		destring year, force replace // convert to values
		
		noi peb_vcontrol, `maxdate' vcdate(`vcdate')
		local vcvar = "`r(`vconfirm')'" 
		keep if `vcvar' == 1
		
		*------- remove duplicates 
		* by module
		duplicates tag countrycode year case , gen(tag)
		keep if (tag ==  0| (tag == 1 & module == "ALL"))
		drop tag
		
		* by survey. 
		duplicates report countrycode year case 
		
		
		/* NOTE: we need to include here the default survey for each 
		country in case there are more than one.  */
		
		* ----- Create id for INDEX formula
		
		gen indicator = "`indic'"
		
		gen id = countrycode + strofreal(year) + indicator + case
		 
		keep id indicator region countrycode year filename case /* 
		*/  date time datetime values
		
		order id indicator region countrycode year filename /* 
		 */   date time  datetime case values
		
		
		*-------------------------------------------------------------
		*------------------Include Groups Data------------------------
		*-------------------------------------------------------------

		*----------Save file
		if (regexm("`trace'", "E|Ex")) set trace on
		peb_exception apply, outdir("`outdir'") // exceptions
		set trace off
		
		
		noi peb_save `indic', datetime(`datetime') outdir("`outdir'")
		
	} // end of pov
	
	
	/*==================================================
	2: 
	==================================================*/
	
	*--------------------2.1:
	
	
	/*==================================================
	3:  Master file
	==================================================*/
	
	*--------------------3.1:
	local indicators "pov ine"
	
	
	
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




datalibweb_inventory
	describe, varlist
	putmata CL=(`r(varlist)'), replace
	local n = _N
	