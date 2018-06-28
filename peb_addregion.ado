/*==================================================
project:       Add region to country code
Author:        Andres Castaneda 
----------------------------------------------------
Creation Date:    28 Jun 2018 - 09:27:53
==================================================*/

/*==================================================
                        0: Program set up
==================================================*/
program define peb_addregion, rclass

cap confirm var region
if (_rc) gen region = ""

preserve 
datalibweb_inventory
putmata I=(region countrycode countryname), replace
restore

levelsof countrycode if region == "", local(codes)
foreach code of local codes {
	mata: st_local("region", I[(selectindex(regexm(I[.,2], "`code'"))),1])
	replace region = "`region'" if countrycode == "`code'"
}



end

exit
/* End of do-file */

><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
