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
log using  ../log/run-cps-appendix-tables-piece-`piece'.log , replace

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
global Niterations = 30

************************************************************
**   Prepare CPS outcomes
************************************************************

**
** Option 13, below, prepares the micro data, and does nothing else.
**
*do fragment-prepare-cps-data.do 13
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
south statefip year tn post nokid own_kid ///
any_public any_mcaid any_empl_wk working* any_private wage* hrs_lw* unemp ilf  ///
any_empl any_noempl_wk any_nocov_wk any_ind ///
hrswork ///
wtsupp hinswt ///
race smc1 smc2 col hsd hsg 

compress

************************************************************
**   Appendix Coverage Table, FP
************************************************************

if "`piece'" == "1" | "`piece'" == "all" {

	disp "The time is now: $S_TIME, $S_DATE"
	preserve

		keep if age >= 21 & age < 65
		keep if south == 1
		global Nclusters = 17

		matrix reg_results = J(8, 7, .)

		qui do fragment-run-our-bbs-procedure ddd any_empl 1 2000 2007
		qui do fragment-run-our-bbs-procedure ddd any_noempl_wk 2 2000 2007
		qui do fragment-run-our-bbs-procedure ddd any_nocov_wk 3 2000 2007
		qui do fragment-run-our-bbs-procedure ddd any_ind 4 2000 2007

		clear
		svmat reg_results
		list, clean

	restore
	disp "The time is now: $S_TIME, $S_DATE"
}

************************************************************
**   Referee Table on traditional health grouping, FP
************************************************************

** Health Status, coded "traditionally"
if "`piece'" == "2" | "`piece'" == "all" {
	disp "The time is now: $S_TIME, $S_DATE"
	preserve

		keep if age >= 21 & age < 65
		keep if south == 1
		global Nclusters = 17

		sum year

		matrix reg_results = J(15, 7, .)

		qui do fragment-run-our-bbs-procedure tradhealthbin any_public 1 2000 2007
		qui do fragment-run-our-bbs-procedure tradhealthbin working 2 2000 2007
		qui do fragment-run-our-bbs-procedure tradhealthbin hrs_lw_lt20 3  2000 2007
		qui do fragment-run-our-bbs-procedure tradhealthbin hrs_lw_ge20 4  2000 2007
		qui do fragment-run-our-bbs-procedure tradhealthbin any_empl_wk 5  2000 2007

		clear
		svmat reg_results
		list, clean

	restore
	disp "The time is now: $S_TIME, $S_DATE"
}

************************************************************
**   Appendix Table for Alternative Samples Table, FP
************************************************************

** Baseline Sample
if "`piece'" == "3" | "`piece'" == "all" {
	disp "The time is now: $S_TIME, $S_DATE"
	preserve

		keep if south == 1
		global Nclusters = 17
		keep if age >= 21 & age < 65

		matrix reg_results = J(9, 9, .)

		qui do fragment-run-our-bbs-procedure ddd any_public 1 2000 2007
		qui do fragment-run-our-bbs-procedure ddd working 2 2000 2007
		qui do fragment-run-our-bbs-procedure ddd hrs_lw_lt20 3  2000 2007
		qui do fragment-run-our-bbs-procedure ddd hrs_lw_ge20 4  2000 2007
		qui do fragment-run-our-bbs-procedure ddd hrs_lw_2035 5  2000 2007
		qui do fragment-run-our-bbs-procedure ddd hrs_lw_ge35 6  2000 2007
		qui do fragment-run-our-bbs-procedure ddd any_private 7  2000 2007

		clear
		svmat reg_results
		list, clean

	restore
	disp "The time is now: $S_TIME, $S_DATE"
}

** 2000-2007; All States
if "`piece'" == "4" | "`piece'" == "all" {
	disp "The time is now: $S_TIME, $S_DATE"
	preserve

		global Nclusters = 50
		keep if age >= 21 & age < 65

		matrix reg_results = J(9, 9, .)

		qui do fragment-run-our-bbs-procedure ddd any_public 1 2000 2007
		qui do fragment-run-our-bbs-procedure ddd working 2 2000 2007
		qui do fragment-run-our-bbs-procedure ddd hrs_lw_lt20 3  2000 2007
		qui do fragment-run-our-bbs-procedure ddd hrs_lw_ge20 4  2000 2007
		qui do fragment-run-our-bbs-procedure ddd hrs_lw_2035 5  2000 2007
		qui do fragment-run-our-bbs-procedure ddd hrs_lw_ge35 6  2000 2007
		qui do fragment-run-our-bbs-procedure ddd any_private 7  2000 2007

		clear
		svmat reg_results
		list, clean

	restore
	disp "The time is now: $S_TIME, $S_DATE"
}

