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

qui {
	cap confirm var region
	if (_rc) gen region = ""
	
	preserve 
	datalibweb_inventory
	putmata I=(region countrycode countryname), replace
	restore
	
	levelsof countrycode if region == "", local(codes)
	foreach code of local codes {
		mata: _addregion(I)
		replace region = "`region'" if countrycode == "`code'"
	}
		
}

end

mata
void _addregion(string matrix I) {
	
	string scalar R, code
	
	code = st_local("code")
	R = I[(selectindex(regexm(I[.,2], code))),1]
	if (rows(R) != 0) st_local("region", R)
	else              st_local("region", "")
	
}
end

exit
/* End of do-file */



><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
