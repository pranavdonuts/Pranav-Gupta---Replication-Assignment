#delim cr
set more off
version 12
pause on
graph set ps logo off

capture log close
set linesize 180
set logtype text
log using  ../log/recover-all-ddd-estimates.log , replace

/* --------------------------------------

This program recovers just one of
our appendix tables. It recovers all triple-difference
estimates, and provides bootstrapped standard errors.

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
gen byte nokid = (1 - kid)

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

d, f

keep ///
female agebin educbin ourhealthbin tradhealthbin age ///
south statefip year tn post nokid ///
any_public any_empl_wk working any_private wage* hrs_lw* unemp ilf  ///
any_empl any_noempl_wk any_nocov_wk any_ind ///
hrswork ///
wtsupp hinswt 

compress

************************************************************
**   Impose restrictions for this table
************************************************************

keep if south == 1
keep if age >= 21 & age <= 64

************************************************************
************************************************************
**   Define program to get us those estimates
************************************************************
************************************************************

************************************************************
**   First we define our collapse statement
************************************************************

capture program drop our_collapse
program define our_collapse 

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

	gen byte post = (year >= 2006)

	keep if year >= 2000 & year <= 2007
end

************************************************************
**   Define bootstrap procedure
************************************************************

capture program drop bs_this
program define bs_this

	args outcome colnumber 

	**   Prepare for iterations

	tempfile original_data
	save `original_data'

	qui xi 

	rename statefip statefip_orig

	tempfile microdata
	save `microdata'

	bys statefip year: gen myn = _n
	isid statefip year myn
	sort statefip year myn

	tempfile microdata_with_myn
	save `microdata_with_myn'

	local number_of_iterations = 1000
	matrix bs_results = J(`number_of_iterations', 5, .)

	**   Iterate!

	forvalues i = 1/`number_of_iterations' {

		** For this iteration, we start with the raw micro-data
		drop _all
		use `microdata'

		** We then block-bootstrap
		** Note that we create a new, pseudo-state-identifier,
		** statefip
		bsample, idcluster(statefip) cluster(statefip_orig)

		** If Tennessee is not selected to be in the sample, then
		** we stop here.
		qui count if statefip_orig == 47

		if (r(N) > 0) {

			** This is how we bootstrap the micro-data
			** within each state. 
			bys statefip year: gen myN = _N
			gen myn = 1 + floor(myN*uniform())
			keep statefip statefip_orig year myn
			sort statefip_orig year myn
			qui merge m:1 statefip_orig year myn using `microdata_with_myn'
			assert _merge != 1
			qui keep if _merge == 3

			drop statefip_orig

			qui our_collapse 

			gen byte tn_X_post_X_nokid = tn * post * nokid
			gen byte tn_X_post = tn * post
			gen byte tn_X_nokid = tn * nokid
			gen byte post_X_nokid = post * nokid

			qui xi i.year i.statefip i.nokid 
			*qui xi i.year*i.statefip i.year*i.nokid i.nokid*i.statefip

			qui reg `outcome' tn_X_post_X_nokid tn_X_post tn_X_nokid post_X_nokid _I*, 

			qui matrix bs_results[`i', 1] = _b[tn_X_post_X_nokid]
			qui matrix bs_results[`i', 2] = _b[tn_X_post]
			qui matrix bs_results[`i', 3] = _b[tn_X_nokid]
			qui matrix bs_results[`i', 4] = _b[post_X_nokid]
		}
	}

	** We now calculate the boostrapped standard error of the estimate
	drop _all
	svmat bs_results

	summ bs_results1
	local bs_tn_X_post_X_nokid = r(sd)

	summ bs_results2
	local bs_tn_X_post = r(sd)

	summ bs_results3
	local bs_tn_X_nokid = r(sd)

	summ bs_results4
	local bs_post_X_nokid = r(sd)

	** We now run the regression on the original (non-re-sampled) data    

	use `original_data' , clear

	our_collapse 

	qui xi i.year i.statefip i.nokid 
	*qui xi i.year*i.statefip i.year*i.nokid i.nokid*i.statefip

	gen byte tn_X_post_X_nokid = tn * post * nokid
	gen byte tn_X_post = tn * post
	gen byte tn_X_nokid = tn * nokid
	gen byte post_X_nokid = post * nokid

	reg `outcome' tn_X_post_X_nokid tn_X_post tn_X_nokid post_X_nokid _I*, 

	local raw_tn_X_post_X_nokid = _b[tn_X_post_X_nokid]
	local raw_tn_X_post = _b[tn_X_post]
	local raw_tn_X_nokid = _b[tn_X_nokid]
	local raw_post_X_nokid = _b[post_X_nokid]

	** Save out key statistics for regular models

	qui matrix reg_results[1, `colnumber'] = `raw_tn_X_post_X_nokid'
	qui matrix reg_results[2, `colnumber'] = `bs_tn_X_post_X_nokid'
	qui matrix reg_results[3, `colnumber'] = 2*abs( ttail(`e(df_r)', abs( `raw_tn_X_post_X_nokid' ) / `bs_tn_X_post_X_nokid' ) ) 

	qui matrix reg_results[5, `colnumber'] = `raw_tn_X_post'
	qui matrix reg_results[6, `colnumber'] = `bs_tn_X_post'
	qui matrix reg_results[7, `colnumber'] = 2*abs( ttail(`e(df_r)', abs( `raw_tn_X_post' ) / `bs_tn_X_post' ) ) 

	qui matrix reg_results[9, `colnumber'] = `raw_tn_X_nokid' 
	qui matrix reg_results[10, `colnumber'] = `bs_tn_X_nokid' 
	qui matrix reg_results[11, `colnumber'] = 2*abs( ttail(`e(df_r)', abs( `raw_tn_X_nokid' ) / `bs_tn_X_nokid' ) ) 

	qui matrix reg_results[13, `colnumber'] = `raw_post_X_nokid'
	qui matrix reg_results[14, `colnumber'] = `bs_post_X_nokid'
	qui matrix reg_results[15, `colnumber'] = 2*abs( ttail(`e(df_r)', abs( `raw_post_X_nokid' ) / `bs_post_X_nokid' ) ) 

	qui matrix reg_results[17, `colnumber'] = `e(r2)'

	** Finally, go back to original data    

	use `original_data' , clear

end

************************************************************
************************************************************
**   Go back to regularly-scheduled program
************************************************************
************************************************************

************************************************************
**   Public-Private Table, difference-in-difference, FP
************************************************************

preserve

	matrix reg_results = J(17, 7, .)

	qui bs_this any_public 1 
	qui bs_this any_private 2 
	qui bs_this working 3 

	clear
	svmat reg_results
	list, clean

restore





log close
exit