** 2000-2011; South Only
if "`piece'" == "5" | "`piece'" == "all" {
	disp "The time is now: $S_TIME, $S_DATE"
	preserve

		keep if age >= 21 & age < 65
		keep if south == 1
		global Nclusters = 17

		matrix reg_results = J(9, 9, .)

		qui do fragment-run-our-bbs-procedure ddd any_public 1 2000 2011
		qui do fragment-run-our-bbs-procedure ddd working 2 2000 2011
		qui do fragment-run-our-bbs-procedure ddd hrs_lw_lt20 3  2000 2011
		qui do fragment-run-our-bbs-procedure ddd hrs_lw_ge20 4  2000 2011
		qui do fragment-run-our-bbs-procedure ddd hrs_lw_2035 5  2000 2011
		qui do fragment-run-our-bbs-procedure ddd hrs_lw_ge35 6  2000 2011
		qui do fragment-run-our-bbs-procedure ddd any_private 7  2000 2011

		clear
		svmat reg_results
		list, clean

	restore
	disp "The time is now: $S_TIME, $S_DATE"
}

** 2003-2007; South Only
if "`piece'" == "6" | "`piece'" == "all" {
	disp "The time is now: $S_TIME, $S_DATE"
	preserve

		keep if age >= 21 & age < 65
		keep if south == 1
		global Nclusters = 17

		matrix reg_results = J(9, 9, .)

		qui do fragment-run-our-bbs-procedure ddd any_public 1 2003 2011
		qui do fragment-run-our-bbs-procedure ddd working 2 2003 2011
		qui do fragment-run-our-bbs-procedure ddd hrs_lw_lt20 3  2003 2011
		qui do fragment-run-our-bbs-procedure ddd hrs_lw_ge20 4  2003 2011
		qui do fragment-run-our-bbs-procedure ddd hrs_lw_2035 5  2003 2011
		qui do fragment-run-our-bbs-procedure ddd hrs_lw_ge35 6  2003 2011
		qui do fragment-run-our-bbs-procedure ddd any_private 7  2003 2011

		clear
		svmat reg_results
		list, clean

	restore
	disp "The time is now: $S_TIME, $S_DATE"
}

************************************************************
**   Appendix Table, Those over 65, FP
************************************************************

if "`piece'" == "7" | "`piece'" == "all" {

	** First for our baseline sample:
	disp "The time is now: $S_TIME, $S_DATE"
	preserve

		keep if age >= 21 & age < 65
		keep if south == 1
		global Nclusters = 17

		matrix reg_results = J(8, 7, .)

		qui do fragment-run-our-bbs-procedure dd any_public 1 2000 2007
		qui do fragment-run-our-bbs-procedure dd working 2 2000 2007 

		clear
		svmat reg_results
		list, clean

	restore
	disp "The time is now: $S_TIME, $S_DATE"

	** Then for those older than 65:
	disp "The time is now: $S_TIME, $S_DATE"
	preserve

		keep if age >= 66
		keep if south == 1
		global Nclusters = 17

		matrix reg_results = J(8, 7, .)

		qui do fragment-run-our-bbs-procedure dd any_public 1 2000 2007
		qui do fragment-run-our-bbs-procedure dd working 2 2000 2007

		clear
		svmat reg_results
		list, clean

	restore
	disp "The time is now: $S_TIME, $S_DATE"
}

************************************************************
**   Try to look at older respondents
************************************************************

** Age:
if "`piece'" == "8" | "`piece'" == "all" {
	disp "The time is now: $S_TIME, $S_DATE"
	preserve

		keep if age >= 21 & age < 65
		keep if south == 1
		global Nclusters = 17

		sum year

		matrix reg_results = J(15, 7, .)

		qui do fragment-run-our-bbs-procedure age5564 any_public 1 2000 2007
		qui do fragment-run-our-bbs-procedure age5564 working 2 2000 2007
		qui do fragment-run-our-bbs-procedure age5564 any_empl_wk 3 2000 2007
		qui do fragment-run-our-bbs-procedure age5564 any_private 4 2000 2007

		clear
		svmat reg_results
		list, clean

	restore
	disp "The time is now: $S_TIME, $S_DATE"
}

************************************************************
**   Try public-private table, recording individ. market, ddd
************************************************************

