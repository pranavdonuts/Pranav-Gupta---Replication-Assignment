#delim cr
set more off
version 12
pause on
graph set ps logo off

capture log close
set linesize 80
set logtype text
log using ../log/graph-laus-trend.log , replace

/* --------------------------------------

This program plots trends in employment based on
LAUS data.

--------------------------------------- */

clear all
estimates clear

insheet using ../src/Laus_TN_popadj.csv
rename emp_rates emp_rate_S

keep if ym >= 2004 & ym <= 2007
summ

format emp_rate_S %12.3f
format emp_rate %12.3f

local tenncare_line = 2005 + (6/12)

local inv_golden_ratio = 2 / ( sqrt(5) + 1 )
graph set window fontface "Garamond" 
twoway ///
	(connected emp_rate_S ym, yaxis(1) lpattern(dash) lcolor(gray) mcolor(red) msymbol(i)) ///
	(connected emp_rate   ym, yaxis(2) lpattern(solid) lcolor(gray) mcolor(blue) msymbol(o) ) ///
	, ///
	ylabel(, nogrid angle(horizontal) axis(1)  ) ///
	ylabel(, nogrid angle(horizontal) axis(2)  ) ///
	scheme(s2mono)  ///
	xline(`tenncare_line') ///
	aspectratio(`inv_golden_ratio') ///
	graphregion(fcolor(white))  ///
	legend(off) ///
	yscale( nofextend ) xscale(nofextend) ///
	xtitle(" ") ///
	xlabel(2004(1)2007) ///
	ytitle("", axis(1)) ytitle("", axis(2)) ///
	ylabel(0.715(0.01)0.765, axis(1)) ylabel(0.69(0.01)0.74, axis(2)) yscale(axis(2) r(0.6898 0.7402))  yscale(axis(1) r(0.7148 0.7652))
  
graph save ../gph/laus-trends.gph , replace



log close
exit
