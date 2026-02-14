#delim cr
version 12
set more off
pause on
graph set ps logo off

capture log close
set linesize 200
set logtype text
log using ../log/create-nhis-table.log , replace

/* --------------------------------------

This program creates basic sample statistics of
employment and health insurance coverage rates.

--------------------------------------- */

clear all
estimates clear
set mem 1500m


************************************************************
**  Bring in Person File 
************************************************************

use ../src/nhis-2005-personsx.dta , clear

************************************************************
**   Gender
************************************************************

tab sex , miss
gen byte female = (sex == 2)

************************************************************
** Clean Weights                                          **
************************************************************

sum wtfa
rename wtfa sample_weight
egen sample_weight_sum = sum(sample_weight)
list sample_weight_sum in 1/1


************************************************************
**   Identify geographic region
************************************************************

** According to this URL, these are Census regions, and the weights
** work within region.
** http://www.cdc.gov/rdc/geocodes/geowt_nhis.htm
** 	1 Northeast
** 	2 Midwest
** 	3 South
** 	4 West

tab region

************************************************************
**   Restrictions
************************************************************

rename age_p age
sum age
keep if age >= 21 & age <= 64

keep if region == 3

************************************************************
**   Code health insurance variables
************************************************************

** Are you offered health insurance from your employer?
** Asked of those who worked last week.
tab hiempof , miss
gen byte eshi_offered = (hiempof == 1)
gen byte eshi_offered_nonmiss = (hiempof == 1 | hiempof == 2)

** Is your private policy in your name?
** Asked of those with private policies.
tab whonam1 , miss
gen byte private_inownname = (whonam1 == 1)
sum private_inownname
table female , c(mean private_inownname)

** Do you have private insurance?
** Asked of everyone.
tab private , miss
gen byte insurance_private = ( private == 1 | private == 2 )

************************************************************
**   Code employment variables
************************************************************

tab wrkhrs2 , miss
gen hours_lastweek = wrkhrs2
replace hours_lastweek = . if wrkhrs2 >= 96

************************************************************
**   Describe offer rates by hours worked
************************************************************

** Overall
count if hours_lastweek > 0 & hours_lastweek < .
sum eshi_offered private_inownname if hours_lastweek > 0 & hours_lastweek < .
sum eshi_offered private_inownname [aw = sample_weight] if hours_lastweek > 0 & hours_lastweek < .

** 0 -- 20
count if hours_lastweek > 0 & hours_lastweek < 20 
sum eshi_offered private_inownname if hours_lastweek > 0 & hours_lastweek < 20 
sum eshi_offered private_inownname [aw = sample_weight] if hours_lastweek > 0 & hours_lastweek < 20 

** 20 -- 35
count if hours_lastweek >= 20 & hours_lastweek < 35
sum eshi_offered private_inownname if hours_lastweek >= 20 & hours_lastweek < 35
sum eshi_offered private_inownname [aw = sample_weight] if hours_lastweek >= 20 & hours_lastweek < 35

** greater than 35
count if hours_lastweek >= 35 & hours_lastweek < .
sum eshi_offered private_inownname if hours_lastweek >= 35 & hours_lastweek < .
sum eshi_offered private_inownname [aw = sample_weight] if hours_lastweek >= 35 & hours_lastweek < .






log close
exit