if "`piece'" == "9" | "`piece'" == "all" {
	disp "The time is now: $S_TIME, $S_DATE"
	preserve

		global Nclusters = 17

		keep if age >= 21 & age < 65
		keep if south == 1

		** We experiment here by assuming that those who
		** report individual coverage were actually Medicaid 
		** recipients.
		sum any_private any_public
		replace any_private = 1 if any_ind == 1
		sum any_private any_public

		matrix reg_results = J(8, 7, .)

		qui do fragment-run-our-bbs-procedure ddd any_public 1 2000 2007
		qui do fragment-run-our-bbs-procedure ddd working 2 2000 2007
		qui do fragment-run-our-bbs-procedure ddd any_empl_wk 3  2000 2007
		qui do fragment-run-our-bbs-procedure ddd any_private 4  2000 2007

		clear
		svmat reg_results
		list, clean

	restore
	disp "The time is now: $S_TIME, $S_DATE"
}

************************************************************
**   Run appendix heterogeneity table, FP
************************************************************

** Age:
if "`piece'" == "10" | "`piece'" == "all" {
	disp "The time is now: $S_TIME, $S_DATE"
	preserve

		keep if age >= 21 & age < 65
		keep if south == 1
		global Nclusters = 17

		sum year

		matrix reg_results = J(15, 7, .)

		qui do fragment-run-our-bbs-procedure agebin any_public 1 2000 2007
		qui do fragment-run-our-bbs-procedure agebin any_private 2 2000 2007

		clear
		svmat reg_results
		list, clean

	restore
	disp "The time is now: $S_TIME, $S_DATE"
}

** Education
if "`piece'" == "11" | "`piece'" == "all" {
	disp "The time is now: $S_TIME, $S_DATE"
	preserve

		keep if age >= 21 & age < 65
		keep if south == 1
		global Nclusters = 17

		sum year

		matrix reg_results = J(15, 7, .)

		qui do fragment-run-our-bbs-procedure educbin any_public 1 2000 2007
		qui do fragment-run-our-bbs-procedure educbin any_private 2 2000 2007

		clear
		svmat reg_results
		list, clean

	restore
	disp "The time is now: $S_TIME, $S_DATE"
}

** Health Status
if "`piece'" == "12" | "`piece'" == "all" {
	disp "The time is now: $S_TIME, $S_DATE"
	preserve

		keep if age >= 21 & age < 65
		keep if south == 1
		global Nclusters = 17

		sum year

		matrix reg_results = J(15, 7, .)

		qui do fragment-run-our-bbs-procedure ourhealthbin any_public 1 2000 2007 
		qui do fragment-run-our-bbs-procedure ourhealthbin any_private 2 2000 2007 

		clear
		svmat reg_results
		list, clean

	restore
	disp "The time is now: $S_TIME, $S_DATE"
}

************************************************************
**   Run gender appendix table, FP
************************************************************

** Gender
if "`piece'" == "13" | "`piece'" == "all" {
	disp "The time is now: $S_TIME, $S_DATE"
	preserve

		keep if age >= 21 & age < 65
		keep if south == 1
		global Nclusters = 17

		sum year

		matrix reg_results = J(15, 8, .)

		qui do fragment-run-our-bbs-procedure female any_public 1 2000 2007 
		qui do fragment-run-our-bbs-procedure female working 2 2000 2007 
		qui do fragment-run-our-bbs-procedure female hrs_lw_lt20 3 2000 2007 
		qui do fragment-run-our-bbs-procedure female hrs_lw_ge20 4 2000 2007 
		qui do fragment-run-our-bbs-procedure female any_empl_wk 5 2000 2007 

		qui do fragment-run-our-bbs-procedure female any_public 6 2000 2007 
		qui do fragment-run-our-bbs-procedure female any_private 7 2000 2007 

		clear
		svmat reg_results
		list, clean

	restore
	disp "The time is now: $S_TIME, $S_DATE"
}

************************************************************
**   Look at employer-provided insurance by age
************************************************************

** Craig wants to look at employer-provided insurance
** in the heterogeneity table, Age.
** Age:

if "`piece'" == "14" | "`piece'" == "all" {
	disp "The time is now: $S_TIME, $S_DATE"
	preserve

		keep if age >= 21 & age < 65
		keep if south == 1
		global Nclusters = 17

		sum year

		matrix reg_results = J(15, 4, .)

		qui do fragment-run-our-bbs-procedure agebin any_empl 1 2000 2007
		qui do fragment-run-our-bbs-procedure agebin any_noempl_wk 2 2000 2007
		qui do fragment-run-our-bbs-procedure agebin any_nocov_wk 3 2000 2007
		qui do fragment-run-our-bbs-procedure agebin any_ind 4 2000 2007

		clear
		svmat reg_results
		list, clean

	restore
	disp "The time is now: $S_TIME, $S_DATE"
}


