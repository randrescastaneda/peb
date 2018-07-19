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
load  shape(string)            ///
GROUPdata   pause              ///
]


drop _all
gtsd check peb
if ("`pause'" == "pause") pause on
else pause off


qui {
	
	/*==================================================
	Consistency Check
	==================================================*/
	* Directory Paths
	if ("`indir'"  == "") local indir  "//wbgfscifs01\gtsd\02.core_team\02.data\01.Indicators"
	if ("`outdir'" == "") local outdir "//wbgfscifs01\GTSD\03.projects_corp\01.PEB\01.PEB_AM18\01.PEB_AM18_QA"
	if ("`ttldir'" == "") local ttldir "//gpvfile\GPV\Knowledge_Learning\PEB\02.tool_output\01.PovEcon_input"
	
	
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
	
	
	/*====================================================================
	Load files
	====================================================================*/
	
	if ("`load'" == "load") {
		if wordcount("`indic'") != 1 {
			noi disp in red "Only one file can be loaded"
			error
		}
		use "`outdir'\02.input/peb_`indic'.dta", clear
		exit
	}
	
	
	/*==================================================
	Update exceptions
	==================================================*/
	peb_exception load, outdir("`outdir'") ttldir("`ttldir'") /* 
	*/ datetime(`datetime') indic("`indic'")
	
	
	/*==================================================
	Group data
	==================================================*/
	if ("`groupdata'" != "") {
		peb_groupdata `indic', outdir("`outdir'") ttldir("`ttldir'") /* 
		*/  indir("`indir'") 
		exit 
	}
	
	
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
		
		* Comparable years
		merge m:1 countrycode year welfarevar using "`outdir'/02.input/peb_comparable.dta", /*  
		*/  keep(match) keepusing(comparable) nogen
		
		destring comparable, replace force
		
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
		
		tostring year, replace force
		gen id = countrycode + year + indicator + case
		
		keep id indicator region countrycode year filename case /* 
		*/  date time datetime values comparable
		
		order id indicator region countrycode year filename /* 
		*/   date time  datetime case values comparable
		
		
		*-------------------------------------------------------------
		*------------------Include Group Data------------------------
		*-------------------------------------------------------------
		
		merge 1:1 id using "`outdir'\02.input/peb_`indic'_GD.dta", nogen /* 
		*/ update replace  
		
		*----------Save file
		if (regexm("`trace'", "E|Ex")) set trace on
		peb_exception apply, outdir("`outdir'") // exceptions
		set trace off
		
		rename filename source 
		noi peb_save `indic', datetime(`datetime') outdir("`outdir'")
		
	} // end of pov and ine
	
	
	/*==================================================
	2: Shared Prosperity
	==================================================*/
	*---------------2.1:
	if ("`indic'" == "shp") {
		
		use "`indir'\indicators_`indic'_long.dta", clear
		destring year, force replace // convert to values
		noi peb_vcontrol, `maxdate' vcdate(`vcdate')
		local vcvar = "`r(`vconfirm')'" 
		keep if `vcvar' == 1
		
		
		* Merge with Exceptions
		merge m:1 countrycode using "`outdir'/02.input/peb_shpupdate.dta", /* 
		*/   keep(match) nogen
		gen ytemp = yeart0 + "-" + yeart1
		destring yeart0 yeart1, replace force
		
		* keep relevant data
		keep if inlist(year, yeart0, yeart1)
		keep if inlist(welfarevar, welfaret0, welfaret1)
		keep if inlist(case, "b40", "mean")
		* filter by module
		duplicates tag countrycode survname year case, gen(tag)
		keep if (tag ==  0| (tag > 0 & module == "ALL"))
		drop tag
		
		* Filter survey
		duplicates tag countrycode year case surveyname, gen(tag)
		keep if ((survname == surveyname & tag >0) |tag == 0)
		drop tag
		
		
		* annualized growth
		bysort countrycode survname case (year): gen growth = /* 
		*/  (values[_n]/values[_n-1])^(1/(year[_n]-year[_n-1])) -1 
		
		keep if growth != .
		
		* expand to add premium
		gen expand = cond(case == "b40", 2, 1)
		expand expand, gen(tag)
		replace case = "pre" if tag ==1
		
		* calculate premium
		bysort countrycode (tag case): replace growth = /* 
		*/ growth[_n-2] - growth[_n-1] if tag ==1
		
		* Create ID and keep relevant data
		
		gen indicator = "`indic'"
		
		replace case = "tot" if case == "mean"
		gen id = countrycode + indicator + case
		
		
		keep id indicator region countrycode ytemp filename case /* 
		*/  date time datetime growth
		
		rename (ytemp growth) (year values)
		
		order id indicator region countrycode year filename /* 
		*/   date time  datetime case values
		
		
		merge 1:1 id using "`outdir'\02.input/peb_`indic'_GD.dta", nogen /* 
		*/ update replace  
		
		
		* Save data
		rename filename source 
		noi peb_save `indic', datetime(`datetime') outdir("`outdir'")
	}
	
	/*==================================================
	3: National Poverty numbers
	==================================================*/
	
	if ("`indic'" == "npl") {
		
		*-------------------- Data from TTL
		use "`outdir'/02.input/peb_nplupdate.dta", clear
		* fix dates
		_gendatetime_var date time
		
		
		* include Population provided by the TTL
		merge m:1 countrycode using "`outdir'/02.input/peb_exceptions.dta", /*  
		*/ nogen keep(master match) keepusing(ex_nu_poor_npl)
		
		* Rename variables to be reshaped 
		rename (population line gini) values=		
		rename ex_* values*
		
		reshape long values, i(countrycode year datetime) j(case) string
		
		replace case = "popu" if case == "population"
		replace case = "pttl" if case == "nu_poor_npl"
		destring values, replace force
		
		
		keep countrycode year datetime date time case values
		gen indicator = "npl"
		gen source = "TTL"
		drop if values == . // if TTL didn't provide info
		
		pause npl- before keepting max date
		
		bysort countrycode year case: egen double maxdate = max(datetime)
		replace maxdate = cond(maxdate == datetime, 1, 0)
		keep if maxdate == 1
		
		pause npl- after keeping max date
		
		gen id = countrycode + year + indicator + case
		
		order id indicator countrycode year source /* 
		*/   date time  datetime case values
		
		tempfile ttlfile
		save `ttlfile'
		
		*-------------------- Data from WDI
		use "`indir'\indicators_wdi_long.dta", clear
		keep if inlist(case, "si_pov_nahc","sp_pop_totl","ny_gdp_pcap_pp_kd","ny_gnp_pcap_kd")
		
		replace countrycode="KSV" if countrycode=="XKX"
		
		replace case = "line"  if case == "si_pov_nahc" 
		replace case = "popu"  if case == "sp_pop_totl" 
		replace case = "gdppc" if case == "ny_gdp_pcap_pp_kd" 
		replace case = "gnppc" if case == "ny_gnp_pcap_kd" 
		
		pause after loading wdi information
		
		noi peb_vcontrol, `maxdate' vcdate(`vcdate')
		local vcvar = "`r(`vconfirm')'" 
		keep if `vcvar' == 1
		
		gen indicator = "npl"
		gen source = "WDI"
		
		pause after controling for vc_
		
		bysort countrycode year case (datetime): egen double maxdate = max(datetime)
		replace maxdate = cond(maxdate == datetime, 1, 0)
		keep if maxdate == 1
		
		pause after keepging maxdate in wdi file 
		
		
		tostring year, replace force 
		gen id = countrycode + year + indicator + case
		
		order id indicator countrycode year source /* 
		*/   date time  datetime case values
		
		*--------------Append TTL file and WDI data
		
		append using `ttlfile'
		keep if real(year) >= 2000
		
		pause before droping duplicates 
		
		duplicates tag id, gen(tag)
		keep if (tag == 0 | (tag >0 & source == "TTL"))
		drop tag 
		
		pause after droping duplicates 
		
		order id indicator countrycode year source /* 
		*/   date time  datetime case values
		
		keep id indicator countrycode year source /* 
		*/   date time  datetime case values
		
		noi peb_save `indic', datetime(`datetime') outdir("`outdir'")
		
		
	} // End of National POverty lines and Macro indicators. 
	
	/*==================================================
	4: Key Indicators
	==================================================*/
	
	*--------------------
	if ("`indic'" == "key") {
		use "`outdir'/02.input/peb_keyupdate.dta", clear
		
		_gendatetime_var date time
		
		replace countrycode = trim(countrycode)
		
		*Create precase
		gen precase = ""				
		replace precase = "edu1"  if regexm(indicator, "^Without")
		replace precase = "edu2"  if regexm(indicator, "^Primary")
		replace precase = "edu3"  if regexm(indicator, "^Secondary")
		replace precase = "edu4"  if regexm(indicator, "^Tertiary")
		replace precase = "gage1" if regexm(indicator, "^0 to 14 ")
		replace precase = "gage2" if regexm(indicator, "^15 to 64")
		replace precase = "gage3" if regexm(indicator, "^65 and ")
		replace precase = "male1" if regexm(indicator, "^[Ff]emale")
		replace precase = "male2" if regexm(indicator, "^[Mm]ale")
		replace precase = "rur1"  if regexm(indicator, "^Urban")
		replace precase = "rur2"  if regexm(indicator, "^Rural")
		
		* max date per country
		tempvar mdatetime
		bysort countrycode precase: egen double `mdatetime' = max(datetime)
		keep if datetime == `mdatetime' 
		
		
		* create variable for poverty line to use
		preserve 
		keep if regexm(indicator, "^Poverty line") 
		gen line2disp = cond(regexm(publish, "^[Uu]p"), 550,  /* 
		*/              cond(regexm(publish, "^[Ll]o"), 320, 190)) 
		keep countrycode line2disp
		tempfile lined
		save `lined'
		restore
		
		merge  m:1 countrycode using `lined', nogen
		drop if regexm(indicator, "^Poverty line") 
		
		
		* Save temporal file
		tempfile keyu
		save `keyu', replace
		
		
		* Load indicators file
		use "`indir'\indicators_`indic'_wide.dta", clear
		
		destring year, force replace // convert to values
		noi peb_vcontrol, `maxdate' vcdate(`vcdate')
		local vcvar = "`r(`vconfirm')'" 
		keep if `vcvar' == 1
		keep if welfarevar == "welfare"
		
		* Max year per country
		tempvar myear
		bysort countrycode: egen double `myear' = max(year)
		keep if year == `myear' 
		tostring year, replace force
		
		* Filter by survey in case there is more than one
		merge m:1 countrycode using "`outdir'/02.input/peb_shpupdate.dta", /* 
		*/	nogen keepusing(surveyname) keep(master match)
		
		
		duplicates tag countrycode precase, gen(tag)
		keep if ((survname == surveyname & tag >0) |tag == 0)
		drop tag
		
		* Merge with Exceptions
		merge 1:1 countrycode precase using `keyu', /* 
		*/	keepusing(publish line2disp) keep(master match) nogen
		
		* clean data 
		replace line2disp = 190 if line2disp == . 
		replace publish = "YES" if publish == ""
		drop if publish == "NO"
		
		reshape long values, i(countrycode  precase) /* 
		*/     j(case) string
		
		keep if (regexm(case, "^[BT]") | real(substr(case, 1,3)) == line2disp)
		
		
		* Organize before save
		
		gen indicator = "key"
		rename filename source
		
		gen id = cond(regexm(case, "^[BT]"), /* 
	  */	          countrycode + indicator + precase + case, /* 
		*/            countrycode + indicator + precase + substr(case, 4,.))
		
		replace case = precase + case
		
		order id indicator countrycode year source /* 
		*/   date time  datetime case values
		
		keep id indicator countrycode year source /* 
		*/   date time  datetime case values
		
			
		merge 1:1 id using "`outdir'\02.input/peb_`indic'_GD.dta", nogen /* 
		*/ update replace  
		
		
		noi peb_save `indic', datetime(`datetime') outdir("`outdir'")
		
	}
	
	*--------------------
	
	/*==================================================
	5. Write ups
	==================================================*/
	
	*--------------------
	if ("`indic'" == "wup") {
		use "`outdir'/02.input/peb_writeupupdate.dta", clear
		missings dropvars, force
		_gendatetime_var date time
		
		* max date per country
		tempvar mdatetime
		bysort countrycode: egen double `mdatetime' = max(datetime)
		keep if datetime == `mdatetime' 
		drop `mdatetime' 
		
		destring toclearance topublish, replace force
		
		rename (keyfindings  nationaldata) writeup=
		reshape long writeup, i(countrycode) j(case) string
		
		gen id = countrycode + substr(case, 1, 4)
		
		
		replace writeup = subinstr(writeup, `"“"', `"""', .)
		replace writeup = subinstr(writeup, `"”"', `"""', .)
		replace writeup = subinstr(writeup, `"’"', `"'"', .)
		
		
		local keepvars "id countrycode case upi date time datetime toclearance topublish writeup"
		order `keepvars'
		keep `keepvars'
		
		noi peb_save `indic', datetime(`datetime') outdir("`outdir'")
	}
	
	*--------------------
	
	/*==================================================
	6. International line in LCU
	==================================================*/
	
	*--------------------
	if ("`indic'" == "plc") {  // Poverty line in Local Currency unite
		use "`outdir'\02.input/peb_pov.dta", clear
		destring year, replace
		collapse (max) year, by(countrycode)
		
		tempfile myear
		save `myear'
		
		qui datalibweb, country(Support) year(2005) surveyid(Support_2005_CPI_v02_M) /* 
		*/	filename("Final CPI PPP to be used.dta") type(GMDRAW) 
		
		local date: char _dta[note1]
		local date: subinstr local date "updated in" "", all
		local date: subinstr local date " " "", all
		
		local date = date("`date'", "DMY")
		local date: disp %tdmonDDCCYY `date'
		
		gen date = "`date'"
		gen time = "00:00:00"
		_gendatetime_var date time
		
		/* NOTE: we still need to add a condition for those countries
		with several data levels. */
		keep if datalevel == 2
		
		rename code countrycode
		
		merge 1:1 countrycode year using `myear', keep(match)
		
		local plines "1.9 3.2 5.5"
		foreach ll of loc plines{
			gen values`=100*`ll'' = `ll'*cpi2011*icp2011
		}
		
		peb_addregion
		
		keep region countrycode year date time datetime values*
		
		reshape long values, i(countrycode) j(case)
		
		
		tostring case year, replace force
		replace case = "ipl" if case == "190" 
		replace case = "lmi" if case == "320" 
		replace case = "umi" if case == "550" 
		
		gen indicator = "plc"
		gen id  = countrycode + year + indicator + case
		gen source = ""
		
		order id indicator region countrycode year source /* 
		*/   date time  datetime case values
		
		merge 1:1 id using "`outdir'\02.input/peb_`indic'_GD.dta", nogen /* 
		*/ update replace  
		noi peb_save `indic', datetime(`datetime') outdir("`outdir'")	
		
	} // end of international poverty line to Local currency unit
}

end


program define _gendatetime_var

args date time nothing

gen double d = date(`date', "MDY")
gen double t = clock(`time', "hms")

drop `date' `time'
rename (d t) (`date' `time')

format `date' %td
format `time' %tcHH:MM:SS

gen double datetime = `date'*24*60*60*1000 + `time'
format datetime %tcDDmonCCYY_HH:MM:SS


end

*-------------------- Generate time variables
program define _gendatetime
syntax , [date(string) time(string)]

if ("`date'" == "") local date = c(current_date)
if ("`time'" == "") local time = c(current_time)

gen double date = date("`date'", "DMY")
format date %td

gen double time = clock("`time'", "hms")
format time %tcHH:MM:SS

// I do it this way to understand the relation
gen double datetime = date*24*60*60*1000 + time  
format datetime %tcDDmonCCYY_HH:MM:SS

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


exit 
WDI fgt0_npl	tot_pop	gdp_pcap	gnp_pcap
reported fgt0_npl	gini	comparability	tot_pop





local indir  "//wbgfscifs01\gtsd\02.core_team\02.data\01.Indicators"
local outdir "//wbgfscifs01\GTSD\03.projects_corp\01.PEB\01.PEB_AM18\01.PEB_AM18_QA"
local ttldir "//gpvfile\GPV\Knowledge_Learning\PEB\02.tool_output\01.PovEcon_input"
local indic key
peb_exception load, outdir("`outdir'") ttldir("`ttldir'") /* 
*/ datetime(`datetime') indic("`indic'")



	/*==================================================
	
	==================================================*/
	
	*--------------------
	
	*--------------------
	
	/*==================================================
	
	==================================================*/
	
	*--------------------
	
	*--------------------
	
