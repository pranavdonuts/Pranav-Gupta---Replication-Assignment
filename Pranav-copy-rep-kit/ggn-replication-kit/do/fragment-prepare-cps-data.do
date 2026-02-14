use ../src/cps_00013.dta, clear
d, f

************************************************************
**   Restrict to South and key years
************************************************************

if (`1' > 0 & `1' < 13) {
	gen south = ///
	 (statefip == 54 | statefip == 24 | statefip == 10 | statefip == 11 | ///
	  statefip == 21 | statefip == 47 | ///
	  statefip == 37 | statefip == 51 | statefip == 45 | statefip == 13 | ///
	  statefip ==  5 | statefip == 22 | statefip == 48 | statefip == 40 | ///
	  statefip ==  1 | statefip == 28 | statefip == 12 )
	
	keep if south == 1
	keep if year >= 1999 & year <= 2013
}


************************************************************
**   Identify those with kids
************************************************************

sort year serial
merge year serial using ../dta/cps_yngch.dta, uniqusing
tab year _merge, missing
assert _merge != 2 if year >= 2000
drop _merge
gen own_kid = yngch < 18

sort year serial age
by year serial: gen min_age = age[1]
by year serial: gen max_age = age[_N]
summ min_age ,det
gen kid = (min_age < 18)

replace inctot = . if inctot == 99999999 
replace inctot = . if inctot == 99999998 

************************************************************
**   Restrictions on age and education
************************************************************