************************************************************
**   Appendix Table: Experiment with status of individual insurance
************************************************************

** We assign private non-group to private coverage

if "`piece'" == "15" | "`piece'" == "all" {
	disp "The time is now: $S_TIME, $S_DATE"
	preserve

		keep if age >= 21 & age < 65
		keep if south == 1
		global Nclusters = 17

		sum year

		replace any_private = 1 if any_ind == 1
		replace any_public = 0 if any_ind == 1

		matrix reg_results = J(15, 4, .)

		qui do fragment-run-our-bbs-procedure ddd any_public 1 2000 2007
		qui do fragment-run-our-bbs-procedure ddd any_private 2 2000 2007

		clear
		svmat reg_results
		list, clean

	restore
	disp "The time is now: $S_TIME, $S_DATE"
}

** Second, we assign private non-group to private coverage

if "`piece'" == "16" | "`piece'" == "all" {
	disp "The time is now: $S_TIME, $S_DATE"
	preserve

		keep if age >= 21 & age < 65
		keep if south == 1
		global Nclusters = 17

		sum year

		replace any_private = 0 if any_ind == 1
		replace any_public = 1 if any_ind == 1

		matrix reg_results = J(15, 4, .)

		qui do fragment-run-our-bbs-procedure ddd any_public 1 2000 2007
		qui do fragment-run-our-bbs-procedure ddd any_private 2 2000 2007

		clear
		svmat reg_results
		list, clean

	restore
	disp "The time is now: $S_TIME, $S_DATE"
}

**
** Alt "no kids" definition using "own kids"
**
if "`piece'" == "17" | "`piece'" == "all" {
	disp "The time is now: $S_TIME, $S_DATE"
	preserve

		keep if age >= 21 & age < 65 
		keep if south == 1
		keep if year >= 2000 & year <= 2008
		global Nclusters = 17

		matrix reg_results = J(15, 7, .)

		replace nokid = (1 - own_kid)

		do fragment-run-our-bbs-procedure ddd any_public 1 2000 2007
		qui do fragment-run-our-bbs-procedure ddd working 2 2000 2007
		qui do fragment-run-our-bbs-procedure ddd hrs_lw_lt20 3  2000 2007
		qui do fragment-run-our-bbs-procedure ddd hrs_lw_ge20 4  2000 2007
		qui do fragment-run-our-bbs-procedure ddd hrs_lw_2035 5  2000 2007
		qui do fragment-run-our-bbs-procedure ddd hrs_lw_ge35 6  2000 2007

		clear
		svmat reg_results
		list, clean

	restore
	disp "The time is now: $S_TIME, $S_DATE"
}

**
** Alternative public h.i. definition using alternative variable
**  ("any Medicaid" instead of "any public health insurance")
**
if "`piece'" == "18" | "`piece'" == "all" {
	disp "The time is now: $S_TIME, $S_DATE"
	preserve

		keep if age >= 21 & age < 65
		keep if south == 1
		keep if year >= 2000 & year <= 2008
		global Nclusters = 17

		matrix reg_results = J(15, 4, .)

		qui do fragment-run-our-bbs-procedure dd any_public 1 2000 2007
		qui do fragment-run-our-bbs-procedure dd any_mcaid 2 2000 2007

		qui do fragment-run-our-bbs-procedure ddd any_public 3 2000 2007
		qui do fragment-run-our-bbs-procedure ddd any_mcaid 4 2000 2007

		clear
		svmat reg_results
		list, clean

	restore
	disp "The time is now: $S_TIME, $S_DATE"
}

**
** Alternative definition of working (including those not at work)
**  (DDD)
**
if "`piece'" == "19" | "`piece'" == "all" {
	disp "The time is now: $S_TIME, $S_DATE"
	preserve

		keep if age >= 21 & age < 65
		keep if south == 1
		keep if year >= 2000 & year <= 2008
		global Nclusters = 17

		matrix reg_results = J(15, 7, .)

		replace working = working_alt
		
		qui do fragment-run-our-bbs-procedure ddd any_public 1 2000 2007
		qui do fragment-run-our-bbs-procedure ddd working 2 2000 2007
		qui do fragment-run-our-bbs-procedure ddd hrs_lw_lt20 3  2000 2007
		qui do fragment-run-our-bbs-procedure ddd hrs_lw_ge20 4  2000 2007
		qui do fragment-run-our-bbs-procedure ddd hrs_lw_2035 5  2000 2007
		qui do fragment-run-our-bbs-procedure ddd hrs_lw_ge35 6  2000 2007

		clear
		svmat reg_results
		list, clean

	restore
	disp "The time is now: $S_TIME, $S_DATE"
}

