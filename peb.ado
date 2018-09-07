/*==================================================
project:       Create and organize all the indicators for the PEB
Author:        Andres Castaneda 
Dependencies:  The World Bank
-----------------------------------------------------
Creation Date:    29 May 2018 - 12:05:37
Modification Date:   
Do-file version:    01
References:          
Output:             xlsx and dta
==================================================*/

/*==================================================
0: Program set up
==================================================*/
program define peb, rclass
version 13

syntax anything(name=indic id="indicator"), [ ///
indir(string)                  ///
outdir(string)                 ///
ttldir(string)                 ///
VCdate(string)                 ///
trace(string)                  ///
load  shpupdate   force        ///
GROUPdata   pause              ///
]


drop _all
gtsd check peb
if ("`pause'" == "pause") pause on
else                      pause off


qui {
	
	*------------------ SSC commands  ------------------
	local sscados "dirlist unique"
	foreach ado of local sscados {
		cap which `ado'
		if (_rc) ssc install `ado'
		local adoupdate "`adoupdate' `ado'"
	}
	
	if ("`adoupdate'" != "") 	{
		adoupdate `adoupdate', ssconly 		
		if ("`r(pkglist)'" != "") adoupdate `r(pkglist)', update
	}
	
	/*==================================================
	Consistency Check
	==================================================*/
	* Directory Paths
	if ("`indir'"  == "") local indir  "//wbgfscifs01\gtsd\02.core_team\02.data\01.Indicators"
	if ("`outdir'" == "") local outdir "//wbgfscifs01\GTSD\03.projects_corp\01.PEB\01.PEB_AM18\01.PEB_AM18_QA"
	if ("`ttldir'" == "") local ttldir "\\gpvfile\GPV\Knowledge_Learning\Global_Stats_Team\PEB\AM2018\02.tool_output\01.PovEcon_input"
	
	if regexm("`indir'", "(.*\\)([a-zA-Z0-9\.]+)$") /* 
  */	     local spdir = regexs(1)+"02.SharedProsperity"
	
	* vintage control
	if ("`vcdate'" == "" ) {
		local vconfirm "maxdate"
		local maxdate maxdate	
	}
	else {
		local vconfirm "vcdate"
		local maxdate ""
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
	*/ datetime(`datetime') indic("`indic'") `pause'
	
	
	/*==================================================
	Group data
	==================================================*/
	if ("`groupdata'" != "") {
		peb_groupdata `indic', outdir("`outdir'") ttldir("`ttldir'") /* 
		*/  indir("`indir'")  `pause'
		exit 
	}
	
	
	/*==================================================
	1: Basic indicators
	==================================================*/
	
	*---------1.1: clean the file
	if inlist("`indic'", "pov", "ine") {
		peb comparable, load `pause'
		tempfile comparafile
		save `comparafile'
		
		* use "`indir'\indicators_`indic'_long.dta", clear
		indicators `indic', load shape(long) `pause'
		
		* ---- Indicator-specific conditions
		
		* pov
		if ("`indic'" == "pov") {
			keep if fgt == 0
			rename line case
			tostring case, replace force
		}
		
		* T-1 for Eusilc data
		replace year = strofreal(real(year) -1) if (regexm(filename, "EU\-"))
		
		* Comparable years
		merge m:1 countrycode year welfarevar using `comparafile', /*  
		*/  keep(match) keepusing(comparable) nogen
		
		destring comparable, replace force
		
		pause `indic' - after merge with comparable
		*----- Organize data 
		destring year, force replace // convert to values
		
		noi peb_vcontrol, `maxdate' vcdate(`vcdate')
		local vcvar = "`r(`vconfirm')'" 
		keep if `vcvar' == 1
		
		*------- homogenize welfare type
		replace welftype = "CONS" if (region == "ECA" & !regexm(filename, "EU\-")) // not EU-SILC in ECA
		replace welftype = "INC"  if (regexm(filename, "EU\-"))  // EU-SILC
		replace welftype = "CONS" if (welftype != "INC")        
		replace welftype = "CONS" if regexm(welfarevar, "pcexp")
		replace welftype = "INC"  if regexm(welfarevar, "pcinc")
		replace welftype = "INC"  if region == "LAC" & !regexm(filename, "_PCN")
		
		
		
		*------- remove duplicates 
		* by module
		sort countrycode year case type welftype
		duplicates tag countrycode year case welftype type, gen(tag)
		pause `indic' - after creating tag of replicates 
		
		keep if (tag ==  0| (tag >= 1 & module == "ALL"))  // All prevails over GPWG 
		drop tag
		
		* by survey. 
		duplicates tag countrycode year case welftype, gen(tag)
		pause `indic' - after dropping replicates and create new tag
		
		// GPWG2 prevails over GMD
		keep if (tag ==  0| (tag >= 1 & type == "GPWG2") | countrycode == "MEX") 
		drop tag
		pause `indic' - after keeping (tag >= 1 & type == "GPWG2")
		
		qui unique welftype, by(countrycode) gen(ntype)
		sort countrycode ntype
		replace ntype = ntype[_n-1] if ntype == .
		
		replace case = case + "c" if (ntype == 2 & welftype == "CONS")
		
		
		pause `indic' - after creating case + "c"
		* Get rid of last year of other surveys different from EUSILC in ECA
		
		
		* ----- Create id for INDEX formula
		
		if ("`indic'" == "ine") {
			
			keep if case == "gini"
			replace values = value*100 if /* 
			*/  (mod(values, 10) > 0 & mod(values, 10) < 1 & case == "gini")				
			
		}
		drop if values == .
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
		pause pov - before merging group data
		
		merge 1:1 id using "`outdir'\02.input/peb_`indic'_GD.dta", nogen /* 
		*/ update replace  
		
		*----------Save file
		if (regexm("`trace'", "E|Ex")) set trace on
		peb_exception apply, outdir("`outdir'") `pause' // exceptions
		set trace off
		
		rename filename source 
		noi peb_save `indic', datetime(`datetime') outdir("`outdir'") `force' `pause'
		
	} // end of pov and ine
	
	
	/*==================================================
	2: Shared Prosperity
	==================================================*/
	*---------------2.1:
	if ("`indic'" == "shp") {
		
		if ("`shpupdate'" == "shpupdate") {
			peb_shpupdate, outdir("`outdir'") ttldir("`ttldir'")
		}
		
		*------------- Describe input file
		* local spdir \\wbgfscifs01\GTSD\02.core_team\02.data\02.SharedProsperity
		local shpfilename "`spdir'/GDSP circa 2010-2015_forPEB_AM2018.xlsx"
		pause shp - load GDSP circa 2010-2015
		dirlist "`shpfilename'"
		local ftimes = "`r(ftimes)'"
		local fdates = "`r(fdates)'"
		
		import excel using "`shpfilename'", describe
		local shtname1  = "`r(worksheet_1)'" 
    local shtname2  = "`r(worksheet_2)'" 
    
		local shtrange1 = "`r(range_1)'" 
    local shtrange2 = "`r(range_2)'" 
		
		local shtrange1: subinstr local shtrange1 "A1" "A6", all
		local shtrange2: subinstr local shtrange2 "A1" "A6", all
		
		
		*------------- Import Old sequence
		import excel using "`shpfilename'", clear case(lower) /* 
		*/            cellra("`shtrange2'") firstrow sheet("`shtname2'")
		
		destring _all, replace
		missings dropobs, force 
		
		sum sequence, meanonly
		local mexseq = r(max)
		tempfile oldseq
		save `oldseq'
		
		*------------- Import NEW sequence
		import excel using "`shpfilename'", clear case(lower) /* 
		*/            cellra("`shtrange1'") firstrow sheet("`shtname1'")
		
		destring _all, replace
		missings dropobs, force 
		
		gen sequence = `mexseq' + 1
		gen round = "AM2018"
		gen circayear = "2010-2015"
		
		append using `oldseq'
		
		* ---------- Arrange data
		
		*date and time
		gen double date = date("`fdates'", "MDY")
		format date %td

		gen double time = clock("`ftimes'", "hm")
		format time %tcHH:MM:SS

		gen double datetime = date*24*60*60*1000 + time  // I do it this way to understand the relation
		format datetime %tcDDmonCCYY_HH:MM:SS

		rename code countrycode
		
		*Max sequence
		bysort countrycode (sequence): egen maxseq = max(sequence)
		keep if sequence == maxseq
		
		*ShP premium
		cap gen double premium=growthb40-growthtotal
		
		** In PEB AM2018 "master" worksheet format	
		rename (premium growthb40 growthtotal) (pre b40 tot)
		rename (pre b40 tot) values=

		reshape long values, i(region countrycode period date time) j(case) string 
		replace values = values/100
		
		gen indicator="shp"
		gen id=countrycode+indicator+case
		ren period year
		gen source=""
		gen comparable = . 
		
		compress
		
		* Save data
		pause shp - before saving 
		noi peb_save `indic', datetime(`datetime') outdir("`outdir'") `force' `pause'
		
	}
	
	/*==================================================
	3: National Poverty numbers
	==================================================*/
	
	if ("`indic'" == "npl") {
		
		*-------------------- Data from TTL
		* use "`outdir'/02.input/peb_nplupdate.dta", clear
		
		peb nplupdate, load `pause'
		* fix dates
		_gendatetime_var date time
		
		pause npl - right after loading data 
		
		* include Population provided by the TTL
		merge m:1 countrycode using "`outdir'/02.input/peb_exceptions.dta", /*  
		*/ nogen keep(master match) keepusing(ex_nu_poor_npl ex_spell_pov_ine)
		
		* Rename variables to be reshaped 
		rename (population line gini) values=		
		rename ex_* values*
		
		reshape long values, i(countrycode year datetime) j(case) string
		
		replace case = "popu" if case == "population"
		replace case = "pttl" if case == "nu_poor_npl"
		destring values, replace force
		
		pause `indic' - before droping variables
		
		keep countrycode year datetime date time case values source
		gen indicator = "npl"
		
		pause npl- before keepting max date
		
		bysort countrycode year /*  case */ : egen double maxdate = max(datetime)
		replace maxdate = cond(maxdate == datetime, 1, 0)
		
		* drop if inlist(values, 0, .)  // if TTL didn't provide info
		keep if maxdate == 1
		
		pause npl- after keeping max date
		
		gen id = countrycode + year + indicator + case
		
		order id indicator countrycode year source /* 
		*/   date time  datetime case values
		
		gen ttl = 1
		drop if date == .
		tempfile ttlfile
		save `ttlfile'
		
		pause npl- after saving ttlfile
		
		*-------------------- Data from WDI
		* use "`indir'\indicators_wdi_long.dta", clear
		indicators wdi, load shape(long) `pause'
		* keep if inlist(case, "si_pov_nahc","sp_pop_totl", "ny_gdp_pcap_pp_kd","ny_gnp_pcap_kd")
		keep if inlist(case, "sp_pop_totl","ny_gdp_pcap_pp_kd","ny_gnp_pcap_kd")
		
		replace countrycode="KSV" if countrycode=="XKX"
		
		* replace case = "line"  if case == "si_pov_nahc" 
		replace case = "popu"  if case == "sp_pop_totl" 
		replace case = "gdppc" if case == "ny_gdp_pcap_pp_kd" 
		replace case = "gnppc" if case == "ny_gnp_pcap_kd" 
		
		pause after loading wdi information
		
		noi peb_vcontrol, `maxdate' vcdate(`vcdate')
		local vcvar = "`r(`vconfirm')'" 
		keep if `vcvar' == 1
		drop region
		rename regioncode region 
		drop  vc_13jun2018 iso2code 
		
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
		keep if (tag == 0    | /* 
		*/      (tag >0 & ttl == 1 & inlist(case, "line", "gini")) |  /* 
		*/      (tag >0 & case == "popu" & values != .)) 
		drop tag 
		
		duplicates tag id, gen(tag)
		keep if (tag == 0 | tag >0 & ttl == 1)
		drop tag 
		
		/* duplicates tag id, gen(tag)
		keep if (tag == 0  | (tag >0 & ttl == 1 & case == "popu" & values == .) )
	 */	
	
	pause after droping duplicates 
		
		* Fix Gini to go from 0 to 1
		
		replace values = value*100 if /* 
		*/  (mod(values, 10) > 0 & mod(values, 10) < 1 & case == "gini")
		
		replace values = value/100 if /* 
		*/  (mod(values, 1000) < values & case == "gini")
		
		
		drop if values == .
		
		order id indicator countrycode year source /* 
		*/   date time  datetime case values
		
		keep id indicator countrycode year source /* 
		*/   date time  datetime case values
		
		pause npl - Right before saving
		noi peb_save `indic', datetime(`datetime') outdir("`outdir'") `force' `pause'
		
		
	} // End of National POverty lines and Macro indicators. 
	
	/*==================================================
	4: Key Indicators
	==================================================*/
	
	*--------------------
	if ("`indic'" == "key") {
		* use "`outdir'/02.input/peb_keyupdate.dta", clear
		tempfile shpfile
		qui peb shpupdate, load `pause'
		save `shpfile'
		
		qui peb keyupdate, load `pause'
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
		pause key - before preserve
		preserve 
		keep if regexm(indicator, "^Poverty line") 
		gen line2disp = cond(regexm(publish, "^[Uu]p"), 550,  /* 
		*/              cond(regexm(publish, "^[Ll]o"), 320, 190)) 
		keep countrycode line2disp
		tempfile lined
		save `lined'
		pause key - before restore
		restore
		
		merge  m:1 countrycode using `lined', nogen
		pause key - after merge with lined
		
		drop if regexm(indicator, "^Poverty line") 
		
		
		* Save temporal file
		tempfile keyu
		save `keyu', replace
		pause key - after saving keyu
		
		* Load indicators file
		* use "`indir'\indicators_`indic'_wide.dta", clear
		indicators key, load shape(wide) `pause'
		
		* T-1 for Eusilc data
		replace year = strofreal(real(year) -1) if (regexm(filename, "EU\-"))
		
		pause key - before applying exceptions
		peb_exception apply, outdir("`outdir'") `pause'	indic(`indic')
		pause key - after applying exceptions
		
		destring year, force replace // convert to values
		noi peb_vcontrol, `maxdate' vcdate(`vcdate')
		local vcvar = "`r(`vconfirm')'" 
		keep if `vcvar' == 1
		keep if welfarevar == "welfare"
		
		* Max year per country
		
		
		pause key - before keeping max year per country
		tempvar myear
		bysort countrycode: egen double `myear' = max(year)
		keep if year == `myear' 
		tostring year, replace force
		
		* Filter by survey in case there is more than one
		merge m:1 countrycode using `shpfile', /* 
		*/	nogen keepusing(surveyname) keep(master match)
		pause key - after merging shpupdate file 
		
		duplicates tag countrycode precase, gen(tag)
		keep if ((survname == surveyname & tag >0) |tag == 0)
		drop tag
		
		* Merge with Exceptions
		merge 1:1 countrycode precase using `keyu', /* 
		*/	keepusing(publish line2disp) keep(master match) nogen
		
		pause key - after merging temp keyu
		* clean data 
		replace line2disp = 190 if line2disp == . 
		replace publish = "YES" if publish == ""
		
		
		reshape long values, i(countrycode  precase) /* 
		*/     j(case) string
		
		pause key - Before dropping observations.
		* keep if (regexm(case, "^[BT]") | real(substr(case, 1,3)) == line2disp)
		
		
		* Organize before save
		
		gen indicator = "key"
		rename filename source
		
		/* 
		gen id = cond(regexm(case, "^[BT]"), /* 
	  */	          countrycode + indicator + precase + case, /* 
		*/            countrycode + indicator + precase + substr(case, 4,.))
		*/
		
		gen id = countrycode + indicator + precase + case 
		
		replace case = precase + case
		
		order id indicator countrycode year source /* 
		*/   date time  datetime case values
		
		keep id indicator countrycode year source /* 
		*/   date time  datetime case values
		
		
		merge 1:1 id using "`outdir'\02.input/peb_`indic'_GD.dta", nogen /* 
		*/ update replace  
		
		pause key - right before saving 
		noi peb_save `indic', datetime(`datetime') outdir("`outdir'") `force'  `pause'
		
	}
	
	*--------------------
	
	/*==================================================
	5. Write ups
	==================================================*/
	
	*--------------------
	if ("`indic'" == "wup") {
		* use "`outdir'/02.input/peb_writeupupdate.dta", clear
		
		peb writeupupdate, load `pause'
		missings dropvars, force
		_gendatetime_var date time
		
		* max date per country
		tempvar mdatetime
		bysort countrycode: egen double `mdatetime' = max(datetime)
		keep if datetime == `mdatetime' 
		drop `mdatetime' 
		
		destring cleared, replace force
		
		rename (keyfindings  nationaldata) writeup=
		reshape long writeup, i(countrycode) j(case) string
		
		gen id = countrycode + substr(case, 1, 4)
		
		
		replace writeup = subinstr(writeup, `"“"', `"""', .)
		replace writeup = subinstr(writeup, `"”"', `"""', .)
		replace writeup = subinstr(writeup, `"’"', `"'"', .)
		
		gen toclearance = "0"
		gen topublish   = "0"
		
		
		pause wup - before keeping final variables
		
		local keepvars id countrycode case upi date time datetime /* 
		*/ cleared writeup toclearance topublish
		order `keepvars'
		keep `keepvars'
		
		pause wup - before saving 
		noi peb_save `indic', datetime(`datetime') outdir("`outdir'") `force'  `pause'
	}
	
	*--------------------
	
	/*==================================================
	6. International line in LCU
	==================================================*/
	
	*--------------------
	if ("`indic'" == "plc") {  // Poverty line in Local Currency unite
		
		qui datalibweb, country(Support) year(2005) type(GMDRAW) fileserver /* 
	 */	surveyid(Support_2005_CPI_v02_M) filename(Final_CPI_PPP_to_be_used.dta) 
		
		local date: char _dta[note1]
		local date: subinstr local date "updated in" "", all
		local date: subinstr local date " " "", all
		
		local date = date("`date'", "DMY")
		local date: disp %tdmonDDCCYY `date'
		
		gen date = "`date'"
		gen time = "00:00:00"
		_gendatetime_var date time
		
		recode datalevel (0 1 = 1) (2 = 2), gen(dlevel)
		
		rename code countrycode
		
		local plines "1.9 3.2 5.5"
		foreach ll of loc plines{
			gen values`=100*`ll'' = `ll'*cpi2011*icp2011
		}
		
		peb_addregion
		
		pause plc - before reshape
		
		keep region countrycode year date time datetime datalevel values*
		reshape long values, i(countrycode year datalevel) j(case)
		
		* when urban and rural ppp values exist, we get the mean. 
		recode datalevel (0 1 = 1) (2 = 2), gen(dlevel)
		
		collapse (mean) values, by(region countrycode year datetime date time dlevel case)
		
		pause plc - after reshape
		
		tostring case year, replace force
		replace case = "ipl" if case == "190" 
		replace case = "lmi" if case == "320" 
		replace case = "umi" if case == "550" 
		
		gen indicator = "plc"
		gen id  = countrycode + year + indicator + case
		gen source = ""
		
		order id indicator region countrycode year source /* 
		*/   date time  datetime case values
		
		keep id indicator region countrycode year source /* 
		*/   date time  datetime case values
		
		merge 1:1 id using "`outdir'\02.input/peb_`indic'_GD.dta", nogen /* 
		*/ update replace  
		
		noi peb_save `indic', datetime(`datetime') outdir("`outdir'")	 `force'  `pause'
		
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
Shared Prosperity using data from indicators.ado
==================================================*/
* use "`indir'\indicators_`indic'_long.dta", clear
indicators `indic', load shape(long) `pause'

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

*--------------------

***********************************************************
*NOTE: This SHP section is provided by Pepe Montes
***********************************************************

pause shp - load GDSP circa 2010-2015
dirlist "`spdir'\GDSP circa 2010-2015.xlsx"
local ftimes = "`r(ftimes)'"
local fdates = "`r(fdates)'"

import excel using "`spdir'/GDSP circa 2010-2015.xlsx", clear /* 
*/                 cellra("A6:N97") first sheet("GPSP 2010-2015") 

destring _all, replace
missings dropobs, force 

ren _all, lower
ren countryname country

keep	region code country period type growthb40 growthtotal
order	region code country period type growthb40 growthtotal
for var region code country period type growthb40 growthtotal \ any A B C D E F G : ren X Y
isid B
tempfile _11
save `_11'

pause shp - load Draft SP SM2018@3.xlsx
import excel using "`spdir'/Draft SP SM2018@3.xlsx", clear cellra("A1:H128") first
replace SPSM2018="Yes" if code=="TUN" | code=="TZA"
keep if trim(SPSM2018)=="Yes"
gen country=""
keep	region code country period type growthb40 growthtotal
order	region code country period type growthb40 growthtotal
for var region code country period type growthb40 growthtotal \ any A B C D E F G : ren X Y
isid B
tempfile _10
save `_10'

pause shp - load GDSP circa 2009-14 (Nov 28 2017).xlsx
import excel using "`spdir'/GDSP circa 2009-14 (Nov 28 2017).xlsx", clear cellra("A6:G100")
isid B
tempfile _9
save `_9'
pause shp - load GDSP circa 2008-13 (08_10_16_UPDATE v2).xlsx
import excel using "`spdir'/GDSP circa 2008-13 (08_10_16_UPDATE v2).xlsx", clear cellra("A6:G88")
for var F G : replace X=X*100
isid B
tempfile _8
save `_8'

pause shp - load GDSP circa 2007-12 (10_19_15_UPDATE) FY15.xls
import excel using "`spdir'/GDSP circa 2007-12 (10_19_15_UPDATE) FY15.xls", clear cellra("A6:G99")
replace A="EAP" if A=="East Asia & Pacific"
replace A="ECA" if A=="Europe & Central Asia"
replace A="LAC" if A=="Latin America & Caribbean"
replace A="MNA" if A=="Middle East & North Africa"
replace A="SAR" if A=="South Asia"
replace A="SSA" if A=="Sub-Saharan Africa"

for var F G : replace X=X*100
isid B
tempfile _7
save `_7'

pause shp - load GDSP circa 2006-2011_Final FY14.xlsx
import excel using "`spdir'/GDSP circa 2006-2011_Final FY14.xlsx", clear cellra("A7:G78") sh("GDSP_Pp")	//faltan 3 digits code
replace A="EAP" if A=="East Asia & Pacific"
replace A="ECA" if A=="Europe & Central Asia"
replace A="LAC" if A=="Latin America & Caribbean"
replace A="MNA" if A=="Middle East & North Africa"
replace A="SAR" if A=="South Asia"
replace A="SSA" if A=="Sub-Saharan Africa"

pause shp - merge all ShP temporal files
merge 1:1 B using `_7' , update replace gen(_me67)
merge 1:1 B using `_8' , update replace gen(_me678)
merge 1:1 B using `_9' , update replace gen(_me6789)
merge 1:1 B using `_10', update replace gen(_me67890)
merge 1:1 B using `_11', update replace gen(_me678901)
ren A region_sp
ren B code
ren D period
ren F growthb40
ren G growthtotal

*import exc using "${SP_final}", sheet(updatedb40) clear first

pause shp - fix data
isid code
*gsort -gr_b40_3
gsort -growthb40
ren _all, lower
cap clonevar code=wbcode
isid code							// making sure there is only one spell per country

gen year0 = substr(period,1,4)
gen year1 = substr(period,-4,4)
drop if year1 == year0 				// exclude countries without SP spell
drop if mi(growthb40)

levelsof code, local(spnats)		// countries with sp data 
foreach c of local spnats {
	qui levelsof year0 if code=="`c'", local(`c'_t0) clean
	qui levelsof year1 if code=="`c'", local(`c'_t1) clean
	di in yellow "`c':``c'_t0':``c'_t1'"
}

* add top10 and top60 for the future 
cap gen double sp_premium=growthb40-growthtotal
cap clonevar region_sp=region
*for var growth* sp_premium : replace X=X*1
keep	region_sp code period sp_premium growthb40 growthtotal
order	region_sp code period sp_premium growthb40 growthtotal


***This part needs to be checked in the exceptions file START
count
loc g=r(N)+1
set obs `g'
replace region_sp="SSA" in `g' //
replace code="ZWE" in `g'
replace period="2011-2017" in `g'
***This part needs to be checked in the exceptions file END

keep if !mi(code)
pause shp - gen date and time

gen double date = date("`fdates'", "MDY")
format date %td

gen double time = clock("`ftimes'", "hm")
format time %tcHH:MM:SS

// I do it this way to understand the relation
gen double datetime = date*24*60*60*1000 + time  
format datetime %tcDDmonCCYY_HH:MM:SS

*tostring region_sp-growthtotal, replace force

**********************************************************************	
** In PEB AM2018 "master" worksheet format	
rename (sp_premium growthb40 growthtotal) (pre b40 tot)
rename (pre b40 tot) values=

reshape long values, i(region_sp code period date time) j(case) s 
*destring _all, replace

gen indicator="shp"
ren code countrycode
gen id=countrycode+indicator+case
ren region_sp region
ren period year
gen source=""
gen comparable = . 

format values %15.10f
replace values=values/100

local v2keep id region countrycode year source date time /* 
*/   datetime case values indicator comparable
order `v2keep'
keep `v2keep'
compress




*--------------------

/*==================================================

==================================================*/

*--------------------

*--------------------

