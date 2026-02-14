#delim cr
set more off
version 12
pause on
graph set ps logo off

capture log close
set linesize 200
set logtype text
log using ../log/clean-brfss-data-1990-2008.log , replace

/* --------------------------------------

This program compiles and cleans a working copy of the 
BRFSS data.

--------------------------------------- */

estimates clear
clear all

************************************************************
**   Bring in all BRFSS Data
************************************************************

forvalues year = 1990 (1) 2008 {
	append using ../dta/brfss/brfss_data_`year'
}

************************************************************
**   Basic Cleaning Code
************************************************************

recode year 90=1990 91=1991 92=1992 93=1993 94=1994 95=1995 96=1996 97=1997 98=1998 99=1999

replace age=. if age<=09

replace educ=. if educ>=9
recode educ 2=1 3=1 4=2 5=2 6=3 7=3 8=3
label variable marital `"marital status 1=marr 2=widow 3=div 4=sep 5=nev mar 6=couple"'
label variable educ `"education, 1= <high school, 2= hs grad/some college 3= college grad "'
label variable phys_act `"activity level, 1=sedentary, 2=irregular, 3=regular, 4=vigorous"'
label variable kids `"# of kids in household, 3=3 or more"'

replace weight=. if weight>=777

************************************************************
**   Save & Close
************************************************************

compress
save ../dta/brfss_data_all.dta , replace


log close
exit