**
** Alternative definition of working (including those not at work)
**  (DD)
**
if "`piece'" == "20" | "`piece'" == "all" {
	disp "The time is now: $S_TIME, $S_DATE"
	preserve

		keep if age >= 21 & age < 65
		keep if south == 1
		keep if year >= 2000 & year <= 2008
		global Nclusters = 17

		matrix reg_results = J(15, 7, .)

		replace working = working_alt
		
		qui do fragment-run-our-bbs-procedure dd any_public 1 2000 2007
		qui do fragment-run-our-bbs-procedure dd working 2 2000 2007
		qui do fragment-run-our-bbs-procedure dd hrs_lw_lt20 3  2000 2007
		qui do fragment-run-our-bbs-procedure dd hrs_lw_ge20 4  2000 2007
		qui do fragment-run-our-bbs-procedure dd hrs_lw_2035 5  2000 2007
		qui do fragment-run-our-bbs-procedure dd hrs_lw_ge35 6  2000 2007

		clear
		svmat reg_results
		list, clean

	restore
	disp "The time is now: $S_TIME, $S_DATE"
}



log close
exit





************************************************************
**   Split up Step 4 Above
************************************************************

** We can delete this section eventually, as it is redundant.
** Piece 4, above, takes too long to run on its own. So, instead, 
** we run it in pieces, as follows.
if "`piece'" == "101" | "`piece'" == "all" {
	disp "The time is now: $S_TIME, $S_DATE"
	preserve

		global Nclusters = 50
		keep if age >= 21 & age < 65

		matrix reg_results = J(9, 9, .)

		qui do fragment-run-our-bbs-procedure ddd any_public 1 2000 2007

		clear
		svmat reg_results
		list, clean

	restore
	disp "The time is now: $S_TIME, $S_DATE"
}
if "`piece'" == "102" | "`piece'" == "all" {
	disp "The time is now: $S_TIME, $S_DATE"
	preserve

		global Nclusters = 50
		keep if age >= 21 & age < 65

		matrix reg_results = J(9, 9, .)

		qui do fragment-run-our-bbs-procedure ddd working 1 2000 2007

		clear
		svmat reg_results
		list, clean

	restore
	disp "The time is now: $S_TIME, $S_DATE"
}
if "`piece'" == "103" | "`piece'" == "all" {
	disp "The time is now: $S_TIME, $S_DATE"
	preserve

		global Nclusters = 50
		keep if age >= 21 & age < 65

		matrix reg_results = J(9, 9, .)

		qui do fragment-run-our-bbs-procedure ddd hrs_lw_lt20 1 2000 2007

		clear
		svmat reg_results
		list, clean

	restore
	disp "The time is now: $S_TIME, $S_DATE"
}
if "`piece'" == "104" | "`piece'" == "all" {
	disp "The time is now: $S_TIME, $S_DATE"
	preserve

		global Nclusters = 50
		keep if age >= 21 & age < 65

		matrix reg_results = J(9, 9, .)

		qui do fragment-run-our-bbs-procedure ddd hrs_lw_ge20 1 2000 2007

		clear
		svmat reg_results
		list, clean

	restore
	disp "The time is now: $S_TIME, $S_DATE"
}
if "`piece'" == "105" | "`piece'" == "all" {
	disp "The time is now: $S_TIME, $S_DATE"
	preserve

		global Nclusters = 50
		keep if age >= 21 & age < 65

		matrix reg_results = J(9, 9, .)

		qui do fragment-run-our-bbs-procedure ddd hrs_lw_2035 1 2000 2007

		clear
		svmat reg_results
		list, clean

	restore
	disp "The time is now: $S_TIME, $S_DATE"
}
if "`piece'" == "106" | "`piece'" == "all" {
	disp "The time is now: $S_TIME, $S_DATE"
	preserve

		global Nclusters = 50
		keep if age >= 21 & age < 65

		matrix reg_results = J(9, 9, .)

		qui do fragment-run-our-bbs-procedure ddd hrs_lw_ge35 1 2000 2007

		clear
		svmat reg_results
		list, clean

	restore
	disp "The time is now: $S_TIME, $S_DATE"
}
if "`piece'" == "107" | "`piece'" == "all" {
	disp "The time is now: $S_TIME, $S_DATE"
	preserve

		global Nclusters = 50
		keep if age >= 21 & age < 65

		matrix reg_results = J(9, 9, .)

		qui do fragment-run-our-bbs-procedure ddd any_private 1 2000 2007

		clear
		svmat reg_results
		list, clean

	restore
	disp "The time is now: $S_TIME, $S_DATE"
}




log close
exit
