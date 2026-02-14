#delim cr
set more off
version 12
pause on
graph set ps logo off

capture log close
set linesize 180
set logtype text
log using  ../log/run-individual-level-regressions.log , replace

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
south statefip year tn post nokid kid ///
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
**   Re-adjust health variables to be in year t - 1
************************************************************

keep if year <= 2008 & year >= 2000

global stats = "mean r2 N"

bys year statefip nokid: egen sum_wgt = sum(wtsupp)
gen wgt = wtsupp / sum_wgt
bys year statefip nokid: egen sum_hwgt = sum(hinswt)
gen hwgt = hinswt / sum_hwgt

************************************************************
************************************************************
**   Define program to get us those estimates
************************************************************
************************************************************

************************************************************
**   Define bootstrap procedure
************************************************************

capture program drop micro_bs_this
program define micro_bs_this

	args outcome colnumber model controls

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

			gen byte tn_X_post_X_nokid = tn * post * nokid

			if "`controls'" == "nocontrols" {
				if "`model'" == "health" {

					keep if year >= 2001 & year <= 2008

					qui xi i.year*i.statefip i.year*i.nokid i.nokid*i.statefip

					replace tn_X_post_X_nokid = (tn) * (nokid) * (year >= 2007)

					reg `outcome' tn_X_post_X_nokid _I* [aw = hwgt] , 
				}
				if "`model'" == "labor" {

					keep if year >= 2000 & year <= 2007

					qui xi i.year*i.statefip i.year*i.nokid i.nokid*i.statefip

					replace tn_X_post_X_nokid = 0
					replace tn_X_post_X_nokid = (tn) * (nokid) * (year >= 2006)

					reg `outcome' tn_X_post_X_nokid _I* [aw = wgt] , 
				}
			}
			if "`controls'" == "withcontrols" {
				if "`model'" == "health" {

					keep if year >= 2001 & year <= 2008

					qui xi i.year*i.statefip i.year*i.nokid i.nokid*i.statefip

					replace tn_X_post_X_nokid = (tn) * (nokid) * (year >= 2007)

					reg `outcome' tn_X_post_X_nokid $xvars _I* [aw = hwgt] , 
				}
				if "`model'" == "labor" {

					keep if year >= 2000 & year <= 2007

					qui xi i.year*i.statefip i.year*i.nokid i.nokid*i.statefip

					replace tn_X_post_X_nokid = 0
					replace tn_X_post_X_nokid = (tn) * (nokid) * (year >= 2006)

					reg `outcome' tn_X_post_X_nokid $xvars _I* [aw = wgt] , 
				}
			}

			qui matrix bs_results[`i', 1] = _b[tn_X_post_X_nokid]
		}
	}

	** We now calculate the boostrapped standard error of the estimate
	drop _all
	svmat bs_results

	summ bs_results1
	local bs_tn_X_post_X_nokid = r(sd)

	** We now run the regression on the original (non-re-sampled) data    

	use `original_data' , clear

	*qui xi i.year i.statefip i.nokid 
	qui xi i.year*i.statefip i.year*i.nokid i.nokid*i.statefip

	gen byte tn_X_post_X_nokid = tn * post * nokid

	if "`controls'" == "nocontrols" {
		if "`model'" == "health" {

			keep if year >= 2001 & year <= 2008

			qui xi i.year*i.statefip i.year*i.nokid i.nokid*i.statefip

			replace tn_X_post_X_nokid = 0
			replace tn_X_post_X_nokid = (statefip == 47) * (nokid) * (year >= 2007)

			reg `outcome' tn_X_post_X_nokid _I* [aw = hwgt] , 
		}
		if "`model'" == "labor" {

			keep if year >= 2000 & year <= 2007

			replace tn_X_post_X_nokid = 0
			replace tn_X_post_X_nokid = (statefip == 47) * (nokid) * (year >= 2006)

			qui xi i.year*i.statefip i.year*i.nokid i.nokid*i.statefip

			reg `outcome' tn_X_post_X_nokid _I* [aw = wgt] , 
		}
	}
	if "`controls'" == "withcontrols" {
		if "`model'" == "health" {

			keep if year >= 2001 & year <= 2008

			qui xi i.year*i.statefip i.year*i.nokid i.nokid*i.statefip

			replace tn_X_post_X_nokid = 0
			replace tn_X_post_X_nokid = (statefip == 47) * (nokid) * (year >= 2007)

			reg `outcome' tn_X_post_X_nokid $xvars _I* [aw = hwgt] , 
		}
		if "`model'" == "labor" {

			keep if year >= 2000 & year <= 2007

			replace tn_X_post_X_nokid = 0
			replace tn_X_post_X_nokid = (statefip == 47) * (nokid) * (year >= 2006)

			qui xi i.year*i.statefip i.year*i.nokid i.nokid*i.statefip

			reg `outcome' tn_X_post_X_nokid $xvars _I* [aw = wgt] , 
		}
	}

	local raw_tn_X_post_X_nokid = _b[tn_X_post_X_nokid]

	** Save out key statistics for regular models

	qui matrix reg_results[1, `colnumber'] = `raw_tn_X_post_X_nokid'
	qui matrix reg_results[2, `colnumber'] = `bs_tn_X_post_X_nokid'
	qui matrix reg_results[3, `colnumber'] = 2*abs( ttail(`e(df_r)', abs( `raw_tn_X_post_X_nokid' ) / `bs_tn_X_post_X_nokid' ) ) 

	qui matrix reg_results[5, `colnumber'] = `e(r2)'
	qui matrix reg_results[6, `colnumber'] = `e(N)'

	** Finally, go back to original data    

	use `original_data' , clear

end

************************************************************
************************************************************
**   Go back to regularly-scheduled program
************************************************************
************************************************************

************************************************************
**   Define individual controls
************************************************************

gen age2 = age * age
gen age3 = age2 * age
gen age4 = age3 * age
gen age5 = age4 * age

gen hsd = (educ < 73)
gen hsg = (educ == 73)
gen smc1 = (educ > 73 & educ < 91)
gen smc2 = (educ >=91 & educ < 111)
gen col = (educ == 111)

gen femaleXkid = female * kid

foreach var of varlist female hsg smc1 smc2 col kid {
	gen `var'Xage = `var' * age
	gen `var'Xage2 = `var' * age2
	gen `var'Xage3 = `var' * age3
	gen `var'Xage4 = `var' * age4
	gen `var'Xage5 = `var' * age5
}

foreach var of varlist hsg smc1 smc2 col kid {
	gen `var'XageXfemale = `var' * age * female
	gen `var'Xage2Xfemale = `var' * age2 * female
	gen `var'Xage3Xfemale = `var' * age3 * female
	gen `var'Xage4Xfemale = `var' * age4 * female
	gen `var'Xage5Xfemale = `var' * age5 * female
}

************************************************************
**   Individual-Level Appendix Table , with contrls
************************************************************

preserve

	global xvars = "age age2-age5 *Xage* female hsg smc1 smc2 col"
	d $xvars , f

	matrix reg_results = J(6, 6, .)

	qui micro_bs_this any_public 1 health withcontrols
	qui micro_bs_this working 2 labor withcontrols
	qui micro_bs_this hrs_lw_lt20 3 labor withcontrols
	qui micro_bs_this hrs_lw_ge20 4 labor withcontrols
	qui micro_bs_this hrs_lw_2035 5 labor withcontrols
	qui micro_bs_this hrs_lw_ge35 6 labor withcontrols

	clear
	svmat reg_results
	list, clean

restore

************************************************************
**   Individual-Level Appendix Table , no contrls
************************************************************

preserve

	matrix reg_results = J(6, 6, .)

	qui micro_bs_this any_public 1 health nocontrols
	qui micro_bs_this working 2 labor nocontrols
	qui micro_bs_this hrs_lw_lt20 3 labor nocontrols
	qui micro_bs_this hrs_lw_ge20 4 labor nocontrols
	qui micro_bs_this hrs_lw_2035 5 labor nocontrols
	qui micro_bs_this hrs_lw_ge35 6 labor nocontrols

	clear
	svmat reg_results
	list, clean

restore





log close
exit
