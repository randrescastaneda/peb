{smcl}
{* *! version 1.0 23 May 2018}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Install gtsd" "ssc install gtsd"}{...}
{vieweralsosee "Help gtsd (if installed)" "help gtsd"}{...}
{vieweralsosee "Install dirstr" "ssc install dirstr"}{...}
{vieweralsosee "Help dirstr (if installed)" "help dirstr"}{...}
{vieweralsosee "Install datalibweb" "ssc install datalibweb"}{...}
{vieweralsosee "Help datalibweb (if installed)" "help datalibweb"}{...}
{vieweralsosee "Install primus" "ssc install primus"}{...}
{vieweralsosee "Help primus (if installed)" "help primus"}{...}
{viewerjumpto "Syntax" "peb##syntax"}{...}
{viewerjumpto "Description" "peb##description"}{...}
{viewerjumpto "Options" "peb##options"}{...}
{viewerjumpto "Remarks" "peb##remarks"}{...}
{viewerjumpto "Examples" "peb##examples"}{...}
{title:Title}
{phang}
{bf:peb} {hline 2} {err: help file in progress}

{marker syntax}{...} 
{title:Syntax}
{p 8 17 2}
{cmdab:peb}
{it:indicator}
[{cmd:,}
{it:options}] 

{pstd}
Where {it:indicator} refers to the shorthand of the file to be included in the PEB output. Hola

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt group:data}} Organizes and exports data from group data surveys. When no selected, 
{cmd:peb} organizes and exports data from microdata{p_end}
{synopt:{opt load}} Load the corresponding file to {it:indicator}. It does not organizes 
neither exports data.{p_end}
{synopt:{opt force}} Force {cmd:peb} to save data even if its data signature is 
the same as the previous one.{p_end}

{syntab:Debugging}
{synopt:{opt trace(indicator)}} Set trace on in the section of the process where 
{it:indicator} is executed.{p_end}
{synopt:{opt pause}}  Activate strategic pause points along the indicators files 
for debugging purposes. See {help pause}{p_end}

{syntab:Auxiliary}
{synopt:{opt povcalnet}} Creates files to share with PovcalNet team. Requires 
{it:indicator}. For now, it only works for indicator {it:npl}{p_end}

