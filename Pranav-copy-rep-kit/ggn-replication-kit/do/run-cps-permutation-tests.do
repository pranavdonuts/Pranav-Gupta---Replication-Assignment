#delim cr
set more off
version 12
pause on
graph set ps logo off

capture log close
set linesize 180
set logtype text
log using  ../log/run-cps-permutation-tests.log , replace

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

************************************************************
**   Prepare CPS outcomes
************************************************************

** Option 13, below, prepares the micro data, and does nothing
** else.

do fragment-prepare-cps-data.do 13

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
**   Run a difference-in-difference permutation test
************************************************************

** Here we run a permutation test. This is an attempt to calculate
** standard errors without making any parametric assumptions.

tempfile preperm2
save `preperm2'

keep if age >= 21 & age < 65
keep if south == 1
global year0 = 2000
global year1 = 2007

our_collapse dd

isid statefip year
codebook statefip year

foreach outcome in any_public working hrs_lw_lt20 hrs_lw_ge20 hrs_lw_2035 hrs_lw_ge35 {

	disp " "
	disp " "
	disp " "
	disp " "
	disp "Now studying outcome `outcome' "

	matrix permutation_results = J(300, 4, 0)
	local row = 1

	preserve

		qui xi i.year i.statefip 

		foreach state_loop in 54 24 10 11 21 47 37 51 45 13 5 22 48 40 1 28 12 {
			foreach year_loop in 2001 2002 2003 2004 2005 2006 {

				gen byte dd_variable = (statefip == `state_loop') * (year >= `year_loop')

				qui reg `outcome' dd_variable _I* , cluster(statefip)
				if (`state_loop' == 47 & `year_loop' == 2006) {
					local result = _b[dd_variable]
					local result_se = _se[dd_variable]
					disp "For outcome `outcome', our main point estimate is `result' with standard error `result_se'"
				}
				
				matrix permutation_results[`row', 1] = `state_loop'
				matrix permutation_results[`row', 2] = `year_loop'
				matrix permutation_results[`row', 3] = _b[dd_variable]

				local row = `row' + 1 
				drop dd_variable

			}
		}

		qui drop _all
		qui svmat permutation_results
		rename permutation_results1 state
		rename permutation_results2 year
		rename permutation_results3 dd_estimate
		qui drop if state == 0

		gen byte our_estimate = (state == 47 & year == 2006)

		disp "The rank of our estimate is: "
		sort dd_estimate
		qui gen rank = _n
		sum rank if our_estimate == 1
		local rank = `r(mean)'
		qui count 
		local denominator = `r(N)'
		local rank_based_pvalue = `rank' / `denominator'
		local reverse_rank_based_pvalue = (`denominator' - `rank') / `denominator'
		disp "Rank-based p-value is: `rank_based_pvalue'"
		disp "Reverse rank-based p-value is: `reverse_rank_based_pvalue'"

	restore
}

use `preperm2' , clear

************************************************************
**   Run a triple-difference permutation test
************************************************************

** Here we run a permutation test. This is an attempt to calculate
** standard errors without making any parametric assumptions.

tempfile preperm2
save `preperm2'

keep if age >= 21 & age < 65
keep if south == 1
global year0 = 2000
global year1 = 2007

our_collapse ddd

foreach outcome in any_public working hrs_lw_lt20 hrs_lw_ge20 hrs_lw_2035 hrs_lw_ge35 {

	disp " "
	disp " "
	disp " "
	disp " "
	disp "Now studying outcome `outcome' "

	matrix permutation_results = J(300, 4, 0)
	local row = 1

	preserve

		qui xi i.year*i.statefip i.year*i.nokid i.nokid*i.statefip

		gen byte kid = 1 - nokid

		foreach group_loop in 0 1 {
			foreach state_loop in 54 24 10 11 21 47 37 51 45 13 5 22 48 40 1 28 12 {
				foreach year_loop in 2001 2002 2003 2004 2005 2006 {

					gen byte ddd_variable = (kid == `group_loop') * (statefip == `state_loop') * (year >= `year_loop')

					qui reg `outcome' ddd_variable _I* , cluster(statefip)
					if (`group_loop' == 0 & `state_loop' == 47 & `year_loop' == 2006) {
						local result = _b[ddd_variable]
						local result_se = _se[ddd_variable]
						disp "For outcome `outcome', our main point estimate is `result' with standard error `result_se'"
					}
					
					matrix permutation_results[`row', 1] = `group_loop'
					matrix permutation_results[`row', 2] = `state_loop'
					matrix permutation_results[`row', 3] = `year_loop'
					matrix permutation_results[`row', 4] = _b[ddd_variable]

					local row = `row' + 1 
					drop ddd_variable

				}
			}
		}

		qui drop _all
		qui svmat permutation_results
		rename permutation_results1 group
		rename permutation_results2 state
		rename permutation_results3 year
		rename permutation_results4 ddd_estimate
		qui drop if state == 0

		gen byte our_estimate = (group == 0 & state == 47 & year == 2006)

		replace ddd_estimate = . if state == 47 & our_estimate != 1

		disp "The rank of our estimate is: "
		sort ddd_estimate
		qui gen rank = _n
		sum rank if our_estimate == 1
		local rank = `r(mean)'
		qui count 
		local denominator = `r(N)'
		local rank_based_pvalue = `rank' / `denominator'
		local reverse_rank_based_pvalue = (`denominator' - `rank') / `denominator'
		disp "Rank-based p-value is: `rank_based_pvalue'"
		disp "Reverse rank-based p-value is: `reverse_rank_based_pvalue'"

	restore
}

use `preperm2' , clear


log close
exit
