#delim cr
set more off
version 12
pause on
graph set ps logo off

args piece
if "`piece'" == "" {
	disp "Please feed the program a set of regressions to run."
	kablooey
}

capture log close
set linesize 180
set logtype text
log using  ../log/run-cps-main-tables-piece-`piece'.log , replace

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

*global Niterations = 500
global Niterations = 20

************************************************************
**   Prepare CPS outcomes
************************************************************

**
** Option 13, below, prepares the micro data, and does nothing else.
**
do fragment-prepare-cps-data.do 13
*exit
use ../dta/cps_MICRO_FINAL.dta, clear
keep if year >= 1998
keep if age >= 21


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
any_public any_empl_wk working any_private wage* hrs_lw* unemp ilf  ///
any_empl any_noempl_wk any_nocov_wk any_ind ///
hrswork ///
wtsupp hinswt ///
race smc1 smc2 col hsd hsg 

compress

************************************************************
**   Table I
************************************************************

preserve

	keep if south == 1
	keep if age >= 21 & age < 65

	** We divide people into White, Black, and Other
	tab race , miss
	** 100	White	

	** 200	Black/Negro	
	** 801	White-Black	
	** 805	Black-American Indian	
	** 806	Black-Asian	
	** 807	Black-Hawaiian/Pacific Islander	

	** 300	American Indian/Aleut/Eskimo	
	** 650	Asian or Pacific Islander	
	** 651	Asian only	
	** 652	Hawaiian/Pacific Islander only	
	** 700	Other (single) race, n.e.c.	
	** 802	White-American Indian	
	** 803	White-Asian	
	** 804	White-Hawaiian/Pacific Islander	
	** 808	American Indian-Asian	
	** 809	Asian-Hawaiian/Pacific Islander	
	** 810	White-Black-American Indian	
	** 811	White-Black-Asian	
	** 812	White-American Indian-Asian	
	** 813	White-Asian-Hawaiian/Pacific Islander	
	** 814	White-Black-American Indian-Asian	
	** 820	Two or three races, unspecified	
	** 830	Four or five races, unspecified	
	** 999	NIU
	gen byte white = (race == 100)
	gen byte black = (race == 200 | race == 801 | race == 805 | race == 806 | race == 807)
	gen byte other = 1 - white - black
	tab1 white black other

	gen byte any_college = ( smc1 == 1 | smc2 == 1 | col == 1)
	gen sum = hsd + hsg + any_college
	tab sum

	gen byte kid = 1 - nokid

	matrix sample_stats = J(25,2,.)

	local row = 1

	foreach var in any_public any_private {
		qui sum `var' [aw = hinswt] if tn == 1 & year >= 2001 & year <= 2008
		matrix sample_stats[`row',1] = r(mean)
		qui sum `var' [aw = hinswt] if tn == 0 & year >= 2001 & year <= 2008
		matrix sample_stats[`row',2] = r(mean)
		local row = `row' + 1
	}

	local row = `row' + 1

	foreach var in working hrs_lw_lt20 hrs_lw_2035 hrs_lw_ge35 {
		qui sum `var' [aw = wtsupp] if tn == 1 & year >= 2000 & year <= 2007
		matrix sample_stats[`row',1] = r(mean)
		qui sum `var' [aw = wtsupp] if tn == 0 & year >= 2000 & year <= 2007
		matrix sample_stats[`row',2] = r(mean)
		local row = `row' + 1
	}

	local row = `row' + 1

	foreach var in kid agebin female {
		qui sum `var' [aw = wtsupp] if tn == 1 & year >= 2000 & year <= 2007
		matrix sample_stats[`row',1] = r(mean)
		qui sum `var' [aw = wtsupp] if tn == 0 & year >= 2000 & year <= 2007
		matrix sample_stats[`row',2] = r(mean)
		local row = `row' + 1
	}

	local row = `row' + 1

	foreach var in hsd hsg any_college {
		qui sum `var' [aw = wtsupp] if tn == 1 & year >= 2000 & year <= 2007
		matrix sample_stats[`row',1] = r(mean)
		qui sum `var' [aw = wtsupp] if tn == 0 & year >= 2000 & year <= 2007
		matrix sample_stats[`row',2] = r(mean)
		local row = `row' + 1
	}

	local row = `row' + 1

	foreach var in white black other {
		qui sum `var' [aw = wtsupp] if tn == 1 & year >= 2000 & year <= 2007
		matrix sample_stats[`row',1] = r(mean)
		qui sum `var' [aw = wtsupp] if tn == 0 & year >= 2000 & year <= 2007
		matrix sample_stats[`row',2] = r(mean)
		local row = `row' + 1
	}

	clear
	svmat sample_stats
	list , clean

restore

** We drop variables here that were only used
** for this one sample statistics table.
drop race smc1 smc2 col hsd hsg 

************************************************************
**   Table II, difference-in-difference
************************************************************

if "`piece'" == "1" | "`piece'" == "all" {
	disp "The time is now: $S_TIME, $S_DATE"
	preserve

		keep if age >= 21 & age < 65
		keep if south == 1
		global Nclusters = 17

		matrix reg_results = J(8, 7, .)

		qui do fragment-run-our-bbs-procedure dd any_public 1 2000 2007 
		qui do fragment-run-our-bbs-procedure dd working 2 2000 2007 
		qui do fragment-run-our-bbs-procedure dd hrs_lw_lt20 3 2000 2007 
		qui do fragment-run-our-bbs-procedure dd hrs_lw_ge20 4 2000 2007 
		qui do fragment-run-our-bbs-procedure dd hrs_lw_2035 5 2000 2007 
		qui do fragment-run-our-bbs-procedure dd hrs_lw_ge35 6 2000 2007 
		qui do fragment-run-our-bbs-procedure dd any_empl_wk 7 2000 2007 

		clear
		svmat reg_results
		list, clean

	restore
	disp "The time is now: $S_TIME, $S_DATE"
}

************************************************************
**   Table II, triple-difference
************************************************************

if "`piece'" == "2" | "`piece'" == "all" {

	disp "The time is now: $S_TIME, $S_DATE"
	preserve

		keep if age >= 21 & age < 65
		keep if south == 1
		global Nclusters = 17

		sum year

		matrix reg_results = J(8, 7, .)

		qui do fragment-run-our-bbs-procedure ddd any_public 1 2000 2007
		qui do fragment-run-our-bbs-procedure ddd working 2 2000 2007
		qui do fragment-run-our-bbs-procedure ddd hrs_lw_lt20 3  2000 2007
		qui do fragment-run-our-bbs-procedure ddd hrs_lw_ge20 4 2000 2007
		qui do fragment-run-our-bbs-procedure ddd hrs_lw_2035 5  2000 2007
		qui do fragment-run-our-bbs-procedure ddd hrs_lw_ge35 6 2000 2007
		qui do fragment-run-our-bbs-procedure ddd any_empl_wk 7 2000 2007

		clear
		svmat reg_results
		list, clean

	restore
	disp "The time is now: $S_TIME, $S_DATE"
}


************************************************************
**   Table III
************************************************************

** Age:
if "`piece'" == "3" | "`piece'" == "all" {
	disp "The time is now: $S_TIME, $S_DATE"
	preserve

		keep if age >= 21 & age < 65
		keep if south == 1
		global Nclusters = 17

		sum year

		matrix reg_results = J(15, 7, .)

		qui do fragment-run-our-bbs-procedure agebin any_public 1 2000 2007
		qui do fragment-run-our-bbs-procedure agebin working 2 2000 2007
		qui do fragment-run-our-bbs-procedure agebin hrs_lw_lt20 3 2000 2007
		qui do fragment-run-our-bbs-procedure agebin hrs_lw_ge20 4 2000 2007
		qui do fragment-run-our-bbs-procedure agebin any_empl_wk 5 2000 2007

		clear
		svmat reg_results
		list, clean

	restore
	disp "The time is now: $S_TIME, $S_DATE"
}

** Education
if "`piece'" == "4" | "`piece'" == "all" {
	disp "The time is now: $S_TIME, $S_DATE"
	preserve

		keep if age >= 21 & age < 65
		keep if south == 1
		global Nclusters = 17

		sum year

		matrix reg_results = J(15, 7, .)

		qui do fragment-run-our-bbs-procedure educbin any_public 1 2000 2007
		qui do fragment-run-our-bbs-procedure educbin working 2 2000 2007
		qui do fragment-run-our-bbs-procedure educbin hrs_lw_lt20 3 2000 2007
		qui do fragment-run-our-bbs-procedure educbin hrs_lw_ge20 4 2000 2007
		qui do fragment-run-our-bbs-procedure educbin any_empl_wk 5 2000 2007

		clear
		svmat reg_results
		list, clean

	restore
	disp "The time is now: $S_TIME, $S_DATE"
}

** Health Status
if "`piece'" == "5" | "`piece'" == "all" {
	disp "The time is now: $S_TIME, $S_DATE"
	preserve

		keep if age >= 21 & age < 65
		keep if south == 1
		global Nclusters = 17

		sum year

		matrix reg_results = J(15, 7, .)

		qui do fragment-run-our-bbs-procedure ourhealthbin any_public 1 2000 2007 
		qui do fragment-run-our-bbs-procedure ourhealthbin working 2 2000 2007 
		qui do fragment-run-our-bbs-procedure ourhealthbin hrs_lw_lt20 3 2000 2007 
		qui do fragment-run-our-bbs-procedure ourhealthbin hrs_lw_ge20 4 2000 2007 
		qui do fragment-run-our-bbs-procedure ourhealthbin any_empl_wk 5 2000 2007 

		clear
		svmat reg_results
		list, clean

	restore
	disp "The time is now: $S_TIME, $S_DATE"
}

************************************************************
**   Table IV, Panel A
************************************************************

if "`piece'" == "6" | "`piece'" == "all" {

	disp "The time is now: $S_TIME, $S_DATE"
	preserve

		keep if age >= 21 & age < 65
		keep if south == 1
		global Nclusters = 17

		matrix reg_results = J(8, 7, .)

		qui do fragment-run-our-bbs-procedure dd wage 1 2000 2007
		qui do fragment-run-our-bbs-procedure dd wage_resid 2 2000 2007

		clear
		svmat reg_results
		list, clean

	restore
	disp "The time is now: $S_TIME, $S_DATE"
}

************************************************************
**   Table IV, Panel B
************************************************************

if "`piece'" == "7" | "`piece'" == "all" {
	disp "The time is now: $S_TIME, $S_DATE"
	preserve

		keep if age >= 21 & age < 65
		keep if south == 1
		global Nclusters = 17

		sum year

		matrix reg_results = J(8, 7, .)

		qui do fragment-run-our-bbs-procedure ddd unemp 1 2000 2007
		qui do fragment-run-our-bbs-procedure ddd ilf 2 2000 2007

		clear
		svmat reg_results
		list, clean

	restore
	disp "The time is now: $S_TIME, $S_DATE"
}

************************************************************
**   Table V, difference-in-difference
************************************************************

if "`piece'" == "8" | "`piece'" == "all" {

	disp "The time is now: $S_TIME, $S_DATE"
	preserve

		keep if age >= 21 & age < 65
		keep if south == 1
		global Nclusters = 17

		matrix reg_results = J(8, 7, .)

		qui do fragment-run-our-bbs-procedure dd any_public 1 2000 2007
		qui do fragment-run-our-bbs-procedure dd working 2 2000 2007
		qui do fragment-run-our-bbs-procedure dd any_private 3 2000 2007

		clear
		svmat reg_results
		list, clean

	restore
	disp "The time is now: $S_TIME, $S_DATE"
}

************************************************************
**   Table V, triple-difference
************************************************************

if "`piece'" == "9" | "`piece'" == "all" {
	disp "The time is now: $S_TIME, $S_DATE"
	preserve

		keep if age >= 21 & age < 65
		keep if south == 1
		global Nclusters = 17

		matrix reg_results = J(8, 7, .)

		qui do fragment-run-our-bbs-procedure ddd any_public 1 2000 2007
		qui do fragment-run-our-bbs-procedure ddd working 2 2000 2007
		qui do fragment-run-our-bbs-procedure ddd any_private 3  2000 2007

		clear
		svmat reg_results
		list, clean

	restore
	disp "The time is now: $S_TIME, $S_DATE"
}



log close
exit
