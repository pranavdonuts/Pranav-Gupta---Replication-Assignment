#delim cr
set more off
version 12
pause on
graph set ps logo off

capture log close
set linesize 80
set logtype text
log using ../log/analyze-brfss-data.log , replace

/* --------------------------------------

This program plots insurance coverage in
Tennessee based on the BRFSS.

--------------------------------------- */

clear all
estimates clear

clear
use ../dta/brfss_data_all.dta

tab year
keep if year >= 2001 & year <= 2007
keep if age>=21 & age<=64

tab year if fips == 47, missing

keep if ///
 fips==47 | fips==1 | fips==21 | fips==28 | fips==5 | ///
 fips==10 | fips==11 | fips==12 | fips==13 | fips==22 | ///
 fips==24 | fips==37 | fips==40 | fips==45 | fips==48 | ///
 fips==51 | fips==54

desc, full

gen mhealth = (mental_poor > 0 & mental_poor < 77)

replace satisfied = . if satisfied > 4

replace employ = (employ == 1) if employ < .

replace srhealth = . if srhealth > 5
forvalues s=1/4 {
	 gen srhealth`s' = (srhealth <= `s') if srhealth < .
}

gen persdoc1 = .
replace persdoc1 = 0 if persdoc == 3
replace persdoc1 = 1 if persdoc < 3

gen persdoc2 = .
replace persdoc2 = 0 if persdoc == 3 | persdoc == 2
replace persdoc2 = 1 if persdoc < 2


**
** Main sample restriction: drop college educated
**
drop if educ == 6


rename insurance insurance_orig
gen insurance = .
replace insurance = 0 if insurance_orig == 2
replace insurance = 1 if insurance_orig == 1
drop insurance_orig

keep if year >= 2000

collapse insurance [aw=finalwgt], by(fips year month)

gen tn = (fips==47)
replace fips = tn

collapse insurance, by(fips tn year month) fast

gen ym = year + month/12
 rename insurance insurance_orig
 sort fips ym
 gen insurance = insurance_orig

 by fips: replace insurance = ///
  (insurance_orig + insurance_orig[_n-1] + insurance_orig[_n-2] + insurance_orig[_n-3] + insurance_orig[_n-4] + insurance_orig[_n-5] + insurance_orig[_n-6] + insurance_orig[_n-7])/8

 by fips: replace insurance = ///
  (insurance_orig + insurance_orig[_n-1] + insurance_orig[_n-2] + insurance_orig[_n-3] + insurance_orig[_n-4] + insurance_orig[_n-5] + insurance_orig[_n-6])/7 if year == 2006 & month == 2 & tn == 1
 by fips: replace insurance = ///
  (insurance_orig + insurance_orig[_n-1] + insurance_orig[_n-2] + insurance_orig[_n-3] + insurance_orig[_n-4] + insurance_orig[_n-5])/6 if year == 2006 & month == 1 & tn == 1
 by fips: replace insurance = ///
  (insurance_orig + insurance_orig[_n-1] + insurance_orig[_n-2] + insurance_orig[_n-3] + insurance_orig[_n-4])/5 if year == 2005 & month == 12 & tn == 1
 by fips: replace insurance = ///
  (insurance_orig + insurance_orig[_n-1] + insurance_orig[_n-2] + insurance_orig[_n-3])/4 if year == 2005 & month == 11 & tn == 1
 by fips: replace insurance = ///
  (insurance_orig + insurance_orig[_n-1] + insurance_orig[_n-2])/3 if year == 2005 & month == 10 & tn == 1
 by fips: replace insurance = ///
  (insurance_orig + insurance_orig[_n-1])/2 if year == 2005 & month == 9 & tn == 1
 by fips: replace insurance = ///
  (insurance_orig)/1 if year == 2005 & month == 8 & tn == 1

keep if year >= 2003

list

summ insurance if ym <= 2005.5 & ym >= 2004.5 & tn == 1
global pre = r(mean)

summ insurance if ym >= 2006 & tn == 1
global post = r(mean)

summ insurance if year == 2005 & month == 9 & tn == 1
global init = r(mean)

gen pre = $pre if ym <= 2005.5 & ym >= 2004.5
gen post = $post if ym >= 2006

di $pre-$init
di $post-$init
di ($post-$init)/($pre-$init)

local tenncare_line = 2005 + (7/12)

format insurance %12.2f
local inv_golden_ratio = 2 / ( sqrt(5) + 1 )
graph set window fontface "Garamond" 
twoway ///
	(connected insurance ym if tn == 1 & year >= 2004 & year <= 2006 , lpattern(solid) lcolor(gray) mcolor(blue) msymbol(o) ) ///
	(connected insurance ym if tn == 0 & year >= 2004 & year <= 2006 , lpattern(dash) lcolor(gray)  mcolor(red) msymbol(i) ) ///
	, ///
	graphregion(fcolor(white)) ///
	ylabel(, nogrid angle(horizontal)  ) ///
	scheme(s2mono)  ///
	aspectratio(`inv_golden_ratio') ///
	xline(`tenncare_line') ///
	graphregion(fcolor(white))  ///
	legend(off) ///
	yscale( nofextend ) xscale(nofextend) ///
	xlabel(2004(1)2007) ///
	xtitle(" ") ytitle(" ") ///
	ylabel(0.78(0.02)0.90) yscale(r(0.7798 0.9002))
graph save ../gph/brfss_insurance-trimmed.gph, replace

log close
exit
