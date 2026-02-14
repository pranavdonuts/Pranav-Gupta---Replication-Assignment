
************************************************************
**   Check arguments for this program
************************************************************

args model outcome colnumber year0 year1
global year0 = `year0'
global year1 = `year1'
if "`model'" == "" | "`outcome'" == "" | "`colnumber'" == "" | "`year0'" == "" | "`year1'" == "" {
	disp "Please give the bootstrap procedure a model and outcome"
	kablooey
}

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

		** For the triple-difference models, we also look at population
		gen byte population = 1

		collapse ///
		(mean) working unemp ilf hrs_lw_* hrswork wage* ///
		(sum) population ///
		[aw = wtsupp] , by(year statefip nokid tn) fast

		gen log_population = log(population)
		drop population

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

	if "`model'" != "ddd" & "`model'" != "dd" {

		tempfile rest
		save `rest'

		collapse ///
		(mean) working unemp ilf hrs_lw_* hrswork wage* ///
		[aw = wtsupp] , by(year statefip nokid `model' tn) fast

		tempfile working_vars
		save `working_vars'

		use `rest'

		** Note: the weight hinswt is designed solely for the insurance variables
		collapse (mean) any_* ///
		[aw = hinswt], by(year statefip nokid `model' tn) fast

		** Redo year for health variables (NOT labor supply variables)
		replace year = year - 1

		sort year statefip nokid `model'
		merge 1:1 year statefip nokid `model' using `working_vars'
		drop _merge

	}

	** After the collapse, we restrict by year
	disp "Now imposing year restriction: `year0' to `year1'"
	keep if year >= $year0 & year <= $year1

	gen byte post = (year >= 2006)

end


************************************************************
**   Prepare for iterations
************************************************************

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

if ("$Niterations" != "") {
 local number_of_iterations = $Niterations
}
else {
 local number_of_iterations = 500
}
matrix bs_results = J(`number_of_iterations', 5, .)
local number_of_skipped_iterations = 0

************************************************************
**   Iterate!
************************************************************

forvalues i = 1/`number_of_iterations' {

 	di "iteration: `i' ..."

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

	if ( r(N) == 0 ) {
		local number_of_skipped_iterations = `number_of_skipped_iterations' + 1
	}

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

		** The following lines of code adjusts the weights for each 
		** iteration. This is experimental.
		*bys statefip year myn: gen count = _N
		*tab count, missing
		*replace wtsupp = wtsupp * count * $Nclusters / ($Nclusters - 1)
		*replace hinswt = hinswt * count * $Nclusters / ($Nclusters - 1)
		*drop count

		drop statefip_orig

		if "`model'" == "ddd" {
			qui our_collapse ddd

			gen byte tn_X_post_X_nokid = tn * post * nokid

			qui xi i.year*i.statefip i.year*i.nokid i.nokid*i.statefip

			qui reg `outcome' tn_X_post_X_nokid _I*, 
			qui matrix bs_results[`i', 1] = _b[tn_X_post_X_nokid]

			if "`outcome'" == "any_private" {
				local private = _b[tn_X_post_X_nokid]
				qui reg any_public tn_X_post_X_nokid _I*, 
				local public =  _b[tn_X_post_X_nokid]

				qui matrix bs_results[`i', 3] = `private' / `public'  
			}

		}

		if "`model'" == "dd" {
			qui our_collapse dd

			gen byte tn_X_post = tn * post 

			qui xi i.year i.statefip

			qui reg `outcome' tn_X_post _I*, 
			qui matrix bs_results[`i', 1] = _b[tn_X_post]

			if "`outcome'" == "any_private" {
				local private =  _b[tn_X_post]
				qui reg any_public tn_X_post _I*, 
				local public = _b[tn_X_post]
				qui matrix bs_results[`i', 3] = `private' / `public' 
			}
				
		}

		if "`model'" != "dd" & "`model'" != "ddd" {
			qui our_collapse `model'

			qui xi i.year*i.statefip i.year*i.nokid i.nokid*i.statefip 

			foreach var of varlist _I* {
				gen byte _`var' = `var' * (`model' == 1)
			}

			gen byte tn_X_post_X_nokid_X_t0 = tn * nokid * post * (`model' == 0)
			gen byte tn_X_post_X_nokid_X_t1 = tn * nokid * post * (`model' == 1)

			gen statefipXtype = statefip * 10 + `model'


			qui reg `outcome' tn_X_post_X_nokid_* _I* __I* `model' , 
			qui matrix bs_results[`i', 1] = _b[tn_X_post_X_nokid_X_t0]
			qui matrix bs_results[`i', 2] = _b[tn_X_post_X_nokid_X_t1]

			if "`outcome'" == "any_private" {
				local private0 =  _b[tn_X_post_X_nokid_X_t0]
				local private1 =  _b[tn_X_post_X_nokid_X_t1]
				qui reg any_public tn_X_post_X_nokid_* _I* __I* `model' , 
				local public0 =  _b[tn_X_post_X_nokid_X_t0]
				local public1 =  _b[tn_X_post_X_nokid_X_t1]
				qui matrix bs_results[`i', 3] = `private0' / `public0'
				qui matrix bs_results[`i', 4] = `private1' / `public1'
			}

			** Now we estimate the p-values across rows with the following regression
			disp "Mark 1!"
			gen byte tn_X_post_X_nokid = tn * nokid * post 
			reg `outcome' tn_X_post_X_nokid_X_t1 tn_X_post_X_nokid _I* __I* `model', 
			qui matrix bs_results[`i', 5] = _b[tn_X_post_X_nokid_X_t1]
		}
	}
}

** We now calculate the boostrapped standard error of the estimate
if "`model'" == "dd" | "`model'" == "ddd" {
	drop _all
	svmat bs_results

	summ bs_results1
	local bs_se = r(sd)

	sum bs_results3
	local crowdout_se = r(sd)
}
if "`model'" != "dd" & "`model'" != "ddd" {
	drop _all
	svmat bs_results

	summ bs_results1
	local bs_se0 = r(sd)

	summ bs_results2
	local bs_se1 = r(sd)

	sum bs_results3
	local crowdout0_se = r(sd)
	sum bs_results4
	local crowdout1_se = r(sd)

	sum bs_results5
	local acrossrow_se = r(sd)
}

************************************************************
** We now run the regression on the original (non-re-sampled) data    
************************************************************

use `original_data' , clear

if "`model'" == "dd" {

	our_collapse dd

	qui xi i.year i.statefip

	gen byte tn_X_post = tn * post 

	reg `outcome' tn_X_post _I* , cluster(statefip)
	local raw_beta = _b[tn_X_post]

	qui sum `outcome' if e(sample)
	local raw_dv_mean = `r(mean)'

	if "`outcome'" == "any_private" {
		local private = _b[tn_X_post]
		reg any_public tn_X_post _I* , cluster(statefip)
		local public = _b[tn_X_post]
		local raw_crowdout = `private' / `public'
	}
}

if "`model'" == "ddd" {

	our_collapse ddd

	qui xi i.year*i.statefip i.year*i.nokid i.nokid*i.statefip

	gen byte tn_X_post_X_nokid = tn * post * nokid

	reg `outcome' tn_X_post_X_nokid _I* , cluster(statefip)
	local raw_beta = _b[tn_X_post_X_nokid]

	qui sum `outcome' if e(sample)
	local raw_dv_mean = `r(mean)'

	if "`outcome'" == "any_private" {
		local private = _b[tn_X_post_X_nokid]
		reg any_public tn_X_post_X_nokid _I* , cluster(statefip)
		local public = _b[tn_X_post_X_nokid]
		local raw_crowdout = `private' / `public'
	}
}

if "`model'" != "ddd" & "`model'" != "dd" {

	our_collapse `model'

	qui xi i.year*i.statefip i.year*i.nokid i.nokid*i.statefip

	foreach var of varlist _I* {
		gen byte _`var' = `var' * (`model' == 1)
	}

	gen byte tn_X_post_X_nokid_X_t0 = tn * nokid * post * (`model' == 0)
	gen byte tn_X_post_X_nokid_X_t1 = tn * nokid * post * (`model' == 1)

	gen statefipXtype = statefip * 10 + `model'

	reg `outcome' tn_X_post_X_nokid_* _I* __I* `model' , 
	local raw_beta0 = _b[tn_X_post_X_nokid_X_t0]
	local raw_beta1 = _b[tn_X_post_X_nokid_X_t1]

	qui sum `outcome' if e(sample) & `model' == 0
	local raw_dv_mean0 = r(mean)
	qui sum `outcome' if e(sample) & `model' == 1
	local raw_dv_mean1 = r(mean)

	if "`outcome'" == "any_private" {
		local private0 =  _b[tn_X_post_X_nokid_X_t0]
		local private1 =  _b[tn_X_post_X_nokid_X_t1]
		qui reg any_public tn_X_post_X_nokid_* _I* __I* `model' , 
		local public0 =  _b[tn_X_post_X_nokid_X_t0]
		local public1 =  _b[tn_X_post_X_nokid_X_t1]
		local raw_crowdout0 = `private0' / `public0'
		local raw_crowdout1 = `private1' / `public1'
	}

	disp "Mark 2!"
	gen byte tn_X_post_X_nokid = tn * nokid * post 
	qui reg `outcome' tn_X_post_X_nokid_X_t1 tn_X_post_X_nokid _I* __I* `model' , 
	local raw_acrossrow = _b[tn_X_post_X_nokid_X_t1]
}

************************************************************
** Save out key statistics for regular models
************************************************************

if "`model'" == "ddd" | "`model'" == "dd" {
	qui matrix reg_results[1, `colnumber'] = `raw_beta'
	qui matrix reg_results[2, `colnumber'] = `bs_se'
	qui matrix reg_results[3, `colnumber'] = 2*abs( ttail(`e(df_r)', abs( `raw_beta' ) / `bs_se' ) ) 

	qui matrix reg_results[5, `colnumber'] = `e(r2)'
	qui matrix reg_results[6, `colnumber'] = `e(N)'

	qui matrix reg_results[8, `colnumber'] = `raw_dv_mean'

	if "`outcome'" == "any_private" {
		local nextcolnumber = `colnumber' + 1
		qui matrix reg_results[1, `nextcolnumber'] = `raw_crowdout'
		qui matrix reg_results[2, `nextcolnumber'] = `crowdout_se'
		qui matrix reg_results[3, `nextcolnumber'] = 2*abs( ttail(`e(df_r)', abs( `raw_crowdout' ) / `crowdout_se' ) ) 
	}
}

************************************************************
**   Save out key statistics for heterogeneity models
************************************************************

if "`model'" != "ddd" & "`model'" != "dd" {
	qui matrix reg_results[1, `colnumber'] = `raw_beta0'
	qui matrix reg_results[2, `colnumber'] = `bs_se0'
	qui matrix reg_results[3, `colnumber'] = 2*abs( ttail(`e(df_r)', abs( `raw_beta0' ) / `bs_se0' ) ) 

	qui matrix reg_results[5, `colnumber'] = `raw_beta1'
	qui matrix reg_results[6, `colnumber'] = `bs_se1'
	qui matrix reg_results[7, `colnumber'] = 2*abs( ttail(`e(df_r)', abs( `raw_beta1' ) / `bs_se1' ) ) 

	qui matrix reg_results[11, `colnumber'] = `e(r2)'
	qui matrix reg_results[12, `colnumber'] = `e(N)'

	qui matrix reg_results[14, `colnumber'] = `raw_dv_mean0'
	qui matrix reg_results[15, `colnumber'] = `raw_dv_mean1'

	if "`outcome'" == "any_private" {
		local nextcolnumber = `colnumber' + 1
		qui matrix reg_results[1, `nextcolnumber'] = `raw_crowdout0'
		qui matrix reg_results[2, `nextcolnumber'] = `crowdout0_se'
		qui matrix reg_results[3, `nextcolnumber'] = 2*abs( ttail(`e(df_r)', abs( `raw_crowdout0' ) / `crowdout0_se' ) ) 

		qui matrix reg_results[5, `nextcolnumber'] = `raw_crowdout1'
		qui matrix reg_results[6, `nextcolnumber'] = `crowdout1_se'
		qui matrix reg_results[7, `nextcolnumber'] = 2*abs( ttail(`e(df_r)', abs( `raw_crowdout1' ) / `crowdout1_se' ) ) 
	}

	qui matrix reg_results[9, `colnumber'] = 2*abs( ttail(`e(df_r)', abs( `raw_acrossrow' ) / `acrossrow_se' ) ) 
}

************************************************************
** Finally, go back to original data    
************************************************************

disp "Note: this bootstrap procedure skipped `number_of_skipped_iterations' out of `number_of_iterations' because those samples did not contain Tennessee"

use `original_data' , clear