if (`1' == 11) {
	keep if age >= 66
	keep if educ <= 111
}
if (`1' != 11 & `1' != 13) {
	keep if age >= 21 & age < 65
	keep if educ <= 111
}
if (`1' == 13) {
	keep if educ <= 111
}

************************************************************
**   Create key variables
************************************************************

gen any_ind = (hinspur == 2)

gen has_spouse = (sploc != 0)

** Impose no private h.i. if on Medicaid for 2003
gen verifs = (himcaid == 2 & hcovpriv == 2)
bys year: tab verifs if statefip == 47, missing
replace hcovpriv = . if himcaid == 2 & (year == 2003)

tab hcovpub , miss
gen byte any_public = (hcovpub == 2)

tab hcovpriv , miss
gen byte any_private = (hcovpriv == 2)

** We have found evidence that some publicly insured CPS respondents are
** mis-reporting their coverage is private. We remove this small group here.
replace any_private = 0 if any_ind == 1

tab hcovany , miss
gen byte any_coverage = (hcovany == 2)

gen any_empl = (hinsemp == 2)

** Drop armed forces(see IPUMS-CPS)
** Only working if have positive hours
drop if empstat == 13
gen byte working = (empstat == 10)

gen byte working_alt = (empstat >= 10 & empstat <= 12)

gen byte unemp = (empstat >= 20 & empstat <= 22)

gen byte ilf = (empstat >= 10 & empstat <= 22)

gen any_mcaid  = (himcaid == 2)
gen any_mcare  = (himcare == 2)

gen byte any_priv_wk   = (hcovpriv == 2 & working == 1)
gen byte any_priv_nowk = (hcovpriv == 2 & working == 0)

gen byte any_empl_wk = (any_empl == 1 & working == 1)
gen byte any_noempl_wk = (any_empl == 0 & working == 1)
 
gen byte any_nocov_wk     = (any_coverage == 0 & working == 1)
gen byte any_cov_wk     = (any_coverage == 1 & working == 1)

tab hrswork , miss
tab hrswork , miss nol
gen byte hrs_lw_lt20 = (hrswork < 20) & working == 1
gen byte hrs_lw_2035 = (hrswork >= 20 & hrswork < 35) & working == 1
gen byte hrs_lw_ge35 = (hrswork >= 35 & hrswork < .) & working == 1
gen byte hrs_lw_ge20 = (hrswork >= 20 & hrswork < .) & working == 1
sum hrs_lw*

replace uhrswork = . if uhrswork == 0
replace uhrswork = . if empstat < 10 | empstat > 13

replace wkswork1 = . if empstat < 10 | empstat > 13

gen wage = inctot / (wkswork1 * uhrswork) 

summ year
local miny = r(min)
local maxy = r(max)
forvalues y = `miny'(1)`maxy' {
	qui summ wage [aw=wtsupp] if year == `y', det
	replace wage = r(p1) if wage < r(p1)  & year == `y'
	replace wage = r(p99) if wage > r(p99) & wage < . & year == `y'
}

replace wage = log(wage)

gen age2 = age * age
gen age3 = age2 * age
gen age4 = age3 * age
gen age5 = age4 * age

gen female = (sex == 2)

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

reg wage age age2-age5 *Xage* female hsg smc1 smc2 col i.year if year >= 2000 & year <= 2004
predict wage_resid, resid

drop age2-age5 *Xage*

gen wage_empl = wage if any_empl == 1

************************************************************
**   Generate "type" variables
************************************************************

gen type0 = 1
gen type1 = (sex == 2)
gen type2 = ///
 0 * (age >= 21 & age < 40) + ///
 1 * (age >= 40 & age < 65)
gen type3 = (educ >= 73)

** Health: 1 is Excellent, 5 is Poor
tab health , miss
gen type4 = (health >= 3) 
gen type5 = (health >= 2) 
gen type6 = (health >= 2) 
sum type4 type5 type6

gen type9 = has_spouse 

if (`1' == 7) {
 keep if has_spouse == 1
}
gen type7 = (sex == 2)

if (`1' == 8) {
 keep if has_spouse == 0
}
gen type8 = (sex == 2)

**
** DD type (use same "prepare-data" to keep same sample restrictions)
**
gen type10 = 1
gen type11 = 1
if (`1' == 10 | `1' == 11) {
	replace kid = 0
}

************************************************************
**   Describe health status
************************************************************

** To answer one referee request, we need to tabulate health status.
** Recall, that 1 indicates "excellent."
tab health

tab health if any_public == 1

tab health if statefip == 47

tab health if any_public == 1 & statefip == 47

tab health if year == 2005

tab health if year == 2005 & any_public == 1

tab health if year == 2005 & statefip == 47

************************************************************
**   Collapse to (DD) cells
************************************************************

if (`1' < 13) {

	preserve

		foreach var of varlist any_public working* any_private hrs_lw_* {
		 gen se_`var' = `var'
		}

		tempfile rest
		save `rest'

		** Extract the working variable separately
		** since it requires a separate weight
			collapse ///
			  (sum) wtsupp (semean) se_working* se_hrs_lw* ///
			  (mean) working* unemp ilf hrs_lw_* hrswork wage* ///
			[aw = wtsupp] , by(year statefip) fast

			tempfile workingDD
			save `workingDD'


		use `rest'
		** Note: the weight hinswt is designed solely for the insurance variables
		collapse (sum) hinswt (mean) any_* ///
		      (semean) se_any_* ///
		      [aw = hinswt], by(year statefip) fast

		** Redo year for health variables (NOT labor supply variables)
		replace year = year - 1

		sort year statefip
		merge 1:1 year statefip using `workingDD'
		tab _merge
		drop _merge

 	save ../dta/cps_DD_FINAL.dta, replace

	restore
}

************************************************************
**   Collapse to (DDD) cells
************************************************************

if (`1' < 13) {

	foreach var of varlist any_public working* any_private hrs_lw_* {
		gen se_`var' = `var'
	}

	** Extract the working variable separately
	** since it requires a separate weight
	preserve
		collapse ///
		  (sum) wtsupp (semean) se_working* se_hrs_lw* ///
		  (mean) working* unemp ilf hrs_lw_* hrswork wage* ///
		[aw = wtsupp] , by(year statefip kid type`1') fast

		tempfile working
		save `working'

	restore


	** Note: the weight hinswt is designed solely for the insurance variables
	collapse (sum) hinswt (mean) any_* ///
	      (semean) se_any_* ///
	      [aw = hinswt], by(year statefip kid type`1') fast

	** Redo year for health variables (NOT labor supply variables)
	replace year = year - 1

	sort year statefip kid type`1'
	merge 1:1 year statefip kid type`1' using `working'
	tab _merge
	drop _merge

 	save ../dta/cps_DDD_FINAL.dta, replace

}


if (`1' == 13) {
  save ../dta/cps_MICRO_FINAL.dta, replace
}
