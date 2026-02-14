#delim cr
set more off
version 12
pause on
graph set ps logo off

capture log close
set linesize 180
set logtype text
log using  ../log/create-cps-figures.log , replace

/* --------------------------------------

This program runs simple regressions
for the Tennessee policy experiment.

--------------------------------------- */

clear all
estimates clear
set mem 500m
set matsize 10000
set linesize 200
describe, short

************************************************************
**   Prepare CPS outcomes
************************************************************

do fragment-prepare-cps-data.do 0
*exit
use ../dta/cps_DDD_FINAL.dta, clear

************************************************************
**   Prpare for simple difference-in-difference regressions
************************************************************

gen south = ///
 (statefip == 54 | statefip == 24 | statefip == 10 | statefip == 11 | ///
  statefip == 21 | statefip == 47 | ///
  statefip == 37 | statefip == 51 | statefip == 45 | statefip == 13 | ///
  statefip ==  5 | statefip == 22 | statefip == 48 | statefip == 40 | ///
  statefip ==  1 | statefip == 28 | statefip == 12 )

tab year, missing
tab statefip

gen byte tn = (statefip == 47)
gen byte post = year >= 2006
gen byte tn_X_post = tn * post

************************************************************
**   Create histograms of state-year changes, FP
**   All US
************************************************************

tempfile workingdata
save `workingdata'

use `workingdata' , clear

gen nokid = 1 - kid

codebook statefip

keep if year >= 2000 & year <= 2011

replace year = 2 * floor(year / 2)
collapse (mean) any_public any_private working, by(statefip year nokid)

keep if nokid == 1

sort statefip nokid year
by statefip nokid: gen diff1 = any_public - any_public[_n-1]
by statefip nokid: gen diff2 = working - working[_n-1]
by statefip nokid: gen diff3 = any_private - any_private[_n-1]

list statefip nokid year diff* if statefip == 47 & nokid == 1
summ diff*, det

list statefip nokid year diff* if diff2 > 0.5 & diff1 < .

gen count = 1

gen treat =  (statefip == 47 & nokid == 1 & year == 2006)

