/*==================================================
project:       Import and Export group data info for the PEB
Author:        Andres Castaneda 
Dependencies:  The World Bank
----------------------------------------------------
Creation Date:    27 Jun 2018 - 14:19:26
Modification Date:   
Do-file version:    01
References:          
Output:             dta and csv file
==================================================*/

/*==================================================
0: Program set up
==================================================*/
program define peb_groupdata, rclass
version 13

syntax anything(name=indic id="indicator"), [ ///
CALCulate                      ///
indir(string)                  ///
outdir(string)                 ///
ttldir(string)                 ///
pause force                    ///
]


if ("`pause'" != "") pause on 
else                 pause off

local auxdir "`outdir'\_aux"

local infile "PEB_templateGroupData.xlsm"

local gd_file "`auxdir'/`infile'"
local gd_file: subinstr local gd_file "/" "\", all
/*==================================================
Load data from template
==================================================*/

*---------- Select version and load
/* 
if ("`tver'" == "" ) {
	local allvers: dir "`auxdir'" files "PEB_template@*.xlsm"
	mata {
		Vs = tokens(st_local("allvers"))
		Vs = regexr(regexr(Vs, "peb_template@", ""), "\.xlsm", "")
		st_local("tver", strofreal(max(strtoreal(Vs))))
	}
}
*/
 
local sheets welfaretype_all


local countries "CHN ZWE MKD IND SSD LCA" /* CPV is exclude since SM2019*/
local countries_: subinstr local countries " " "|", all


/*==================================================
Pov line in LCU
==================================================*/
qui{
if ("`indic'" == "plc") {
	
	local sheet Overview_all
	
	import excel using "`auxdir'/`infile'", sheet("`sheet'") /* 
	*/ firstrow case(lower) clear
	
	missings dropobs, force
	missings dropvars, force
	
	rename code countrycode
	
	keep if regexm(countrycode, "`countries_'")
	split concatenate, gen(c) parse(_)
	drop year
	
	rename c2 year
	tempvar myear
	bysort countrycode: egen double `myear' = max(real(year)) 
	keep if `myear' == real(year)
	
	keep region countrycode year *_lcu 
	local date = date("27mar2018", "DMY")
	local date: disp %tdmonDDCCYY `date'
	gen date = "`date'"
	gen time = "00:00:00"
	_gendatetime_var date time
	
	rename (*_lcu) values=
	reshape long values, i(countrycode year) j(case) string
	replace case = subinstr(case, "_lcu", "", .)
	replace case = subinstr(case, "cl", "", .)
	
	gen indicator = "plc"
	gen source = "Group Data"
	gen id = countrycode + year + indicator + case
	
	order id indicator region countrycode year source /* 
	*/   date time  datetime case values
	
}

/*==================================================
Poverty
==================================================*/

if ("`indic'" == "pov") {
	local sheet Poverty_all
	
	import excel using "`auxdir'/`infile'", sheet("`sheet'") /* 
	*/ firstrow case(lower) clear
	
	missings dropobs, force
	missings dropvars, force
	
	rename code countrycode
	keep if regexm(countrycode, "`countries_'")
	
	gen double d = date(date, "DMY")
	gen double t = clock(time, "hms")
	
	drop date time
	rename (d t) (date time)
	
	format date %td
	format time %tcHH:MM:SS
	
	gen double datetime = date*24*60*60*1000 + time
	format datetime %tcDDmonCCYY_HH:MM:SS
	
	rename (fgt0_*) (values*)
	reshape long values, i(countrycode year) j(case) string
	peb_addregion
	
	
	gen indicator = "`indic'"
	gen filename = "Group Data"
	
	tostring year, replace force
	gen id = countrycode + year + indicator + case
	
	keep id indicator region countrycode year filename case /* 
	*/  date time datetime values comparable
	
	order id indicator region countrycode year filename /* 
	*/   date time  datetime case values comparable
	
}


/*==================================================
Inequality
==================================================*/

if ("`indic'" == "ine") {
	local sheet Inequality_all
	
	import excel using "`auxdir'/`infile'", sheet("`sheet'") /* 
	*/ firstrow case(lower) clear
	
	missings dropobs, force
	missings dropvars, force
	
	rename code countrycode
	keep if regexm(countrycode, "`countries_'")
	
	gsort countrycode -date -time
	local date = date[1]
	local time = time[1]
	
	replace time = "`time'" if time == ""
	replace date = "`date'" if date == ""
	
	
	gen double d = date(date, "DMY")
	gen double t = clock(time, "hms")
	
	drop date time
	rename (d t) (date time)
	
	format date %td
	format time %tcHH:MM:SS
	
	gen double datetime = date*24*60*60*1000 + time
	format datetime %tcDDmonCCYY_HH:MM:SS
	
	rename gini values
	
	gen indicator = "`indic'"
	gen filename = "Group Data"
	gen case = "gini"
	
	peb_addregion
	
	tostring year, replace force
	gen id = countrycode + year + indicator + case
	
	keep id indicator region countrycode year filename case /* 
	*/  date time datetime values comparable
	
	order id indicator region countrycode year filename /* 
	*/   date time  datetime case values comparable
}

/*==================================================
Shared Prosperity
==================================================*/

if ("`indic'" == "shp") {
	local sheet Shared_Prosperity_all
	
	import excel using "`auxdir'/`infile'", sheet("`sheet'") /* 
	*/ firstrow case(lower) clear
	
	missings dropobs, force
	missings dropvars, force
	
	format date %td
	format time %tcHH:MM:SS
	
	gen double datetime = date*24*60*60*1000 + time
	format datetime %tcDDmonCCYY_HH:MM:SS
	
	rename code countrycode
	keep if regexm(countrycode, "`countries_'")
	
	drop region
	peb_addregion
	
	rename (sp_premium growthb40  growthtotal) values=
	destring values*, replace force
	reshape long values, i(countrycode period) j(case) string
	
	rename period year
	replace case = "b40" if case == "growthb40"
	replace case = "tot" if case == "growthtotal"
	replace case = "pre" if case == "sp_premium"
	
	gen indicator = "shp"
	gen source  = "Group Data"
	gen id = countrycode + indicator + case
	
	keep id indicator region countrycode year source case /* 
	*/  date time datetime values
	
	
	order id indicator region countrycode year source /* 
	*/   date time  datetime case values
	
}

/*==================================================
Key Indicators
==================================================*/

if ("`indic'" == "key") {
	
	local sheet Key_indicators_all
	
	import excel using "`auxdir'/`infile'", sheet("`sheet'") /* 
	*/ firstrow case(lower) clear
	
	missings dropobs, force
	missings dropvars, force
	
	rename code countrycode
	keep if regexm(countrycode, "`countries_'")
	
	gsort countrycode -date -time
	local date = date[1]
	local time = time[1]
	
	replace time = "`time'" if time == ""
	replace date = "`date'" if date == ""
	
	
	gen double d = date(date, "DMY")
	gen double t = clock(time, "hms")
	
	drop date time
	rename (d t) (date time)
	
	format date %td
	format time %tcHH:MM:SS
	
	gen double datetime = date*24*60*60*1000 + time
	format datetime %tcDDmonCCYY_HH:MM:SS
	
	cap drop _all__1 concate 
	rename b40 t60 , upper
	rename (B40 T60) poor=zz
	
	tempvar myear
	destring year, replace force
	bysort countrycode: egen double `myear' = max(year)
	keep if year == `myear' 
	tostring year, replace force
	
	reshape long poor, i(countrycode year _varname) j(case) string
	rename (poor _varname) (values precase)
	
	
	replace precase = subinstr(precase, "educa", "edu", .)
	replace precase = subinstr(precase, "gage", "gag", .)
	replace precase = subinstr(precase, "rural", "rur2", .)
	replace precase = subinstr(precase, "urban", "rur1", .)
	replace precase = subinstr(precase, "ggender1", "gen1", .)
	replace precase = subinstr(precase, "ggender", "gen2", .)
	
	replace case = subinstr(case, "nonpoor", "np", .)
	replace case = subinstr(case, "poor", "pz", .)
	replace case = subinstr(case, "_", "", .)
	replace case = subinstr(case, "z", "_", .)
	
	gen indicator = "key"
	gen source = "Group Data"
	
	pause group data key - Before creating variable id
	
	/* 
	gen id = cond(regexm(case, "^[BT]"), /* 
	*/	          countrycode + indicator + precase + case, /* 
	*/            countrycode + indicator + precase + substr(case, 4,.))
	*/
	gen id = countrycode + indicator + precase + case, 
	
	replace case = precase+case
	tostring year, replace force
	
	order id indicator countrycode year source /* 
	*/   date time  datetime case values
	
	keep id indicator countrycode year source /* 
	*/   date time  datetime case values
	
	* keep if regexm(case,"B|T|190")
}
/*==================================================
Add characteristics
==================================================*/

