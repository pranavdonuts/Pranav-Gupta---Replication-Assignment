#delim cr
set more off
version 12
pause on
graph set ps logo off

capture log close
set linesize 180
set logtype text
log using  ../log/run-cps-wild-bootstrap-tests.log , replace

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
**   Bootstrap Program Used Below                          
************************************************************

** The following code originally comes from Doug Miller's web site.
** It is meant to calculate wild-bootstrap-based standard errors.
** I have refactored CGM's original code.


** NOTES: first argument should be "0" (null hypothesis is 0)
**        second argument is name of dependent variable
**        third argument is either DD or DDD
**
**        must set "global bootreps" before running
**

capture program drop wildbootstrap 
program define wildbootstrap 

	preserve

		args hypothesis outcome type
	 
		if ("`type'" == "DD") {
			local var = "tn_X_post"
		}
		else {
			if ("`type'" == "DDD") {
				local var = "tn_X_post_X_nokid"
			}
			else {
				di "ERROR: Must be either DD or DDD"
				kaboom
			}
		}
	  
		postutil clear
		tempfile main 
		tempfile bootsave 

		disp 
		disp "Now calculating wild bootstrap for outcome `outcome'"

		** First run OLS on the original sample, and calculate Wald statistic
		reg `outcome' `var' _I*, cluster(statefip)
	  
		global mainbeta = _b[`var'] 
		global maint = (_b[`var'] - `hypothesis') / _se[`var'] 
		predict epshat , resid

		** If imposing null of 0, we don't need to re-run OLS
		gen epshat_imposed = epshat
		gen yhat_imposed = `outcome' - epshat

		sort statefip year 
		qui save `main' , replace 

		qui by statefip: keep if _n == 1 
		qui summ 
		global numstates = r(N) 
		di "num states: $numstates"

		postfile bskeep beta_np t_np t_wild using `bootsave' , replace 

		forvalues b = 1/$bootreps { 

			if (`b' == 50 * floor(`b' / 50)) {
				display "Now on bootstrap iteration `b'"
			}  

			use `main', replace 
			qui by statefip: gen temp = uniform() 
			qui by statefip: gen pos = (temp[1] < .5) 
			gen wildresid = epshat_imposed * (2*pos - 1) 
			gen wildy = yhat_imposed + wildresid 
			qui reg wildy `var' _I*, cluster(statefip)
			local bst_wild = (_b[`var'] - $mainbeta) / _se[`var'] 

			local bsbeta = _b[`var'] 
			local bst = (_b[`var'] - $mainbeta) / _se[`var']

			** post bskeep (`bst_wild') 
			post bskeep (`bsbeta') (`bst') (`bst_wild') 

		}
		qui postclose bskeep 

		qui drop _all 
		qui set obs 1 
		gen beta_np = $mainbeta
		gen t_wild = $maint 
		gen t_np = $maint 
		qui append using `bootsave' 

		qui gen n = . 

		foreach stat in t_wild { 

			summ `stat', det
			local bign = r(N) 
			gen a`stat' = abs(`stat')
			sort a`stat'
			qui replace n = _n 
			qui summ n if abs(`stat' - $maint) < .000001 
			local myp = r(mean) / `bign' 
			global pctile_`stat' = min(`myp',(1-`myp')) 

		}

		global mainp = normal($maint) 
		global pctile_main = 2 * min($mainp,(1-$mainp)) 

		local myfmt = "%7.5f" 

		di 
		di "Number BS reps = $bootreps, Null hypothesis = `hypothesis'" 
		display "Main beta" _column(13) "main T"  _column(22) "Main %le" _column(54) "wild %le" 
		di   %6.3f $mainbeta _column(13) %6.3f $maint  _column(23) `myfmt' $pctile_main _column(55) `myfmt' $pctile_t_wild 

	restore
  
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
**   Run Wild Bootstrap for triple-difference results
************************************************************

tempfile preboot2
save `preboot2'

foreach outcome in any_public working hrs_lw_lt20 hrs_lw_ge20 hrs_lw_2035 hrs_lw_ge35 {

	disp " "
	disp " "
	disp " "
	disp " "
	disp "Now studying outcome `outcome' "

	keep if age >= 21 & age < 65
	keep if south == 1

	** We need to define these global variables for the
	** collapse command.
	global year0 = 2000
	global year1 = 2007

	our_collapse ddd

	** We define these global variables for the
	** bootstrap command.
	global numstates = 17
	global bootreps = 10000

	qui xi i.year*i.statefip i.year*i.nokid i.nokid*i.statefip
	gen tn_X_post_X_nokid = tn *  (year >= 2006) * nokid
	wildbootstrap 0 `outcome' DDD

	use `preboot2' , clear
}

************************************************************
**   Run Wild Bootstrap for difference-in-difference results
************************************************************

tempfile preboot
save `preboot'

foreach outcome in any_public working hrs_lw_lt20 hrs_lw_ge20 hrs_lw_2035 hrs_lw_ge35 {

	disp " "
	disp " "
	disp " "
	disp " "
	disp "Now studying outcome `outcome' "

	keep if age >= 21 & age < 65
	keep if south == 1

	** We need to define these global variables for the
	** collapse command.
	global year0 = 2000
	global year1 = 2007

	our_collapse dd

	** We define these global variables for the
	** bootstrap command.
	global numstates = 17
	global bootreps = 10000

	gen tn_X_post = tn * (year >= 2006)
	xi i.statefip i.year
	wildbootstrap 0 `outcome' DD

	use `preboot' , clear
}



log close
exit