preserve
	replace diff1 = diff2

	replace count = 40 if (statefip == 47 & nokid == 1 & year == 2006)
	replace diff1 = 0.005 * floor(diff1 / 0.005) if (statefip != 47 | nokid != 1 | year != 2006)
	summ diff1, det
	collapse (sum) count, by(treat diff1)
	drop if missing(diff1)
	gen height = count
	replace diff1 = diff1 + 0.0025 if treat == 0
	twoway (bar height diff1 if (treat == 0), barwidth(0.005) fcolor(gs10) ) ///
	       (bar height diff1 if (treat == 1), barwidth(0.0005) color(gs4) ), ///
		xlabel(-0.08(0.02)0.08) ///
		ylabel(0(5)40) yscale(r(-0.001 40.001)) ///
		ylabel(, nogrid angle(horizontal)  ) ///
		scheme(s2mono) ///
		graphregion(fcolor(white)) ///
		aspectratio(`inv_golden_ratio') ///
		legend(off) ///
		yscale( nofextend ) xscale(nofextend) ///
		xtitle(" ") ytitle(" ") 
	graph save ../gph/working_histo-allus.gph , replace
 restore

preserve
	replace count = 40 if (statefip == 47 & nokid == 1 & year == 2006)
	replace diff3 = 0.005 * floor(diff3 / 0.005) if (statefip != 47 | nokid != 1 | year != 2006)
	summ diff3, det
	collapse (sum) count, by(treat diff3)
	drop if missing(diff3)
	gen height = count
	replace diff3 = diff3 + 0.0025 if treat == 0
	twoway (bar height diff3 if (treat == 0), barwidth(0.005) fcolor(gs10) ) ///
	       (bar height diff3 if (treat == 1), barwidth(0.0005) color(gs4) ), ///
		xlabel(-0.08(0.02)0.08) ///
		ylabel(0(5)40) yscale(r(-0.001 40.001)) ///
		ylabel(, nogrid angle(horizontal)  ) ///
		scheme(s2mono) ///
		graphregion(fcolor(white)) ///
		aspectratio(`inv_golden_ratio') ///
		legend(off) ///
		yscale( nofextend ) xscale(nofextend) ///
		xtitle(" ") ytitle(" ") 
	graph save ../gph/any_private_histo-allus.gph , replace
restore

preserve
	replace count = 40 if (statefip == 47 & nokid == 1 & year == 2006)
	replace diff1 = 0.005 * floor(diff1 / 0.005) if (statefip != 47 | nokid != 1 | year != 2006)
	summ diff1, det
	collapse (sum) count, by(treat diff1)
	drop if missing(diff1)
	gen height = count
	replace diff1 = diff1 + 0.0025 if treat == 0
	twoway (bar height diff1 if (treat == 0), barwidth(0.005) fcolor(gs10) ) ///
	       (bar height diff1 if (treat == 1), barwidth(0.0005) color(gs6) ), ///
		xlabel(-0.08(0.02)0.08) ///
		ylabel(0(5)40) yscale(r(-0.001 40.001)) ///
		ylabel(, nogrid angle(horizontal)  ) ///
		scheme(s2mono) ///
		graphregion(fcolor(white)) ///
		aspectratio(`inv_golden_ratio') ///
		legend(off) ///
		yscale( nofextend ) xscale(nofextend) ///
		xtitle(" ") ytitle(" ") 
	graph save ../gph/any_public_histo-allus.gph , replace
restore

use `workingdata' , clear

************************************************************
**   Create histograms of state-year changes, FP
**   South only
************************************************************

tempfile working
save `working'


use `working' , clear

gen nokid = 1 - kid

keep if south == 1

keep if year >= 2000 & year <= 2011

replace year = 2 * floor(year / 2)
collapse (mean) any_public any_private working, by(statefip year nokid)

keep if nokid == 1

sort statefip nokid year
by statefip nokid: gen diff1 = any_public - any_public[_n-1]
by statefip nokid: gen diff2 = working - working[_n-1]
by statefip nokid: gen diff3 = any_private - any_private[_n-1]

list statefip nokid year diff* if statefip == 47 & nokid == 1
summ diff*, det

list statefip nokid year diff* if diff2 > 0.5 & diff1 < .

gen count = 1

gen treat =  (statefip == 47 & nokid == 1 & year == 2006)

preserve
	replace diff1 = diff2

	replace count = 15 if (statefip == 47 & nokid == 1 & year == 2006)
	replace diff1 = 0.005 * floor(diff1 / 0.005) if (statefip != 47 | nokid != 1 | year != 2006)
	summ diff1, det
	collapse (sum) count, by(treat diff1)
	drop if missing(diff1)
	gen height = count
	replace diff1 = diff1 + 0.0025 if treat == 0
	twoway (bar height diff1 if (treat == 0), barwidth(0.005) fcolor(gs10) ) ///
	       (bar height diff1 if (treat == 1), barwidth(0.0005) color(gs4) ), ///
		xlabel(-0.08(0.02)0.08) ///
		ylabel(0(5)15) yscale(r(-0.001 15.001)) ///
		ylabel(, nogrid angle(horizontal)  ) ///
		scheme(s2mono) ///
		graphregion(fcolor(white)) ///
		aspectratio(`inv_golden_ratio') ///
		legend(off) ///
		yscale( nofextend ) xscale(nofextend) ///
		xtitle(" ") ytitle(" ") 
	graph save ../gph/working_histo.gph , replace
 restore

preserve
	replace count = 15 if (statefip == 47 & nokid == 1 & year == 2006)
	replace diff3 = 0.005 * floor(diff3 / 0.005) if (statefip != 47 | nokid != 1 | year != 2006)
	summ diff3, det
	collapse (sum) count, by(treat diff3)
	drop if missing(diff3)
	gen height = count
	replace diff3 = diff3 + 0.0025 if treat == 0
	twoway (bar height diff3 if (treat == 0), barwidth(0.005) fcolor(gs10) ) ///
	       (bar height diff3 if (treat == 1), barwidth(0.0005) color(gs4) ), ///
		xlabel(-0.08(0.02)0.08) ///
		ylabel(0(5)15) yscale(r(-0.001 15.001)) ///
		ylabel(, nogrid angle(horizontal)  ) ///
		scheme(s2mono) ///
		graphregion(fcolor(white)) ///
		aspectratio(`inv_golden_ratio') ///
		legend(off) ///
		yscale( nofextend ) xscale(nofextend) ///
		xtitle(" ") ytitle(" ") 
	graph save ../gph/any_private_histo.gph , replace
restore

preserve
	replace count = 15 if (statefip == 47 & nokid == 1 & year == 2006)
	replace diff1 = 0.005 * floor(diff1 / 0.005) if (statefip != 47 | nokid != 1 | year != 2006)
	summ diff1, det
	collapse (sum) count, by(treat diff1)
	drop if missing(diff1)
	gen height = count
	replace diff1 = diff1 + 0.0025 if treat == 0
	twoway (bar height diff1 if (treat == 0), barwidth(0.005) fcolor(gs10) ) ///
	       (bar height diff1 if (treat == 1), barwidth(0.0005) color(gs6) ), ///
		xlabel(-0.08(0.02)0.08) ///
		ylabel(0(5)15) yscale(r(-0.001 15.001)) ///
		ylabel(, nogrid angle(horizontal)  ) ///
		scheme(s2mono) ///
		graphregion(fcolor(white)) ///
		aspectratio(`inv_golden_ratio') ///
		legend(off) ///
		yscale( nofextend ) xscale(nofextend) ///
		xtitle(" ") ytitle(" ") 
	graph save ../gph/any_public_histo.gph , replace
restore

use `working' , clear

************************************************************
**   Run triple-difference figures for entire US
************************************************************

preserve
	keep if year >= 2000 & year <= 2007

	tab state
	codebook state

	** Given small cells, we present the raw data in two-year means
	tab year
	replace year = 2 * floor(year / 2)
	tab year

	collapse (mean) any_p* any_coverage any_empl any_m* working, by(year tn kid)
	sort tn kid year
	list

	local inv_golden_ratio = 2 / ( sqrt(5) + 1 )
	twoway ///
		(connected any_public year if tn == 0 & kid == 1, lpattern(dash) lcolor(gray) mcolor(red) msymbol(D)) ///
		(connected any_public year if tn == 0 & kid == 0, lpattern(dash) lcolor(gray) mcolor(red) msymbol(T)) ///
		(connected any_public year if tn == 1 & kid == 1, lpattern(solid) lcolor(gray) mcolor(blue) msymbol(s) ) ///
		(connected any_public year if tn == 1 & kid == 0, lpattern(solid) lcolor(gray) mcolor(blue) msymbol(o) ) ///
		, ///
		ylabel(, nogrid angle(horizontal)  ) ///
		scheme(s2mono) ///
		graphregion(fcolor(white)) ///
		xline(2005) ///
		aspectratio(`inv_golden_ratio') ///
		legend(off) ///
		yscale( nofextend ) xscale(nofextend) ///
		xlabel(2000 "2000-2001" 2002 "2002-2003" 2004 "2004-2005" 2006 "2006-07") ///
		xtitle(" ") ytitle(" ") 
	 graph save ../gph/any_public_kid-allus.gph, replace

	local inv_golden_ratio = 2 / ( sqrt(5) + 1 )
	twoway ///
		(connected any_private year if tn == 0 & kid == 1, lpattern(dash) lcolor(gray) mcolor(red) msymbol(D)) /// 
		(connected any_private year if tn == 0 & kid == 0, lpattern(dash) lcolor(gray) mcolor(red) msymbol(T)) ///
		(connected any_private year if tn == 1 & kid == 1, lpattern(solid) lcolor(gray) mcolor(blue) msymbol(s) ) ///
		(connected any_private year if tn == 1 & kid == 0, lpattern(solid) lcolor(gray) mcolor(blue) msymbol(o) ) ///
		, ///
		ylabel(, nogrid angle(horizontal)  ) ///
		scheme(s2mono) ///
		aspectratio(`inv_golden_ratio') ///
		graphregion(fcolor(white)) ///
		xline(2005) ///
		legend(off) ///
		yscale( nofextend ) xscale(nofextend) ///
		xlabel(2000 "2000-2001" 2002 "2002-2003" 2004 "2004-2005" 2006 "2006-07") ///
		xtitle(" ") ytitle(" ") 
	graph save ../gph/any_private_kid-allus.gph, replace

	local inv_golden_ratio = 2 / ( sqrt(5) + 1 )
	twoway ///
		(connected working year if tn == 0 & kid == 1, lpattern(dash) lcolor(gray) mcolor(red) msymbol(D)) ///
		(connected working year if tn == 0 & kid == 0, lpattern(dash) lcolor(gray) mcolor(red) msymbol(T)) ///
		(connected working year if tn == 1 & kid == 1, lpattern(solid) lcolor(gray) mcolor(blue) msymbol(s) ) ///
		(connected working year if tn == 1 & kid == 0, lpattern(solid) lcolor(gray) mcolor(blue) msymbol(o) ) ///
		, ///
		ylabel(, nogrid angle(horizontal)  ) ///
		scheme(s2mono) ///
		graphregion(fcolor(white)) ///
		xline(2005) ///
		legend(off) ///
		yscale( nofextend ) xscale(nofextend) ///
		aspectratio(`inv_golden_ratio') ///
		xlabel(2000 "2000-2001" 2002 "2002-2003" 2004 "2004-2005" 2006 "2006-07") ///
		xtitle(" ") ytitle(" ") 
	graph save ../gph/working_kid-allus.gph, replace

restore

************************************************************
**   Run overall triple-difference figures, FP
************************************************************

preserve
	keep if south == 1
	keep if year >= 2000 & year <= 2007

	** Given small cells, we present the raw data in two-year means
	tab year
	replace year = 2 * floor(year / 2)
	tab year

	collapse (mean) any_p* any_coverage any_empl any_m* working, by(year tn kid)
	sort tn kid year
	list

	local inv_golden_ratio = 2 / ( sqrt(5) + 1 )

	twoway ///
		(connected any_public year if tn == 0 & kid == 1, lpattern(dash) lcolor(gray) mcolor(red) msymbol(D)) ///
		(connected any_public year if tn == 0 & kid == 0, lpattern(dash) lcolor(gray) mcolor(red) msymbol(T)) ///
		(connected any_public year if tn == 1 & kid == 1, lpattern(solid) lcolor(gray) mcolor(blue) msymbol(s) ) ///
		(connected any_public year if tn == 1 & kid == 0, lpattern(solid) lcolor(gray) mcolor(blue) msymbol(o) ) ///
		, ///
		ylabel(, nogrid angle(horizontal)  ) ///
		scheme(s2mono) ///
		graphregion(fcolor(white)) ///
		xline(2005) ///
		aspectratio(`inv_golden_ratio') ///
		legend(off) ///
		yscale( nofextend ) xscale(nofextend) ///
		xlabel(2000 "2000-2001" 2002 "2002-2003" 2004 "2004-2005" 2006 "2006-07") ///
		xtitle(" ") ytitle(" ") 
	 graph save ../gph/any_public_kid.gph, replace

	twoway ///
		(connected any_private year if tn == 0 & kid == 1, lpattern(dash) lcolor(gray) mcolor(red) msymbol(D)) /// 
		(connected any_private year if tn == 0 & kid == 0, lpattern(dash) lcolor(gray) mcolor(red) msymbol(T)) ///
		(connected any_private year if tn == 1 & kid == 1, lpattern(solid) lcolor(gray) mcolor(blue) msymbol(s) ) ///
		(connected any_private year if tn == 1 & kid == 0, lpattern(solid) lcolor(gray) mcolor(blue) msymbol(o) ) ///
		, ///
		ylabel(, nogrid angle(horizontal)  ) ///
		scheme(s2mono) ///
		aspectratio(`inv_golden_ratio') ///
		graphregion(fcolor(white)) ///
		xline(2005) ///
		legend(off) ///
		yscale( nofextend ) xscale(nofextend) ///
		xlabel(2000 "2000-2001" 2002 "2002-2003" 2004 "2004-2005" 2006 "2006-07") ///
		xtitle(" ") ytitle(" ") 
	graph save ../gph/any_private_kid.gph, replace

	twoway ///
		(connected working year if tn == 0 & kid == 1, lpattern(dash) lcolor(gray) mcolor(red) msymbol(D)) ///
		(connected working year if tn == 0 & kid == 0, lpattern(dash) lcolor(gray) mcolor(red) msymbol(T)) ///
		(connected working year if tn == 1 & kid == 1, lpattern(solid) lcolor(gray) mcolor(blue) msymbol(s) ) ///
		(connected working year if tn == 1 & kid == 0, lpattern(solid) lcolor(gray) mcolor(blue) msymbol(o) ) ///
		, ///
		ylabel(, nogrid angle(horizontal)  ) ///
		scheme(s2mono) ///
		graphregion(fcolor(white)) ///
		xline(2005) ///
		legend(off) ///
		yscale( nofextend ) xscale(nofextend) ///
		aspectratio(`inv_golden_ratio') ///
		xlabel(2000 "2000-2001" 2002 "2002-2003" 2004 "2004-2005" 2006 "2006-07") ///
		xtitle(" ") ytitle(" ") 
	graph save ../gph/working_kid.gph, replace

restore

************************************************************
**   Long-run triple-difference figures, FP
************************************************************

preserve

	keep if south == 1

	keep if year >= 1998 & year <= 2011
	replace year = 2 * floor(year / 2)

	collapse (mean) any_p* any_coverage any_empl any_m* working, by(year tn kid)
	sort tn kid year
	list

	local inv_golden_ratio = 2 / ( sqrt(5) + 1 )

	twoway ///
	 (connected any_public year if tn == 0 & kid == 1, lpattern(dash) lcolor(gray) mcolor(red) msymbol(D)) ///
	 (connected any_public year if tn == 0 & kid == 0, lpattern(dash) lcolor(gray) mcolor(red) msymbol(T)) ///
	 (connected any_public year if tn == 1 & kid == 1, lpattern(solid) lcolor(gray) mcolor(blue) msymbol(s) ) ///
	 (connected any_public year if tn == 1 & kid == 0, lpattern(solid) lcolor(gray) mcolor(blue) msymbol(o) ) ///
		, ///
		ylabel(, nogrid angle(horizontal)  ) ///
		ylabel(0.12(0.02)0.24) ///
		scheme(s2mono) ///
		graphregion(fcolor(white)) ///
		xline(2005) ///
		legend(region(style(none))) ///
		aspectratio(`inv_golden_ratio') ///
		legend(off) ///
		yscale( nofextend ) xscale(nofextend) ///
		xlabel(1998 "1998-1999" 2000 "2000-2001" 2002 "2002-2003" 2004 "2004-2005" 2006 "2006-2007" 2008 "2008-2009" 2010 "2010-11") ///
		xtitle(" ") ytitle(" ") 
	 graph save ../gph/any_public_kid-longterm.gph, replace

	sum any_private 
	format any_private %-9.2f
	local inv_golden_ratio = 2 / ( sqrt(5) + 1 )

	twoway ///
	 (connected any_private year if tn == 0 & kid == 1, lpattern(dash) lcolor(gray) mcolor(red) msymbol(D)) ///
	 (connected any_private year if tn == 0 & kid == 0, lpattern(dash) lcolor(gray) mcolor(red) msymbol(T)) ///
	 (connected any_private year if tn == 1 & kid == 1, lpattern(solid) lcolor(gray) mcolor(blue) msymbol(s) ) ///
	 (connected any_private year if tn == 1 & kid == 0, lpattern(solid) lcolor(gray) mcolor(blue) msymbol(o) ) ///
		, ///
		ylabel(, nogrid angle(horizontal)  ) ///
		ylabel(0.54(0.02)0.70) ///
		scheme(s2mono) ///
		graphregion(fcolor(white)) ///
		xline(2005) ///
		legend(region(style(none))) ///
		aspectratio(`inv_golden_ratio') ///
		legend(off) ///
		yscale( nofextend ) xscale(nofextend) ///
		xlabel(1998 "1998-1999" 2000 "2000-2001" 2002 "2002-2003" 2004 "2004-2005" 2006 "2006-2007" 2008 "2008-2009" 2010 "2010-11") ///
		xtitle(" ") ytitle(" ") 
	 graph save ../gph/any_private_kid-longterm.gph, replace

	twoway ///
	 (connected working year if tn == 0 & kid == 1, lpattern(dash) lcolor(gray) mcolor(red) msymbol(D)) ///
	 (connected working year if tn == 0 & kid == 0, lpattern(dash) lcolor(gray) mcolor(red) msymbol(T)) ///
	 (connected working year if tn == 1 & kid == 1, lpattern(solid) lcolor(gray) mcolor(blue) msymbol(s) ) ///
	 (connected working year if tn == 1 & kid == 0, lpattern(solid) lcolor(gray) mcolor(blue) msymbol(o) ) ///
		, ///
		ylabel(, nogrid angle(horizontal)  ) ///
		ylabel(0.66(0.02)0.78) ///
		scheme(s2mono) ///
		graphregion(fcolor(white)) ///
		xline(2005) ///
		legend(region(style(none))) ///
		aspectratio(`inv_golden_ratio') ///
		legend(off) ///
		yscale( nofextend ) xscale(nofextend) ///
		xlabel(1998 "1998-1999" 2000 "2000-2001" 2002 "2002-2003" 2004 "2004-2005" 2006 "2006-2007" 2008 "2008-2009" 2010 "2010-11") ///
		xtitle(" ") ytitle(" ") 
	 graph save ../gph/working_kid-longterm.gph, replace

restore

************************************************************
**   difference-in-difference plots, FP
************************************************************

preserve
	keep if south == 1
	keep if year >= 2000 & year <= 2007

	collapse (mean) any_p* any_coverage any_empl any_m* working, by(year tn)

	tab year, missing
	replace year = 2 * floor(year/2)
	tab year, missing
	collapse (mean) any_p* any_coverage any_empl any_m* working, by(year tn)

	sort tn year
	list

	local inv_golden_ratio = 2 / ( sqrt(5) + 1 )

	twoway ///
	 (connected any_public year if tn == 0, lpattern(dash) lcolor(gray) mcolor(red) msymbol(i) yaxis(1) ) ///
	 (connected any_public year if tn == 1, lpattern(solid) lcolor(gray) mcolor(blue) yaxis(2) msymbol(o) ) ///
	 , /// 
		scheme(s2mono) ///
		graphregion(fcolor(white)) ///
		xline(2005) ///
		legend(off) ///
		yscale( nofextend ) xscale(nofextend) ///
		aspectratio(`inv_golden_ratio') ///
		xlabel(2000 "2000-2001" 2002 "2002-2003" 2004 "2004-2005" 2006 "2006-2007") ///
	  ylabel(0.10(0.02)0.18, nogrid axis(1) angle(horizontal) ) ylabel(0.16(0.02)0.24, axis(2) angle(horizontal) ) ///
		xtitle(" ") ytitle(" ", axis(1) ) ytitle(" ", axis(2) ) 
	 graph save ../gph/any_public.gph, replace


	sum any_private if tn == 0
	sum any_private if tn == 1
	format any_private %-9.2f
	local inv_golden_ratio = 2 / ( sqrt(5) + 1 )

	twoway ///
	 (connected any_private year if tn == 0, lpattern(dash) lcolor(gray) mcolor(red) msymbol(i) yaxis(1)) ///
	 (connected any_private year if tn == 1, lpattern(solid) lcolor(blue) msymbol(o) mcolor(blue) yaxis(2) ) ///
	 , /// 
	  ylabel(0.60(0.02)0.68, axis(1) nogrid angle(horizontal)) ylabel(0.58(0.02)0.66, axis(2) angle(horizontal)) ///
		scheme(s2mono) ///
		graphregion(fcolor(white)) ///
		xline(2005) ///
		aspectratio(`inv_golden_ratio') ///
		legend(off) ///
		yscale( nofextend ) xscale(nofextend) ///
		xlabel(2000 "2000-2001" 2002 "2002-2003" 2004 "2004-2005" 2006 "2006-2007") ///
		xtitle(" ") ytitle(" ", axis(1) ) ytitle(" ", axis(2) ) 

	 graph save ../gph/any_private.gph, replace

	twoway ///
	 (connected working year if tn == 0, lpattern(dash) lcolor(gray) mcolor(red) msymbol(i) yaxis(1)) ///
	 (connected working year if tn == 1, lpattern(solid) lcolor(gray) mcolor(blue) msymbol(o) yaxis(2)) ///
	 , /// 
	  ylabel(0.66(0.02)0.78, axis(1) nogrid angle(horizontal)) ylabel(0.64(0.02)0.76, axis(2) angle(horizontal)) ///
		scheme(s2mono) ///
		graphregion(fcolor(white)) ///
		aspectratio(`inv_golden_ratio') ///
		xline(2005) ///
		legend(off) ///
		yscale( nofextend ) xscale(nofextend) ///
		xlabel(2000 "2000-2001" 2002 "2002-2003" 2004 "2004-2005" 2006 "2006-2007") ///
		xtitle(" ") ytitle(" ", axis(1) ) ytitle(" ", axis(2) ) 
	 graph save ../gph/working.gph, replace

restore








************************************************************
** "event study" appendix figures
************************************************************
keep if year >= 2000 & year <= 2011
keep if south == 1

gen nokid = 1 - kid

forvalues y = 2000/2011 {
 gen evt`y' = (year == `y') * (statefip == 47) * nokid
}
drop evt2000

xi i.statefip*i.year i.year*i.nokid i.statefip*i.nokid

reg any_public evt* _I*

matrix results = J(12,1,0)
local row = 2
forvalues i = 2001/2011 {
 matrix results[`row',1] = _b[evt`i']
 local row = `row' + 1
}

 preserve

drop _all
svmat results
rename results1 evt_coeffs
gen year = _n + 1999

local inv_golden_ratio = 2 / ( sqrt(5) + 1 )
twoway ///
	(connected evt_coeffs year, lpattern(solid) lcolor(gray) mcolor(blue) msymbol(o)) /// 
		, ///
		ylabel(, nogrid angle(horizontal)  ) ///
		scheme(s2mono) ///
		aspectratio(`inv_golden_ratio') ///
		graphregion(fcolor(white)) ///
		xline(2005.1) ///
		legend(off) ///
		yscale( nofextend ) xscale(nofextend) ///
		xlabel(2000(1)2011) ylabel(-0.12(0.04)0.12) /// 
		xtitle(" ") ytitle(" ") 
	graph save ../gph/event_study_working.gph, replace
	graph export ../gph/event_study_any_public.eps, replace
	!sz ../gph/event_study_any_public.eps

 restore




reg working evt* _I*

matrix results = J(12,1,0)
local row = 2
forvalues i = 2001/2011 {
 matrix results[`row',1] = _b[evt`i']
 local row = `row' + 1
}

 preserve

drop _all
svmat results
rename results1 evt_coeffs
gen year = _n + 1999

local inv_golden_ratio = 2 / ( sqrt(5) + 1 )
twoway ///
	(connected evt_coeffs year, lpattern(solid) lcolor(gray) mcolor(blue) msymbol(o)) /// 
		, ///
		ylabel(, nogrid angle(horizontal)  ) ///
		scheme(s2mono) ///
		aspectratio(`inv_golden_ratio') ///
		graphregion(fcolor(white)) ///
		xline(2005.1) ///
		legend(off) ///
		yscale( nofextend ) xscale(nofextend) ///
		xlabel(2000(1)2011) ylabel(-0.06(0.02)0.06) /// 
		xtitle(" ") ytitle(" ") 
	graph save ../gph/event_study_working.gph, replace
	graph export ../gph/event_study_working.eps, replace
	!sz ../gph/event_study_working.eps

 restore



log close
exit
