#delim cr
set more off
version 12
pause on
graph set ps logo off

capture log close
set linesize 80
set logtype text
log using ../log/plot-ssdi-trend.log , replace

/* --------------------------------------

This program plots trends in SSDI applications.

--------------------------------------- */

clear all
estimates clear

clear
set more off


************************************************************
**   Bring in Data
************************************************************

use ../src/ssdi_applications.dta


************************************************************
**   Identify South
************************************************************

gen south = ///
 (statecode == "WV" | statecode == "MD" | statecode == "DE"| statecode == "DC" | ///
  statecode == "KY" | statecode == "TN" | ///
  statecode == "NC" | statecode == "VA" | statecode == "SC" | statecode == "GA" | ///
  statecode ==  "AK" | statecode == "LA" | statecode == "TX" | statecode == "OK" | ///
  statecode ==  "AL" | statecode == "MS" | statecode == "FL" )

tab statecode, missing
rename date year
tab year, missing

egen stnum = group(statecode)


************************************************************
**   Clean up key variables
************************************************************

gen log_apps = log(adultreceipts)

gen tn_X_post = (statecode == "TN") * (year >= 2006)

gen tn = (statecode == "TN")

************************************************************
**   Graph Tennessee versus South
************************************************************

preserve

	keep if south == 1

	tab1 state year

	collapse (mean) adultreceipts , by(tn year)

	list

	sort tn year
	by tn: gen init = adultreceipts[1]
	by tn: replace adultreceipts = adultreceipts / init * 100
	drop init

	list

	** title: "SSDI applications (Year 2001=100)"
	local inv_golden_ratio = 2 / ( sqrt(5) + 1 )
	twoway ///
		(connected adultreceipts year if tn == 0, lpattern(dash) lcolor(gray) mcolor(red) msymbol(i)) ///
		(connected adultreceipts year if tn == 1, lpattern(solid) lcolor(gray) mcolor(blue) msymbol(o) ) ///
		, ///
		ylabel(, nogrid angle(horizontal)  ) ///
		scheme(s2mono) ///
		graphregion(fcolor(white)) ///
		xline(2005) ///
		aspectratio(`inv_golden_ratio') ///
		legend(off) ///
		yscale( nofextend ) xscale(nofextend) ///
		xlabel(2001(2)2011) xtitle(" ") ytitle( "") ///
		ylabel(100(10)150) yscale(r(99.99 150.01))
	 graph save ../gph/ssdi-tn-v-south-mostyears.gph, replace

restore



log close
exit