{syntab:Advanced}
{synopt:{opt vc:date(string)}} Vintage control date of input file from pre-calculated 
indicators. see {help indicators##vc_vars:indicators}{p_end}
{synopt:{opt shpupdate}} update shared prosperity spell from Excel file provided by 
Minh that has been completed by regional focal points. Only works within instruction 
{it:shp}{p_end}
{syntab:Purge}
{synopt:{opt purge}} purges the indicators files and the master file of the 
information of a particualr country. Must be used with option {it:country()} {p_end}
{synopt:{opt count:ry(string)}} country to be purged from final files. Use with 
option {it: purge} {p_end}
{synopt:{opt update}} Executes the creation of the PEB file after it was been purged. 
Only works with option {it:purge} {p_end}
{synopt:{opt restore}} Restore a particular version of any file.{p_end}

{syntab:Directories}
{synopt:{opt indir(string)}} Alternative directory to indicators input{p_end}
{synopt:{opt outdir(string)}} Alternative directory to PEB folder. Modify directly in 
the ado-file when a new round of the PEB comes in time.{p_end}
{synopt:{opt ttldir(string)}} Alternative directory to Exceptions database. This 
does not need to change from one round to the other.{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}
{cmd:peb} is a Stata package that organizes and exports the inputs of the PEB Excel tool. 
It uses as input two types of data. [1] First, it uses a database of pre-calculated 
socioeconomic indicators created with the Stata package {help indicators}. This database 
includes the estimates for poverty, inequality, shared prosperity, key indicators, and 
some indicators from WDI. [2] Second, {cmd:peb} uses a database of Excel files that have 
been previously created and constantly updated with the information provided by the 
Poverty economist throughout the PEB tool and by the GTSD with the information provided 
by regional focal points or poverty economist via email. This second set of data is used 
within {cmd:peb} to filter the information in the database of pre-calculated indicators. 
For a better understanding of the PEB process, please refer to the this 
{browse "\\wbgfscifs01\gtsd\03.projects_corp\01.PEB\01.PEB_AM18\01.PEB_AM18_QA\_aux\PEBTechnicalWorkflow.pdf":flowchart}.

{marker indicators}{...}
{title:Indicators}
{pstd}
{it:indicator} is a shorthand for a set of common calculations that should be included 
in the PEB layout. So far, the indicators available are 

		Indicator{col 35}Set of calculations
		{hline 45}
		{cmd:pov }{col 35}Poverty rates
		{cmd:ine }{col 35}Inequality indicators
		{cmd:shp }{col 35}Shared Prosperity
		{cmd:key }{col 35}Key Indicators
		{cmd:npl }{col 35}National numbers
		{cmd:wup }{col 35}Write-ups
		{hline 45}

{marker exceptions}{...}
{title:Exceptions files}
{pstd}
The exceptions files are used by {cmd:peb} to filter the data produced by {help indicators}. 
The first three files listed below are directly modified by the Excel Tool, whereas 
the other files must be modified by the GTSD manually in case the Poverty Economist 
or the regional focal point asks to do so. This is in fact the reason of this section. 
To explain how each file is created and how to modify it. Keep in mind that as of today 
(17jul2018) these files are placed in 
{browse "\\gpvfile\GPV\Knowledge_Learning\PEB\02.tool_output\01.PovEcon_input\":this folder}.

{phang}
{bf:writeupupdate.xlsx} contains the historical submission of write-ups by the Poverty 
Economists. It stores the name of the person who made the submission as well as the 
date and time. The two main variables are 'keyFindings' and 'nationaldata'. The former 
refers to the economic analysis of the Poverty Economist, whereas the latter 
refers to the technical particularities of the data of each country. 
Do {err:not} manipulate this file as you may mess up the {cmd:peb} system. 

{phang}
{bf:nplupdate.xlsx} contains national numbers. the 'npl' acronym refers to 'national 
poverty line' but the file actually contain gini and population as well. This file is 
updated through the tool directly, so do {err:not} manipulate this file as you 
may mess up the {cmd:peb} system. 

{phang}
{bf:keyupdate.xlsx} contains a series of exceptions for the Key Indicators table. 
Variable 'publish' is either YES or NO to signalize whether that particular indicator 
should be published in the final version. Do {err:not} manipulate this file as you 
may mess up the {cmd:peb} system. 

{phang}
{bf:exceptions.xlsx} contains two types of information, [1] spell of survey/years to 
be {ul:included} in the calculations, and [2] a series of indicators to be 
{ul:excluded} from the published version. Each observation of the file corresponds to 
a country and it hast to be modified manually in the following way. [1] The spell of the 
survey/year should be included as a Stata {help numlist}. [2] The indicators, which 
are listed below, are excluded by entering a 1 in the corresponding cell. 

		Variable name{col 35}Definition
		{hline 50}
		{cmd:ex_fgt0_190}{col 35} pov. at $1.9
		{cmd:ex_fgt0_190C}{col 35} pov. at $1.9 using consumption
		{cmd:ex_fgt0_320}{col 35} pov. at $3.2
		{cmd:ex_fgt0_550}{col 35} pov. at $5.5
		{cmd:ex_gini}{col 35} Gini
		{cmd:ex_country}{col 35} Country
		{hline 50}

{pmore} There are two additional variables, {cmd:ex_GDP_Growth_years} and 
{cmd:ex_Nu_poor_NPL} that refer to the spell of years of the GDP and the poor population
of the country for the year to be included in the overview table. The former must be 
included as a Stata {help numlist}, whereas the former is a real number {it:in millions}. 
For instance, the number of poor in China in millions would have to be entered as 30.46.

{phang}
{bf:shpupdate.xlsx} has three types of important information. [1] the shared prosperity period 
(or survey spell), which can be modified in variables 'yeart0' and 'yeart1'. [2] The 
GMD welfare variable that has to be used in the each year of the spell. It can be modified in 
variables 'welfaret0' and 'welfaret1'. In general, the GMD variable used is 'welfare' 
but some countries use variable 'welfareshprosperity'. [3] Finally, the level of 
aggregation of the data can be changed as well in variables 'levelt0' and 'levelt1'. 
these variables can take only the values of 'HH' for household level data and 'IND' for
individual level data. 

{phang}
{bf:comparable.xlsx} contains the time comparability of poverty rates in each country. 
the variable 'comparable' takes integer values starting from zero (0), which is the first 
series of survey/years with comparable poverty rates starting chronologically. When the 
series is broken, the next comparable series will be identified with 1, the following 
series with a 2, and so on and so forth. If there is no data available for a particular year, 
the value of the 'comparable' variable is "", i.e., string missing value (do not confused with 
numerical missing represented by a period '.').

{phang}
{bf:countriesin.xlsx} contains several pieces of information by country. [1] Name of the 
as they will be presented in the final layout. [2] Name of the countries as they are 
organized alphabetically. [3] Name of the countries in upper casses. [4] Name of the 
corresponding poverty economist. [5] A column to identify whether or not each country 
will have PEB. This file is read by the Excel tool via a query, filtered by those countries 
with PEB only, and placed in sheet 'merge' in the Excel tool. 


{marker options}{...}
{title:Options}
{dlgtab:Main}

{phang}
{opt load}  

{phang}
{opt group:data}  

{dlgtab:Debugging}
{phang}
{opt trace(string)}  

{phang}
{opt pause}  

{dlgtab:Advanced}

{phang}
{opt indir(string)}  

{phang}
{opt outdir(string)}  

{phang}
{opt ttldir(string)}  

{phang}
{opt vc:date(string)}  


{marker examples}{...}
{title:Examples}
{dlgtab:Organize and Export}
{pstd}
The following line will organize and export the results of the corresponding indicators. 
Notice that in contrast to the package {help indicators}, {cmd:peb} does not allow for 
multiple indicators at the same time. The reason for this is that each change in the 
master file must be done consciously. 

{p 10 10 2}.peb pov{p_end}
{p 10 10 2}.peb ine{p_end}
{p 10 10 2}.peb shp{p_end}
{p 10 10 2}.peb key{p_end}
{p 10 10 2}.peb npl{p_end}
{p 10 10 2}.peb wup{p_end}

{dlgtab:Load data}
{pstd}
Load poverty data and/or inequality data

{p 10 10 2}{stata peb pov, load}{p_end}
{p 10 10 2}{stata peb ine, load}{p_end}


{dlgtab:Purge data}
{pstd}
Purge file 'peb_pov.dta' from country COL

{p 10 10 2}.peb pov, countr(COL) purge {p_end}

{pstd}
Purge file 'peb_ine.dta' and 'peb_key.dta' from country ARG

{p 10 10 2}.peb ine key, countr(ARG) purge {p_end}

{pstd}
Purge file 'peb_pov.dta'  from all countries

{p 10 10 2}.peb pov, countr(all) purge {p_end}

{dlgtab:Purge data}
{pstd}
Restore 'peb_pov.dta' to a particular vintage. You just have to click on the date 
and follow the instructions. 

{p 10 10 2}.peb pov, restore {p_end}

{dlgtab:povcalnet}
{pstd}
Update file with national poverty rates to share with PovcalNet

{p 10 10 2}{stata peb npl, povcalnet}{p_end}


{title:Author}
{p}

{p 4 4 4}R.Andres Castaneda, The World Bank{p_end}
{p 6 6 4}Email {browse "mailto:acastanedaa@worldbank.org":acastanedaa@worldbank.org}{p_end}

