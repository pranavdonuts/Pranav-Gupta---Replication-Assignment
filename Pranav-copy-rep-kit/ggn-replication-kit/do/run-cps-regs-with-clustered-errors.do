#delim cr
set more off
version 12
pause on
graph set ps logo off

capture log close
set linesize 180
set logtype text
log using  ../log/run-cps-regs-with-clustered-errors.log , replace

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
**   Programs Used Below                          
************************************************************

** We display the time throughout this program to track which
** pieces are slowing things down.
capture program drop datetime
program define datetime 
	disp "The time is now: $S_TIME, $S_DATE"
end

capture program drop tabresults
	program tabresults
	disp "Readable Output:  "
	esttab * , keep( `1' ) ///
	stats(r2 N, fmt(%9.3f %9.0g)) ///
	cells(b( fmt(%9.3f)) se( par(( )) fmt(%9.3f)) p(par([ ]) fmt(%9.3f)) ) replace  
	disp "To be pasted into excel:  "
	estout * , keep( `1' ) ///
	stats(r2 N, fmt(%9.6f %9.0g)) ///   
	cells(b(nostar fmt(%9.6f)) se(fmt(%9.6f) nostar) p(fmt(%9.6f) )) ///
	style(fixed) replace type mlabels(, nonumbers )

	estimates clear
end

** then call it with:
** tabresults "var1 var2 ..."

************************************************************
**   Prepare CPS outcomes
************************************************************

** Option 13, below, prepares the micro data, and does nothing
** else.

do fragment-prepare-cps-data.do 13
*exit

use ../dta/cps_MICRO_FINAL.dta, clear


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
**   Prepare for simple difference-in-difference regressions
************************************************************

gen byte nokid = (1 - kid)
gen byte nokid_X_post = (1 - kid) * post
gen byte tn_X_nokid = tn * (1 - kid)
gen tn_X_post_X_nokid = tn * (1 - kid) * post

************************************************************
**   Generate "type" variables
************************************************************

tab female

gen byte agebin = 0 * (age >= 21 & age < 40) + ///
 1 * (age >= 40 & age < 65)
tab agebin

gen byte educbin = (educ >= 73)

gen byte ourhealthbin = (health >= 2)
gen byte tradhealthbin = (health > 2)

gen byte age5564 = 0 * (age >= 21 & age < 54) + 1 * (age >= 55 & age <= 64)
tab age5564

d, f

keep ///
female agebin age5564 educbin ourhealthbin tradhealthbin age ///
south statefip year tn post nokid ///
any_public any_empl_wk working* any_private wage* hrs_lw* unemp ilf  ///
any_empl any_noempl_wk any_nocov_wk any_ind ///
hrswork ///
wtsupp hinswt ///
race smc1 smc2 col hsd hsg 

compress


************************************************************
**   Our collapse statement (used below)
************************************************************

capture program drop our_collapse
program define our_collapse 
	args model
	if "`model'" == "" {
		disp "Please choose a specification for the collapse statement"
		kablooey
	}

	if "`model'" == "dd" {

		tempfile rest
		save `rest'

		collapse ///
		(mean) working unemp ilf hrs_lw_* hrswork wage* ///
		[aw = wtsupp] , by(year statefip tn) fast

		tempfile workingDD
		save `workingDD'

		use `rest'

		** Note: the weight hinswt is designed solely for the insurance variables
		collapse (mean) any_* ///
		[aw = hinswt], by(year statefip tn) fast

		** Redo year for health variables (NOT labor supply variables)
		replace year = year - 1

		sort year statefip
		merge 1:1 year statefip using `workingDD'
		drop _merge
	}

	if "`model'" == "ddd" {

		tempfile rest
		save `rest'

		collapse ///
		(mean) working unemp ilf hrs_lw_* hrswork wage* ///
		[aw = wtsupp] , by(year statefip nokid tn) fast

		tempfile working_vars
		save `working_vars'

		use `rest'

		** Note: the weight hinswt is designed solely for the insurance variables
		collapse (mean) any_* ///
		[aw = hinswt], by(year statefip nokid tn) fast

		** Redo year for health variables (NOT labor supply variables)
		replace year = year - 1

		sort year statefip nokid 
		merge 1:1 year statefip nokid using `working_vars'
		drop _merge
	}

	** After the collapse, we restrict by year
	disp "Now imposing year restriction: `year0' to `year1'"
	keep if year >= $year0 & year <= $year1

	gen byte post = (year >= 2006)

end


************************************************************
**   Try Different Standard Errors, DD (Panel B, C, and D of A12)
************************************************************

preserve
	keep if age >= 21 & age < 65
	keep if south == 1
	global year0 = 2000
	global year1 = 2007

	our_collapse dd

	isid statefip year
	codebook statefip year

	qui xi i.year i.statefip 

	gen byte tn_post = (statefip == 47) * (year >= 2006)

	** First, cluster-robust
	foreach outcome in any_public working hrs_lw_lt20 hrs_lw_ge20 hrs_lw_2035 hrs_lw_ge35 {
		
		qui reg `outcome' tn_post _I* , cluster(statefip)
		estimates store `outcome'

	}

	tabresults "tn_post"

	** Second, heteroskedasticity-robust
	foreach outcome in any_public working hrs_lw_lt20 hrs_lw_ge20 hrs_lw_2035 hrs_lw_ge35 {
		
		qui reg `outcome' tn_post _I* , robust
		estimates store `outcome'

	}

	tabresults "tn_post"

	** Third, Unadjusted
	foreach outcome in any_public working hrs_lw_lt20 hrs_lw_ge20 hrs_lw_2035 hrs_lw_ge35 {
		
		qui reg `outcome' tn_post _I* 
		estimates store `outcome'

	}

	tabresults "tn_post"

restore

************************************************************
**   Try Different Standard Errors, DDD (Panel B, C, and D of A12)
************************************************************

preserve
	keep if age >= 21 & age < 65
	keep if south == 1
	global year0 = 2000
	global year1 = 2007

	our_collapse ddd

	isid statefip year nokid
	codebook statefip year

	gen byte tn_X_post_X_nokid = tn * post * nokid

	qui xi i.year*i.statefip i.year*i.nokid i.nokid*i.statefip

	** First, cluster-robust
	foreach outcome in any_public working hrs_lw_lt20 hrs_lw_ge20 hrs_lw_2035 hrs_lw_ge35 {
		
		qui reg `outcome' tn_X_post_X_nokid _I* , cluster(statefip)
		estimates store `outcome'

	}

	tabresults "tn_X_post_X_nokid"

	** Second, heteroskedasticity-robust
	foreach outcome in any_public working hrs_lw_lt20 hrs_lw_ge20 hrs_lw_2035 hrs_lw_ge35 {
		
		qui reg `outcome' tn_X_post_X_nokid _I* , robust
		estimates store `outcome'

	}

	tabresults "tn_X_post_X_nokid"

	** Third, Unadjusted
	foreach outcome in any_public working hrs_lw_lt20 hrs_lw_ge20 hrs_lw_2035 hrs_lw_ge35 {
		
		qui reg `outcome' tn_X_post_X_nokid _I* 
		estimates store `outcome'

	}

	tabresults "tn_X_post_X_nokid"

restore



log close
exit
