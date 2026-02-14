#delim cr
set more off
version 12
clear all
estimates clear
macro drop _all

************************************************************
** CONFIGURATION (Automatic)
************************************************************
* We set this manually to "all" so you don't need arguments.
local piece "all"

capture log close
set linesize 200
log using "../log/run-cps-tables-extended.log", replace

************************************************************
** Prepare Data
************************************************************
use "../dta/cps_MICRO_FINAL.dta", clear

* Filter main sample immediately
keep if year >= 1998
keep if age >= 21

* Define Original South Control
gen byte south = (statefip == 54 | statefip == 24 | statefip == 10 | statefip == 11 | ///
                  statefip == 21 | statefip == 47 | statefip == 37 | statefip == 51 | ///
                  statefip == 45 | statefip == 13 | statefip == 5  | statefip == 22 | ///
                  statefip == 48 | statefip == 40 | statefip == 1  | statefip == 28 | statefip == 12)

* EXTENSION: Define "Direct Border States" Control Group
* KY(21), VA(51), NC(37), GA(13), AL(1), MS(28), AR(5), MO(29)
gen byte border_states = (statefip==21 | statefip==51 | statefip==37 | statefip==13 | ///
                          statefip==1  | statefip==28 | statefip==5  | statefip==29)

gen byte tn = (statefip == 47)
gen byte post = (year >= 2006)
gen byte tn_X_post = tn * post
gen byte nokid = (1 - kid)

* --------------------------------------------------------
* ROBUST VARIABLE CLEANUP (Prevents "already defined" errors)
* --------------------------------------------------------
foreach var in female agebin age5564 educbin white black other any_college hsd hsg {
    capture drop `var'
}

* Now we can safely generate them
gen byte female = (sex == 2)
gen byte agebin = (age >= 40 & age < 65)
gen byte age5564 = (age >= 55 & age <= 64)
gen byte educbin = (educ >= 73)

* Race definitions
gen byte white = (race == 100)
gen byte black = (race == 200 | race == 801 | race == 805 | race == 806 | race == 807)
gen byte other = 1 - white - black

* Education definitions
gen byte hsd = (educ < 73)
gen byte hsg = (educ == 73)
gen byte any_college = (smc1 == 1 | smc2 == 1 | col == 1)

compress

************************************************************
** Table I: Summary Statistics (Extended)
************************************************************

preserve
    keep if south == 1
    keep if age >= 21 & age < 65

    * Initialize matrix with 3 columns: TN, South, Border
    matrix sample_stats = J(25,3,.)

    local row = 1

    * Loop for Insurance Variables
    foreach var in any_public any_private {
        qui sum `var' [aw = hinswt] if tn == 1 & year >= 2001 & year <= 2008
        matrix sample_stats[`row',1] = r(mean)
        
        qui sum `var' [aw = hinswt] if tn == 0 & south == 1 & year >= 2001 & year <= 2008
        matrix sample_stats[`row',2] = r(mean)
        
        qui sum `var' [aw = hinswt] if border_states == 1 & year >= 2001 & year <= 2008
        matrix sample_stats[`row',3] = r(mean)
        
        local row = `row' + 1
    }
    local row = `row' + 1

    * Loop for Employment Variables
    foreach var in working hrs_lw_lt20 hrs_lw_2035 hrs_lw_ge35 {
        qui sum `var' [aw = wtsupp] if tn == 1 & year >= 2000 & year <= 2007
        matrix sample_stats[`row',1] = r(mean)
        
        qui sum `var' [aw = wtsupp] if tn == 0 & south == 1 & year >= 2000 & year <= 2007
        matrix sample_stats[`row',2] = r(mean)
        
        qui sum `var' [aw = wtsupp] if border_states == 1 & year >= 2000 & year <= 2007
        matrix sample_stats[`row',3] = r(mean)
        local row = `row' + 1
    }
    local row = `row' + 1

    * Loop for Demographics
    foreach var in kid agebin female {
        qui sum `var' [aw = wtsupp] if tn == 1 & year >= 2000 & year <= 2007
        matrix sample_stats[`row',1] = r(mean)
        
        qui sum `var' [aw = wtsupp] if tn == 0 & south == 1 & year >= 2000 & year <= 2007
        matrix sample_stats[`row',2] = r(mean)
        
        qui sum `var' [aw = wtsupp] if border_states == 1 & year >= 2000 & year <= 2007
        matrix sample_stats[`row',3] = r(mean)
        local row = `row' + 1
    }
    local row = `row' + 1

    * Loop for Education
    foreach var in hsd hsg any_college {
        qui sum `var' [aw = wtsupp] if tn == 1 & year >= 2000 & year <= 2007
        matrix sample_stats[`row',1] = r(mean)
        
        qui sum `var' [aw = wtsupp] if tn == 0 & south == 1 & year >= 2000 & year <= 2007
        matrix sample_stats[`row',2] = r(mean)
        
        qui sum `var' [aw = wtsupp] if border_states == 1 & year >= 2000 & year <= 2007
        matrix sample_stats[`row',3] = r(mean)
        local row = `row' + 1
    }
    local row = `row' + 1

    * Loop for Race
    foreach var in white black other {
        qui sum `var' [aw = wtsupp] if tn == 1 & year >= 2000 & year <= 2007
        matrix sample_stats[`row',1] = r(mean)
        
        qui sum `var' [aw = wtsupp] if tn == 0 & south == 1 & year >= 2000 & year <= 2007
        matrix sample_stats[`row',2] = r(mean)
        
        qui sum `var' [aw = wtsupp] if border_states == 1 & year >= 2000 & year <= 2007
        matrix sample_stats[`row',3] = r(mean)
        local row = `row' + 1
    }

    disp ""
    disp "--------------------------------------------------------"
    disp "TABLE 1: TN (Col 1) vs. South (Col 2) vs. Border (Col 3)"
    disp "--------------------------------------------------------"
    clear
    svmat sample_stats
    list , clean
restore

************************************************************
** Table II: Regression Analysis (Border States Only)
************************************************************

if "`piece'" == "1" | "`piece'" == "all" {
    disp "Running Table 2 Regressions using BORDER STATES as control..."
    preserve

        * --- SPEED FIX: LIMIT ITERATIONS ---
        * Set this to 20 for a quick run. (Default is likely 200+)
        global Niterations = 20
        * -----------------------------------

        * RESTRICTION: Keep only Tennessee and Border States
        keep if tn == 1 | border_states == 1
        
        keep if age >= 21 & age < 65
        
        * Update clusters count (TN + 8 Border States = 9)
        global Nclusters = 9
        
        * Initialize matrix to store results
        matrix reg_results = J(8, 7, .)

        * Run the regressions using the authors' fragment script
        qui do fragment-run-our-bbs-procedure dd any_public 1 2000 2007 
        qui do fragment-run-our-bbs-procedure dd working 2 2000 2007 
        qui do fragment-run-our-bbs-procedure dd hrs_lw_lt20 3 2000 2007 
        qui do fragment-run-our-bbs-procedure dd hrs_lw_ge20 4 2000 2007 
        qui do fragment-run-our-bbs-procedure dd hrs_lw_2035 5 2000 2007 
        qui do fragment-run-our-bbs-procedure dd hrs_lw_ge35 6 2000 2007 
        qui do fragment-run-our-bbs-procedure dd any_empl_wk 7 2000 2007 

        clear
        svmat reg_results
        disp ""
        disp "--------------------------------------------------------"
        disp "TABLE 2: DiD Results (TN vs. Border States Only)"
        disp "--------------------------------------------------------"
        list, clean

    restore
}

log close
exit