**** indicators ****
tempfile dirlist
local shellcmd `"dir `gd_file'>`dirlist'"'
quietly shell `shellcmd'

tempname fh		
file open `fh' using "`dirlist'", text read
file read `fh' line
	
while r(eof)==0  {
	
	if `"`line'"' ~= "" & substr(`"`line'"',1,1) ~= " " {
		local fdates : word 1 of `line'
		local ftimes : word 2 of `line'
	}
	file read `fh' line	
}
file close `fh'

local ind_date = date("`fdates'", "MDY")  
local ind_time = clock("`ftimes'", "hm")  
local ind_datetime = `ind_date'*24*60*60*1000 + `ind_time' 
local ind_datetimeHRF: disp %tcDDmonCCYY_HH:MM:SS `ind_datetime' 
local ind_datetimeHRF = trim("`ind_datetimeHRF'")
datasignature set, reset
	
char _dta[ind_`indic'_GD_calcset]        "`indic'_GD" 
char _dta[ind_`indic'_GD_datetimeHRF]    "`ind_datetimeHRF'" 
char _dta[ind_`indic'_GD_user]           "Minh" 
char _dta[ind_`indic'_GD_datasignature_si] "`_dta[datasignature_si]'" 

}
/*==================================================
Save and execute general calculations
==================================================*/
save "`outdir'\02.input/peb_`indic'_GD.dta", replace
*save "`outdir'\02.input/_vintage/peb_`indic'_`datetime'.dta"
noi disp in y "file peb_`indic'_GD.dta has been updated" _n
*}
*else{
* noi disp in y "The groupdata is not updated" _n
*}
global groupdata = 1
noi peb `indic',`force'
end

*-------------------- Generate time variables

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
